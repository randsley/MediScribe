//
//  FHIRPatient.swift
//  MediScribe
//
//  FHIR R4 Patient resource — HL7 EU Base Patient profile.
//

import Foundation

struct FHIRPatient: Codable {
    let resourceType: String = "Patient"
    let id: String
    let meta: FHIRMeta?
    let text: FHIRNarrative?
    let identifier: [FHIRIdentifier]?
    let active: Bool?
    let name: [FHIRHumanName]?
    let telecom: [FHIRContactPoint]?
    let gender: String?         // male | female | other | unknown
    let birthDate: String?      // date (YYYY or YYYY-MM or YYYY-MM-DD)
    let deceasedBoolean: Bool?
    let address: [FHIRAddress]?
    let communication: [FHIRPatientCommunication]?
    let generalPractitioner: [FHIRReference]?
    let managingOrganization: FHIRReference?

    enum CodingKeys: String, CodingKey {
        case resourceType, id, meta, text, identifier, active, name, telecom,
             gender, birthDate, deceasedBoolean, address, communication,
             generalPractitioner, managingOrganization
    }

    init(id: String = UUID().uuidString,
         meta: FHIRMeta? = nil,
         identifier: [FHIRIdentifier]? = nil,
         name: [FHIRHumanName]? = nil,
         gender: String? = nil,
         birthDate: String? = nil,
         text: FHIRNarrative? = nil) {
        self.id = id
        self.meta = meta
        self.text = text
        self.identifier = identifier
        self.active = true
        self.name = name
        self.telecom = nil
        self.gender = gender
        self.birthDate = birthDate
        self.deceasedBoolean = nil
        self.address = nil
        self.communication = nil
        self.generalPractitioner = nil
        self.managingOrganization = nil
    }
}

struct FHIRPatientCommunication: Codable {
    let language: FHIRCodeableConcept
    let preferred: Bool?
}
