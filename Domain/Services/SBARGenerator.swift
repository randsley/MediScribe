//
//  SBARGenerator.swift
//  MediScribe
//
//  Generates SBAR (Situation, Background, Assessment, Recommendation) handoff summaries
//  from FieldNote data for clinical communication and patient transfers
//

import Foundation

struct SBARGenerator {

    /// Generates a complete SBAR summary from a FieldNote
    /// - Parameter note: The field note to generate SBAR from
    /// - Returns: Populated SBAR structure
    static func generate(from note: FieldNote) -> SBAR {
        return SBAR(
            situation: generateSituation(from: note),
            background: generateBackground(from: note),
            assessment: generateAssessment(from: note),
            recommendation: generateRecommendation(from: note)
        )
    }

    /// Generates formatted SBAR text suitable for verbal handoff or documentation
    /// - Parameter note: The field note to generate SBAR from
    /// - Returns: Formatted SBAR text
    static func generateText(from note: FieldNote) -> String {
        let sbar = generate(from: note)
        return formatSBAR(sbar)
    }

    // MARK: - Section Generators

    private static func generateSituation(from note: FieldNote) -> SBARSituation {
        let patientSummary = "\(note.meta.patient.id), \(genderAndAge(note.meta.patient))"

        let triageSummary: String?
        if let triage = note.triage {
            triageSummary = "\(triage.system.rawValue.uppercased()) \(triage.category.rawValue)"
        } else {
            triageSummary = nil
        }

        let worstVital = findWorstVital(note.objective?.vitals ?? [])
        let chiefComplaint = note.subjective?.chiefComplaint

        let location: String?
        let setting = note.meta.encounter.setting.rawValue.capitalized
        if let locationText = note.meta.encounter.locationText {
            location = "\(setting) - \(locationText)"
        } else {
            location = setting
        }

        return SBARSituation(
            patientSummary: patientSummary,
            location: location,
            acuity: triageSummary,
            chiefComplaint: chiefComplaint,
            worstVital: worstVital
        )
    }

    private static func generateBackground(from note: FieldNote) -> SBARBackground {
        let mechanism = note.subjective?.mechanismOrExposure
        let allergies = note.subjective?.allergies
        let medications = note.subjective?.medications

        let workingDiagnoses: [String]?
        if let diagnoses = note.assessment?.workingDiagnoses, !diagnoses.isEmpty {
            workingDiagnoses = diagnoses.map { $0.label }
        } else {
            workingDiagnoses = nil
        }

        let keyRisks: [String]?
        if let risks = note.subjective?.keyRisks, !risks.isEmpty {
            keyRisks = risks
        } else {
            keyRisks = nil
        }

        return SBARBackground(
            mechanismOrExposure: mechanism,
            allergies: allergies,
            medications: medications,
            keyComorbidities: keyRisks,
            workingDiagnoses: workingDiagnoses
        )
    }

    private static func generateAssessment(from note: FieldNote) -> SBARAssessment {
        let latestVitals = note.objective?.vitals.last

        let examHighlights = collectExamHighlights(note.objective)

        let stability = note.assessment?.stability?.rawValue

        let redFlags: [String]?
        if let flags = note.assessment?.redFlags, !flags.isEmpty {
            redFlags = flags
        } else {
            redFlags = nil
        }

        return SBARAssessment(
            latestVitals: latestVitals,
            examHighlights: examHighlights,
            stability: stability,
            redFlags: redFlags
        )
    }

    private static func generateRecommendation(from note: FieldNote) -> SBARRecommendation {
        let disposition = note.plan?.disposition
        let destination = disposition?.destination
        let urgency = disposition?.urgency?.rawValue

        let interventionsPerformed: [String]?
        if !note.interventions.isEmpty {
            interventionsPerformed = note.interventions.map { intervention in
                return "\(intervention.type): \(intervention.details)"
            }
        } else if let actions = note.plan?.immediateActions, !actions.isEmpty {
            interventionsPerformed = actions
        } else {
            interventionsPerformed = nil
        }

        let medicationsGiven = note.plan?.medicationsGiven

        let transportNeeds: String?
        if disposition?.urgency == .immediate || disposition?.urgency == .urgent {
            transportNeeds = "Urgent transport required"
        } else if disposition?.type == .transfer || disposition?.type == .evacuate {
            transportNeeds = "Transport needed"
        } else {
            transportNeeds = nil
        }

        return SBARRecommendation(
            disposition: disposition?.type.rawValue,
            destination: destination,
            urgency: urgency,
            interventionsPerformed: interventionsPerformed,
            medicationsGiven: medicationsGiven,
            transportNeeds: transportNeeds
        )
    }

    // MARK: - Helper Functions

    private static func genderAndAge(_ patient: NotePatient) -> String {
        var parts: [String] = []

        if let age = patient.estimatedAgeYears {
            parts.append("\(age)yo")
        }

        if let sex = patient.sexAtBirth {
            parts.append(sex.rawValue)
        }

        return parts.isEmpty ? "unknown" : parts.joined(separator: " ")
    }

    private static func findWorstVital(_ vitals: [VitalSet]) -> String? {
        guard let latest = vitals.last else {
            return nil
        }

        var concerns: [String] = []

        // Check blood pressure
        if let bp = latest.bloodPressure {
            if bp.systolic < 90 || bp.systolic > 180 {
                concerns.append("BP \(bp.systolic)/\(bp.diastolic)")
            }
        }

        // Check heart rate
        if let hr = latest.heartRate, hr < 50 || hr > 120 {
            concerns.append("HR \(hr)")
        }

        // Check respiratory rate
        if let rr = latest.respiratoryRate, rr < 10 || rr > 30 {
            concerns.append("RR \(rr)")
        }

        // Check SpO2
        if let spo2 = latest.spo2, spo2 < 92 {
            concerns.append("SpO2 \(spo2)%")
        }

        // Check GCS
        if let gcs = latest.gcs, gcs < 15 {
            concerns.append("GCS \(gcs)")
        }

        return concerns.isEmpty ? nil : concerns.joined(separator: ", ")
    }

