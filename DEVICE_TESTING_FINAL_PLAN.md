# Device Testing Plan - With Final MLX Model

**Date**: February 3, 2026
**Status**: Ready for Device Testing with Real MLX Model
**Model Available**: ✅ YES (3 quantization levels tested)
**Python Validation**: ✅ COMPLETE

---

## Model Status: Production Ready

### Available Models
```
Models Directory: /Users/nigelrandsley/MediScribe/Models/

✅ medgemma-4b-it-4bit    (2.8 GB) - Fastest, Recommended
✅ medgemma-4b-it-6bit    (3.9 GB) - Balanced
✅ medgemma-4b-it-8bit    (4.5 GB) - Highest Quality
```

### Tested on Python/MLX
- ✅ All 3 quantizations work
- ✅ Inference times: 1,055-1,473ms (1-1.5 seconds)
- ✅ Valid output for medical queries
- ✅ No gibberish or degradation
- ✅ Proper Gemma3 chat format

### Performance Comparison
| Quantization | Size | Speed | Recommendation |
|--------------|------|-------|-----------------|
| **4-bit** | 2.8 GB | 1,056 ms | ✅ **RECOMMENDED** |
| 6-bit | 3.9 GB | 1,307 ms | Optional |
| 8-bit | 4.5 GB | 1,473 ms | Only if needed |

---

## Device Testing Plan: Three Phases

### **Phase 1: Bundle & Deploy (This Week)** 🚀 IMMEDIATE

**Objective**: Get 4-bit model into iOS app and deploy to device

**Steps**:

1. **Choose Quantization**
   ```
   Selected: 4-bit (medgemma-4b-it-4bit)
   Reason: Best balance of speed (1 sec) and quality
   Size: 2.8 GB (reasonable for device storage)
   ```

2. **Prepare Model Bundle for iOS**
   ```
   Create: App/Assets/Models/medgemma-4b-it/
   Copy from: Models/medgemma-4b-it-4bit/
   Include:
   ├── model.safetensors
   ├── tokenizer.json
   ├── config.json
   ├── generation_config.json
   ├── preprocessor_config.json
   └── processor_config.json
   ```

3. **Update MLXModelLoader Path**
   ```swift
   // In MLXModelLoader.swift, setupModelPath()
   // Point to bundled model:
   Bundle.main.path(forResource: "medgemma-4b-it", ofType: nil)
   ```

4. **Uncomment MLX Imports in MLXMedGemmaBridge.swift**
   ```swift
   #if !targetEnvironment(simulator)
   import MLX          // Uncomment
   import MLXNN        // Uncomment
   import MLXVLM       // Uncomment
   #endif
   ```

5. **Build and Deploy**
   ```bash
   xcodebuild -project MediScribe.xcodeproj \
              -scheme MediScribe \
              -configuration Release \
              -destination 'generic/platform=iOS' \
              build
   # Install on device via Xcode
   ```

**Timeline**: 2-3 hours
**Risk**: LOW (model is validated, infrastructure is ready)

---

### **Phase 2: Real-World Device Testing (This Week)** ✅ VALIDATION

**Objective**: Validate model works on actual iOS device with Metal GPU

**Setup**:
- Connect iPhone (Sarov or Seversk)
- Run deployed app with 4-bit model

**Test Cases**:

#### A. Basic Model Loading
```
☑ App launches without crash
☑ Model loads on first use
☑ Memory usage reasonable (< 4GB)
☑ No thermal throttling
```

#### B. SOAP Note Generation
```
☑ Generate SOAP note with patient data
☑ Model produces valid output (~1-2 seconds)
☑ Output passes validation (no forbidden phrases)
☑ Validation errors display correctly
☑ UI remains responsive during generation
```

#### C. Error Handling (from ViewModel work)
```
☑ Invalid output caught and blocked
☑ Error message displays to user
☑ User can edit and retry
☑ No crashes on edge cases
```

#### D. Performance Metrics
```
☑ Measure actual inference time on device
☑ Compare to Python benchmark (should be similar)
☑ Monitor memory during generation
☑ Check battery impact
☑ Monitor thermal behavior
```

