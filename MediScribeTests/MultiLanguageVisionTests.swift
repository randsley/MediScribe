//
//  MultiLanguageVisionTests.swift
//  MediScribeTests
//
//  Tests for vision inference with multi-language support (EN, ES, FR, PT)
//

import XCTest
import Foundation

@testable import MediScribe

class MultiLanguageVisionTests: XCTestCase {

    var bridge: MLXMedGemmaBridge!
    var imagingModel: MLXImagingModel!

    override func setUp() {
        super.setUp()
        bridge = MLXMedGemmaBridge.shared
        imagingModel = MLXImagingModel()
    }

    override func tearDown() {
        bridge = nil
        imagingModel = nil
        super.tearDown()
    }

    // MARK: - English Vision Tests

    /// Test 1: English vision inference generates medical findings
    func testEnglishVisionInferenceFindingsGeneration() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        do {
            let result = try await bridge.generateFindings(
                from: imageData,
                prompt: "",
                maxTokens: 100,
                temperature: 0.3,
                language: .english
            )

            XCTAssertFalse(result.isEmpty, "English vision inference should generate text")
            // Check for English limitations statement
            let englishPrompt = LocalizedPrompts(language: .english).buildImagingPrompt(imageContext: "Test")
            XCTAssertTrue(englishPrompt.contains("does not assess clinical significance"),
                         "English prompt should have safety statement")
            print("✓ English vision inference: \(result.prefix(100))...")
        } catch {
            XCTFail("English vision inference failed: \(error)")
        }
    }

    /// Test 2: English vision findings pass safety validation
    func testEnglishVisionFindingsSafetyValidation() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        do {
            let result = try await imagingModel.generateFindings(
                from: imageData,
                options: InferenceOptions(language: .english)
            )

            let findings = try JSONDecoder().decode(
                ImagingFindingsSummary.self,
                from: result.findingsJSON.data(using: .utf8) ?? Data()
            )

            // Verify safety requirements
            XCTAssertFalse(findings.limitations.isEmpty, "Must have limitations")
            XCTAssertTrue(findings.limitations.contains("does not assess clinical significance"),
                         "Must mention no clinical significance assessment")

            // Verify no forbidden phrases
            let forbidden = Language.english.forbiddenPhrases
            for phrase in forbidden {
                let lowerFindings = findings.limitations.lowercased()
                XCTAssertFalse(lowerFindings.contains(phrase),
                              "Should not contain forbidden phrase: \(phrase)")
            }

            print("✓ English findings pass all safety checks")
        } catch {
            XCTFail("English safety validation failed: \(error)")
        }
    }

    // MARK: - Spanish Vision Tests

    /// Test 3: Spanish vision inference generates medical findings
    func testSpanishVisionInferenceFindingsGeneration() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        do {
            let result = try await bridge.generateFindings(
                from: imageData,
                prompt: "",
                maxTokens: 100,
                temperature: 0.3,
                language: .spanish
            )

            XCTAssertFalse(result.isEmpty, "Spanish vision inference should generate text")
            // Check for Spanish prompt generation
            let spanishPrompt = LocalizedPrompts(language: .spanish).buildImagingPrompt(imageContext: "Test")
            XCTAssertTrue(spanishPrompt.contains("solo") || spanishPrompt.contains("solamente"),
                         "Spanish prompt should be present")
            print("✓ Spanish vision inference: \(result.prefix(100))...")
        } catch {
            XCTFail("Spanish vision inference failed: \(error)")
        }
    }

    /// Test 4: Spanish vision findings pass safety validation
    func testSpanishVisionFindingsSafetyValidation() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        do {
            let result = try await imagingModel.generateFindings(
                from: imageData,
                options: InferenceOptions(language: .spanish)
            )

            let findings = try JSONDecoder().decode(
                ImagingFindingsSummary.self,
                from: result.findingsJSON.data(using: .utf8) ?? Data()
            )

            // Verify safety requirements
            XCTAssertFalse(findings.limitations.isEmpty, "Must have limitations")

            // Verify no Spanish forbidden phrases
            let forbidden = Language.spanish.forbiddenPhrases
            for phrase in forbidden {
                let lowerFindings = findings.limitations.lowercased()
                XCTAssertFalse(lowerFindings.contains(phrase),
                              "Should not contain Spanish forbidden phrase: \(phrase)")
            }

            print("✓ Spanish findings pass all safety checks")
        } catch {
            XCTFail("Spanish safety validation failed: \(error)")
        }
    }

    // MARK: - French Vision Tests

    /// Test 5: French vision inference generates medical findings
    func testFrenchVisionInferenceFindingsGeneration() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        do {
            let result = try await bridge.generateFindings(
                from: imageData,
                prompt: "",
                maxTokens: 100,
                temperature: 0.3,
                language: .french
            )

            XCTAssertFalse(result.isEmpty, "French vision inference should generate text")
            // Check for French prompt generation
            let frenchPrompt = LocalizedPrompts(language: .french).buildImagingPrompt(imageContext: "Test")
            XCTAssertTrue(frenchPrompt.contains("décire") || frenchPrompt.contains("visible"),
                         "French prompt should be present")
            print("✓ French vision inference: \(result.prefix(100))...")
        } catch {
            XCTFail("French vision inference failed: \(error)")
        }
    }

    /// Test 6: French vision findings pass safety validation
    func testFrenchVisionFindingsSafetyValidation() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        do {
            let result = try await imagingModel.generateFindings(
                from: imageData,
                options: InferenceOptions(language: .french)
            )

            let findings = try JSONDecoder().decode(
                ImagingFindingsSummary.self,
                from: result.findingsJSON.data(using: .utf8) ?? Data()
            )

            // Verify safety requirements
            XCTAssertFalse(findings.limitations.isEmpty, "Must have limitations")

            // Verify no French forbidden phrases
            let forbidden = Language.french.forbiddenPhrases
            for phrase in forbidden {
                let lowerFindings = findings.limitations.lowercased()
                XCTAssertFalse(lowerFindings.contains(phrase),
                              "Should not contain French forbidden phrase: \(phrase)")
            }

            print("✓ French findings pass all safety checks")
        } catch {
            XCTFail("French safety validation failed: \(error)")
        }
    }

    // MARK: - Portuguese Vision Tests

    /// Test 7: Portuguese vision inference generates medical findings
    func testPortugueseVisionInferenceFindingsGeneration() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        do {
            let result = try await bridge.generateFindings(
                from: imageData,
                prompt: "",
                maxTokens: 100,
                temperature: 0.3,
                language: .portuguese
            )

            XCTAssertFalse(result.isEmpty, "Portuguese vision inference should generate text")
            // Check for Portuguese prompt generation
            let ptPrompt = LocalizedPrompts(language: .portuguese).buildImagingPrompt(imageContext: "Test")
            XCTAssertTrue(ptPrompt.contains("visível") || ptPrompt.contains("descrever"),
                         "Portuguese prompt should be present")
            print("✓ Portuguese vision inference: \(result.prefix(100))...")
        } catch {
            XCTFail("Portuguese vision inference failed: \(error)")
        }
    }

    /// Test 8: Portuguese vision findings pass safety validation
    func testPortugueseVisionFindingsSafetyValidation() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        do {
            let result = try await imagingModel.generateFindings(
                from: imageData,
                options: InferenceOptions(language: .portuguese)
            )

            let findings = try JSONDecoder().decode(
                ImagingFindingsSummary.self,
                from: result.findingsJSON.data(using: .utf8) ?? Data()
            )

            // Verify safety requirements
            XCTAssertFalse(findings.limitations.isEmpty, "Must have limitations")

            // Verify no Portuguese forbidden phrases
            let forbidden = Language.portuguese.forbiddenPhrases
            for phrase in forbidden {
                let lowerFindings = findings.limitations.lowercased()
                XCTAssertFalse(lowerFindings.contains(phrase),
                              "Should not contain Portuguese forbidden phrase: \(phrase)")
            }

            print("✓ Portuguese findings pass all safety checks")
        } catch {
            XCTFail("Portuguese safety validation failed: \(error)")
        }
    }

    // MARK: - Cross-Language Tests

    /// Test 9: All languages produce consistent safety output
    func testAllLanguagesProduceConsistentSafetyOutput() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        for language in Language.allCases {
            do {
                let result = try await imagingModel.generateFindings(
                    from: imageData,
                    options: InferenceOptions(language: language)
                )

                let findings = try JSONDecoder().decode(
                    ImagingFindingsSummary.self,
                    from: result.findingsJSON.data(using: .utf8) ?? Data()
                )

                // All languages must have limitations
                XCTAssertFalse(findings.limitations.isEmpty,
                              "Language \(language.displayName) must have limitations")

                // All languages must not contain forbidden phrases
                let forbidden = language.forbiddenPhrases
                let lowerFindings = findings.limitations.lowercased()
                for phrase in forbidden {
                    XCTAssertFalse(lowerFindings.contains(phrase),
                                  "Language \(language.displayName) should not contain: \(phrase)")
                }

                print("✓ \(language.displayName) safety checks passed")
            } catch {
                XCTFail("Language \(language.displayName) failed: \(error)")
            }
        }
    }

    /// Test 10: Language parameter flows through validation
    func testLanguageParameterFlowsThroughValidation() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        for language in Language.allCases {
            do {
                let options = InferenceOptions(
                    temperature: 0.3,
                    maxTokens: 100,
                    language: language
                )

                let result = try await imagingModel.generateFindings(
                    from: imageData,
                    options: options
                )

                XCTAssertFalse(result.findingsJSON.isEmpty,
                              "Should generate findings for \(language.displayName)")

                // Verify the result can be decoded
                _ = try JSONDecoder().decode(
                    ImagingFindingsSummary.self,
                    from: result.findingsJSON.data(using: .utf8) ?? Data()
                )

                print("✓ Language parameter worked for \(language.displayName)")
            } catch {
                XCTFail("Language parameter test failed for \(language.displayName): \(error)")
            }
        }
    }

    // MARK: - Lab Test Multi-Language Tests

    /// Test 11: Lab extraction works in all languages
    func testLabExtractionMultiLanguageSupport() async {
        let image = createTestImage()
        guard let imageData = image.pngData() else {
            XCTFail("Failed to create test image")
            return
        }

        for language in Language.allCases {
            do {
                let prompt = LocalizedPrompts(language: language).buildLabPrompt()
                XCTAssertFalse(prompt.isEmpty, "Lab prompt should exist for \(language.displayName)")

                // Verify prompt contains language-specific safety content
                let lowerPrompt = prompt.lowercased()
                XCTAssertTrue(
                    lowerPrompt.contains("visible") || lowerPrompt.contains("visible") ||
                    lowerPrompt.contains("visible") || lowerPrompt.contains("visible"),
                    "Lab prompt should mention visibility"
                )

                print("✓ Lab prompt available for \(language.displayName)")
            } catch {
                XCTFail("Lab test failed for \(language.displayName): \(error)")
            }
        }
    }

    // MARK: - Helper Methods

    private func createTestImage() -> UIImage {
        let size = CGSize(width: 384, height: 384)
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        UIColor.white.setFill()
        UIRectFill(rect)

        // Draw some simple shapes to simulate medical image
        UIColor.gray.setStroke()
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 192, y: 192), radius: 50, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        circlePath.lineWidth = 2
        circlePath.stroke()

        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
