# Model Download Integration Guide

Quick reference for integrating model download into MediScribe's app lifecycle.

## Files Created

| File | Purpose |
|------|---------|
| `Domain/ML/ModelDownloader.swift` | Handles Hugging Face API and file downloads |
| `Domain/ML/ModelConfiguration.swift` | Centralized configuration (edit this!) |
| `UI/ModelSetupView.swift` | First-run model download UI |
| `HUGGINGFACE_MODEL_SETUP.md` | Complete HF setup instructions |

## Quick Setup (3 Steps)

### Step 1: Configure Your Hugging Face Repository

Edit `Domain/ML/ModelConfiguration.swift`:

```swift
static let huggingFaceRepositoryId = "your-username/mediscribe-medgemma-mlx"
static let huggingFaceRevision = "main"  // or "v1.0", etc.
```

### Step 2: Integrate into App Initialization

In `MediScribeApp.swift`:

```swift
@main
struct MediScribeApp: App {
    @State private var modelIsReady = false

    var body: some Scene {
        WindowGroup {
            if modelIsReady {
                RootView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                ModelSetupView()
                    .onAppear {
                        setupModelDownloader()
                        checkAndLoadModel()
                    }
            }
        }
    }

    private func setupModelDownloader() {
        // Configure the downloader with your HF repo
        ModelDownloader.shared.configure(with: ModelConfiguration.huggingFaceConfig())
    }

    private func checkAndLoadModel() {
        // Check if model is already downloaded
        if ModelConfiguration.modelFilesExist() {
            // Model exists, try to load it
            loadModel()
        }
        // If model doesn't exist, ModelSetupView will handle download
    }

    private func loadModel() {
        Task {
            do {
                try MLXModelLoader.shared.loadModel()
                DispatchQueue.main.async {
                    modelIsReady = true
                }
            } catch {
                // Handle error - show error view or fallback
                print("Model loading failed: \(error)")
            }
        }
    }
}
```

### Step 3: Upload Model to Hugging Face

See [HUGGINGFACE_MODEL_SETUP.md](./HUGGINGFACE_MODEL_SETUP.md) for detailed instructions.

## Component Details

### ModelDownloader

Handles all download logic:

```swift
// Configure with your HF repo
let config = HFModelConfig(repositoryId: "your-username/repo")
ModelDownloader.shared.configure(with: config)

// Check if files exist
if ModelDownloader.shared.modelFilesExist(at: path) {
    // Ready to use
}

// Start download
ModelDownloader.shared.downloadModel(
    to: destinationPath,
    progressCallback: { progress in
        print("Downloading \(progress.fileName): \(progress.percentComplete * 100)%")
    },
    completion: { result in
        switch result {
        case .success:
            print("Download complete!")
        case .failure(let error):
            print("Download failed: \(error)")
        }
    }
)

// Cancel active downloads
ModelDownloader.shared.cancelDownloads()
```

### ModelSetupView

Pre-built UI for first-run model download:

```swift
// Automatically handles:
// ✓ Checking if model files exist
// ✓ Starting downloads from HF
// ✓ Showing progress (file name, percentage)
// ✓ Error handling with retry
// ✓ Cancel support

ModelSetupView()
    .onAppear {
        checkAndLoadModel()
    }
```

### ModelConfiguration

Centralized config management:

```swift
// Access configuration values
let hfConfig = ModelConfiguration.huggingFaceConfig()
let modelPath = ModelConfiguration.modelDirectoryPath()
let exists = ModelConfiguration.modelFilesExist()
let usage = ModelConfiguration.modelDiskUsage()
```

## Integration Patterns

### Pattern A: Show Setup Screen Until Model Ready

```swift
@main
struct MediScribeApp: App {
    @State private var modelReady = false

    var body: some Scene {
        WindowGroup {
            if modelReady {
                RootView()
            } else {
                ModelSetupView()
                    .onAppear { checkModel() }
            }
        }
    }

    private func checkModel() {
        if ModelConfiguration.modelFilesExist() {
            // Optionally try to load
            loadModel()
        }
        // Otherwise ModelSetupView handles download
    }

    private func loadModel() {
        Task {
            try await MLXModelLoader.shared.loadModel()
            DispatchQueue.main.async { modelReady = true }
        }
    }
}
```

### Pattern B: Background Download

Show main app immediately, download model in background:

```swift
@main
struct MediScribeApp: App {
    @State private var modelDownloadTask: Task<Void, Never>?

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    startBackgroundModelDownload()
                }
        }
    }

    private func startBackgroundModelDownload() {
        guard !ModelConfiguration.modelFilesExist() else { return }

        modelDownloadTask = Task {
            let config = ModelConfiguration.huggingFaceConfig()
            ModelDownloader.shared.configure(with: config)

            ModelDownloader.shared.downloadModel(
                to: ModelConfiguration.modelDirectoryPath(),
                progressCallback: { _ in },
                completion: { result in
                    switch result {
                    case .success:
                        // Optionally load model
                        try? MLXModelLoader.shared.loadModel()
                    case .failure(let error):
                        print("Background download failed: \(error)")
                    }
                }
            )
        }
    }
}
```

