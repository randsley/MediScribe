//
//  SOAPNoteParser.swift
//  MediScribe
//
//  Enhanced SOAP note parser with validation
//

import Foundation

/// Parses and validates SOAP note output from model
class SOAPNoteParser {
    // MARK: - Properties

    private let promptBlockedPhrases = [
        "diagnose", "diagnosis", "diagnostic",
        "recommend", "should treat", "requires treatment",
        "likely", "probable", "probably", "suspicious for",
        "concerning", "critical", "urgent", "emergent",
        "rule out", "cannot exclude",
        "consistent with", "compatible with", "indicative of"
    ]

    // MARK: - Parsing Methods

    /// Parse raw model output into structured SOAP note
    /// - Parameters:
    ///   - output: Raw text output from model
    ///   - modelVersion: Version of model used
    ///   - generationTime: Time taken to generate
    /// - Returns: Parsed and validated SOAP note data
    func parseSOAPNote(
        from output: String,
        modelVersion: String,
        generationTime: TimeInterval
    ) throws -> SOAPNoteData {
        // 1. Extract JSON
        let jsonString = try extractJSON(from: output)

        // 2. Decode JSON into sections
        let sections = try decodeSOAPSections(from: jsonString)

        // 3. Validate content
        let validationErrors = validateSOAPContent(sections)

        // 4. Create SOAP note data
        let metadata = SOAPMetadata(
            modelVersion: modelVersion,
            generationTime: generationTime,
            promptTemplate: "soap_generation_1.0",
            clinicianReviewedBy: nil,
            reviewedAt: nil,
            encryptionVersion: "1.0"
        )

        let validationStatus: ValidationStatus = validationErrors.isEmpty ? .validated : .blocked

        return SOAPNoteData(
            patientIdentifier: nil,
            generatedAt: Date(),
            completedAt: nil,
            subjective: sections.subjective,
            objective: sections.objective,
            assessment: sections.assessment,
            plan: sections.plan,
            metadata: metadata,
            validationStatus: validationStatus
        )
    }

    /// Validate SOAP note content
    /// - Returns: Array of validation errors (empty if valid)
    func validateSOAPContent(_ sections: SOAPSections) -> [SOAPValidationError] {
        var errors: [SOAPValidationError] = []

        // Validate Subjective
        if sections.subjective.chiefComplaint.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(
                SOAPValidationError(
                    field: "Chief Complaint",
                    message: "Cannot be empty",
                    severity: .error
                )
            )
        }

        if (sections.subjective.historyOfPresentIllness ?? "").trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(
                SOAPValidationError(
                    field: "History of Present Illness",
                    message: "Cannot be empty",
                    severity: .error
                )
            )
        }

        // Validate Objective - Vital Signs
        if sections.objective.vitalSigns?.temperature == nil
            && sections.objective.vitalSigns?.heartRate == nil {
            errors.append(
                SOAPValidationError(
                    field: "Vital Signs",
                    message: "At least one vital sign should be documented",
                    severity: .warning
                )
            )
        }

        // Validate Assessment
        if sections.assessment.clinicalImpression.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(
                SOAPValidationError(
                    field: "Clinical Impression",
                    message: "Cannot be empty",
                    severity: .error
                )
            )
        }

        // Check for blocked phrases in all sections
        let blockedPhraseErrors = checkForBlockedPhrases(
            subjective: sections.subjective,
            objective: sections.objective,
            assessment: sections.assessment,
            plan: sections.plan
        )
        errors.append(contentsOf: blockedPhraseErrors)

        return errors
    }

    // MARK: - Private Methods

    private func extractJSON(from output: String) throws -> String {
        // Find first { and last }
        guard let startIndex = output.firstIndex(of: "{"),
              let endIndex = output.lastIndex(of: "}") else {
            throw SOAPParserError.noJSON
        }

        let jsonString = String(output[startIndex ... endIndex])

        // Validate JSON structure
        guard let jsonData = jsonString.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: jsonData) else {
            throw SOAPParserError.invalidJSON
        }

        return jsonString
    }

    private func decodeSOAPSections(from jsonString: String) throws -> SOAPSections {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw SOAPParserError.invalidJSON
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(SOAPSections.self, from: jsonData)
        } catch {
            throw SOAPParserError.decodingFailed(error)
        }
    }

    private func checkForBlockedPhrases(
        subjective: SOAPSubjective,
        objective: SOAPObjective,
        assessment: SOAPAssessment,
        plan: SOAPPlan
    ) -> [SOAPValidationError] {
        var errors: [SOAPValidationError] = []

        // Check subjective
        if let phrase = findBlockedPhrase(in: subjective.chiefComplaint) {
            errors.append(
                SOAPValidationError(
                    field: "Chief Complaint",
                    message: "Contains prohibited language: '\(phrase)'",
                    severity: .critical
                )
            )
        }

        if let hpi = subjective.historyOfPresentIllness, let phrase = findBlockedPhrase(in: hpi) {
            errors.append(
                SOAPValidationError(
                    field: "HPI",
                    message: "Contains prohibited language: '\(phrase)'",
                    severity: .critical
                )
            )
        }

        // Check assessment
        if let phrase = findBlockedPhrase(in: assessment.clinicalImpression) {
            errors.append(
                SOAPValidationError(
                    field: "Assessment",
                    message: "Contains prohibited language: '\(phrase)'",
                    severity: .critical
                )
            )
        }

        // Check plan items
        if let items = plan.interventions {
            for item in items {
                if let phrase = findBlockedPhrase(in: item) {
                    errors.append(
                        SOAPValidationError(
                            field: "Plan - Interventions",
                            message: "Contains prohibited language: '\(phrase)'",
                            severity: .critical
                        )
                    )
                    break
                }
            }
        }

        return errors
    }

    private func findBlockedPhrase(in text: String) -> String? {
        let lowerText = text.lowercased()

        for phrase in promptBlockedPhrases {
            if lowerText.contains(phrase) {
                return phrase
            }
        }

        return nil
    }
}

// MARK: - Supporting Models

/// Decodable SOAP sections (intermediate format)
struct SOAPSections: Codable {
    let subjective: SOAPSubjective
    let objective: SOAPObjective
    let assessment: SOAPAssessment
    let plan: SOAPPlan
}

// MARK: - Parser Error

enum SOAPParserError: LocalizedError {
    case noJSON
    case invalidJSON
    case decodingFailed(Error)
    case validationFailed([SOAPValidationError])

    var errorDescription: String? {
        switch self {
        case .noJSON:
            return "No JSON found in model output"
        case .invalidJSON:
            return "Invalid JSON format in model output"
        case .decodingFailed(let error):
            return "Failed to decode SOAP sections: \(error.localizedDescription)"
        case .validationFailed(let errors):
            let errorMessages = errors
                .map { "\($0.field): \($0.message)" }
                .joined(separator: "; ")
            return "Validation failed: \(errorMessages)"
        }
    }
}
