//
//  PlaceholderImagingModel.swift
//  MediScribe
//
//  Placeholder model that generates fixed test data
//  Used during development until real model is integrated
//

import Foundation
import UIKit

/// Placeholder model for testing workflow without real ML
class PlaceholderImagingModel: ImagingModelProtocol {
    var modelName: String { "Placeholder (Test)" }
    var modelVersion: String { "0.1.0-dev" }
    var isLoaded: Bool { true } // Always "loaded" since it's just placeholder
    var estimatedMemoryUsage: Int64 { 1024 } // Negligible

    func loadModel() async throws {
        // No-op for placeholder
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds fake load time
    }

    func unloadModel() {
        // No-op for placeholder
    }

    func generateFindings(from imageData: Data, options: InferenceOptions?) async throws -> ImagingInferenceResult {
        let startTime = Date()

        // Simulate processing time (0.5 - 1.5 seconds)
        let processingDelay = TimeInterval.random(in: 0.5...1.5)
        try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))

        // Validate image data
        guard UIImage(data: imageData) != nil else {
            throw ImagingModelError.invalidImageData
        }

        // Generate placeholder JSON
        let json = """
        {
          "image_type": "Clinical Image (view not specified)",
          "image_quality": "Image quality not specified.",
          "anatomical_observations": {
            "lungs": ["Lung fields appear symmetric."],
            "pleural_regions": ["No clearly visible pleural fluid is observed."],
            "cardiomediastinal_silhouette": ["Cardiomediastinal contours appear within expected visual limits."],
            "bones_and_soft_tissues": ["No obvious displacement is visible in the ribs."]
          },
          "comparison_with_prior": "No prior image available for comparison.",
          "areas_highlighted": "No highlighted areas provided.",
          "limitations": "\(FindingsValidator.limitationsConst)"
        }
        """

        let processingTime = Date().timeIntervalSince(startTime)

        return ImagingInferenceResult(
            findingsJSON: json,
            processingTime: processingTime,
            modelVersion: modelVersion
        )
    }
}
