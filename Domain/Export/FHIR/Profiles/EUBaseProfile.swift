//
//  EUBaseProfile.swift
//  MediScribe
//
//  HL7 Europe Base profile URIs and national ID extensions.
//  Reference: http://hl7.eu/fhir/base
//

import Foundation

enum EUBaseProfile {

    // MARK: - EU Base Resource Profile URIs

    static let patientProfileURI      = "http://hl7.eu/fhir/base/StructureDefinition/Patient-eu-base"
    static let practitionerProfileURI = "http://hl7.eu/fhir/base/StructureDefinition/Practitioner-eu-base"
    static let organizationProfileURI = "http://hl7.eu/fhir/base/StructureDefinition/Organization-eu-base"

    // MARK: - EU Lab IG Profile URIs

    static let diagnosticReportLabProfileURI = "http://hl7.eu/fhir/laboratory/StructureDefinition/DiagnosticReport-lab-eu-lab"
    static let observationLabProfileURI      = "http://hl7.eu/fhir/laboratory/StructureDefinition/ObservationResultsLaboratory-eu-lab"

    // MARK: - National Patient Identifier System URIs
    // Used in Patient.identifier.system when facility has configured a national ID

    static let nhsNumberSystem       = "https://fhir.nhs.uk/Id/nhs-number"
    static let oidNetherlandsBSN     = "urn:oid:2.16.840.1.113883.2.4.6.3"
    static let oidFranceINS          = "urn:oid:1.2.250.1.213.1.4.8"
    static let oidGermanyKVID        = "http://fhir.de/CodeSystem/identifier-type-de-basis"
    static let mediScribeLocalSystem = FHIRSystems.mediScribeLocal

    // MARK: - EU Professional Qualification Extension URI

    static let professionalQualificationExtURI = "http://hl7.eu/fhir/base/StructureDefinition/practitioner-professional-qualification"

    // MARK: - Helper: EU Lab DiagnosticReport meta

    static func labDiagnosticReportMeta() -> FHIRMeta {
        FHIRMeta(profile: [diagnosticReportLabProfileURI])
    }

    // MARK: - Helper: EU Lab Observation meta

    static func labObservationMeta() -> FHIRMeta {
        FHIRMeta(profile: [observationLabProfileURI])
    }

    // MARK: - Helper: EU Patient meta

    static func patientMeta() -> FHIRMeta {
        FHIRMeta(profile: [patientProfileURI])
    }

    // MARK: - Helper: EU Practitioner meta

    static func practitionerMeta() -> FHIRMeta {
        FHIRMeta(profile: [practitionerProfileURI])
    }

    // MARK: - Helper: EU Organization meta

    static func organizationMeta() -> FHIRMeta {
        FHIRMeta(profile: [organizationProfileURI])
    }

    // MARK: - Lab DiagnosticReport Category (EU Lab IG)

    /// EU Lab IG requires category with LAB coding
    static var labCategory: [FHIRCodeableConcept] {
        [FHIRCodeableConcept.coded(
            system: FHIRSystems.diagnosticServiceSections,
            code: "LAB",
            display: "Laboratory"
        )]
    }

    // MARK: - Imaging DiagnosticReport Category

    static var imagingCategory: [FHIRCodeableConcept] {
        [FHIRCodeableConcept.coded(
            system: FHIRSystems.diagnosticServiceSections,
            code: "RAD",
            display: "Radiology"
        )]
    }
}
