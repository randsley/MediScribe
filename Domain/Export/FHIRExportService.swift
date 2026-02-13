//
//  FHIRExportService.swift
//  MediScribe
//
//  Orchestrates assembly and export of FHIR R4 bundles (IPS + individual documents).
//  Output: UTF-8 JSON, application/fhir+json.
//
//  SAFETY GATE: Export is blocked if reviewedAt is nil or validationStatus
//  is not .reviewed or .signed. Mirrors the existing save/share gate pattern.
//

import Foundation

// MARK: - Export Errors

enum FHIRExportError: LocalizedError {
    case notReviewed
    case invalidData(String)
    case encodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .notReviewed:
            return "Export blocked: clinician review is required before exporting."
        case .invalidData(let detail):
            return "Export blocked: invalid data — \(detail)"
        case .encodingFailed(let detail):
            return "Export failed: encoding error — \(detail)"
        }
    }
}

// MARK: - FHIRExportService

class FHIRExportService {

    private let settings: AppSettings
    private let jsonEncoder: JSONEncoder

    init(settings: AppSettings = AppSettings.shared) {
        self.settings = settings
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder = encoder
    }

    // MARK: - IPS Full Patient Bundle

    /// Export an IPS patient summary bundle for a patient from all reviewed data.
    /// - Parameters:
    ///   - notes: Reviewed/signed SOAP notes.
    ///   - labFindings: Reviewed lab Finding entities with decoded LabResultsSummary.
    ///   - imagingFindings: Reviewed imaging Finding entities with decoded ImagingFindingsSummary.
    ///   - referrals: Referral entities.
    ///   - patientIdentifier: De-identified patient ID string.
    ///   - patientIdentifierSystem: Optional national ID system URI.
    func exportIPSBundle(
        notes: [SOAPNoteData],
        labFindings: [(Finding, LabResultsSummary)],
        imagingFindings: [(Finding, ImagingFindingsSummary)],
        referrals: [Referral],
        patientIdentifier: String?,
        patientIdentifierSystem: String? = nil
    ) throws -> Data {
        // Safety gate: ensure at least some reviewed content exists
        let reviewedNotes = notes.filter { $0.validationStatus == .reviewed || $0.validationStatus == .signed }
        let reviewedLabs = labFindings.filter { $0.0.reviewedAt != nil }
        let reviewedImaging = imagingFindings.filter { $0.0.reviewedAt != nil }

        if reviewedNotes.isEmpty && reviewedLabs.isEmpty && reviewedImaging.isEmpty {
            throw FHIRExportError.notReviewed
        }

        let idSystem = patientIdentifierSystem ?? settings.facilityInfo.patientIdentifierSystemURI
                       ?? FHIRSystems.mediScribeLocal

        // Build Patient, Practitioner, Organization
        let (patient, patientID) = FHIRPatientMapper.patient(
            patientIdentifier: patientIdentifier,
            identifierSystem: idSystem
        )
        let (practitioner, practitionerID) = FHIRPatientMapper.practitioner(
            from: settings.clinicianInfo
        )
        let (organization, organizationID) = FHIRPatientMapper.organization(
            from: settings.facilityInfo
        )

        var entries: [FHIRBundleEntry] = []
        var allProvenances: [FHIRProvenance] = []

        // ── SOAP Notes ──
        var soapNoteEntryRefs: [FHIRReference] = []
        for note in reviewedNotes {
            let result = FHIRSOAPNoteMapper.map(
                note,
                patientID: patientID,
                practitionerID: practitionerID,
                organizationID: organizationID
            )
            entries.append(.urn(result.compositionID, resource: FHIRAnyResource(result.composition)))
            entries.append(.urn(result.clinicalImpressionID, resource: FHIRAnyResource(result.clinicalImpression)))
            soapNoteEntryRefs.append(FHIRReference.urn(result.compositionID))

            for (stmt, id) in zip(result.medicationStatements, result.medicationStatementIDs) {
                entries.append(.urn(id, resource: FHIRAnyResource(stmt)))
            }
            for (allergy, id) in zip(result.allergyIntolerances, result.allergyIntoleranceIDs) {
                entries.append(.urn(id, resource: FHIRAnyResource(allergy)))
            }
            if let prov = result.provenance {
                allProvenances.append(prov)
            }
        }

        // ── Lab Findings ──
        var labEntryRefs: [FHIRReference] = []
        for (finding, labSummary) in reviewedLabs {
            let result = FHIRLabMapper.map(
                labSummary,
                patientID: patientID,
                practitionerID: practitionerID,
                createdAt: finding.createdAt ?? Date()
            )
            entries.append(.urn(result.diagnosticReportID, resource: FHIRAnyResource(result.diagnosticReport)))
            labEntryRefs.append(FHIRReference.urn(result.diagnosticReportID))
            for (obs, id) in zip(result.observations, result.observationIDs) {
                entries.append(.urn(id, resource: FHIRAnyResource(obs)))
            }
            allProvenances.append(result.provenance)
        }

        // ── Imaging Findings ──
        var imagingEntryRefs: [FHIRReference] = []
        for (finding, imagingSummary) in reviewedImaging {
            let result = FHIRImagingMapper.map(
                imagingSummary,
                patientID: patientID,
                practitionerID: practitionerID,
                imageData: finding.imageData,
                createdAt: finding.createdAt ?? Date()
            )
            entries.append(.urn(result.diagnosticReportID, resource: FHIRAnyResource(result.diagnosticReport)))
            entries.append(.urn(result.imagingStudyID, resource: FHIRAnyResource(result.imagingStudy)))
            imagingEntryRefs.append(FHIRReference.urn(result.diagnosticReportID))
            if let media = result.media, let mediaID = result.mediaID {
                entries.append(.urn(mediaID, resource: FHIRAnyResource(media)))
            }
            allProvenances.append(result.provenance)
        }

        // ── Referrals ──
        var referralEntryRefs: [FHIRReference] = []
        for referral in referrals {
            let clinicalSummary = referral.isEncrypted ? nil : referral.clinicalSummary
            let reason = referral.isEncrypted ? nil : referral.reason
            let result = FHIRReferralMapper.map(
                referral: referral,
                patientID: patientID,
                practitionerID: practitionerID,
                clinicalSummary: clinicalSummary,
                reason: reason
            )
            entries.append(.urn(result.serviceRequestID, resource: FHIRAnyResource(result.serviceRequest)))
            referralEntryRefs.append(FHIRReference.urn(result.serviceRequestID))
        }

        // ── IPS Composition ──
        let compositionID = UUID().uuidString
        let composition = buildIPSComposition(
            id: compositionID,
            patientRef: FHIRReference.urn(patientID),
            practRef: FHIRReference.urn(practitionerID),
            orgRef: FHIRReference.urn(organizationID),
            labRefs: labEntryRefs,
            imagingRefs: imagingEntryRefs,
            noteRefs: soapNoteEntryRefs,
            referralRefs: referralEntryRefs
        )
        entries.insert(.urn(compositionID, resource: FHIRAnyResource(composition)), at: 0)

        // ── Add Patient / Practitioner / Organization ──
        entries.append(.urn(patientID, resource: FHIRAnyResource(patient)))
        entries.append(.urn(practitionerID, resource: FHIRAnyResource(practitioner)))
        entries.append(.urn(organizationID, resource: FHIRAnyResource(organization)))

        // ── Provenance ──
        for prov in allProvenances {
            entries.append(.urn(prov.id, resource: FHIRAnyResource(prov)))
        }

        let bundle = FHIRBundle(
            type: "document",
            meta: FHIRMeta(profile: [IPSProfile.bundleProfileURI]),
            identifier: FHIRIdentifier(
                system: FHIRSystems.mediScribeLocal,
                value: UUID().uuidString
            ),
            timestamp: Date().fhirDateTime,
            entry: entries
        )

        do {
            return try jsonEncoder.encode(bundle)
        } catch {
            throw FHIRExportError.encodingFailed(error.localizedDescription)
        }
    }