### Pattern C: Settings UI for Manual Download

Add to Settings view:

```swift
struct SettingsView: View {
    @State private var showModelDownload = false
    @State private var modelStatus = "Checking..."

    var body: some View {
        Form {
            Section("Model Management") {
                if ModelConfiguration.modelFilesExist() {
                    HStack {
                        Label("Model Status", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        Spacer()

                        if let usage = ModelConfiguration.modelDiskUsage() {
                            Text("\(usage / 1_000_000_000) GB")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button("Download Latest Model", action: {
                        showModelDownload = true
                    })
                } else {
                    Button("Download Model", action: {
                        showModelDownload = true
                    })
                    .foregroundColor(.orange)
                }
            }
        }
        .sheet(isPresented: $showModelDownload) {
            ModelSetupView()
        }
    }
}
```

## Error Handling

### Common Errors and Solutions

```swift
// Error: Model files not found
// Solution: Ensure download completed successfully
if !ModelConfiguration.modelFilesExist() {
    // Show download UI
}

// Error: Insufficient disk space
// Solution: Check free space, clean up other files
let usage = ModelConfiguration.modelDiskUsage()
print("Model size: \(usage ?? 0) bytes")

// Error: Download failed
// Solution: Retry, check network, verify HF repo access
ModelDownloader.shared.downloadModel(
    to: path,
    progressCallback: { progress in },
    completion: { result in
        if case .failure(let error) = result {
            // Show retry UI
        }
    }
)

// Error: Model load failed after download
// Solution: Verify all files exist and are not corrupted
do {
    try MLXModelLoader.shared.loadModel()
} catch MLXModelError.modelNotFound {
    // Re-download model
} catch MLXModelError.fileAccessError(let msg) {
    // File corruption or permission issue
}
```

## Testing

### Simulator
- Uses placeholder model automatically
- No download occurs
- Full testing of UI/UX

### Device
- Download happens on first launch
- Monitor download progress
- Test offline loading after download

### Network Simulation
```swift
// Test poor network conditions
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 5  // Shorter timeout
config.waitsForConnectivity = true

// This is already handled in ModelDownloader with defaults:
// - 5 minute per-file timeout
// - 1 hour total timeout
```

## Configuration Reference

### Edit These Values in ModelConfiguration.swift

| Setting | Default | Purpose |
|---------|---------|---------|
| `huggingFaceRepositoryId` | `username/mediscribe-medgemma-mlx` | **REQUIRED**: Your HF repo |
| `huggingFaceRevision` | `main` | Branch/tag to download |
| `modelDirectoryName` | `medgemma-1.5-4b-it-mlx` | Local directory name |
| `downloadTimeoutSeconds` | `300` | Per-file timeout (seconds) |
| `downloadTotalTimeoutSeconds` | `3600` | Total download timeout (seconds) |
| `minimumFreeSpaceBytes` | `15_000_000_000` | Disk space check (bytes) |
| `minimumShardSizeBytes` | `4_000_000_000` | Minimum shard size (bytes) |

## Monitoring & Debugging

### Enable Detailed Logging

In `ModelDownloader.swift`, add after download:

```swift
private func downloadFile(...) {
    print("Starting download: \(fileName)")
    // ... existing code ...
}

func urlSession(_ session: URLSession,
                downloadTask: URLSessionDownloadTask,
                didWriteData bytesWritten: Int64,
                totalBytesWritten: Int64,
                totalBytesExpectedToWrite: Int64) {
    print("Downloaded \(fileName): \(totalBytesWritten)/\(totalBytesExpectedToWrite)")
}
```

### Check Model Status in Xcode Console

```swift
// Add to Xcode breakpoint action or print statements
let exists = ModelConfiguration.modelFilesExist()
let path = ModelConfiguration.modelDirectoryPath()
let usage = ModelConfiguration.modelDiskUsage()

print("Model exists: \(exists)")
print("Model path: \(path)")
print("Model size: \(usage ?? 0) bytes")
```

## Next Steps

1. **Edit `ModelConfiguration.swift`** with your HF repo ID
2. **Create your HF repository** following [HUGGINGFACE_MODEL_SETUP.md](./HUGGINGFACE_MODEL_SETUP.md)
3. **Upload model files** to Hugging Face
4. **Update `MediScribeApp.swift`** with integration pattern of your choice
5. **Test on device** with real model files
6. **Deploy!**

## Support

- **Setup issues**: See [HUGGINGFACE_MODEL_SETUP.md](./HUGGINGFACE_MODEL_SETUP.md)
- **Integration issues**: See CLAUDE.md for architecture
- **Model issues**: See Domain/ML components for MLX integration
