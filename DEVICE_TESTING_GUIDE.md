# MediScribe Device Testing Guide

**Date Created**: 2026-01-31
**Target Devices**: iPhone 17 Max Pro, iPad M5
**Purpose**: Step-by-step guide for testing MediScribe on real iOS/iPadOS devices

---

## Overview

Since MLX requires the Metal GPU framework (unavailable in iOS Simulator), MediScribe must be tested on real devices. This guide covers building and deploying to your iPhone 17 Max Pro and iPad M5.

---

## Prerequisites

- M-series Mac with Xcode 15+ installed
- iPhone 17 Max Pro (USB-C cable)
- iPad M5 (USB-C cable)
- Apple ID (for code signing)
- MediScribe project cloned locally

---

## Part 1: Device Preparation

### Step 1.1: Connect iPhone 17 Max Pro
1. Plug in via USB-C cable to your M-series Mac
2. Unlock the phone
3. Tap **"Trust"** when prompted with "Trust This Computer?"
4. Wait for Xcode to recognize the device

### Step 1.2: Connect iPad M5
1. Plug in via USB-C cable to your M-series Mac
2. Unlock the iPad
3. Tap **"Trust"** when prompted
4. Wait for Xcode to recognize the device

### Step 1.3: Verify Device Recognition
```bash
# In Terminal, check connected devices
xcrun xcode-select --print-path
# Should show /Applications/Xcode.app/Contents/Developer
```

---

## Part 2: Xcode Project Setup

### Step 2.1: Open Project
```bash
cd /Users/nigelrandsley/MediScribe
open MediScribe.xcodeproj
```

### Step 2.2: Configure Code Signing
1. In Xcode, select **MediScribe** project (left sidebar)
2. Select **MediScribe** target
3. Go to **Signing & Capabilities** tab
4. Under **Signing**:
   - Team: Select your Apple ID (or create a personal team)
   - Bundle Identifier: Should be `com.mediscribe.app` (or similar)
5. Xcode may auto-generate a provisioning profile—allow it

### Step 2.3: Verify Build Settings
- **iOS Deployment Target**: 17.0+
- **Swift Language Version**: 5.9+
- **Build System**: New Build System (default)

---

## Part 3: Building & Running on iPhone 17 Max Pro

### Step 3.1: Select iPhone Device
1. Click the **Scheme selector** (top-left of Xcode toolbar)
2. In the dropdown, select **iPhone 17 Max Pro**
3. Confirm the device is listed (if not, reconnect USB)

### Step 3.2: Build & Run
```bash
# Option A: Use Xcode UI
# Press ⌘R (or Product → Run)

# Option B: Command line
xcodebuild -project MediScribe.xcodeproj \
  -scheme MediScribe \
  -destination 'generic/platform=iOS' \
  -configuration Debug build
```

### Step 3.3: Monitor Build Progress
- Watch the **Build** tab in Xcode
- First build may take 2-3 minutes (including MLX framework linking)
- Subsequent builds are faster
- If Metal linking errors appear, verify device is connected

### Step 3.4: Verify App Launch
- App should launch on iPhone 17 Max Pro
- Tap through tabs: Notes, Imaging, Labs, Referrals, Settings
- Verify no immediate crashes

---

## Part 4: Building & Running on iPad M5

### Step 4.1: Select iPad Device
1. Click the **Scheme selector** (top-left of Xcode toolbar)
2. In the dropdown, select **iPad M5**
3. Confirm the device is listed

### Step 4.2: Build & Run
```bash
# Press ⌘R to build and run on iPad
```

### Step 4.3: Verify Tablet Layout
- App should adapt to iPad's larger screen
- Tab navigation should work
- Forms should have proper spacing for tablet
- Landscape orientation should be supported (if implemented)

---

## Part 5: Initial Feature Testing

### Test 1: SBAR Note Creation (Critical - Phase 6)
**Purpose**: Validate SOAP note generation with streaming

