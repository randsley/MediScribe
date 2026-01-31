# Phase 6 Testing Guide - Real Device Execution

**Status**: Ready for testing on real device
**Date**: 2026-01-31
**Scope**: Validate Phase 6 implementation (vision support foundation, imaging/labs integration)

## Prerequisites

### Hardware
- iPhone with iOS 17.0+ (Apple Silicon recommended)
- Xcode 15.x or later
- USB cable for device connection

### Software
- MediScribe Xcode project with Phase 6 changes
- MLX-Swift framework (0.16.0+)
- MedGemma 1.5 model (2GB, placed in ~/MediScribe/models/)

### Configuration
- Real device must be registered in Apple Developer account
- Signing certificate properly configured in Xcode
- Device must have minimum 3GB free storage for model

## Test Execution Plan

### Phase 1: Unit Tests (Simulator or Device)

Run ALL unit tests to validate foundational changes:

```bash
# Run all unit tests
xcodebuild test -project MediScribe.xcodeproj \
  -scheme MediScribe \
  -destination 'generic/platform=iOS' \
  -only-testing:MediScribeTests

# Key tests for Phase 6:
# 1. TextSanitizerTests - Multi-language forbidden phrase detection
# 2. FindingEncryptionTests - Imaging findings validation
# 3. LabResultsValidatorTests - Lab results safety validation
# 4. SafetyAuditTests - Safety validation edge cases
```

**Expected Results**: All 100+ tests pass

### Phase 2: Device-Specific Tests

Deploy to real device and verify:

```bash
# Build for device
xcodebuild build-for-testing -project MediScribe.xcodeproj \
  -scheme MediScribe \
  -configuration Debug \
  -derivedDataPath ./DerivedData \
  -destination generic/platform=iOS

# Install on device (manual via Xcode or via CLI)
# Then run tests on device
xcodebuild test -project MediScribe.xcodeproj \
  -scheme MediScribe \
  -configuration Debug \
  -destination 'platform=iOS,name=YOUR_DEVICE_NAME' \
  -only-testing:MediScribeTests
```

### Phase 3: Integration Testing (Hands-On)

#### 3.1 Imaging Feature Validation

**Objective**: Validate Phase 6 integration with real images

Steps:
1. Launch MediScribe on device
2. Navigate to Imaging tab
3. Test English mode:
   - Select/capture chest X-ray or test image
   - Tap "Generate findings summary"
   - Verify findings generated in English
   - Verify "Reviewed by clinician" toggle appears
   - Check findings contain no diagnostic language (run TextSanitizer)
   - Tap toggle, then "Add to patient record"
   - Verify finding saved to Core Data

4. Test language switching:
   - Settings → Change language to Spanish
   - Return to Imaging, select image
   - Generate findings in Spanish
   - Verify output language matches selection
   - Verify limitations statement in Spanish

5. Test safety validation:
   - Generate multiple findings
   - Verify no "diagnosis", "likely", "recommend" in output
   - Verify 4 anatomical sections present
   - Verify exact limitations statement

6. Test all 4 languages:
   - Repeat steps 4-5 for French and Portuguese

**Success Criteria**:
- ✅ Findings generate in <10 seconds
- ✅ All output is descriptive only (no diagnostic language)
- ✅ Language selection respected across pipeline
- ✅ Findings saved correctly to Core Data

#### 3.2 Labs Feature Validation

**Objective**: Validate lab result extraction

Steps:
1. Navigate to Labs tab
2. Tap camera button
3. Capture or select lab report image
4. Verify extracted test values display
5. Test each language (English, Spanish, French, Portuguese)
6. Verify limitations statement present
7. Toggle "I have reviewed these results"
8. Tap "Save"
9. Verify saved to Core Data

**Success Criteria**:
- ✅ Lab values extracted accurately
- ✅ Values displayed grouped by category
- ✅ No interpretation language in output
- ✅ Saves successfully

#### 3.3 Performance Testing

**Objective**: Validate Phase 6 performance targets

Measurements:
```
Metric                          Target      Acceptable
─────────────────────────────────────────────────────
Image processing time           < 10s       < 15s
Lab extraction time             < 8s        < 12s
Memory during inference          < 500MB     < 800MB
Model load time (first-time)    < 30s       < 60s
Model load time (cached)         < 2s        < 5s
```

Test procedure:
1. Open Xcode Organizer → Devices
2. Select device → Diagnostics → Profile
3. Run Imaging generation 3 times
4. Record processing time each run
5. Note memory peak each run
6. Check model is cached (second run faster)

**Success Criteria**:
- ✅ All measurements within target
- ✅ Memory remains stable across runs
- ✅ No crashes or memory leaks

#### 3.4 Safety Validation Testing

**Objective**: Ensure safety constraints enforced

Test Cases:
1. **Forbidden Phrase Detection**
   - Generate findings in all 4 languages
   - Manually review output for:
     - Disease names (pneumonia, fracture, etc.)
     - Diagnostic language (diagnosis, consistent with, etc.)
     - Probabilistic terms (likely, probable, etc.)
     - Management terms (recommend, treat, etc.)

2. **Limitations Statement**
   - Verify exact limitations text present
   - Verify cannot be edited
   - Verify appears before clinician review

3. **Schema Validation**
   - Export findings JSON from Core Data
   - Verify contains only allowed keys
   - Verify anatomical observations have allowed anatomy keys
   - No extra fields present

4. **Language Consistency**
   - Verify language parameter propagates:
     - AppSettings → View → ImagingGenerateView/LabsProcessView
     - → LocalizedPrompts → MLXModelBridge
     - → FindingsValidator/LabResultsValidator
   - Language affects both prompt generation and validation

