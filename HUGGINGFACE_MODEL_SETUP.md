# MediScribe Model Setup with Hugging Face

This guide walks you through setting up the MedGemma MLX model for MediScribe using Hugging Face as the distribution platform.

## Overview

MediScribe downloads the MedGemma-1.5-4b multimodal model from Hugging Face Hub on first app launch. The model files are approximately 10 GB and are stored locally on the device for offline operation.

## Step 1: Prepare Your Hugging Face Repository

### 1.1 Create a Hugging Face Account
If you don't have one, sign up at [huggingface.co](https://huggingface.co)

### 1.2 Create a New Repository
1. Go to [huggingface.co/new](https://huggingface.co/new)
2. Fill in the repository details:
   - **Repository name**: `mediscribe-medgemma-mlx` (or similar)
   - **Organization**: Your username (or organization)
   - **Type**: Model
   - **License**: Choose appropriate license (e.g., Apache 2.0, MIT)
   - **Private**: Recommended if this is for internal/organizational use only
   - Click **Create repository**

Your repository URL will be: `https://huggingface.co/{username}/mediscribe-medgemma-mlx`

### 1.3 Prepare Model Files

You should have the following MLX-converted model files:
```
medgemma-1.5-4b-it-mlx/
├── config.json                          # Model configuration
├── tokenizer.json                       # BPE tokenizer vocabulary
├── model.safetensors.index.json        # Sharded model index
├── model-00001-of-00002.safetensors    # Model weights shard 1 (~5GB)
└── model-00002-of-00002.safetensors    # Model weights shard 2 (~5GB)
```

**If you need to convert the model to MLX format**, see the MLX documentation:
- [MLX GitHub](https://github.com/ml-explore/mlx)
- [MLX Gemma Port](https://github.com/ml-explore/mlx-swift-gemma-port)

## Step 2: Upload Model to Hugging Face

### Option A: Using Hugging Face Web Interface (Recommended for first upload)

1. Go to your repository: `https://huggingface.co/{username}/mediscribe-medgemma-mlx`
2. Click **Files and versions** tab
3. Click **Upload file** button
4. Drag and drop or select the following files in order:
   - `config.json` (small, upload first)
   - `tokenizer.json` (small, ~500KB)
   - `model.safetensors.index.json` (small, upload early)
   - `model-00001-of-00002.safetensors` (~5GB, use Git LFS)
   - `model-00002-of-00002.safetensors` (~5GB, use Git LFS)

**Note**: Hugging Face automatically uses Git LFS for files >5GB. No action needed on your part.

### Option B: Using Hugging Face CLI (For updates/automation)

First, install the Hugging Face Hub CLI:
```bash
pip install huggingface-hub
```

Authenticate with your token:
```bash
huggingface-cli login
# Follow the prompts and enter your token from https://huggingface.co/settings/tokens
```

Upload files using the CLI:
```bash
huggingface-cli upload {username}/mediscribe-medgemma-mlx \
    config.json config.json
huggingface-cli upload {username}/mediscribe-medgemma-mlx \
    tokenizer.json tokenizer.json
huggingface-cli upload {username}/mediscribe-medgemma-mlx \
    model.safetensors.index.json model.safetensors.index.json
huggingface-cli upload {username}/mediscribe-medgemma-mlx \
    model-00001-of-00002.safetensors model-00001-of-00002.safetensors
huggingface-cli upload {username}/mediscribe-medgemma-mlx \
    model-00002-of-00002.safetensors model-00002-of-00002.safetensors
```

### Option C: Using Git + Git LFS (For developers familiar with git)

```bash
# Clone the repository
git clone https://huggingface.co/{username}/mediscribe-medgemma-mlx
cd mediscribe-medgemma-mlx

# Initialize Git LFS for large files
git lfs install
git lfs track "*.safetensors"

# Copy your model files into the directory
cp /path/to/your/model/files/* .

# Commit and push
git add .
git commit -m "Add MedGemma MLX model files"
git push
```

## Step 3: Configure MediScribe

### 3.1 Update Model Configuration

In your MediScribe app code, configure the model downloader with your Hugging Face repository:

**In AppDelegate or app initialization code:**
```swift
import Foundation

// Configure the model downloader with your HF repo
let config = HFModelConfig(
    repositoryId: "your-username/mediscribe-medgemma-mlx"
    // Optional: specify a branch/revision other than "main"
    // revision: "v1.0"  // or any git ref/tag
)
ModelDownloader.shared.configure(with: config)
```

### 3.2 Integrate First-Run Setup

In your `MediScribeApp` or main view initialization:

```swift
@main
struct MediScribeApp: App {
    @State private var showModelSetup = false
    @State private var modelIsReady = false

    var body: some Scene {
        WindowGroup {
            if modelIsReady {
                RootView()
            } else {
                ModelSetupView()
                    .onAppear {
                        checkModelStatus()
                    }
            }
        }
    }

    private func checkModelStatus() {
        let modelPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "") +
            "/../MediScribe/models/medgemma-1.5-4b-it-mlx"

        if ModelDownloader.shared.modelFilesExist(at: modelPath) {
            modelIsReady = true
        } else {
            showModelSetup = true
        }
    }
}
```

### 3.3 Environment Configuration (Optional)

For development/testing, you can override the repository in different environments:

**Development (Firebase config/plist):**
```
HF_MODEL_REPO = "your-username/mediscribe-medgemma-mlx-dev"
```

**Production:**
```
HF_MODEL_REPO = "your-username/mediscribe-medgemma-mlx"
```

## Step 4: Test the Integration

### Test on Device
1. Install MediScribe on a device with Apple Silicon (iPhone 15+ or iPad Pro M-series)
2. Launch the app
3. You should see the **Model Setup** screen
4. Tap **Download Model**
5. Monitor the download progress (10+ GB will take 30-60 minutes on typical network)
6. Once complete, the app will proceed to the main interface

### Test on Simulator
- The simulator will use placeholder model responses
- No actual download occurs on simulator
- Useful for testing UI without downloading 10GB

### Offline Testing
After the first download completes on a device:
1. Disconnect from network (airplane mode or WiFi off)
2. Relaunch the app
3. The model should load from local storage and work normally

## Troubleshooting

### Download Fails with "Network Error"

**Check:**
- Internet connection is stable
- Repository ID is correct (`{username}/{repo-name}`)
- No corporate firewall blocking Hugging Face CDN
- Device has sufficient storage (need 15GB free)

**Solution:**
- The app allows resuming interrupted downloads
- Tap "Retry Download" to restart from where it failed

### Model Loads but Inference Fails

**Check:**
- All required files exist:
  - `config.json` ✓
  - `tokenizer.json` ✓
  - `model.safetensors.index.json` ✓
  - `model-00001-of-00002.safetensors` ✓
  - `model-00002-of-00002.safetensors` ✓
- Model file shards are fully downloaded (~5GB each minimum)

**Verify:**
```bash
# On your development machine:
ls -lah ~/MediScribe/models/medgemma-1.5-4b-it-mlx/
# Each shard should show ~5GB or larger
```

### Model Path Not Found

Check that the model directory is at the expected location:
- Development machines: `~/MediScribe/models/medgemma-1.5-4b-it-mlx/`
- iOS devices: App documents folder equivalent

The app will automatically create the directory if it doesn't exist.

## Updating the Model

### When Releasing a New Model Version

1. Upload new model files to Hugging Face (same steps as Step 2)
2. Create a git tag/release on Hugging Face (optional but recommended)
3. Users will be prompted to download the update on next app launch

### Versioning Strategy (Recommended)

Use git tags for version management:

```bash
# Create a version tag
git tag -a v1.0 -m "MedGemma MLX v1.0 release"
git push origin v1.0

# In app code, specify the version:
let config = HFModelConfig(
    repositoryId: "your-username/mediscribe-medgemma-mlx",
    revision: "v1.0"  // Downloads from the v1.0 tag
)
```

## File Size Reference

| File | Size | Notes |
|------|------|-------|
| config.json | ~2 KB | Model architecture config |
| tokenizer.json | ~500 KB | BPE vocabulary |
| model.safetensors.index.json | ~50 KB | Shard index |
| model-00001-of-00002.safetensors | ~5 GB | Model weights shard 1 |
| model-00002-of-00002.safetensors | ~5 GB | Model weights shard 2 |
| **Total** | **~10 GB** | Approximate download size |

## Security Considerations

### Private Repository
If your model is proprietary or internal-only:
1. Set repository to **Private** on Hugging Face
2. Provide access token to app (optional, for private repos)
3. Document access requirements for deployment

### Model Integrity
The current implementation downloads from Hugging Face public URLs without signature verification. For production/regulated environments:
- Consider adding SHA256 checksum verification
- Implement signed release process
- Document model provenance and review process

### HIPAA/Compliance
If deploying in regulated healthcare settings:
- Ensure model files are downloaded over HTTPS (Hugging Face provides this by default)
- Implement additional logging for audit trails
- Document data handling procedures in compliance documentation

## Architecture Details

### Download Flow

```
App Launch
    ↓
Check local model files
    ├─ Files exist? → Load from disk → Continue to main app
    └─ Files missing? → Show ModelSetupView
                           ↓
                        Download via ModelDownloader
                           ↓
                        HF Hub CDN
                           ↓
                        Store in ~/MediScribe/models/
                           ↓
                        Verify file integrity
                           ↓
                        Load model → Continue to main app
```

### Configuration Structure

```swift
struct HFModelConfig {
    let repositoryId: String      // "username/repo-name"
    let modelPath: String         // Subdirectory in repo (default: root)
    let revision: String          // Git ref: "main", "v1.0", etc.
}
```

### Download Progress Tracking

The `ModelDownloader` provides per-file progress updates:
- File name being downloaded
- Bytes downloaded
- Total bytes expected
- Percentage complete (0.0-1.0)

UI uses this to show:
- Current file name
- Overall progress bar
- Download percentage

## Next Steps

1. **Create your HF repository** (Step 1)
2. **Upload model files** (Step 2)
3. **Update app configuration** with your repo ID (Step 3)
4. **Test on device** (Step 4)
5. **Deploy with confidence!**

## Support

For issues with:
- **Hugging Face**: See [Hugging Face Documentation](https://huggingface.co/docs)
- **MLX Model Conversion**: See [MLX GitHub](https://github.com/ml-explore/mlx)
- **MediScribe Integration**: Check CLAUDE.md and Domain/ML components

## References

- [Hugging Face Hub Documentation](https://huggingface.co/docs/hub)
- [Hugging Face Hub Python Library](https://huggingface.co/docs/huggingface_hub/main)
- [Git LFS Documentation](https://git-lfs.github.com/)
- [MLX Swift](https://github.com/ml-explore/mlx-swift)
- [MediScribe CLAUDE.md](./CLAUDE.md)
