//
//  LabsProcessView.swift
//  MediScribe
//
//  View for processing captured lab documents
//

import SwiftUI
import UIKit
import CoreData

struct LabsProcessView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var modelManager = ImagingModelManager.shared
    @State private var isProcessing = false
    @State private var processingError: String?
    @State private var labResults: LabResultsSummary?
    @State private var showingValidationError = false
    @State private var validationError: LabValidationError?
    @State private var clinicianReviewed = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Captured image preview
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(8)
                        .padding()

                    if isProcessing {
                        ProgressView("Extracting lab results...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }

                    if let error = processingError {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text("Processing Error")
                                    .fontWeight(.semibold)
                            }
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    if let results = labResults {
                        labResultsView(results)
                    }
                }
            }
            .navigationTitle("Lab Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                if labResults != nil && clinicianReviewed {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            saveLabResults()
                        }
                    }
                }
            }
            .task {
                await processDocument()
            }
            .alert("Save Error", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveErrorMessage)
            }
        }
    }

    @ViewBuilder
    private func labResultsView(_ results: LabResultsSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Document info
            GroupBox("Document Information") {
                VStack(alignment: .leading, spacing: 8) {
                    detailRow("Type:", results.documentType)
                    if let date = results.documentDate {
                        detailRow("Date:", date)
                    }
                    if let lab = results.laboratoryName {
                        detailRow("Laboratory:", lab)
                    }
                }
            }
            .padding(.horizontal)

            // Test results
            ForEach(Array(results.testCategories.enumerated()), id: \.offset) { _, category in
                GroupBox(category.category) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(category.tests.enumerated()), id: \.offset) { _, test in
                            testResultRow(test)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Limitations statement
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Limitations")
                        .fontWeight(.semibold)
                }
                Text(results.limitations)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)

            // Clinician review toggle
            Toggle(isOn: $clinicianReviewed) {
                VStack(alignment: .leading) {
                    Text("I have reviewed these results")
                        .fontWeight(.semibold)
                    Text("Required before saving to patient record")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func testResultRow(_ test: LabTestResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(test.testName)
                .font(.subheadline)
                .fontWeight(.medium)
            HStack {
                Text(test.value)
                    .font(.title3)
                    .fontWeight(.bold)
                if let unit = test.unit {
                    Text(unit)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let range = test.referenceRange {
                    Text("Ref: \(range)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func processDocument() async {
        isProcessing = true
        processingError = nil

        do {
            // Convert image to data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                processingError = "Failed to process image"
                isProcessing = false
                return
            }

            // Get model (assuming MedGemmaModel is the current model)
            guard let medgemmaModel = modelManager.currentModel as? MedGemmaModel else {
                processingError = "Model not available"
                isProcessing = false
                return
            }

            // Process document as lab results
            let result = try await medgemmaModel.processDocument(
                imageData: imageData,
                documentType: .labResults,
                options: nil
            )

            // Validate output
            let validatedResults = try LabResultsValidator.decodeAndValidate(result.jsonOutput)

            labResults = validatedResults
            isProcessing = false

        } catch let error as LabValidationError {
            validationError = error
            processingError = "Safety validation failed: \(error.localizedDescription)"
            showingValidationError = true
            isProcessing = false
        } catch {
            processingError = "Processing failed: \(error.localizedDescription)"
            isProcessing = false
        }
    }

    private func saveLabResults() {
        guard let results = labResults else {
            return
        }

        do {
            // Encode lab results to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(results)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw NSError(domain: "LabsProcessView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON to string"])
            }

            // Create Finding entity
            let finding = Finding(context: viewContext)
            finding.id = UUID()
            finding.createdAt = Date()
            finding.documentType = "lab" // Mark as lab result
            finding.findingsJSON = jsonString
            finding.reviewedAt = Date()
            finding.reviewedBy = "Clinician" // TODO: Get actual clinician name from settings

            // Store original image
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                finding.imageData = imageData
                finding.imageType = "image/jpeg"
            }

            // Save context
            try viewContext.save()

            // Dismiss on success
            dismiss()

        } catch {
            saveErrorMessage = "Failed to save lab results: \(error.localizedDescription)"
            showingSaveError = true
        }
    }
}

#Preview {
    LabsProcessView(image: UIImage(systemName: "doc.text")!)
}
