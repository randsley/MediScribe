//
//  FHIRObservation.swift
//  MediScribe
//
//  FHIR R4 Observation resource — vitals (LOINC) and lab result observations.
//

import Foundation

struct FHIRObservation: Codable {
    let resourceType: String = "Observation"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let basedOn: [FHIRReference]?
    let partOf: [FHIRReference]?
    let status: String         // registered | preliminary | final | amended | ...
    let category: [FHIRCodeableConcept]?
    let code: FHIRCodeableConcept
    let subject: FHIRReference?
    let focus: [FHIRReference]?
    let encounter: FHIRReference?
    let effectiveDateTime: String?
    let effectivePeriod: FHIRPeriod?
    let issued: String?
    let performer: [FHIRReference]?
    let valueQuantity: FHIRQuantity?
    let valueCodeableConcept: FHIRCodeableConcept?
    let valueString: String?
    let dataAbsentReason: FHIRCodeableConcept?
    let interpretation: [FHIRCodeableConcept]?
    let note: [FHIRAnnotation]?
    let bodySite: FHIRCodeableConcept?
    let method: FHIRCodeableConcept?
    let referenceRange: [FHIRObservationReferenceRange]?
    let hasMember: [FHIRReference]?
    let derivedFrom: [FHIRReference]?
    let component: [FHIRObservationComponent]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, basedOn, partOf,
             status, category, code, subject, focus, encounter,
             effectiveDateTime, effectivePeriod, issued, performer,
             valueQuantity, valueCodeableConcept, valueString,
             dataAbsentReason, interpretation, note, bodySite, method,
             referenceRange, hasMember, derivedFrom, component
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         status: String = "final",
         category: [FHIRCodeableConcept]? = nil,
         code: FHIRCodeableConcept,
         subject: FHIRReference? = nil,
         effectiveDateTime: String? = nil,
         valueQuantity: FHIRQuantity? = nil,
         valueString: String? = nil,
         referenceRange: [FHIRObservationReferenceRange]? = nil,
         component: [FHIRObservationComponent]? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = nil
        self.basedOn = nil
        self.partOf = nil
        self.status = status
        self.category = category
        self.code = code
        self.subject = subject
        self.focus = nil
        self.encounter = nil
        self.effectiveDateTime = effectiveDateTime
        self.effectivePeriod = nil
        self.issued = nil
        self.performer = nil
        self.valueQuantity = valueQuantity
        self.valueCodeableConcept = nil
        self.valueString = valueString
        self.dataAbsentReason = nil
        self.interpretation = nil
        self.note = nil
        self.bodySite = nil
        self.method = nil
        self.referenceRange = referenceRange
        self.hasMember = nil
        self.derivedFrom = nil
        self.component = component
    }
}

// MARK: - Observation.ReferenceRange

struct FHIRObservationReferenceRange: Codable {
    let low: FHIRQuantity?
    let high: FHIRQuantity?
    let type: FHIRCodeableConcept?
    let appliesTo: [FHIRCodeableConcept]?
    let age: FHIRRange?
    let text: String?

    init(text: String? = nil, low: FHIRQuantity? = nil, high: FHIRQuantity? = nil) {
        self.low = low
        self.high = high
        self.type = nil
        self.appliesTo = nil
        self.age = nil
        self.text = text
    }
}

// MARK: - Observation.Component

struct FHIRObservationComponent: Codable {
    let code: FHIRCodeableConcept
    let valueQuantity: FHIRQuantity?
    let valueString: String?
    let dataAbsentReason: FHIRCodeableConcept?

    init(code: FHIRCodeableConcept,
         valueQuantity: FHIRQuantity? = nil,
         valueString: String? = nil) {
        self.code = code
        self.valueQuantity = valueQuantity
        self.valueString = valueString
        self.dataAbsentReason = nil
    }
}

// MARK: - Range (for reference ranges)

struct FHIRRange: Codable {
    let low: FHIRQuantity?
    let high: FHIRQuantity?
}
