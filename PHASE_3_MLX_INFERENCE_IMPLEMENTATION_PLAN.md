# Phase 3: Real MLX Inference Implementation Plan

**Date**: February 4, 2026
**Status**: Ready to implement
**Estimated Duration**: 7-12 hours (1-2 days)
**Priority**: CRITICAL - Blocks production readiness

---

## Overview

Phase 3 implements the missing real MLX inference that Phase 2 discovered is not yet functional.

### Current State
- ✅ Model bundled with app (2.8 GB)
- ✅ MLX imports active on device
- ✅ Build succeeds
- ❌ **Inference methods are stubs (return random garbage)**
- ❌ Validation correctly rejects invalid output
- ❌ User gets "Model inference failed" error

### Goal
Replace stub implementations with real MLX model.forward() calls so inference produces valid medical text.

---

## Implementation Tasks

### Task 1: Implement Vision Image Encoder (encodeImage)

**Current State**:
```swift
// File: MLXMedGemmaBridge.swift, line 418
private func encodeImage(_ image: UIImage) throws -> [[Float]] {
    // Placeholder: returns simulated embeddings
    return [[Float.random(in: 0...1)]]
}
```

**What It Needs to Do**:
1. Convert UIImage to tensor format (NCHW or NHWC)
2. Run through SigLIP vision encoder
3. Return vision embeddings [num_patches, vision_dim]

**Implementation Steps**:

**Step 1a: Convert UIImage to Tensor**
```swift
// Convert to CGImage
let cgImage = image.cgImage!

// Get pixel data
let bytesPerPixel = 4
let bytesPerRow = cgImage.bytesPerRow
let width = cgImage.width
let height = cgImage.height

// Create tensor [height, width, 3] (RGB)
let pixels = try convertImageToRGBTensor(cgImage)  // [H, W, 3]

// Resize to vision encoder input size (usually 384x384 for SigLIP)
let resized = try resizeImage(pixels, to: (384, 384))  // [384, 384, 3]

// Normalize: (pixel - mean) / std
let normalized = try normalizeImageTensor(resized)  // [384, 384, 3]

// Convert to model input shape [1, 3, 384, 384] (batch, channels, H, W)
let input = try transpose(normalized)  // [1, 3, 384, 384]
```

**Step 1b: Create Vision Encoder Module**
```swift
// Need to load vision encoder from model files
// MedGemma has separate vision_encoder.safetensors

let visionEncoderPath = (modelPath as NSString)
    .appendingPathComponent("vision_encoder.safetensors")

// Load via MLX (requires mlx-swift-gemma-port's vision loader)
let visionEncoder = try VisionEncoderFactory.load(
    from: visionEncoderPath,
    modelType: .sigLIP  // SigLIP for Gemma3
)
```

**Step 1c: Run Vision Encoder**
```swift
// Forward pass through vision encoder
let visionOutput = try visionEncoder.forward(input)  // [1, num_patches, vision_dim]

// Extract embeddings [num_patches, vision_dim]
let embeddings = try visionOutput.squeezed(dim: 0)

// Return as [[Float]]
return embeddings.converted(to: [[Float]].self)
```

**Success Criteria**:
- ✅ Takes UIImage input
- ✅ Returns [[Float]] embeddings
- ✅ Shape: [576, 768] (typical: 24x24 patches, 768 dim)
- ✅ Values are real (not random)

**Estimated Time**: 2-3 hours

---

### Task 2: Implement Tokenization (tokenizePrompt)

**Current State**:
```swift
// File: MLXMedGemmaBridge.swift, line 458
private func tokenizePrompt(_ prompt: String) throws -> [Int32] {
    // Placeholder: returns random token IDs
    return (0..<prompt.count).map { _ in Int32.random(in: 0..<256000) }
}
```

**What It Needs to Do**:
1. Take text prompt string
2. Run through BPE tokenizer
3. Return token IDs [seq_len]

**Implementation Steps**:

**Step 2a: Verify Tokenizer Loaded**
```swift
// Tokenizer already loaded in loadTokenizer()
// Access it from model info
guard let tokenizerData = self.vlmModel as? [String: Any],
      let tokenizer = tokenizerData["tokenizer"] as? [String: Any] else {
    throw MLXModelError.tokenizerNotLoaded
}
```

