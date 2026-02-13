//
//  SOAPNoteData.swift
//  MediScribe
//
//  Comprehensive SOAP note data models for Core Data persistence
//

import Foundation

// MARK: - Complete SOAP Note Model

/// Complete SOAP note with metadata and validation
struct SOAPNoteData: Codable, Identifiable {
    let id: UUID
    let patientIdentifier: String? // De-identified patient reference
    let generatedAt: Date
    let completedAt: Date?

    // SOAP Sections
    let subjective: SOAPSubjective
    let objective: SOAPObjective
    let assessment: SOAPAssessment
    let plan: SOAPPlan

    // Metadata
    let metadata: SOAPMetadata
    let validationStatus: ValidationStatus

    enum CodingKeys: String, CodingKey {
        case id
        case patientIdentifier = "patient_identifier"
        case generatedAt = "generated_at"
        case completedAt = "completed_at"
        case subjective
        case objective
        case assessment
        case plan
        case metadata
        case validationStatus = "validation_status"
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        patientIdentifier: String?,
        generatedAt: Date = Date(),
        completedAt: Date? = nil,
        subjective: SOAPSubjective,
        objective: SOAPObjective,
        assessment: SOAPAssessment,
        plan: SOAPPlan,
        metadata: SOAPMetadata,
        validationStatus: ValidationStatus = .unvalidated
    ) {
        self.id = id
        self.patientIdentifier = patientIdentifier
        self.generatedAt = generatedAt
        self.completedAt = completedAt
        self.subjective = subjective
        self.objective = objective
        self.assessment = assessment
        self.plan = plan
        self.metadata = metadata
        self.validationStatus = validationStatus
    }

    // MARK: - Computed Properties

    /// Whether note has been reviewed by clinician
    var isReviewed: Bool {
        validationStatus == .validated
    }

    /// Whether note can be saved/shared
    var isReadyForUse: Bool {
        isReviewed && !hasCriticalIssues
    }

    /// Whether note has any critical validation issues
    var hasCriticalIssues: Bool {
        validationStatus == .blocked
    }

    /// Complete note as formatted text
    var formattedText: String {
        """
        SUBJECTIVE:
        \(subjective.chiefComplaint)

        History of Present Illness:
        \(subjective.historyOfPresentIllness ?? "Not documented")

        Past Medical History:
        \(subjective.pastMedicalHistory?.joined(separator: "\n") ?? "Not documented")

        Current Medications:
        \(subjective.medications?.joined(separator: "\n") ?? "Not documented")

        Allergies:
        \(subjective.allergies?.joined(separator: "\n") ?? "NKDA")

        ─────────────────────────────────────────────

        OBJECTIVE:
        Vital Signs:
        \(objective.vitalSigns?.formatted ?? "Not recorded")

        Physical Exam:
        \(objective.physicalExamFindings?.joined(separator: "\n") ?? "Not documented")

        Diagnostic Results:
        \(objective.diagnosticResults?.joined(separator: "\n") ?? "Not documented")

        ─────────────────────────────────────────────

        ASSESSMENT:
        Clinical Impression:
        \(assessment.clinicalImpression)

        Differential Considerations:
        \(assessment.differentialConsiderations?.joined(separator: "\n") ?? "Not documented")

        Problem List:
        \(assessment.problemList?.joined(separator: "\n") ?? "Not documented")

        ─────────────────────────────────────────────

        PLAN:
        Interventions:
        \(plan.interventions?.joined(separator: "\n") ?? "Not documented")

        Follow-up:
        \(plan.followUp?.joined(separator: "\n") ?? "Not documented")

        Patient Education:
        \(plan.patientEducation?.joined(separator: "\n") ?? "Not documented")

        Referrals:
        \(plan.referrals?.joined(separator: "\n") ?? "Not applicable")

        ─────────────────────────────────────────────
        GENERATED: \(ISO8601DateFormatter().string(from: generatedAt))
        STATUS: \(validationStatus.rawValue.uppercased())
        LIMITATIONS: This note was generated with AI assistance. Clinician review is mandatory before use.
        """
    }
}

// MARK: - SOAP Section Models

/// Subjective section
struct SOAPSubjective: Codable {
    let chiefComplaint: String
    let historyOfPresentIllness: String?
    let pastMedicalHistory: [String]?
    let medications: [String]?
    let allergies: [String]?

    enum CodingKeys: String, CodingKey {
        case chiefComplaint = "chief_complaint"
        case historyOfPresentIllness = "history_of_present_illness"
        case pastMedicalHistory = "past_medical_history"
        case medications
        case allergies
    }
}

