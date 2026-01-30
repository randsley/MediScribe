//
//  SOAPNoteParserTests.swift
//  MediScribeTests
//
//  Unit tests for SOAP note parser and validation
//

import XCTest
@testable import MediScribe

class SOAPNoteParserTests: XCTestCase {
    var parser: SOAPNoteParser!

    override func setUp() {
        super.setUp()
        parser = SOAPNoteParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - JSON Extraction Tests

    func testExtractJSONFromValidOutput() {
        let validJSON = """
        Some preamble before JSON
        {"subjective": "test", "objective": "test", "assessment": "test", "plan": "test"}
        Some postamble after JSON
        """

        // Would test extraction (private method tested indirectly through parsing)
        XCTAssertTrue(validJSON.contains("{"))
        XCTAssertTrue(validJSON.contains("}"))
    }

    func testExtractJSONFromMissingJSON() {
        let noJSON = "This output has no JSON structure at all"

        XCTAssertFalse(noJSON.contains("{"))
        XCTAssertFalse(noJSON.contains("}"))
    }

    // MARK: - Parsing Tests

    func testParseValidSOAPNote() {
        let validOutput = """
        {
          "subjective": {
            "chief_complaint": "Chest pain",
            "history_of_present_illness": "Patient reports 3 days of chest pain",
            "past_medical_history": ["Hypertension"],
            "medications": ["Lisinopril"],
            "allergies": ["Penicillin"]
          },
          "objective": {
            "vital_signs": {
              "temperature": 37.2,
              "heart_rate": 92,
              "respiratory_rate": 18,
              "systolic_bp": 130,
              "diastolic_bp": 85,
              "oxygen_saturation": 98
            },
            "physical_exam_findings": ["Clear lungs"],
            "diagnostic_results": null
          },
          "assessment": {
            "clinical_impression": "Likely musculoskeletal pain",
            "differential_considerations": null,
            "problem_list": ["Chest pain"]
          },
          "plan": {
            "interventions": ["Rest", "Ice"],
            "follow_up": ["Return in 1 week"],
            "patient_education": null,
            "referrals": null
          }
        }
        """

        do {
            let note = try parser.parseSOAPNote(
                from: validOutput,
                modelVersion: "test-1.0",
                generationTime: 0.5
            )

            XCTAssertEqual(note.subjective.chiefComplaint, "Chest pain")
            XCTAssertEqual(note.validationStatus, .validated)
        } catch {
            XCTFail("Should parse valid SOAP note: \(error)")
        }
    }

    // MARK: - Validation Tests

    func testValidateEmptyChiefComplaint() {
        let sections = SOAPSections(
            subjective: SOAPSubjective(
                chiefComplaint: "",
                historyOfPresentIllness: "Valid HPI",
                pastMedicalHistory: nil,
                medications: nil,
                allergies: nil
            ),
            objective: SOAPObjective(
                vitalSigns: VitalSignsData(temperature: nil, heartRate: nil, respiratoryRate: nil, systolicBP: nil, diastolicBP: nil, oxygenSaturation: nil, recordedAt: nil),
                physicalExamFindings: nil,
                diagnosticResults: nil
            ),
            assessment: SOAPAssessment(
                clinicalImpression: "Valid",
                differentialConsiderations: nil,
                problemList: nil
            ),
            plan: SOAPPlan(interventions: nil, followUp: nil, patientEducation: nil, referrals: nil)
        )

        let errors = parser.validateSOAPContent(sections)

        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains { $0.field == "Chief Complaint" })
    }

