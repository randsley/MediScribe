//
//  LabsHistoryView.swift
//  MediScribe
//
//  View for browsing historical lab results
//

import SwiftUI
import CoreData
import UIKit

struct LabsHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: Finding.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Finding.createdAt, ascending: false)],
        predicate: NSPredicate(format: "documentType == %@", "lab"),
        animation: .default)
    private var labFindings: FetchedResults<Finding>

    var body: some View {
        List {
            if labFindings.isEmpty {
                Text("No saved lab results yet.")
                    .foregroundColor(.secondary)
                    .font(.footnote)
            } else {
                ForEach(labFindings) { finding in
                    NavigationLink(destination: LabResultDetailView(finding: finding)) {
                        LabResultRowView(finding: finding)
                    }
                }
                .onDelete(perform: deleteFindings)
            }
        }
        .navigationTitle("Lab History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }

    private func deleteFindings(offsets: IndexSet) {
        withAnimation {
            offsets.map { labFindings[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                print("Failed to delete: \(error)")
            }
        }
    }
}

// MARK: - Lab Result Row View
struct LabResultRowView: View {
    let finding: Finding

    private var labResults: LabResultsSummary? {
        guard let json = try? finding.getFindingsJSONWithMigration() else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(LabResultsSummary.self, from: json.data(using: .utf8) ?? Data())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(labResults?.laboratoryName ?? "Lab Results")
                    .font(.headline)
                Spacer()
                if let date = labResults?.documentDate {
                    Text(date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Created: \(finding.createdAt ?? Date(), style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let testCount = labResults?.testCategories.count {
                Text("\(testCount) test categor\(testCount == 1 ? "y" : "ies")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

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

// MARK: - Lab Result Detail View
struct LabResultDetailView: View {
    let finding: Finding

    /// Decrypted lab results (with migration support for legacy data)
    private var labResults: LabResultsSummary? {
        guard let json = try? finding.getFindingsJSONWithMigration() else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(LabResultsSummary.self, from: json.data(using: .utf8) ?? Data())
    }

    /// Decrypted image data (with migration support for legacy data)
    private var decryptedImageData: Data? {
        try? finding.getImageWithMigration()
    }

    @State private var showingFHIRExport = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Metadata section
                Group {
                    Text("Lab Results Details")
                        .font(.title2)
                        .bold()

                    if let results = labResults {
                        VStack(alignment: .leading, spacing: 8) {
                            if let laboratoryName = results.laboratoryName {
                                labDetailRow("Laboratory", laboratoryName)
                            }
                            if let docDate = results.documentDate {
                                labDetailRow("Document Date", docDate)
                            }
                            labDetailRow("Created", finding.createdAt?.formatted(date: .long, time: .shortened) ?? "N/A")

                            if let reviewedBy = finding.reviewedBy {
                                labDetailRow("Reviewed By", reviewedBy)
                            }

                            if let reviewedAt = finding.reviewedAt {
                                labDetailRow("Reviewed At", reviewedAt.formatted(date: .long, time: .shortened))
                            }
                        }
                    }
                }

                Divider()

                // Test results grouped by category
                if let results = labResults {
                    Text("Test Results")
                        .font(.title3)
                        .bold()

                    ForEach(Array(results.testCategories.enumerated()), id: \.offset) { _, category in
                        GroupBox(label: Text(category.category).font(.subheadline).bold()) {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(Array(category.tests.enumerated()), id: \.offset) { _, test in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(test.testName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        HStack {
                                            Text(test.value)
                                                .font(.body)
                                                .fontWeight(.bold)
                                            if let unit = test.unit {
                                                Text(unit)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            if let refRange = test.referenceRange {
                                                Text("Ref: \(refRange)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }

                    Divider()

                    // Limitations statement
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Important Limitations")
                                .fontWeight(.semibold)
                        }
                        Text(results.limitations)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // Image if available
                if let imageData = decryptedImageData, let uiImage = UIImage(data: imageData) {
                    Divider()

                    Text("Captured Lab Report")
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
        .navigationTitle("Lab Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if finding.reviewedAt != nil, labResults != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFHIRExport = true
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.doc.on.clipboard")
                    }
                }
            }
        }
        .sheet(isPresented: $showingFHIRExport) {
            if let summary = labResults {
                FHIRExportView(source: .labFinding(finding, summary))
            }
        }
    }

    private func labDetailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
        }
    }
}

#Preview {
    NavigationStack {
        LabsHistoryView()
    }
}
