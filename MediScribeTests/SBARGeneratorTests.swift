//
//  SBARGeneratorTests.swift
//  MediScribeTests
//
//  Tests for SBAR handoff generation
//

import XCTest
@testable import MediScribe

final class SBARGeneratorTests: XCTestCase {

    // MARK: - Complete Note Test

    func testCompleteNoteGeneration() {
        let note = createSampleNote()
        let sbar = SBARGenerator.generate(from: note)

        // Situation
        XCTAssertTrue(sbar.situation.patientSummary.contains("PAT-123"))
        XCTAssertTrue(sbar.situation.patientSummary.contains("45yo"))
        XCTAssertTrue(sbar.situation.patientSummary.contains("male"))
        XCTAssertEqual(sbar.situation.chiefComplaint, "Chest pain")
        XCTAssertEqual(sbar.situation.acuity, "START red")

        // Background
        XCTAssertEqual(sbar.background.allergies, "Penicillin")
        XCTAssertEqual(sbar.background.medications, "Aspirin 81mg daily")
        XCTAssertNotNil(sbar.background.workingDiagnoses)
        XCTAssertTrue(sbar.background.workingDiagnoses!.contains("Acute coronary syndrome"))

        // Assessment
        XCTAssertNotNil(sbar.assessment.latestVitals)
        XCTAssertEqual(sbar.assessment.stability, "unstable")

        // Recommendation
        XCTAssertEqual(sbar.recommendation.disposition, "transfer")
        XCTAssertNotNil(sbar.recommendation.urgency)
    }

    // MARK: - Situation Generation Tests

    func testSituationWithCriticalVitals() {
        var note = createSampleNote()

        // Add critical vital signs
        var vitals = VitalSet()
        vitals.spo2 = 85  // Critical
        vitals.heartRate = 135  // Tachycardia
        vitals.bloodPressure = BloodPressure(systolic: 80, diastolic: 50)  // Hypotensive
        note.objective?.vitals = [vitals]

        let sbar = SBARGenerator.generate(from: note)

        XCTAssertNotNil(sbar.situation.worstVital)
        XCTAssertTrue(sbar.situation.worstVital!.contains("SpO2 85"))
        XCTAssertTrue(sbar.situation.worstVital!.contains("HR 135"))
        XCTAssertTrue(sbar.situation.worstVital!.contains("BP 80"))
    }

    func testSituationWithNormalVitals() {
        var note = createMinimalNote()

        // Add normal vitals
        var vitals = VitalSet()
        vitals.spo2 = 98
        vitals.heartRate = 75
        vitals.bloodPressure = BloodPressure(systolic: 120, diastolic: 80)
        note.objective = NoteObjective(vitals: [vitals])

        let sbar = SBARGenerator.generate(from: note)

        // Should not flag normal vitals as "worst"
        XCTAssertNil(sbar.situation.worstVital)
    }

    // MARK: - Background Generation Tests

    func testBackgroundWithKeyRisks() {
        var note = createMinimalNote()
        note.subjective = NoteSubjective()
        note.subjective?.keyRisks = ["Diabetes", "Anticoagulation", "Pregnancy"]

        let sbar = SBARGenerator.generate(from: note)

        XCTAssertNotNil(sbar.background.keyComorbidities)
        XCTAssertEqual(sbar.background.keyComorbidities?.count, 3)
        XCTAssertTrue(sbar.background.keyComorbidities!.contains("Diabetes"))
    }

    func testBackgroundWithMechanism() {
        var note = createMinimalNote()
        note.subjective = NoteSubjective()
        note.subjective?.mechanismOrExposure = "Motor vehicle collision, high speed"

        let sbar = SBARGenerator.generate(from: note)

        XCTAssertEqual(sbar.background.mechanismOrExposure, "Motor vehicle collision, high speed")
    }

    // MARK: - Assessment Generation Tests

    func testAssessmentWithExamHighlights() {
        var note = createMinimalNote()
        note.objective = NoteObjective()
        note.objective?.primarySurvey = "ABCDE: A clear, B bilateral air entry"
        note.objective?.focusedExam = [
            "cardiovascular": ["Regular rate", "No murmurs"],
            "respiratory": ["Crackles at bases"]
        ]
        note.objective?.pointOfCareTests = ["Glucose 95 mg/dL"]

        let sbar = SBARGenerator.generate(from: note)

        XCTAssertNotNil(sbar.assessment.examHighlights)
        let highlights = sbar.assessment.examHighlights!.joined(separator: " ")
        XCTAssertTrue(highlights.contains("ABCDE"))
        XCTAssertTrue(highlights.contains("Cardiovascular"))
        XCTAssertTrue(highlights.contains("POC"))
    }

