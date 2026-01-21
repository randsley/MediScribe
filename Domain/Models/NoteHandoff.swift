import Foundation

/// Contains data structured for a handoff report, such as SBAR.
struct NoteHandoff: Codable {
    var sbar: SBAR?
}

struct SBAR: Codable {
    var situation: String
    var background: String
    var assessment: String
    var recommendation: String
}