    // MARK: - Individual Document Exports

    func exportSOAPNote(_ note: SOAPNoteData) throws -> Data {
        try validateReviewed(status: note.validationStatus)

        let (patient, patientID) = FHIRPatientMapper.patient(
            patientIdentifier: note.patientIdentifier,
            identifierSystem: settings.facilityInfo.patientIdentifierSystemURI ?? FHIRSystems.mediScribeLocal
        )
        let (practitioner, practitionerID) = FHIRPatientMapper.practitioner(from: settings.clinicianInfo)
        let (organization, organizationID) = FHIRPatientMapper.organization(from: settings.facilityInfo)

        let result = FHIRSOAPNoteMapper.map(
            note,
            patientID: patientID,
            practitionerID: practitionerID,
            organizationID: organizationID
        )

        var entries: [FHIRBundleEntry] = [
            .urn(result.compositionID, resource: FHIRAnyResource(result.composition)),
            .urn(result.clinicalImpressionID, resource: FHIRAnyResource(result.clinicalImpression)),
            .urn(patientID, resource: FHIRAnyResource(patient)),
            .urn(practitionerID, resource: FHIRAnyResource(practitioner)),
            .urn(organizationID, resource: FHIRAnyResource(organization)),
        ]
        for (stmt, id) in zip(result.medicationStatements, result.medicationStatementIDs) {
            entries.append(.urn(id, resource: FHIRAnyResource(stmt)))
        }
        for (allergy, id) in zip(result.allergyIntolerances, result.allergyIntoleranceIDs) {
            entries.append(.urn(id, resource: FHIRAnyResource(allergy)))
        }
        if let prov = result.provenance {
            entries.append(.urn(prov.id, resource: FHIRAnyResource(prov)))
        }

        let bundle = FHIRBundle(type: "document", timestamp: Date().fhirDateTime, entry: entries)
        return try encodeBundle(bundle)
    }

