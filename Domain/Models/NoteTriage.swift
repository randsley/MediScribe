import Foundation

/// Triage information for the field note.
struct NoteTriage: Codable {
    var system: TriageSystem
    var category: TriageCategory
}

enum TriageSystem: String, Codable {
    case start = "START"
    // Add other triage systems as needed
}

enum TriageCategory: String, Codable {
    case red
    case yellow
    case green
    case black
}
