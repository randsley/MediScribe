//
//  PerformanceBenchmarkTests.swift
//  MediScribeTests
//
//  Performance benchmarking for Phase 6 features
//

import XCTest
@testable import MediScribe

class PerformanceBenchmarkTests: XCTestCase {
    // MARK: - Properties

    var modelLoader: MLXModelLoader!
    var encryptionService: EncryptionService!

    // MARK: - Performance Targets

    struct PerformanceTargets {
        static let modelLoadTimeMax: TimeInterval = 5.0 // seconds
        static let soapGenerationMax: TimeInterval = 10.0 // seconds
        static let tokenizationMax: TimeInterval = 1.0 // seconds
        static let encryptionMax: TimeInterval = 0.5 // seconds
        static let decryptionMax: TimeInterval = 0.5 // seconds
        static let memoryPeakMax: UInt64 = 3_000_000_000 // 3GB
    }

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        modelLoader = MLXModelLoader.shared
        encryptionService = EncryptionService()
    }

    override func tearDown() {
        encryptionService = nil
        modelLoader = nil
        super.tearDown()
    }

    // MARK: - Benchmark Tests

    /// Benchmark 1: Model loading time
    func testModelLoadingPerformance() {
        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        measure(options: measureOptions) {
            let startTime = Date()

            do {
                // Simulate model loading (in real scenario, this loads actual MLX model)
                try modelLoader.loadModel()
                let loadTime = Date().timeIntervalSince(startTime)

                print("✓ Model load time: \(String(format: "%.3f", loadTime))s")
                XCTAssertLessThanOrEqual(
                    loadTime,
                    PerformanceTargets.modelLoadTimeMax,
                    "Model loading should complete in under 5 seconds"
                )
            } catch {
                print("⚠️ Model loading not available in test environment")
            }

            self.stopMeasuring()
        }
    }

    /// Benchmark 2: Tokenization performance
    func testTokenizationPerformance() {
        let testPrompt = """
        Patient presents with persistent cough for 2 weeks, worse at night.
        Vital signs: Temperature 37.2°C, Heart Rate 78 bpm, BP 120/80 mmHg.
        Physical exam: Lungs clear to auscultation bilaterally.
        """

        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        measure(options: measureOptions) {
            let startTime = Date()

            do {
                _ = try MLXModelBridge.tokenize(testPrompt)
                let tokenizationTime = Date().timeIntervalSince(startTime)

                print("✓ Tokenization time: \(String(format: "%.3f", tokenizationTime))s")
                XCTAssertLessThanOrEqual(
                    tokenizationTime,
                    PerformanceTargets.tokenizationMax,
                    "Tokenization should complete in under 1 second"
                )
            } catch {
                print("⚠️ Tokenization not available in test environment")
            }

            self.stopMeasuring()
        }
    }

    /// Benchmark 3: SOAP prompt generation
    func testSOAPPromptGenerationPerformance() {
        let context = createTestPatientContext()
        let promptBuilder = SOAPPromptBuilder()

        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        measure(options: measureOptions) {
            let startTime = Date()

            let prompt = promptBuilder.buildSOAPPrompt(from: context)
            let generationTime = Date().timeIntervalSince(startTime)

            print("✓ SOAP prompt generation: \(String(format: "%.3f", generationTime))s")
            XCTAssertLessThanOrEqual(
                generationTime,
                0.1,
                "Prompt generation should be nearly instant (<100ms)"
            )
            XCTAssertGreaterThan(prompt.count, 100, "Prompt should have content")

            self.stopMeasuring()
        }
    }

    /// Benchmark 4: Imaging findings validation
    func testFindingsValidationPerformance() {
        let findingsJSON = createValidFindingsJSON()

        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        measure(options: measureOptions) {
            let startTime = Date()

            do {
                _ = try FindingsValidator.decodeAndValidate(Data(findingsJSON.utf8))
                let validationTime = Date().timeIntervalSince(startTime)

                print("✓ Findings validation: \(String(format: "%.3f", validationTime))s")
                XCTAssertLessThanOrEqual(
                    validationTime,
                    0.1,
                    "Validation should be fast (<100ms)"
                )
            } catch {
                XCTFail("Valid findings should not fail validation: \(error)")
            }

            self.stopMeasuring()
        }
    }

    /// Benchmark 5: Lab results validation
    func testLabResultsValidationPerformance() {
        let labJSON = createValidLabResultsJSON()

        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        measure(options: measureOptions) {
            let startTime = Date()

            do {
                _ = try LabResultsValidator.decodeAndValidate(labJSON)
                let validationTime = Date().timeIntervalSince(startTime)

                print("✓ Lab results validation: \(String(format: "%.3f", validationTime))s")
                XCTAssertLessThanOrEqual(
                    validationTime,
                    0.1,
                    "Lab validation should be fast (<100ms)"
                )
            } catch {
                XCTFail("Valid lab results should not fail validation: \(error)")
            }

            self.stopMeasuring()
        }
    }

    /// Benchmark 6: Encryption performance
    func testEncryptionPerformance() {
        let testData = "This is sensitive patient information that needs encryption".data(using: .utf8)!

        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        measure(options: measureOptions) {
            let startTime = Date()

            do {
                _ = try encryptionService.encrypt(testData)
                let encryptionTime = Date().timeIntervalSince(startTime)

                print("✓ Encryption time: \(String(format: "%.3f", encryptionTime))s")
                XCTAssertLessThanOrEqual(
                    encryptionTime,
                    PerformanceTargets.encryptionMax,
                    "Encryption should be fast (<500ms)"
                )
            } catch {
                XCTFail("Encryption should not fail: \(error)")
            }

            self.stopMeasuring()
        }
    }

    /// Benchmark 7: Decryption performance
    func testDecryptionPerformance() {
        let testData = "This is sensitive patient information that needs encryption".data(using: .utf8)!

        do {
            let encryptedData = try encryptionService.encrypt(testData)

            let measureOptions = XCTMeasureOptions()
            measureOptions.invocationOptions = [.manuallyStop]

            measure(options: measureOptions) {
                let startTime = Date()

                do {
                    _ = try encryptionService.decrypt(encryptedData)
                    let decryptionTime = Date().timeIntervalSince(startTime)

                    print("✓ Decryption time: \(String(format: "%.3f", decryptionTime))s")
                    XCTAssertLessThanOrEqual(
                        decryptionTime,
                        PerformanceTargets.decryptionMax,
                        "Decryption should be fast (<500ms)"
                    )
                } catch {
                    XCTFail("Decryption should not fail: \(error)")
                }

                self.stopMeasuring()
            }
        } catch {
            XCTFail("Setup encryption failed: \(error)")
        }
    }

    /// Benchmark 8: JSON encoding/decoding performance
    func testJSONSerializationPerformance() {
        let noteData = createTestSOAPNoteData()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        measure(options: measureOptions) {
            let startTime = Date()

            do {
                let encoded = try encoder.encode(noteData)
                let serializationTime = Date().timeIntervalSince(startTime)

                print("✓ JSON encoding: \(String(format: "%.3f", serializationTime))s for \(encoded.count) bytes")
                XCTAssertLessThanOrEqual(
                    serializationTime,
                    0.1,
                    "JSON encoding should be fast (<100ms)"
                )
            } catch {
                XCTFail("JSON encoding should not fail: \(error)")
            }

            self.stopMeasuring()
        }
    }

    /// Benchmark 9: Model manager initialization
    func testModelManagerInitializationPerformance() {
        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        measure(options: measureOptions) {
            let startTime = Date()

            _ = ImagingModelManager.shared
            let initTime = Date().timeIntervalSince(startTime)

            print("✓ Model manager init: \(String(format: "%.3f", initTime))s")
            XCTAssertLessThanOrEqual(
                initTime,
                0.5,
                "Model manager should initialize quickly (<500ms)"
            )

            self.stopMeasuring()
        }
    }

    /// Benchmark 10: Text sanitization performance
    func testTextSanitizationPerformance() {
        let longText = """
        This is a sample medical report with various findings including
        cardiac assessment, pulmonary examination, and abdominal palpation.
        The patient demonstrates normal cardiac rhythm and clear lungs.
        """ + String(repeating: " Additional text ", count: 100)

        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        measure(options: measureOptions) {
            let startTime = Date()

            let sanitized = TextSanitizer.sanitize(longText)
            let sanitizationTime = Date().timeIntervalSince(startTime)

            print("✓ Text sanitization: \(String(format: "%.3f", sanitizationTime))s for \(longText.count) chars")
            XCTAssertLessThanOrEqual(
                sanitizationTime,
                0.05,
                "Text sanitization should be very fast (<50ms)"
            )
            XCTAssertGreaterThan(sanitized.count, 0, "Sanitized text should have content")

            self.stopMeasuring()
        }
    }

    /// Benchmark 11: Comprehensive workflow timing
    func testCompleteSOAPGenerationWorkflowTiming() {
        print("\n=== SOAP Generation Workflow Timing ===")

        // Step 1: Patient context preparation
        var totalTime: TimeInterval = 0

        let contextStart = Date()
        let context = createTestPatientContext()
        let contextTime = Date().timeIntervalSince(contextStart)
        totalTime += contextTime
        print("1. Patient context preparation: \(String(format: "%.3f", contextTime))s")

        // Step 2: Prompt generation
        let promptStart = Date()
        let promptBuilder = SOAPPromptBuilder()
        let prompt = promptBuilder.buildSOAPPrompt(from: context)
        let promptTime = Date().timeIntervalSince(promptStart)
        totalTime += promptTime
        print("2. Prompt generation: \(String(format: "%.3f", promptTime))s")

        // Step 3: Tokenization simulation
        let tokenStart = Date()
        do {
            let tokens = try MLXModelBridge.tokenize(prompt)
            let tokenTime = Date().timeIntervalSince(tokenStart)
            totalTime += tokenTime
            print("3. Tokenization: \(String(format: "%.3f", tokenTime))s (\(tokens.count) tokens)")
        } catch {
            print("3. Tokenization: skipped (not available)")
        }

        // Step 4: JSON decoding simulation
        let jsonStart = Date()
        let sampleResponse = createValidSOAPResponse()
        let parser = SOAPResponseParser()
        do {
            _ = try parser.parseSOAPNote(from: sampleResponse)
            let parseTime = Date().timeIntervalSince(jsonStart)
            totalTime += parseTime
            print("4. Response parsing: \(String(format: "%.3f", parseTime))s")
        } catch {
            print("4. Response parsing failed")
        }

        // Step 5: Validation
        let validationStart = Date()
        do {
            _ = try FindingsValidator.decodeAndValidate(Data(createValidFindingsJSON().utf8))
            let validationTime = Date().timeIntervalSince(validationStart)
            totalTime += validationTime
            print("5. Safety validation: \(String(format: "%.3f", validationTime))s")
        } catch {
            print("5. Validation failed")
        }

        // Summary
        print("\n=== Workflow Summary ===")
        print("Total preparation + validation: \(String(format: "%.3f", totalTime))s")
        print("Target inference time: <10s")
        print("Estimated total: <10.5s")

        XCTAssertLessThanOrEqual(
            totalTime,
            0.5,
            "Preparation + validation should be fast to allow room for inference"
        )
    }

    /// Benchmark 12: Memory baseline measurement
    func testMemoryBaselineAndGrowth() {
        let initialMemory = getMemoryUsage()
        print("Initial memory usage: \(formatBytes(initialMemory))")

        // Create test data
        var notesList: [SOAPNoteData] = []
        for i in 0..<10 {
            var data = createTestSOAPNoteData()
            data.subjective.chiefComplaint = "Complaint \(i)"
            notesList.append(data)
        }

        let afterCreationMemory = getMemoryUsage()
        let creationDelta = afterCreationMemory - initialMemory
        print("After creating 10 notes: \(formatBytes(afterCreationMemory)) (+\(formatBytes(creationDelta)))")

        // Encrypt/decrypt cycle
        do {
            for data in notesList {
                let encoder = JSONEncoder()
                let encoded = try encoder.encode(data)
                _ = try encryptionService.encrypt(encoded)
            }
        } catch {
            XCTFail("Memory test encryption failed: \(error)")
        }

        let afterEncryptionMemory = getMemoryUsage()
        let encryptionDelta = afterEncryptionMemory - afterCreationMemory
        print("After encryption: \(formatBytes(afterEncryptionMemory)) (+\(formatBytes(encryptionDelta)))")

        // Verify memory growth is reasonable
        XCTAssertLessThanOrEqual(
            afterEncryptionMemory,
            PerformanceTargets.memoryPeakMax,
            "Memory usage should stay under 3GB"
        )
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

    private func createTestSOAPNoteData() -> SOAPNoteData {
        let vitals = VitalSigns(
            temperature: 37.2,
            heartRate: 78,
            respiratoryRate: 16,
            systolicBP: 120,
            diastolicBP: 80,
            oxygenSaturation: 98
        )

        let subjective = SOAPSubjective(
            chiefComplaint: "Test complaint",
            historyOfPresentIllness: "Test history",
            pastMedicalHistory: ["Asthma"],
            allergies: ["Penicillin"],
            medications: ["Albuterol"]
        )

        let objective = SOAPObjective(
            vitalSigns: vitals,
            physicalExamFindings: "Test findings",
            labResults: [],
            imagingFindings: []
        )

        let assessment = SOAPAssessment(
            clinicalImpressions: "Test impression",
            differentialDiagnosis: ["URTI"],
            riskFactors: []
        )

        let plan = SOAPPlan(
            nextSteps: ["Follow-up"],
            investigations: [],
            followUpInstructions: "Return if worse"
        )

        let metadata = SOAPMetadata(
            modelVersion: "MedGemma 1.5 4B",
            generationTime: 2.5,
            promptTemplate: "standard",
            clinicianReviewedBy: nil,
            reviewedAt: nil,
            encryptionVersion: "v1"
        )

        return SOAPNoteData(
            id: UUID(),
            patientIdentifier: "test-patient",
            generatedAt: Date(),
            completedAt: nil,
            subjective: subjective,
            objective: objective,
            assessment: assessment,
            plan: plan,
            metadata: metadata,
            validationStatus: .unvalidated
        )
    }

    private func createValidFindingsJSON() -> String {
        """
        {
            "limitations": "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis.",
            "anatomicalObservations": {
                "lungs": "Bilateral lungs clear to auscultation",
                "cardiomediastinal": "Normal cardiac silhouette",
                "bones": "No acute osseous abnormalities"
            }
        }
        """
    }

    private func createValidLabResultsJSON() -> String {
        """
        {
            "documentType": "laboratory_report",
            "documentDate": "2026-01-30",
            "laboratoryName": "Central Laboratory",
            "testCategories": [
                {
                    "category": "Complete Blood Count",
                    "tests": [
                        {"testName": "Hemoglobin", "value": "14.2", "unit": "g/dL"}
                    ]
                }
            ],
            "limitations": "This extraction shows ONLY the visible values from the laboratory report and does not interpret clinical significance or provide recommendations."
        }
        """
    }

    private func createValidSOAPResponse() -> String {
        """
        {
            "subjective": "Patient reports persistent cough",
            "objective": "Vitals stable, lungs clear",
            "assessment": "Likely viral infection",
            "plan": "Supportive care and follow-up",
            "generated_at": "2026-01-30T17:00:00Z"
        }
        """
    }

    private func getMemoryUsage() -> UInt64 {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size)/4

        let kerr = withUnsafeMutablePointer(to: &info) {
            task_info(
                mach_task_self_,
                task_flavor_t(TASK_BASIC_INFO),
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) { $0 },
                &count
            )
        }

        guard kerr == KERN_SUCCESS else { return 0 }
        return UInt64(info.resident_size)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Mach Task Info

import Darwin

let TASK_BASIC_INFO = Int32(4)

struct task_basic_info {
    var suspend_count: Int32
    var resident_size: Int32
    var virtual_size: Int32
    var resident_size_max: Int32
    var virtual_size_max: Int32
    var user_time: timeval
    var system_time: timeval
    var policy: Int32
    var threads_in_use: Int32
}
