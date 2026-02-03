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
    var isLoaded: Bool { MLXModelLoader.shared.isModelLoaded }
    var estimatedMemoryUsage: Int64 { 2_000_000_000 } // ~2GB

    // MARK: - Initialization

    init() {}

    // MARK: - ImagingModelProtocol Methods

    func loadModel() async throws {
        if !isLoaded {
            try MLXModelLoader.shared.loadModel()
        }
    }

    func unloadModel() {
        MLXModelLoader.shared.unloadModel()
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

        // Run inference with image (true multimodal vision-language)
        do {
            let startTime = Date()
            let responseText = try await MLXModelBridge.generateWithImage(
                imageData: imageData,
                prompt: prompt,
                maxTokens: opts.maxTokens,
                temperature: opts.temperature,
                language: opts.language
            )
            let processingTime = Date().timeIntervalSince(startTime)

            // Convert response to Data for validation
            guard let responseData = responseText.data(using: String.Encoding.utf8) else {
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
        } catch {
            throw ImagingModelError.inferenceFailed
        }
    }
}
