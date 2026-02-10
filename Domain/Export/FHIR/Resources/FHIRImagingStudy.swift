//
//  FHIRImagingStudy.swift
//  MediScribe
//
//  FHIR R4 ImagingStudy resource — EHDS imaging domain.
//

import Foundation

struct FHIRImagingStudy: Codable {
    let resourceType: String = "ImagingStudy"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let status: String              // registered | available | cancelled | entered-in-error | unknown
    let modality: [FHIRCoding]?
    let subject: FHIRReference
    let encounter: FHIRReference?
    let started: String?            // dateTime
    let basedOn: [FHIRReference]?
    let referrer: FHIRReference?
    let interpreter: [FHIRReference]?
    let endpoint: [FHIRReference]?
    let numberOfSeries: Int?
    let numberOfInstances: Int?
    let procedureReference: FHIRReference?
    let procedureCode: [FHIRCodeableConcept]?
    let location: FHIRReference?
    let reasonCode: [FHIRCodeableConcept]?
    let note: [FHIRAnnotation]?
    let description: String?
    let series: [FHIRImagingStudySeries]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, status, modality,
             subject, encounter, started, basedOn, referrer, interpreter,
             endpoint, numberOfSeries, numberOfInstances, procedureReference,
             procedureCode, location, reasonCode, note, description, series
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         status: String = "available",
         modality: [FHIRCoding]? = nil,
         subject: FHIRReference,
         started: String? = nil,
         description: String? = nil,
         note: [FHIRAnnotation]? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = nil
        self.status = status
        self.modality = modality
        self.subject = subject
        self.encounter = nil
        self.started = started
        self.basedOn = nil
        self.referrer = nil
        self.interpreter = nil
        self.endpoint = nil
        self.numberOfSeries = nil
        self.numberOfInstances = nil
        self.procedureReference = nil
        self.procedureCode = nil
        self.location = nil
        self.reasonCode = nil
        self.note = note
        self.description = description
        self.series = nil
    }
}

struct FHIRImagingStudySeries: Codable {
    let uid: String
    let number: Int?
    let modality: FHIRCoding
    let description: String?
    let numberOfInstances: Int?
    let bodySite: FHIRCoding?
    let laterality: FHIRCoding?
    let started: String?
    let performer: [FHIRImagingStudyPerformer]?
    let instance: [FHIRImagingStudyInstance]?
}

struct FHIRImagingStudyPerformer: Codable {
    let function: FHIRCodeableConcept?
    let actor: FHIRReference
}

struct FHIRImagingStudyInstance: Codable {
    let uid: String
    let sopClass: FHIRCoding
    let number: Int?
    let title: String?
}
