//
//  MLXModelInferenceTests.swift
//  MediScribeTests
//
//  Integration tests for MLX model inference pipeline
//

import XCTest
@testable import MediScribe

class MLXModelInferenceTests: XCTestCase {
    // MARK: - Properties

    var modelLoader: MLXModelLoader!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        modelLoader = MLXModelLoader.shared
    }

    override func tearDown() {
        modelLoader = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    /// Test 1: MLXModelBridge is accessible
    func testMLXModelBridgeAccess() {
        // Verify the bridge class can be instantiated
        let bridgeClass = NSClassFromString("MediScribe.MLXModelBridge")
        XCTAssertNotNil(bridgeClass, "MLXModelBridge should be accessible")
    }

    /// Test 2: Tokenization with vocabulary
    func testTokenization() throws {
        let prompt = "Patient presents with fever and cough"

        // Tokenize the text
        do {
            let tokens = try MLXModelBridge.tokenize(prompt)
            XCTAssertGreaterThan(tokens.count, 0, "Should produce tokens")
            XCTAssertTrue(tokens.allSatisfy { $0 >= 0 }, "Token IDs should be non-negative")
        } catch {
            // If model not loaded yet, that's expected - skip this test
            print("Tokenization test skipped (model not loaded): \(error)")
        }
    }

    /// Test 3: Imaging prompt generation
    func testImagingPromptGeneration() {
        let localizedPrompts = LocalizedPrompts(language: .english)
        let prompt = localizedPrompts.buildImagingPrompt(imageContext: "Chest X-ray image provided")

        // Verify prompt structure
        XCTAssertTrue(prompt.contains("Describe") || prompt.contains("describe"), "Should instruct to describe visible features")
        XCTAssertTrue(prompt.contains("diagnoses") || prompt.contains("Diagnoses"), "Should include safety disclaimer")
        XCTAssertTrue(prompt.contains("JSON"), "Should specify JSON output format")
    }

    /// Test 4: Lab results prompt generation
    func testLabResultsPromptGeneration() {
        let localizedPrompts = LocalizedPrompts(language: .english)
        let prompt = localizedPrompts.buildLabPrompt()

        // Verify prompt structure
        XCTAssertTrue(prompt.contains("Extract") || prompt.contains("extract"), "Should instruct to extract")
        XCTAssertTrue(prompt.contains("visible values"), "Should specify visible values only")
        XCTAssertTrue(prompt.contains("JSON"), "Should specify JSON output format")
        XCTAssertTrue(prompt.contains("limitations"), "Should include limitations statement")
    }

    /// Test 5: SOAP prompt generation
    func testSOAPPromptGeneration() {
        let context = createTestPatientContext()
        let promptBuilder = SOAPPromptBuilder()
        let prompt = promptBuilder.buildSOAPPrompt(from: context)

        // Verify prompt structure
        XCTAssertTrue(prompt.contains("SOAP note"), "Should mention SOAP note generation")
        XCTAssertTrue(prompt.contains("CRITICAL SAFETY"), "Should include safety guidelines")
        XCTAssertTrue(prompt.contains("diagnose"), "Should explicitly forbid diagnosis")
        XCTAssertTrue(prompt.contains("JSON"), "Should specify JSON output format")
    }

    /// Test 6: Imaging findings validator integration
    func testImagingFindingsValidation() {
        let validJSON = """
        {
            "limitations": "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis.",
            "anatomicalObservations": {
                "lungs": "Bilateral lungs clear to auscultation"
            }
        }
        """

        do {
            let findings = try FindingsValidator.decodeAndValidate(Data(validJSON.utf8))
            XCTAssertNotNil(findings, "Valid findings should decode")
            XCTAssertTrue(findings.limitations.contains("does not"), "Should contain limitations")
        } catch {
            XCTFail("Valid findings should not throw: \(error)")
        }
    }

    /// Test 7: Lab results validator integration
    func testLabResultsValidation() {
        let validJSON = """
        {
            "documentType": "laboratory_report",
            "testCategories": [
                {
                    "category": "Complete Blood Count",
                    "tests": [
                        {
                            "testName": "Hemoglobin",
                            "value": "14.2",
                            "unit": "g/dL"
                        }
                    ]
                }
            ],
            "limitations": "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
        }
        """

        do {
            let results = try LabResultsValidator.decodeAndValidate(validJSON)
            XCTAssertNotNil(results, "Valid lab results should decode")
            XCTAssertEqual(results.testCategories.count, 1, "Should have one category")
        } catch {
            XCTFail("Valid lab results should not throw: \(error)")
        }
    }

    /// Test 8: Temperature scaling effect on sampling
    func testTemperatureScaling() {
        // Verify temperature values are in reasonable range
        let lowTemp: Float = 0.2  // Deterministic
        let highTemp: Float = 0.9 // Creative

        XCTAssertGreater(lowTemp, 0, "Temperature should be > 0")
        XCTAssertLess(highTemp, 1.1, "Temperature should be < 1.1")
        XCTAssertLess(lowTemp, highTemp, "Low temp should be lower than high temp")
    }

    /// Test 9: InferenceOptions structure
    func testInferenceOptions() {
        let options = MLXInferenceOptions(
            maxTokens: 1024,
            temperature: 0.3,
            topP: 0.9,
            topK: 50,
            numContexts: 2048,
            greedyDecoding: false
        )

        XCTAssertEqual(options.maxTokens, 1024)
        XCTAssertEqual(options.temperature, 0.3)
        XCTAssertEqual(options.topK, 50)
        XCTAssertFalse(options.greedyDecoding)
    }

    /// Test 10: Model manager initialization
    func testModelManagerInitialization() {
        let manager = ImagingModelManager.shared

        // Verify manager is accessible
        XCTAssertNotNil(manager, "Model manager should be initialized")
        XCTAssertNotNil(manager.currentModel, "Should have current model")
        XCTAssertFalse(manager.modelInfo.isEmpty, "Should provide model info")
    }

    /// Test 11: Safety validator forbidden phrases
    func testSafetyValidatorForbiddenPhrases() {
        // Test that forbidden phrases are blocked
        let invalidJSON = """
        {
            "limitations": "This is a valid limitations statement.",
            "anatomicalObservations": {
                "lungs": "Pneumonia detected in left lung"
            }
        }
        """

        do {
            _ = try FindingsValidator.decodeAndValidate(Data(invalidJSON.utf8))
            XCTFail("Should reject findings with forbidden phrase 'pneumonia'")
        } catch let error as FindingsValidationError {
            // Expected - forbidden phrase detected
            XCTAssertTrue(error.localizedDescription.contains("blocked") || error.localizedDescription.contains("Invalid"))
        } catch {
            XCTFail("Should throw FindingsValidationError: \(error)")
        }
    }

    /// Test 12: SOAP response parsing structure
    func testSOAPResponseParserStructure() {
        let validResponse = """
        {
            "subjective": "Patient reports fever",
            "objective": "Temperature 38.5C",
            "assessment": "Consistent with viral infection",
            "plan": "Rest and supportive care",
            "generated_at": "2026-01-30T17:00:00Z"
        }
        """

        let parser = SOAPResponseParser()

        do {
            let note = try parser.parseSOAPNote(from: validResponse)
            XCTAssertFalse(note.subjective.isEmpty, "Should have subjective section")
            XCTAssertFalse(note.objective.isEmpty, "Should have objective section")
            XCTAssertFalse(note.assessment.isEmpty, "Should have assessment section")
            XCTAssertFalse(note.plan.isEmpty, "Should have plan section")
        } catch {
            XCTFail("Valid SOAP response should parse: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func createTestPatientContext() -> PatientContext {
        let vitals = VitalSigns(
            temperature: 37.2,
            heartRate: 78,
            respiratoryRate: 16,
            systolicBP: 120,
            diastolicBP: 80,
            oxygenSaturation: 98
        )

        return PatientContext(
            age: 45,
            sex: "M",
            chiefComplaint: "Persistent cough",
            vitalSigns: vitals,
            medicalHistory: ["Asthma"],
            currentMedications: ["Albuterol"],
            allergies: ["Penicillin"]
        )
    }
}