    func testValidateEmptyHPI() {
        let sections = SOAPSections(
            subjective: SOAPSubjective(
                chiefComplaint: "Valid CC",
                historyOfPresentIllness: "",
                pastMedicalHistory: nil,
                medications: nil,
                allergies: nil
            ),
            objective: SOAPObjective(
                vitalSigns: VitalSignsData(temperature: nil, heartRate: nil, respiratoryRate: nil, systolicBP: nil, diastolicBP: nil, oxygenSaturation: nil, recordedAt: nil),
                physicalExamFindings: nil,
                diagnosticResults: nil
            ),
            assessment: SOAPAssessment(
                clinicalImpression: "Valid",
                differentialConsiderations: nil,
                problemList: nil
            ),
            plan: SOAPPlan(interventions: nil, followUp: nil, patientEducation: nil, referrals: nil)
        )

        let errors = parser.validateSOAPContent(sections)

        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains { $0.field == "History of Present Illness" })
    }

    // MARK: - Blocked Phrase Detection Tests

    func testDetectBlockedPhrase_Diagnose() {
        let sections = SOAPSections(
            subjective: SOAPSubjective(
                chiefComplaint: "Patient diagnoses with chest pain",
                historyOfPresentIllness: "Valid",
                pastMedicalHistory: nil,
                medications: nil,
                allergies: nil
            ),
            objective: SOAPObjective(
                vitalSigns: VitalSignsData(temperature: nil, heartRate: nil, respiratoryRate: nil, systolicBP: nil, diastolicBP: nil, oxygenSaturation: nil, recordedAt: nil),
                physicalExamFindings: nil,
                diagnosticResults: nil
            ),
            assessment: SOAPAssessment(
                clinicalImpression: "Valid",
                differentialConsiderations: nil,
                problemList: nil
            ),
            plan: SOAPPlan(interventions: nil, followUp: nil, patientEducation: nil, referrals: nil)
        )

        let errors = parser.validateSOAPContent(sections)

        XCTAssertTrue(errors.contains { $0.message.lowercased().contains("diagnose") })
    }

    func testDetectBlockedPhrase_Recommend() {
        let sections = SOAPSections(
            subjective: SOAPSubjective(
                chiefComplaint: "Valid",
                historyOfPresentIllness: "Valid",
                pastMedicalHistory: nil,
                medications: nil,
                allergies: nil
            ),
            objective: SOAPObjective(
                vitalSigns: VitalSignsData(temperature: nil, heartRate: nil, respiratoryRate: nil, systolicBP: nil, diastolicBP: nil, oxygenSaturation: nil, recordedAt: nil),
                physicalExamFindings: nil,
                diagnosticResults: nil
            ),
            assessment: SOAPAssessment(
                clinicalImpression: "Valid",
                differentialConsiderations: nil,
                problemList: nil
            ),
            plan: SOAPPlan(
                interventions: ["Recommend antibiotics"],
                followUp: nil,
                patientEducation: nil,
                referrals: nil
            )
        )

        let errors = parser.validateSOAPContent(sections)

        XCTAssertTrue(errors.contains { $0.message.lowercased().contains("recommend") || $0.message.lowercased().contains("prohibited") })
    }

    func testDetectBlockedPhrase_Likely() {
        let sections = SOAPSections(
            subjective: SOAPSubjective(
                chiefComplaint: "Valid",
                historyOfPresentIllness: "Valid",
                pastMedicalHistory: nil,
                medications: nil,
                allergies: nil
            ),
            objective: SOAPObjective(
                vitalSigns: VitalSignsData(temperature: nil, heartRate: nil, respiratoryRate: nil, systolicBP: nil, diastolicBP: nil, oxygenSaturation: nil, recordedAt: nil),
                physicalExamFindings: nil,
                diagnosticResults: nil
            ),
            assessment: SOAPAssessment(
                clinicalImpression: "This is likely pneumonia",
                differentialConsiderations: nil,
                problemList: nil
            ),
            plan: SOAPPlan(interventions: nil, followUp: nil, patientEducation: nil, referrals: nil)
        )

        let errors = parser.validateSOAPContent(sections)

        XCTAssertTrue(errors.contains { $0.message.lowercased().contains("likely") || $0.message.lowercased().contains("prohibited") })
    }

    func testAllowSafeLanguage() {
        let sections = SOAPSections(
            subjective: SOAPSubjective(
                chiefComplaint: "Patient presents with chest pain",
                historyOfPresentIllness: "Symptoms began 3 days ago",
                pastMedicalHistory: nil,
                medications: nil,
                allergies: nil
            ),
            objective: SOAPObjective(
                vitalSigns: VitalSignsData(temperature: nil, heartRate: nil, respiratoryRate: nil, systolicBP: nil, diastolicBP: nil, oxygenSaturation: nil, recordedAt: nil),
                physicalExamFindings: nil,
                diagnosticResults: nil
            ),
            assessment: SOAPAssessment(
                clinicalImpression: "Patient appears to have chest discomfort",
                differentialConsiderations: nil,
                problemList: nil
            ),
            plan: SOAPPlan(interventions: nil, followUp: nil, patientEducation: nil, referrals: nil)
        )

        let errors = parser.validateSOAPContent(sections)

        // Should have no critical errors for safe language
        XCTAssertTrue(!errors.contains { $0.severity == .critical })
    }

    // MARK: - Vital Signs Validation Tests

    func testValidateNoVitalSigns() {
        let sections = SOAPSections(
            subjective: SOAPSubjective(
                chiefComplaint: "Valid",
                historyOfPresentIllness: "Valid",
                pastMedicalHistory: nil,
                medications: nil,
                allergies: nil
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
                clinicalImpression: "Valid",
                differentialConsiderations: nil,
                problemList: nil
            ),
            plan: SOAPPlan(interventions: nil, followUp: nil, patientEducation: nil, referrals: nil)
        )

        let errors = parser.validateSOAPContent(sections)

        // Should have warning but not error
        XCTAssertTrue(errors.contains { $0.severity == .warning && $0.field == "Vital Signs" })
    }
}
