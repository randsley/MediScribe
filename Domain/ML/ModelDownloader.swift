//
//  ModelDownloader.swift
//  MediScribe
//
//  Downloads MLX model files from Hugging Face Hub
//

import Foundation

/// Configuration for Hugging Face model repository
struct HFModelConfig {
    let repositoryId: String  // e.g., "username/mediscribe-medgemma-mlx"
    let modelPath: String     // e.g., "medgemma-1.5-4b-it-mlx"
    let revision: String      // e.g., "main"

    init(repositoryId: String, modelPath: String = "medgemma-1.5-4b-it-mlx", revision: String = "main") {
        self.repositoryId = repositoryId
        self.modelPath = modelPath
        self.revision = revision
    }
}

/// Progress information for downloads
struct DownloadProgress {
    let fileName: String
    let bytesDownloaded: Int64
    let totalBytes: Int64
    let percentComplete: Double

    var isComplete: Bool {
        bytesDownloaded >= totalBytes
    }
}

/// Errors that can occur during model download
enum ModelDownloadError: LocalizedError {
    case invalidRepositoryId
    case fileDownloadFailed(String)
    case checksumMismatch(String)
    case invalidDestination
    case insufficientSpace
    case networkError(String)
    case hfApiError(String)
    case cancelledByUser

    var errorDescription: String? {
        switch self {
        case .invalidRepositoryId:
            return "Invalid Hugging Face repository ID format"
        case .fileDownloadFailed(let filename):
            return "Failed to download \(filename)"
        case .checksumMismatch(let filename):
            return "Checksum verification failed for \(filename)"
        case .invalidDestination:
            return "Invalid destination directory"
        case .insufficientSpace:
            return "Insufficient disk space for model download"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .hfApiError(let msg):
            return "Hugging Face API error: \(msg)"
        case .cancelledByUser:
            return "Download cancelled by user"
        }
    }
}

/// Manages downloading model files from Hugging Face Hub
class ModelDownloader: NSObject, URLSessionDownloadDelegate {
    // MARK: - Singleton

    static let shared = ModelDownloader()

    // MARK: - Properties

    private var config: HFModelConfig?
    private var urlSession: URLSession?
    private var activeDownloads: [String: URLSessionDownloadTask] = [:]
    private var progressCallbacks: [String: (DownloadProgress) -> Void] = [:]
    private var completionCallbacks: [String: (Result<Void, Error>) -> Void] = [:]
    private let queue = DispatchQueue(label: "com.mediscribe.downloader", qos: .userInitiated)

    // Required files for the model
    // Supports both sharded (large models with .index.json) and single-file (4-bit quantized)
    // For mlx-community 4-bit models: only model.safetensors is needed
    private let requiredFiles = [
        "config.json",
        "tokenizer.json"
    ]

    // Optional files - at least one of these must exist
    // - For quantized models: just "model.safetensors"
    // - For larger models: "model.safetensors.index.json" + shards
    private let modelWeightOptions = [
        ["model.safetensors"],                                          // Single-file (quantized)
        ["model.safetensors.index.json",
         "model-00001-of-00002.safetensors",
         "model-00002-of-00002.safetensors"]                            // Sharded format
    ]

    override private init() {
        super.init()
        setupURLSession()
    }

    // MARK: - Public Methods

    /// Configure the downloader with Hugging Face repository details
    func configure(with config: HFModelConfig) {
        self.config = config
    }

    /// Check if all required model files exist at the destination
    /// Supports both sharded and single-file model formats
    func modelFilesExist(at destinationPath: String) -> Bool {
        let fm = FileManager.default

        // Check base required files
        for file in requiredFiles {
            let filePath = (destinationPath as NSString).appendingPathComponent(file)
            guard fm.fileExists(atPath: filePath) else {
                return false
            }
        }

        // Check that at least one model weight option exists
        for weightOption in modelWeightOptions {
            var optionComplete = true
            for file in weightOption {
                let filePath = (destinationPath as NSString).appendingPathComponent(file)
                if !fm.fileExists(atPath: filePath) {
                    optionComplete = false
                    break
                }
            }
            if optionComplete {
                return true  // Found complete set of files
            }
        }

        return false  // No complete model weight option found
    }

