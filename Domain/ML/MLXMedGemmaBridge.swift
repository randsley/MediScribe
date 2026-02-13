//
//  MLXMedGemmaBridge.swift
//  MediScribe
//
//  MedGemma-specific wrapper for multimodal vision-language inference
//  Uses MLXVLM for true on-device inference on physical devices
//  Falls back to correctly-structured placeholder JSON on simulator
//

import Foundation
import UIKit

#if !targetEnvironment(simulator)
import MLX
import MLXNN
import MLXVLM
import MLXLMCommon
#endif

/// MedGemma-specific wrapper for multimodal vision-language inference
class MLXMedGemmaBridge {
    static let shared = MLXMedGemmaBridge()

    private var isLoaded = false

    #if !targetEnvironment(simulator)
    private var modelContainer: ModelContainer?
    #endif

    private init() {}

    /// Whether the model is currently loaded and ready for inference
    var isModelLoaded: Bool { isLoaded }

    // MARK: - Memory Diagnostics (DEBUG only)

    #if DEBUG
    /// Returns current process resident memory in MB.
    /// Used to pinpoint which inference phase causes the memory spike.
    private func memMB() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
        )
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return "?MB" }
        return String(format: "%.0fMB", Double(info.resident_size) / 1_048_576)
    }
    #endif

    // MARK: - Model Loading

    /// Load MedGemma from a local model directory
    func loadModel(from modelPath: String) async throws {
        guard !isLoaded else { return }

        #if targetEnvironment(simulator)
        // MLX Metal GPU APIs are unavailable on simulator — use placeholder path
        print("⚠️ MLX not available on simulator - using placeholder responses")
        isLoaded = true

        #else
        // Physical device: load via VLMModelFactory with local directory
        guard FileManager.default.fileExists(atPath: modelPath) else {
            throw MLXModelError.fileAccessError("Model path does not exist: \(modelPath)")
        }

        // Only verify the two core config files — weight files may be sharded
        // (model-NNNNN-of-NNNNN.safetensors + index) so checking for model.safetensors
        // directly will fail on quantized models. VLMModelFactory discovers weights itself.
        let requiredFiles = ["config.json", "tokenizer.json"]
        for file in requiredFiles {
            let filePath = (modelPath as NSString).appendingPathComponent(file)
            guard FileManager.default.fileExists(atPath: filePath) else {
                throw MLXModelError.fileAccessError("Missing required file: \(file)")
            }
        }

        do {
            // Limit MLX GPU buffer cache to avoid OOM during vision encoder inference.
            // Default cache is unbounded; 512 MB is enough for inter-op reuse without
            // allowing the allocator to hold onto all activation buffers after the
            // 4096-token SigLIP attention pass.
            MLX.GPU.set(cacheLimit: 512 * 1024 * 1024)

            // ModelConfiguration(directory:) loads from local path, no Hub download
            // MedGemma is Gemma3-based; extraEOSTokens matches the model's end-of-turn token
            let config = MLXLMCommon.ModelConfiguration(
                directory: URL(fileURLWithPath: modelPath),
                extraEOSTokens: ["<end_of_turn>"]
            )
            let container = try await VLMModelFactory.shared.loadContainer(
                configuration: config
            )
            // Release cached load-phase allocations before first inference
            MLX.GPU.clearCache()
            modelContainer = container
            isLoaded = true
            print("✅ MedGemma (Gemma3 VLM) loaded from: \(modelPath)")
        } catch {
            let detail = "VLMModelFactory error: \(error)"
            print("❌ \(detail)")
            throw MLXModelError.modelLoadFailed(detail)
        }
        #endif
    }

    /// Unload model and free memory
    func unloadModel() {
        #if !targetEnvironment(simulator)
        modelContainer = nil
        #endif
        isLoaded = false
    }

    // MARK: - Vision-Language Inference

    /// Generate medical findings from image + prompt (multimodal)
    func generateFindings(
        from imageData: Data,
        prompt: String,
        maxTokens: Int = 1024,
        temperature: Float = 0.3,
        language: Language = .english
    ) async throws -> String {
        #if targetEnvironment(simulator)
        return simulatorPlaceholderJSON()

        #else
        guard let container = modelContainer else {
            throw MLXModelError.modelNotLoaded
        }

        // Decode and pre-resize inside a nested scope so the original
        // full-resolution bitmap (up to ~200 MB for camera images) is freed
        // from memory before the 30-60 s SigLIP + LM inference pass starts.
        // preparingThumbnail(of:) returns a new UIImage with its own independent
        // pixel buffer — the CIImage below has no reference back to the
        // original imageData decode.
        #if DEBUG
        print("🧠 [inference start] app memory: \(memMB())")
        #endif

        let ciImage: CIImage = try {
            guard let uiImage = UIImage(data: imageData) else {
                throw MLXModelError.invocationFailed("Failed to decode image data")
            }
            // 448×448: (448/14)² = 1024 patches → pooled to 256 LM tokens (2×2 pool).
            // Sufficient visual resolution to distinguish image modalities and read
            // coarse text. SigLIP attention at 1024 patches: ~33MB/layer vs ~537MB
            // at 896×896 — safe with the shortened prompt (~190 tokens, 446 total).
            let maxDim: CGFloat = 448
            let longest = max(uiImage.size.width, uiImage.size.height)
            let inferenceImage: UIImage
            if longest > maxDim {
                let scale = maxDim / longest
                let sz = CGSize(
                    width:  (uiImage.size.width  * scale).rounded(),
                    height: (uiImage.size.height * scale).rounded()
                )
                // Thread-safe (iOS 15+); creates an independent pixel buffer
                inferenceImage = uiImage.preparingThumbnail(of: sz) ?? uiImage
            } else {
                inferenceImage = uiImage
            }
            guard let ci = CIImage(image: inferenceImage) else {
                throw MLXModelError.invocationFailed("Failed to convert image to CIImage")
            }
            return ci
            // uiImage exits scope here — ARC can free the original full-res bitmap
        }()

        // Use the caller-supplied prompt, or build a language-specific default
        let localizedPrompt = LocalizedPrompts(language: language)
            .buildImagingPrompt(imageContext: "Medical imaging scan")
        let finalPrompt = prompt.isEmpty ? localizedPrompt : prompt

        // Wrap in Optional so we can nil it out inside container.perform
        // once prepare() has consumed it — frees the CIImage reference before
        // the generation loop.
        var userInput: UserInput? = UserInput(
            prompt: finalPrompt,
            images: [.ciImage(ciImage)]
        )
        let parameters = GenerateParameters(maxTokens: maxTokens, temperature: temperature)

        do {
            // Zero the GPU buffer cache immediately before inference so every
            // intermediate SigLIP activation is freed as soon as it's no longer
            // referenced, rather than being held in a reuse pool.
            // At 224×224 (256 patches) SigLIP attention is ~2MB/layer (trivial).
            // Keeping cacheLimit=0 ensures any unexpected accumulation is freed
            // immediately rather than growing in a reuse pool.
            MLX.GPU.set(cacheLimit: 0)
            MLX.GPU.clearCache()

            let result = try await container.perform { [userInput] context in
                guard let ui = userInput else {
                    throw MLXModelError.invocationFailed("UserInput was unexpectedly nil")
                }
                #if DEBUG
                print("🧠 [before prepare] app memory: \(self.memMB())")
                #endif
                let lmInput = try await context.processor.prepare(input: ui)
                // Force evaluation of all preprocessed arrays before entering
                // the LM decoding loop, so the computation graph for the image
                // preprocessing step is freed before the generation loop begins.
                MLX.eval(lmInput.text.tokens)
                if let img = lmInput.image { MLX.eval(img.pixels) }
                MLX.GPU.clearCache()
                #if DEBUG
                print("🧠 [after SigLIP eval+clearCache] app memory: \(self.memMB())")
                #endif
                // Flush the GPU buffer reuse pool every 32 tokens during decode.
                // MLX's lazy evaluation can accumulate unevaluated graph nodes and
                // cached buffers across generation steps; periodic clearCache()
                // releases these before they pile up into an OOM kill.
                var stepCount = 0
                return try generate(
                    input: lmInput,
                    parameters: parameters,
                    context: context
                ) { (_: [Int]) in
                    stepCount += 1
                    #if DEBUG
                    if stepCount == 1 || stepCount % 32 == 0 {
                        print("🧠 [token \(stepCount)] app memory: \(self.memMB())")
                    }
                    #endif
                    if stepCount % 32 == 0 { MLX.GPU.clearCache() }
                    return .more
                }
            }
            userInput = nil  // free CIImage reference after container.perform

            // Restore a small reuse pool so subsequent inference (if any) can
            // benefit from buffer recycling without accumulating stale memory.
            MLX.GPU.set(cacheLimit: 64 * 1024 * 1024)

            return result.output
        } catch let error as MLXModelError {
            throw error
        } catch {
            throw MLXModelError.invocationFailed(error.localizedDescription)
        }
        #endif
    }

    /// Streaming variant — yields decoded text pieces as they are generated
    func generateFindingsStreaming(
        from imageData: Data,
        prompt: String,
        maxTokens: Int = 1024,
        temperature: Float = 0.3,
        language: Language = .english
    ) -> AsyncThrowingStream<String, Error> {
        #if targetEnvironment(simulator)
        // Simulator: stream the placeholder JSON one character at a time
        return AsyncThrowingStream { continuation in
            Task {
                let json = simulatorPlaceholderJSON()
                for char in json {
                    try await Task.sleep(nanoseconds: 10_000_000)
                    continuation.yield(String(char))
                }
                continuation.finish()
            }
        }

        #else
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let container = self.modelContainer else {
                        throw MLXModelError.modelNotLoaded
                    }
                    let ciImage: CIImage = try {
                        guard let uiImage = UIImage(data: imageData) else {
                            throw MLXModelError.invocationFailed("Failed to decode image data")
                        }
                        let maxDim: CGFloat = 448
                        let longest = max(uiImage.size.width, uiImage.size.height)
                        let inferenceImage: UIImage
                        if longest > maxDim {
                            let scale = maxDim / longest
                            let sz = CGSize(
                                width:  (uiImage.size.width  * scale).rounded(),
                                height: (uiImage.size.height * scale).rounded()
                            )
                            inferenceImage = uiImage.preparingThumbnail(of: sz) ?? uiImage
                        } else {
                            inferenceImage = uiImage
                        }
                        guard let ci = CIImage(image: inferenceImage) else {
                            throw MLXModelError.invocationFailed("Failed to convert image to CIImage")
                        }
                        return ci
                    }()

                    let localizedPrompt = LocalizedPrompts(language: language)
                        .buildImagingPrompt(imageContext: "Medical imaging scan")
                    let finalPrompt = prompt.isEmpty ? localizedPrompt : prompt

                    var userInput: UserInput? = UserInput(
                        prompt: finalPrompt,
                        images: [.ciImage(ciImage)]
                    )
                    let parameters = GenerateParameters(maxTokens: maxTokens, temperature: temperature)

                    try await container.perform { [userInput] context in
                        guard let ui = userInput else {
                            throw MLXModelError.invocationFailed("UserInput was unexpectedly nil")
                        }
                        let lmInput = try await context.processor.prepare(input: ui)
                        MLX.eval(lmInput.text.tokens)
                        if let img = lmInput.image { MLX.eval(img.pixels) }
                        MLX.GPU.clearCache()
                        var detokenizer = NaiveStreamingDetokenizer(tokenizer: context.tokenizer)
                        var stepCount = 0
                        _ = try generate(
                            input: lmInput,
                            parameters: parameters,
                            context: context
                        ) { (tokens: [Int]) in
                            stepCount += 1
                            if stepCount % 32 == 0 { MLX.GPU.clearCache() }
                            if let last = tokens.last {
                                detokenizer.append(token: last)
                                if let piece = detokenizer.next() {
                                    continuation.yield(piece)
                                }
                            }
                            return .more
                        }
                    }
                    userInput = nil  // free CIImage reference after inference

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        #endif
    }

    // MARK: - Text-Only Inference (SOAP notes, no image)

    /// Generate a text-only response — used for SOAP note generation where no image is involved.
    func generateText(
        prompt: String,
        maxTokens: Int = 384,
        temperature: Float = 0.3
    ) async throws -> String {
        #if targetEnvironment(simulator)
        return simulatorSOAPPlaceholderJSON()

        #else
        guard let container = modelContainer else {
            throw MLXModelError.modelNotLoaded
        }

        let userInput = UserInput(prompt: prompt, images: [])
        let parameters = GenerateParameters(maxTokens: maxTokens, temperature: temperature)

        do {
            #if DEBUG
            print("🧠 [SOAP inference start] app memory: \(memMB())")
            #endif
            MLX.GPU.set(cacheLimit: 0)
            MLX.GPU.clearCache()

            let result = try await container.perform { context in
                let lmInput = try await context.processor.prepare(input: userInput)
                MLX.eval(lmInput.text.tokens)
                MLX.GPU.clearCache()
                #if DEBUG
                print("🧠 [SOAP after prepare+clearCache] app memory: \(self.memMB())")
                #endif
                // Second clearCache immediately before generate loop —
                // eval may have left lazy computation nodes in the graph.
                MLX.GPU.clearCache()
                var stepCount = 0
                return try generate(
                    input: lmInput,
                    parameters: parameters,
                    context: context
                ) { (_: [Int]) in
                    stepCount += 1
                    if stepCount % 32 == 0 {
                        #if DEBUG
                        print("🧠 [SOAP token \(stepCount)] app memory: \(self.memMB())")
                        #endif
                        MLX.GPU.clearCache()
                    }
                    return .more
                }
            }

            MLX.GPU.set(cacheLimit: 64 * 1024 * 1024)
            #if DEBUG
            print("🧠 [SOAP inference done] app memory: \(self.memMB())")
            #endif
            return result.output
        } catch let error as MLXModelError {
            throw error
        } catch {
            throw MLXModelError.invocationFailed(error.localizedDescription)
        }
        #endif
    }

    /// Streaming text-only response — used for streaming SOAP note generation.
    func generateTextStreaming(
        prompt: String,
        maxTokens: Int = 384,
        temperature: Float = 0.3
    ) -> AsyncThrowingStream<String, Error> {
        #if targetEnvironment(simulator)
        return AsyncThrowingStream { continuation in
            Task {
                let json = simulatorSOAPPlaceholderJSON()
                for char in json {
                    try await Task.sleep(nanoseconds: 5_000_000)
                    continuation.yield(String(char))
                }
                continuation.finish()
            }
        }

        #else
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let container = self.modelContainer else {
                        throw MLXModelError.modelNotLoaded
                    }
                    let userInput = UserInput(prompt: prompt, images: [])
                    let parameters = GenerateParameters(maxTokens: maxTokens, temperature: temperature)

                    try await container.perform { context in
                        let lmInput = try await context.processor.prepare(input: userInput)
                        MLX.eval(lmInput.text.tokens)
                        MLX.GPU.clearCache()
                        var detokenizer = NaiveStreamingDetokenizer(tokenizer: context.tokenizer)
                        var stepCount = 0
                        _ = try generate(
                            input: lmInput,
                            parameters: parameters,
                            context: context
                        ) { (tokens: [Int]) in
                            stepCount += 1
                            if stepCount % 32 == 0 { MLX.GPU.clearCache() }
                            if let last = tokens.last {
                                detokenizer.append(token: last)
                                if let piece = detokenizer.next() {
                                    continuation.yield(piece)
                                }
                            }
                            return .more
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        #endif
    }

    // MARK: - Private

    /// Placeholder SOAP JSON for simulator builds — valid schema for SOAPNoteParser.
    private func simulatorSOAPPlaceholderJSON() -> String {
        """
        {
          "subjective": {
            "chief_complaint": "Simulator placeholder — on-device inference unavailable",
            "history_of_present_illness": "This is a fixed placeholder returned on simulator builds. Real generation requires a physical device.",
            "past_medical_history": null,
            "medications": null,
            "allergies": null
          },
          "objective": {
            "vital_signs": {
              "temperature": null,
              "heart_rate": null,
              "respiratory_rate": null,
              "systolic_bp": null,
              "diastolic_bp": null,
              "oxygen_saturation": null,
              "recorded_at": null
            },
            "physical_exam_findings": null,
            "diagnostic_results": null
          },
          "assessment": {
            "clinical_impression": "Simulator build — no clinical impression available.",
            "differential_considerations": null,
            "problem_list": null
          },
          "plan": {
            "interventions": null,
            "follow_up": null,
            "patient_education": null,
            "referrals": null
          }
        }
        """
    }

    /// Correctly-structured placeholder JSON for simulator builds.
    /// Uses the exact schema expected by FindingsValidator / ImagingFindingsSummary.
    private func simulatorPlaceholderJSON() -> String {
        """
        {
          "image_type": "Simulator placeholder — MLX inference unavailable",
          "image_quality": "N/A (simulator build; no real image was processed)",
          "anatomical_observations": {
            "note": ["Real inference requires a physical device. This is a fixed placeholder."]
          },
          "comparison_with_prior": "No prior image available for comparison.",
          "areas_highlighted": "No highlighted areas provided.",
          "limitations": "\(FindingsValidator.limitationsConst)"
        }
        """
    }
}
