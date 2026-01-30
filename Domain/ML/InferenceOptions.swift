//
//  InferenceOptions.swift
//  MediScribe
//
//  Configuration for model inference
//

import Foundation

/// Options for model inference
struct InferenceOptions: Codable {
    /// Maximum number of tokens to generate
    let maxTokens: Int

    /// Sampling temperature (0.0-2.0)
    /// Lower values = more deterministic, higher = more creative
    let temperature: Float

    /// Top-p (nucleus) sampling parameter
    let topP: Float

    /// Top-k sampling parameter
    let topK: Int

    /// Number of generation contexts to keep (for batching)
    let numContexts: Int

    /// Whether to use deterministic greedy decoding
    let greedyDecoding: Bool

    // MARK: - Initialization

    init(
        maxTokens: Int = 1024,
        temperature: Float = 0.3,
        topP: Float = 0.9,
        topK: Int = 40,
        numContexts: Int = 1,
        greedyDecoding: Bool = false
    ) {
        self.maxTokens = maxTokens
        self.temperature = max(0.0, min(2.0, temperature)) // Clamp to valid range
        self.topP = max(0.0, min(1.0, topP))
        self.topK = max(0, topK)
        self.numContexts = max(1, numContexts)
        self.greedyDecoding = greedyDecoding
    }

    /// Default options for SOAP note generation (deterministic)
    static var soapGeneration: InferenceOptions {
        InferenceOptions(
            maxTokens: 2048,
            temperature: 0.3,
            topP: 0.95,
            topK: 50,
            greedyDecoding: false
        )
    }

    /// Default options for imaging findings (deterministic)
    static var imagingFindings: InferenceOptions {
        InferenceOptions(
            maxTokens: 1024,
            temperature: 0.2,
            topP: 0.9,
            topK: 40,
            greedyDecoding: false
        )
    }

    /// Default options for lab results extraction (deterministic)
    static var labResults: InferenceOptions {
        InferenceOptions(
            maxTokens: 1536,
            temperature: 0.1,
            topP: 0.85,
            topK: 30,
            greedyDecoding: false
        )
    }

    /// Strict/safe options (minimal variation)
    static var strict: InferenceOptions {
        InferenceOptions(
            maxTokens: 512,
            temperature: 0.0,
            topP: 0.8,
            topK: 20,
            greedyDecoding: true
        )
    }
}

/// Result of a document processing operation
struct DocumentProcessingResult: Codable {
    let jsonOutput: String
    let processingTime: TimeInterval
    let modelVersion: String
    let documentType: String

    enum CodingKeys: String, CodingKey {
        case jsonOutput = "json_output"
        case processingTime = "processing_time"
        case modelVersion = "model_version"
        case documentType = "document_type"
    }
}

/// Result of imaging inference
struct ImagingInferenceResult: Codable {
    let findingsJSON: String
    let processingTime: TimeInterval
    let modelVersion: String

    enum CodingKeys: String, CodingKey {
        case findingsJSON = "findings_json"
        case processingTime = "processing_time"
        case modelVersion = "model_version"
    }
}
