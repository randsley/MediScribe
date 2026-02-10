//
//  FHIRMedicationStatement.swift
//  MediScribe
//
//  FHIR R4 MedicationStatement resource — eRx domain (documented medications).
//

import Foundation

struct FHIRMedicationStatement: Codable {
    let resourceType: String = "MedicationStatement"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let basedOn: [FHIRReference]?
    let partOf: [FHIRReference]?
    let status: String              // active | completed | entered-in-error | intended | stopped | on-hold | unknown | not-taken
    let statusReason: [FHIRCodeableConcept]?
    let category: FHIRCodeableConcept?
    let medicationCodeableConcept: FHIRCodeableConcept?
    let medicationReference: FHIRReference?
    let subject: FHIRReference
    let context: FHIRReference?
    let effectiveDateTime: String?
    let effectivePeriod: FHIRPeriod?
    let dateAsserted: String?
    let informationSource: FHIRReference?
    let derivedFrom: [FHIRReference]?
    let reasonCode: [FHIRCodeableConcept]?
    let reasonReference: [FHIRReference]?
    let note: [FHIRAnnotation]?
    let dosage: [FHIRDosage]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, basedOn, partOf,
             status, statusReason, category, medicationCodeableConcept,
             medicationReference, subject, context, effectiveDateTime,
             effectivePeriod, dateAsserted, informationSource, derivedFrom,
             reasonCode, reasonReference, note, dosage
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         status: String = "active",
         medicationCodeableConcept: FHIRCodeableConcept? = nil,
         subject: FHIRReference,
         dateAsserted: String? = nil,
         informationSource: FHIRReference? = nil,
         note: [FHIRAnnotation]? = nil,
         dosage: [FHIRDosage]? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = nil
        self.basedOn = nil
        self.partOf = nil
        self.status = status
        self.statusReason = nil
        self.category = nil
        self.medicationCodeableConcept = medicationCodeableConcept
        self.medicationReference = nil
        self.subject = subject
        self.context = nil
        self.effectiveDateTime = nil
        self.effectivePeriod = nil
        self.dateAsserted = dateAsserted
        self.informationSource = informationSource
        self.derivedFrom = nil
        self.reasonCode = nil
        self.reasonReference = nil
        self.note = note
        self.dosage = dosage
    }
}

// MARK: - Dosage (shared with MedicationRequest)

struct FHIRDosage: Codable {
    let sequence: Int?
    let text: String?
    let patientInstruction: String?
    let timing: FHIRTiming?
    let asNeededBoolean: Bool?
    let route: FHIRCodeableConcept?
    let doseAndRate: [FHIRDosageDoseAndRate]?

    init(text: String? = nil, patientInstruction: String? = nil,
         route: FHIRCodeableConcept? = nil) {
        self.sequence = nil
        self.text = text
        self.patientInstruction = patientInstruction
        self.timing = nil
        self.asNeededBoolean = nil
        self.route = route
        self.doseAndRate = nil
    }
}

struct FHIRDosageDoseAndRate: Codable {
    let type: FHIRCodeableConcept?
    let doseQuantity: FHIRQuantity?
    let rateQuantity: FHIRQuantity?
}

struct FHIRTiming: Codable {
    let event: [String]?
    let code: FHIRCodeableConcept?
}
