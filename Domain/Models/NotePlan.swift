import Foundation

/// The clinician's plan for the patient.
struct NotePlan: Codable {
    var immediateActions: [String] = []
    var medicationsGiven: [String] = [] // Consider a more structured model later
    var disposition: Disposition?
    var safetyNetInstructions: String?
}

struct Disposition: Codable {
    var type: DispositionType
    var destination: String?
    var urgency: Urgency?
}

enum DispositionType: String, Codable, CaseIterable {
    case observe
    case refer
    case transfer
    case evacuate
    case discharge
}

enum Urgency: String, Codable, CaseIterable {
    case immediate
    case urgent
    case routine
}
