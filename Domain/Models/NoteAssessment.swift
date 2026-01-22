import Foundation

/// The clinician's assessment based on subjective and objective findings.
struct NoteAssessment: Codable {
    var workingDiagnoses: [Diagnosis] = []
    var differentials: [String] = []
    var redFlags: [String] = []
    var stability: Stability?
}

struct Diagnosis: Codable {
    var label: String
    var certainty: Certainty
}

enum Certainty: String, Codable {
    case possible
    case probable
    case confirmed
}

enum Stability: String, Codable, CaseIterable {
    case stable
    case unstable
}
