//
//  FHIRLabMapper.swift
//  MediScribe
//
//  Maps LabResultsSummary to FHIR DiagnosticReport (EU Lab IG) + Observations.
//  SAFETY: DiagnosticReport.status always "preliminary" for AI-extracted labs.
//          Limitations statement mandatory in text.div.
//

import Foundation

struct FHIRLabMapper {

    struct LabResult {
        let diagnosticReport: FHIRDiagnosticReport
        let diagnosticReportID: String
        let observations: [FHIRObservation]
        let observationIDs: [String]
        let provenance: FHIRProvenance
    }

    // MARK: - Public API

    static func map(
        _ summary: LabResultsSummary,
        patientID: String,
        practitionerID: String,
        createdAt: Date
    ) -> LabResult {
        let patientRef = FHIRReference.urn(patientID)
        let practRef   = FHIRReference.urn(practitionerID)
        let reportID   = UUID().uuidString

        // Map each test category → Observations
        var observations: [FHIRObservation] = []
        var observationIDs: [String] = []

        for category in summary.testCategories {
            for test in category.tests {
                let (obs, obsID) = makeObservation(
                    test: test,
                    category: category.category,
                    patientRef: patientRef,
                    performerRef: practRef,
                    effectiveDate: summary.documentDate ?? createdAt.fhirDate
                )
                observations.append(obs)
                observationIDs.append(obsID)
            }
        }

        let resultRefs = observationIDs.map { FHIRReference.urn($0) }

        // Mandatory limitations narrative (safety)
        let limitationsText = summary.limitations
        let narrativeDiv = buildNarrativeDiv(summary: summary, limitations: limitationsText)

        let reportCode = FHIRCodeableConcept.coded(
            system: FHIRSystems.loinc,
            code: "11502-2",
            display: "Laboratory report"
        )

        let report = FHIRDiagnosticReport(
            id: reportID,
            meta: EUBaseProfile.labDiagnosticReportMeta(),
            status: "preliminary",      // SAFETY: AI-extracted, not clinician verified
            category: EUBaseProfile.labCategory,
            code: reportCode,
            subject: patientRef,
            effectiveDateTime: summary.documentDate ?? createdAt.fhirDate,
            performer: [practRef],
            result: resultRefs.isEmpty ? nil : resultRefs,
            conclusion: nil,
            text: FHIRNarrative(status: "generated", div: narrativeDiv)
        )

        // Provenance for AI attribution
        let provenance = makeProvenance(
            reportID: reportID,
            createdAt: createdAt,
            practRef: practRef,
            summary: summary
        )

        return LabResult(
            diagnosticReport: report,
            diagnosticReportID: reportID,
            observations: observations,
            observationIDs: observationIDs,
            provenance: provenance
        )
    }

    // MARK: - Private Helpers

    private static func makeObservation(
        test: LabTestResult,
        category: String,
        patientRef: FHIRReference,
        performerRef: FHIRReference,
        effectiveDate: String
    ) -> (FHIRObservation, String) {
        let id = UUID().uuidString

        // Lab category coding
        let categoryCoding = FHIRCodeableConcept.coded(
            system: FHIRSystems.observationCategory,
            code: "laboratory",
            display: "Laboratory"
        )

        // Reference range from free text
        let refRange: [FHIRObservationReferenceRange]? = test.referenceRange.map {
            [FHIRObservationReferenceRange(text: $0)]
        }

        // Build quantity if value + unit present
        var valueQuantity: FHIRQuantity? = nil
        var valueString: String? = nil

        if let unit = test.unit, !unit.isEmpty,
           let numericValue = Double(test.value.trimmingCharacters(in: .whitespaces)) {
            valueQuantity = FHIRQuantity(value: numericValue, unit: unit)
        } else {
            valueString = "\(test.value)\(test.unit.map { " \($0)" } ?? "")"
        }

        let obs = FHIRObservation(
            id: id,
            meta: EUBaseProfile.labObservationMeta(),
            status: "preliminary",     // SAFETY: AI-extracted
            category: [categoryCoding],
            // code.text only — no LOINC lookup available offline
            code: FHIRCodeableConcept(
                coding: nil,
                text: "\(category): \(test.testName)"
            ),
            subject: patientRef,
            effectiveDateTime: effectiveDate,
            valueQuantity: valueQuantity,
            valueString: valueString,
            referenceRange: refRange
        )
        return (obs, id)
    }

    private static func buildNarrativeDiv(
        summary: LabResultsSummary,
        limitations: String
    ) -> String {
        var html = "<div xmlns=\"http://www.w3.org/1999/xhtml\">"
        if let lab = summary.laboratoryName {
            html += "<p><strong>Laboratory:</strong> \(lab)</p>"
        }
        if let date = summary.documentDate {
            html += "<p><strong>Date:</strong> \(date)</p>"
        }
        for category in summary.testCategories {
            html += "<p><strong>\(category.category):</strong></p><ul>"
            for test in category.tests {
                let unitPart = test.unit.map { " \($0)" } ?? ""
                let rangePart = test.referenceRange.map { " [\($0)]" } ?? ""
                html += "<li>\(test.testName): \(test.value)\(unitPart)\(rangePart)</li>"
            }
            html += "</ul>"
        }
        html += "<p><em>LIMITATIONS: \(limitations)</em></p>"
        html += "</div>"
        return html
    }

    private static func makeProvenance(
        reportID: String,
        createdAt: Date,
        practRef: FHIRReference,
        summary: LabResultsSummary
    ) -> FHIRProvenance {
        let aiAgent = FHIRProvenanceAgent(
            type: FHIRCodeableConcept.coded(
                system: FHIRSystems.provenanceAgentType,
                code: "AIs",
                display: "AI System"
            ),
            who: FHIRReference(display: "MediScribe Lab Extraction (MedGemma)")
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
            target: [FHIRReference.urn(reportID)],
            recorded: createdAt.fhirDateTime,
            agent: [aiAgent, authorAgent],
            reason: [FHIRCodeableConcept.text("AI-extracted laboratory values — MediScribe")],
            text: FHIRNarrative.fromText(
                "Lab results extracted by MediScribe AI on \(createdAt.fhirDate). " +
                "Status: preliminary. Mandatory clinician review required."
            )
        )
    }
}
