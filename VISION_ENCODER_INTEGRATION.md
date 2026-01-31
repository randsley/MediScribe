# Vision Encoder Integration Guide

**Status**: Waiting for MLX-Swift library updates
**Last Updated**: 2026-01-31

## Overview

This document describes how to integrate MLX-Swift's vision encoder support into MediScribe when the library is updated to support vision-language inference.

## Current Architecture

### 1. Image Preprocessing Pipeline (Ready)

Location: `Domain/ML/MLXModelLoader.swift` (lines 325-350)

```swift
// MLXModelBridge.generateWithImage() method includes:
- UIImage(data:) conversion
- Image validation via cgImage property
- TODO: Image resizing to 448x448
- TODO: RGB pixel array conversion via UIImage+RGB.swift
```

### 2. Vision-Language Inference Methods (Stubbed)

Location: `Domain/ML/MLXModelBridge.swift`

**Methods ready for integration:**
- `generateWithImage(imageData:prompt:maxTokens:temperature:)` → text generation
- `generateWithImageStreaming(...)` → token streaming

Both methods currently:
- ✅ Validate image can be loaded as UIImage
- ❌ TODO: Pass image through vision encoder
- ✅ Use text-only inference with image context
- ✅ Return generated text

## Integration Steps

### Step 1: Update MLX-Swift Package

When MLXSwift gains vision support:

```swift
// In Package.swift or via SPM
.package(url: "https://github.com/ml-explore/mlx-swift", from: "0.17.0") // or later with vision
```

Check the MLX-Swift release notes for:
- Vision encoder API (likely `MLX.Vision.ImageEncoder`)
- Expected input format (pixel arrays, tensor format)
- Output shape (embedding dimensions)

### Step 2: Implement Vision Image Encoding

**File**: `Domain/ML/MLXModelLoader.swift` (lines 340-350)

```swift
// REPLACE this stub:
// TODO: Pass through vision encoder to get image embeddings
// For now, use text-only inference with image context

// WITH:
// 1. Convert UIImage to tensor format
let imageTensor = try convertImageToTensor(imageData: imageData)

// 2. Pass through vision encoder
let imageEmbeddings = try encodeImage(tensor: imageTensor)

// 3. Concatenate with text tokens
let combinedInput = try concatenateEmbeddings(
    imageEmbeddings: imageEmbeddings,
    textTokens: inputIds
)

// 4. Run forward pass with combined input
let generatedIds = try inferenceLoop(
    inputIds: combinedInput,
    isVisionInput: true,
    maxNewTokens: maxTokens,
    temperature: temperature
)
```

### Step 3: Add Helper Methods

**Location**: `Domain/ML/MLXModelLoader.swift`

```swift
// Private helper functions to add:

/// Convert UIImage to tensor format expected by vision encoder
private static func convertImageToTensor(imageData: Data) throws -> MLXArray {
    guard let uiImage = UIImage(data: imageData) else {
        throw MLXModelError.invocationFailed("Failed to decode image")
    }

    // Resize to standard vision encoder input size (usually 448x448)
    guard let resized = uiImage.resized(to: CGSize(width: 448, height: 448)) else {
        throw MLXModelError.invocationFailed("Failed to resize image")
    }

    // Convert to RGB pixel array
    guard let (width, height, pixelData) = resized.toRGBData() else {
        throw MLXModelError.invocationFailed("Failed to convert to RGB")
    }

    // Normalize pixels to [0, 1] range
    var normalizedPixels = [Float]()
    let bytes = [UInt8](pixelData)
    for byte in bytes {
        normalizedPixels.append(Float(byte) / 255.0)
    }

    // Create MLX tensor: shape (height, width, channels)
    // MLX API may vary; check MLX-Swift documentation
    let tensor = try MLXArray(shape: [height, width, 3], elements: normalizedPixels)
    return tensor
}

/// Encode image using vision encoder
private static func encodeImage(tensor: MLXArray) throws -> MLXArray {
    // This assumes MLX-Swift provides Vision.ImageEncoder
    // API pattern may differ based on actual library

    let visionEncoder = try MLXVision.ImageEncoder(modelPath: modelPath)
    let embeddings = try visionEncoder.encode(tensor)

    return embeddings
}

/// Concatenate image embeddings with text token embeddings
private static func concatenateEmbeddings(
    imageEmbeddings: MLXArray,
    textTokenIds: [Int32]
) throws -> [Int32] {
    // Implementation depends on MedGemma's expected input format
    // Options:
    // 1. Prepend image embedding tokens to sequence
    // 2. Use special [IMG] tokens to mark image positions
    // 3. Interleave image and text embeddings

    // This is likely handled by MLX's vision-language module
    // Check MedGemma's implementation for expected format

    return textTokenIds  // Placeholder
}
```