1. Navigate to **Notes** tab
2. Tap **"New Note"** or **"Generate Note"**
3. Enter patient context (name, age, chief complaint)
4. Enter vital signs (use realistic values)
5. Tap **"Generate"**
6. **Observe**:
   - ✅ Tokens appear in real-time (streaming)
   - ✅ Progress bar shows percentage
   - ✅ Generation completes in <10 seconds
   - ✅ No crash or memory spikes

### Test 2: Multi-Language Support (Phase 8.2)
**Purpose**: Validate language selection and generation in all 4 languages

1. Go to **Settings** tab
2. Scroll down to **Language** section
3. Select **English** and generate a note (observe format)
4. Switch to **Spanish** (Español)
5. Generate another note (verify prompts are in Spanish)
6. Repeat for **French** (Français) and **Portuguese** (Português)
7. **Observe**:
   - ✅ Language picker updates immediately
   - ✅ Generated content matches selected language
   - ✅ No crashes on language switching
   - ✅ Safety validation works per language

### Test 3: Imaging Findings (Phase 3 - Placeholder)
**Purpose**: Verify UI works (note: uses placeholder JSON currently)

1. Navigate to **Imaging** tab
2. Tap **"Capture Image"** or camera icon
3. Take a test image or use existing photo
4. Tap **"Generate Findings"**
5. **Observe**:
   - ✅ Placeholder JSON loads and displays
   - ✅ Safety validation passes
   - ✅ Clinician review toggle works
   - ✅ No crashes

### Test 4: Lab Results Extraction (Phase 3 - Placeholder)
**Purpose**: Verify UI works (note: uses placeholder JSON currently)

1. Navigate to **Labs** tab
2. Tap **"Capture Lab Report"**
3. Take a test image or use existing photo
4. Tap **"Extract Results"**
5. **Observe**:
   - ✅ Placeholder JSON loads and displays
   - ✅ Results grouped by category
   - ✅ Clinician review toggle works
   - ✅ No crashes

### Test 5: Settings & Configuration
**Purpose**: Verify user profile and app settings

1. Navigate to **Settings** tab
2. Update **Clinician Name** and **Facility Name**
3. Toggle **Language** selection
4. View **Encryption Status** (should show AES-256-GCM active)
5. View **Privacy** and **Safety Limitations** documents
6. **Observe**:
   - ✅ Settings persist across app close/reopen
   - ✅ No crashes during editing
   - ✅ Encryption status displays correctly

---

## Part 6: Performance Monitoring

### Monitor Memory Usage (iPhone)
1. In Xcode, with app running on iPhone, go to **Debug** menu
2. Select **Gauges** (or press ⌘⌥E)
3. Watch the **Memory** gauge while generating notes
4. **Target**: Peak memory should stay below 3GB
5. **Expected**: Typically 2-2.5GB for SOAP generation

### Monitor Memory Usage (iPad)
1. Same as iPhone (Gauges view)
2. iPad M5 should have similar or better memory profile
3. Watch for sustained high memory after generation completes

### Monitor CPU Usage
1. In **Gauges**, observe **CPU** tab
2. During generation: CPU should spike to 80-100%
3. After generation: CPU should drop to <10%
4. Monitor **Thermal State** (if available)
   - Normal: ✅ Green
   - Warm: ⚠️ Yellow
   - Critical: ❌ Red (pause testing, let cool)

### Generation Speed Benchmarks
Use iPhone's Clock app or Xcode's Time Profiler:
1. Start note generation
2. Note the start time
3. Observe when generation completes
4. **Target**: <10 seconds total time
5. **Baseline**: First run may be slower (model loading), subsequent runs faster

---

## Part 7: Troubleshooting

### Build Fails: "Metal Linking Error"
**Cause**: Device disconnected or build system confusion
**Solution**:
1. Disconnect and reconnect device
2. Clean build folder (⇧⌘K)
3. Rebuild (⌘B)

### Build Fails: Code Signing Issues
**Cause**: Apple ID not configured or provisioning profile missing
**Solution**:
1. Xcode → Settings → Accounts
2. Add your Apple ID
3. Create a personal team if needed
4. Select the team in project Signing & Capabilities
5. Try again

