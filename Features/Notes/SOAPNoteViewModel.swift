//
//  SOAPNoteViewModel.swift
//  MediScribe
//
//  ViewModel for SOAP note generation and management
//

import Combine
import Foundation

/// ViewModel managing SOAP note generation workflow
@MainActor
class SOAPNoteViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var generationState: GenerationState = .idle
    @Published var currentNote: SOAPNoteData?
    @Published var validationErrors: [SOAPNoteValidationError] = []
    @Published var isReviewed: Bool = false
    @Published var streamingTokens: String = ""
    @Published var streamingState: StreamingState = .idle
    @Published var generationProgress: Float = 0.0

    // Input form state
    @Published var patientAge: String = ""
    @Published var patientSex: String = "M"
    @Published var chiefComplaint: String = ""

    @Published var temperature: String = ""
    @Published var heartRate: String = ""
    @Published var respiratoryRate: String = ""
    @Published var systolicBP: String = ""
    @Published var diastolicBP: String = ""
    @Published var oxygenSaturation: String = ""

    @Published var medicalHistory: [String] = []
    @Published var medications: [String] = []
    @Published var allergies: [String] = []

    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var validationFailureReason: String? = nil
    @Published var hasValidationErrors: Bool = false

    // MARK: - Properties

    private let soapGenerator: SOAPNoteGenerator
    private let parser: SOAPNoteParser
    private let repository: SOAPNoteRepository

    // MARK: - Initialization

    init(
        soapGenerator: SOAPNoteGenerator = SOAPNoteGenerator(),
        parser: SOAPNoteParser = SOAPNoteParser(),
        repository: SOAPNoteRepository = SOAPNoteRepository(
            managedObjectContext: PersistenceController.shared.container.viewContext,
            encryptionService: EncryptionService.shared
        )
    ) {
        self.soapGenerator = soapGenerator
        self.parser = parser
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Start SOAP note generation
    func generateSOAPNote() {
        guard validateInput() else { return }

        generationState = .generating
        streamingTokens = ""
        validationErrors = []

        Task {
            do {
                // Create patient context
                let vitalSigns = buildVitalSigns()
                let context = PatientContext(
                    age: Int(patientAge) ?? 0,
                    sex: patientSex,
                    chiefComplaint: chiefComplaint,
                    vitalSigns: vitalSigns,
                    medicalHistory: medicalHistory.isEmpty ? nil : medicalHistory,
                    currentMedications: medications.isEmpty ? nil : medications,
                    allergies: allergies.isEmpty ? nil : allergies
                )

                // Generate note
                let note = try await soapGenerator.generateSOAPNote(
                    from: context,
                    options: .soapGeneration
                )

                // Store in repository (validates before persisting)
                let noteID = try repository.save(note)

                // Update UI
                self.currentNote = note
                self.generationState = .complete
                self.isReviewed = false
                self.validationErrors = []
                self.hasValidationErrors = false
                self.validationFailureReason = nil
            } catch let error as SOAPNoteValidationError {
                handleValidationError(error)
            } catch {
                handleError(error)
            }
        }
    }

    /// Start SOAP note generation with streaming token display
    func generateSOAPNoteStreaming() {
        guard validateInput() else { return }

        streamingState = .generating
        generationProgress = 0.0
        streamingTokens = ""
        validationErrors = []

        Task {
            do {
                // Create patient context
                let vitalSigns = buildVitalSigns()
                let context = PatientContext(
                    age: Int(patientAge) ?? 0,
                    sex: patientSex,
                    chiefComplaint: chiefComplaint,
                    vitalSigns: vitalSigns,
                    medicalHistory: medicalHistory.isEmpty ? nil : medicalHistory,
                    currentMedications: medications.isEmpty ? nil : medications,
                    allergies: allergies.isEmpty ? nil : allergies
                )

                // Get streaming token updates
                let stream = soapGenerator.generateSOAPNoteTokenStream(from: context)
                var tokenCount = 0
                let maxExpectedTokens: Float = 1024.0

                for try await token in stream {
                    // Accumulate tokens
                    streamingTokens.append(token)
                    tokenCount += 1

                    // Update progress
                    generationProgress = min(0.95, Float(tokenCount) / maxExpectedTokens)
                }

                // Validate and parse complete output
                streamingState = .validating

                let soapNote = try soapGenerator.parseResponse(streamingTokens)

                // Store in repository (validates before persisting)
                _ = try repository.save(soapNote)

                // Update UI
                self.currentNote = soapNote
                self.streamingState = .complete
                self.generationState = .complete
                self.isReviewed = false
                self.validationErrors = []
                self.hasValidationErrors = false
                self.validationFailureReason = nil

            } catch let error as SOAPNoteValidationError {
                handleStreamingValidationError(error)
            } catch {
                handleStreamingError(error)
            }
        }
    }

    /// Mark note as reviewed
    func markAsReviewed(clinicianID: String) {
        guard let note = currentNote else { return }

        do {
            try repository.markReviewed(id: note.id, by: clinicianID)
            isReviewed = true
        } catch {
            handleError(error)
        }
    }

    /// Sign/finalize note
    func signNote(clinicianID: String) {
        guard let note = currentNote else { return }

        do {
            try repository.markSigned(id: note.id, by: clinicianID)
            generationState = .signed
        } catch {
            handleError(error)
        }
    }

    /// Export note as formatted text
    func exportAsText() -> String {
        guard let note = currentNote else { return "" }

        do {
            return try repository.getFormattedText(id: note.id)
        } catch {
            handleError(error)
            return ""
        }
    }

    /// Reset form for new note
    func resetForm() {
        patientAge = ""
        patientSex = "M"
        chiefComplaint = ""

        temperature = ""
        heartRate = ""
        respiratoryRate = ""
        systolicBP = ""
        diastolicBP = ""
        oxygenSaturation = ""

        medicalHistory = []
        medications = []
        allergies = []

        currentNote = nil
        validationErrors = []
        isReviewed = false
        streamingTokens = ""
        generationState = .idle
    }

    // MARK: - Private Methods

    private func validateInput() -> Bool {
        var errors: [String] = []

        if patientAge.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Patient age is required")
        }

        if chiefComplaint.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Chief complaint is required")
        }

        if errors.isEmpty {
            return true
        }

        errorMessage = errors.joined(separator: "\n")
        showError = true
        return false
    }

    private func buildVitalSigns() -> VitalSigns {
        let temp = temperature.isEmpty ? nil : Double(temperature)
        let hr = heartRate.isEmpty ? nil : Int(heartRate)
        let rr = respiratoryRate.isEmpty ? nil : Int(respiratoryRate)
        let sys = systolicBP.isEmpty ? nil : Int(systolicBP)
        let dia = diastolicBP.isEmpty ? nil : Int(diastolicBP)
        let o2 = oxygenSaturation.isEmpty ? nil : Int(oxygenSaturation)

        return VitalSigns(
            temperature: temp,
            heartRate: hr,
            respiratoryRate: rr,
            systolicBP: sys,
            diastolicBP: dia,
            oxygenSaturation: o2
        )
    }

    /// Handle validation errors specifically
    private func handleValidationError(_ error: SOAPNoteValidationError) {
        // Set validation error state
        self.validationErrors = [error]
        self.hasValidationErrors = true
        self.validationFailureReason = error.displayMessage

        // Also set generic error display for user
        self.errorMessage = error.displayMessage
        self.showError = true

        // Mark state as validation error
        self.generationState = .validationFailed(error)
    }

    /// Handle validation errors during streaming
    private func handleStreamingValidationError(_ error: SOAPNoteValidationError) {
        // Set validation error state
        self.validationErrors = [error]
        self.hasValidationErrors = true
        self.validationFailureReason = error.displayMessage

        // Also set generic error display for user
        self.errorMessage = error.displayMessage
        self.showError = true

        // Mark states
        self.streamingState = .validationFailed(error.displayMessage)
        self.generationState = .validationFailed(error)
    }

    /// Handle generic errors (non-validation)
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        generationState = .error(error)
    }

    /// Handle generic errors during streaming (non-validation)
    private func handleStreamingError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        streamingState = .failed(error.localizedDescription)
        generationState = .error(error)
    }

    // MARK: - Computed Properties

    var isReadyToGenerate: Bool {
        !patientAge.trimmingCharacters(in: .whitespaces).isEmpty
            && !chiefComplaint.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var canReview: Bool {
        generationState == .complete && currentNote != nil && validationErrors.isEmpty
    }

    var canSign: Bool {
        isReviewed && currentNote != nil
    }
}

