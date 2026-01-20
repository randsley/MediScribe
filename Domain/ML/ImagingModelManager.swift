//
//  ImagingModelManager.swift
//  MediScribe
//
//  Manages model lifecycle and provides singleton access to imaging model
//

import Foundation
import Combine

/// Singleton manager for medical imaging model
@MainActor
class ImagingModelManager: ObservableObject {
    static let shared = ImagingModelManager()

    /// Current model instance
    @Published private(set) var currentModel: ImagingModelProtocol

    /// Whether model is currently loading
    @Published private(set) var isLoading: Bool = false

    /// Last error that occurred
    @Published private(set) var lastError: Error? = nil

    /// Model loading progress (0.0 - 1.0)
    @Published private(set) var loadingProgress: Double = 0.0

    private init() {
        // Start with placeholder model
        // TODO: Replace with MedGemmaModel once integrated
        self.currentModel = PlaceholderImagingModel()

        // Automatically load model on init
        Task {
            try? await loadCurrentModel()
        }
    }

    /// Load the current model into memory
    func loadCurrentModel() async throws {
        guard !currentModel.isLoaded else { return }

        isLoading = true
        lastError = nil
        loadingProgress = 0.0

        do {
            // Simulate progress updates for placeholder
            // Real model would report actual progress
            loadingProgress = 0.3
            try await Task.sleep(nanoseconds: 100_000_000)

            loadingProgress = 0.6
            try await currentModel.loadModel()

            loadingProgress = 1.0
            isLoading = false
        } catch {
            isLoading = false
            lastError = error
            throw error
        }
    }

    /// Unload the current model from memory
    func unloadCurrentModel() {
        currentModel.unloadModel()
    }

    /// Switch to a different model implementation
    /// - Parameter model: New model to use
    func switchModel(to model: ImagingModelProtocol) async throws {
        // Unload current model
        currentModel.unloadModel()

        // Switch to new model
        currentModel = model

        // Load new model
        try await loadCurrentModel()
    }

    /// Generate findings from image using current model
    func generateFindings(from imageData: Data, options: InferenceOptions? = nil) async throws -> ImagingInferenceResult {
        // Ensure model is loaded
        if !currentModel.isLoaded {
            try await loadCurrentModel()
        }

        // Generate findings
        return try await currentModel.generateFindings(from: imageData, options: options)
    }

    /// Get model information string for display
    var modelInfo: String {
        "\(currentModel.modelName) v\(currentModel.modelVersion)"
    }

    /// Get memory usage string for display
    var memoryUsageInfo: String {
        let bytes = currentModel.estimatedMemoryUsage
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .memory)
    }
}