/// Objective section
struct SOAPObjective: Codable {
    let vitalSigns: VitalSignsData?
    let physicalExamFindings: [String]?
    let diagnosticResults: [String]?

    enum CodingKeys: String, CodingKey {
        case vitalSigns = "vital_signs"
        case physicalExamFindings = "physical_exam_findings"
        case diagnosticResults = "diagnostic_results"
    }
}

/// Assessment section
struct SOAPAssessment: Codable {
    let clinicalImpression: String
    let differentialConsiderations: [String]?
    let problemList: [String]?

    enum CodingKeys: String, CodingKey {
        case clinicalImpression = "clinical_impression"
        case differentialConsiderations = "differential_considerations"
        case problemList = "problem_list"
    }
}

/// Plan section
struct SOAPPlan: Codable {
    let interventions: [String]?
    let followUp: [String]?
    let patientEducation: [String]?
    let referrals: [String]?

    enum CodingKeys: String, CodingKey {
        case interventions
        case followUp = "follow_up"
        case patientEducation = "patient_education"
        case referrals
    }
}

// MARK: - Supporting Models

/// Vital signs data
struct VitalSignsData: Codable {
    // Plain Double so the model's numeric output decodes directly.
    // (Measurement<UnitTemperature/UnitFrequency> requires a nested object
    // {"value":…,"unit":{…}} that no LLM produces.)
    let temperature: Double?       // °C
    let heartRate: Double?         // bpm
    let respiratoryRate: Double?   // breaths/min
    let systolicBP: Int?
    let diastolicBP: Int?
    let oxygenSaturation: Int?     // percentage
    let recordedAt: Date?

    enum CodingKeys: String, CodingKey {
        case temperature
        case heartRate = "heart_rate"
        case respiratoryRate = "respiratory_rate"
        case systolicBP = "systolic_bp"
        case diastolicBP = "diastolic_bp"
        case oxygenSaturation = "oxygen_saturation"
        case recordedAt = "recorded_at"
    }

    /// Formatted vital signs string
    var formatted: String {
        var parts: [String] = []
        if let temp = temperature { parts.append("Temperature: \(String(format: "%.1f", temp))°C") }
        if let hr   = heartRate   { parts.append("Heart Rate: \(Int(hr)) bpm") }
        if let rr   = respiratoryRate { parts.append("Respiratory Rate: \(Int(rr)) breaths/min") }
        if let sys  = systolicBP, let dia = diastolicBP { parts.append("BP: \(sys)/\(dia) mmHg") }
        if let o2   = oxygenSaturation { parts.append("O₂ Saturation: \(o2)% (RA)") }
        return parts.isEmpty ? "Not recorded" : parts.joined(separator: "\n")
    }
}

/// SOAP note metadata
struct SOAPMetadata: Codable {
    let modelVersion: String
    let generationTime: TimeInterval
    let promptTemplate: String
    let clinicianReviewedBy: String?
    let reviewedAt: Date?
    let encryptionVersion: String

    enum CodingKeys: String, CodingKey {
        case modelVersion = "model_version"
        case generationTime = "generation_time"
        case promptTemplate = "prompt_template"
        case clinicianReviewedBy = "clinician_reviewed_by"
        case reviewedAt = "reviewed_at"
        case encryptionVersion = "encryption_version"
    }
}

// MARK: - Validation Status

/// Validation status of a SOAP note
enum ValidationStatus: String, Codable {
    /// Note is unvalidated (fresh from AI)
    case unvalidated = "unvalidated"

    /// Note passed validation and is ready for review
    case validated = "validated"

    /// Note failed validation and is blocked
    case blocked = "blocked"

    /// Note has been reviewed by clinician
    case reviewed = "reviewed"

    /// Note has been signed/finalized
    case signed = "signed"

    // MARK: - Properties

    var displayName: String {
        switch self {
        case .unvalidated:
            return "Draft - Awaiting Review"
        case .validated:
            return "Ready for Review"
        case .blocked:
            return "Validation Failed"
        case .reviewed:
            return "Clinician Reviewed"
        case .signed:
            return "Finalized"
        }
    }

    var isEditable: Bool {
        self == .unvalidated || self == .validated
    }
}

// MARK: - SOAP Validation Error

struct SOAPValidationError: LocalizedError, Identifiable {
    let id = UUID()
    let field: String
    let message: String
    let severity: Severity

    enum Severity: String {
        case warning
        case error
        case critical
    }

    var errorDescription: String? {
        "\(field): \(message)"
    }
}
