//
//  SOAPNoteGenerator.swift
//  MediScribe
//
//  Generates SOAP notes using MedGemma model
//

import Foundation

// Note: MLXModelBridge is defined in Domain/ML/MLXModelLoader.swift
// It's part of the internal module and doesn't require a separate import

// MARK: - Data Models

/// Generation options
struct SOAPGenerationOptions {
    let maxTokens: Int
    let temperature: Float
    let includeVoiceInput: Bool

    nonisolated static var `default`: SOAPGenerationOptions {
        SOAPGenerationOptions(
            maxTokens: 2048,
            temperature: 0.3,
            includeVoiceInput: false
        )
    }

    nonisolated static var soapGeneration: SOAPGenerationOptions {
        SOAPGenerationOptions(
            maxTokens: 2048,
            temperature: 0.3,
            includeVoiceInput: false
        )
    }
}

// MARK: - SOAP Note Generator

/// Service for generating SOAP notes using MedGemma
class SOAPNoteGenerator {
    // MARK: - Properties

    private let modelLoader: MLXModelLoader
    private let promptBuilder: SOAPPromptBuilder
    private let noteParser: SOAPNoteParser

    // MARK: - Initialization

    init(
        modelLoader: MLXModelLoader = .shared,
        promptBuilder: SOAPPromptBuilder = SOAPPromptBuilder(),
        noteParser: SOAPNoteParser = SOAPNoteParser()
    ) {
        self.modelLoader = modelLoader
        self.promptBuilder = promptBuilder
        self.noteParser = noteParser
    }

    // MARK: - Public Methods

    /// Generate a SOAP note from patient context
    /// - Parameters:
    ///   - context: Patient information for the note
    ///   - language: Language for generation (default: English)
    ///   - options: Generation options
    /// - Returns: Generated SOAP note
    func generateSOAPNote(
        from context: PatientContext,
        language: Language = .english,
        options: SOAPGenerationOptions = .default
    ) async throws -> SOAPNoteData {
        // 1. Ensure model is loaded
        if !modelLoader.isModelLoaded {
            try modelLoader.loadModel()
        }

        // 2. Build prompt from context
        let prompt = promptBuilder.buildSOAPPrompt(from: context, language: language)

        // 3. Generate response using MLX model
        let startTime = Date()
        let response = try await generateResponse(prompt: prompt, options: options)
        let elapsed = Date().timeIntervalSince(startTime)

        // 4. Parse and validate response into SOAPNoteData
        return try noteParser.parseSOAPNote(
            from: response,
            modelVersion: ModelConfiguration.huggingFaceRepositoryId,
            generationTime: elapsed
        )
    }

    /// Generate streaming SOAP note updates
    /// - Parameters:
    ///   - context: Patient information
    ///   - language: Language for generation (default: English)
    ///   - options: Generation options
    ///   - onPartialNote: Callback with partial note updates
    func generateSOAPNoteStreaming(
        from context: PatientContext,
        language: Language = .english,
        options: SOAPGenerationOptions = .default,
        onPartialNote: @escaping (PartialSOAPNote) -> Void
    ) async throws {
        // 1. Ensure model is loaded
        if !modelLoader.isModelLoaded {
            try modelLoader.loadModel()
        }

        // 2. Build prompt
        let prompt = promptBuilder.buildSOAPPrompt(from: context, language: language)

        // 3. Stream generation with callbacks
        try await streamResponse(
            prompt: prompt,
            options: options,
            onPartialToken: { token in
                // Update UI with streaming token
                onPartialNote(PartialSOAPNote(token: token))
            }
        )
    }

