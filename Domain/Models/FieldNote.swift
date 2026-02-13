import Foundation

/// Represents the top-level structure for a field medical note, based on the Unified Field Note Schema.
struct FieldNote: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var meta: NoteMeta
    var triage: NoteTriage?
    var problemList: [NoteProblem] = []
    var subjective: NoteSubjective?
    var objective: NoteObjective?
    var assessment: NoteAssessment?
    var plan: NotePlan?
    var interventions: [NoteIntervention] = []
    var handoff: NoteHandoff?

    enum CodingKeys: String, CodingKey {
        case meta, triage, problemList, subjective, objective, assessment, plan, interventions, handoff
    }
}
