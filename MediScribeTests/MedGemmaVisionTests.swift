//
//  MedGemmaVisionTests.swift
//  MediScribeTests
//
//  Tests for MedGemma multimodal vision-language inference
//

import XCTest
import Foundation

@testable import MediScribe

class MedGemmaVisionTests: XCTestCase {

    var imagingModel: MLXImagingModel!

    override func setUp() {
        super.setUp()
        imagingModel = MLXImagingModel()
    }

    override func tearDown() {
        imagingModel = nil
        super.tearDown()
    }

    // MARK: - Model Loading Tests

    /// Test 1: Verify MLXMedGemmaBridge is accessible
    func testMLXMedGemmaBridgeAccessible() {
        let bridge = MLXMedGemmaBridge.shared
        XCTAssertNotNil(bridge, "MLXMedGemmaBridge singleton should be accessible")
    }

    /// Test 2: Vision model initialization with valid path
    func testVisionModelLoadingWithValidPath() async {
        // Create temporary test directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("medgemma-test")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Create mock model files
        let requiredFiles = [
            "model.safetensors",
            "vision_encoder.safetensors",
            "config.json",
            "tokenizer.json"
        ]

        for file in requiredFiles {
            let filePath = tempDir.appendingPathComponent(file)
            try? "{}".write(to: filePath, atomically: true, encoding: .utf8)
        }

        do {
            try await MLXMedGemmaBridge.shared.loadModel(from: tempDir.path)
            // Success - model loaded
        } catch {
            XCTFail("Model should load with required files: \(error)")
        }

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    /// Test 3: Vision model initialization with invalid path
    func testVisionModelLoadingWithInvalidPath() async {
        let invalidPath = "/invalid/model/path"

        do {
            try await MLXMedGemmaBridge.shared.loadModel(from: invalidPath)
            XCTFail("Should throw error for invalid path")
        } catch let error as MLXModelError {
            XCTAssertEqual(error as? MLXModelError, .fileAccessError("Model path does not exist: \(invalidPath)") as? MLXModelError,
                          "Should throw fileAccessError")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Vision Inference Tests

    /// Test 4: Vision inference with valid image and text prompt
    func testVisionInferenceWithValidImageAndPrompt() async {
        // Create a simple test image (1x1 pixel)
        let image = createTestImage(size: CGSize(width: 384, height: 384))
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image data")
            return
        }

        do {
            let result = try await MLXMedGemmaBridge.shared.generateFindings(
                from: imageData,
                prompt: "Describe visible features in this medical image.",
                maxTokens: 100,
                temperature: 0.3,
                language: .english
            )

            XCTAssertFalse(result.isEmpty, "Generated findings should not be empty")
            XCTAssertLessThan(result.count, 5000, "Generated text should be reasonable length")
        } catch {
            XCTFail("Vision inference should succeed: \(error)")
        }
    }

    /// Test 5: Vision inference with invalid image data
    func testVisionInferenceWithInvalidImageData() async {
        let invalidImageData = Data([0xFF, 0xD8, 0xFF])  // Invalid JPEG header

        do {
            _ = try await MLXMedGemmaBridge.shared.generateFindings(
                from: invalidImageData,
                prompt: "Test prompt",
                maxTokens: 100,
                temperature: 0.3,
                language: .english
            )
            XCTFail("Should throw error for invalid image data")
        } catch let error as MLXModelError {
            // Expected
            switch error {
            case .invocationFailed:
                break
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// Test 6: Memory usage during inference
    func testMemoryUsageDuringInference() async {
        let image = createTestImage(size: CGSize(width: 384, height: 384))
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image data")
            return
        }

        // Record memory before inference
        let memBefore = getMemoryUsage()

        do {
            let result = try await MLXMedGemmaBridge.shared.generateFindings(
                from: imageData,
                prompt: "Test",
                maxTokens: 100,
                temperature: 0.3,
                language: .english
            )

            // Record memory after inference
            let memAfter = getMemoryUsage()
            let memIncrease = memAfter - memBefore

            // Memory increase should be reasonable (less than 3GB)
            XCTAssertLessThan(memIncrease, 3_000_000_000,
                             "Memory usage increase should be less than 3GB, got \(memIncrease) bytes")

            XCTAssertFalse(result.isEmpty, "Should generate findings")
        } catch {
            XCTFail("Inference failed: \(error)")
        }
    }

    // MARK: - Streaming Tests

    /// Test 7: Streaming vision inference produces tokens progressively
    func testStreamingVisionInferenceProgressively() async {
        let image = createTestImage(size: CGSize(width: 384, height: 384))
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image data")
            return
        }

        var collectedTokens = ""
        var tokenCount = 0

        let stream = MLXMedGemmaBridge.shared.generateFindingsStreaming(
            from: imageData,
            prompt: "Test",
            maxTokens: 50,
            temperature: 0.3,
            language: .english
        )

        do {
            for try await token in stream {
                collectedTokens += token
                tokenCount += 1
            }

            XCTAssertGreaterThan(tokenCount, 0, "Should receive at least one token")
            XCTAssertFalse(collectedTokens.isEmpty, "Collected tokens should not be empty")
            print("Streaming test: Received \(tokenCount) tokens")
        } catch {
            XCTFail("Streaming inference failed: \(error)")
        }
    }

    // MARK: - Language Support Tests

    /// Test 8: Vision inference respects language parameter
    func testVisionInferenceRespectLanguage() async {
        let image = createTestImage(size: CGSize(width: 384, height: 384))
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image data")
            return
        }

        for language in Language.allCases {
            do {
                let result = try await MLXMedGemmaBridge.shared.generateFindings(
                    from: imageData,
                    prompt: "",
                    maxTokens: 100,
                    temperature: 0.3,
                    language: language
                )

                XCTAssertFalse(result.isEmpty, "Should generate findings in \(language.displayName)")
                print("✓ Vision inference works for \(language.displayName)")
            } catch {
                XCTFail("Vision inference failed for \(language.displayName): \(error)")
            }
        }
    }

    // MARK: - Integration Tests

    /// Test 9: Vision findings pass safety validation
    func testVisionFindingsPassSafetyValidation() async {
        let image = createTestImage(size: CGSize(width: 384, height: 384))
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image data")
            return
        }

        do {
            let result = try await imagingModel.generateFindings(
                from: imageData,
                options: InferenceOptions(language: .english)
            )

            // Result should be valid JSON
            let decoder = JSONDecoder()
            let findings = try decoder.decode(ImagingFindingsSummary.self, from: result.findingsJSON.data(using: .utf8) ?? Data())

            XCTAssertFalse(findings.limitations.isEmpty, "Should have limitations statement")
            XCTAssertTrue(findings.limitations.contains("does not assess clinical significance"),
                         "Limitations should be explicit about safety")

            print("✓ Vision findings pass safety validation")
        } catch {
            XCTFail("Findings validation failed: \(error)")
        }
    }

    /// Test 10: Vision inference completes within timeout
    func testVisionInferenceCompleteWithinTimeout() async {
        let image = createTestImage(size: CGSize(width: 384, height: 384))
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image data")
            return
        }

        let startTime = Date()
        let timeoutSeconds: TimeInterval = 30

        do {
            _ = try await MLXMedGemmaBridge.shared.generateFindings(
                from: imageData,
                prompt: "Test",
                maxTokens: 100,
                temperature: 0.3,
                language: .english
            )

            let elapsed = Date().timeIntervalSince(startTime)
            XCTAssertLessThan(elapsed, timeoutSeconds, "Inference should complete within \(timeoutSeconds)s, took \(elapsed)s")
            print("✓ Vision inference completed in \(String(format: "%.2f", elapsed))s")
        } catch {
            XCTFail("Inference failed: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func createTestImage(size: CGSize) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        UIColor.white.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    private func getMemoryUsage() -> Int64 {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size)/4

        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: Int32.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        guard kerr == KERN_SUCCESS else { return 0 }
        return Int64(info.resident_size)
    }
}
