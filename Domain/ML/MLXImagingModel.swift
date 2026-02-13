//
//  MLXImagingModel.swift
//  MediScribe
//
//  Real MLX-based implementation of imaging findings generator
//

import Foundation

/// MLX-based imaging model for findings extraction
class MLXImagingModel: ImagingModelProtocol {

    // MARK: - ImagingModelProtocol Properties

    var modelName: String { "MedGemma 1.5 4B (MLX)" }
    var modelVersion: String { "1.5" }
    var isLoaded: Bool { MLXMedGemmaBridge.shared.isModelLoaded }
    var estimatedMemoryUsage: Int64 { 4_000_000_000 } // ~4GB (4-bit quantized)

    // MARK: - Initialization

    init() {}

    // MARK: - ImagingModelProtocol Methods

    func loadModel() async throws {
        guard !isLoaded else { return }
        guard let modelPath = MLXModelLoader.shared.currentModelPath else {
            throw ImagingModelError.modelNotLoaded
        }
        do {
            try await MLXMedGemmaBridge.shared.loadModel(from: modelPath)
        } catch {
            print("❌ MLXMedGemmaBridge load error: \(error)")
            throw error
        }
    }

    func unloadModel() {
        MLXMedGemmaBridge.shared.unloadModel()
    }

    func generateFindings(
        from imageData: Data,
        options: InferenceOptions? = nil
    ) async throws -> ImagingInferenceResult {
        // Ensure model is loaded
        guard isLoaded else {
            throw ImagingModelError.modelNotLoaded
        }

        let opts = options ?? InferenceOptions(
            timeout: 60.0,
            temperature: 0.2,
            maxTokens: 1024,
            systemPrompt: nil,
            language: .english
        )

        // Build image context for vision-language inference
        let imageContext = "Medical imaging scan provided for analysis"

        // Note: Prompt is built by the caller (view layer) using LocalizedPrompts
        // The prompt is passed via systemPrompt field, or build it here with a default
        let localizedPrompts = LocalizedPrompts(language: opts.language)
        let prompt = opts.systemPrompt ?? localizedPrompts.buildImagingPrompt(imageContext: imageContext)

        // Run inference with image via MLXMedGemmaBridge (MLXVLM on device, placeholder on simulator)
        do {
            let startTime = Date()
            let responseText = try await MLXMedGemmaBridge.shared.generateFindings(
                from: imageData,
                prompt: prompt,
                maxTokens: opts.maxTokens,
                temperature: opts.temperature,
                language: opts.language
            )
            let processingTime = Date().timeIntervalSince(startTime)

            // Extract the JSON object from raw model output.
            // MedGemma may prepend explanation text or wrap output in markdown
            // code fences (```json ... ```) — extractJSON strips those.
            let jsonText = MLXImagingModel.extractJSON(from: responseText)
            #if DEBUG
            print("🔍 Raw model output (\(responseText.count) chars):\n\(responseText.prefix(500))")
            print("🔍 Extracted JSON (\(jsonText.count) chars):\n\(jsonText.prefix(500))")
            #endif

            guard let responseData = jsonText.data(using: String.Encoding.utf8) else {
                throw ImagingModelError.invalidModelOutput
            }

            // Validate response through language-aware safety validator
            let validatedFindings = try FindingsValidator.decodeAndValidate(
                responseData,
                language: opts.language
            )

            // Re-encode validated findings to JSON
            let encoder = JSONEncoder()
            let findingsJSONData = try encoder.encode(validatedFindings)
            guard let findingsJSON = String(data: findingsJSONData, encoding: String.Encoding.utf8) else {
                throw ImagingModelError.invalidModelOutput
            }

            return ImagingInferenceResult(
                findingsJSON: findingsJSON,
                processingTime: processingTime,
                modelVersion: modelVersion
            )

        } catch let error as ImagingModelError {
            throw error
        } catch let error as FindingsValidationError {
            // Propagate so ImagingGenerateView can show a specific "blocked output" message
            throw error
        } catch let error as MLXModelError {
            print("❌ MLXImagingModel MLX error: \(error)")
            throw ImagingModelError.inferenceFailed
        } catch {
            print("❌ MLXImagingModel unexpected error: \(error)")
            throw ImagingModelError.inferenceFailed
        }
    }

    // MARK: - Private

    /// Extracts the first balanced JSON object from raw model output.
    /// Handles markdown code fences (```json ... ```) and any preamble text.
    private static func extractJSON(from text: String) -> String {
        var source = text

        // Strip markdown code fences
        if let fenceStart = source.range(of: "```json"),
           let fenceEnd = source.range(of: "```", range: fenceStart.upperBound..<source.endIndex) {
            source = String(source[fenceStart.upperBound..<fenceEnd.lowerBound])
        } else if let fenceStart = source.range(of: "```"),
                  let fenceEnd = source.range(of: "```", range: fenceStart.upperBound..<source.endIndex) {
            source = String(source[fenceStart.upperBound..<fenceEnd.lowerBound])
        }

        // Find and extract the outermost balanced { } object
        guard let startIdx = source.firstIndex(of: "{") else {
            return source.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var depth = 0
        var inString = false
        var escape = false

        for idx in source.indices[startIdx...] {
            let ch = source[idx]
            if escape { escape = false; continue }
            if ch == "\\" && inString { escape = true; continue }
            if ch == "\"" { inString.toggle(); continue }
            if !inString {
                if ch == "{" { depth += 1 }
                else if ch == "}" {
                    depth -= 1
                    if depth == 0 {
                        return String(source[startIdx...idx])
                    }
                }
            }
        }

        // Truncated JSON — return whatever we found from the first brace
        return String(source[startIdx...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
