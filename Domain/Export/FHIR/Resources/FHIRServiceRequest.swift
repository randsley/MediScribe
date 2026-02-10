//
//  FHIRServiceRequest.swift
//  MediScribe
//
//  FHIR R4 ServiceRequest resource — referrals.
//

import Foundation

struct FHIRServiceRequest: Codable {
    let resourceType: String = "ServiceRequest"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let instantiatesUri: [String]?
    let basedOn: [FHIRReference]?
    let replaces: [FHIRReference]?
    let requisition: FHIRIdentifier?
    let status: String              // draft | active | on-hold | revoked | completed | entered-in-error | unknown
    let intent: String              // proposal | plan | directive | order | original-order | reflex-order | filler-order | instance-order | option
    let category: [FHIRCodeableConcept]?
    let priority: String?           // routine | urgent | asap | stat
    let doNotPerform: Bool?
    let code: FHIRCodeableConcept?
    let orderDetail: [FHIRCodeableConcept]?
    let subject: FHIRReference
    let encounter: FHIRReference?
    let occurrenceDateTime: String?
    let occurrencePeriod: FHIRPeriod?
    let authoredOn: String?
    let requester: FHIRReference?
    let performerType: FHIRCodeableConcept?
    let performer: [FHIRReference]?
    let locationCode: [FHIRCodeableConcept]?
    let locationReference: [FHIRReference]?
    let reasonCode: [FHIRCodeableConcept]?
    let reasonReference: [FHIRReference]?
    let insurance: [FHIRReference]?
    let supportingInfo: [FHIRReference]?
    let specimen: [FHIRReference]?
    let bodySite: [FHIRCodeableConcept]?
    let note: [FHIRAnnotation]?
    let patientInstruction: String?
    let relevantHistory: [FHIRReference]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, instantiatesUri,
             basedOn, replaces, requisition, status, intent, category,
             priority, doNotPerform, code, orderDetail, subject, encounter,
             occurrenceDateTime, occurrencePeriod, authoredOn, requester,
             performerType, performer, locationCode, locationReference,
             reasonCode, reasonReference, insurance, supportingInfo,
             specimen, bodySite, note, patientInstruction, relevantHistory
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         status: String,
         intent: String = "proposal",
         code: FHIRCodeableConcept? = nil,
         subject: FHIRReference,
         authoredOn: String? = nil,
         requester: FHIRReference? = nil,
         reasonCode: [FHIRCodeableConcept]? = nil,
         note: [FHIRAnnotation]? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = nil
        self.instantiatesUri = nil
        self.basedOn = nil
        self.replaces = nil
        self.requisition = nil
        self.status = status
        self.intent = intent
        self.category = nil
        self.priority = nil
        self.doNotPerform = nil
        self.code = code
        self.orderDetail = nil
        self.subject = subject
        self.encounter = nil
        self.occurrenceDateTime = nil
        self.occurrencePeriod = nil
        self.authoredOn = authoredOn
        self.requester = requester
        self.performerType = nil
        self.performer = nil
        self.locationCode = nil
        self.locationReference = nil
        self.reasonCode = reasonCode
        self.reasonReference = nil
        self.insurance = nil
        self.supportingInfo = nil
        self.specimen = nil
        self.bodySite = nil
        self.note = note
        self.patientInstruction = nil
        self.relevantHistory = nil
    }
}