    func exportLabReport(_ finding: Finding, labSummary: LabResultsSummary) throws -> Data {
        try validateFindingReviewed(finding)

        let (patient, patientID) = FHIRPatientMapper.patient(
            patientIdentifier: finding.patient?.identifier
        )
        let (practitioner, practitionerID) = FHIRPatientMapper.practitioner(from: settings.clinicianInfo)

        let result = FHIRLabMapper.map(
            labSummary,
            patientID: patientID,
            practitionerID: practitionerID,
            createdAt: finding.createdAt ?? Date()
        )

        var entries: [FHIRBundleEntry] = [
            .urn(result.diagnosticReportID, resource: FHIRAnyResource(result.diagnosticReport)),
            .urn(patientID, resource: FHIRAnyResource(patient)),
            .urn(practitionerID, resource: FHIRAnyResource(practitioner)),
            .urn(result.provenance.id, resource: FHIRAnyResource(result.provenance)),
        ]
        for (obs, id) in zip(result.observations, result.observationIDs) {
            entries.append(.urn(id, resource: FHIRAnyResource(obs)))
        }

        let bundle = FHIRBundle(type: "collection", timestamp: Date().fhirDateTime, entry: entries)
        return try encodeBundle(bundle)
    }

    func exportImagingReport(_ finding: Finding, imagingSummary: ImagingFindingsSummary) throws -> Data {
        try validateFindingReviewed(finding)

        let (patient, patientID) = FHIRPatientMapper.patient(
            patientIdentifier: finding.patient?.identifier
        )
        let (practitioner, practitionerID) = FHIRPatientMapper.practitioner(from: settings.clinicianInfo)

        let result = FHIRImagingMapper.map(
            imagingSummary,
            patientID: patientID,
            practitionerID: practitionerID,
            imageData: finding.imageData,
            createdAt: finding.createdAt ?? Date()
        )

        var entries: [FHIRBundleEntry] = [
            .urn(result.diagnosticReportID, resource: FHIRAnyResource(result.diagnosticReport)),
            .urn(result.imagingStudyID, resource: FHIRAnyResource(result.imagingStudy)),
            .urn(patientID, resource: FHIRAnyResource(patient)),
            .urn(practitionerID, resource: FHIRAnyResource(practitioner)),
            .urn(result.provenance.id, resource: FHIRAnyResource(result.provenance)),
        ]
        if let media = result.media, let mediaID = result.mediaID {
            entries.append(.urn(mediaID, resource: FHIRAnyResource(media)))
        }

        let bundle = FHIRBundle(type: "collection", timestamp: Date().fhirDateTime, entry: entries)
        return try encodeBundle(bundle)
    }

