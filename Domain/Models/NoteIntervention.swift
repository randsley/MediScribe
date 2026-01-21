import Foundation

/// Represents a specific action or intervention performed by a clinician.
struct NoteIntervention: Codable, Identifiable {
    var id: UUID = UUID()
    var type: String // e.g., "oxygen", "iv_access", "medication_administered"
    var details: String
    var performedAt: Date = Date()
}
