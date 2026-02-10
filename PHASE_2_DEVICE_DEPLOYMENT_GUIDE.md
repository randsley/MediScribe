# Phase 2: Device Deployment & Testing Guide

**Date**: February 4, 2026
**Status**: Ready to deploy
**Expected Duration**: 4-6 hours (including testing)

---

## Quick Start: Deploy to Device

### Step 1: Connect iPhone
```bash
# Connect your iPhone (Sarov or Seversk) via USB to your Mac
# Xcode will automatically recognize it
```

### Step 2: Check Connected Devices
```bash
# List all connected iOS devices
xcrun xcode-select --print-path
xctrace list devices

# Or use Xcode's device selector: Top menu bar → select your device
```

### Step 3: Deploy the App

#### Option A: Using Xcode GUI (Easiest)
1. Open `MediScribe.xcodeproj` in Xcode
2. Top menu bar → Select your connected device (instead of Simulator)
3. Product → Run (⌘R)
4. Wait for build and automatic installation

#### Option B: Using Command Line
```bash
# Build and install to connected device
xcodebuild -project MediScribe.xcodeproj \
           -scheme MediScribe \
           -configuration Release \
           -destination 'platform=iOS' \
           install

# Or with specific device:
xcodebuild -project MediScribe.xcodeproj \
           -scheme MediScribe \
           -configuration Release \
           -destination 'platform=iOS,name=Sarov' \
           install
```

---

## Phase 2 Testing Checklist

### Section A: Basic Model Loading (15-30 min)

#### Test A1: App Launch
- [ ] App launches without crash
- [ ] Main UI appears
- [ ] No immediate errors in Console

**If fails**: Check device Console (Xcode → View → Navigators → Show Console)

#### Test A2: Model Load on First Use
Navigate to: Notes → Generate SOAP Note

- [ ] App loads model on first access
- [ ] Progress indicator shows (if implemented)
- [ ] Model loads in < 5 seconds
- [ ] No memory warnings in Console

**What to observe**:
- Check memory pressure: Settings → Developer → Memory Pressure Utility (if available)
- Watch for "Low Memory" warnings in Console
- Verify device doesn't thermal throttle (back of phone shouldn't get hot)

