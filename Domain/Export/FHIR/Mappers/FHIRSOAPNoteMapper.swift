//
//  FHIRSOAPNoteMapper.swift
//  MediScribe
//
//  Maps SOAPNoteData to FHIR Composition + ClinicalImpression.
//
//  SAFETY ARCHITECTURE:
//  - AI / unsigned → ClinicalImpression (status: in-progress)
//  - Clinician reviewed → ClinicalImpression (status: completed)
//  - Composition status: preliminary until signed, final when signed
//  - MedicationStatement + AllergyIntolerance from subjective section
//

import Foundation

struct FHIRSOAPNoteMapper {

    struct SOAPNoteResult {
        let composition: FHIRComposition
        let compositionID: String
        let clinicalImpression: FHIRClinicalImpression
        let clinicalImpressionID: String
        let medicationStatements: [FHIRMedicationStatement]
        let medicationStatementIDs: [String]
        let allergyIntolerances: [FHIRAllergyIntolerance]
        let allergyIntoleranceIDs: [String]
        let provenance: FHIRProvenance?
    }

    // MARK: - Public API

    static func map(
        _ note: SOAPNoteData,
        patientID: String,
        practitionerID: String,
        organizationID: String
    ) -> SOAPNoteResult {
        let patientRef = FHIRReference.urn(patientID)
        let practRef   = FHIRReference.urn(practitionerID)
        let orgRef     = FHIRReference.urn(organizationID)

        // Composition status mirrors review state
        let compositionStatus = compositionStatus(for: note.validationStatus)

        // Clinical impression maps AI assessment
        let (impression, impressionID) = makeClinicalImpression(
            note: note,
            patientRef: patientRef,
            assessorRef: practRef
        )

        // Medications from subjective
        let (medStatements, medIDs) = makeMedicationStatements(
            from: note.subjective.medications ?? [],
            patientRef: patientRef,
            informerRef: practRef,
            dateAsserted: note.generatedAt.fhirDateTime
        )

        // Allergies from subjective
        let (allergies, allergyIDs) = makeAllergyIntolerances(
            from: note.subjective.allergies ?? [],
            patientRef: patientRef,
            recorderRef: practRef,
            recordedDate: note.generatedAt.fhirDate
        )

        // Build sections
        var sections: [FHIRCompositionSection] = []

        // Problem List section
        let problemSection = FHIRCompositionSection(
            title: "Problem List",
            code: IPSProfile.sectionCode(loinc: IPSProfile.sectionProblemLOINC,
                                         display: IPSProfile.sectionProblemDisplay),
            text: FHIRNarrative.fromText(note.assessment.clinicalImpression),
            entry: [FHIRReference.urn(impressionID)],
            emptyReason: nil
        )
        sections.append(problemSection)

        // Medications section
        let medEntries = medIDs.map { FHIRReference.urn($0) }
        let medicationSection = FHIRCompositionSection(
            title: "Medications Summary",
            code: IPSProfile.sectionCode(loinc: IPSProfile.sectionMedicationLOINC,
                                         display: IPSProfile.sectionMedicationDisplay),
            text: FHIRNarrative.fromText(
                note.subjective.medications?.joined(separator: "\n") ?? "No medications documented"
            ),
            entry: medEntries.isEmpty ? nil : medEntries,
            emptyReason: medEntries.isEmpty ? IPSProfile.emptyReason() : nil
        )
        sections.append(medicationSection)

        // Allergies section
        let allergyEntries = allergyIDs.map { FHIRReference.urn($0) }
        let allergySection = FHIRCompositionSection(
            title: "Allergies and Intolerances",
            code: IPSProfile.sectionCode(loinc: IPSProfile.sectionAllergyLOINC,
                                         display: IPSProfile.sectionAllergyDisplay),
            text: FHIRNarrative.fromText(
                note.subjective.allergies?.joined(separator: "\n") ?? "NKDA"
            ),
            entry: allergyEntries.isEmpty ? nil : allergyEntries,
            emptyReason: allergyEntries.isEmpty ? IPSProfile.emptyReason(display: "NKDA") : nil
        )
        sections.append(allergySection)

        let compositionID = UUID().uuidString
        let composition = FHIRComposition(
            id: compositionID,
            meta: FHIRMeta(profile: [IPSProfile.compositionProfileURI]),
            status: compositionStatus,
            type: FHIRCodeableConcept(
                coding: [IPSProfile.compositionTypeCoding],
                text: "Patient Summary Document"
            ),
            subject: patientRef,
            date: note.generatedAt.fhirDateTime,
            author: [practRef],
            title: "MediScribe Clinical Note — \(note.generatedAt.fhirDate)",
            custodian: orgRef,
            section: sections,
            text: FHIRNarrative.fromText(
                "SOAP Note generated \(note.generatedAt.fhirDate). " +
                "Status: \(note.validationStatus.displayName). " +
                "AI-assisted documentation. Mandatory clinician review required before use."
            )
        )

        // Provenance for AI attribution
        let provenance = note.validationStatus != .blocked ?
            makeProvenance(
                targetID: compositionID,
                note: note,
                practitionerRef: practRef
            ) : nil

        return SOAPNoteResult(
            composition: composition,
            compositionID: compositionID,
            clinicalImpression: impression,
            clinicalImpressionID: impressionID,
            medicationStatements: medStatements,
            medicationStatementIDs: medIDs,
            allergyIntolerances: allergies,
            allergyIntoleranceIDs: allergyIDs,
            provenance: provenance
        )
    }

