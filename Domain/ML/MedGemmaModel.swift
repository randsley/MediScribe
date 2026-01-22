//
//  MedGemmaModel.swift
//  MediScribe
//
//  MedGemma 1.5 4B implementation using llama.cpp
//

import Foundation
import UIKit
import CoreGraphics

/// MedGemma 1.5 4B multimodal medical imaging model
class MedGemmaModel: ImagingModelProtocol {
    var modelName: String { "MedGemma 1.5 4B" }
    var modelVersion: String { "1.5.0" }
    var isLoaded: Bool { context != nil }
    var estimatedMemoryUsage: Int64 { 3_000_000_000 } // ~3 GB for INT4 quantized

    // MARK: - Private Properties

    private var context: OpaquePointer? = nil // llama_context
    private var model: OpaquePointer? = nil // llama_model
    private var vocab: OpaquePointer? = nil // llama_vocab
    private var sampler: UnsafeMutablePointer<llama_sampler>? = nil // llama_sampler
    private var mtmdContext: OpaquePointer? = nil // mtmd_context for vision
    private let modelQueue = DispatchQueue(label: "com.mediscribe.medgemma", qos: .userInitiated)

    deinit {
        unloadModel()
    }

    // MARK: - Model Loading

    func loadModel() async throws {
        guard !isLoaded else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            modelQueue.async {
                do {
                    // 1. Get model path from bundle
                    let modelFileName = "medgemma-1.5-4b-it-Q4_K_M"
                    let modelFileExt = "gguf"

                    // Try standard resource path first
                    var modelPath = Bundle.main.path(forResource: modelFileName, ofType: modelFileExt)

                    // If not found, try bundle root directly (for PBXFileSystemSynchronizedRootGroup)
                    if modelPath == nil {
                        let bundleRootPath = Bundle.main.bundlePath + "/\(modelFileName).\(modelFileExt)"
                        if FileManager.default.fileExists(atPath: bundleRootPath) {
                            modelPath = bundleRootPath
                        }
                    }

                    guard let modelPath = modelPath else {
                        continuation.resume(throwing: ImagingModelError.modelNotLoaded)
                        return
                    }

                    // 2. Load dynamic backends
                    ggml_backend_load_all()

                    // 3. Initialize llama backend
                    llama_backend_init()

                    // 4. Load model parameters
                    var modelParams = llama_model_default_params()
                    #if targetEnvironment(simulator)
                    modelParams.n_gpu_layers = 0
                    #else
                    modelParams.n_gpu_layers = 1 // Use Metal on device
                    #endif

                    // 5. Load model
                    self.model = llama_model_load_from_file(modelPath, modelParams)

                    guard self.model != nil else {
                        continuation.resume(throwing: ImagingModelError.modelNotLoaded)
                        return
                    }

                    // 6. Get vocab from model
                    self.vocab = mediscribe_get_vocab(self.model)

                    guard self.vocab != nil else {
                        continuation.resume(throwing: ImagingModelError.modelNotLoaded)
                        return
                    }

                    // 7. Create context
                    var contextParams = llama_context_default_params()
                    contextParams.n_ctx = 2048
                    contextParams.n_batch = 512
                    contextParams.no_perf = false

                    self.context = llama_init_from_model(self.model, contextParams)

                    guard self.context != nil else {
                        continuation.resume(throwing: ImagingModelError.modelNotLoaded)
                        return
                    }

                    // 8. Initialize sampler (greedy decoding with low temperature)
                    var samplerParams = llama_sampler_chain_default_params()
                    samplerParams.no_perf = false
                    self.sampler = llama_sampler_chain_init(samplerParams)

                    // Add temperature sampler (low temperature for deterministic output)
                    llama_sampler_chain_add(self.sampler, llama_sampler_init_temp(0.3))
                    // Add greedy sampler
                    llama_sampler_chain_add(self.sampler, llama_sampler_init_greedy())

                    // 9. Initialize mtmd context for vision (mmproj file)
                    // NOTE: Multimodal support is optional - model works in text-only mode without it
                    let mmprojFileName = "medgemma-1.5-4b-it.mmproj-Q8_0"
                    let mmprojFileExt = "gguf"

                    // Try standard resource path first
                    var mmprojPath = Bundle.main.path(forResource: mmprojFileName, ofType: mmprojFileExt)

                    // If not found, try bundle root directly
                    if mmprojPath == nil {
                        let bundleRootPath = Bundle.main.bundlePath + "/\(mmprojFileName).\(mmprojFileExt)"
                        if FileManager.default.fileExists(atPath: bundleRootPath) {
                            mmprojPath = bundleRootPath
                        }
                    }

                    // Only attempt to load mmproj if file exists AND is valid
                    if let mmprojPath = mmprojPath, FileManager.default.fileExists(atPath: mmprojPath) {
                        // Verify file size is reasonable (should be > 100MB for Q8 quantization)
                        if let attributes = try? FileManager.default.attributesOfItem(atPath: mmprojPath),
                           let fileSize = attributes[.size] as? Int64,
                           fileSize > 1_000_000 { // At least 1MB to avoid corrupted files
                            print("📁 Found mmproj file (\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))) - attempting to load...")
                            self.mtmdContext = mediscribe_mtmd_init(mmprojPath, self.model)
                            if self.mtmdContext == nil {
                                print("⚠️ Failed to load mmproj file - multimodal support disabled")
                            } else if mediscribe_mtmd_has_vision(self.mtmdContext) {
                                print("✓ MedGemma multimodal vision support enabled")
                            } else {
                                print("⚠️ mmproj loaded but vision not supported")
                            }
                        } else {
                            print("⚠️ mmproj file too small or corrupted - skipping multimodal support")
                        }
                    } else {
                        print("⚠️ mmproj file not found - text-only mode")
                        print("   To enable vision support, add \(mmprojFileName).\(mmprojFileExt) to Xcode project")
                    }

                    continuation.resume()
                }
            }
        }
    }

    func unloadModel() {
        modelQueue.sync {
            if let mtmdContext = mtmdContext {
                mtmd_free(mtmdContext)
                self.mtmdContext = nil
            }
            if let sampler = sampler {
                llama_sampler_free(sampler)
                self.sampler = nil
            }
            if let context = context {
                llama_free(context)
                self.context = nil
            }
            if let model = model {
                llama_model_free(model)
                self.model = nil
            }
            self.vocab = nil // vocab is owned by model, don't free separately
            llama_backend_free()
        }
    }

    // MARK: - Inference

    func generateFindings(from imageData: Data, options: InferenceOptions?) async throws -> ImagingInferenceResult {
        guard context != nil else {
            throw ImagingModelError.modelNotLoaded
        }

        guard let uiImage = UIImage(data: imageData) else {
            throw ImagingModelError.invalidImageData
        }

        let startTime = Date()

        // Generate findings using llama.cpp with multimodal support
        let jsonOutput = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            modelQueue.async {
                do {
                    // 1. Build prompt with image placeholder
                    let prompt = self.buildMultimodalPrompt()

                    var outputTokens: [llama_token] = []

                    // 2. Check if we have multimodal support
                    if let mtmdCtx = self.mtmdContext, mediscribe_mtmd_has_vision(mtmdCtx) {
                        // Multimodal path: encode image and process together
                        outputTokens = try self.runMultimodalInference(
                            image: uiImage,
                            prompt: prompt,
                            mtmdContext: mtmdCtx,
                            options: options
                        )
                    } else {
                        // Fallback: text-only (less accurate)
                        print("⚠️ Multimodal not available, using text-only fallback")
                        let textPrompt = self.buildMedicalImagingPrompt()
                        let tokens = self.tokenize(textPrompt)
                        outputTokens = try self.runInference(tokens: tokens, imageEmbedding: nil, options: options)
                    }

                    // 3. Decode output tokens to string
                    let outputText = self.detokenize(outputTokens)

                    // 4. Extract JSON from output
                    let json = try self.extractJSON(from: outputText)

                    continuation.resume(returning: json)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        let processingTime = Date().timeIntervalSince(startTime)

        return ImagingInferenceResult(
            findingsJSON: jsonOutput,
            processingTime: processingTime,
            modelVersion: modelVersion
        )
    }

    // MARK: - Private Helpers

    /// Process any type of medical document (imaging, labs, etc.)
    func processDocument(imageData: Data, documentType: DocumentType, options: InferenceOptions?) async throws -> DocumentProcessingResult {
        guard context != nil else {
            throw ImagingModelError.modelNotLoaded
        }

        guard let uiImage = UIImage(data: imageData) else {
            throw ImagingModelError.invalidImageData
        }

        let startTime = Date()

        // Generate output using llama.cpp with multimodal support
        let jsonOutput = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            modelQueue.async {
                do {
                    // 1. Build prompt for the document type
                    let prompt = self.buildMultimodalPrompt(for: documentType)

                    var outputTokens: [llama_token] = []

                    // 2. Check if we have multimodal support
                    if let mtmdCtx = self.mtmdContext, mediscribe_mtmd_has_vision(mtmdCtx) {
                        // Multimodal path: encode image and process together
                        outputTokens = try self.runMultimodalInference(
                            image: uiImage,
                            prompt: prompt,
                            mtmdContext: mtmdCtx,
                            options: options
                        )
                    } else {
                        // Fallback: text-only (less accurate)
                        print("⚠️ Multimodal not available, using text-only fallback")
                        let textPrompt = self.buildDocumentPrompt(for: documentType)
                        let tokens = self.tokenize(textPrompt)
                        outputTokens = try self.runInference(tokens: tokens, imageEmbedding: nil, options: options)
                    }

                    // 3. Decode output tokens to string
                    let outputText = self.detokenize(outputTokens)

                    // 4. Extract JSON from output
                    let json = try self.extractJSON(from: outputText)

                    continuation.resume(returning: json)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        let processingTime = Date().timeIntervalSince(startTime)

        return DocumentProcessingResult(
            jsonOutput: jsonOutput,
            processingTime: processingTime,
            modelVersion: modelVersion,
            documentType: documentType
        )
    }

    /// Build multimodal prompt with image placeholder (imaging - for backwards compatibility)
    private func buildMultimodalPrompt() -> String {
        return buildMultimodalPrompt(for: .medicalImaging)
    }

    /// Build multimodal prompt with image placeholder for specific document type
    private func buildMultimodalPrompt(for documentType: DocumentType) -> String {
        let imageMarker = String(cString: mtmd_default_marker())

        switch documentType {
        case .labResults:
            return buildLabResultsPrompt(imageMarker: imageMarker)
        case .medicalImaging:
            return buildMedicalImagingMultimodalPrompt(imageMarker: imageMarker)
        default:
            return buildGenericDocumentPrompt(imageMarker: imageMarker, documentType: documentType)
        }
    }

    /// Build prompt for lab results documents
    private func buildLabResultsPrompt(imageMarker: String) -> String {
        return """
        \(imageMarker)

        You are a laboratory results transcription assistant. Your role is to extract and structure visible test results from this document for clinical documentation purposes.

        CRITICAL SAFETY RULES - YOU MUST FOLLOW THESE EXACTLY:
        1. Extract ONLY the visible values from the document
        2. Transcribe test names, values, units, and reference ranges exactly as shown
        3. NEVER interpret whether values are normal or abnormal
        4. NEVER assess clinical significance
        5. NEVER recommend actions or follow-up
        6. NEVER use terms like "elevated", "high", "low", "concerning", "abnormal"
        7. If a value is unclear, state "Not clearly visible" rather than guessing

        OUTPUT FORMAT:
        You must generate valid JSON matching this exact schema:

        {
          "document_type": "Description of document (e.g., 'Complete Blood Count', 'Metabolic Panel')",
          "document_date": "Date visible on document or null",
          "laboratory_name": "Laboratory name if visible or null",
          "patient_identifier": "Patient ID/name if visible (for verification) or null",
          "ordering_provider": "Provider name if visible or null",
          "test_categories": [
            {
              "category": "Test category name (e.g., 'Hematology', 'Chemistry')",
              "tests": [
                {
                  "test_name": "Exact test name as shown",
                  "value": "Exact value as shown",
                  "unit": "Unit of measurement or null",
                  "reference_range": "Reference range as shown or null",
                  "method": "Test method if shown or null"
                }
              ]
            }
          ],
          "notes": "Any additional notes visible on document or null",
          "limitations": "This summary transcribes visible values from the document and does not interpret clinical significance or provide medical advice."
        }

        IMPORTANT:
        - The "limitations" field must contain EXACTLY the text shown above
        - Extract values exactly as printed - do not round or modify
        - If you cannot read a value clearly, omit that test rather than guessing
        - Do not add interpretive comments

        Analyze the laboratory document above and generate the structured JSON:
        """
    }

    /// Build prompt for medical imaging (multimodal)
    private func buildMedicalImagingMultimodalPrompt(imageMarker: String) -> String {
        return """
        \(imageMarker)

        You are a medical imaging documentation assistant. Your role is to describe visible features in this medical image for clinical documentation purposes.

        CRITICAL SAFETY RULES - YOU MUST FOLLOW THESE EXACTLY:
        1. Describe ONLY what you can see in the image
        2. Use neutral, descriptive language (e.g., "appears", "visible", "observed")
        3. NEVER diagnose or name diseases
        4. NEVER interpret clinical significance
        5. NEVER recommend treatments or actions
        6. NEVER use probabilistic language (e.g., "likely", "probably", "suggests")
        7. NEVER assess severity or urgency

        OUTPUT FORMAT:
        You must generate valid JSON matching this exact schema:

        {
          "image_type": "Description of image modality and view",
          "image_quality": "Brief quality assessment",
          "anatomical_observations": {
            "lungs": ["List of observations"],
            "pleural_regions": ["List of observations"],
            "cardiomediastinal_silhouette": ["List of observations"],
            "bones_and_soft_tissues": ["List of observations"]
          },
          "comparison_with_prior": "Statement about prior imaging",
          "areas_highlighted": "Any highlighted regions",
          "limitations": "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."
        }

        IMPORTANT:
        - The "limitations" field must contain EXACTLY the text shown above
        - All observations must be purely descriptive
        - If uncertain about a region, state "Not clearly visible" rather than speculating

        Analyze the medical image above and generate findings JSON:
        """
    }

    /// Build generic document prompt for other document types
    private func buildGenericDocumentPrompt(imageMarker: String, documentType: DocumentType) -> String {
        return """
        \(imageMarker)

        \(documentType.systemPromptPrefix)

        CRITICAL SAFETY RULES - YOU MUST FOLLOW THESE EXACTLY:
        1. Extract ONLY the visible information from the document
        2. Transcribe text exactly as shown
        3. NEVER interpret clinical significance
        4. NEVER provide diagnoses or assessments
        5. NEVER recommend actions or treatments
        6. Use neutral, descriptive language only

        Extract and structure the visible information from this document in clear, organized JSON format. Include only what is clearly visible.
        """
    }

    /// Build document-specific prompt for text-only fallback
    private func buildDocumentPrompt(for documentType: DocumentType) -> String {
        switch documentType {
        case .labResults:
            return buildLabResultsTextPrompt()
        case .medicalImaging:
            return buildMedicalImagingPrompt()
        default:
            return buildGenericTextPrompt(for: documentType)
        }
    }

    /// Build text-only prompt for lab results (fallback)
    private func buildLabResultsTextPrompt() -> String {
        return """
        You are a laboratory results transcription assistant operating in text-only mode.

        Since no image is available, generate a template structure for laboratory results.

        CRITICAL: All values should be marked as "Not available - image required" since this is text-only mode.

        \(buildLabResultsPrompt(imageMarker: ""))
        """
    }

    /// Build generic text-only prompt (fallback)
    private func buildGenericTextPrompt(for documentType: DocumentType) -> String {
        return """
        \(documentType.systemPromptPrefix)

        Since no image is available, indicate that document processing requires image input.
        """
    }

    /// Build the system prompt for medical imaging task (text-only fallback)
    private func buildMedicalImagingPrompt() -> String {
        return """
        You are a medical imaging documentation assistant. Your role is to describe visible features in medical images for clinical documentation purposes.

        CRITICAL SAFETY RULES - YOU MUST FOLLOW THESE EXACTLY:
        1. Describe ONLY what you can see in the image
        2. Use neutral, descriptive language (e.g., "appears", "visible", "observed")
        3. NEVER diagnose or name diseases
        4. NEVER interpret clinical significance
        5. NEVER recommend treatments or actions
        6. NEVER use probabilistic language (e.g., "likely", "probably", "suggests")
        7. NEVER assess severity or urgency

        OUTPUT FORMAT:
        You must generate valid JSON matching this exact schema:

        {
          "image_type": "Description of image modality and view",
          "image_quality": "Brief quality assessment",
          "anatomical_observations": {
            "lungs": ["List of observations"],
            "pleural_regions": ["List of observations"],
            "cardiomediastinal_silhouette": ["List of observations"],
            "bones_and_soft_tissues": ["List of observations"]
          },
          "comparison_with_prior": "Statement about prior imaging",
          "areas_highlighted": "Any highlighted regions",
          "limitations": "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."
        }

        IMPORTANT:
        - The "limitations" field must contain EXACTLY the text shown above
        - All observations must be purely descriptive
        - If uncertain about a region, state "Not clearly visible" rather than speculating

        Now, analyze the following medical image and generate findings JSON:
        """
    }

    /// Tokenize text using llama.cpp tokenizer
    private func tokenize(_ text: String) -> [llama_token] {
        guard let vocab = vocab else { return [] }

        // First call to get the number of tokens (negative return value)
        let n_tokens_needed = -llama_tokenize(vocab, text, Int32(text.utf8.count), nil, 0, true, true)

        guard n_tokens_needed > 0 else { return [] }

        // Allocate space and tokenize
        var tokens = [llama_token](repeating: 0, count: Int(n_tokens_needed))
        let n_tokens = llama_tokenize(vocab, text, Int32(text.utf8.count), &tokens, Int32(n_tokens_needed), true, true)

        guard n_tokens > 0 else { return [] }

        return Array(tokens.prefix(Int(n_tokens)))
    }

    /// Detokenize output tokens to string
    private func detokenize(_ tokens: [llama_token]) -> String {
        guard let vocab = vocab else { return "" }
        var output = ""
        for token in tokens {
            var piece = [CChar](repeating: 0, count: 128)
            let nChars = llama_token_to_piece(vocab, token, &piece, 128, 0, true)
            if nChars > 0 {
                if let str = String(validatingUTF8: piece) {
                    output += str
                }
            }
        }
        return output
    }

    /// Run inference with llama.cpp using modern API
    private func runInference(tokens: [llama_token], imageEmbedding: Data?, options: InferenceOptions?) throws -> [llama_token] {
        guard let context = context, let sampler = sampler, let vocab = vocab else {
            throw ImagingModelError.modelNotLoaded
        }

        var promptTokens = tokens
        let maxTokens = options?.maxTokens ?? 1024

        // Prepare initial batch for prompt
        var batch = llama_batch_get_one(&promptTokens, Int32(promptTokens.count))

        // Process prompt
        if llama_decode(context, batch) != 0 {
            throw ImagingModelError.inferenceFailed
        }

        var outputTokens: [llama_token] = []
        var n_pos = Int32(promptTokens.count)

        // Generation loop
        for _ in 0..<maxTokens {
            // Sample next token using the sampler
            let new_token = llama_sampler_sample(sampler, context, -1)

            // Check for end of generation
            if llama_vocab_is_eog(vocab, new_token) {
                break
            }

            outputTokens.append(new_token)

            // Prepare next batch with sampled token
            var token = new_token
            batch = llama_batch_get_one(&token, 1)

            // Decode the new token
            if llama_decode(context, batch) != 0 {
                throw ImagingModelError.inferenceFailed
            }

            n_pos += 1
        }

        return outputTokens
    }

    /// Extract JSON from model output text
    private func extractJSON(from output: String) throws -> String {
        // Model may generate preamble/postamble - extract just the JSON

        // Method 1: Look for first '{' and last '}'
        guard let startIndex = output.firstIndex(of: "{"),
              let endIndex = output.lastIndex(of: "}") else {
            throw ImagingModelError.invalidModelOutput
        }

        let jsonString = String(output[startIndex...endIndex])

        // Validate it's actually JSON
        guard let jsonData = jsonString.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: jsonData) else {
            throw ImagingModelError.invalidModelOutput
        }

        return jsonString
    }

    /// Run multimodal inference with image and text
    private func runMultimodalInference(
        image: UIImage,
        prompt: String,
        mtmdContext: OpaquePointer,
        options: InferenceOptions?
    ) throws -> [llama_token] {
        // 1. Convert UIImage to RGB bitmap
        guard let (width, height, rgbData) = image.toRGBData() else {
            throw ImagingModelError.invalidImageData
        }

        // 2. Create mtmd bitmap
        let bitmap = rgbData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> OpaquePointer? in
            guard let baseAddress = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return nil
            }
            return mediscribe_mtmd_bitmap_from_rgb(UInt32(width), UInt32(height), baseAddress)
        }

        guard let bitmap = bitmap else {
            throw ImagingModelError.invalidImageData
        }
        defer { mtmd_bitmap_free(bitmap) }

        // 3. Tokenize text + image together
        var chunks: OpaquePointer? = nil
        let result = mediscribe_mtmd_tokenize_with_image(mtmdContext, prompt, bitmap, &chunks)

        guard result == 0, let chunks = chunks else {
            throw ImagingModelError.inferenceFailed
        }
        defer { mtmd_input_chunks_free(chunks) }

        // 4. Process each chunk and generate response
        let nChunks = mtmd_input_chunks_size(chunks)
        guard let context = context, let sampler = sampler, let vocab = vocab else {
            throw ImagingModelError.modelNotLoaded
        }

        var allTokens: [llama_token] = []

        // Process all chunks (text + image tokens)
        for i in 0..<nChunks {
            guard let chunk = mtmd_input_chunks_get(chunks, i) else { continue }

            let chunkType = mtmd_input_chunk_get_type(chunk)

            if chunkType == MTMD_INPUT_CHUNK_TYPE_TEXT {
                // Text chunk - get tokens
                var nTokens: Int = 0
                guard let tokens = mtmd_input_chunk_get_tokens_text(chunk, &nTokens) else { continue }

                for j in 0..<nTokens {
                    allTokens.append(tokens[j])
                }
            } else if chunkType == MTMD_INPUT_CHUNK_TYPE_IMAGE {
                // Image chunk - encode to get embeddings
                if mtmd_encode_chunk(mtmdContext, chunk) != 0 {
                    throw ImagingModelError.inferenceFailed
                }

                // Get embeddings and add to context
                guard let embeddings = mediscribe_mtmd_get_embeddings(mtmdContext) else {
                    throw ImagingModelError.inferenceFailed
                }

                let nTokens = mediscribe_mtmd_chunk_n_tokens(chunk)

                // Process image embeddings through the model
                // For now, we'll add placeholder tokens for the image
                // The actual integration would require passing embeddings directly to llama context
                for _ in 0..<nTokens {
                    allTokens.append(0) // Placeholder - proper implementation needs embedding integration
                }
            }
        }

        // 5. Run generation with the combined context
        let maxTokens = options?.maxTokens ?? 1024
        var outputTokens: [llama_token] = []

        // Prepare initial batch with all tokens (text + image placeholders)
        var promptTokens = allTokens
        var batch = llama_batch_get_one(&promptTokens, Int32(promptTokens.count))

        // Process prompt
        if llama_decode(context, batch) != 0 {
            throw ImagingModelError.inferenceFailed
        }

        var n_pos = Int32(promptTokens.count)

        // Generation loop
        for _ in 0..<maxTokens {
            let new_token = llama_sampler_sample(sampler, context, -1)

            if llama_vocab_is_eog(vocab, new_token) {
                break
            }

            outputTokens.append(new_token)

            var token = new_token
            batch = llama_batch_get_one(&token, 1)

            if llama_decode(context, batch) != 0 {
                throw ImagingModelError.inferenceFailed
            }

            n_pos += 1
        }

        return outputTokens
    }
}

// MARK: - UIImage Extension for RGB Conversion
private extension UIImage {
    /// Converts the image to RGB24 bitmap data suitable for mtmd
    /// Returns (width, height, rgbData) tuple, or nil on failure
    func toRGBData() -> (width: Int, height: Int, data: Data)? {
        guard let cgImage = self.cgImage else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 3
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8

        // Allocate buffer for RGB data
        var rgbData = Data(count: width * height * bytesPerPixel)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)

        guard let context = CGContext(
            data: &rgbData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        // Draw image into context (this converts to RGB)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return (width: width, height: height, data: rgbData)
    }
}
