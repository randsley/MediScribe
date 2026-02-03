//
//  LabsProcessView.swift
//  MediScribe
//
//  View for processing captured lab documents
//

import SwiftUI
import UIKit
import CoreData

// Note: MLXModelLoader and MLXModelBridge are imported via module bridging
// Lab prompts are generated via LocalizedPrompts in Domain/Prompts/

struct LabsProcessView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

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

            // Get user's selected language from AppSettings
            let language = AppSettings.shared.generationLanguage

            // Generate findings using MLX model via MLXModelBridge
            let labJSON = try await extractLabResultsFromImage(imageData, language: language)

            // Validate output through safety validator with language parameter
            let validatedResults = try LabResultsValidator.decodeAndValidate(labJSON, language: language)

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

    private func extractLabResultsFromImage(_ imageData: Data, language: Language) async throws -> String {
        // Build localized prompt for this language
        let localizedPrompts = LocalizedPrompts(language: language)
        let prompt = localizedPrompts.buildLabPrompt()

        // Run inference using MLX model bridge with vision support
        // This generates a JSON response describing visible lab values
        let response = try await MLXModelBridge.generateWithImage(
            imageData: imageData,
            prompt: prompt,
            maxTokens: 1024,
            temperature: 0.2,
            language: language
        )

        return response
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
            finding.reviewedAt = Date()
            finding.reviewedBy = "Clinician" // TODO: Get actual clinician name from settings

            // Store findings JSON with encryption
            try finding.setFindingsJSON(jsonString)

            // Store original image with encryption
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                try finding.setImage(imageData)
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
