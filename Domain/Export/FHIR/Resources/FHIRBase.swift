//
//  FHIRBase.swift
//  MediScribe
//
//  FHIR R4 shared primitive types used across all FHIR resources.
//  Covers: Extension, Coding, CodeableConcept, Identifier, Reference,
//          Narrative, Meta, Quantity, Period, Attachment.
//

import Foundation

// MARK: - FHIR Extension

struct FHIRExtension: Codable {
    let url: String
    let valueString: String?
    let valueCode: String?
    let valueUri: String?

    init(url: String, valueString: String? = nil, valueCode: String? = nil, valueUri: String? = nil) {
        self.url = url
        self.valueString = valueString
        self.valueCode = valueCode
        self.valueUri = valueUri
    }
}

// MARK: - Coding

struct FHIRCoding: Codable {
    let system: String?
    let version: String?
    let code: String?
    let display: String?
    let userSelected: Bool?

    init(system: String? = nil, code: String? = nil, display: String? = nil,
         version: String? = nil, userSelected: Bool? = nil) {
        self.system = system
        self.version = version
        self.code = code
        self.display = display
        self.userSelected = userSelected
    }
}

// MARK: - CodeableConcept

struct FHIRCodeableConcept: Codable {
    let coding: [FHIRCoding]?
    let text: String?

    init(coding: [FHIRCoding]? = nil, text: String? = nil) {
        self.coding = coding
        self.text = text
    }

    static func text(_ text: String) -> FHIRCodeableConcept {
        FHIRCodeableConcept(coding: nil, text: text)
    }

    static func coded(system: String, code: String, display: String? = nil, text: String? = nil) -> FHIRCodeableConcept {
        FHIRCodeableConcept(
            coding: [FHIRCoding(system: system, code: code, display: display)],
            text: text ?? display
        )
    }
}

// MARK: - Identifier

struct FHIRIdentifier: Codable {
    let use: String?       // usual | official | temp | secondary | old
    let type: FHIRCodeableConcept?
    let system: String?
    let value: String?
    let period: FHIRPeriod?

    init(system: String? = nil, value: String? = nil,
         use: String? = nil, type: FHIRCodeableConcept? = nil,
         period: FHIRPeriod? = nil) {
        self.use = use
        self.type = type
        self.system = system
        self.value = value
        self.period = period
    }
}

// MARK: - Reference

struct FHIRReference: Codable {
    let reference: String?  // e.g., "Patient/123"
    let type: String?       // e.g., "Patient"
    let identifier: FHIRIdentifier?
    let display: String?

    init(reference: String? = nil, type: String? = nil,
         identifier: FHIRIdentifier? = nil, display: String? = nil) {
        self.reference = reference
        self.type = type
        self.identifier = identifier
        self.display = display
    }

    static func local(_ resourceType: String, id: String) -> FHIRReference {
        FHIRReference(reference: "\(resourceType)/\(id)")
    }

    static func urn(_ id: String) -> FHIRReference {
        FHIRReference(reference: "urn:uuid:\(id)")
    }
}

// MARK: - Narrative

struct FHIRNarrative: Codable {
    let status: String  // generated | extensions | additional | empty
    let div: String     // XHTML string (xhtml namespace required)

    init(status: String = "generated", div: String) {
        self.status = status
        self.div = div
    }

    static func fromText(_ text: String, status: String = "generated") -> FHIRNarrative {
        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        let div = "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p>\(escaped)</p></div>"
        return FHIRNarrative(status: status, div: div)
    }
}

// MARK: - Meta

struct FHIRMeta: Codable {
    let versionId: String?
    let lastUpdated: String? // instant (ISO 8601)
    let source: String?
    let profile: [String]?
    let security: [FHIRCoding]?
    let tag: [FHIRCoding]?

    init(profile: [String]? = nil, lastUpdated: String? = nil,
         source: String? = nil, security: [FHIRCoding]? = nil,
         tag: [FHIRCoding]? = nil, versionId: String? = nil) {
        self.versionId = versionId
        self.lastUpdated = lastUpdated
        self.source = source
        self.profile = profile
        self.security = security
        self.tag = tag
    }
}

// MARK: - Quantity

struct FHIRQuantity: Codable {
    let value: Double?
    let comparator: String? // < | <= | >= | >
    let unit: String?
    let system: String?    // http://unitsofmeasure.org for UCUM
    let code: String?      // UCUM code

    init(value: Double? = nil, unit: String? = nil,
         system: String? = nil, code: String? = nil,
         comparator: String? = nil) {
        self.value = value
        self.comparator = comparator
        self.unit = unit
        self.system = system
        self.code = code
    }

