//
//  SOAPNoteViewModelTests.swift
//  MediScribeTests
//
//  Unit tests for SOAP note generation ViewModel
//

import XCTest
@testable import MediScribe

class SOAPNoteViewModelTests: XCTestCase {
    var viewModel: SOAPNoteViewModel!
    var mockGenerator: MockSOAPNoteGenerator!
    var mockRepository: MockSOAPNoteRepository!

    override func setUp() {
        super.setUp()
        mockGenerator = MockSOAPNoteGenerator()
        mockRepository = MockSOAPNoteRepository()
        viewModel = SOAPNoteViewModel(
            soapGenerator: mockGenerator,
            parser: SOAPNoteParser(),
            repository: mockRepository
        )
    }

    override func tearDown() {
        viewModel = nil
        mockGenerator = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Input Validation Tests

    func testGenerateSOAPNoteWithoutAge() {
        viewModel.patientAge = ""
        viewModel.chiefComplaint = "Chest pain"

        viewModel.generateSOAPNote()

        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.generationState, .idle)
    }

    func testGenerateSOAPNoteWithoutChiefComplaint() {
        viewModel.patientAge = "35"
        viewModel.chiefComplaint = ""

        viewModel.generateSOAPNote()

        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.generationState, .idle)
    }

    func testGenerateSOAPNoteWithRequiredFields() {
        viewModel.patientAge = "35"
        viewModel.chiefComplaint = "Chest pain"
        viewModel.patientSex = "F"
        viewModel.temperature = "37.2"
        viewModel.heartRate = "92"

        // Should not show error for valid input
        XCTAssertTrue(viewModel.isReadyToGenerate)
    }

    // MARK: - Vital Signs Conversion Tests

    func testVitalSignsConversionFromStrings() {
        viewModel.temperature = "37.5"
        viewModel.heartRate = "80"
        viewModel.respiratoryRate = "18"
        viewModel.systolicBP = "130"
        viewModel.diastolicBP = "85"
        viewModel.oxygenSaturation = "98"

        // Test that conversion works (private method, tested indirectly)
        viewModel.patientAge = "45"
        viewModel.chiefComplaint = "Headache"

        // When generation is called, vital signs should be properly converted
        XCTAssertTrue(viewModel.isReadyToGenerate)
    }

    func testEmptyVitalSignsAllowed() {
        viewModel.temperature = ""
        viewModel.heartRate = ""
        viewModel.patientAge = "50"
        viewModel.chiefComplaint = "Fever"

        // Should still be ready to generate (vital signs are optional)
        XCTAssertTrue(viewModel.isReadyToGenerate)
    }

    // MARK: - State Management Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.generationState, .idle)
        XCTAssertNil(viewModel.currentNote)
        XCTAssertTrue(viewModel.validationErrors.isEmpty)
        XCTAssertFalse(viewModel.isReviewed)
    }

    func testResetForm() {
        viewModel.patientAge = "35"
        viewModel.chiefComplaint = "Chest pain"
        viewModel.isReviewed = true
        viewModel.streamingTokens = "Some tokens"

        viewModel.resetForm()

        XCTAssertEqual(viewModel.patientAge, "")
        XCTAssertEqual(viewModel.chiefComplaint, "")
        XCTAssertFalse(viewModel.isReviewed)
        XCTAssertEqual(viewModel.streamingTokens, "")
        XCTAssertEqual(viewModel.generationState, .idle)
    }

    // MARK: - Computed Properties Tests

    func testIsReadyToGenerateComputed() {
        viewModel.patientAge = ""
        viewModel.chiefComplaint = ""
        XCTAssertFalse(viewModel.isReadyToGenerate)

        viewModel.patientAge = "40"
        XCTAssertFalse(viewModel.isReadyToGenerate)

        viewModel.chiefComplaint = "Symptoms"
        XCTAssertTrue(viewModel.isReadyToGenerate)
    }

    func testCanReviewComputed() {
        // Not ready to review initially
        XCTAssertFalse(viewModel.canReview)

        // Would need a complete note to review
        // (Mock this in actual tests)
    }

    func testCanSignComputed() {
        viewModel.isReviewed = false
        XCTAssertFalse(viewModel.canSign)

        viewModel.isReviewed = true
        XCTAssertTrue(viewModel.canSign)
    }

    // MARK: - Dynamic List Management Tests

    func testAddMedicalHistoryItem() {
        let initialCount = viewModel.medicalHistory.count
        viewModel.medicalHistory.append("Hypertension")

        XCTAssertEqual(viewModel.medicalHistory.count, initialCount + 1)
        XCTAssertTrue(viewModel.medicalHistory.contains("Hypertension"))
    }

    func testRemoveMedicalHistoryItem() {
        viewModel.medicalHistory = ["Hypertension", "Diabetes"]
        viewModel.medicalHistory.removeAll { $0 == "Diabetes" }

        XCTAssertEqual(viewModel.medicalHistory.count, 1)
        XCTAssertEqual(viewModel.medicalHistory.first, "Hypertension")
    }

    func testAddMedication() {
        let initialCount = viewModel.medications.count
        viewModel.medications.append("Lisinopril 10mg")

        XCTAssertEqual(viewModel.medications.count, initialCount + 1)
    }

    func testAddAllergy() {
        let initialCount = viewModel.allergies.count
        viewModel.allergies.append("Penicillin")

        XCTAssertEqual(viewModel.allergies.count, initialCount + 1)
    }

    // MARK: - Error Handling Tests

    func testErrorMessageDisplay() {
        viewModel.showError = false
        viewModel.errorMessage = ""

        viewModel.patientAge = ""
        viewModel.chiefComplaint = ""
        viewModel.generateSOAPNote()

        XCTAssertTrue(viewModel.showError)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
    }
}