#### Test A3: Memory Usage
- [ ] Device remains responsive during model loading
- [ ] No lag when navigating
- [ ] Model stays loaded between notes (don't unload)

---

### Section B: SOAP Note Generation (1-2 hours)

#### Test B1: Generate First Note
1. Enter patient demographics:
   - Name: "Test Patient"
   - Age: 45
   - Sex: Male

2. Enter clinical data:
   - Subjective: "Patient reports fever for 3 days"
   - Objective: "Temperature 38.5°C, RR 20"
   - Assessment: "Acute febrile illness"
   - Plan: "Start supportive care"

3. Tap "Generate SOAP Note"

**Observe**:
- [ ] Generation starts (loading state shows)
- [ ] Text generates incrementally (if streaming)
- [ ] Inference completes in **1-2 seconds** (Python test: 1.056 seconds)
- [ ] Output is valid medical text
- [ ] No gibberish or repeated phrases
- [ ] No diagnostic language (validation working)

**Measure**:
- Note exact time: How long did generation take?
- Compare to Python benchmark (expect 1-1.5 sec)
- If significantly different, note device CPU/RAM state

#### Test B2: Output Quality
Verify generated note contains:
- [ ] Patient demographics echoed correctly
- [ ] Subjective section with patient complaint
- [ ] Objective section with vital signs
- [ ] Assessment with clinical impression
- [ ] Plan section with recommendations
- [ ] No forbidden phrases (diagnosis, disease names)

**Document any issues**:
- Wrong sections missing?
- Truncated text?
- Validation blocks (see Test B3)?

#### Test B3: Validation Error Handling
Generate note with problematic assessment:

1. Enter Assessment: "Patient has pneumonia and likely TB"
2. Tap "Generate SOAP Note"

**Expected behavior**:
- [ ] Model generates text
- [ ] Validation detects forbidden phrases ("pneumonia", "TB")
- [ ] Error message displays: "🛑 SAFETY BLOCK: Forbidden phrase..."
- [ ] Note NOT saved to database
- [ ] User can edit and retry
- [ ] Error message is clear and actionable

**Error message should include**:
```
🛑 SAFETY BLOCK: Forbidden phrase detected in assessment: 'pneumonia'
Assessment must contain observations only, not diagnostic conclusions.
Please revise the assessment and try again.
```

#### Test B4: Valid Note After Error
1. User sees error from Test B3
2. Revise Assessment: "Patient reports chest pain and cough"
3. Tap "Generate SOAP Note" again

**Expected**:
- [ ] New generation succeeds
- [ ] No validation errors
- [ ] Note saves successfully
- [ ] Previous error cleared

#### Test B5: Multiple Consecutive Generations
Generate 3-5 notes in succession:

1. Generate note 1
2. Save
3. Generate note 2
4. Save
5. Continue...

**Observe**:
- [ ] Each generation completes in ~1 second
- [ ] No memory buildup (check Console)
- [ ] No crashes after multiple generations
- [ ] Device stays responsive

---

### Section C: Performance Metrics (30-45 min)

#### Test C1: Measure Inference Time
Use Xcode's Time Profiler:

1. Product → Profile (⌘I)
2. Select "Time Profiler" instrument
3. Record while generating notes
4. Stop and analyze

**Expected**:
- [ ] Model inference: 1,000-1,500 ms
- [ ] Total generation time: 1,100-1,600 ms (includes tokenization overhead)
- [ ] No long stalls or stutters

#### Test C2: Memory Usage
Watch Console during generation:

1. Start Memory Gauge in Xcode
2. Generate note
3. Observe peak memory

**Expected**:
- [ ] Peak memory: < 4 GB
- [ ] Memory released after generation completes
- [ ] No memory leaks (stable between generations)

#### Test C3: Thermal Behavior
Touch the back of the iPhone during generation:

- [ ] Slight warmth acceptable (computation-intensive)
- [ ] ❌ Should NOT get very hot (> 38°C)
- [ ] No thermal throttling messages
- [ ] Device should cool down between generations

**If overheating**:
- Note ambient temperature
- Check if other apps running
- Consider 6-bit model if needed (slower but cooler)

#### Test C4: Battery Impact
Check battery usage:

1. Settings → Battery → Battery Usage by App
2. Look for "MediScribe" usage over test period

**Expected**:
- [ ] ~5-10% per generation reasonable
- [ ] Not continuously high when idle
- [ ] No background drain

---

### Section D: Core Data Integration (30-45 min)

#### Test D1: Save Note to Core Data
1. Generate valid SOAP note
2. Tap "Save" button
3. Verify save succeeds

**Expected**:
- [ ] Note saved without errors
- [ ] Success message appears
- [ ] Navigation to Notes list

#### Test D2: Retrieve Saved Note
1. Go to Notes list view
2. Tap saved note

**Expected**:
- [ ] Note loads from Core Data
- [ ] Text appears correctly
- [ ] Decryption works (text is readable, not encrypted garbage)
- [ ] All sections display

#### Test D3: Multiple Notes Queries
1. Generate and save 5 notes
2. Navigate to Notes list
3. Filter by date, status

**Expected**:
- [ ] List loads quickly (< 1 second)
- [ ] All notes appear
- [ ] Sorting works
- [ ] No crashes

#### Test D4: Encryption/Decryption
Generated notes should be encrypted in Core Data:

1. Generate note with sensitive text: "Patient reports cocaine use"
2. Save note
3. Inspect Core Data file (optional, via Xcode's Core Data inspector)

**Expected**:
- [ ] Note appears decrypted in UI
- [ ] Raw Core Data should show encrypted sections
- [ ] Only user can decrypt (key-based)

---

### Section E: Error Cases & Edge Conditions (45-60 min)

#### Test E1: Network Disabled
1. Turn off Wi-Fi and cellular (Airplane mode)
2. Generate SOAP note
3. Should work (offline-first app)

**Expected**:
- [ ] Generation succeeds
- [ ] No network errors
- [ ] Save completes
- [ ] App remains functional

#### Test E2: Low Memory Condition
1. Open many other apps to consume RAM
2. Try to generate note

**Expected**:
- [ ] App either:
  - Succeeds with longer generation time, OR
  - Shows graceful error (not crash)
- [ ] ❌ Must NOT crash
- [ ] User sees helpful error message

#### Test E3: Interrupted Generation
1. Start generating note
2. While generating, swipe up to go to Home Screen
3. Swipe back to app

**Expected**:
- [ ] Generation can be resumed or starts fresh
- [ ] ❌ Must NOT crash or corrupted state
- [ ] UI returns to consistent state

#### Test E4: Invalid Input Data
Try to generate with missing required fields:

1. Leave Assessment blank
2. Try to generate

**Expected**:
- [ ] Validation error before generation
- [ ] User sees clear message (e.g., "Assessment required")
- [ ] User can fix and retry

#### Test E5: Very Long Input
1. Enter very long subjective: 500+ characters
2. Generate note

**Expected**:
- [ ] Generation succeeds
- [ ] No crashes or truncation
- [ ] Note completes in reasonable time

---

## Detailed Testing Results Template

### Test Session Info
```
Date: _______________
Device: _______________  (Sarov / Seversk)
iOS Version: _______________
Device Memory: _______________
Ambient Temperature: _______________
Other Running Apps: _______________
```

### Key Metrics
```
INFERENCE TIME:
  Expected: 1,000-1,500 ms
  Actual: _____________ ms
  Status: ☐ Pass ☐ Slow ☐ Fail

MEMORY USAGE:
  Peak: _____________ GB
  Status: ☐ < 4GB (Pass) ☐ > 4GB (High)

THERMAL:
  Temperature: _____________ °C
  Status: ☐ Normal ☐ Warm ☐ Hot

BATTERY (per generation):
  Usage: _____________%
  Status: ☐ 5-10% (Good) ☐ > 10% (High)
```

### Test Summary
```
Section A (Loading):      ☐ Pass ☐ Partial ☐ Fail
Section B (Generation):   ☐ Pass ☐ Partial ☐ Fail
Section C (Performance):  ☐ Pass ☐ Partial ☐ Fail
Section D (Core Data):    ☐ Pass ☐ Partial ☐ Fail
Section E (Error Cases):  ☐ Pass ☐ Partial ☐ Fail

Overall: ☐ PASS ☐ NEEDS WORK ☐ FAIL
```

---

## Troubleshooting During Testing

### App Crashes on Launch
**Symptom**: App crashes immediately after opening

**Solutions**:
1. Check Console for error message
2. Likely causes:
   - Model path not found (check MLXModelLoader.currentModelPath)
   - Missing model files (verify all 6 config files bundled)
   - MLX framework linking issue

**Action**:
```bash
# Check app contents
ls -la ~/Library/Developer/Xcode/DerivedData/MediScribe-*/Build/Products/Release-iphoneos/MediScribe.app/
# Should see: model.safetensors, tokenizer.json, config.json, etc.
```

### Model Load Timeout (> 5 seconds)
**Symptom**: Model takes too long to load

**Solutions**:
1. Could be normal first-time load (caching)
2. Could be device under memory pressure
3. Check if other background tasks running

**Action**:
1. Try again on fresh device restart
2. Close other apps
3. Check available RAM: Settings → General → iPhone Storage

### Inference Very Slow (> 3 seconds)
**Symptom**: Each SOAP note takes > 3 seconds to generate

**Expected**: 1-1.5 seconds per Python testing

**Solutions**:
1. Device might be thermally throttled (too hot)
2. Low available memory
3. Device might be lower-end CPU

**Action**:
1. Let device cool down (put in airplane mode for 5 min)
2. Close background apps
3. Restart device
4. If still slow, might need to try 6-bit model (slower, cooler)

### Validation Errors Not Blocking
**Symptom**: Model generates forbidden phrases (e.g., "diagnosis")

**This means**: Validation is NOT working

**Action**:
1. Check SOAPNoteValidator is being called
2. Verify validator rules in ValidationStatus enum
3. Check ViewModel error handling (should catch SOAPNoteValidationError)
4. Check logs for validation errors

### Memory Not Released
**Symptom**: Memory keeps increasing with each note

**This means**: Memory leak in model unload

**Action**:
1. Check MLXModelBridge.unloadModel() is called
2. Verify no circular references
3. Might need to explicitly unload between generations

---

## Success Criteria

### Phase 2 SUCCESS if all of these pass:
- [x] App deploys and launches on device
- [x] Model loads in < 5 seconds
- [x] Inference completes in 1-2 seconds
- [x] Generated text is valid (no gibberish)
- [x] Validation blocks forbidden phrases
- [x] Error messages are clear
- [x] Save to Core Data works
- [x] Retrieve from Core Data works
- [x] No crashes in error cases
- [x] Encryption/decryption works
- [x] Multiple notes work without issues

### Phase 2 PARTIAL SUCCESS if:
- App works but inference slower than expected
- Some validation cases missing
- Memory usage higher than expected (but still functional)

### Phase 2 FAIL if:
- App crashes on device
- Model won't load
- Inference produces gibberish
- Validation not working
- Memory leaks causing crashes

---

## After Testing

### If All Tests Pass ✅
- Move to Phase 3 (Optimization, if needed)
- Document results in PHASE_2_RESULTS.md
- Consider production deployment

### If Some Tests Fail ⚠️
- Analyze root causes
- May need to implement Phase 3 optimizations:
  - Use 6-bit or 8-bit model if memory issues
  - Profile hot paths if too slow
  - Fix validation if not blocking correctly

### If Major Failures ❌
- Debug issues before proceeding
- May need to revisit infrastructure
- Check ViewModel error handling
- Verify Core Data integrity

---

## Commands Reference

### Deploy & Test
```bash
# List devices
xcrun xcode-select --print-path

# Build for device
xcodebuild -project MediScribe.xcodeproj \
           -scheme MediScribe \
           -configuration Release \
           -destination 'platform=iOS' \
           build

# Install to connected device
xcodebuild -project MediScribe.xcodeproj \
           -scheme MediScribe \
           -configuration Release \
           -destination 'platform=iOS' \
           install

# Run and monitor console
xcodebuild -project MediScribe.xcodeproj \
           -scheme MediScribe \
           -configuration Release \
           -destination 'platform=iOS' \
           test
```

### Debug on Device
```bash
# In Xcode:
# 1. Product → Scheme → Edit Scheme
# 2. Set Pre-actions or Post-actions as needed
# 3. View Console: View → Navigators → Show Console (⌘6)
# 4. View Devices: Window → Devices & Simulators
```

---

## Timeline Estimate

| Task | Duration |
|------|----------|
| Setup & Deploy | 15-30 min |
| Section A (Loading) | 15-30 min |
| Section B (Generation) | 1-2 hours |
| Section C (Performance) | 30-45 min |
| Section D (Core Data) | 30-45 min |
| Section E (Error Cases) | 45-60 min |
| Documentation | 15-30 min |
| **TOTAL** | **4-6 hours** |

---

## Next Steps After Phase 2

1. **Document Results**
   - Create PHASE_2_RESULTS.md
   - Include all metrics and observations
   - List any issues found

2. **Decide on Phase 3**
   - If all tests pass: Consider production-ready
   - If performance issues: Implement optimizations
   - If safety issues: Fix and re-test

3. **Plan Production Deployment**
   - TestFlight distribution (if applicable)
   - User documentation
   - Clinical trial or real-world testing

---

## Conclusion

Phase 2 will validate that MediScribe works as intended on real iOS devices with the production MLX model. Success here means the app is ready for clinical use and further deployment.

Good luck! 🚀
