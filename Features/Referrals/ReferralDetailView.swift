//
//  ReferralDetailView.swift
//  MediScribe
//
//  View for viewing and managing referral details
//

import SwiftUI
import CoreData

struct ReferralDetailView: View {
    let referral: Referral
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isEditing = false
    @State private var editReason = ""
    @State private var editSummary = ""
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""

    private var decryptedReason: String {
        (try? referral.getReasonWithMigration()) ?? ""
    }

    private var decryptedSummary: String {
        (try? referral.getClinicalSummaryWithMigration()) ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with status
                Group {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Referral")
                                .font(.title2)
                                .bold()
                            Text(referral.destination ?? "Unknown")
                                .font(.headline)
                        }
                        Spacer()
                        statusBadge
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        detailRow("Created", referral.createdAt?.formatted(date: .long, time: .shortened) ?? "N/A")
                        if let sentAt = referral.sentAt {
                            detailRow("Sent", sentAt.formatted(date: .long, time: .shortened))
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                Divider()

                // Reason section
                Group {
                    Text("Reason for Referral")
                        .font(.title3)
                        .bold()

                    if isEditing {
                        TextEditor(text: $editReason)
                            .frame(minHeight: 80)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Text(decryptedReason)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                // Clinical summary section
                Group {
                    Text("Clinical Summary")
                        .font(.title3)
                        .bold()

                    if isEditing {
                        TextEditor(text: $editSummary)
                            .frame(minHeight: 120)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        if decryptedSummary.isEmpty {
                            Text("No clinical summary added")
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            Text(decryptedSummary)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }

                // Attached findings
                if let findings = referral.attachedFindings as? Set<Finding>, !findings.isEmpty {
                    Divider()

                    Group {
                        Text("Attached Findings")
                            .font(.title3)
                            .bold()

                        ForEach(Array(findings).sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }, id: \.id) { finding in
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
                                Image(systemName: "paperclip")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }

                // Safety information
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Important")
                            .fontWeight(.semibold)
                    }
                    Text("All referral data is encrypted and stored locally on this device. Review all information carefully before marking as sent.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Referral Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    HStack {
                        Button("Cancel") {
                            isEditing = false
                        }
                        Button("Save") {
                            saveChanges()
                        }
                        .disabled(editReason.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } else {
                    HStack {
                        if referral.status != "sent" {
                            Button(action: { isEditing = true; loadEditingState() }) {
                                Image(systemName: "pencil")
                            }
                            Button(action: markAsSent) {
                                Text("Mark Sent")
                            }
                        }
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.caption)
            Text(statusLabel)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(4)
    }

    private var statusLabel: String {
        switch referral.status {
        case "sent":
            return "Sent"
        case "received":
            return "Received"
        default:
            return "Draft"
        }
    }

    private var statusColor: Color {
        switch referral.status {
        case "sent":
            return .green
        case "received":
            return .blue
        default:
            return .orange
        }
    }

    private var statusIcon: String {
        switch referral.status {
        case "sent":
            return "checkmark.circle.fill"
        case "received":
            return "checkmark.square.stack.fill"
        default:
            return "circle"
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .font(.caption)
        }
    }

    private func loadEditingState() {
        editReason = decryptedReason
        editSummary = decryptedSummary
    }

    private func saveChanges() {
        do {
            try referral.setReason(editReason)
            try referral.setClinicalSummary(editSummary)
            try viewContext.save()
            isEditing = false
        } catch {
            saveErrorMessage = "Failed to save changes: \(error.localizedDescription)"
            showingSaveError = true
        }
    }

    private func markAsSent() {
        referral.status = "sent"
        referral.sentAt = Date()

        do {
            try viewContext.save()
        } catch {
            saveErrorMessage = "Failed to mark referral as sent: \(error.localizedDescription)"
            showingSaveError = true
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let referral = Referral(context: context)
    referral.id = UUID()
    referral.createdAt = Date()
    referral.destination = "Central Hospital"
    referral.status = "draft"
    try? referral.setReason("Patient needs specialist evaluation")
    try? referral.setClinicalSummary("45-year-old patient with persistent symptoms")

    return NavigationStack {
        ReferralDetailView(referral: referral)
    }
}
