import Foundation

/// Metadata associated with a field note.
struct NoteMeta: Codable {
    var noteId: UUID = UUID()
    var status: NoteStatus = .draft
    var createdAt: Date = Date()
    var author: NoteAuthor
    var patient: NotePatient
    var encounter: NoteEncounter
    var consent: NoteConsent

    enum CodingKeys: String, CodingKey {
        case status, createdAt, author, patient, encounter, consent
    }
}

enum NoteStatus: String, Codable {
    case draft
    case signed
    case amended
}

struct NoteAuthor: Codable {
    var id: String
    var displayName: String
    var role: String
}

struct NotePatient: Codable {
    var id: String // Can be temporary
    var estimatedAgeYears: Int?
    var sexAtBirth: SexAtBirth?
}

enum SexAtBirth: String, Codable, CaseIterable {
    case male
    case female
    case unknown
}

struct NoteEncounter: Codable {
    var setting: EncounterSetting
    var locationText: String?
    // Optional GPS coordinates can be added here if needed
}

enum EncounterSetting: String, Codable, CaseIterable {
    case roadside
    case tent
    case home
    case ambulance
}

struct NoteConsent: Codable {
    var status: ConsentStatus
}

enum ConsentStatus: String, Codable {
    case obtained
    case impliedEmergency = "implied_emergency"
    case notPossible = "not_possible"
}