    func testAssessmentWithRedFlags() {
        var note = createMinimalNote()
        note.assessment = NoteAssessment()
        note.assessment?.redFlags = ["Altered mental status", "Hypoxia despite oxygen"]

        let sbar = SBARGenerator.generate(from: note)

        XCTAssertNotNil(sbar.assessment.redFlags)
        XCTAssertEqual(sbar.assessment.redFlags?.count, 2)
    }

    // MARK: - Recommendation Generation Tests

    func testRecommendationWithInterventions() {
        var note = createMinimalNote()
        note.interventions = [
            NoteIntervention(type: "oxygen", details: "15L NRB", performedAt: Date()),
            NoteIntervention(type: "iv_access", details: "18G x 2", performedAt: Date())
        ]

        let sbar = SBARGenerator.generate(from: note)

        XCTAssertNotNil(sbar.recommendation.interventionsPerformed)
        XCTAssertEqual(sbar.recommendation.interventionsPerformed?.count, 2)
        XCTAssertTrue(sbar.recommendation.interventionsPerformed!.contains("oxygen: 15L NRB"))
    }

    func testRecommendationUrgentTransport() {
        var note = createMinimalNote()
        note.plan = NotePlan()
        note.plan?.disposition = Disposition(
            type: .transfer,
            destination: "Regional Trauma Center",
            urgency: .immediate
        )

        let sbar = SBARGenerator.generate(from: note)

        XCTAssertEqual(sbar.recommendation.disposition, "transfer")
        XCTAssertEqual(sbar.recommendation.destination, "Regional Trauma Center")
        XCTAssertEqual(sbar.recommendation.urgency, "immediate")
        XCTAssertNotNil(sbar.recommendation.transportNeeds)
        XCTAssertTrue(sbar.recommendation.transportNeeds!.contains("Urgent"))
    }

    // MARK: - Text Formatting Tests

    func testFormattedTextOutput() {
        let note = createSampleNote()
        let text = SBARGenerator.generateText(from: note)

        // Check structure
        XCTAssertTrue(text.contains("SITUATION"))
        XCTAssertTrue(text.contains("BACKGROUND"))
        XCTAssertTrue(text.contains("ASSESSMENT"))
        XCTAssertTrue(text.contains("RECOMMENDATION"))

        // Check content
        XCTAssertTrue(text.contains("PAT-123"))
        XCTAssertTrue(text.contains("Chest pain"))
    }

    // MARK: - Minimal Note Tests

    func testMinimalNoteDoesNotCrash() {
        let note = createMinimalNote()

        // Should not crash even with minimal data
        XCTAssertNoThrow(SBARGenerator.generate(from: note))
        XCTAssertNoThrow(SBARGenerator.generateText(from: note))
    }

    // MARK: - Helper Methods

    private func createSampleNote() -> FieldNote {
        var note = FieldNote(
            meta: NoteMeta(
                author: NoteAuthor(id: "dr_001", displayName: "Dr. Smith", role: "Physician"),
                patient: NotePatient(id: "PAT-123", estimatedAgeYears: 45, sexAtBirth: .male),
                encounter: NoteEncounter(setting: .ambulance, locationText: "Highway 101"),
                consent: NoteConsent(status: .impliedEmergency)
            )
        )

        note.triage = NoteTriage(system: .start, category: .red)

        note.subjective = NoteSubjective()
        note.subjective?.chiefComplaint = "Chest pain"
        note.subjective?.allergies = "Penicillin"
        note.subjective?.medications = "Aspirin 81mg daily"

        note.objective = NoteObjective()
        var vitals = VitalSet()
        vitals.bloodPressure = BloodPressure(systolic: 95, diastolic: 60)
        vitals.heartRate = 110
        vitals.spo2 = 92
        note.objective?.vitals = [vitals]

        note.assessment = NoteAssessment()
        note.assessment?.workingDiagnoses = [
            Diagnosis(label: "Acute coronary syndrome", certainty: .possible)
        ]
        note.assessment?.stability = Stability.unstable

        note.plan = NotePlan()
        note.plan?.disposition = Disposition(type: .transfer, destination: "Cardiac Center", urgency: .immediate)

        return note
    }

    private func createMinimalNote() -> FieldNote {
        return FieldNote(
            meta: NoteMeta(
                author: NoteAuthor(id: "test", displayName: "Test", role: "Test"),
                patient: NotePatient(id: "TEST-001"),
                encounter: NoteEncounter(setting: .roadside),
                consent: NoteConsent(status: .notPossible)
            )
        )
    }
}
