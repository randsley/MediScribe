//
//  SOAPNoteGeneratorView.swift
//  MediScribe
//
//  Main container view for SOAP note generation workflow
//

import SwiftUI

/// Main view for SOAP note generation workflow
struct SOAPNoteGeneratorView: View {
    @StateObject private var viewModel = SOAPNoteViewModel()
    @State private var showInput: Bool = true

    var body: some View {
        ZStack {
            switch viewModel.generationState {
            case .idle:
                SOAPNoteInputView(viewModel: viewModel)

            case .generating:
                SOAPNoteGeneratingView(viewModel: viewModel)

            case .complete, .signed:
                SOAPNoteReviewView(viewModel: viewModel)

            case .validationFailed(let validationError):
                VStack(spacing: 16) {
                    Image(systemName: "shield.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)

                    Text("Safety Validation Failed")
                        .font(.headline)

                    Text(validationError.displayMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button(action: { viewModel.resetForm() }) {
                        Text("Start Over")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()

            case .error(let error):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)

                    Text("Generation Failed")
                        .font(.headline)

                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button(action: { viewModel.resetForm() }) {
                        Text("Try Again")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
    }
}

/// View showing generation progress
struct SOAPNoteGeneratingView: View {
    @ObservedObject var viewModel: SOAPNoteViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                // Progress indicator
                if viewModel.streamingState.isValidating {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.blue)

                        Text("Validating for Safety")
                            .font(.headline)

                        Text("Checking output against safety requirements...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: 12) {
                        VStack {
                            ProgressView(value: Double(viewModel.generationProgress))
                                .tint(.blue)

                            HStack {
                                Text("Generating...")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(viewModel.generationProgress * 100))%")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                        Text("Generating SOAP Note")
                            .font(.headline)

                        Text("Streaming tokens from MedGemma...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }

            // Streaming output display
            if !viewModel.streamingTokens.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Live Output")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Spacer()

                        if viewModel.streamingState.isGenerating {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: viewModel.streamingState)

                                Text("Streaming")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(viewModel.streamingTokens)
                                    .font(.caption)
                                    .lineLimit(.max)
                                    .textSelection(.enabled)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id("bottom")
                            }
                            .background(Color(.systemGray6))
                            .onChange(of: viewModel.streamingTokens) { _, _ in
                                withAnimation {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                        .cornerRadius(8)
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            }

            Spacer()

            // Status and safety notice
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text(viewModel.streamingState.isValidating ? "Validating Output" : "Generation in Progress")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Text("All generated content is validated against safety requirements. Do not close the app while generation is in progress.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBlue).opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}

/// View for listing previous SOAP notes
struct SOAPNoteListView: View {
    @StateObject private var viewModel = SOAPNoteViewModel()
    @State private var notes: [SOAPNoteData] = []
    @State private var selectedStatus: ValidationStatus?
    @State private var showNewNoteSheet: Bool = false

    var body: some View {
        Group {
            if notes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)

                        Text("No SOAP Notes Yet")
                            .font(.headline)

                        Text("Create your first SOAP note to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button(action: { showNewNoteSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("New SOAP Note")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(notes, id: \.id) { note in
                            NavigationLink(destination: SOAPNoteDetailView(noteID: note.id, viewModel: viewModel)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(note.subjective.chiefComplaint)
                                            .font(.headline)
                                            .lineLimit(1)

                                        Spacer()

                                        StatusBadge(status: note.validationStatus)
                                    }

                                    HStack {
                                        Text("Generated: \(note.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        if let reviewedBy = note.metadata.clinicianReviewedBy {
                                            Text("• Reviewed by \(reviewedBy)")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteNotes)
                    }
                }
            }
            .navigationTitle("SOAP Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewNoteSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewNoteSheet) {
                SOAPNoteGeneratorView()
            }
    }

    private func deleteNotes(at offsets: IndexSet) {
        // Note deletion would be implemented here
        notes.remove(atOffsets: offsets)
    }
}

/// Status badge component
struct StatusBadge: View {
    let status: ValidationStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }

    private var statusColor: Color {
        switch status {
        case .unvalidated:
            return .orange
        case .validated:
            return .blue
        case .blocked:
            return .red
        case .reviewed:
            return .green
        case .signed:
            return .green
        }
    }
}

/// Detail view for a specific note
struct SOAPNoteDetailView: View {
    let noteID: UUID
    @ObservedObject var viewModel: SOAPNoteViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            if let note = viewModel.currentNote {
                VStack(alignment: .leading, spacing: 16) {
                    // Chief complaint header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(note.subjective.chiefComplaint)
                            .font(.headline)

                        HStack {
                            Text("Generated: \(note.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            StatusBadge(status: note.validationStatus)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    // Full note content
                    Text(viewModel.exportAsText())
                        .font(.body)
                        .lineSpacing(2)
                        .padding()
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(8)

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("SOAP Note Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

struct SOAPNoteGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        SOAPNoteGeneratorView()
    }
}
