//
//  FHIRImagingMapper.swift
//  MediScribe
//
//  Maps ImagingFindingsSummary + Finding entity to FHIR DiagnosticReport + ImagingStudy.
//  SAFETY: DiagnosticReport.status always "preliminary" for AI-generated imaging findings.
//          Limitations statement mandatory in text.div.
//

import Foundation

struct FHIRImagingMapper {

    struct ImagingResult {
        let diagnosticReport: FHIRDiagnosticReport
        let diagnosticReportID: String
        let imagingStudy: FHIRImagingStudy
        let imagingStudyID: String
        let media: FHIRMedia?
        let mediaID: String?
        let provenance: FHIRProvenance
    }

    // MARK: - Public API

    static func map(
        _ summary: ImagingFindingsSummary,
        patientID: String,
        practitionerID: String,
        imageData: Data?,
        createdAt: Date
    ) -> ImagingResult {
        let patientRef  = FHIRReference.urn(patientID)
        let practRef    = FHIRReference.urn(practitionerID)
        let studyID     = UUID().uuidString
        let reportID    = UUID().uuidString

        // ImagingStudy resource
        let modality = EHDSProfile.modalityCoding(for: summary.imageType)
        let study = FHIRImagingStudy(
            id: studyID,
            meta: EHDSProfile.imagingStudyMeta(),
            status: "available",
            modality: [modality],
            subject: patientRef,
            started: createdAt.fhirDateTime,
            description: summary.imageType,
            note: [FHIRAnnotation(
                text: "Image quality: \(summary.imageQuality). " +
                      "Comparison with prior: \(summary.comparisonWithPrior).",
                time: createdAt.fhirDateTime
            )],
            text: FHIRNarrative.fromText("Imaging study — \(summary.imageType)")
        )

        // Media (image attachment) if imageData available
        var media: FHIRMedia? = nil
        var mediaID: String? = nil

        if let data = imageData {
            let mID = UUID().uuidString
            media = FHIRMedia(
                id: mID,
                status: "completed",
                type: FHIRCodeableConcept.coded(
                    system: "http://terminology.hl7.org/CodeSystem/media-type",
                    code: "image",
                    display: "Image"
                ),
                subject: patientRef,
                createdDateTime: createdAt.fhirDateTime,
                content: FHIRAttachment(
                    contentType: "image/jpeg",
                    data: data.base64EncodedString(),
                    title: summary.imageType,
                    creation: createdAt.fhirDateTime
                )
            )
            mediaID = mID
        }

        // Mandatory limitations narrative (safety)
        let narrativeDiv = buildNarrativeDiv(summary)

        let reportCode = FHIRCodeableConcept.coded(
            system: FHIRSystems.loinc,
            code: "18748-4",
            display: "Diagnostic imaging study"
        )

        let imagingStudyRefs: [FHIRReference] = [FHIRReference.urn(studyID)]

        let report = FHIRDiagnosticReport(
            id: reportID,
            meta: FHIRMeta(profile: [IPSProfile.diagnosticReportProfileURI]),
            status: "preliminary",          // SAFETY: AI-generated
            category: EUBaseProfile.imagingCategory,
            code: reportCode,
            subject: patientRef,
            effectiveDateTime: createdAt.fhirDateTime,
            performer: [practRef],
            result: nil,
            imagingStudy: imagingStudyRefs,
            conclusion: summary.areasHighlighted.isEmpty ? nil : summary.areasHighlighted,
            text: FHIRNarrative(status: "generated", div: narrativeDiv)
        )

        let provenance = makeProvenance(
            reportID: reportID,
            studyID: studyID,
            createdAt: createdAt,
            practRef: practRef,
            imageType: summary.imageType
        )

        return ImagingResult(
            diagnosticReport: report,
            diagnosticReportID: reportID,
            imagingStudy: study,
            imagingStudyID: studyID,
            media: media,
            mediaID: mediaID,
            provenance: provenance
        )
    }

    // MARK: - Private Helpers

    private static func buildNarrativeDiv(_ summary: ImagingFindingsSummary) -> String {
        var html = "<div xmlns=\"http://www.w3.org/1999/xhtml\">"
        html += "<p><strong>Image Type:</strong> \(summary.imageType)</p>"
        html += "<p><strong>Image Quality:</strong> \(summary.imageQuality)</p>"

        for (key, values) in summary.anatomicalObservations.structures.sorted(by: { $0.key < $1.key }) where !values.isEmpty {
            let label = key.replacingOccurrences(of: "_", with: " ").capitalized
            html += "<p><strong>\(label):</strong> \(values.joined(separator: "; "))</p>"
        }
        if !summary.comparisonWithPrior.isEmpty {
            html += "<p><strong>Comparison with Prior:</strong> \(summary.comparisonWithPrior)</p>"
        }
        if !summary.areasHighlighted.isEmpty {
            html += "<p><strong>Areas Highlighted:</strong> \(summary.areasHighlighted)</p>"
        }
        html += "<p><em>LIMITATIONS: \(summary.limitations)</em></p>"
        html += "</div>"
        return html
    }

    private static func makeProvenance(
        reportID: String,
        studyID: String,
        createdAt: Date,
        practRef: FHIRReference,
        imageType: String
    ) -> FHIRProvenance {
        let aiAgent = FHIRProvenanceAgent(
            type: FHIRCodeableConcept.coded(
                system: FHIRSystems.provenanceAgentType,
                code: "AIs",
                display: "AI System"
            ),
            who: FHIRReference(display: "MediScribe Imaging Analysis (MedGemma)")
        )
        let authorAgent = FHIRProvenanceAgent(
            type: FHIRCodeableConcept.coded(
                system: FHIRSystems.provenanceAgentType,
                code: "author",
                display: "Author"
            ),
            who: practRef
        )
        return FHIRProvenance(
            target: [FHIRReference.urn(reportID), FHIRReference.urn(studyID)],
            recorded: createdAt.fhirDateTime,
            agent: [aiAgent, authorAgent],
            reason: [FHIRCodeableConcept.text("AI-generated imaging findings — MediScribe")],
            text: FHIRNarrative.fromText(
                "Imaging findings generated by MediScribe AI on \(createdAt.fhirDate). " +
                "Image type: \(imageType). Status: preliminary. " +
                "Mandatory clinician review required."
            )
        )
    }
}
