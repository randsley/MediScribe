//
//  MLXModelLoader.swift
//  MediScribe
//
//  Model loader for MLX-format MedGemma model
//

import Foundation

/// Error types for MLX model operations
enum MLXModelError: LocalizedError {
    case modelNotFound
    case modelLoadFailed(String)
    case invocationFailed(String)
    case tokenizationFailed
    case memoryError
    case fileAccessError(String)
    case tokenizerNotLoaded
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "MLX model not found at path"
        case .modelLoadFailed(let msg):
            return "Failed to load MLX model: \(msg)"
        case .invocationFailed(let msg):
            return "Model invocation failed: \(msg)"
        case .tokenizationFailed:
            return "Failed to tokenize input text"
        case .memoryError:
            return "Insufficient memory to load model"
        case .fileAccessError(let msg):
            return "File access error: \(msg)"
        case .tokenizerNotLoaded:
            return "Tokenizer not loaded"
        case .modelNotLoaded:
            return "Model not loaded"
        }
    }
}

/// Manages loading and access to MLX-format MedGemma model
class MLXModelLoader {
    // MARK: - Singleton

    static let shared = MLXModelLoader()

    // MARK: - Properties

    private var modelPath: String?
    private var isLoaded = false
    private let queue = DispatchQueue(label: "com.mediscribe.mlx", qos: .userInitiated)

    // MARK: - Initialization

    private init() {
        setupModelPath()
    }

    // MARK: - Public Methods

    /// Load the MLX model from disk
    /// - Throws: MLXModelError if loading fails
    func loadModel() throws {
        try queue.sync {
            guard !isLoaded else { return }

            guard let modelPath = modelPath else {
                throw MLXModelError.modelNotFound
            }

            // Verify model files exist
            try verifyModelFiles(at: modelPath)

            // Load model using MLX framework
            // Note: Actual loading delegated to MLXModelBridge (Objective-C wrapper)
            try MLXModelBridge.loadModel(at: modelPath)

            isLoaded = true
        }
    }

    /// Unload the model from memory
    func unloadModel() {
        queue.sync {
            MLXModelBridge.unloadModel()
            isLoaded = false
        }
    }

    /// Check if model is currently loaded
    var isModelLoaded: Bool {
        queue.sync { isLoaded }
    }

    /// Get the model path
    var currentModelPath: String? {
        queue.sync { modelPath }
    }

    // MARK: - Private Methods

    private func setupModelPath() {
        // Model is in ~/MediScribe/models/medgemma-1.5-4b-it-mlx
        // Use NSSearchPathForDirectoriesInDomains for iOS compatibility
        if let homeDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let modelDir = (homeDir as NSString).appendingPathComponent("../MediScribe/models/medgemma-1.5-4b-it-mlx")
            modelPath = modelDir
        } else {
            // Fallback: try using app bundle
            if let bundlePath = Bundle.main.bundlePath as String? {
                let modelDir = (bundlePath as NSString).appendingPathComponent("../../../MediScribe/models/medgemma-1.5-4b-it-mlx")
                modelPath = modelDir
            }
        }
    }

    private func verifyModelFiles(at path: String) throws {
        let fm = FileManager.default

        // Check for required files
        let requiredFiles = [
            "model.safetensors",
            "tokenizer.json",
            "config.json"
        ]

        for file in requiredFiles {
            let filePath = (path as NSString).appendingPathComponent(file)
            if !fm.fileExists(atPath: filePath) {
                throw MLXModelError.fileAccessError("Missing required file: \(file)")
            }
        }

        // Verify model file size (should be ~2GB)
        let modelPath = (path as NSString).appendingPathComponent("model.safetensors")
        if let attrs = try? fm.attributesOfItem(atPath: modelPath),
           let size = attrs[.size] as? Int64 {
            // File should be at least 1GB
            if size < 1_000_000_000 {
                throw MLXModelError.fileAccessError("Model file too small: \(size) bytes")
            }
        }
    }
}

// MARK: - MLXModelBridge

/// Bridge to MLX-Swift framework for model inference
/// Note: This implementation requires the MLX-Swift package to be added to the project
class MLXModelBridge: NSObject {

    // MARK: - Static Properties

    /// Singleton instance of loaded model
    private static var loadedModel: Any?

    /// Tokenizer instance
    private static var tokenizer: Any?

    /// Model configuration
    private static var modelConfig: [String: Any]?

    /// Lock for thread-safe access
    private static let lock = NSLock()

    // MARK: - Public Methods

