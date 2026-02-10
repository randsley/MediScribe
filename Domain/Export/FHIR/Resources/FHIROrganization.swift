//
//  FHIROrganization.swift
//  MediScribe
//
//  FHIR R4 Organization resource — HL7 EU Base Organization profile.
//

import Foundation

struct FHIROrganization: Codable {
    let resourceType: String = "Organization"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let active: Bool?
    let type: [FHIRCodeableConcept]?
    let name: String?
    let alias: [String]?
    let telecom: [FHIRContactPoint]?
    let address: [FHIRAddress]?
    let partOf: FHIRReference?
    let contact: [FHIROrganizationContact]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, active, type, name,
             alias, telecom, address, partOf, contact
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         identifier: [FHIRIdentifier]? = nil,
         name: String? = nil,
         telecom: [FHIRContactPoint]? = nil,
         address: [FHIRAddress]? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = identifier
        self.active = true
        self.type = nil
        self.name = name
        self.alias = nil
        self.telecom = telecom
        self.address = address
        self.partOf = nil
        self.contact = nil
    }
}

struct FHIROrganizationContact: Codable {
    let purpose: FHIRCodeableConcept?
    let name: FHIRHumanName?
    let telecom: [FHIRContactPoint]?
    let address: FHIRAddress?
}