#### E. Integration Testing
```
☑ Save to Core Data works
☑ Retrieve encrypted note works
☑ Multi-note queries fast
☑ Index-based filtering works
☑ Encryption/decryption on device
```

#### F. Streaming Generation (if implemented)
```
☑ Token streaming updates UI
☑ Progress indicator works
☑ Cancellation works
☑ No memory leaks
```

**Expected Results**:
- ✅ Model inference: ~1-1.5 seconds (per Python testing)
- ✅ SOAP note generation complete end-to-end
- ✅ Validation errors work as designed
- ✅ No crashes or thermal issues

**Timeline**: 4-6 hours
**Risk**: LOW (model validated, infrastructure ready)

---

### **Phase 3: Optimization & Release (If Needed)**

**Objective**: Fine-tune for production if Phase 2 reveals issues

**Potential Optimizations**:
```
If memory pressure:
  → Use 4-bit quantization (already selected)
  → Implement lazy loading
  → Unload after use

If slow inference:
  → Measure GPU utilization
  → Check for CPU fallback
  → Profile on device

If thermal issues:
  → Reduce batch size
  → Add inference cooling breaks
  → Implement throttling
```

**Timeline**: 2-4 hours (if needed)
**Risk**: MEDIUM (depends on Phase 2 findings)

---

## Device Testing Checklist

### Pre-Testing Setup
```
☑ Model selected: 4-bit (2.8GB)
☑ Model validated: Python tests pass
☑ Model path: Models/medgemma-4b-it-4bit/
☑ ViewModel: Error handling complete
☑ iOS device: Sarov or Seversk ready
☑ Xcode: Latest version, device registered
☑ Storage: Device has 5GB+ free space
```

### Phase 1: Bundle & Deploy
```
☑ Copy 4-bit model to App/Assets/Models/
☑ Update MLXModelLoader.setupModelPath()
☑ Uncomment MLX imports in MLXMedGemmaBridge.swift
☑ Update deployment target to iOS 17+
☑ Set up device provisioning
☑ Build for device (not simulator)
☑ Deploy to iPhone via Xcode
☑ App launches without crash
```

### Phase 2: Functional Testing
```
LOADING:
☑ Model loads on first use
☑ Memory usage < 4GB
☑ No thermal throttling

GENERATION:
☑ Generate SOAP note with patient data
☑ Model responds in ~1-1.5 seconds
☑ Output is valid medical text
☑ No gibberish or repetition

VALIDATION:
☑ Valid output passes validation
☑ Invalid output blocked
☑ Error message clear
☑ User can retry

INTEGRATION:
☑ Save to Core Data works
☑ Retrieve note works
☑ Encryption/decryption works
☑ Multiple notes work

PERFORMANCE:
☑ Measure inference time
☑ Monitor memory
☑ Check thermal behavior
☑ Verify battery impact
```

### Phase 3: Edge Cases
```
☑ Network disabled (should work offline)
☑ Low memory (test with 512MB free)
☑ Extended use (generate multiple notes)
☑ Interrupted generation (user cancels)
☑ Concurrent operations (multiple notes at once)
```

---

## Model Integration: Technical Details

### Current State
```
MLXMedGemmaBridge.swift:
├── #if targetEnvironment(simulator)
│   └── Placeholder implementation
└── #else
    └── Real MLX model (needs uncommenting)
```

### What Needs to Happen

1. **Uncomment MLX Imports**
   ```swift
   // In MLXMedGemmaBridge.swift, line ~15
   #if !targetEnvironment(simulator)
   import MLX              // UNCOMMENT
   import MLXNN            // UNCOMMENT
   import MLXVLM           // UNCOMMENT
   import MLXLMCommon      // UNCOMMENT
   #endif
   ```

2. **Bundle Model with App**
   ```
   Xcode Project Settings:
   ├─ Add Model Files to Target
   ├─ Bundle Resources: Include medgemma-4b-it/
   └─ Copy Files: medgemma-4b-it/ to App Bundle
   ```