// MARK: - Generation State

enum GenerationState: Equatable {
    case idle
    case generating
    case complete
    case signed
    case validationFailed(SOAPNoteValidationError)
    case error(Error)

    static func == (lhs: GenerationState, rhs: GenerationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.generating, .generating), (.complete, .complete), (.signed, .signed):
            return true
        case (.validationFailed, .validationFailed):
            return true // Simplified for Equatable
        case (.error, .error):
            return true // Simplified for Equatable
        default:
            return false
        }
    }

    var isGenerating: Bool {
        if case .generating = self {
            return true
        }
        return false
    }

    var isComplete: Bool {
        if case .complete = self {
            return true
        }
        return false
    }

    var isValidationFailed: Bool {
        if case .validationFailed = self {
            return true
        }
        return false
    }

    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}

// MARK: - Streaming State

enum StreamingState: Equatable {
    case idle
    case generating
    case validating
    case complete
    case validationFailed(String)
    case failed(String)

    var isGenerating: Bool {
        if case .generating = self {
            return true
        }
        return false
    }

    var isValidating: Bool {
        if case .validating = self {
            return true
        }
        return false
    }

    var isComplete: Bool {
        if case .complete = self {
            return true
        }
        return false
    }

    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    var isValidationFailed: Bool {
        if case .validationFailed = self {
            return true
        }
        return false
    }
}
