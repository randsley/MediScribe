//
//  ModelConfiguration.swift
//  MediScribe
//
//  Centralized model configuration for easy setup
//

import Foundation

/// Centralized configuration for model management
struct ModelConfiguration {
    // MARK: - Hugging Face Configuration

    /// Your Hugging Face repository ID
    /// Format: "username/repository-name"
    /// Examples:
    ///   - "mlx-community/medgemma-4b-it-4bit" (✓ RECOMMENDED: 4-bit quantized, 3GB)
    ///   - "mlx-community/medgemma-4b-it-8bit" (8-bit quantized, 2.5GB)
    ///   - "mlx-community/medgemma-4b-it-6bit" (6-bit quantized, 1.8GB)
    ///   - "username/mediscribe-medgemma-mlx" (custom repository)
    static let huggingFaceRepositoryId = "mlx-community/medgemma-4b-it-4bit"

    /// Git revision/branch to download from
    /// Use "main" for the main branch, or specify a tag like "v1.0"
    static let huggingFaceRevision = "main"

    /// Model directory name within the app documents
    /// This is just the local folder name - actual model repo ID is in huggingFaceRepositoryId
    static let modelDirectoryName = "medgemma-4b-it"

    // MARK: - Download Configuration

    /// Timeout for individual file downloads (5 minutes)
    static let downloadTimeoutSeconds: TimeInterval = 300

    /// Timeout for the entire download process (1 hour)
    static let downloadTotalTimeoutSeconds: TimeInterval = 3600

    /// Minimum free disk space required (15 GB for ~10GB model + buffer)
    static let minimumFreeSpaceBytes: Int64 = 15_000_000_000

    // MARK: - Model Information

    /// Required model files (in download order)
    /// Single-file format (medgemma-4b-it uses model.safetensors, not sharded)
    static let requiredModelFiles = [
        "config.json",
        "tokenizer.json",
        "model.safetensors"
    ]

    // MARK: - Inference Configuration

    /// Default maximum tokens for imaging findings.
    /// 384 tokens: JSON schema is ~150-200 tokens; headroom absorbs model preamble.
    /// Crash was caused by O(n²) prefill attention (596 prompt+image tokens), not
    /// by the decode length. Prefill is now safe at ~450 tokens total; decode
    /// memory is stable and grows very slowly (~0.1MB/token observed on device).
    static let defaultImagingMaxTokens = 384

    /// Default maximum tokens for lab results
    static let defaultLabMaxTokens = 1536

    /// Default inference temperature (lower = more deterministic)
    static let defaultInferenceTemperature: Float = 0.3

    /// Minimum inference temperature (for strict/deterministic output)
    static let minimumInferenceTemperature: Float = 0.0

    /// Maximum inference temperature (for more creative output)
    static let maximumInferenceTemperature: Float = 1.0

    // MARK: - Helper Methods

    /// Get the full path to the model directory.
    /// Uses Library/Application Support so files persist across backups and
    /// are not exposed via iTunes/Finder file sharing (Documents would be).
    /// - Returns: Path to <Library/Application Support>/models/
    static func modelDirectoryPath() -> String {
        let baseDir = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first ?? ""
        return (baseDir as NSString).appendingPathComponent("medgemma-4b-it")
    }

    /// Create HFModelConfig with current settings
    /// Usage: let config = ModelConfiguration.createHFConfig()
    static func createHFConfig() -> HFModelConfig {
        HFModelConfig(
            repositoryId: huggingFaceRepositoryId,
            modelPath: modelDirectoryName,
            revision: huggingFaceRevision
        )
    }

    /// Check if all required model files exist at the model directory
    /// This is called from ModelDownloader.modelFilesExist(at:)
    static func allModelFilesExist(at path: String = "") -> Bool {
        let targetPath = path.isEmpty ? modelDirectoryPath() : path
        let fm = FileManager.default

        for file in requiredModelFiles {
            let filePath = (targetPath as NSString).appendingPathComponent(file)
            if !fm.fileExists(atPath: filePath) {
                return false
            }
        }

        return true
    }

    /// Get disk usage of downloaded model
    /// - Returns: Size in bytes, or nil if model not found
    static func modelDiskUsage() -> Int64? {
        let fm = FileManager.default
        let modelPath = modelDirectoryPath()

        guard fm.fileExists(atPath: modelPath) else { return nil }

        do {
            let attributes = try fm.attributesOfItem(atPath: modelPath)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
}
