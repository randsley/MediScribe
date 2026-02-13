//
//  FindingsValidator.swift
//  MediScribe
//
//  Safety validation for imaging findings output
//  Enforces: fixed schema, mandatory limitations statement, forbidden phrase blocking
//

import Foundation

final class FindingsValidator {
    /// Mandatory limitations statement that must appear verbatim in all findings
    static let limitationsConst =
        "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."

    private static let allowedTopLevelKeys: Set<String> = [
        "image_type", "image_quality", "anatomical_observations",
        "comparison_with_prior", "areas_highlighted", "limitations"
    ]

    /// Validates imaging findings JSON against all safety rules
    /// Throws FindingsValidationError if any rule is violated
    static func decodeAndValidate(_ data: Data, language: Language = .english) throws -> ImagingFindingsSummary {
        // Check JSON structure
        guard let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FindingsValidationError.invalidJSON
        }

        // Validate top-level keys — no extra keys allowed
        let rawKeys = Set(raw.keys)
        if !rawKeys.isSubset(of: allowedTopLevelKeys) {
            throw FindingsValidationError.extraTopLevelKeys(found: rawKeys, allowed: allowedTopLevelKeys)
        }

        // Anatomy keys are intentionally NOT validated against a fixed list.
        // The model uses keys appropriate to the actual image modality
        // (e.g. chest X-ray vs ultrasound vs echocardiogram).

        // Decode to typed model
        let decoded = try JSONDecoder().decode(ImagingFindingsSummary.self, from: data)

        // Validate limitations statement (exact match required)
        if decoded.limitations != limitationsConst {
            throw FindingsValidationError.limitationsMismatch
        }

        // IMPORTANT: The limitations sentence contains the word "diagnosis" by design.
        // We validate it by exact match above, but we must exclude it from forbidden phrase scanning.
        let textForScan = flattenStringsExcludingLimitations(decoded)
        if let bad = TextSanitizer.findForbiddenInLanguage(in: textForScan, language: language) {
            throw FindingsValidationError.forbiddenPhraseFound(bad)
        }

        return decoded
    }

    /// Flattens all text fields except limitations into a single string for scanning
    private static func flattenStringsExcludingLimitations(_ s: ImagingFindingsSummary) -> String {
        var parts: [String] = []
        parts.append(s.imageType)
        parts.append(s.imageQuality)
        // Scan all observation values regardless of which keys the model used
        parts.append(contentsOf: s.anatomicalObservations.structures.values.flatMap { $0 })
        parts.append(s.comparisonWithPrior)
        parts.append(s.areasHighlighted)
        // NOTE: intentionally exclude s.limitations
        return parts.joined(separator: "\n")
    }
}
