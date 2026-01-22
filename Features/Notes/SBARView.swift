//
//  SBARView.swift
//  MediScribe
//
//  Displays auto-generated SBAR handoff summary from a FieldNote
//

import SwiftUI

struct SBARView: View {
    let note: FieldNote
    @State private var sbarText: String = ""
    @State private var showingShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("SBAR Handoff Summary")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Auto-generated from clinical note")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Patient: \(note.meta.patient.id)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

                // SBAR Content
                Text(sbarText)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)

                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        copyToClipboard()
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                // Usage Note
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Usage Note")
                            .fontWeight(.semibold)
                    }
                    Text("This SBAR summary is auto-generated for handoff communication. Review and modify as needed before use.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("SBAR Handoff")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            generateSBAR()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [sbarText])
        }
    }

    private func generateSBAR() {
        sbarText = SBARGenerator.generateText(from: note)
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = sbarText
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SBARView(note: FieldNote(
            meta: NoteMeta(
                author: NoteAuthor(id: "dr_001", displayName: "Dr. Smith", role: "Physician"),
                patient: NotePatient(id: "PAT-123", estimatedAgeYears: 45, sexAtBirth: .male),
                encounter: NoteEncounter(setting: .tent, locationText: "Disaster Zone A"),
                consent: NoteConsent(status: .impliedEmergency)
            )
        ))
    }
}
