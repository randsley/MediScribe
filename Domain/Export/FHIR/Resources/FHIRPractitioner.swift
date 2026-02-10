//
//  FHIRPractitioner.swift
//  MediScribe
//
//  FHIR R4 Practitioner resource — HL7 EU Base Practitioner profile.
//

import Foundation

struct FHIRPractitioner: Codable {
    let resourceType: String = "Practitioner"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let active: Bool?
    let name: [FHIRHumanName]?
    let telecom: [FHIRContactPoint]?
    let address: [FHIRAddress]?
    let gender: String?
    let birthDate: String?
    let qualification: [FHIRPractitionerQualification]?
    let communication: [FHIRCodeableConcept]?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, active, name, telecom,
             address, gender, birthDate, qualification, communication
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         identifier: [FHIRIdentifier]? = nil,
         name: [FHIRHumanName]? = nil,
         qualification: [FHIRPractitionerQualification]? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = identifier
        self.active = true
        self.name = name
        self.telecom = nil
        self.address = nil
        self.gender = nil
        self.birthDate = nil
        self.qualification = qualification
        self.communication = nil
    }
}

struct FHIRPractitionerQualification: Codable {
    let identifier: [FHIRIdentifier]?
    let code: FHIRCodeableConcept
    let period: FHIRPeriod?
    let issuer: FHIRReference?

    init(code: FHIRCodeableConcept,
         identifier: [FHIRIdentifier]? = nil,
         period: FHIRPeriod? = nil,
         issuer: FHIRReference? = nil) {
        self.identifier = identifier
        self.code = code
        self.period = period
        self.issuer = issuer
    }
}
