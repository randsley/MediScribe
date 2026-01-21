import Foundation

/// Subjective findings reported by the patient.
struct NoteSubjective: Codable {
    var chiefComplaint: String?
    var onset: String?
    var duration: String?
    var severity: String?
    var mechanismOrExposure: String?
    var associatedSymptoms: [String] = []
    var allergies: String? // "unknown" is a valid value
    var medications: String? // "unknown" is a valid value
    var keyRisks: [String] = []
}