**Step 2b: Implement BPE Tokenization**
```swift
// Extract tokenizer components from JSON
let vocab = tokenizer["vocab"] as? [String: Int]  // token_string -> token_id
let merges = tokenizer["merges"] as? [[String]]   // BPE merge rules
let specialTokens = tokenizer["special_tokens_map"] as? [String: String]

// Implement BPE algorithm:
// 1. Split text into characters
// 2. Apply merge rules iteratively
// 3. Look up final subwords in vocab

func tokenizeBPE(_ text: String, vocab: [String: Int], merges: [[String]]) -> [Int32] {
    // Lowercase and normalize
    var text = text.lowercased()

    // Split into characters: "hello" -> ["h", "e", "l", "l", "o"]
    var subwords = text.map { String($0) }

    // Apply BPE merges (iteratively combine most frequent pairs)
    for merge in merges {
        guard merge.count == 2 else { continue }
        let pair = merge[0] + merge[1]

        // Find and merge all occurrences
        subwords = mergeBPEPair(subwords, from: merge[0], to: merge[1], result: pair)
    }

    // Look up token IDs
    var tokenIds: [Int32] = []
    for subword in subwords {
        if let tokenId = vocab[subword] {
            tokenIds.append(Int32(tokenId))
        } else {
            // Unknown token
            tokenIds.append(Int32(vocab["<unk>"] ?? 0))
        }
    }

    return tokenIds
}
```

**Step 2c: Handle Special Tokens**
```swift
// Add special tokens for chat format (Gemma3 uses specific format)
var tokenIds = tokenizeBPE(prompt, vocab: vocab, merges: merges)

// Prepend <bos> if needed
if let bosTokenId = vocab["<bos>"] {
    tokenIds.insert(Int32(bosTokenId), at: 0)
}

// Append <eos> if needed
if let eosTokenId = vocab["<eos>"] {
    tokenIds.append(Int32(eosTokenId))
}

return tokenIds
```

**Success Criteria**:
- ✅ Takes text string input
- ✅ Returns [Int32] token IDs
- ✅ Length matches expected (typically prompt.count * 1.3 for BPE)
- ✅ Token IDs are valid (0 to vocab_size)
- ✅ Consistent (same input → same output)

**Estimated Time**: 1-2 hours

---

### Task 3: Implement Autoregressive Generation (runGenerativeInference)

**Current State**:
```swift
// File: MLXMedGemmaBridge.swift, line 495
private func runGenerativeInference(
    visionEmbeddings: [[Float]],
    promptTokens: [Int32],
    maxTokens: Int,
    temperature: Float
) throws -> String {
    // Placeholder: random garbage
    var generatedText = ""
    for _ in 0..<maxTokens {
        let nextToken = Int32.random(in: 0..<256000)
        if let scalar = UnicodeScalar(Int(nextToken)),
           let decodedChar = String(scalar) as String? {
            generatedText += decodedChar
        }
    }
    return generatedText
}
```

**What It Needs to Do**:
1. Take vision embeddings + prompt tokens
2. Iteratively predict next tokens
3. Accumulate into output text
4. Return final text string

**Implementation Steps**:

**Step 3a: Project Vision Embeddings**
```swift
// Vision embeddings [num_patches, vision_dim] need to be
// projected to language model embedding space [num_patches, language_dim]

// Get projection matrix from model
let projectionMatrix = try model.getProjectionMatrix()  // [vision_dim, language_dim]

// Project embeddings
var projectedEmbeddings = try projectTensor(
    visionEmbeddings,
    with: projectionMatrix
)  // [num_patches, language_dim]
```

**Step 3b: Prepare Input Sequence**
```swift
// Combine vision embeddings with text tokens:
// 1. Convert text tokens to embeddings
// 2. Concatenate [vision_embeddings; token_embeddings]

let textEmbeddings = try model.embed(promptTokens)  // [seq_len, language_dim]

// Concatenate: [vision (576, dim); text (prompt_len, dim)]
var inputSequence = try concatenate(
    [projectedEmbeddings, textEmbeddings],
    dim: 0
)  // [576 + prompt_len, language_dim]

var generatedTokens = promptTokens  // Keep track of generated sequence
```

**Step 3c: Autoregressive Generation Loop**
```swift
var generatedText = ""
let startLen = inputSequence.shape[0]

for i in 0..<maxTokens {
    // Forward pass: get logits for last token position
    let logits = try model.forward(
        input: inputSequence,
        attention_mask: nil,
        past: nil  // Or use KV cache if available
    )  // [seq_len, vocab_size]

    // Get logits only for last token position (most efficient)
    let lastLogits = logits[-1, :]  // [vocab_size]

    // Sample next token
    let nextToken = try sampleToken(
        logits: lastLogits,
        temperature: temperature,
        topK: 50,
        topP: 0.9
    )

    // Check for end-of-sequence
    if nextToken == 2 {  // EOS token
        break
    }

    // Decode token to text
    if let decodedText = try tokenizer.decode([nextToken]) {
        generatedText += decodedText
    }

    // Add to sequence for next iteration
    generatedTokens.append(nextToken)

    // Add token embedding to input sequence
    let nextEmbedding = try model.embed([nextToken])
    inputSequence = try concatenate([inputSequence, nextEmbedding], dim: 0)
}

return generatedText.trimmingCharacters(in: .whitespaces)
```