    /// Generate streaming token updates as AsyncThrowingStream
    /// - Parameters:
    ///   - context: Patient information
    ///   - language: Language for generation (default: English)
    ///   - options: Generation options
    /// - Returns: Stream of token strings
    func generateSOAPNoteTokenStream(
        from context: PatientContext,
        language: Language = .english,
        options: SOAPGenerationOptions = .default
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let bridge = MLXMedGemmaBridge.shared
                    if !bridge.isModelLoaded {
                        let modelPath = ModelConfiguration.modelDirectoryPath()
                        try await bridge.loadModel(from: modelPath)
                    }

                    let prompt = self.promptBuilder.buildSOAPPrompt(from: context, language: language)
                    let stream = bridge.generateTextStreaming(
                        prompt: prompt,
                        maxTokens: options.maxTokens,
                        temperature: options.temperature
                    )
                    for try await token in stream {
                        continuation.yield(token)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func generateResponse(
        prompt: String,
        options: SOAPGenerationOptions
    ) async throws -> String {
        let bridge = MLXMedGemmaBridge.shared
        if !bridge.isModelLoaded {
            let modelPath = ModelConfiguration.modelDirectoryPath()
            try await bridge.loadModel(from: modelPath)
        }
        return try await bridge.generateText(
            prompt: prompt,
            maxTokens: options.maxTokens,
            temperature: options.temperature
        )
    }

    private func streamResponse(
        prompt: String,
        options: SOAPGenerationOptions,
        onPartialToken: @escaping (String) -> Void
    ) async throws {
        let bridge = MLXMedGemmaBridge.shared
        if !bridge.isModelLoaded {
            let modelPath = ModelConfiguration.modelDirectoryPath()
            try await bridge.loadModel(from: modelPath)
        }
        let stream = bridge.generateTextStreaming(
            prompt: prompt,
            maxTokens: options.maxTokens,
            temperature: options.temperature
        )
        for try await token in stream {
            onPartialToken(token)
        }
    }

    /// Parse raw response text into SOAP note data (used for accumulated streaming tokens)
    /// - Parameter responseText: Raw text output from model
    /// - Returns: Parsed SOAP note data
    func parseResponse(_ responseText: String) throws -> SOAPNoteData {
        return try noteParser.parseSOAPNote(
            from: responseText,
            modelVersion: ModelConfiguration.huggingFaceRepositoryId,
            generationTime: 0
        )
    }
}

// MARK: - Prompt Builder

/// Builds SOAP generation prompts
class SOAPPromptBuilder {

    func buildSOAPPrompt(from context: PatientContext, language: Language = .english) -> String {
        var vitalsText = "Not recorded"
        let v = context.vitalSigns
        var parts: [String] = []
        if let t = v.temperature { parts.append("Temp \(t)°C") }
        if let hr = v.heartRate { parts.append("HR \(hr) bpm") }
        if let rr = v.respiratoryRate { parts.append("RR \(rr)/min") }
        if let sys = v.systolicBP, let dia = v.diastolicBP { parts.append("BP \(sys)/\(dia) mmHg") }
        if let o2 = v.oxygenSaturation { parts.append("SpO₂ \(o2)%") }
        if !parts.isEmpty { vitalsText = parts.joined(separator: ", ") }

        let historyText = context.medicalHistory?.joined(separator: "; ") ?? "None documented"
        let medsText = context.currentMedications?.joined(separator: "; ") ?? "None"
        let allergiesText = context.allergies?.joined(separator: "; ") ?? "NKDA"

        return """
        Generate a structured SOAP note in JSON format for the following patient. \
        Output ONLY valid JSON, no other text. The output must be observational and descriptive only — \
        do NOT include diagnoses, disease names, probabilistic statements, or treatment recommendations.

        Patient: \(context.age)y \(context.sex)
        Chief complaint: \(context.chiefComplaint)
        Vitals: \(vitalsText)
        Medical history: \(historyText)
        Current medications: \(medsText)
        Allergies: \(allergiesText)

        Required JSON schema:
        {
          "subjective": {
            "chief_complaint": "string",
            "history_of_present_illness": "string",
            "past_medical_history": ["string"] or null,
            "medications": ["string"] or null,
            "allergies": ["string"] or null
          },
          "objective": {
            "vital_signs": {
              "temperature": number or null,
              "heart_rate": number or null,
              "respiratory_rate": number or null,
              "systolic_bp": number or null,
              "diastolic_bp": number or null,
              "oxygen_saturation": number or null,
              "recorded_at": null
            },
            "physical_exam_findings": ["string"] or null,
            "diagnostic_results": ["string"] or null
          },
          "assessment": {
            "clinical_impression": "string (observations only, no diagnoses)",
            "differential_considerations": null,
            "problem_list": ["string"] or null
          },
          "plan": {
            "interventions": ["string"] or null,
            "follow_up": ["string"] or null,
            "patient_education": null,
            "referrals": null
          }
        }
        """
    }
}

// MARK: - Partial Note for Streaming

/// Represents partial SOAP note updates during streaming
struct PartialSOAPNote {
    let token: String
    let timestamp: Date

    init(token: String) {
        self.token = token
        self.timestamp = Date()
    }
}
