import Foundation

/// Represents a single clinical problem in the problem list.
struct NoteProblem: Codable, Identifiable {
    var id: String // problemId, e.g., "p1"
    var label: String
    var status: ProblemStatus
}

enum ProblemStatus: String, Codable {
    case active
    case resolved
}
