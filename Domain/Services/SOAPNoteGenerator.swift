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

/// Vital signs for SOAP note context
struct VitalSigns: Codable {
    let temperature: Double? // Celsius
    let heartRate: Int? // bpm
    let respiratoryRate: Int? // breaths/min
    let systolicBP: Int? // mmHg
    let diastolicBP: Int? // mmHg
    let oxygenSaturation: Int? // % on room air

    enum CodingKeys: String, CodingKey {
        case temperature
        case heartRate = "heart_rate"
        case respiratoryRate = "respiratory_rate"
        case systolicBP = "systolic_bp"
        case diastolicBP = "diastolic_bp"
        case oxygenSaturation = "oxygen_saturation"
    }
}

/// Patient context for SOAP note generation
struct PatientContext: Codable {
    let age: Int
    let sex: String // M, F, Other
    let chiefComplaint: String
    let vitalSigns: VitalSigns
    let medicalHistory: [String]?
    let currentMedications: [String]?
    let allergies: [String]?

    enum CodingKeys: String, CodingKey {
        case age
        case sex
        case chiefComplaint = "chief_complaint"
        case vitalSigns = "vital_signs"
        case medicalHistory = "medical_history"
        case currentMedications = "current_medications"
        case allergies
    }
}

/// SOAP note sections
struct SOAPNote: Codable {
    let subjective: String
    let objective: String
    let assessment: String
    let plan: String
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case subjective
        case objective
        case assessment
        case plan
        case generatedAt = "generated_at"
    }
}

/// Generation options
struct SOAPGenerationOptions {
    let maxTokens: Int
    let temperature: Float
    let includeVoiceInput: Bool

    static var `default`: SOAPGenerationOptions {
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
    private let responseParser: SOAPResponseParser

    // MARK: - Initialization

    init(
        modelLoader: MLXModelLoader = .shared,
        promptBuilder: SOAPPromptBuilder = SOAPPromptBuilder(),
        responseParser: SOAPResponseParser = SOAPResponseParser()
    ) {
        self.modelLoader = modelLoader
        self.promptBuilder = promptBuilder
        self.responseParser = responseParser
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
    ) async throws -> SOAPNote {
        // 1. Ensure model is loaded
        if !modelLoader.isModelLoaded {
            try modelLoader.loadModel()
        }

        // 2. Build prompt from context
        let prompt = promptBuilder.buildSOAPPrompt(from: context, language: language)

        // 3. Generate response using MLX model
        let response = try await generateResponse(prompt: prompt, options: options)

        // 4. Parse response into SOAP sections
        let soapNote = try responseParser.parseSOAPNote(from: response)

        return soapNote
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
                    // 1. Ensure model is loaded
                    if !self.modelLoader.isModelLoaded {
                        try self.modelLoader.loadModel()
                    }

                    // 2. Build prompt
                    let prompt = self.promptBuilder.buildSOAPPrompt(from: context, language: language)

                    // 3. Get streaming from model bridge
                    let stream = MLXModelBridge.generateStreaming(
                        prompt: prompt,
                        maxTokens: options.maxTokens,
                        temperature: options.temperature
                    )

                    // 4. Yield tokens from stream
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
        // Delegate to MLX model
        return try await Task.detached(priority: .userInitiated) {
            try MLXModelBridge.generate(
                prompt: prompt,
                maxTokens: options.maxTokens,
                temperature: options.temperature
            )
        }.value
    }

    private func streamResponse(
        prompt: String,
        options: SOAPGenerationOptions,
        onPartialToken: @escaping (String) -> Void
    ) async throws {
        // Get streaming from model bridge
        let stream = MLXModelBridge.generateStreaming(
            prompt: prompt,
            maxTokens: options.maxTokens,
            temperature: options.temperature
        )

        // Yield each token via callback
        for try await token in stream {
            onPartialToken(token)
        }
    }

    /// Parse raw response text into SOAP note
    /// - Parameter responseText: Raw text output from model
    /// - Returns: Parsed SOAP note
    func parseResponse(_ responseText: String) throws -> SOAPNote {
        return try responseParser.parseSOAPNote(from: responseText)
    }
}

// MARK: - Prompt Builder

/// Builds SOAP generation prompts
class SOAPPromptBuilder {

    func buildSOAPPrompt(from context: PatientContext, language: Language = .english) -> String {
        let localizedPrompts = LocalizedPrompts(language: language)
        return localizedPrompts.buildSOAPPrompt(from: context)
    }
}

// MARK: - Response Parser

/// Parses model output into SOAP note structure
class SOAPResponseParser {

    func parseSOAPNote(from output: String) throws -> SOAPNote {
        // Extract JSON from output
        guard let jsonString = extractJSON(from: output) else {
            throw MLXModelError.invocationFailed("No valid JSON found in model output")
        }

        // Decode JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw MLXModelError.invocationFailed("Failed to encode JSON string")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(SOAPNote.self, from: jsonData)
        } catch {
            throw MLXModelError.invocationFailed("Failed to decode SOAP note: \(error)")
        }
    }

    private func extractJSON(from output: String) -> String? {
        // Find first { and last }
        guard let startIndex = output.firstIndex(of: "{"),
              let endIndex = output.lastIndex(of: "}") else {
            return nil
        }

        let jsonString = String(output[startIndex ... endIndex])

        // Validate JSON
        if let jsonData = jsonString.data(using: .utf8),
           let _ = try? JSONSerialization.jsonObject(with: jsonData) {
            return jsonString
        }

        return nil
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
