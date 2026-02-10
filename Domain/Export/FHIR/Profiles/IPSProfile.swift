//
//  IPSProfile.swift
//  MediScribe
//
//  IPS (International Patient Summary) IG profile URIs and section LOINC codes.
//  Reference: http://hl7.org/fhir/uv/ips/
//

import Foundation

enum IPSProfile {

    // MARK: - Profile URIs

    static let bundleProfileURI      = "http://hl7.org/fhir/uv/ips/StructureDefinition/Bundle-uv-ips"
    static let compositionProfileURI = "http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips"
    static let patientProfileURI     = "http://hl7.org/fhir/uv/ips/StructureDefinition/Patient-uv-ips"
    static let medicationStatementProfileURI = "http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips"
    static let allergyIntoleranceProfileURI  = "http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips"
    static let conditionProfileURI           = "http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips"
    static let observationVitalsProfileURI   = "http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-vitalsigns-uv-ips"
    static let diagnosticReportProfileURI    = "http://hl7.org/fhir/uv/ips/StructureDefinition/DiagnosticReport-uv-ips"
    static let imagingStudyProfileURI        = "http://hl7.org/fhir/uv/ips/StructureDefinition/ImagingStudy-uv-ips"
    static let mediaProfileURI               = "http://hl7.org/fhir/uv/ips/StructureDefinition/Media-observation-uv-ips"

    // MARK: - Composition Type

    /// LOINC code for Patient Summary document
    static let compositionTypeCoding = FHIRCoding(
        system: FHIRSystems.loinc,
        code: "60591-5",
        display: "Patient summary Document"
    )

    // MARK: - IPS Mandatory Section LOINC Codes

    /// Medication Summary — REQUIRED
    static let sectionMedicationLOINC     = "10160-0"
    static let sectionMedicationDisplay   = "History of Medication use Narrative"

    /// Allergies and Intolerances — REQUIRED
    static let sectionAllergyLOINC        = "48765-2"
    static let sectionAllergyDisplay      = "Allergies and adverse reactions Document"

    /// Problem List — REQUIRED
    static let sectionProblemLOINC        = "11450-4"
    static let sectionProblemDisplay      = "Problem list - Reported"

    /// Results (Lab / Diagnostics) — RECOMMENDED
    static let sectionResultsLOINC        = "30954-2"
    static let sectionResultsDisplay      = "Relevant diagnostic tests/laboratory data Narrative"

    /// Vital Signs — RECOMMENDED
    static let sectionVitalsLOINC         = "8716-3"
    static let sectionVitalsDisplay       = "Vital signs"

    /// History of Procedures — RECOMMENDED
    static let sectionProceduresLOINC     = "47519-4"
    static let sectionProceduresDisplay   = "History of Procedures Document"

    /// Encounters — OPTIONAL
    static let sectionEncountersLOINC     = "46240-8"
    static let sectionEncountersDisplay   = "History of encounters Narrative"

    // MARK: - Helper: Build IPS Section CodeableConcept

    static func sectionCode(loinc: String, display: String) -> FHIRCodeableConcept {
        FHIRCodeableConcept.coded(system: FHIRSystems.loinc, code: loinc, display: display)
    }

    // MARK: - Empty Reason (IPS)

    /// CodeableConcept for an absent/empty section with a known empty reason
    static func emptyReason(display: String = "No information available") -> FHIRCodeableConcept {
        FHIRCodeableConcept(
            coding: [FHIRCoding(
                system: FHIRSystems.v3NullFlavor,
                code: "NI",
                display: display
            )],
            text: display
        )
    }
}