**Success Criteria**:
- ✅ Zero prohibited language in output across all languages
- ✅ All findings pass schema validation
- ✅ Language parameter consistent throughout pipeline

### Phase 4: Stress Testing

**Objective**: Validate stability under load

Test Procedure:
```
1. Generate 10 findings sequentially
   - Measure: Time per generation, memory trend, crashes
   - Expected: ~80-100 seconds total, stable memory, no crashes

2. Switch languages 5 times between generations
   - Verify language changes respected immediately
   - No cached prompts from previous language

3. Test with various image types
   - X-rays (various body parts)
   - Ultrasounds
   - CT scans (if available)
   - Test images with artifacts

4. Test network edge cases
   - Disable WiFi/cellular (ensure offline operation)
   - Re-enable and verify caching works
```

**Success Criteria**:
- ✅ 10+ generations without crash
- ✅ Memory doesn't accumulate (no leak)
- ✅ Language switching immediate
- ✅ Offline operation confirmed

### Phase 5: UI/UX Validation

**Objective**: Ensure user experience meets requirements

Checklist:
- [ ] Language selector in Settings visible and responsive
- [ ] Language changes apply immediately to next generation
- [ ] Processing spinners display during inference
- [ ] Error messages clear and actionable
- [ ] "Reviewed by clinician" toggle required before saving
- [ ] Findings text editable before save (for clinician corrections)
- [ ] Back button returns to list
- [ ] Findings list shows generation timestamp
- [ ] Patient context clear (patient name, date)

**Success Criteria**:
- ✅ All UI elements responsive
- ✅ No crashes from button taps
- ✅ Smooth animations during loading
- ✅ Font sizes readable on device

## Test Results Recording

### Template: Test Results Report

```markdown
## Phase 6 Test Results

**Device**: [Device name/model, iOS version]
**Date**: [Date]
**Tester**: [Name]

### Unit Tests
- [ ] All 100+ tests pass
- [ ] No test timeouts
- [ ] TextSanitizerTests: ✓ PASS
- [ ] FindingEncryptionTests: ✓ PASS
- [ ] LabResultsValidatorTests: ✓ PASS
- [ ] SafetyAuditTests: ✓ PASS

### Imaging Feature
- [x] English mode: ✓ PASS
- [x] Spanish mode: ✓ PASS
- [x] French mode: ✓ PASS
- [x] Portuguese mode: ✓ PASS
- [x] Safety validation: ✓ PASS
- [x] Core Data save: ✓ PASS

### Labs Feature
- [x] English extraction: ✓ PASS
- [x] Language switching: ✓ PASS
- [x] Core Data save: ✓ PASS

### Performance
- Processing time: 8.5s avg (target: <10s) ✓
- Memory peak: 450MB (target: <500MB) ✓
- No memory leaks detected ✓

### Safety Validation
- Forbidden phrase detection: ✓ All languages
- Limitations statement: ✓ Exact match
- Schema validation: ✓ All findings pass
- Language consistency: ✓ Throughout pipeline

### Issues Found
1. [If any] Describe and prioritize
2. [Workaround] If available

### Signature
- [ ] Tester confirms all tests passed
- [ ] Ready for production

Signed: _____________ Date: _________
```

## Automated Test Configurations

### 1. Create Test Schemes

```bash
# Create testing scheme for device
xcodebuild -project MediScribe.xcodeproj \
  -scheme MediScribe \
  build-for-testing \
  -configuration Debug \
  -destination generic/platform=iOS \
  -derivedDataPath ./DerivedData
```

### 2. CI/CD Integration (Future)

For GitHub Actions or similar:

```yaml
name: Phase 6 Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: 15
      - run: xcodebuild test -project MediScribe.xcodeproj -scheme MediScribe
```

## Known Limitations

### Simulator vs. Device
- Metal linker symbols missing on simulator (pre-existing)
- Tests must run on **real device** or **iPhone Simulator with arm64 support**
- Linking may fail on x86_64 simulator (expected)

### Model Loading
- First load: ~30-60 seconds (model is 2GB)
- Subsequent loads: ~2-5 seconds (cached)
- If model missing, app shows informational message

### Language Support
- All 4 languages (English, Spanish, French, Portuguese) supported
- UI language independent of generation language
- Device locale doesn't affect app language

## Troubleshooting

### Tests Won't Run on Device

```bash
# Check provisioning profile
xcode-select --print-path

# Resign app
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Reconnect device and retry
```

### Memory Issues During Testing

```bash
# Clear Derived Data
rm -rf ~/Library/Developer/Xcode/DerivedData/MediScribe*

# Rebuild
xcodebuild clean -project MediScribe.xcodeproj -scheme MediScribe
```

### Model Not Loading

```bash
# Verify model location
ls -lah ~/MediScribe/models/medgemma-1.5-4b-it-mlx/

# Check file permissions
chmod 644 ~/MediScribe/models/medgemma-1.5-4b-it-mlx/*

# Verify file integrity
ls -lh ~/MediScribe/models/medgemma-1.5-4b-it-mlx/model.safetensors
# Should show ~2GB
```

### Language Not Switching

```bash
# Clear app cache
Settings → MediScribe → Reset App Data (if available)

# Restart app
Kill app from App Switcher, reopen

# Verify AppSettings persistence
Xcode Debugger: po AppSettings.shared.generationLanguage
```

## Sign-Off

Once all tests pass on real device:

- [ ] Unit tests: 100% pass
- [ ] Integration tests: All features validated
- [ ] Performance: Within targets
- [ ] Safety: No diagnostic language
- [ ] UI/UX: Responsive and clear

**Ready for**: Phase 7 Production Preparation
