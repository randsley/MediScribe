//
//  SOAPNoteValidatorTests.swift
//  MediScribeTests
//
//  Tests for SOAP note safety validation
//

import XCTest
@testable import MediScribe

class SOAPNoteValidatorTests: XCTestCase {
    // MARK: - Test Data Helpers

    func createValidSOAPNoteData() -> SOAPNoteData {
        return SOAPNoteData(
            id: UUID(),
            patientIdentifier: "P001",
            generatedAt: Date(),
            completedAt: nil,
            subjective: SOAPSubjective(
                chiefComplaint: "Patient reports headache for 2 days",
                historyOfPresentIllness: "Headache started after physical activity, associated with mild nausea",
                pastMedicalHistory: ["Hypertension"],
                medications: ["Lisinopril 10mg daily"],
                allergies: ["Penicillin"]
            ),
            objective: SOAPObjective(
                vitalSigns: VitalSignsData(
                    temperature: Measurement(value: 37.5, unit: UnitTemperature.celsius),
                    heartRate: Measurement(value: 72, unit: UnitFrequency.beatsPerMinute),
                    respiratoryRate: Measurement(value: 16, unit: UnitFrequency.beatsPerMinute),
                    systolicBP: 130,
                    diastolicBP: 85,
                    oxygenSaturation: 98,
                    recordedAt: Date()
                ),
                physicalExamFindings: ["Alert and oriented", "No neck stiffness"],
                diagnosticResults: nil
            ),
            assessment: SOAPAssessment(
                clinicalImpression: "Patient presents with acute onset headache. Vital signs are stable. Physical examination shows no focal neurological deficits. Patient appears well.",
                differentialConsiderations: ["Tension headache", "Migraine without aura"],
                problemList: ["Acute headache", "Hypertension - controlled"]
            ),
            plan: SOAPPlan(
                interventions: ["Rest in quiet environment", "Hydration"],
                followUp: ["Return if symptoms worsen or persist beyond 48 hours"],
                patientEducation: ["Symptoms typically resolve with rest"],
                referrals: nil
            ),
            metadata: SOAPMetadata(
                modelVersion: "medgemma-1.5-4b",
                generationTime: 2.5,
                promptTemplate: "standard_sbar",
                clinicianReviewedBy: nil,
                reviewedAt: nil,
                encryptionVersion: "v1"
            ),
            validationStatus: .unvalidated
        )
    }

    // MARK: - Test Cases: Valid Notes

    func testValidNotePassesValidation() throws {
        let noteData = createValidSOAPNoteData()

        // Should not throw
        let validated = try SOAPNoteValidator.validate(noteData)
        XCTAssertEqual(validated.id, noteData.id)
    }

    // MARK: - Test Cases: Assessment Section Validation

    func testForbiddenDiseaseNameInAssessmentBlocked() throws {
        var noteData = createValidSOAPNoteData()
        noteData.assessment.clinicalImpression = "Patient likely has pneumonia based on symptoms"

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssertEqual(validationError.field, "assessment")
            XCTAssertEqual(validationError.severity, .critical)
            XCTAssert(validationError.message.contains("pneumonia"))
        }
    }

    func testForbiddenPhraseDiagnosticLanguageBlocked() throws {
        var noteData = createValidSOAPNoteData()
        noteData.assessment.clinicalImpression = "Findings are consistent with tuberculosis"

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssertEqual(validationError.severity, .critical)
        }
    }

    func testProbabilisticLanguageBlocked() throws {
        var noteData = createValidSOAPNoteData()
        noteData.assessment.clinicalImpression = "Patient likely has a serious condition that suggests cancer"

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssertEqual(validationError.severity, .critical)
        }
    }

    // MARK: - Test Cases: Plan Section Validation

    func testPrescriptiveLanguageInPlanBlocked() throws {
        var noteData = createValidSOAPNoteData()
        noteData.plan.interventions = ["Prescribe antibiotics immediately for infection"]

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssertEqual(validationError.field, "plan")
        }
    }

    func testUrgentLanguageBlocked() throws {
        var noteData = createValidSOAPNoteData()
        noteData.plan.interventions = ["Urgent transfer to hospital required"]

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssertEqual(validationError.field, "plan")
        }
    }

    // MARK: - Test Cases: Schema Validation

    func testMissingChiefComplaintFails() throws {
        var noteData = createValidSOAPNoteData()
        noteData.subjective.chiefComplaint = ""

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssert(validationError.field.contains("chiefComplaint"))
        }
    }

    func testMissingVitalSignsTimestampFails() throws {
        var noteData = createValidSOAPNoteData()
        var vitals = noteData.objective.vitalSigns
        vitals.recordedAt = nil
        noteData.objective.vitalSigns = vitals

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssert(validationError.field.contains("recordedAt"))
        }
    }

    func testMissingClinicalImpressionFails() throws {
        var noteData = createValidSOAPNoteData()
        noteData.assessment.clinicalImpression = ""

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssert(validationError.field.contains("clinicalImpression"))
        }
    }

    // MARK: - Test Cases: Multi-Language Validation

    func testEnglishForbiddenPhrasesDetected() throws {
        var noteData = createValidSOAPNoteData()
        noteData.assessment.clinicalImpression = "Diagnosis of pneumonia confirmed"

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData, language: .english)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssertEqual(validationError.severity, .critical)
        }
    }

    func testSpanishForbiddenPhrasesDetected() throws {
        var noteData = createValidSOAPNoteData()
        noteData.assessment.clinicalImpression = "Diagnóstico de neumonía confirmado"

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData, language: .spanish)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssertEqual(validationError.severity, .critical)
        }
    }

    func testFrenchForbiddenPhrasesDetected() throws {
        var noteData = createValidSOAPNoteData()
        noteData.assessment.clinicalImpression = "Diagnostic de pneumonie confirmé"

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData, language: .french)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssertEqual(validationError.severity, .critical)
        }
    }

    func testPortugueseForbiddenPhrasesDetected() throws {
        var noteData = createValidSOAPNoteData()
        noteData.assessment.clinicalImpression = "Diagnóstico de pneumonia confirmado"

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData, language: .portuguese)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssertEqual(validationError.severity, .critical)
        }
    }

    // MARK: - Test Cases: Obfuscation Detection

    func testObfuscatedForbiddenPhraseDetected() throws {
        var noteData = createValidSOAPNoteData()
        // Try to obfuscate "pneumonia"
        noteData.assessment.clinicalImpression = "Patient has p-n-e-u-m-o-n-i-a symptoms"

        XCTAssertThrowsError(try SOAPNoteValidator.validate(noteData, language: .english)) { error in
            guard let validationError = error as? SOAPNoteValidationError else {
                XCTFail("Expected SOAPNoteValidationError")
                return
            }
            XCTAssertEqual(validationError.severity, .critical)
        }
    }

    // MARK: - Test Cases: Error Messages

    func testValidationErrorDisplayMessage() throws {
        let error = SOAPNoteValidationError(
            field: "assessment.clinicalImpression",
            message: "Forbidden phrase detected",
            severity: .critical
        )

        XCTAssert(error.displayMessage.contains("🛑"))
        XCTAssert(error.displayMessage.contains("SAFETY BLOCK"))
    }

    func testValidationErrorDescription() throws {
        let error = SOAPNoteValidationError(
            field: "test_field",
            message: "Test error message",
            severity: .error
        )

        XCTAssertEqual(error.errorDescription, "test_field: Test error message")
    }
}