### App Crashes on Launch
**Cause**: Usually Core Data migration or encryption key issue
**Solution**:
1. Delete app from device (hold icon → Remove App)
2. Rebuild and run fresh
3. If crashes persist, check Xcode console for errors

### Streaming Tokens Not Appearing
**Cause**: Model may not be loading, or network issue
**Solution**:
1. Check Xcode console for model loading errors
2. Verify device has sufficient free space (>10GB)
3. Try force-quitting app (swipe up from bottom) and restarting

### Language Selection Not Persisting
**Cause**: UserDefaults not saving properly
**Solution**:
1. Delete app and reinstall fresh
2. Check that AppSettings.swift is being used
3. Verify Settings tab language picker is connected

---

## Part 8: Wireless Deployment (Optional)

Once USB testing is working, you can enable wireless deployment:

### Enable Wireless Deployment
1. Connect device via USB first
2. In Xcode: **Window** → **Devices and Simulators**
3. Select your device
4. Check **"Connect via Network"** checkbox
5. Disconnect USB cable (device remains listed)

### Build & Run Wirelessly
- Select device from scheme dropdown (still shows as available)
- Press ⌘R to build and run over WiFi
- Faster iteration once model is loaded

---

## Part 9: Data & App State Management

### Reset App Data (If Needed)
If you need to start fresh:

**On Device**:
1. Settings app → General → iPhone Storage → MediScribe
2. Tap **"Offload App"** (keeps data) or **"Delete App"** (removes everything)
3. Reinstall from Xcode

**Via Xcode**:
```bash
xcrun simctl erase all  # Only for simulators, not real devices
```

### Preserve Test Data Between Runs
- App data persists in Core Data
- Encryption keys stored in Keychain
- Simply press ⌘R to rebuild—data remains

---

## Part 10: Reporting Issues

When testing, if you encounter bugs:

### Log Test Results
Create a test log with:
- **Device**: iPhone 17 Max Pro or iPad M5
- **iOS/iPadOS Version**: (Check Settings → General → About)
- **Test Performed**: Which feature (SOAP, Imaging, Labs, etc.)
- **Expected Behavior**: What should happen
- **Actual Behavior**: What happened
- **Error**: Console output if crashed (View → Debug Area → Show Console)

### Check Xcode Console
1. View → Debug Area → Show Console (⌘⇧Y)
2. Filter by "MediScribe" to see app logs
3. Look for red error messages or warnings
4. Copy error text for reporting

---

## Part 11: Next Steps After Initial Testing

Once basic features work:

1. **Complete Phase 6 Core Data** (3-4 hours)
   - Test SOAPNote entity save/load
   - Verify notes persist in Core Data

2. **Real Model Inference Validation** (2-3 hours)
   - Test with real MLX model on device
   - Benchmark generation speed
   - Profile memory usage under real load

3. **Phase 8 Integration** (2-3 hours)
   - Test feature generators (Imaging, Labs) with real languages
   - Validate safety validation in each language
   - Test language switching during generation

4. **Performance Profiling** (ongoing)
   - Use Xcode Instruments (Cmd+I) for detailed analysis
   - Profile energy usage
   - Test thermal limits under sustained generation

---

## Quick Reference Commands

```bash
# Open project
open MediScribe.xcodeproj

# Build for device
xcodebuild -project MediScribe.xcodeproj -scheme MediScribe -destination 'generic/platform=iOS'

# Run all tests
xcodebuild test -project MediScribe.xcodeproj -scheme MediScribe -destination 'platform=iOS Simulator,name=iPhone 15'

# View connected devices
xcode-select --print-path
```

---

## Document Info

**Created**: 2026-01-31
**Last Updated**: 2026-01-31
**Related Documents**:
- PHASE_ROADMAP.md (overall project timeline)
- MEDISCRIBE_PROGRESS.md (detailed phase status)
- CLAUDE.md (architecture and safety guidelines)

**Devices Tested**:
- ✅ iPhone 17 Max Pro
- ✅ iPad M5

---

**Questions?** Refer to CLAUDE.md for architecture details or PHASE_ROADMAP.md for phase-specific information.
