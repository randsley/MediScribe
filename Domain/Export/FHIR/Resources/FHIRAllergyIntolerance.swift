//
//  FHIRAllergyIntolerance.swift
//  MediScribe
//
//  FHIR R4 AllergyIntolerance resource.
//

import Foundation

struct FHIRAllergyIntolerance: Codable {
    let resourceType: String = "AllergyIntolerance"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let clinicalStatus: FHIRCodeableConcept?
    let verificationStatus: FHIRCodeableConcept?
    let type: String?            // allergy | intolerance
    let category: [String]?      // food | medication | environment | biologic
    let criticality: String?     // low | high | unable-to-assess
    let code: FHIRCodeableConcept?
    let patient: FHIRReference
    let encounter: FHIRReference?
    let onsetDateTime: String?
    let recordedDate: String?
    let recorder: FHIRReference?
    let asserter: FHIRReference?
    let note: [FHIRAnnotation]?
    let reaction: [FHIRAllergyReaction]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, clinicalStatus,
             verificationStatus, type, category, criticality, code,
             patient, encounter, onsetDateTime, recordedDate, recorder,
             asserter, note, reaction
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         clinicalStatus: FHIRCodeableConcept? = nil,
         verificationStatus: FHIRCodeableConcept? = nil,
         code: FHIRCodeableConcept? = nil,
         patient: FHIRReference,
         recordedDate: String? = nil,
         recorder: FHIRReference? = nil,
         note: [FHIRAnnotation]? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = nil
        self.clinicalStatus = clinicalStatus
        self.verificationStatus = verificationStatus
        self.type = nil
        self.category = nil
        self.criticality = nil
        self.code = code
        self.patient = patient
        self.encounter = nil
        self.onsetDateTime = nil
        self.recordedDate = recordedDate
        self.recorder = recorder
        self.asserter = nil
        self.note = note
        self.reaction = nil
    }
}

struct FHIRAllergyReaction: Codable {
    let substance: FHIRCodeableConcept?
    let manifestation: [FHIRCodeableConcept]
    let description: String?
    let severity: String?     // mild | moderate | severe
    let exposureRoute: FHIRCodeableConcept?
    let note: [FHIRAnnotation]?
}