### Step 4: Update Inference Loop for Vision

**Location**: `Domain/ML/MLXModelLoader.swift` (lines 521-570)

Modify `inferenceLoop` to handle vision inputs:

```swift
private static func inferenceLoop(
    inputIds: [Int32],
    isVisionInput: Bool = false,  // NEW parameter
    maxNewTokens: Int,
    temperature: Float
) throws -> [Int32] {
    // ... existing code ...

    for _ in 0..<maxNewTokens {
        do {
            // Vision-aware forward pass
            let lastLogits = if isVisionInput {
                try visionAwareModelForward(inputIds: generatedIds)
            } else {
                try simulateModelForward(inputIds: generatedIds)
            }

            // ... rest of loop ...
        }
    }
}

/// Vision-aware model forward pass
private static func visionAwareModelForward(inputIds: [Int32]) throws -> [[Float]] {
    guard let model = loadedModel else {
        throw MLXModelError.modelNotLoaded
    }

    // When vision encoder is available, use:
    // let output = try model.forward(inputIds: inputIds, hasVision: true)

    // For now, fallback to text-only
    return try simulateModelForward(inputIds: inputIds)
}
```

### Step 5: Testing

**New Test File**: `MediScribeTests/VisionEncoderIntegrationTests.swift`

```swift
import XCTest
@testable import MediScribe

class VisionEncoderIntegrationTests: XCTestCase {

    func testImageTensorConversion() {
        // Test UIImage → tensor conversion
        // Verify shape, dimensions, normalization
    }

    func testVisionEncoding() {
        // Test image encoder produces expected embedding
        // Verify embedding shape matches concatenation requirements
    }

    func testEmbeddingConcatenation() {
        // Test image and text embeddings combine correctly
        // Verify output shape for inference loop
    }

    func testVisionLanguageInference() {
        // End-to-end test with vision input
        // Verify model generates appropriate output
    }

    func testMemoryUsageWithVision() {
        // Verify image encoding doesn't exceed memory limits
        // Monitor memory during inference
    }
}
```

## Dependencies

### MLX-Swift Updates Needed

1. **Vision Encoder Module**
   - Class: `MLX.Vision.ImageEncoder` (or similar)
   - Method: `encode(_ image: MLXArray) -> MLXArray`
   - Input: RGB tensor (H, W, 3)
   - Output: Image embedding vector

2. **Tensor Operations**
   - `MLXArray.concatenate()` for combining embeddings
   - Shape inference for embedding dimensions

3. **MedGemma Vision Support**
   - Updated model weights with vision encoder
   - API for vision-aware forward pass

### Estimated MLX-Swift Version

Likely available in version **0.17.0** or later (check official releases)

## Performance Considerations

### Memory Usage

```
UIImage (original)         : ~10-20 MB
Resized to 448x448        : ~2-3 MB
Pixel normalization       : ~2-3 MB
Image embeddings          : ~1-2 MB
Text embeddings (seq)     : ~0.5-1 MB
Total peak memory         : ~3-5 MB additional
```

Target: Keep total inference memory under 3GB

### Inference Speed

- Image encoding: ~100-200ms (typically done once)
- Combined text+vision inference: ~150-300ms per token
- No significant regression vs text-only mode expected

## Rollback Plan

If vision integration causes issues:

1. The `isVisionInput` parameter allows fallback to text-only
2. `generateWithImage()` already handles errors gracefully
3. Views can automatically fallback if vision inference fails:

```swift
do {
    let result = try MLXModelBridge.generateWithImage(imageData:prompt:...)
} catch {
    // Fallback to text-only inference
    let result = try MLXModelBridge.generate(prompt:...)
}
```

## References

- MedGemma Model: https://github.com/google/medgemma
- MLX-Swift: https://github.com/ml-explore/mlx-swift
- MLX Vision Docs: (Check MLX documentation for vision module)

## Timeline

- **Phase 6 Current**: Text-only inference with image validation (complete)
- **Phase 6 Next**: Vision encoder integration (blocked on MLX-Swift updates)
- **Phase 7**: Production optimization and testing
- **Phase 8**: Advanced vision features (e.g., multi-image, cropping)

## Notes

- Monitor MLX-Swift releases for vision support
- Subscribe to repo notifications: https://github.com/ml-explore/mlx-swift/releases
- Contact MLX team if timeline needed for production