    static func ucum(value: Double, unit: String, ucumCode: String) -> FHIRQuantity {
        FHIRQuantity(value: value, unit: unit,
                     system: FHIRSystems.ucum, code: ucumCode)
    }
}

// MARK: - Period

struct FHIRPeriod: Codable {
    let start: String? // dateTime
    let end: String?   // dateTime

    init(start: String? = nil, end: String? = nil) {
        self.start = start
        self.end = end
    }
}

// MARK: - Attachment

struct FHIRAttachment: Codable {
    let contentType: String? // MIME type
    let language: String?
    let data: String?        // base64Binary
    let url: String?
    let size: Int?
    let hash: String?        // base64Binary SHA-1
    let title: String?
    let creation: String?    // dateTime

    init(contentType: String? = nil, data: String? = nil,
         url: String? = nil, title: String? = nil,
         language: String? = nil, creation: String? = nil) {
        self.contentType = contentType
        self.language = language
        self.data = data
        self.url = url
        self.size = nil
        self.hash = nil
        self.title = title
        self.creation = creation
    }
}

// MARK: - HumanName

struct FHIRHumanName: Codable {
    let use: String?   // usual | official | temp | nickname | anonymous | old | maiden
    let text: String?
    let family: String?
    let given: [String]?
    let prefix: [String]?
    let suffix: [String]?
    let period: FHIRPeriod?

    init(text: String? = nil, family: String? = nil,
         given: [String]? = nil, prefix: [String]? = nil,
         suffix: [String]? = nil, use: String? = "official") {
        self.use = use
        self.text = text
        self.family = family
        self.given = given
        self.prefix = prefix
        self.suffix = suffix
        self.period = nil
    }
}

// MARK: - ContactPoint

struct FHIRContactPoint: Codable {
    let system: String? // phone | fax | email | pager | url | sms | other
    let value: String?
    let use: String?    // home | work | temp | old | mobile
    let rank: Int?
    let period: FHIRPeriod?

    init(system: String, value: String, use: String? = "work") {
        self.system = system
        self.value = value
        self.use = use
        self.rank = nil
        self.period = nil
    }
}

// MARK: - Address

struct FHIRAddress: Codable {
    let use: String?   // home | work | temp | old | billing
    let type: String?  // postal | physical | both
    let text: String?
    let line: [String]?
    let city: String?
    let district: String?
    let state: String?
    let postalCode: String?
    let country: String?
    let period: FHIRPeriod?

    init(text: String? = nil, city: String? = nil,
         country: String? = nil, use: String? = "work") {
        self.use = use
        self.type = nil
        self.text = text
        self.line = nil
        self.city = city
        self.district = nil
        self.state = nil
        self.postalCode = nil
        self.country = country
        self.period = nil
    }
}

// MARK: - Annotation

struct FHIRAnnotation: Codable {
    let authorString: String?
    let time: String?    // dateTime
    let text: String     // markdown

    init(text: String, author: String? = nil, time: String? = nil) {
        self.authorString = author
        self.time = time
        self.text = text
    }
}

// MARK: - Common FHIR System URIs

enum FHIRSystems {
    static let loinc       = "http://loinc.org"
    static let snomed      = "http://snomed.info/sct"
    static let rxnorm      = "http://www.nlm.nih.gov/research/umls/rxnorm"
    static let ucum        = "http://unitsofmeasure.org"
    static let icd10       = "http://hl7.org/fhir/sid/icd-10"
    static let icd10cm     = "http://hl7.org/fhir/sid/icd-10-cm"
    static let npiProvider = "http://hl7.org/fhir/sid/us-npi"
    static let v3NullFlavor = "http://terminology.hl7.org/CodeSystem/v3-NullFlavor"
    static let v3ActCode   = "http://terminology.hl7.org/CodeSystem/v3-ActCode"
    static let observationCategory = "http://terminology.hl7.org/CodeSystem/observation-category"
    static let diagnosticServiceSections = "http://terminology.hl7.org/CodeSystem/v2-0074"
    static let medicationStatementStatus = "http://hl7.org/fhir/CodeSystem/medication-statement-status"
    static let provenanceAgentType = "http://terminology.hl7.org/CodeSystem/provenance-participant-type"
    static let mediScribeLocal = "urn:mediscribe:local"
}

// MARK: - Date Formatters

extension ISO8601DateFormatter {
    static let fhirDate: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    static let fhirDateTime: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

extension Date {
    var fhirDate: String { ISO8601DateFormatter.fhirDate.string(from: self) }
    var fhirDateTime: String { ISO8601DateFormatter.fhirDateTime.string(from: self) }
}
