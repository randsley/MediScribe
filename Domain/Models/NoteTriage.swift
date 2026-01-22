import Foundation

/// Triage information for the field note.
struct NoteTriage: Codable {
    var system: TriageSystem
    var category: TriageCategory
}

enum TriageSystem: String, Codable, CaseIterable {
    case start = "START"
    // Add other triage systems as needed
}

enum TriageCategory: String, Codable, CaseIterable {
    case red
    case yellow
    case green
    case black
}