    func exportReferral(_ referral: Referral) throws -> Data {
        let (patient, patientID) = FHIRPatientMapper.patient(
            patientIdentifier: referral.patient?.identifier
        )
        let (practitioner, practitionerID) = FHIRPatientMapper.practitioner(from: settings.clinicianInfo)

        let clinicalSummary = referral.isEncrypted ? nil : referral.clinicalSummary
        let reason = referral.isEncrypted ? nil : referral.reason

        let result = FHIRReferralMapper.map(
            referral: referral,
            patientID: patientID,
            practitionerID: practitionerID,
            clinicalSummary: clinicalSummary,
            reason: reason
        )

        let entries: [FHIRBundleEntry] = [
            .urn(result.serviceRequestID, resource: FHIRAnyResource(result.serviceRequest)),
            .urn(patientID, resource: FHIRAnyResource(patient)),
            .urn(practitionerID, resource: FHIRAnyResource(practitioner)),
        ]

        let bundle = FHIRBundle(type: "collection", timestamp: Date().fhirDateTime, entry: entries)
        return try encodeBundle(bundle)
    }

    // MARK: - Validation Gates

    func validateReadiness(note: SOAPNoteData) throws {
        try validateReviewed(status: note.validationStatus)
    }

    func validateReadiness(finding: Finding) throws {
        try validateFindingReviewed(finding)
    }

    // MARK: - File Naming

    static func filename(for type: String, id: String? = nil) -> String {
        let dateStr = ISO8601DateFormatter.fhirDate.string(from: Date())
            .replacingOccurrences(of: "-", with: "")
        if let id = id {
            return "mediscribe-\(type)-\(id).json"
        }
        return "mediscribe-\(type)-\(dateStr).json"
    }

    // MARK: - Private Helpers

    private func validateReviewed(status: ValidationStatus) throws {
        guard status == .reviewed || status == .signed else {
            throw FHIRExportError.notReviewed
        }
    }

    private func validateFindingReviewed(_ finding: Finding) throws {
        guard finding.reviewedAt != nil else {
            throw FHIRExportError.notReviewed
        }
    }

    private func encodeBundle(_ bundle: FHIRBundle) throws -> Data {
        do {
            return try jsonEncoder.encode(bundle)
        } catch {
            throw FHIRExportError.encodingFailed(error.localizedDescription)
        }
    }

    private func buildIPSComposition(
        id: String,
        patientRef: FHIRReference,
        practRef: FHIRReference,
        orgRef: FHIRReference,
        labRefs: [FHIRReference],
        imagingRefs: [FHIRReference],
        noteRefs: [FHIRReference],
        referralRefs: [FHIRReference]
    ) -> FHIRComposition {
        var sections: [FHIRCompositionSection] = []

        // Results section (labs + imaging)
        let resultRefs = labRefs + imagingRefs
        sections.append(FHIRCompositionSection(
            title: "Results",
            code: IPSProfile.sectionCode(loinc: IPSProfile.sectionResultsLOINC,
                                         display: IPSProfile.sectionResultsDisplay),
            text: FHIRNarrative.fromText("Diagnostic results — see attached DiagnosticReport resources."),
            entry: resultRefs.isEmpty ? nil : resultRefs,
            emptyReason: resultRefs.isEmpty ? IPSProfile.emptyReason() : nil
        ))

        // Encounters section (clinical notes as encounters)
        sections.append(FHIRCompositionSection(
            title: "Clinical Documents",
            code: IPSProfile.sectionCode(loinc: IPSProfile.sectionEncountersLOINC,
                                         display: IPSProfile.sectionEncountersDisplay),
            text: FHIRNarrative.fromText("Clinical SOAP notes — see Composition resources."),
            entry: noteRefs.isEmpty ? nil : noteRefs,
            emptyReason: noteRefs.isEmpty ? IPSProfile.emptyReason() : nil
        ))

        return FHIRComposition(
            id: id,
            meta: FHIRMeta(profile: [IPSProfile.compositionProfileURI]),
            status: "final",
            type: FHIRCodeableConcept(
                coding: [IPSProfile.compositionTypeCoding],
                text: "International Patient Summary"
            ),
            subject: patientRef,
            date: Date().fhirDateTime,
            author: [practRef],
            title: "International Patient Summary — MediScribe \(Date().fhirDate)",
            custodian: orgRef,
            section: sections,
            text: FHIRNarrative.fromText(
                "International Patient Summary generated by MediScribe on \(Date().fhirDate). " +
                "All AI-generated content has been reviewed by a qualified clinician."
            )
        )
    }
}

// MARK: - Patient identifier helper

private extension Patient {
    var identifier: String? { nil }  // Patient CoreData entity has no plain identifier field
}