    private static func collectExamHighlights(_ objective: NoteObjective?) -> [String]? {
        guard let objective = objective else {
            return nil
        }

        var highlights: [String] = []

        // Add primary survey if present
        if let survey = objective.primarySurvey, !survey.isEmpty {
            highlights.append(survey)
        }

        // Add focused exam findings
        for (system, findings) in objective.focusedExam {
            if !findings.isEmpty {
                highlights.append("\(system.capitalized): \(findings.joined(separator: ", "))")
            }
        }

        // Add point-of-care test results
        if !objective.pointOfCareTests.isEmpty {
            highlights.append("POC: \(objective.pointOfCareTests.joined(separator: ", "))")
        }

        return highlights.isEmpty ? nil : highlights
    }

    private static func formatSBAR(_ sbar: SBAR) -> String {
        var output: [String] = []

        // SITUATION
        output.append("SITUATION")
        output.append("Patient: \(sbar.situation.patientSummary)")
        if let location = sbar.situation.location {
            output.append("Location: \(location)")
        }
        if let acuity = sbar.situation.acuity {
            output.append("Triage: \(acuity)")
        }
        if let cc = sbar.situation.chiefComplaint {
            output.append("Chief Complaint: \(cc)")
        }
        if let vital = sbar.situation.worstVital {
            output.append("Concerning Vitals: \(vital)")
        }
        output.append("")

        // BACKGROUND
        output.append("BACKGROUND")
        if let mechanism = sbar.background.mechanismOrExposure {
            output.append("Mechanism: \(mechanism)")
        }
        if let allergies = sbar.background.allergies {
            output.append("Allergies: \(allergies)")
        }
        if let meds = sbar.background.medications {
            output.append("Medications: \(meds)")
        }
        if let comorbidities = sbar.background.keyComorbidities, !comorbidities.isEmpty {
            output.append("Key Risks: \(comorbidities.joined(separator: ", "))")
        }
        if let diagnoses = sbar.background.workingDiagnoses, !diagnoses.isEmpty {
            output.append("Working Diagnoses: \(diagnoses.joined(separator: ", "))")
        }
        output.append("")

        // ASSESSMENT
        output.append("ASSESSMENT")
        if let vitals = sbar.assessment.latestVitals {
            output.append(formatVitals(vitals))
        }
        if let highlights = sbar.assessment.examHighlights, !highlights.isEmpty {
            output.append("Exam: \(highlights.joined(separator: "; "))")
        }
        if let stability = sbar.assessment.stability {
            output.append("Stability: \(stability.capitalized)")
        }
        if let redFlags = sbar.assessment.redFlags, !redFlags.isEmpty {
            output.append("Red Flags: \(redFlags.joined(separator: ", "))")
        }
        output.append("")

        // RECOMMENDATION
        output.append("RECOMMENDATION")
        if let disposition = sbar.recommendation.disposition {
            output.append("Disposition: \(disposition.capitalized)")
        }
        if let destination = sbar.recommendation.destination {
            output.append("Destination: \(destination)")
        }
        if let urgency = sbar.recommendation.urgency {
            output.append("Urgency: \(urgency.capitalized)")
        }
        if let interventions = sbar.recommendation.interventionsPerformed, !interventions.isEmpty {
            output.append("Interventions: \(interventions.joined(separator: ", "))")
        }
        if let meds = sbar.recommendation.medicationsGiven, !meds.isEmpty {
            output.append("Medications Given: \(meds.joined(separator: ", "))")
        }
        if let transport = sbar.recommendation.transportNeeds {
            output.append("Transport: \(transport)")
        }

        return output.joined(separator: "\n")
    }

    private static func formatVitals(_ vitals: VitalSet) -> String {
        var parts: [String] = []

        if let bp = vitals.bloodPressure {
            parts.append("BP \(bp.systolic)/\(bp.diastolic)")
        }
        if let hr = vitals.heartRate {
            parts.append("HR \(hr)")
        }
        if let rr = vitals.respiratoryRate {
            parts.append("RR \(rr)")
        }
        if let spo2 = vitals.spo2 {
            parts.append("SpO2 \(spo2)%")
        }
        if let temp = vitals.temperatureCelsius {
            parts.append("Temp \(temp)°C")
        }
        if let gcs = vitals.gcs {
            parts.append("GCS \(gcs)")
        }

        return parts.isEmpty ? "Vitals not recorded" : parts.joined(separator: ", ")
    }
}

// MARK: - SBAR Models

struct SBAR: Codable {
    let situation: SBARSituation
    let background: SBARBackground
    let assessment: SBARAssessment
    let recommendation: SBARRecommendation
}

struct SBARSituation: Codable {
    let patientSummary: String
    let location: String?
    let acuity: String?
    let chiefComplaint: String?
    let worstVital: String?
}

struct SBARBackground: Codable {
    let mechanismOrExposure: String?
    let allergies: String?
    let medications: String?
    let keyComorbidities: [String]?
    let workingDiagnoses: [String]?
}

struct SBARAssessment: Codable {
    let latestVitals: VitalSet?
    let examHighlights: [String]?
    let stability: String?
    let redFlags: [String]?
}

struct SBARRecommendation: Codable {
    let disposition: String?
    let destination: String?
    let urgency: String?
    let interventionsPerformed: [String]?
    let medicationsGiven: [String]?
    let transportNeeds: String?
}
