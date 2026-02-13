//
//  ImagingGenerateView.swift
//  MediScribe
//
//  Imaging findings generation with safety validation
//

import SwiftUI
import Foundation
import PhotosUI
import CoreData

struct ImagingGenerateView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var modelManager = ImagingModelManager.shared

    @State private var status = "Select an image to generate a descriptive findings summary."
    @State private var findingsJSON = ""
    @State private var clinicianReviewed = false
    @State private var showError = false
    @State private var errorText = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showCamera = false
    @State private var showSaveSuccess = false
    @State private var isGenerating = false
    @State private var selectedModality: String = ImagingGenerateView.imagingModalities[0]
    @State private var customModality: String = ""

    static let imagingModalities = [
        "PA chest radiograph",
        "Lateral chest radiograph",
        "AP abdominal X-ray",
        "Abdominal CT axial",
        "Head CT axial",
        "Pelvic ultrasound",
        "Abdominal ultrasound",
        "Fetal / obstetric ultrasound",
        "Echocardiogram",
        "12-lead ECG",
        "Haemogram / CBC",
        "Laboratory report",
        "Wound / clinical photograph",
        "Other"
    ]

    var body: some View {
        Form {
            Section("Safety") {
                Text("This tool summarizes visible image features to support documentation and communication. It does not assess clinical significance or provide a diagnosis.")
                    .font(.footnote)
            }

            Section("Model Information") {
                HStack {
                    Text("Model:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(modelManager.modelInfo)
                        .font(.caption)
                }

                if modelManager.isLoading {
                    ProgressView("Loading model...", value: modelManager.loadingProgress)
                        .font(.caption)
                }
            }

            Section("Image Type") {
                Picker("Modality", selection: $selectedModality) {
                    ForEach(ImagingGenerateView.imagingModalities, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)
                if selectedModality == "Other" {
                    TextField("Describe image type", text: $customModality)
                        .textInputAutocapitalization(.words)
                }
            }

            Section("Image Selection") {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose from Photo Library", systemImage: "photo.on.rectangle")
                }

                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }

                if let imageData = selectedImageData {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Image selected (\(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file)))")
                            .font(.caption)
                    }
                }
            }

            Section("Actions") {
                Button {
                    Task {
                        await generateFindings()
                    }
                } label: {
                    if isGenerating {
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                            Text("Generating...")
                        }
                    } else {
                        Text("Generate findings summary")
                    }
                }
                .disabled(selectedImageData == nil || isGenerating || modelManager.isLoading)
            }

            Section("Findings (for clinician review)") {
                TextEditor(text: $findingsJSON)
                    .frame(minHeight: 220)

                Toggle("Findings reviewed by clinician", isOn: $clinicianReviewed)
            }

            Section("Status") {
                Text(status).font(.footnote)
            }

            Section {
                Button("Add to patient record") {
                    saveFinding()
                }
                .disabled(!clinicianReviewed || findingsJSON.isEmpty)

                Button("Include in referral summary") { }
                    .disabled(!clinicianReviewed || findingsJSON.isEmpty)
            }
        }
        .navigationTitle("Findings Draft")
        .alert("Blocked output", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorText)
        }
        .alert("Finding Saved", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Imaging finding has been saved to patient record.")
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                    status = "Image loaded. Ready to generate findings."
                    // Reset findings when new image is selected
                    findingsJSON = ""
                    clinicianReviewed = false
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(imageData: $selectedImageData, sourceType: .camera)
                .onDisappear {
                    if selectedImageData != nil {
                        status = "Image captured. Ready to generate findings."
                        // Reset findings when new image is captured
                        findingsJSON = ""
                        clinicianReviewed = false
                    }
                }
        }
    }

    private func generateFindings() async {
        guard let imageData = selectedImageData else { return }

        isGenerating = true
        status = "Reviewing visible features in the image…"

        do {
            // Get user's selected language from AppSettings
            let language = AppSettings.shared.generationLanguage

            // Build localized prompt for this language, injecting clinician-selected modality
            let localizedPrompts = LocalizedPrompts(language: language)
            let imageContext = selectedModality == "Other" ? (customModality.isEmpty ? "Medical imaging study" : customModality) : selectedModality
            let prompt = localizedPrompts.buildImagingPrompt(imageContext: imageContext)

            // Create inference options with language and localized prompt
            let options = InferenceOptions(
                timeout: 60.0,
                temperature: 0.35,
                maxTokens: ModelConfiguration.defaultImagingMaxTokens,
                systemPrompt: prompt,
                language: language
            )

            // Generate findings using model manager with language support
            let result = try await modelManager.generateFindings(from: imageData, options: options)

            // Validate the model output with language parameter
            _ = try FindingsValidator.decodeAndValidate(
                Data(result.findingsJSON.utf8),
                language: language
            )

            // If validation passes, update UI
            findingsJSON = result.findingsJSON
            status = "Draft generated in \(String(format: "%.1f", result.processingTime))s. Please review."
            isGenerating = false

        } catch let error as ImagingModelError {
            // Handle model-specific errors
            findingsJSON = ""
            status = "Unable to generate findings."
            errorText = error.localizedDescription
            showError = true
            isGenerating = false

        } catch let error as FindingsValidationError {
            // Handle validation errors (safety gate triggered)
            findingsJSON = ""
            status = "Unable to generate a compliant findings summary."
            #if DEBUG
            errorText = "Blocked output (debug): \(error)"
            #else
            errorText = "Unable to generate a compliant findings summary. Please document manually."
            #endif
            showError = true
            isGenerating = false

        } catch {
            // Handle unexpected errors
            findingsJSON = ""
            status = "An unexpected error occurred."
            #if DEBUG
            errorText = "Error: \(error.localizedDescription)"
            #else
            errorText = "Unable to generate findings. Please try again."
            #endif
            showError = true
            isGenerating = false
        }
    }

    private func saveFinding() {
        // Create or get default patient
        let patient = getOrCreateDefaultPatient()

        // Create finding
        let finding = Finding(context: viewContext)
        finding.id = UUID()
        finding.createdAt = Date()
        finding.documentType = "imaging" // Mark as imaging finding
        finding.reviewedAt = Date()
        finding.reviewedBy = "Clinician" // TODO: Get actual clinician name from app settings
        finding.imageType = "Imaging" // TODO: Extract from findings JSON
        finding.patient = patient

        do {
            // Store findings JSON with encryption
            try finding.setFindingsJSON(findingsJSON)

            // Store image data with encryption if available
            if let imageData = selectedImageData {
                try finding.setImage(imageData)
            }

            try viewContext.save()
            showSaveSuccess = true
            status = "Finding saved successfully."

            // Reset form
            findingsJSON = ""
            clinicianReviewed = false
            selectedImageData = nil
            selectedPhoto = nil
        } catch {
            errorText = "Failed to save finding: \(error.localizedDescription)"
            showError = true
        }
    }

    private func getOrCreateDefaultPatient() -> Patient {
        // Try to fetch existing default patient
        let request: NSFetchRequest<Patient> = Patient.fetchRequest()
        request.predicate = NSPredicate(format: "medicalRecordNumber == %@", "DEFAULT")
        request.fetchLimit = 1

        if let existingPatient = try? viewContext.fetch(request).first {
            return existingPatient
        }

        // Create default patient if none exists
        let newPatient = Patient(context: viewContext)
        newPatient.id = UUID()
        newPatient.createdAt = Date()
        newPatient.medicalRecordNumber = "DEFAULT"
        newPatient.notes = "Default patient for imaging findings"

        return newPatient
    }
}

// MARK: - Image Picker for Camera
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Convert to JPEG data for storage
                parent.imageData = image.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
