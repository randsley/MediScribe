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

    private static let allowedAnatomyKeys: Set<String> = [
        "lungs", "pleural_regions", "cardiomediastinal_silhouette", "bones_and_soft_tissues"
    ]

    /// Forbidden phrases covering diagnostic, probabilistic, and prescriptive language
    private static let forbiddenPhrases: [String] = [
        // Disease names
        "pneumonia", "tuberculosis", "tb", "covid", "covid-19", "infection",
        "malignancy", "cancer", "tumor", "fracture", "heart failure", "cardiomegaly",
        "edema", "emphysema", "fibrosis",

        // Diagnostic language
        "diagnosis", "diagnostic", "diagnostic of", "consistent with", "indicative of",
        "suggests", "confirms", "rules out", "compatible with", "cannot exclude",

        // Probabilistic terms
        "likely", "unlikely", "probable", "possibly", "suspicious for",
        "high probability", "low probability", "risk of",

        // Prescriptive/management terms
        "recommend", "recommendation", "treat", "treatment", "start", "stop", "manage",
        "urgent", "emergency", "referral indicated", "hospitalize", "follow up required",

        // Interpretive language
        "may represent", "could represent", "appears to represent", "concerning for",
        "suggests the presence of",

        // AI overconfidence
        "ai detected", "system identified", "algorithm determined", "more accurate than",
        "better than clinician"
    ]

    /// Validates imaging findings JSON against all safety rules
    /// Throws FindingsValidationError if any rule is violated
    static func decodeAndValidate(_ data: Data) throws -> ImagingFindingsSummary {
        // Check JSON structure
        guard let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FindingsValidationError.invalidJSON
        }

        // Validate top-level keys
        let rawKeys = Set(raw.keys)
        if !rawKeys.isSubset(of: allowedTopLevelKeys) {
            throw FindingsValidationError.extraTopLevelKeys(found: rawKeys, allowed: allowedTopLevelKeys)
        }

        // Validate anatomy keys
        if let anatomy = raw["anatomical_observations"] as? [String: Any] {
            let anatomyKeys = Set(anatomy.keys)
            if !anatomyKeys.isSubset(of: allowedAnatomyKeys) {
                throw FindingsValidationError.extraAnatomyKeys(found: anatomyKeys, allowed: allowedAnatomyKeys)
            }
        }

        // Decode to typed model
        let decoded = try JSONDecoder().decode(ImagingFindingsSummary.self, from: data)

        // Validate limitations statement (exact match required)
        if decoded.limitations != limitationsConst {
            throw FindingsValidationError.limitationsMismatch
        }

        // IMPORTANT: The limitations sentence contains the word "diagnosis" by design.
        // We validate it by exact match above, but we must exclude it from forbidden phrase scanning.
        let textForScan = flattenStringsExcludingLimitations(decoded)
        if let bad = TextSanitizer.findForbidden(in: textForScan, forbidden: forbiddenPhrases) {
            throw FindingsValidationError.forbiddenPhraseFound(bad)
        }

        return decoded
    }

    /// Flattens all text fields except limitations into a single string for scanning
    private static func flattenStringsExcludingLimitations(_ s: ImagingFindingsSummary) -> String {
        var parts: [String] = []
        parts.append(s.imageType)
        parts.append(s.imageQuality)
        parts.append(contentsOf: s.anatomicalObservations.lungs)
        parts.append(contentsOf: s.anatomicalObservations.pleuralRegions)
        parts.append(contentsOf: s.anatomicalObservations.cardiomediastinalSilhouette)
        parts.append(contentsOf: s.anatomicalObservations.bonesAndSoftTissues)
        parts.append(s.comparisonWithPrior)
        parts.append(s.areasHighlighted)
        // NOTE: intentionally exclude s.limitations
        return parts.joined(separator: "\n")
    }
}