    // MARK: - Private Helpers

    private static func compositionStatus(for status: ValidationStatus) -> String {
        switch status {
        case .signed:     return "final"
        case .reviewed:   return "final"
        case .validated:  return "preliminary"
        default:          return "preliminary"
        }
    }

    private static func makeClinicalImpression(
        note: SOAPNoteData,
        patientRef: FHIRReference,
        assessorRef: FHIRReference
    ) -> (FHIRClinicalImpression, String) {
        let id = UUID().uuidString

        // Status: in-progress if not reviewed, completed if reviewed/signed
        let status: String
        switch note.validationStatus {
        case .reviewed, .signed: status = "completed"
        default: status = "in-progress"
        }

        // Build findings from problem list (differential/problem strings)
        var findings: [FHIRClinicalImpressionFinding] = []
        if let problems = note.assessment.problemList {
            for problem in problems {
                findings.append(FHIRClinicalImpressionFinding(
                    itemCodeableConcept: FHIRCodeableConcept.text(problem),
                    basis: "AI-assisted documentation — descriptive only, clinician review required"
                ))
            }
        }

        let impression = FHIRClinicalImpression(
            id: id,
            status: status,
            description: note.assessment.clinicalImpression,
            subject: patientRef,
            date: note.generatedAt.fhirDateTime,
            assessor: assessorRef,
            summary: note.assessment.differentialConsiderations?.joined(separator: "; "),
            finding: findings.isEmpty ? nil : findings,
            note: [FHIRAnnotation(
                text: "AI-generated clinical impression. Descriptive only. " +
                      "Does not constitute a diagnosis. Clinician review is mandatory.",
                author: "MediScribe",
                time: note.generatedAt.fhirDateTime
            )],
            text: FHIRNarrative.fromText(note.assessment.clinicalImpression)
        )
        return (impression, id)
    }

    private static func makeMedicationStatements(
        from medications: [String],
        patientRef: FHIRReference,
        informerRef: FHIRReference,
        dateAsserted: String
    ) -> ([FHIRMedicationStatement], [String]) {
        var statements: [FHIRMedicationStatement] = []
        var ids: [String] = []

        for med in medications where !med.trimmingCharacters(in: .whitespaces).isEmpty {
            let id = UUID().uuidString
            let stmt = FHIRMedicationStatement(
                id: id,
                status: "active",
                medicationCodeableConcept: FHIRCodeableConcept.text(med),
                subject: patientRef,
                dateAsserted: dateAsserted,
                informationSource: informerRef,
                note: [FHIRAnnotation(
                    text: "Documented from patient history. Source: provider (clinician-entered).",
                    time: dateAsserted
                )]
            )
            statements.append(stmt)
            ids.append(id)
        }
        return (statements, ids)
    }

    private static func makeAllergyIntolerances(
        from allergies: [String],
        patientRef: FHIRReference,
        recorderRef: FHIRReference,
        recordedDate: String
    ) -> ([FHIRAllergyIntolerance], [String]) {
        var resources: [FHIRAllergyIntolerance] = []
        var ids: [String] = []

        let activeStatus = FHIRCodeableConcept.coded(
            system: "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical",
            code: "active", display: "Active"
        )
        let confirmedStatus = FHIRCodeableConcept.coded(
            system: "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification",
            code: "confirmed", display: "Confirmed"
        )

        for allergy in allergies where !allergy.trimmingCharacters(in: .whitespaces).isEmpty {
            let id = UUID().uuidString
            let resource = FHIRAllergyIntolerance(
                id: id,
                clinicalStatus: activeStatus,
                verificationStatus: confirmedStatus,
                code: FHIRCodeableConcept.text(allergy),
                patient: patientRef,
                recordedDate: recordedDate,
                recorder: recorderRef
            )
            resources.append(resource)
            ids.append(id)
        }
        return (resources, ids)
    }

    private static func makeProvenance(
        targetID: String,
        note: SOAPNoteData,
        practitionerRef: FHIRReference
    ) -> FHIRProvenance {
        let agent = FHIRProvenanceAgent(
            type: FHIRCodeableConcept.coded(
                system: FHIRSystems.provenanceAgentType,
                code: "AIs",
                display: "AI System"
            ),
            who: FHIRReference(display: "MediScribe AI (\(note.metadata.modelVersion))")
        )
        let authorAgent = FHIRProvenanceAgent(
            type: FHIRCodeableConcept.coded(
                system: FHIRSystems.provenanceAgentType,
                code: "author",
                display: "Author"
            ),
            who: practitionerRef
        )
        let entity = FHIRProvenanceEntity(
            role: "source",
            what: FHIRReference(display: "MediScribe generated note: \(note.id)")
        )
        return FHIRProvenance(
            target: [FHIRReference.urn(targetID)],
            recorded: note.generatedAt.fhirDateTime,
            agent: [agent, authorAgent],
            entity: [entity],
            reason: [FHIRCodeableConcept.text("AI-assisted clinical documentation — MediScribe")],
            text: FHIRNarrative.fromText(
                "AI-generated by MediScribe model \(note.metadata.modelVersion) " +
                "on \(note.generatedAt.fhirDate). Clinician review gate: \(note.validationStatus.displayName)."
            )
        )
    }
}