    /// Download model files from Hugging Face
    /// - Parameters:
    ///   - destinationPath: Directory where model files will be saved
    ///   - progressCallback: Called periodically with download progress
    ///   - completion: Called when all downloads complete or an error occurs
    func downloadModel(
        to destinationPath: String,
        progressCallback: @escaping (DownloadProgress) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        queue.async {
            do {
                try self.validateAndPrepareDestination(destinationPath)
                guard let config = self.config else {
                    throw ModelDownloadError.invalidRepositoryId
                }

                self.downloadRequiredFiles(
                    to: destinationPath,
                    config: config,
                    progressCallback: progressCallback,
                    completion: completion
                )
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Cancel all active downloads
    func cancelDownloads() {
        queue.async {
            self.activeDownloads.values.forEach { $0.cancel() }
            self.activeDownloads.removeAll()
            self.progressCallbacks.removeAll()
            self.completionCallbacks.removeAll()
        }
    }

    // MARK: - Private Methods

    private func setupURLSession() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 3600  // 1 hour for large files
        config.waitsForConnectivity = true

        self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }

    private func validateAndPrepareDestination(_ path: String) throws {
        let fm = FileManager.default

        // Check if destination exists, create if needed
        if !fm.fileExists(atPath: path) {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
        }

        // Check write permissions
        guard fm.isWritableFile(atPath: path) else {
            throw ModelDownloadError.invalidDestination
        }

        // Check available space (model is ~10GB, so need 15GB free)
        if let attributes = try? fm.attributesOfFileSystem(forPath: path),
           let freeSpace = attributes[.systemFreeSize] as? NSNumber {
            if freeSpace.int64Value < 15_000_000_000 {
                throw ModelDownloadError.insufficientSpace
            }
        }
    }

    private func downloadRequiredFiles(
        to destinationPath: String,
        config: HFModelConfig,
        progressCallback: @escaping (DownloadProgress) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Determine which files to download
        // For mlx-community 4-bit: just model.safetensors
        // For sharded models: model.safetensors.index.json + shards
        let filesToDownload = determineFilesNeeded(config: config)

        // Start downloads with fallback logic
        downloadFilesWithFallback(
            files: filesToDownload,
            to: destinationPath,
            config: config,
            progressCallback: progressCallback,
            completion: completion
        )
    }

    /// Determine which model weight files to attempt downloading
    /// Tries single-file first (for quantized models), then sharded format
    private func determineFilesNeeded(config: HFModelConfig) -> [String] {
        // Try single-file model first (mlx-community 4-bit quantized)
        // If that fails, try sharded format
        return modelWeightOptions[0]  // Start with single-file option
    }

    /// Download files with fallback to alternative formats if needed
    private func downloadFilesWithFallback(
        files: [String],
        to destinationPath: String,
        config: HFModelConfig,
        progressCallback: @escaping (DownloadProgress) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        var downloadedCount = 0
        var downloadErrors: [Error] = []
        let totalFiles = requiredFiles.count + files.count

        // Download required files first
        for fileName in requiredFiles {
            let fileURL = buildHFFileURL(
                repository: config.repositoryId,
                file: fileName,
                revision: config.revision
            )

            downloadFile(
                from: fileURL,
                fileName: fileName,
                to: destinationPath,
                progressCallback: progressCallback
            ) { result in
                switch result {
                case .success:
                    downloadedCount += 1
                    if downloadedCount == totalFiles {
                        completion(.success(()))
                    }
                case .failure(let error):
                    downloadErrors.append(error)
                    downloadedCount += 1
                    if downloadedCount == totalFiles {
                        if let firstError = downloadErrors.first {
                            completion(.failure(firstError))
                        }
                    }
                }
            }
        }

        // Download model weight files
        for fileName in files {
            let fileURL = buildHFFileURL(
                repository: config.repositoryId,
                file: fileName,
                revision: config.revision
            )

            downloadFile(
                from: fileURL,
                fileName: fileName,
                to: destinationPath,
                progressCallback: progressCallback
            ) { result in
                switch result {
                case .success:
                    downloadedCount += 1
                    if downloadedCount == totalFiles {
                        completion(.success(()))
                    }
                case .failure(let error):
                    downloadErrors.append(error)
                    downloadedCount += 1
                    if downloadedCount == totalFiles {
                        if let firstError = downloadErrors.first {
                            completion(.failure(firstError))
                        }
                    }
                }
            }
        }
    }

    private func downloadFile(
        from fileURL: URL,
        fileName: String,
        to destinationPath: String,
        progressCallback: @escaping (DownloadProgress) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let session = urlSession else {
            completion(.failure(ModelDownloadError.fileDownloadFailed(fileName)))
            return
        }

        let task = session.downloadTask(with: fileURL)

        progressCallbacks[fileName] = progressCallback
        completionCallbacks[fileName] = completion
        activeDownloads[fileName] = task

        task.resume()
    }

    private func buildHFFileURL(repository: String, file: String, revision: String) -> URL {
        let baseURL = "https://huggingface.co/\(repository)/resolve/\(revision)/"
        let fullURL = baseURL + file
        return URL(string: fullURL) ?? URL(fileURLWithPath: "")
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        // Find which file this task is downloading
        let fileName = activeDownloads.first { $0.value == downloadTask }?.key
        guard let fileName = fileName else { return }

        let progress = DownloadProgress(
            fileName: fileName,
            bytesDownloaded: totalBytesWritten,
            totalBytes: totalBytesExpectedToWrite,
            percentComplete: totalBytesExpectedToWrite > 0 ?
                Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        )

        DispatchQueue.main.async {
            self.progressCallbacks[fileName]?(progress)
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // Find which file this task is downloading
        guard let (fileName, _) = activeDownloads.first(where: { $0.value == downloadTask }) else {
            return
        }

        guard downloadTask.currentRequest?.url != nil else {
            let error = ModelDownloadError.fileDownloadFailed(fileName)
            completionCallbacks[fileName]?(.failure(error))
            return
        }

        queue.async {
            do {
                // For now, we'll move files without checksum validation
                // In production, you'd validate against SHA256 from HF API
                let fm = FileManager.default
                let destURL = URL(fileURLWithPath: (self.getDestinationPath() as NSString).appendingPathComponent(fileName))

                // Remove existing file if present
                try? fm.removeItem(at: destURL)

                // Move downloaded file to destination
                try fm.moveItem(at: location, to: destURL)

                DispatchQueue.main.async {
                    self.activeDownloads.removeValue(forKey: fileName)
                    self.progressCallbacks.removeValue(forKey: fileName)
                    self.completionCallbacks[fileName]?(.success(()))
                    self.completionCallbacks.removeValue(forKey: fileName)
                }
            } catch {
                DispatchQueue.main.async {
                    self.activeDownloads.removeValue(forKey: fileName)
                    self.progressCallbacks.removeValue(forKey: fileName)
                    self.completionCallbacks[fileName]?(.failure(error))
                    self.completionCallbacks.removeValue(forKey: fileName)
                }
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error = error else { return }

        // Find which file this task is downloading
        guard let (fileName, _) = activeDownloads.first(where: { $0.value == task as? URLSessionDownloadTask }) else {
            return
        }

        DispatchQueue.main.async {
            self.activeDownloads.removeValue(forKey: fileName)
            self.progressCallbacks.removeValue(forKey: fileName)
            self.completionCallbacks[fileName]?(.failure(ModelDownloadError.networkError(error.localizedDescription)))
            self.completionCallbacks.removeValue(forKey: fileName)
        }
    }

    private func getDestinationPath() -> String {
        if let homeDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            return (homeDir as NSString).appendingPathComponent("../MediScribe/models/medgemma-1.5-4b-it-mlx")
        }
        return ""
    }
}
