//
//  EHDSProfile.swift
//  MediScribe
//
//  EHDS / EEHRxF domain coverage profile constants and helpers.
//  Reference: https://health.ec.europa.eu/ehealth-digital-health-and-care/electronic-health-data-space_en
//

import Foundation

enum EHDSProfile {

    // MARK: - EHDS Domain Identifiers

    static let ehdsLabDomain       = "EHDS-Labs"
    static let ehdsMedicalImaging  = "EHDS-MedicalImaging"
    static let ehdsEPrescription   = "EHDS-ePrescription"
    static let ehdsPatientSummary  = "EHDS-PatientSummary"
    static let ehdsClinicalDocument = "EHDS-ClinicalDocument"

    // MARK: - eRx (ePrescription) Profile URIs

    /// MedicationStatement — used for documented medications (source: provider)
    static let medicationStatementProfileURI = "http://hl7.eu/fhir/StructureDefinition/MedicationStatement-eu-mhd"

    /// MedicationRequest — DRAFT/PROPOSAL only (not a prescribing system)
    static let medicationRequestProfileURI   = "http://hl7.eu/fhir/StructureDefinition/MedicationRequest-eu-ep"

    // MARK: - Imaging Profile URIs

    /// ImagingStudy — EHDS imaging domain
    static let imagingStudyProfileURI        = "http://hl7.eu/fhir/StructureDefinition/ImagingStudy-eu-mhd"

    // MARK: - DICOM Modality Codings (used in ImagingStudy.modality / series.modality)

    static func modalityCoding(for imageType: String) -> FHIRCoding {
        let upper = imageType.uppercased()
        switch upper {
        case "CHEST X-RAY", "CXR", "X-RAY", "RADIOGRAPH":
            return FHIRCoding(system: "http://dicom.nema.org/resources/ontology/DCM",
                              code: "CR", display: "Computed Radiography")
        case "CT", "CT SCAN", "COMPUTED TOMOGRAPHY":
            return FHIRCoding(system: "http://dicom.nema.org/resources/ontology/DCM",
                              code: "CT", display: "Computed Tomography")
        case "MRI", "MR", "MAGNETIC RESONANCE":
            return FHIRCoding(system: "http://dicom.nema.org/resources/ontology/DCM",
                              code: "MR", display: "Magnetic Resonance")
        case "ULTRASOUND", "US", "ECHO":
            return FHIRCoding(system: "http://dicom.nema.org/resources/ontology/DCM",
                              code: "US", display: "Ultrasound")
        default:
            return FHIRCoding(system: "http://dicom.nema.org/resources/ontology/DCM",
                              code: "OT", display: imageType.isEmpty ? "Other" : imageType)
        }
    }

    // MARK: - MedicationStatement helpers

    static func medicationStatementMeta() -> FHIRMeta {
        FHIRMeta(profile: [medicationStatementProfileURI])
    }

    static func medicationRequestMeta() -> FHIRMeta {
        FHIRMeta(profile: [medicationRequestProfileURI])
    }

    // MARK: - Imaging Study meta

    static func imagingStudyMeta() -> FHIRMeta {
        FHIRMeta(profile: [imagingStudyProfileURI])
    }

    // MARK: - Service categorisation

    /// LOINC code for referral note
    static let referralNoteLOINC = "57133-1"
    static let referralNoteDisplay = "Referral note"

    static var referralCode: FHIRCodeableConcept {
        FHIRCodeableConcept.coded(
            system: FHIRSystems.loinc,
            code: referralNoteLOINC,
            display: referralNoteDisplay
        )
    }
}
