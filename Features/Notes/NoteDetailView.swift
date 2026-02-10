//
//  NoteDetailView.swift
//  MediScribe
//
//  Displays note details with signing and addendum support
//

import SwiftUI
import CoreData

struct NoteDetailView: View {
    @ObservedObject var noteEntity: Note
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingSignConfirmation = false
    @State private var showingAddendumSheet = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var fieldNote: FieldNote?
    @State private var showingFHIRExport = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Patient Header
                if let note = fieldNote {
                    patientHeaderView(note)
                }

                // Signing Status
                signingStatusView

                // Note Content Summary
                if let note = fieldNote {
                    noteContentSummary(note)
                }

                // Addenda Section
                if noteEntity.isLocked {
                    addendaSection
                }

                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Note Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadNote()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingAddendumSheet) {
            AddendumEditorView(noteEntity: noteEntity)
        }
        .sheet(isPresented: $showingFHIRExport) {
            fhirExportSheet
        }
    }

    @ViewBuilder
    private var fhirExportSheet: some View {
        // FHIR export requires a SOAPNoteData; this view uses legacy Note entity.
        // Show a message directing to the SOAP note export flow.
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "arrow.triangle.2.circlepath.doc.on.clipboard")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                Text("FHIR Export")
                    .font(.title2.bold())
                Text("To export a FHIR R4 bundle, use the SOAP Note workflow to generate and review a structured note, then export from the SOAP note review screen.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingFHIRExport = false }
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func patientHeaderView(_ note: FieldNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Patient: \(note.meta.patient.id)")
                .font(.headline)
            Text("Created: \(note.meta.createdAt, style: .date) at \(note.meta.createdAt, style: .time)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    private var signingStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: noteEntity.isLocked ? "lock.fill" : "lock.open.fill")
                    .foregroundStyle(noteEntity.isLocked ? .green : .orange)
                Text(noteEntity.isLocked ? "Signed & Locked" : "Draft (Unsigned)")
                    .fontWeight(.semibold)
            }

            if noteEntity.isLocked {
                if let signedBy = noteEntity.signedBy {
                    Text("Signed by: \(signedBy)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let signedAt = noteEntity.signedAt {
                    Text("Signed at: \(signedAt, style: .date) \(signedAt, style: .time)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("This note is locked and cannot be edited. Use addenda for corrections.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("This note is a draft and can still be edited.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(noteEntity.isLocked ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func noteContentSummary(_ note: FieldNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note Summary")
                .font(.headline)

            if let cc = note.subjective?.chiefComplaint {
                detailRow("Chief Complaint", cc)
            }

            if let triage = note.triage {
                detailRow("Triage", "\(triage.system.rawValue.uppercased()) - \(triage.category.rawValue)")
            }

            if let stability = note.assessment?.stability {
                detailRow("Stability", stability.rawValue.capitalized)
            }

            if let disposition = note.plan?.disposition {
                detailRow("Disposition", disposition.type.rawValue.capitalized)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private var addendaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Addenda (\(noteEntity.sortedAddenda.count))")
                .font(.headline)

            if noteEntity.sortedAddenda.isEmpty {
                Text("No addenda have been added to this note.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                ForEach(noteEntity.sortedAddenda, id: \.id) { addendum in
                    addendumCard(addendum)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(8)
    }

    /// Decrypts addendum text with migration support for legacy data
    private func decryptedAddendumText(_ addendum: NoteAddendum) -> String {
        (try? addendum.getAddendumTextWithMigration()) ?? ""
    }

    @ViewBuilder
    private func addendumCard(_ addendum: NoteAddendum) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.append.fill")
                    .foregroundStyle(.purple)
                Text("Addendum")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                if let date = addendum.createdAt {
                    Text(date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(decryptedAddendumText(addendum))
                .font(.body)

            if let correction = addendum.correctionOf {
                Text("Correction of: \(correction)")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            Text("— \(addendum.authorName ?? "Unknown")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(6)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !noteEntity.isLocked {
                Button(action: {
                    showingSignConfirmation = true
                }) {
                    Label("Sign Note", systemImage: "signature")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .confirmationDialog("Sign Note", isPresented: $showingSignConfirmation) {
                    Button("Sign and Lock", role: .destructive) {
                        signNote()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Signing this note will lock it permanently. You will not be able to edit it after signing. Use addenda for corrections.")
                }
            } else {
                Button(action: {
                    showingAddendumSheet = true
                }) {
                    Label("Add Addendum", systemImage: "doc.append")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    showingFHIRExport = true
                }) {
                    Label("Export as FHIR R4", systemImage: "arrow.triangle.2.circlepath.doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }

    // MARK: - Actions

    private func loadNote() {
        do {
            fieldNote = try noteEntity.getFieldNoteWithMigration()
        } catch {
            errorMessage = "Failed to load note: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func signNote() {
        do {
            // TODO: Get actual clinician info from app settings
            try noteEntity.sign(by: "Dr. Clinician", clinicianID: "CLIN_001")
            try viewContext.save()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Addendum Editor

struct AddendumEditorView: View {
    @ObservedObject var noteEntity: Note
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var addendumText = ""
    @State private var correctionField = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Addendum Text") {
                    TextEditor(text: $addendumText)
                        .frame(minHeight: 150)
                }

                Section("Optional: Field Being Corrected") {
                    TextField("e.g., /objective/vitals/0/spo2", text: $correctionField)
                        .autocapitalization(.none)
                    Text("Enter the JSON path to the field being corrected, or leave blank for general addenda.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Addendum")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveAddendum()
                    }
                    .disabled(addendumText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveAddendum() {
        do {
            // TODO: Get actual clinician info from app settings
            _ = try noteEntity.addAddendum(
                text: addendumText,
                authorName: "Dr. Clinician",
                authorID: "CLIN_001",
                correctionOf: correctionField.isEmpty ? nil : correctionField,
                context: viewContext
            )
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
