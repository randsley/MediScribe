//
//  FHIRBundlePreviewView.swift
//  MediScribe
//
//  Preview of FHIR resources to be exported before confirmation.
//

import SwiftUI

struct FHIRBundlePreviewView: View {

    let resourceSummary: FHIRExportSummary

    var body: some View {
        List {
            Section("Export Summary") {
                LabeledContent("Bundle Type", value: resourceSummary.bundleType)
                LabeledContent("Total Resources", value: "\(resourceSummary.totalResourceCount)")
                LabeledContent("Profile", value: resourceSummary.profileLabel)
            }

            Section("Resources") {
                ForEach(resourceSummary.resourceCounts, id: \.resourceType) { item in
                    LabeledContent(item.resourceType, value: "\(item.count)")
                }
            }

            Section("Safety") {
                reviewStatusRow
                limitationsRow
            }
        }
        .navigationTitle("Export Preview")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var reviewStatusRow: some View {
        HStack {
            Image(systemName: resourceSummary.allReviewed ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .foregroundStyle(resourceSummary.allReviewed ? .green : .red)
            VStack(alignment: .leading) {
                Text("Clinician Review")
                    .font(.subheadline)
                Text(resourceSummary.allReviewed
                     ? "All content reviewed"
                     : "Some content not reviewed — will be excluded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var limitationsRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Limitations Statements", systemImage: "info.circle")
                .font(.subheadline)
            Text("All AI-generated resources include mandatory limitations statements in their narrative text.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - FHIRExportSummary

struct FHIRExportSummary {
    let bundleType: String
    let profileLabel: String
    let resourceCounts: [ResourceCount]
    let allReviewed: Bool

    struct ResourceCount {
        let resourceType: String
        let count: Int
    }

    var totalResourceCount: Int {
        resourceCounts.reduce(0) { $0 + $1.count }
    }

    static func ips(
        compositionCount: Int,
        patientCount: Int,
        practitionerCount: Int,
        organizationCount: Int,
        observationCount: Int,
        diagnosticReportCount: Int,
        imagingStudyCount: Int,
        medicationStatementCount: Int,
        allergyCount: Int,
        clinicalImpressionCount: Int,
        serviceRequestCount: Int,
        provenanceCount: Int,
        allReviewed: Bool
    ) -> FHIRExportSummary {
        var counts: [ResourceCount] = []
        let add = { (type: String, n: Int) in
            if n > 0 { counts.append(ResourceCount(resourceType: type, count: n)) }
        }
        add("Composition", compositionCount)
        add("Patient", patientCount)
        add("Practitioner", practitionerCount)
        add("Organization", organizationCount)
        add("Observation", observationCount)
        add("DiagnosticReport", diagnosticReportCount)
        add("ImagingStudy", imagingStudyCount)
        add("MedicationStatement", medicationStatementCount)
        add("AllergyIntolerance", allergyCount)
        add("ClinicalImpression", clinicalImpressionCount)
        add("ServiceRequest", serviceRequestCount)
        add("Provenance", provenanceCount)

        return FHIRExportSummary(
            bundleType: "Document (IPS)",
            profileLabel: "IPS + EU Base + EHDS",
            resourceCounts: counts,
            allReviewed: allReviewed
        )
    }
}

#Preview {
    NavigationStack {
        FHIRBundlePreviewView(
            resourceSummary: .ips(
                compositionCount: 1,
                patientCount: 1,
                practitionerCount: 1,
                organizationCount: 1,
                observationCount: 5,
                diagnosticReportCount: 2,
                imagingStudyCount: 1,
                medicationStatementCount: 3,
                allergyCount: 1,
                clinicalImpressionCount: 1,
                serviceRequestCount: 0,
                provenanceCount: 3,
                allReviewed: true
            )
        )
    }
}
