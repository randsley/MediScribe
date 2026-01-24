//
//  ReferralCreationView.swift
//  MediScribe
//
//  View for creating new referrals
//

import SwiftUI
import CoreData

struct ReferralCreationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool

    @State private var destination = ""
    @State private var reason = ""
    @State private var clinicalSummary = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Finding.createdAt, ascending: false)],
        animation: .default)
    private var availableFindings: FetchedResults<Finding>

    @State private var selectedFindings: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Referral Information") {
                    TextField("Destination (facility/clinician)", text: $destination)
                    TextField("Reason for Referral", text: $reason)
                }

                Section("Clinical Summary") {
                    TextEditor(text: $clinicalSummary)
                        .frame(minHeight: 150)
                        .font(.body)
                }

                if !availableFindings.isEmpty {
                    Section("Attach Findings (Optional)") {
                        ForEach(availableFindings) { finding in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(finding.imageType ?? "Finding")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Created: \(finding.createdAt ?? Date(), style: .date)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedFindings.contains(finding.id ?? UUID()) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let id = finding.id {
                                    if selectedFindings.contains(id) {
                                        selectedFindings.remove(id)
                                    } else {
                                        selectedFindings.insert(id)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Safety Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Important")
                                .fontWeight(.semibold)
                        }
                        Text("This referral will be saved as a draft until you explicitly mark it as sent. All content is encrypted and stored locally.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Referral")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Create") {
                        saveReferral()
                    }
                    .disabled(destination.trimmingCharacters(in: .whitespaces).isEmpty || reason.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveReferral() {
        guard !destination.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a destination"
            showingError = true
            return
        }

        guard !reason.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a reason for referral"
            showingError = true
            return
        }

        do {
            let referral = Referral(context: viewContext)
            referral.id = UUID()
            referral.createdAt = Date()
            referral.destination = destination
            referral.status = "draft"

            // Encrypt sensitive fields
            try referral.setReason(reason)
            try referral.setClinicalSummary(clinicalSummary)

            // Attach selected findings
            for findingID in selectedFindings {
                if let finding = availableFindings.first(where: { $0.id == findingID }) {
                    referral.addToAttachedFindings(finding)
                }
            }

            try viewContext.save()
            isPresented = false
        } catch {
            errorMessage = "Failed to create referral: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    ReferralCreationView(isPresented: $isPresented)
}