**Step 3d: Token Sampling (Critical for Quality)**
```swift
// Implement proper sampling (not just argmax)
func sampleToken(
    logits: [Float],
    temperature: Float,
    topK: Int,
    topP: Float
) throws -> Int32 {
    // Apply temperature scaling
    let scaledLogits = logits.map { $0 / temperature }

    // Apply softmax
    let maxLogit = scaledLogits.max() ?? 0
    let expLogits = scaledLogits.map { exp($0 - maxLogit) }
    let sumExp = expLogits.reduce(0, +)
    var probs = expLogits.map { $0 / sumExp }

    // Top-K filtering
    let topKIndices = probs.enumerated()
        .sorted { $0.element > $1.element }
        .prefix(topK)
        .map { $0.offset }

    // Renormalize
    let topKProbs = topKIndices.map { probs[$0] }
    let sumTopKProbs = topKProbs.reduce(0, +)
    var normalizedProbs = topKProbs.map { $0 / sumTopKProbs }

    // Multinomial sampling
    var cumulativeProb: Float = 0
    let rand = Float.random(in: 0..<1)

    for (idx, prob) in zip(topKIndices, normalizedProbs) {
        cumulativeProb += prob
        if rand < cumulativeProb {
            return Int32(idx)
        }
    }

    // Fallback (shouldn't reach)
    return Int32(topKIndices.first ?? 0)
}
```

**Success Criteria**:
- ✅ Takes vision embeddings + prompt tokens
- ✅ Generates tokens autoregressively
- ✅ Returns valid medical text (not garbage)
- ✅ Respects max tokens
- ✅ Stops on EOS token
- ✅ Takes 1-2 seconds (device inference time)
- ✅ Output is coherent and valid

**Estimated Time**: 2-3 hours

---

### Task 4: Implement Streaming Generation

**Current State**:
```swift
// File: MLXMedGemmaBridge.swift, line 537
private func runGenerativeInferenceStreaming(...) async throws {
    // Placeholder
}
```

**What It Needs to Do**:
1. Same as Task 3, but yield tokens as generated
2. Call onToken callback for each token
3. Enable real-time UI updates

**Implementation**:
```swift
private func runGenerativeInferenceStreaming(
    visionEmbeddings: [[Float]],
    promptTokens: [Int32],
    maxTokens: Int,
    temperature: Float,
    onToken: @escaping (String) -> Void
) async throws {
    // Same setup as runGenerativeInference
    let projectedEmbeddings = try projectTensor(visionEmbeddings, ...)
    let textEmbeddings = try model.embed(promptTokens)
    var inputSequence = try concatenate([projectedEmbeddings, textEmbeddings], dim: 0)
    var generatedTokens = promptTokens

    // Generation loop (same as Task 3, but with callback)
    for i in 0..<maxTokens {
        let logits = try model.forward(input: inputSequence, ...)
        let nextToken = try sampleToken(logits[-1, :], temperature: temperature, ...)

        if nextToken == 2 { break }

        // Decode and callback
        if let decodedText = try tokenizer.decode([nextToken]) {
            onToken(decodedText)  // ← Streaming callback
        }

        // Continue sequence
        generatedTokens.append(nextToken)
        let nextEmbedding = try model.embed([nextToken])
        inputSequence = try concatenate([inputSequence, nextEmbedding], dim: 0)
    }
}
```

**Success Criteria**:
- ✅ Tokens yielded in real-time
- ✅ UI updates as tokens arrive
- ✅ Same quality as non-streaming
- ✅ Can be cancelled mid-generation

**Estimated Time**: 1-2 hours

---

## Implementation Order

### Day 1 (3-4 hours)
1. ✅ **Task 1: Vision Encoder** (encodeImage)
   - Convert UIImage to tensor
   - Load vision encoder
   - Run forward pass
   - Test with sample image

2. ✅ **Task 2: Tokenization** (tokenizePrompt)
   - Implement BPE algorithm
   - Add special tokens
   - Test with sample text

### Day 2 (4-8 hours)
3. ✅ **Task 3: Generation** (runGenerativeInference)
   - Project embeddings
   - Autoregressive loop
   - Implement sampling
   - Test end-to-end

4. ✅ **Task 4: Streaming** (runGenerativeInferenceStreaming)
   - Add callback version
   - Test streaming output
   - Verify UI updates

