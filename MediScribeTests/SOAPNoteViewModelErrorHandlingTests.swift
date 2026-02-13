//
//  SOAPNoteViewModelErrorHandlingTests.swift
//  MediScribeTests
//
//  Tests for SOAP note ViewModel error handling
//

import XCTest
@testable import MediScribe

class SOAPNoteViewModelErrorHandlingTests: XCTestCase {
    // MARK: - Properties

    var viewModel: SOAPNoteViewModel!
    var mockRepository: EHMockSOAPNoteRepository!
    var mockGenerator: EHMockSOAPNoteGenerator!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create mock repository that can throw validation errors
        mockRepository = EHMockSOAPNoteRepository()
        mockGenerator = EHMockSOAPNoteGenerator()

        // Initialize ViewModel with mocks
        viewModel = SOAPNoteViewModel(
            soapGenerator: mockGenerator,
            parser: SOAPNoteParser(),
            repository: mockRepository
        )
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        mockGenerator = nil
        super.tearDown()
    }

    // MARK: - Test Cases: Validation Error Handling

    func testValidationErrorIsDisplayedToUser() {
        // Setup: Mock repository to throw validation error
        let validationError = SOAPNoteValidationError(
            field: "assessment.clinicalImpression",
            message: "Forbidden phrase detected: diagnosis",
            severity: .critical
        )
        mockRepository.nextError = validationError

        // Setup: Valid input
        viewModel.patientAge = "45"
        viewModel.chiefComplaint = "Headache"

        // Act: Generate note (which will fail validation on save)
        viewModel.generateSOAPNote()

        // Wait for async operation
        let expectation = XCTestExpectation(description: "Validation error handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Assert: Error is displayed
        XCTAssertTrue(viewModel.hasValidationErrors)
        XCTAssertFalse(viewModel.validationErrors.isEmpty)
        XCTAssertTrue(viewModel.showError)
        XCTAssertNotNil(viewModel.validationFailureReason)
        XCTAssertTrue(viewModel.validationFailureReason!.contains("diagnosis"))
    }

    func testGenerationStateShowsValidationFailure() {
        // Setup: Mock repository to throw validation error
        let validationError = SOAPNoteValidationError(
            field: "assessment",
            message: "Assessment contains diagnostic language",
            severity: .critical
        )
        mockRepository.nextError = validationError

        // Setup: Valid input
        viewModel.patientAge = "30"
        viewModel.chiefComplaint = "Fever"

        // Act: Generate note
        viewModel.generateSOAPNote()

        // Wait for async operation
        let expectation = XCTestExpectation(description: "State updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Assert: Generation state reflects validation failure
        XCTAssertTrue(viewModel.generationState.isValidationFailed)
    }

    func testValidationErrorMessageFormatted() {
        // Setup: Create validation error
        let error = SOAPNoteValidationError(
            field: "plan.interventions",
            message: "Prescriptive language detected: recommend",
            severity: .error
        )

        // Act: Check display message
        let displayMessage = error.displayMessage

        // Assert: Display message includes severity indicator
        XCTAssertTrue(displayMessage.contains("❌"))
        XCTAssertTrue(displayMessage.contains("recommend"))
    }

    func testCriticalValidationErrorShowsWarning() {
        // Setup: Create critical validation error
        let error = SOAPNoteValidationError(
            field: "assessment.clinicalImpression",
            message: "Diagnostic conclusion detected",
            severity: .critical
        )

        // Assert: Critical errors have special indicator
        XCTAssertTrue(error.displayMessage.contains("🛑"))
        XCTAssertTrue(error.displayMessage.contains("SAFETY BLOCK"))
    }

    func testValidationErrorClearedAfterSuccessfulGeneration() {
        // Setup: First set an error
        viewModel.validationErrors = [
            SOAPNoteValidationError(
                field: "test",
                message: "Test error",
                severity: .error
            )
        ]
        viewModel.hasValidationErrors = true

        // Setup: Valid input
        viewModel.patientAge = "50"
        viewModel.chiefComplaint = "Dizziness"

        // Setup: Mock successful generation
        mockRepository.shouldSucceed = true

        // Act: Generate (should succeed)
        viewModel.generateSOAPNote()

        // Wait for async operation
        let expectation = XCTestExpectation(description: "Errors cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Assert: Previous errors are cleared
        XCTAssertTrue(viewModel.validationErrors.isEmpty)
        XCTAssertFalse(viewModel.hasValidationErrors)
    }

    func testStreamingValidationErrorHandled() {
        // Setup: Mock repository to throw validation error during streaming
        let validationError = SOAPNoteValidationError(
            field: "assessment",
            message: "Contains diagnosis",
            severity: .critical
        )
        mockRepository.nextError = validationError

        // Setup: Valid input
        viewModel.patientAge = "40"
        viewModel.chiefComplaint = "Back pain"

        // Act: Generate with streaming
        viewModel.generateSOAPNoteStreaming()

        // Wait for async operation
        let expectation = XCTestExpectation(description: "Streaming error handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Assert: Streaming state shows validation failure
        XCTAssertTrue(viewModel.streamingState.isValidationFailed)
        XCTAssertTrue(viewModel.hasValidationErrors)
    }

    func testNonValidationErrorHandledSeparately() {
        // Setup: Mock repository to throw generic error
        let genericError = NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database error"])
        mockRepository.nextGenericError = genericError

        // Setup: Valid input
        viewModel.patientAge = "35"
        viewModel.chiefComplaint = "Cough"

        // Act: Generate note
        viewModel.generateSOAPNote()

        // Wait for async operation
        let expectation = XCTestExpectation(description: "Generic error handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Assert: Generic error shown, not validation error
        XCTAssertTrue(viewModel.generationState.isError)
        XCTAssertTrue(viewModel.hasValidationErrors == false)
        XCTAssertTrue(viewModel.showError)
    }

    func testInputValidationStillWorks() {
        // Act: Try to generate without required fields
        viewModel.patientAge = ""
        viewModel.chiefComplaint = ""

        viewModel.generateSOAPNote()

        // Assert: Input validation prevents generation
        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.generationState, .idle)
    }
}

// MARK: - Mock Classes

class EHMockSOAPNoteRepository: SOAPNoteRepository {
    var shouldSucceed = false
    var nextError: SOAPNoteValidationError?
    var nextGenericError: NSError?

    override func save(_ noteData: SOAPNoteData) throws -> UUID {
        if let validationError = nextError {
            throw validationError
        }
        if let genericError = nextGenericError {
            throw genericError
        }
        if shouldSucceed {
            return noteData.id
        }
        throw NSError(domain: "Mock", code: -1)
    }
}

class EHMockSOAPNoteGenerator: SOAPNoteGenerator {
    // Mock generator that returns placeholder data
    override func generateSOAPNote(
        from context: PatientContext,
        language: Language = .english,
        options: SOAPGenerationOptions = .default
    ) async throws -> SOAPNoteData {
        return SOAPNoteData(
            patientIdentifier: nil,
            generatedAt: Date(),
            subjective: SOAPSubjective(
                chiefComplaint: context.chiefComplaint,
                historyOfPresentIllness: "Patient reports \(context.chiefComplaint)",
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
                clinicalImpression: "Vital signs stable",
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
                generationTime: 0.1,
                promptTemplate: "test",
                clinicianReviewedBy: nil,
                reviewedAt: nil,
                encryptionVersion: "1.0"
            ),
            validationStatus: .validated
        )
    }
}
