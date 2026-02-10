//
//  FHIRPatientMapper.swift
//  MediScribe
//
//  Maps AppSettings (ClinicianInfo, FacilityInfo) to Patient, Practitioner, Organization.
//  GDPR: Patient.name and real PII excluded by default. Pseudonymous identifier used.
//

import Foundation

struct FHIRPatientMapper {

    // MARK: - Patient

    /// Build a pseudonymous FHIR Patient from de-identified identifiers.
    /// - Parameters:
    ///   - patientIdentifier: De-identified patient reference string.
    ///   - identifierSystem: The identifier system URI (from FacilityInfo or fallback).
    ///   - gender: Optional gender string ("male" | "female" | "other" | "unknown").
    ///   - birthYear: Optional birth year (YYYY only, for IPS cross-border, no full DOB).
    static func patient(
        patientIdentifier: String?,
        identifierSystem: String = FHIRSystems.mediScribeLocal,
        gender: String? = nil,
        birthYear: Int? = nil
    ) -> (resource: FHIRPatient, id: String) {
        let id = UUID().uuidString
        let identifier: FHIRIdentifier? = patientIdentifier.map {
            FHIRIdentifier(system: identifierSystem, value: $0, use: "secondary")
        }
        let birthDate = birthYear.map { "\($0)" }  // YYYY only — no full DOB per GDPR

        let meta = EUBaseProfile.patientMeta()
        let patient = FHIRPatient(
            id: id,
            meta: meta,
            identifier: identifier.map { [$0] },
            name: nil,          // PII excluded by default
            gender: gender,
            birthDate: birthDate,
            text: FHIRNarrative.fromText("De-identified patient record — MediScribe export")
        )
        return (patient, id)
    }

    // MARK: - Practitioner

    /// Build a FHIR Practitioner from ClinicianInfo.
    static func practitioner(from clinicianInfo: ClinicianInfo) -> (resource: FHIRPractitioner, id: String) {
        let id = UUID().uuidString

        // Build HumanName from name string
        let name: FHIRHumanName? = clinicianInfo.name.isEmpty ? nil : FHIRHumanName(text: clinicianInfo.name)

        // Build qualification from credentials
        let qualification: FHIRPractitionerQualification? = clinicianInfo.credentials.isEmpty ? nil :
            FHIRPractitionerQualification(
                code: FHIRCodeableConcept.text(clinicianInfo.credentials)
            )

        // Build identifier from license number
        let identifier: FHIRIdentifier? = clinicianInfo.licenseNumber.isEmpty ? nil :
            FHIRIdentifier(system: FHIRSystems.mediScribeLocal, value: clinicianInfo.licenseNumber, use: "official")

        let meta = EUBaseProfile.practitionerMeta()
        let practitioner = FHIRPractitioner(
            id: id,
            meta: meta,
            identifier: identifier.map { [$0] },
            name: name.map { [$0] },
            qualification: qualification.map { [$0] },
            text: FHIRNarrative.fromText(clinicianInfo.name.isEmpty ? "Unknown Clinician" : clinicianInfo.name)
        )
        return (practitioner, id)
    }

    // MARK: - Organization

    /// Build a FHIR Organization from FacilityInfo.
    static func organization(from facilityInfo: FacilityInfo) -> (resource: FHIROrganization, id: String) {
        let id = UUID().uuidString

        var telecom: [FHIRContactPoint] = []
        if !facilityInfo.phoneNumber.isEmpty {
            telecom.append(FHIRContactPoint(system: "phone", value: facilityInfo.phoneNumber))
        }
        if !facilityInfo.email.isEmpty {
            telecom.append(FHIRContactPoint(system: "email", value: facilityInfo.email))
        }

        let address: FHIRAddress? = facilityInfo.location.isEmpty ? nil :
            FHIRAddress(text: facilityInfo.location)

        let meta = EUBaseProfile.organizationMeta()
        let organization = FHIROrganization(
            id: id,
            meta: meta,
            identifier: nil,
            name: facilityInfo.name.isEmpty ? nil : facilityInfo.name,
            telecom: telecom.isEmpty ? nil : telecom,
            address: address.map { [$0] },
            text: FHIRNarrative.fromText(facilityInfo.name.isEmpty ? "Unknown Facility" : facilityInfo.name)
        )
        return (organization, id)
    }
}
