# Adding mlx-swift-lm Package to Xcode

**Status**: Ready to add during model download
**Estimated time**: 5-10 minutes
**Target**: MediScribe iOS app

## Step-by-Step Instructions

### Step 1: Open Xcode Project

```bash
open /Users/nigelrandsley/MediScribe.xcodeproj
```

### Step 2: Navigate to Package Dependencies

1. **In Xcode menu bar**: File → Add Packages...
   - Or use keyboard shortcut: `⌘ + ⌧` (Cmd + Shift + A)

2. You should see the "Add Package" dialog

### Step 3: Add mlx-swift-lm

1. **In the search/URL field** at the top, paste:
   ```
   https://github.com/ml-explore/mlx-swift-lm.git
   ```

2. **Wait for Xcode to resolve** the repository (takes ~10-30 seconds)

3. Once resolved, you should see:
   - Package: `mlx-swift-lm`
   - Repository: `ml-explore/mlx-swift-lm`

### Step 4: Configure Dependency Settings

1. **Dependency Rule**: Select "Branch" → "main"
   - (or use the latest stable release tag if available)

2. **Add to**: Select "MediScribe" target
   - Ensure ONLY "MediScribe" is checked
   - Do NOT add to test targets

3. Click **"Add Package"**

### Step 5: Xcode Resolution

Xcode will now:
1. Clone the mlx-swift-lm repository
2. Resolve all transitive dependencies
3. Download necessary packages
4. Build dependencies (first time only)

**This may take 5-15 minutes the first time**

### Step 6: Verification

After completion:
1. Check the Project Navigator (left sidebar)
2. Expand "Package Dependencies"
3. You should see:
   - `mlx-swift-lm` ✅
   - `mlx-swift` (transitive dependency)
   - Other dependencies

4. Build the project: `⌘ + B`
   - Should build without errors

## Build Output

Once added successfully, you should see in the build log:

```
Building for production...
Compiling ... mlx-swift-lm/MLXVLM.swift
Compiling ... mlx-swift/MLX.swift
Linking MediScribe
Build complete!
```

## Troubleshooting

### Issue: "Cannot find the repository"

**Solution**:
- Verify internet connection
- Try again with exact URL: `https://github.com/ml-explore/mlx-swift-lm.git`
- Clear Xcode cache: `rm -rf ~/Library/Caches/com.apple.dt.Xcode`

### Issue: "Build fails after adding package"

**Solution**:
- Run: `File → Packages → Reset Package Caches`
- Clean build folder: `⌘ + Shift + K`
- Re-build: `⌘ + B`

### Issue: "Duplicate module" errors

**Solution**:
- Check that mlx-swift and mlx-swift-lm aren't both directly added
- mlx-swift should be a transitive dependency
- Remove any direct mlx-swift dependency

## Alternative: Manual Package.swift Edit

If the UI method doesn't work, you can manually edit Package.swift:

```swift
let package = Package(
    // ... existing config ...
    dependencies: [
        // ... existing deps ...
        .package(url: "https://github.com/ml-explore/mlx-swift-lm.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MediScribe",
            dependencies: [
                // ... existing deps ...
                .product(name: "MLXVLM", package: "mlx-swift-lm"),
            ]
        ),
        // ... other targets ...
    ]
)
```

Then run: `File → Packages → Reset Package Caches`

## Expected Package Contents

Once added, mlx-swift-lm provides:

- **MLXVLM** product:
  - Vision-language model APIs
  - Image encoding
  - Multimodal inference

- **MLX** product (transitive):
  - Core ML operations
  - Tensor operations
  - Metal GPU acceleration

## Integration with MediScribe Code

Once added, MLXMedGemmaBridge can import and use:

```swift
import MLXVLM
import MLX

// Now available in MLXMedGemmaBridge.swift:
// - MLXVLM.load(modelPath:, modelType:, quantization:)
// - MLXVLM.generateStreaming(...)
// - Vision encoder APIs
// - Multimodal inference methods
```

## Build System Integration

After successful addition:
- The build system automatically includes mlx-swift-lm headers
- No additional import statements needed in project files
- Xcode handles symbol resolution
- Metal GPU acceleration is automatically enabled on Apple Silicon

## Next Steps After Package Addition

Once the package is successfully added:

1. ✅ Package should be discoverable in code
2. ✅ IDE should provide autocomplete for MLXVLM APIs
3. ⏳ Wait for MedGemma model download (10-40 minutes)
4. 🔄 Convert model to MLX format
5. ✅ Run tests to verify integration

## Time Breakdown

| Task | Duration |
|------|----------|
| Adding package via UI | 5-10 min |
| Xcode SPM resolution | 5-15 min |
| First build with package | 10-20 min |
| **Total** | **20-45 min** |

---

**Status**: Ready to proceed
**Note**: Model download happens in parallel - no need to wait for it
