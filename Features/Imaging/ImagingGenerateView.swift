import SwiftUI
import Foundation

struct ImagingGenerateView: View {
    @State private var status = "Select an image to generate a descriptive findings summary."
    @State private var findingsJSON = ""
    @State private var clinicianReviewed = false
    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        Form {
            Section("Safety") {
                Text("This tool summarizes visible image features to support documentation and communication. It does not assess clinical significance or provide a diagnosis.")
                    .font(.footnote)
            }

            Section("Actions") {
                Button("Generate findings summary") {
                    generatePlaceholderThenValidate()
                }
            }

            Section("Findings (for clinician review)") {
                TextEditor(text: $findingsJSON)
                    .frame(minHeight: 220)

                Toggle("Findings reviewed by clinician", isOn: $clinicianReviewed)
            }

            Section("Status") {
                Text(status).font(.footnote)
            }

            Section {
                Button("Add to patient record") { }
                    .disabled(!clinicianReviewed)

                Button("Include in referral summary") { }
                    .disabled(!clinicianReviewed)
            }
        }
        .navigationTitle("Findings Draft")
        .alert("Blocked output", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorText)
        }
    }

    private func generatePlaceholderThenValidate() {
        status = "Reviewing visible features in the image…"

        // TODO: Replace this placeholder with Core ML output (Data)
        let json = """
        {
          \"image_type\": \"Chest X-ray (view not specified)\",
          \"image_quality\": \"Image quality not specified.\",
          \"anatomical_observations\": {
            \"lungs\": [\"Lung fields appear symmetric.\"],
            \"pleural_regions\": [\"No clearly visible pleural fluid is observed.\"],
            \"cardiomediastinal_silhouette\": [\"Cardiomediastinal contours appear within expected visual limits.\"],
            \"bones_and_soft_tissues\": [\"No obvious displacement is visible in the ribs.\"]
          },
          \"comparison_with_prior\": \"No prior image available for comparison.\",
          \"areas_highlighted\": \"No highlighted areas provided.\",
          \"limitations\": \"\(FindingsValidator.limitationsConst)\"
        }
        """

        do {
            _ = try FindingsValidator.decodeAndValidate(Data(json.utf8))
            findingsJSON = json
            status = "Draft generated. Please review."
        } catch {
            findingsJSON = ""
            status = "Unable to generate a compliant findings summary."
            #if DEBUG
            errorText = "Blocked output (debug): \(error)"
            #else
            errorText = "Unable to generate a compliant findings summary. Please document manually."
            #endif
            showError = true
        }
    }
}

// MARK: - Findings safety gate (temporary colocated implementation)
// NOTE: Move these types into separate files under Domain/ when convenient.

struct ImagingFindingsSummary: Codable {
    let imageType: String
    let imageQuality: String
    let anatomicalObservations: AnatomicalObservations
    let comparisonWithPrior: String
    let areasHighlighted: String
    let limitations: String

    enum CodingKeys: String, CodingKey {
        case imageType = "image_type"
        case imageQuality = "image_quality"
        case anatomicalObservations = "anatomical_observations"
        case comparisonWithPrior = "comparison_with_prior"
        case areasHighlighted = "areas_highlighted"
        case limitations
    }
}

struct AnatomicalObservations: Codable {
    let lungs: [String]
    let pleuralRegions: [String]
    let cardiomediastinalSilhouette: [String]
    let bonesAndSoftTissues: [String]

    enum CodingKeys: String, CodingKey {
        case lungs
        case pleuralRegions = "pleural_regions"
        case cardiomediastinalSilhouette = "cardiomediastinal_silhouette"
        case bonesAndSoftTissues = "bones_and_soft_tissues"
    }
}

enum FindingsValidationError: Error {
    case invalidJSON
    case extraTopLevelKeys(found: Set<String>, allowed: Set<String>)
    case extraAnatomyKeys(found: Set<String>, allowed: Set<String>)
    case limitationsMismatch
    case forbiddenPhraseFound(String)
}

struct TextSanitizer {
    static func normalize(_ input: String) -> (spaced: String, collapsed: String) {
        var s = input.lowercased()
        s = s.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)

        let allowed = CharacterSet.alphanumerics
        s = s.unicodeScalars.map { allowed.contains($0) ? Character($0) : " " }
            .reduce(into: "") { $0.append($1) }

        s = s.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }).joined(separator: " ")
        let collapsed = s.replacingOccurrences(of: " ", with: "")
        return (spaced: s, collapsed: collapsed)
    }

    static func findForbidden(in input: String, forbidden: [String]) -> String? {
        let norm = normalize(input)
        for rawPhrase in forbidden {
            let p = normalize(rawPhrase)
            if norm.spaced.contains(p.spaced) { return rawPhrase }
            if !p.collapsed.isEmpty && norm.collapsed.contains(p.collapsed) { return rawPhrase }
        }
        return nil
    }
}

final class FindingsValidator {
    static let limitationsConst =
        "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."

    private static let allowedTopLevelKeys: Set<String> = [
        "image_type", "image_quality", "anatomical_observations",
        "comparison_with_prior", "areas_highlighted", "limitations"
    ]

    private static let allowedAnatomyKeys: Set<String> = [
        "lungs", "pleural_regions", "cardiomediastinal_silhouette", "bones_and_soft_tissues"
    ]

    private static let forbiddenPhrases: [String] = [
        "pneumonia", "tuberculosis", "tb", "covid", "covid-19", "infection",
        "malignancy", "cancer", "tumor", "fracture", "heart failure", "cardiomegaly",
        "edema", "emphysema", "fibrosis",
        "diagnosis", "diagnostic", "diagnostic of", "consistent with", "indicative of",
        "suggests", "confirms", "rules out", "compatible with", "cannot exclude",
        "likely", "unlikely", "probable", "possibly", "suspicious for",
        "high probability", "low probability", "risk of",
        "recommend", "recommendation", "treat", "treatment", "start", "stop", "manage",
        "urgent", "emergency", "referral indicated", "hospitalize", "follow up required",
        "may represent", "could represent", "appears to represent", "concerning for",
        "suggests the presence of",
        "ai detected", "system identified", "algorithm determined", "more accurate than",
        "better than clinician"
    ]

    static func decodeAndValidate(_ data: Data) throws -> ImagingFindingsSummary {
        guard let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FindingsValidationError.invalidJSON
        }

        let rawKeys = Set(raw.keys)
        if !rawKeys.isSubset(of: allowedTopLevelKeys) {
            throw FindingsValidationError.extraTopLevelKeys(found: rawKeys, allowed: allowedTopLevelKeys)
        }

        if let anatomy = raw["anatomical_observations"] as? [String: Any] {
            let anatomyKeys = Set(anatomy.keys)
            if !anatomyKeys.isSubset(of: allowedAnatomyKeys) {
                throw FindingsValidationError.extraAnatomyKeys(found: anatomyKeys, allowed: allowedAnatomyKeys)
            }
        }

        let decoded = try JSONDecoder().decode(ImagingFindingsSummary.self, from: data)

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