    /// Load model from disk
    /// - Parameter path: Path to model directory containing model.safetensors, tokenizer.json, config.json
    /// - Throws: MLXModelError if loading fails
    static func loadModel(at path: String) throws {
        lock.lock()
        defer { lock.unlock() }

        guard FileManager.default.fileExists(atPath: path) else {
            throw MLXModelError.fileAccessError("Model path does not exist: \(path)")
        }

        do {
            // Load tokenizer
            let tokenizerPath = (path as NSString).appendingPathComponent("tokenizer.json")
            try loadTokenizer(from: tokenizerPath)

            // Load config
            let configPath = (path as NSString).appendingPathComponent("config.json")
            try loadConfig(from: configPath)

            // Load model safetensors
            let modelPath = (path as NSString).appendingPathComponent("model.safetensors")
            try loadModelWeights(from: modelPath)

        } catch {
            throw MLXModelError.modelLoadFailed(error.localizedDescription)
        }
    }

    /// Unload model from memory
    static func unloadModel() {
        lock.lock()
        defer { lock.unlock() }

        loadedModel = nil
        tokenizer = nil
        modelConfig = nil
    }

    /// Run inference on text with MLX model
    /// - Parameters:
    ///   - prompt: Input text prompt
    ///   - maxTokens: Maximum tokens to generate (default: 1024)
    ///   - temperature: Sampling temperature 0.0-1.0 (default: 0.3)
    /// - Returns: Generated text completion
    /// - Throws: MLXModelError if inference fails
    static func generate(
        prompt: String,
        maxTokens: Int = 1024,
        temperature: Float = 0.3
    ) throws -> String {
        lock.lock()
        defer { lock.unlock() }

        guard loadedModel != nil else {
            throw MLXModelError.modelNotLoaded
        }

        guard tokenizer != nil else {
            throw MLXModelError.tokenizerNotLoaded
        }

        do {
            // Tokenize input
            let inputIds = try tokenizeText(prompt)

            // Run inference with safety constraints
            let generatedIds = try inferenceLoop(
                inputIds: inputIds,
                maxNewTokens: maxTokens,
                temperature: temperature
            )

            // Detokenize output
            let generatedText = try detokenizeIds(generatedIds)

            return generatedText

        } catch let error as MLXModelError {
            throw error
        } catch {
            throw MLXModelError.invocationFailed(error.localizedDescription)
        }
    }

    /// Tokenize text into token IDs
    /// - Parameter text: Input text to tokenize
    /// - Returns: Array of token IDs
    /// - Throws: MLXModelError if tokenization fails
    static func tokenize(_ text: String) throws -> [Int32] {
        lock.lock()
        defer { lock.unlock() }

        guard tokenizer != nil else {
            throw MLXModelError.tokenizerNotLoaded
        }

        do {
            return try tokenizeText(text)
        } catch let error as MLXModelError {
            throw error
        } catch {
            throw MLXModelError.tokenizationFailed
        }
    }

    // MARK: - Private Methods

    private static func loadTokenizer(from path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MLXModelError.fileAccessError("Tokenizer not found at \(path)")
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            // In real implementation with MLX-Swift, would use:
            // tokenizer = try Tokenizer(jsonData: data)
            // For now, store marker that tokenizer is loaded
            tokenizer = NSData(data: data)
        } catch {
            throw MLXModelError.modelLoadFailed("Failed to load tokenizer: \(error)")
        }
    }

    private static func loadConfig(from path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MLXModelError.fileAccessError("Config not found at \(path)")
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                modelConfig = json
            }
        } catch {
            throw MLXModelError.modelLoadFailed("Failed to load config: \(error)")
        }
    }

    private static func loadModelWeights(from path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MLXModelError.fileAccessError("Model weights not found at \(path)")
        }

        // In real implementation with MLX-Swift, would use:
        // loadedModel = try MLX.load(contentsOf: URL(fileURLWithPath: path))
        // For now, store marker that model is loaded
        loadedModel = NSObject()
    }

    private static func tokenizeText(_ text: String) throws -> [Int32] {
        // Placeholder: would use actual tokenizer
        // This is a simple demonstration - real implementation would tokenize properly
        let tokens = text.split(separator: " ").enumerated().map { Int32($0.offset) }
        return tokens
    }

    private static func inferenceLoop(
        inputIds: [Int32],
        maxNewTokens: Int,
        temperature: Float
    ) throws -> [Int32] {
        // Placeholder for actual MLX inference loop
        // In real implementation:
        // 1. Convert input IDs to embeddings
        // 2. Run model forward pass
        // 3. Sample next token based on temperature
        // 4. Repeat until max tokens or EOS
        return inputIds  // Simplified return
    }

    private static func detokenizeIds(_ ids: [Int32]) throws -> String {
        // Placeholder: would use actual tokenizer
        let words = ids.map { String(format: "token_%d", $0) }
        return words.joined(separator: " ")
    }
}
