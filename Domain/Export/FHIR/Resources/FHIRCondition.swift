//
//  FHIRCondition.swift
//  MediScribe
//
//  FHIR R4 Condition resource.
//  SAFETY: Only used for clinician-entered, confirmed working diagnoses.
//  AI-generated assessments MUST use FHIRClinicalImpression instead.
//

import Foundation

struct FHIRCondition: Codable {
    let resourceType: String = "Condition"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let clinicalStatus: FHIRCodeableConcept?
    let verificationStatus: FHIRCodeableConcept?
    let category: [FHIRCodeableConcept]?
    let severity: FHIRCodeableConcept?
    let code: FHIRCodeableConcept?
    let bodySite: [FHIRCodeableConcept]?
    let subject: FHIRReference
    let encounter: FHIRReference?
    let onsetDateTime: String?
    let onsetString: String?
    let recordedDate: String?
    let recorder: FHIRReference?
    let asserter: FHIRReference?
    let note: [FHIRAnnotation]?
    let evidence: [FHIRConditionEvidence]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, clinicalStatus,
             verificationStatus, category, severity, code, bodySite,
             subject, encounter, onsetDateTime, onsetString, recordedDate,
             recorder, asserter, note, evidence
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         clinicalStatus: FHIRCodeableConcept,
         verificationStatus: FHIRCodeableConcept,
         category: [FHIRCodeableConcept]? = nil,
         code: FHIRCodeableConcept? = nil,
         subject: FHIRReference,
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
        self.category = category
        self.severity = nil
        self.code = code
        self.bodySite = nil
        self.subject = subject
        self.encounter = nil
        self.onsetDateTime = nil
        self.onsetString = nil
        self.recordedDate = recordedDate
        self.recorder = recorder
        self.asserter = nil
        self.note = note
        self.evidence = nil
    }
}

struct FHIRConditionEvidence: Codable {
    let code: [FHIRCodeableConcept]?
    let detail: [FHIRReference]?
}
