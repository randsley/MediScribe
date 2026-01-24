import SwiftUI
import CoreData

struct ReferralsHomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingNewReferral = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Referral.createdAt, ascending: false)],
        animation: .default)
    private var referrals: FetchedResults<Referral>

    var body: some View {
        NavigationStack {
            List {
                if referrals.isEmpty {
                    Text("No referrals yet.")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                } else {
                    ForEach(referrals) { referral in
                        NavigationLink(destination: ReferralDetailView(referral: referral)) {
                            ReferralRowView(referral: referral)
                        }
                    }
                    .onDelete(perform: deleteReferrals)
                }
            }
            .navigationTitle("Referrals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        EditButton()
                        Button(action: { showingNewReferral = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewReferral) {
                ReferralCreationView(isPresented: $showingNewReferral)
            }
        }
    }

    private func deleteReferrals(offsets: IndexSet) {
        withAnimation {
            offsets.map { referrals[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                print("Failed to delete referral: \(error)")
            }
        }
    }
}

// MARK: - Referral Row View
struct ReferralRowView: View {
    let referral: Referral

    private var destination: String {
        referral.destination ?? "Unknown"
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(destination)
                        .font(.headline)

                    Text("Created: \(referral.createdAt ?? Date(), style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(statusColor)
                            .font(.caption2)
                        Text(statusLabel)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    if let sentAt = referral.sentAt {
                        Text("Sent: \(sentAt, style: .date)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
