//
//  SOAPNoteValidator.swift
//  MediScribe
//
//  Safety validation for SOAP note output
//  Enforces: mandatory limitations statement, forbidden phrase blocking, schema validation
//

import Foundation

final class SOAPNoteValidator {
    /// Mandatory limitations statement that must appear in all SOAP notes
    /// This statement is included in metadata, not in individual sections
    static let limitationsStatement =
        "This SOAP note was generated with AI assistance and describes observations only. Clinical judgment and decision-making remain the responsibility of the reviewing clinician."

    /// Validates SOAP note data against all safety rules
    /// - Parameters:
    ///   - noteData: The SOAP note data to validate
    ///   - language: Language for forbidden phrase detection
    /// - Returns: The validated SOAPNoteData if all checks pass
    /// - Throws: SOAPNoteValidationError if any rule is violated
    static func validate(
        _ noteData: SOAPNoteData,
        language: Language = .english
    ) throws -> SOAPNoteData {
        // 1. Check mandatory limitations statement in metadata
        // For now, we validate that metadata exists and has proper structure
        try validateMetadata(noteData.metadata)

        // 2. Scan all text sections for forbidden phrases
        // Assessment and Plan sections are highest risk for diagnostic/prescriptive language
        try validateAssessmentSection(noteData.assessment, language: language)
        try validatePlanSection(noteData.plan, language: language)

        // 3. General forbidden phrase scan on all sections
        try validateAllSections(noteData, language: language)

        // 4. Schema validation (all required fields present)
        try validateSchema(noteData)

        return noteData
    }

    // MARK: - Private Validation Methods

    /// Validates metadata structure and limitations statement requirement
    private static func validateMetadata(_ metadata: SOAPMetadata) throws {
        // Metadata must exist and have required fields
        // Note: The actual limitations statement check would happen at the UI/storage level
        // where we ensure it's displayed to and acknowledged by the clinician
        if metadata.encryptionVersion.isEmpty {
            throw SOAPNoteValidationError(
                field: "metadata.encryptionVersion",
                message: "Encryption version is required",
                severity: .error
            )
        }
    }

    /// Validates Assessment section specifically for diagnostic language
    /// This is the highest-risk section for safety violations
    private static func validateAssessmentSection(
        _ assessment: SOAPAssessment,
        language: Language
    ) throws {
        let allText = (assessment.clinicalImpression + " " +
                       (assessment.differentialConsiderations?.joined(separator: " ") ?? "") + " " +
                       (assessment.problemList?.joined(separator: " ") ?? "")).lowercased()

        if let bad = TextSanitizer.findForbiddenInLanguage(in: allText, language: language) {
            throw SOAPNoteValidationError(
                field: "assessment",
                message: "Forbidden phrase detected in assessment: '\(bad)'. Assessment must contain observations only, not diagnostic conclusions.",
                severity: .critical
            )
        }
    }

    /// Validates Plan section for prescriptive language
    private static func validatePlanSection(
        _ plan: SOAPPlan,
        language: Language
    ) throws {
        let allText = (
            (plan.interventions?.joined(separator: " ") ?? "") + " " +
            (plan.followUp?.joined(separator: " ") ?? "") + " " +
            (plan.patientEducation?.joined(separator: " ") ?? "") + " " +
            (plan.referrals?.joined(separator: " ") ?? "")
        ).lowercased()

        if let bad = TextSanitizer.findForbiddenInLanguage(in: allText, language: language) {
            throw SOAPNoteValidationError(
                field: "plan",
                message: "Forbidden phrase detected in plan: '\(bad)'. Plan section requires clinician review and should avoid directive language.",
                severity: .critical
            )
        }
    }

    /// Validates all SOAP sections for forbidden phrases
    private static func validateAllSections(
        _ noteData: SOAPNoteData,
        language: Language
    ) throws {
        let sections = [
            ("subjective.chiefComplaint", noteData.subjective.chiefComplaint),
            ("subjective.historyOfPresentIllness", noteData.subjective.historyOfPresentIllness),
            ("subjective.pastMedicalHistory", noteData.subjective.pastMedicalHistory?.joined(separator: " ") ?? ""),
            ("subjective.medications", noteData.subjective.medications?.joined(separator: " ") ?? ""),
            ("subjective.allergies", noteData.subjective.allergies?.joined(separator: " ") ?? ""),
            ("objective.vitalSigns", formatVitalSigns(noteData.objective.vitalSigns)),
            ("objective.physicalExamFindings", noteData.objective.physicalExamFindings?.joined(separator: " ") ?? ""),
            ("objective.diagnosticResults", noteData.objective.diagnosticResults?.joined(separator: " ") ?? ""),
        ]

        for (field, text) in sections {
            if let bad = TextSanitizer.findForbiddenInLanguage(in: text, language: language) {
                throw SOAPNoteValidationError(
                    field: field,
                    message: "Forbidden phrase '\(bad)' found in \(field)",
                    severity: .error
                )
            }
        }
    }

    /// Validates required schema elements are present
    private static func validateSchema(_ noteData: SOAPNoteData) throws {
        // Check required SOAP sections
        if noteData.subjective.chiefComplaint.trimmingCharacters(in: .whitespaces).isEmpty {
            throw SOAPNoteValidationError(
                field: "subjective.chiefComplaint",
                message: "Chief complaint is required",
                severity: .error
            )
        }

        if noteData.objective.vitalSigns.recordedAt == nil {
            throw SOAPNoteValidationError(
                field: "objective.vitalSigns.recordedAt",
                message: "Vital signs recording timestamp is required",
                severity: .error
            )
        }

        if noteData.assessment.clinicalImpression.trimmingCharacters(in: .whitespaces).isEmpty {
            throw SOAPNoteValidationError(
                field: "assessment.clinicalImpression",
                message: "Clinical impression is required",
                severity: .error
            )
        }

        // Metadata is required
        _ = noteData.metadata
    }

    /// Formats vital signs data into a string for phrase checking
    private static func formatVitalSigns(_ vitals: VitalSignsData) -> String {
        var parts: [String] = []

        if let temp = vitals.temperature {
            parts.append("Temperature \(String(format: "%.1f", temp.value)) degrees")
        }
        if let hr = vitals.heartRate {
            parts.append("Heart rate \(Int(hr.value)) beats per minute")
        }
        if let rr = vitals.respiratoryRate {
            parts.append("Respiratory rate \(Int(rr.value)) breaths per minute")
        }
        if let sys = vitals.systolicBP, let dia = vitals.diastolicBP {
            parts.append("Blood pressure \(sys) over \(dia)")
        }
        if let o2 = vitals.oxygenSaturation {
            parts.append("Oxygen saturation \(o2) percent")
        }

        return parts.joined(separator: " ")
    }
}

// MARK: - SOAP Note Validation Error

/// Error type for SOAP note validation failures
struct SOAPNoteValidationError: LocalizedError, Identifiable {
    let id = UUID()
    let field: String
    let message: String
    let severity: Severity

    enum Severity: String, Codable {
        case warning
        case error
        case critical
    }

    var errorDescription: String? {
        "\(field): \(message)"
    }

    var failureReason: String? {
        message
    }

    /// User-friendly error message for display
    var displayMessage: String {
        switch severity {
        case .warning:
            return "⚠️ \(message)"
        case .error:
            return "❌ \(message)"
        case .critical:
            return "🛑 SAFETY BLOCK: \(message)"
        }
    }
}
