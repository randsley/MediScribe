//
//  FHIREncounter.swift
//  MediScribe
//
//  FHIR R4 Encounter resource — clinical encounter context.
//

import Foundation

struct FHIREncounter: Codable {
    let resourceType: String = "Encounter"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let status: String              // planned | arrived | triaged | in-progress | onleave | finished | cancelled | entered-in-error | unknown
    let statusHistory: [FHIREncounterStatusHistory]?
    let `class`: FHIRCoding
    let classHistory: [FHIREncounterClassHistory]?
    let type: [FHIRCodeableConcept]?
    let serviceType: FHIRCodeableConcept?
    let priority: FHIRCodeableConcept?
    let subject: FHIRReference?
    let episodeOfCare: [FHIRReference]?
    let basedOn: [FHIRReference]?
    let participant: [FHIREncounterParticipant]?
    let period: FHIRPeriod?
    let reasonCode: [FHIRCodeableConcept]?
    let reasonReference: [FHIRReference]?
    let location: [FHIREncounterLocation]?
    let serviceProvider: FHIRReference?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, status, statusHistory,
             `class`, classHistory, type, serviceType, priority, subject,
             episodeOfCare, basedOn, participant, period, reasonCode,
             reasonReference, location, serviceProvider
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         status: String = "finished",
         `class`: FHIRCoding,
         subject: FHIRReference? = nil,
         period: FHIRPeriod? = nil,
         serviceProvider: FHIRReference? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = nil
        self.status = status
        self.statusHistory = nil
        self.class = `class`
        self.classHistory = nil
        self.type = nil
        self.serviceType = nil
        self.priority = nil
        self.subject = subject
        self.episodeOfCare = nil
        self.basedOn = nil
        self.participant = nil
        self.period = period
        self.reasonCode = nil
        self.reasonReference = nil
        self.location = nil
        self.serviceProvider = serviceProvider
    }
}

struct FHIREncounterStatusHistory: Codable {
    let status: String
    let period: FHIRPeriod
}

struct FHIREncounterClassHistory: Codable {
    let `class`: FHIRCoding
    let period: FHIRPeriod

    enum CodingKeys: String, CodingKey {
        case `class`, period
    }
}

struct FHIREncounterParticipant: Codable {
    let type: [FHIRCodeableConcept]?
    let period: FHIRPeriod?
    let individual: FHIRReference?
}

struct FHIREncounterLocation: Codable {
    let location: FHIRReference
    let status: String?
    let period: FHIRPeriod?
}
