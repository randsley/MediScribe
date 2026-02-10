//
//  FHIRProvenance.swift
//  MediScribe
//
//  FHIR R4 Provenance resource — AI attribution audit trail.
//  All AI-assisted resources receive a Provenance resource linking them
//  to the MediScribe model version and generation timestamp.
//

import Foundation

struct FHIRProvenance: Codable {
    let resourceType: String = "Provenance"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let target: [FHIRReference]        // Resources this provenance applies to
    let occurredPeriod: FHIRPeriod?
    let occurredDateTime: String?
    let recorded: String               // instant (when recorded)
    let policy: [String]?              // Policy URI(s)
    let location: FHIRReference?
    let reason: [FHIRCodeableConcept]?
    let activity: FHIRCodeableConcept?
    let agent: [FHIRProvenanceAgent]
    let entity: [FHIRProvenanceEntity]?
    let signature: [FHIRSignature]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, target, occurredPeriod,
             occurredDateTime, recorded, policy, location, reason,
             activity, agent, entity, signature
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         target: [FHIRReference],
         recorded: String,
         agent: [FHIRProvenanceAgent],
         entity: [FHIRProvenanceEntity]? = nil,
         reason: [FHIRCodeableConcept]? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.target = target
        self.occurredPeriod = nil
        self.occurredDateTime = nil
        self.recorded = recorded
        self.policy = nil
        self.location = nil
        self.reason = reason
        self.activity = nil
        self.agent = agent
        self.entity = entity
        self.signature = nil
    }
}

// MARK: - Provenance.Agent

struct FHIRProvenanceAgent: Codable {
    let type: FHIRCodeableConcept?
    let role: [FHIRCodeableConcept]?
    let who: FHIRReference
    let onBehalfOf: FHIRReference?

    init(type: FHIRCodeableConcept? = nil,
         role: [FHIRCodeableConcept]? = nil,
         who: FHIRReference,
         onBehalfOf: FHIRReference? = nil) {
        self.type = type
        self.role = role
        self.who = who
        self.onBehalfOf = onBehalfOf
    }
}

// MARK: - Provenance.Entity

struct FHIRProvenanceEntity: Codable {
    let role: String            // derivation | revision | quotation | source | removal
    let what: FHIRReference
    let agent: [FHIRProvenanceAgent]?

    init(role: String = "source", what: FHIRReference, agent: [FHIRProvenanceAgent]? = nil) {
        self.role = role
        self.what = what
        self.agent = agent
    }
}

// MARK: - Signature

struct FHIRSignature: Codable {
    let type: [FHIRCoding]
    let `when`: String          // instant
    let who: FHIRReference
    let onBehalfOf: FHIRReference?
    let targetFormat: String?
    let sigFormat: String?
    let data: String?           // base64Binary

    enum CodingKeys: String, CodingKey {
        case type, `when`, who, onBehalfOf, targetFormat, sigFormat, data
    }
}