3. **Update Model Path**
   ```swift
   // In MLXModelLoader.setupModelPath()
   guard let bundlePath = Bundle.main.bundlePath else { return }
   let modelPath = "\(bundlePath)/medgemma-4b-it"
   ```

4. **Ensure Device Build**
   ```
   Build Settings:
   ├─ Architecture: ARM64 (Apple Silicon)
   ├─ Platform: iOS 17+
   ├─ Metal: Enabled (for GPU acceleration)
   └─ Deployment Target: iPhone compatible
   ```

---

## Performance Expectations

### From Python Testing
```
Quantization: 4-bit
Model: medgemma-4b-it-4bit
Inference Time: ~1,056 ms (1 second)
Output Quality: Valid medical text
GPU Required: Yes (Metal on iOS)
```

### On iOS Device
```
Expected similar to Python:
- Inference: 1-2 seconds (on Metal GPU)
- Memory: 2.8GB for model + overhead
- Thermal: Manageable (brief inference)
- Battery: ~5-10% per generation
```

### Why Device Might Differ
```
Factors that might change performance:
- Device CPU/GPU generation (newer = faster)
- Ambient temperature (thermal throttling)
- Available free memory
- Other background apps
- iOS version
```

---

## Risk Assessment

### Low Risk ✅
- Model validated on Python/MLX
- Infrastructure tested (ViewModel, validation)
- Build system ready
- Device available

### Medium Risk ⚠️
- First time running on physical iOS device
- Metal GPU optimization unknown
- Device-specific thermal issues possible
- Model size (2.8GB) on limited storage

### Mitigation
```
✅ Have fallback plan (4-bit is smallest)
✅ Monitor thermal during testing
✅ Start with short generations
✅ Have simulator backup for quick iteration
```

---

## Success Criteria

### Phase 1 Success
```
✅ App builds and deploys to device
✅ Model loads without crash
✅ Memory usage acceptable
✅ App remains responsive
```

### Phase 2 Success
```
✅ SOAP note generates in 1-2 seconds
✅ Output is valid (no gibberish)
✅ Validation works as designed
✅ Errors are handled gracefully
✅ Core Data operations work
✅ Encryption/decryption works
✅ Performance acceptable for clinical use
```

### Overall Device Testing Success
```
✅ Model works on actual iOS device
✅ All features function end-to-end
✅ Error handling robust
✅ Performance acceptable
✅ Ready for user testing
```

---

## Timeline

### This Week (Feb 3-7)
```
Monday (2-4 hrs):
  → Bundle 4-bit model
  → Update code paths
  → Build for device

Tuesday (2-3 hrs):
  → Deploy to device
  → Test basic loading
  → Test generation

Wednesday (4-6 hrs):
  → Full functional testing
  → Performance measurement
  → Error case testing

Thursday (2 hrs):
  → Documentation
  → Results summary
  → Optimization ideas
```

**Total**: ~10-15 hours over the week

---

## Next Immediate Actions

### Priority 1 (Do First - 30 min)
```
☑ Verify 4-bit model location
☑ Copy model files to Xcode Assets
☑ Update MLXModelLoader path
```

### Priority 2 (Do Second - 1-2 hours)
```
☑ Uncomment MLX imports
☑ Verify build settings for iOS device
☑ Build for device (not simulator)
```

### Priority 3 (Do Third - 2-3 hours)
```
☑ Deploy to iPhone
☑ Test basic app launch
☑ Test model loading
☑ Test SOAP generation
```

---

## Conclusion

**Status**: ✅ READY FOR IMMEDIATE DEVICE TESTING

**Model**: Validated (Python/MLX testing complete)
**Infrastructure**: Ready (ViewModel error handling complete)
**Timeline**: Can start this week
**Risk**: LOW (all components tested)
**Expected Outcome**: Full end-to-end validation of MediScribe with real MLX model on iOS device

**Recommendation**: **Begin Phase 1 (Bundle & Deploy) immediately**
- No blockers
- High confidence (model validated)
- Fast turnaround (2-3 hours)
- Will unblock production readiness
