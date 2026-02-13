//
//  FHIRExportView.swift
//  MediScribe
//
//  Export options, confirmation UI, and share sheet for FHIR R4 export.
//  Used as a sheet from NoteDetailView, ImagingHistoryView, LabsHistoryView,
//  ReferralDetailView, and Settings.
//

import SwiftUI

// MARK: - Export Source

enum FHIRExportSource {
    case soapNote(SOAPNoteData)
    case labFinding(Finding, LabResultsSummary)
    case imagingFinding(Finding, ImagingFindingsSummary)
    case referral(Referral)
    case ipsBundle(patientIdentifier: String?)
}

// MARK: - FHIRExportView

struct FHIRExportView: View {

    let source: FHIRExportSource
    @ObservedObject var settings: AppSettings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    @State private var exportState: ExportState = .idle
    @State private var exportedData: Data? = nil
    @State private var showShareSheet: Bool = false
    @State private var exportError: String? = nil
    @State private var showPreview: Bool = false

    private let exportService = FHIRExportService()

    enum ExportState {
        case idle, exporting, ready, failed
    }

    var body: some View {
        NavigationStack {
            Form {
                exportInfoSection
                safetySection
                if exportState == .ready {
                    readySection
                }
                if let error = exportError {
                    errorSection(error)
                }
                exportButton
            }
            .navigationTitle("Export as FHIR R4")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if showPreview {
                    ToolbarItem(placement: .confirmationAction) {
                        NavigationLink("Preview") {
                            FHIRBundlePreviewView(resourceSummary: previewSummary())
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = exportedData {
                FHIRShareSheet(data: data, filename: exportFilename())
            }
        }
    }

    // MARK: - Sections

    private var exportInfoSection: some View {
        Section("Export Details") {
            LabeledContent("Format", value: "FHIR R4 JSON")
            LabeledContent("Content-Type", value: "application/fhir+json")
            LabeledContent("Profiles", value: exportProfileLabel)
            LabeledContent("Source", value: exportSourceLabel)
        }
    }

    private var safetySection: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.shield")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clinician Review Required")
                        .font(.subheadline.bold())
                    Text(
                        "Export is only permitted for clinician-reviewed content. " +
                        "AI-generated observations are exported as preliminary resources " +
                        "and do not constitute diagnoses."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Safety")
        }
    }

    private var readySection: some View {
        Section("Ready to Share") {
            Button {
                showShareSheet = true
            } label: {
                Label("Share FHIR Bundle", systemImage: "square.and.arrow.up")
            }
            .foregroundStyle(.blue)
        }
    }

    private func errorSection(_ error: String) -> some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export Blocked")
                        .font(.subheadline.bold())
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Error")
        }
    }

    private var exportButton: some View {
        Section {
            Button {
                Task { await performExport() }
            } label: {
                HStack {
                    if exportState == .exporting {
                        ProgressView()
                            .padding(.trailing, 4)
                    }
                    Text(exportState == .exporting ? "Generating…" : "Generate FHIR Bundle")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(exportState == .exporting || exportState == .ready)
            .buttonStyle(.borderedProminent)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Export Action

    @MainActor
    private func performExport() async {
        exportState = .exporting
        exportError = nil

        do {
            let data = try FHIRExportView.runExport(exportService: exportService, source: source)

            exportedData = data
            exportState = .ready
            showPreview = true
        } catch let err as FHIRExportError {
            exportError = err.errorDescription
            exportState = .failed
        } catch {
            exportError = error.localizedDescription
            exportState = .failed
        }
    }

    private func generateExportData() throws -> Data {
        try FHIRExportView.runExport(exportService: exportService, source: source)
    }

    private static func runExport(exportService: FHIRExportService, source: FHIRExportSource) throws -> Data {
        switch source {
        case .soapNote(let note):
            return try exportService.exportSOAPNote(note)
        case .labFinding(let finding, let summary):
            return try exportService.exportLabReport(finding, labSummary: summary)
        case .imagingFinding(let finding, let summary):
            return try exportService.exportImagingReport(finding, imagingSummary: summary)
        case .referral(let referral):
            return try exportService.exportReferral(referral)
        case .ipsBundle:
            // IPS bundle requires notes/findings — not supported via this simplified path
            // Caller should use FHIRExportService.exportIPSBundle directly
            throw FHIRExportError.invalidData("Use SettingsView to export full IPS patient bundle")
        }
    }

    // MARK: - Helpers

    private var exportProfileLabel: String {
        switch source {
        case .soapNote:       return "IPS + EU Base"
        case .labFinding:     return "EU Lab IG"
        case .imagingFinding: return "IPS Imaging + EHDS"
        case .referral:       return "FHIR R4 Base"
        case .ipsBundle:      return "IPS + EU Base + EHDS"
        }
    }

    private var exportSourceLabel: String {
        switch source {
        case .soapNote(let n):   return "SOAP Note — \(n.generatedAt.fhirDate)"
        case .labFinding:         return "Lab Report"
        case .imagingFinding:     return "Imaging Findings"
        case .referral(let r):    return "Referral to \(r.destination ?? "Unknown")"
        case .ipsBundle:          return "Full Patient Summary (IPS)"
        }
    }

    private func exportFilename() -> String {
        switch source {
        case .soapNote(let n):   return FHIRExportService.filename(for: "soap", id: n.id.uuidString)
        case .labFinding:         return FHIRExportService.filename(for: "lab")
        case .imagingFinding:     return FHIRExportService.filename(for: "imaging")
        case .referral(let r):    return FHIRExportService.filename(for: "referral", id: r.id?.uuidString)
        case .ipsBundle:          return FHIRExportService.filename(for: "ips")
        }
    }

    private func previewSummary() -> FHIRExportSummary {
        // Simplified preview — actual counts vary
        FHIRExportSummary.ips(
            compositionCount: 1,
            patientCount: 1,
            practitionerCount: 1,
            organizationCount: 1,
            observationCount: 0,
            diagnosticReportCount: 0,
            imagingStudyCount: 0,
            medicationStatementCount: 0,
            allergyCount: 0,
            clinicalImpressionCount: 0,
            serviceRequestCount: 0,
            provenanceCount: 1,
            allReviewed: true
        )
    }
}

// MARK: - FHIRShareSheet

struct FHIRShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        let controller = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    // Preview with a dummy SOAP note source
    let note = SOAPNoteData(
        id: UUID(),
        patientIdentifier: "DEMO-001",
        generatedAt: Date(),
        subjective: SOAPSubjective(
            chiefComplaint: "Fever",
            historyOfPresentIllness: "3 days of fever",
            pastMedicalHistory: nil,
            medications: ["Paracetamol 500mg"],
            allergies: ["Penicillin"]
        ),
        objective: SOAPObjective(
            vitalSigns: VitalSignsData(
                temperature: nil, heartRate: nil,
                respiratoryRate: nil, systolicBP: nil,
                diastolicBP: nil, oxygenSaturation: nil,
                recordedAt: nil
            ),
            physicalExamFindings: nil,
            diagnosticResults: nil
        ),
        assessment: SOAPAssessment(
            clinicalImpression: "Febrile illness",
            differentialConsiderations: nil,
            problemList: nil
        ),
        plan: SOAPPlan(
            interventions: nil, followUp: nil,
            patientEducation: nil, referrals: nil
        ),
        metadata: SOAPMetadata(
            modelVersion: "medgemma-1.5-4b",
            generationTime: 1.2,
            promptTemplate: "soap_v1",
            clinicianReviewedBy: "Dr. Test",
            reviewedAt: Date(),
            encryptionVersion: "AES256"
        ),
        validationStatus: .reviewed
    )
    FHIRExportView(source: .soapNote(note))
}
