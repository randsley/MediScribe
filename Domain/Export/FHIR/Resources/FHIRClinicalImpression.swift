//
//  FHIRClinicalImpression.swift
//  MediScribe
//
//  FHIR R4 ClinicalImpression resource.
//
//  SAFETY ARCHITECTURE:
//  AI-generated assessments MUST map to ClinicalImpression, NOT Condition.
//  This preserves the descriptive-only boundary:
//    - AI / unsigned assessments → ClinicalImpression (status: in-progress)
//    - AI assessments with possible/probable certainty → ClinicalImpression (status: completed)
//    - Clinician-signed with certainty:confirmed → Condition (verificationStatus: confirmed)
//

import Foundation

struct FHIRClinicalImpression: Codable {
    let resourceType: String = "ClinicalImpression"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let status: String              // in-progress | completed | entered-in-error
    let statusReason: FHIRCodeableConcept?
    let code: FHIRCodeableConcept?
    let description: String?
    let subject: FHIRReference
    let encounter: FHIRReference?
    let effectiveDateTime: String?
    let effectivePeriod: FHIRPeriod?
    let date: String?               // When recorded
    let assessor: FHIRReference?
    let previous: FHIRReference?
    let problem: [FHIRReference]?
    let investigation: [FHIRClinicalImpressionInvestigation]?
    let `protocol`: [String]?       // URI
    let summary: String?
    let finding: [FHIRClinicalImpressionFinding]?
    let prognosisCodeableConcept: [FHIRCodeableConcept]?
    let prognosisReference: [FHIRReference]?
    let supportingInfo: [FHIRReference]?
    let note: [FHIRAnnotation]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, status, statusReason,
             code, description, subject, encounter, effectiveDateTime,
             effectivePeriod, date, assessor, previous, problem,
             investigation, `protocol`, summary, finding,
             prognosisCodeableConcept, prognosisReference, supportingInfo, note
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         status: String = "in-progress",
         description: String? = nil,
         subject: FHIRReference,
         date: String? = nil,
         assessor: FHIRReference? = nil,
         summary: String? = nil,
         finding: [FHIRClinicalImpressionFinding]? = nil,
         note: [FHIRAnnotation]? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = nil
        self.status = status
        self.statusReason = nil
        self.code = nil
        self.description = description
        self.subject = subject
        self.encounter = nil
        self.effectiveDateTime = nil
        self.effectivePeriod = nil
        self.date = date
        self.assessor = assessor
        self.previous = nil
        self.problem = nil
        self.investigation = nil
        self.protocol = nil
        self.summary = summary
        self.finding = finding
        self.prognosisCodeableConcept = nil
        self.prognosisReference = nil
        self.supportingInfo = nil
        self.note = note
    }
}

struct FHIRClinicalImpressionInvestigation: Codable {
    let code: FHIRCodeableConcept
    let item: [FHIRReference]?
}

struct FHIRClinicalImpressionFinding: Codable {
    let itemCodeableConcept: FHIRCodeableConcept?
    let itemReference: FHIRReference?
    let basis: String?

    init(itemCodeableConcept: FHIRCodeableConcept? = nil,
         itemReference: FHIRReference? = nil,
         basis: String? = nil) {
        self.itemCodeableConcept = itemCodeableConcept
        self.itemReference = itemReference
        self.basis = basis
    }
}
