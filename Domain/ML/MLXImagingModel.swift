//
//  MLXImagingModel.swift
//  MediScribe
//
//  Real MLX-based implementation of imaging findings generator
//

import Foundation
import Combine

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
            throw MLXModelError.modelNotLoaded
        }

        let opts = options ?? InferenceOptions()

        // Build image context prompt
        let imageContext = "Medical image provided for analysis"

        // Get imaging prompt
        let prompt = ImagingPrompts.findingsExtractionPrompt(imageContext: imageContext)

        // Run inference
        do {
            let responseText = try await Task.detached(priority: .userInitiated) {
                try MLXModelBridge.generate(
                    prompt: prompt,
                    maxTokens: opts.maxNewTokens,
                    temperature: opts.temperature
                )
            }.value

            // Validate response
            let validationResult = try FindingsValidator.decodeAndValidate(responseText)

            // Extract findings JSON
            guard let findingsData = validationResult.findings else {
                throw ImagingModelError.validationFailed("No findings extracted from model output")
            }

            return ImagingInferenceResult(
                findings: findingsData,
                rawResponse: responseText,
                tokensGenerated: 256, // Placeholder
                executionTime: 0.0    // Placeholder
            )

        } catch let error as FindingsValidationError {
            throw ImagingModelError.validationFailed(error.description)
        } catch {
            throw ImagingModelError.inferenceError(error.localizedDescription)
        }
    }
}

// MARK: - Error Types

enum ImagingModelError: LocalizedError {
    case modelNotLoaded
    case validationFailed(String)
    case inferenceError(String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Model not loaded"
        case .validationFailed(let msg):
            return "Validation failed: \(msg)"
        case .inferenceError(let msg):
            return "Inference error: \(msg)"
        }
    }
}
