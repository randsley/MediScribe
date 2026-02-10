//
//  FHIRMedicationRequest.swift
//  MediScribe
//
//  FHIR R4 MedicationRequest resource — eRx domain.
//  SAFETY: Always exported with status:draft, intent:proposal.
//  MediScribe is documentation support, not a prescribing system.
//

import Foundation

struct FHIRMedicationRequest: Codable {
    let resourceType: String = "MedicationRequest"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let status: String          // draft | active | on-hold | cancelled | completed | entered-in-error | stopped | unknown
    let statusReason: FHIRCodeableConcept?
    let intent: String          // proposal | plan | order | original-order | reflex-order | filler-order | instance-order | option
    let category: [FHIRCodeableConcept]?
    let priority: String?       // routine | urgent | asap | stat
    let doNotPerform: Bool?
    let medicationCodeableConcept: FHIRCodeableConcept?
    let medicationReference: FHIRReference?
    let subject: FHIRReference
    let encounter: FHIRReference?
    let requester: FHIRReference?
    let performer: FHIRReference?
    let reasonCode: [FHIRCodeableConcept]?
    let note: [FHIRAnnotation]?
    let dosageInstruction: [FHIRDosage]?
    let authoredOn: String?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, status, statusReason,
             intent, category, priority, doNotPerform, medicationCodeableConcept,
             medicationReference, subject, encounter, requester, performer,
             reasonCode, note, dosageInstruction, authoredOn
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         status: String = "draft",
         intent: String = "proposal",
         medicationCodeableConcept: FHIRCodeableConcept? = nil,
         subject: FHIRReference,
         requester: FHIRReference? = nil,
         authoredOn: String? = nil,
         note: [FHIRAnnotation]? = nil,
         dosageInstruction: [FHIRDosage]? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = nil
        self.status = status
        self.statusReason = nil
        self.intent = intent
        self.category = nil
        self.priority = nil
        self.doNotPerform = nil
        self.medicationCodeableConcept = medicationCodeableConcept
        self.medicationReference = nil
        self.subject = subject
        self.encounter = nil
        self.requester = requester
        self.performer = nil
        self.reasonCode = nil
        self.note = note
        self.dosageInstruction = dosageInstruction
        self.authoredOn = authoredOn
    }
}
