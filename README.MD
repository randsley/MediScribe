# MediScribe

**MediScribe** is an offline-first clinical documentation support application designed for **rural, remote, and low-resource healthcare settings**.
It assists healthcare professionals in structuring notes, summarizing visible image features, and preparing referral documentation — **without providing diagnoses or clinical decisions**.

---

## Purpose & Scope

MediScribe is designed to:
- Support **clinical documentation and communication**
- Reduce clerical burden in primary care
- Operate **fully offline** on iPhone and iPad (Apple Silicon / M-series)
- Respect strict **clinical safety boundaries**

MediScribe **does not**:
- Provide diagnoses
- Assess clinical significance
- Recommend treatments or management
- Replace clinical judgment

---

## Key Principles

- **Findings-only output**  
  All generated content is descriptive and observational.
- **Clinician-in-the-loop**  
  Content must be explicitly reviewed before it can be saved or shared.
- **Offline-first**  
  No network connectivity is required.
- **Safety by design**  
  Outputs are validated against strict structural and linguistic rules.

---

## Current Features

### 📝 Notes
- Structured clinical note entry (in progress)

### 🖼 Imaging
- Generates **descriptive findings summaries** from imaging input
- Enforces:
  - Fixed JSON schema
  - Mandatory limitations statement
  - Forbidden phrase detection
- Blocks output if safety rules are violated
- Requires explicit clinician review before use

### 📄 Referrals
- Referral documentation support (in progress)

### ⚙️ Settings
- App information and configuration

---

## Safety & Intended Use

### Intended Use
MediScribe is intended to support **clinical documentation and communication** by qualified healthcare professionals.
It assists users in structuring notes and generating **descriptive summaries of visible features** in clinical images to support record-keeping and referrals.

MediScribe is designed for use in:
- Rural and remote primary care
- Low-resource healthcare environments
- NGO-supported clinical programs
- Settings with intermittent or no internet connectivity

### Explicit Non-Uses
MediScribe **does not**:
- Provide diagnoses
- Assess clinical significance
- Recommend treatment, triage, or management
- Replace clinical judgment
- Operate autonomously without clinician review

### Human Oversight
All generated content:
- Is presented as a **draft**
- Must be explicitly reviewed by a clinician
- Cannot be saved or shared until review is confirmed

### Safety Controls
MediScribe enforces safety through:
- Fixed output structures (schema validation)
- Mandatory limitations statements
- Automated detection of diagnostic, probabilistic, or prescriptive language
- Output blocking if safety rules are violated

If content cannot be generated safely, MediScribe prompts the user to document manually.

### Data Handling
- Operates **offline by default**
- Stores data locally on the device
- Does not transmit data externally unless explicitly configured
- Does not require cloud services or user accounts

---

## Developer Setup

### Requirements
- **macOS:** Latest stable version recommended
- **Xcode:** 15.x or later
- **Swift:** 5.9+
- **iOS / iPadOS Deployment Target:** iOS 17.0+

### Supported Devices
- iPhone (Apple Silicon)
- iPad (M-series recommended)

### Project Configuration
- UI framework: **SwiftUI**
- Architecture: Modular (UI / Features / Domain)
- No external dependencies required
- Offline-first (no network entitlements)

### Simulator
Recommended simulator for development:
- **iPhone 15**
- **iPad Pro (M2)**

To run:
1. Open `MediScribe.xcodeproj` or `.xcworkspace`
2. Select the **MediScribe** scheme
3. Choose a simulator device
4. Build & Run (⌘R)

### Build Notes
- All imaging outputs are validated at runtime
- If validation fails, output is intentionally blocked
- Debug builds display validation error reasons to assist development

---

## Disclaimer

MediScribe is **not a medical device** and does **not** provide medical advice, diagnosis, or treatment recommendations.
All outputs are intended solely to support documentation and communication by qualified healthcare professionals.

---

## Licensing

The source code for **MediScribe** is licensed under the **Apache 2.0 License**. See the [LICENSE](LICENSE) file for details.

### Required Model Dependency

This application requires the **MedGemma** model to function. The MedGemma model is **not included** in this repository and is governed by a separate set of terms.

- **Model:** MedGemma
- **Governing Terms:** [Health AI Developer Foundations Terms of Use](https://ai.google.dev/terms)

Users must acquire the MedGemma model from its official source and agree to its terms of use before using it with MediScribe. The application is configured to use the `medgemma-1.5-4b-it-Q4_K_M.gguf` model file, which should be placed in the appropriate directory after acquisition.