### Testing & Debugging (2-3 hours)
- Test Imaging tab → upload image → generate findings
- Test Notes tab → generate SOAP note
- Verify inference time (1-2 seconds expected)
- Compare output quality to Python benchmark
- Check memory/thermal/battery usage
- Handle edge cases

---

## Testing Strategy

### Unit Tests
```swift
// Test encodeImage with known image
let testImage = UIImage(...)
let embeddings = try encodeImage(testImage)
XCTAssertEqual(embeddings.count, 576)  // num_patches
XCTAssertEqual(embeddings[0].count, 768)  // vision_dim

// Test tokenization consistency
let tokens1 = try tokenizePrompt("Hello world")
let tokens2 = try tokenizePrompt("Hello world")
XCTAssertEqual(tokens1, tokens2)

// Test generation produces text
let output = try runGenerativeInference(...)
XCTAssertFalse(output.isEmpty)
XCTAssertGreater(output.count, 10)
```

### Integration Tests
```swift
// Test Imaging findings generation
let image = loadTestMRIImage()
let findings = try generateFindings(image: image)
XCTAssertTrue(findingsValidator.isValid(findings))

// Test SOAP note generation
let patientData = createTestPatientData()
let soapNote = try generateSOAPNote(patientData)
XCTAssertTrue(soapValidator.isValid(soapNote))
```

### Device Tests
- Generate findings from real medical images
- Generate SOAP notes with clinical data
- Measure inference time
- Monitor memory/thermal/battery
- Compare quality to Python results

---

## Success Criteria

### Phase 3 Complete When:

✅ **Inference Working**
- encodeImage() returns real embeddings
- tokenizePrompt() returns real tokens
- runGenerativeInference() produces valid output
- runGenerativeInferenceStreaming() yields tokens

✅ **Validation Passes**
- Imaging: Can generate findings from image
- Notes: Can generate SOAP notes
- Both outputs pass validation (not blocked)

✅ **Performance Acceptable**
- Inference time: 1-2 seconds (Python benchmark)
- Memory: Peak < 4 GB
- Thermal: No excessive heat
- Battery: Reasonable impact

✅ **Quality Matches Expectations**
- Output is realistic medical text
- No gibberish or repeated tokens
- Coherent and clinically appropriate
- Comparable to Python testing results

---

## Dependencies & Resources

### Framework
- MLX Swift framework (already linked)
- MLXLMCommon for model operations
- MLXVLM for vision-language functionality

### Model Files
- model.safetensors (main model weights)
- vision_encoder.safetensors (vision encoder)
- tokenizer.json (BPE tokenizer)

### Documentation
- MLX Swift docs: https://github.com/ml-explore/mlx-swift
- MedGemma model card: huggingface.co/google/medgemma-1.5-4b-it
- BPE tokenization: https://github.com/openai/tiktoken

---

## Risk Assessment

### Low Risk
- Model files present and verified
- Tokenizer JSON available
- MLX framework properly linked
- Infrastructure in place

### Medium Risk
- First-time MLX inference implementation
- Vision encoder may need calibration
- Sampling algorithm requires tuning
- Device-specific optimizations may be needed

### Mitigation
- Start with non-streaming version
- Add detailed logging
- Test incrementally
- Have fallback to Python version if needed
- Monitor memory/thermal closely

---

## Timeline Estimate

| Task | Est. Time | Status |
|------|-----------|--------|
| Vision Encoder | 2-3 hrs | 📋 Planned |
| Tokenization | 1-2 hrs | 📋 Planned |
| Generation Loop | 2-3 hrs | 📋 Planned |
| Streaming | 1-2 hrs | 📋 Planned |
| Testing/Debug | 2-3 hrs | 📋 Planned |
| **TOTAL** | **8-13 hrs** | **1-2 days** |

---

## Next Steps

1. ✅ **Approve Plan** - Get sign-off on approach
2. ✅ **Create Task Branches** - One per implementation task
3. ✅ **Implement Task 1** - Vision encoder
4. ✅ **Test Task 1** - Verify embeddings quality
5. ✅ **Implement Task 2** - Tokenization
6. ✅ **Test Task 2** - Verify token consistency
7. ✅ **Implement Task 3** - Generation loop
8. ✅ **Test Task 3** - End-to-end inference
9. ✅ **Implement Task 4** - Streaming
10. ✅ **Full Device Testing** - Repeat Phase 2 with real inference

---

## Conclusion

Phase 3 is a focused, well-defined implementation of the missing MLX inference layer. With clear tasks, success criteria, and estimated timeline, this should result in fully functional on-device model inference.

**Recommendation**: Proceed with Phase 3 implementation. Expected completion: 1-2 days. After completion, re-run Phase 2 device testing to validate full end-to-end functionality.

