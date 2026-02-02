# Model Installation Setup Checklist

Follow this checklist to get model downloads working in MediScribe.

## ✅ Phase 1: Prepare Hugging Face (15 minutes)

- [ ] Go to [huggingface.co](https://huggingface.co) and sign in (or create account)
- [ ] Go to [huggingface.co/new](https://huggingface.co/new) to create a new repository
- [ ] Fill in details:
  - [ ] Repository name: `mediscribe-medgemma-mlx` (or your preference)
  - [ ] Type: **Model**
  - [ ] License: Apache 2.0 (or your choice)
  - [ ] Private: Check if internal-only
  - [ ] Click **Create repository**
- [ ] Note your repository URL: `https://huggingface.co/{username}/{repo-name}`
- [ ] Copy your repo ID for later: `{username}/{repo-name}`

## ✅ Phase 2: Upload Model Files (1-2 hours)

- [ ] Have your MLX model files ready:
  - [ ] `config.json`
  - [ ] `tokenizer.json`
  - [ ] `model.safetensors.index.json`
  - [ ] `model-00001-of-00002.safetensors` (~5GB)
  - [ ] `model-00002-of-00002.safetensors` (~5GB)

### Using Hugging Face Web UI (Easiest)

- [ ] Go to your HF repo at `https://huggingface.co/{username}/{repo-name}`
- [ ] Click **Files and versions** tab
- [ ] Click **Upload file** button
- [ ] Upload files in this order:
  - [ ] 1. `config.json`
  - [ ] 2. `tokenizer.json`
  - [ ] 3. `model.safetensors.index.json`
  - [ ] 4. `model-00001-of-00002.safetensors` (HF will auto-use Git LFS)
  - [ ] 5. `model-00002-of-00002.safetensors` (HF will auto-use Git LFS)
- [ ] Wait for all uploads to complete
- [ ] Verify files appear in the repo

### OR Using Hugging Face CLI (For developers)

- [ ] Install CLI: `pip install huggingface-hub`
- [ ] Login: `huggingface-cli login`
- [ ] Enter your token from [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)
- [ ] Upload each file:
  ```bash
  huggingface-cli upload {username}/{repo-name} config.json config.json
  huggingface-cli upload {username}/{repo-name} tokenizer.json tokenizer.json
  huggingface-cli upload {username}/{repo-name} model.safetensors.index.json model.safetensors.index.json
  huggingface-cli upload {username}/{repo-name} model-00001-of-00002.safetensors model-00001-of-00002.safetensors
  huggingface-cli upload {username}/{repo-name} model-00002-of-00002.safetensors model-00002-of-00002.safetensors
  ```
- [ ] Wait for uploads to complete

## ✅ Phase 3: Configure MediScribe (5 minutes)

- [ ] Open Xcode and load `MediScribe.xcodeproj`
- [ ] Open file: `Domain/ML/ModelConfiguration.swift`
- [ ] Edit this line (around line 13):
  ```swift
  static let huggingFaceRepositoryId = "your-username/mediscribe-medgemma-mlx"
  ```
  Replace with your actual repo ID from Phase 1
- [ ] Optional: Change revision if not using "main":
  ```swift
  static let huggingFaceRevision = "v1.0"  // or your tag
  ```
- [ ] Save file (⌘S)

## ✅ Phase 4: Integrate Into App (10 minutes)

Choose one integration pattern:

### Option A: Show Setup Screen (Recommended for first-run)

- [ ] Open `MediScribeApp.swift`
- [ ] Add this code to check model on launch:
  ```swift
  @State private var modelIsReady = false

  var body: some Scene {
      WindowGroup {
          if modelIsReady {
              RootView()
          } else {
              ModelSetupView()
                  .onAppear {
                      if ModelConfiguration.modelFilesExist() {
                          modelIsReady = true
                      }
                  }
          }
      }
  }
  ```
- [ ] Save file

### Option B: Background Download (Continue to main app immediately)

- [ ] Open `MediScribeApp.swift`
- [ ] Add this code:
  ```swift
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

      let config = ModelConfiguration.createHFConfig()
      ModelDownloader.shared.configure(with: config)

      ModelDownloader.shared.downloadModel(
          to: ModelConfiguration.modelDirectoryPath(),
          progressCallback: { _ in },
          completion: { _ in }
      )
  }
  ```
- [ ] Save file

### Option C: Settings UI (For manual download)

- [ ] Open `SettingsView.swift`
- [ ] Add this section:
  ```swift
  Section("Model") {
      if ModelConfiguration.modelFilesExist() {
          Label("Model Ready", systemImage: "checkmark.circle.fill")
      } else {
          Button("Download Model", action: {
              // Show ModelSetupView in sheet
          })
      }
  }
  ```
- [ ] Save file

## ✅ Phase 5: Test on Simulator (5 minutes)

- [ ] In Xcode, select simulator target (iPhone 15 or similar)
- [ ] Build and run (⌘R)
- [ ] Observe:
  - [ ] App launches without model
  - [ ] Uses placeholder model (no actual download)
  - [ ] Test imaging/lab features work (with placeholder)
  - [ ] App does not crash

## ✅ Phase 6: Test on Device (1+ hour)

- [ ] Connect Apple Silicon device (iPhone 15+, iPad Pro M1+)
- [ ] Build and run to device (⌘R)
- [ ] Observe first launch:
  - [ ] ModelSetupView appears
  - [ ] "Download Model" button visible
  - [ ] App shows estimated size (~10GB)

- [ ] Tap "Download Model"
  - [ ] Download starts
  - [ ] Progress bar shows current file and percentage
  - [ ] Monitor in Xcode console:
    ```
    Downloading config.json: 100%
    Downloading tokenizer.json: 100%
    Downloading model.safetensors.index.json: 100%
    Downloading model-00001-of-00002.safetensors: 45% ...
    ```
  - [ ] Download may take 30-60 minutes depending on network

- [ ] After download completes:
  - [ ] App shows "Model Ready" with checkmark
  - [ ] Tap "Continue"
  - [ ] RootView appears
  - [ ] Imaging/lab features use real model (not placeholder)

- [ ] Test offline operation:
  - [ ] Put device in Airplane mode
  - [ ] Kill and relaunch app
  - [ ] Model loads from local storage
  - [ ] Inference works completely offline
  - [ ] Turn Airplane mode off

## ✅ Phase 7: Test Error Scenarios (Optional but recommended)

- [ ] Test retry on network failure:
  - [ ] Start download
  - [ ] Disconnect from WiFi mid-download
  - [ ] Tap "Retry Download"
  - [ ] Download resumes and completes

- [ ] Test cancel:
  - [ ] Start download
  - [ ] Tap "Cancel Download"
  - [ ] Verify no partial files remain
  - [ ] Can restart fresh download

- [ ] Test disk space warning:
  - [ ] Fill device to < 15GB free
  - [ ] Try to download
  - [ ] Should show "Insufficient disk space" error

## ✅ Phase 8: Verify Production Build (5 minutes)

- [ ] Build Release configuration:
  ```bash
  xcodebuild -project MediScribe.xcodeproj -scheme MediScribe -configuration Release build
  ```
- [ ] Verify no warnings or errors
- [ ] Check app size: `ls -lh build/Release-iphoneos/MediScribe.app/`
  - [ ] Should NOT include model files (they download separately)

## ✅ Phase 9: Document Your Setup (5 minutes)

- [ ] Record your settings somewhere:
  - [ ] HF repo URL: `https://huggingface.co/{your-repo-url}`
  - [ ] Repo ID: `{your-repo-id}`
  - [ ] Model version/tag: (e.g., "main" or "v1.0")
  - [ ] Upload date: ___________

- [ ] Create a team wiki/doc with:
  - [ ] How to update model (upload new files to HF)
  - [ ] How to deploy new version (update tag in ModelConfiguration)
  - [ ] Support contacts for model issues

## ✅ Phase 10: Commit Your Changes (5 minutes)

- [ ] Review changes:
  ```bash
  git status
  ```
  Should show modified:
  - [ ] `Domain/ML/ModelConfiguration.swift` (you edited this)
  - [ ] `MediScribeApp.swift` (integration code)
  - [ ] Other files you modified

- [ ] Commit:
  ```bash
  git add Domain/ML/ModelConfiguration.swift MediScribeApp.swift [other files]
  git commit -m "feat: Add Hugging Face model download integration"
  ```

- [ ] Push (if using remote):
  ```bash
  git push origin main
  ```

## ✅ Done! 🎉

Your MediScribe app now has:
- ✅ Automatic model download on first launch
- ✅ Progress tracking UI
- ✅ Error handling and retry
- ✅ Offline operation after download
- ✅ Simulator support for development

## Troubleshooting

**Problem**: App shows "Model not found" after what appeared to be successful download

**Solution**:
- [ ] Verify all files in HF repo:
  ```
  https://huggingface.co/{username}/{repo}/blob/main
  ```
- [ ] Check file sizes are correct (~5GB per shard)
- [ ] Delete local model: `rm -rf ~/MediScribe/models/`
- [ ] Relaunch app and re-download

**Problem**: Download times out or fails

**Solution**:
- [ ] Check internet connection (not WiFi issue)
- [ ] Verify HF repo is public or you have access token
- [ ] Check free disk space: `df -h` (need 15GB)
- [ ] Try again with better network (5G or wired)

**Problem**: Can't find ModelConfiguration.swift

**Solution**:
- [ ] In Xcode, use ⌘O (Open Quickly)
- [ ] Search: "ModelConfiguration"
- [ ] Open the file

**Problem**: ModelSetupView shows "Cannot find type"

**Solution**:
- [ ] Build project once: ⌘B
- [ ] Wait for indexing to complete
- [ ] Close and reopen Xcode if needed

## Need Help?

- **HF Repo Setup**: See [HUGGINGFACE_MODEL_SETUP.md](./HUGGINGFACE_MODEL_SETUP.md)
- **Integration Details**: See [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md)
- **Architecture**: See [CLAUDE.md](./CLAUDE.md)
- **Error Handling**: See specific troubleshooting section in this file

---

**Estimated Total Time**: 2-3 hours (mostly waiting for download)

**Latest Update**: 2026-02-02