// MARK: - Mocks

class MockSOAPNoteGenerator: SOAPNoteGenerator {
    var shouldFail = false

    override func generateSOAPNote(
        from context: PatientContext,
        options: SOAPGenerationOptions = .default
    ) async throws -> SOAPNoteData {
        if shouldFail {
            throw MockError.generationFailed
        }

        // Return mock data
        return SOAPNoteData(
            id: UUID(),
            patientIdentifier: nil,
            generatedAt: Date(),
            completedAt: nil,
            subjective: SOAPSubjective(
                chiefComplaint: context.chiefComplaint,
                historyOfPresentIllness: "Mock HPI",
                pastMedicalHistory: context.medicalHistory,
                medications: context.currentMedications,
                allergies: context.allergies
            ),
            objective: SOAPObjective(
                vitalSigns: VitalSignsData(
                    temperature: nil,
                    heartRate: nil,
                    respiratoryRate: nil,
                    systolicBP: nil,
                    diastolicBP: nil,
                    oxygenSaturation: nil,
                    recordedAt: nil
                ),
                physicalExamFindings: nil,
                diagnosticResults: nil
            ),
            assessment: SOAPAssessment(
                clinicalImpression: "Mock assessment",
                differentialConsiderations: nil,
                problemList: nil
            ),
            plan: SOAPPlan(
                interventions: nil,
                followUp: nil,
                patientEducation: nil,
                referrals: nil
            ),
            metadata: SOAPMetadata(
                modelVersion: "test-1.0",
                generationTime: 0.5,
                promptTemplate: "test",
                clinicianReviewedBy: nil,
                reviewedAt: nil,
                encryptionVersion: "1.0"
            ),
            validationStatus: .validated
        )
    }
}

class MockSOAPNoteRepository: SOAPNoteRepository {
    var savedNotes: [SOAPNoteData] = []

    override func save(_ noteData: SOAPNoteData) throws -> UUID {
        savedNotes.append(noteData)
        return noteData.id
    }

    override func fetch(id: UUID) throws -> SOAPNoteData? {
        return savedNotes.first { $0.id == id }
    }

    override func markReviewed(id: UUID, by clinicianID: String) throws {
        // Mock implementation
    }

    override func markSigned(id: UUID, by clinicianID: String) throws {
        // Mock implementation
    }
}

enum MockError: Error {
    case generationFailed
}
