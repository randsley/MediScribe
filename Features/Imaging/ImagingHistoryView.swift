//
//  ImagingHistoryView.swift
//  MediScribe
//
//  Displays saved imaging findings from patient records
//

import SwiftUI
import CoreData

struct ImagingHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Finding.createdAt, ascending: false)],
        animation: .default)
    private var findings: FetchedResults<Finding>

    var body: some View {
        List {
            if findings.isEmpty {
                Text("No saved findings yet.")
                    .foregroundColor(.secondary)
                    .font(.footnote)
            } else {
                ForEach(findings) { finding in
                    NavigationLink(destination: FindingDetailView(finding: finding)) {
                        FindingRowView(finding: finding)
                    }
                }
                .onDelete(perform: deleteFindings)
            }
        }
        .navigationTitle("Imaging History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }

    private func deleteFindings(offsets: IndexSet) {
        withAnimation {
            offsets.map { findings[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Handle error appropriately in production
                print("Failed to delete: \(error)")
            }
        }
    }
}

// MARK: - Finding Row View
struct FindingRowView: View {
    let finding: Finding

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(finding.imageType ?? "Imaging Finding")
                .font(.headline)

            Text("Created: \(finding.createdAt ?? Date(), style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let reviewedAt = finding.reviewedAt {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Reviewed \(reviewedAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Finding Detail View
struct FindingDetailView: View {
    let finding: Finding

    /// Decrypted findings JSON (with migration support for legacy data)
    private var decryptedFindingsJSON: String? {
        try? finding.getFindingsJSONWithMigration()
    }

    /// Decrypted image data (with migration support for legacy data)
    private var decryptedImageData: Data? {
        try? finding.getImageWithMigration()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Metadata section
                Group {
                    Text("Finding Details")
                        .font(.title2)
                        .bold()

                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(label: "Created", value: finding.createdAt?.formatted(date: .long, time: .shortened) ?? "N/A")
                        DetailRow(label: "Type", value: finding.imageType ?? "N/A")

                        if let reviewedBy = finding.reviewedBy {
                            DetailRow(label: "Reviewed By", value: reviewedBy)
                        }

                        if let reviewedAt = finding.reviewedAt {
                            DetailRow(label: "Reviewed At", value: reviewedAt.formatted(date: .long, time: .shortened))
                        }
                    }
                }

                Divider()

                // Findings JSON
                Group {
                    Text("Findings Summary")
                        .font(.title3)
                        .bold()

                    if let json = decryptedFindingsJSON {
                        Text(json)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Text("No findings data available")
                            .foregroundColor(.secondary)
                    }
                }

                // Image if available
                if let imageData = decryptedImageData, let uiImage = UIImage(data: imageData) {
                    Divider()

                    Text("Captured Image")
                        .font(.title3)
                        .bold()

                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Finding Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Detail Row Helper
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
        }
    }
}
