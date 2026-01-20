//
//  ImagingModelProtocol.swift
//  MediScribe
//
//  Protocol for medical image interpretation models
//  Supports multiple implementations (placeholder, on-device ML, cloud fallback)
//

import Foundation
import UIKit

/// Result from imaging model inference
struct ImagingInferenceResult {
    let findingsJSON: String
    let processingTime: TimeInterval
    let modelVersion: String
}

/// Errors that can occur during model inference
enum ImagingModelError: Error {
    case modelNotLoaded
    case invalidImageData
    case inferenceTimeout
    case invalidModelOutput
    case insufficientMemory
    case unsupportedImageFormat

    var localizedDescription: String {
        switch self {
        case .modelNotLoaded:
            return "Model not loaded. Please restart the app."
        case .invalidImageData:
            return "Invalid image data provided."
        case .inferenceTimeout:
            return "Model inference timed out. Please try again."
        case .invalidModelOutput:
            return "Model produced invalid output."
        case .insufficientMemory:
            return "Insufficient memory to run model. Close other apps and try again."
        case .unsupportedImageFormat:
            return "Unsupported image format. Please use JPEG or PNG."
        }
    }
}

/// Protocol for medical imaging interpretation models
protocol ImagingModelProtocol {
    /// Identifier for this model implementation
    var modelName: String { get }

    /// Version of the model
    var modelVersion: String { get }

    /// Whether the model is currently loaded and ready
    var isLoaded: Bool { get }

    /// Estimated memory usage in bytes
    var estimatedMemoryUsage: Int64 { get }

    /// Load the model into memory
    func loadModel() async throws

    /// Unload the model from memory
    func unloadModel()

    /// Generate findings from an image
    /// - Parameters:
    ///   - imageData: JPEG or PNG image data
    ///   - options: Optional configuration for inference
    /// - Returns: ImagingInferenceResult with JSON findings
    func generateFindings(from imageData: Data, options: InferenceOptions?) async throws -> ImagingInferenceResult
}

/// Options for model inference
struct InferenceOptions {
    /// Maximum time to wait for inference (seconds)
    var timeout: TimeInterval = 60.0

    /// Temperature for generation (0.0 - 1.0, lower is more deterministic)
    var temperature: Float = 0.3

    /// Maximum tokens to generate
    var maxTokens: Int = 1024

    /// Additional context or instructions
    var systemPrompt: String? = nil
}
