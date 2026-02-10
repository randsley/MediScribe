//
//  FHIRComposition.swift
//  MediScribe
//
//  FHIR R4 Composition resource — IPS document sections + EU profile.
//

import Foundation

struct FHIRComposition: Codable {
    let resourceType: String = "Composition"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: FHIRIdentifier?
    let status: String          // preliminary | final | amended | entered-in-error
    let type: FHIRCodeableConcept
    let category: [FHIRCodeableConcept]?
    let subject: FHIRReference?
    let encounter: FHIRReference?
    let date: String            // dateTime
    let author: [FHIRReference]
    let title: String
    let confidentiality: String?
    let attester: [FHIRCompositionAttester]?
    let custodian: FHIRReference?
    let relatesTo: [FHIRCompositionRelatesTo]?
    let event: [FHIRCompositionEvent]?
    let section: [FHIRCompositionSection]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, status, type, category,
             subject, encounter, date, author, title, confidentiality,
             attester, custodian, relatesTo, event, section
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         status: String,
         type: FHIRCodeableConcept,
         subject: FHIRReference? = nil,
         date: String,
         author: [FHIRReference],
         title: String,
         custodian: FHIRReference? = nil,
         section: [FHIRCompositionSection]? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = nil
        self.status = status
        self.type = type
        self.category = nil
        self.subject = subject
        self.encounter = nil
        self.date = date
        self.author = author
        self.title = title
        self.confidentiality = nil
        self.attester = nil
        self.custodian = custodian
        self.relatesTo = nil
        self.event = nil
        self.section = section
    }
}

// MARK: - Composition.Attester

struct FHIRCompositionAttester: Codable {
    let mode: String   // personal | professional | legal | official
    let time: String?
    let party: FHIRReference?
}

// MARK: - Composition.RelatesTo

struct FHIRCompositionRelatesTo: Codable {
    let code: String
    let targetIdentifier: FHIRIdentifier?
    let targetReference: FHIRReference?
}

// MARK: - Composition.Event

struct FHIRCompositionEvent: Codable {
    let code: [FHIRCodeableConcept]?
    let period: FHIRPeriod?
    let detail: [FHIRReference]?
}

// MARK: - Composition.Section

struct FHIRCompositionSection: Codable {
    let title: String?
    let code: FHIRCodeableConcept?
    let author: [FHIRReference]?
    let focus: FHIRReference?
    let text: FHIRNarrative?
    let mode: String?          // working | snapshot | changes
    let orderedBy: FHIRCodeableConcept?
    let entry: [FHIRReference]?
    let emptyReason: FHIRCodeableConcept?
    let section: [FHIRCompositionSection]?

    init(title: String? = nil,
         code: FHIRCodeableConcept? = nil,
         text: FHIRNarrative? = nil,
         entry: [FHIRReference]? = nil,
         emptyReason: FHIRCodeableConcept? = nil) {
        self.title = title
        self.code = code
        self.author = nil
        self.focus = nil
        self.text = text
        self.mode = nil
        self.orderedBy = nil
        self.entry = entry
        self.emptyReason = emptyReason
        self.section = nil
    }
}
