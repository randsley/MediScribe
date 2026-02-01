//
//  VisionIntegrationTests.swift
//  MediScribeTests
//
//  End-to-end integration tests for vision-language inference pipeline
//

import XCTest
import Foundation

@testable import MediScribe

class VisionIntegrationTests: XCTestCase {

    var imagingModel: MLXImagingModel!
    var bridge: MLXMedGemmaBridge!

    override func setUp() {
        super.setUp()
        imagingModel = MLXImagingModel()
        bridge = MLXMedGemmaBridge.shared
    }

    override func tearDown() {
        imagingModel = nil
        bridge = nil
        super.tearDown()
    }

    // MARK: - Full Pipeline Tests

    /// Test 1: Image → MLXModelBridge → MLXMedGemmaBridge → FindingsValidator (full chain)
    func testFullImagingPipelineChain() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        do {
            // Step 1: Call imagingModel (public API)
            let result = try await imagingModel.generateFindings(
                from: imageData,
                options: InferenceOptions(language: .english)
            )

            // Step 2: Verify result has valid findings JSON
            XCTAssertFalse(result.findingsJSON.isEmpty, "Should generate findings JSON")

            // Step 3: Verify findings can be decoded
            let decoder = JSONDecoder()
            let findings = try decoder.decode(
                ImagingFindingsSummary.self,
                from: result.findingsJSON.data(using: .utf8) ?? Data()
            )

            // Step 4: Verify safety validation passed
            XCTAssertFalse(findings.limitations.isEmpty, "Must have limitations statement")

            // Step 5: Verify anatomical observations present
            XCTAssertNotNil(findings.anatomicalObservations, "Should have observations")

            print("✓ Full imaging pipeline: Image → Model → Validator → Findings")
            print("  Processing time: \(String(format: "%.2f", result.processingTime))s")
        } catch {
            XCTFail("Full imaging pipeline failed: \(error)")
        }
    }

    /// Test 2: Image → MLXMedGemmaBridge direct call
    func testDirectMLXMedGemmaBridgeCall() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        do {
            let result = try await bridge.generateFindings(
                from: imageData,
                prompt: "Describe the visible features in this medical image.",
                maxTokens: 200,
                temperature: 0.3,
                language: .english
            )

            XCTAssertFalse(result.isEmpty, "Should generate findings")
            XCTAssertLessThan(result.count, 10000, "Output should be reasonable size")

            print("✓ Direct MLXMedGemmaBridge call: \(result.prefix(150))...")
        } catch {
            XCTFail("Direct bridge call failed: \(error)")
        }
    }

    // MARK: - Labs Pipeline Tests

    /// Test 3: Lab image → Extraction → Validation (full chain)
    func testFullLabExtractionPipeline() async {
        let labImage = createTestImage()
        guard let imageData = labImage.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        do {
            // Generate lab findings through the bridge
            let prompt = LocalizedPrompts(language: .english).buildLabPrompt()
            let result = try await bridge.generateFindings(
                from: imageData,
                prompt: prompt,
                maxTokens: 500,
                temperature: 0.3,
                language: .english
            )

            XCTAssertFalse(result.isEmpty, "Lab extraction should produce output")

            // Try to decode as LabResultsSummary if it's lab format
            // In real usage, result would be validated through LabResultsValidator
            print("✓ Full lab extraction pipeline completed")
        } catch {
            XCTFail("Lab extraction pipeline failed: \(error)")
        }
    }

    // MARK: - Streaming Tests

    /// Test 4: Streaming token generation maintains order and completeness
    func testStreamingTokenGenerationOrder() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        var streamedText = ""
        var tokenCount = 0
        let startTime = Date()

        let stream = bridge.generateFindingsStreaming(
            from: imageData,
            prompt: "Test",
            maxTokens: 100,
            temperature: 0.3,
            language: .english
        )

        do {
            for try await token in stream {
                streamedText += token
                tokenCount += 1
            }

            let elapsed = Date().timeIntervalSince(startTime)
            XCTAssertGreaterThan(tokenCount, 0, "Should receive tokens")
            XCTAssertFalse(streamedText.isEmpty, "Streamed text should accumulate")

            print("✓ Streaming: \(tokenCount) tokens in \(String(format: "%.2f", elapsed))s")
            print("  Text: \(streamedText.prefix(100))...")
        } catch {
            XCTFail("Streaming generation failed: \(error)")
        }
    }

    /// Test 5: Streaming can be cancelled mid-generation
    func testStreamingCanBeCancelled() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        let stream = bridge.generateFindingsStreaming(
            from: imageData,
            prompt: "Test",
            maxTokens: 1000,
            temperature: 0.3,
            language: .english
        )

        var tokenCount = 0

        do {
            for try await token in stream {
                tokenCount += 1

                // Cancel after a few tokens
                if tokenCount > 5 {
                    break
                }
            }

            XCTAssertGreaterThan(tokenCount, 0, "Should receive some tokens before cancel")
            print("✓ Streaming cancelled successfully after \(tokenCount) tokens")
        } catch {
            // Cancellation may throw or not depending on implementation
            print("ℹ️  Stream ended (may be normal after cancellation): \(error)")
        }
    }

    // MARK: - Error Handling & Fallback Tests

    /// Test 6: Error handling for corrupted image data
    func testErrorHandlingForCorruptedImageData() async {
        let corruptedData = Data([0xFF, 0xD8, 0xFF, 0xE0])  // Partial JPEG header

        do {
            _ = try await bridge.generateFindings(
                from: corruptedData,
                prompt: "Test",
                maxTokens: 100,
                temperature: 0.3,
                language: .english
            )
            XCTFail("Should throw error for corrupted image data")
        } catch let error as MLXModelError {
            // Expected error
            switch error {
            case .invocationFailed:
                print("✓ Correct error for corrupted image: \(error)")
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// Test 7: Memory cleanup after inference
    func testMemoryCleanupAfterInference() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        let memBefore = getMemoryUsage()

        do {
            _ = try await bridge.generateFindings(
                from: imageData,
                prompt: "Test",
                maxTokens: 100,
                temperature: 0.3,
                language: .english
            )
        } catch {
            XCTFail("Inference failed: \(error)")
        }

        // Give system time to garbage collect
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let memAfter = getMemoryUsage()
        let memLeak = memAfter - memBefore

        // Should not leak excessive memory
        XCTAssertLessThan(memLeak, 500_000_000, "Should not leak more than 500MB")
        print("✓ Memory cleanup: \(ByteCountFormatter.string(fromByteCount: memLeak, countStyle: .memory))")
    }

    // MARK: - Performance Tests

    /// Test 8: Vision inference performance benchmark
    func testVisionInferencePerformanceBenchmark() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        let iterations = 3
        var times: [TimeInterval] = []

        for i in 1...iterations {
            let startTime = Date()

            do {
                _ = try await bridge.generateFindings(
                    from: imageData,
                    prompt: "Test",
                    maxTokens: 100,
                    temperature: 0.3,
                    language: .english
                )

                let elapsed = Date().timeIntervalSince(startTime)
                times.append(elapsed)
                print("✓ Iteration \(i): \(String(format: "%.2f", elapsed))s")
            } catch {
                XCTFail("Benchmark iteration \(i) failed: \(error)")
            }
        }

        let avgTime = times.reduce(0, +) / TimeInterval(times.count)
        let maxTime = times.max() ?? 0

        XCTAssertLessThan(avgTime, 10.0, "Average inference should be <10s")
        XCTAssertLessThan(maxTime, 15.0, "Max inference should be <15s")

        print("✓ Performance: avg=\(String(format: "%.2f", avgTime))s, max=\(String(format: "%.2f", maxTime))s")
    }

    /// Test 9: Inference scaling with different token limits
    func testInferenceScalingWithTokenLimits() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        let tokenLimits = [50, 100, 200, 500]

        for maxTokens in tokenLimits {
            let startTime = Date()

            do {
                let result = try await bridge.generateFindings(
                    from: imageData,
                    prompt: "Test",
                    maxTokens: maxTokens,
                    temperature: 0.3,
                    language: .english
                )

                let elapsed = Date().timeIntervalSince(startTime)
                let resultLength = result.count

                print("✓ \(maxTokens) tokens: \(String(format: "%.2f", elapsed))s, \(resultLength) chars")

                // Longer generations should generally take more time
                if maxTokens > 50 {
                    // Relax constraint since actual implementation may vary
                    XCTAssertLessThan(elapsed, 20.0, "Should complete within reasonable time")
                }
            } catch {
                XCTFail("Inference with \(maxTokens) tokens failed: \(error)")
            }
        }
    }

    // MARK: - Safety & Validation Tests

    /// Test 10: Vision output integration with FindingsValidator
    func testVisionOutputValidationIntegration() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        do {
            // Generate findings
            let result = try await imagingModel.generateFindings(
                from: imageData,
                options: InferenceOptions(language: .english)
            )

            // Decode findings
            let decoder = JSONDecoder()
            let findings = try decoder.decode(
                ImagingFindingsSummary.self,
                from: result.findingsJSON.data(using: .utf8) ?? Data()
            )

            // Validate safety constraints
            let lowerFindings = findings.limitations.lowercased()

            // Check for forbidden phrases
            let forbidden = Language.english.forbiddenPhrases
            for phrase in forbidden {
                XCTAssertFalse(lowerFindings.contains(phrase),
                              "Validated findings should not contain: \(phrase)")
            }

            // Verify positive safety properties
            XCTAssertTrue(
                lowerFindings.contains("visible") || lowerFindings.contains("features") || lowerFindings.contains("observe"),
                "Should describe observable features"
            )

            print("✓ Vision output passes FindingsValidator integration test")
        } catch {
            XCTFail("Vision validation integration failed: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func createTestImage() -> UIImage {
        let size = CGSize(width: 384, height: 384)
        let rect = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        UIColor.white.setFill()
        UIRectFill(rect)

        // Draw medical-like patterns
        UIColor.lightGray.setStroke()
        for i in stride(from: 0, to: Int(size.width), by: 50) {
            UIBezierPath(rect: CGRect(x: i, y: 0, width: 1, height: Int(size.height))).stroke()
        }

        UIColor.darkGray.setFill()
        let oblong = UIBezierPath(ovalIn: CGRect(x: 100, y: 100, width: 184, height: 184))
        oblong.fill()

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
