# MediScribe

**MediScribe** is an offline-first clinical documentation support application designed for **rural, remote, and low-resource healthcare settings**.

It assists qualified healthcare professionals in structuring clinical notes, summarising visible findings from imaging and lab reports, and preparing referral documentation — **without providing diagnoses or clinical decisions**.

---

## Purpose & Scope

MediScribe is designed to:
- Support **clinical documentation and communication**
- Reduce clerical burden in primary care and field settings
- Operate **fully offline** on iPhone and iPad (Apple Silicon / M-series)
- Respect strict **clinical safety boundaries**
- Export structured records as **FHIR R4** for interoperability

MediScribe **does not**:
- Provide diagnoses or assess clinical significance
- Recommend treatments, triage, or management
- Replace clinical judgment
- Operate autonomously without clinician review

---

## Key Principles

- **Findings-only output** — All AI-generated content is descriptive and observational.
- **Clinician-in-the-loop** — Content must be explicitly reviewed before it can be saved or shared.
- **Offline-first** — No network connectivity is required; all processing is on-device.
- **Safety by design** — Outputs are validated against strict structural and linguistic rules. If safe output cannot be produced, the system blocks output entirely.
- **Encrypted at rest** — All clinical data is AES-256 encrypted in Core Data.

---

## Features

### 📝 SOAP Notes
- Structured SOAP note entry with AI-assisted generation (MedGemma on-device)
- Mandatory clinician review and signing before use
- Secure storage with AES-256 encryption
- FHIR R4 export (Composition + ClinicalImpression)

### 🖼 Imaging Findings
- AI-assisted descriptive findings summaries from clinical images
- Runtime safety validation:
  - Fixed JSON schema enforcement
  - Mandatory limitations statement
  - Forbidden phrase detection (diagnostic, probabilistic, prescriptive language blocked)
- Output blocked if any safety rule is violated
- Mandatory clinician review before saving or sharing
- FHIR R4 export (DiagnosticReport + ImagingStudy, status: `preliminary`)

### 🔬 Lab Results
- AI-assisted extraction of visible laboratory values from images of lab reports
- Same safety validation architecture as Imaging
- Results grouped by test category with reference ranges
- Mandatory clinician review before saving
- FHIR R4 export (DiagnosticReport + Observations, EU Lab IG profile)

### 📋 Referrals
- Referral documentation with destination, reason, and clinical summary
- Attach related imaging or lab findings
- Status tracking (Draft → Sent → Received)
- FHIR R4 export (ServiceRequest)

### 🔄 FHIR R4 Export
- Full **IPS (International Patient Summary)** bundle export
- Individual document export for notes, labs, imaging, and referrals
- Profiles supported:
  - IPS IG (`Bundle-uv-ips`, `Composition-uv-ips`)
  - HL7 Europe Base (`Patient-eu-base`, `Practitioner-eu-base`, `Organization-eu-base`)
  - EU Lab IG (`DiagnosticReport-lab-eu-lab`)
  - EHDS/EEHRxF (labs, imaging, eRx domains)
- Safety architecture in export:
  - AI assessments → `ClinicalImpression` (never `Condition`)
  - AI findings → `DiagnosticReport` with `status: preliminary`
  - All AI resources include a `Provenance` audit trail
  - Export blocked until clinician review is confirmed
  - Patient name excluded by default (GDPR pseudonymous identifier)
  - `MedicationRequest` exported as `status: draft`, `intent: proposal` only

### ⚙️ Settings
- Clinician and facility profile
- FHIR export configuration (patient identifier system URI)
- App information

---

## Safety Architecture

MediScribe implements a **safety gate** system across all AI-assisted features:

| Layer | Implementation |
|---|---|
| Schema validation | Fixed JSON structures; unexpected keys rejected |
| Mandatory limitations | Exact limitations statement required in every output |
| Forbidden phrase detection | Runtime text sanitisation blocking diagnostic, probabilistic, and prescriptive language |
| Clinician review gate | Content cannot be saved or shared until clinician confirms review |
| Fail closed | If safe output cannot be produced, output is blocked entirely |
| FHIR safety mapping | AI content → `ClinicalImpression`/`preliminary` (never `Condition`/`final`) |

---

## Architecture

```
MediScribe/
├── Domain/
│   ├── Export/FHIR/         # FHIR R4 resources, profiles, mappers
│   ├── ML/                  # MLX model loader and MedGemma bridge
│   ├── Models/              # Core Data extensions and domain models
│   ├── Prompts/             # Localised prompt templates
│   ├── Security/            # AES-256 encryption, Keychain manager
│   ├── Services/            # SOAP note generation, SBAR generator
│   └── Validators/          # FindingsValidator, LabResultsValidator, SOAPNoteValidator
├── Features/
│   ├── Export/              # FHIRExportView, FHIRBundlePreviewView
│   ├── Imaging/             # Imaging capture, generation, history
│   ├── Labs/                # Lab capture, processing, history
│   ├── Notes/               # SOAP note entry, SBAR, note detail
│   └── Referrals/           # Referral creation and management
└── UI/                      # RootView (TabView), SettingsView, shared components
```

- **UI framework:** SwiftUI
- **Persistence:** Core Data (encrypted)
- **AI inference:** MLX (on-device, Apple Silicon)
- **Interoperability:** FHIR R4 (native Swift Codable, no external library)
- **External dependencies:** mlx-swift, swift-transformers (Swift Package Manager)

---

## Developer Setup

### Requirements

| Tool | Version |
|---|---|
| macOS | Sequoia or later |
| Xcode | 16.x or later |
| Swift | 5.10+ |
| iOS / iPadOS deployment target | 17.0+ |

### Supported Devices

- iPhone (Apple Silicon)
- iPad (M-series recommended)

> **Note:** Swift compilation succeeds on the iOS Simulator. Full linking (including MLX) requires a physical Apple Silicon device because MLX references Metal GPU symbols unavailable in the simulator.

### Build & Run

```bash
# Open in Xcode
open MediScribe.xcodeproj

# Build for simulator (Swift compilation check)
xcodebuild -project MediScribe.xcodeproj -scheme MediScribe \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for physical device (full build including MLX)
xcodebuild -project MediScribe.xcodeproj -scheme MediScribe \
  -destination 'generic/platform=iOS' build
```

### Run Tests

```bash
# All unit tests
xcodebuild test -project MediScribe.xcodeproj -scheme MediScribe \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# FHIR export tests only
xcodebuild test -project MediScribe.xcodeproj -scheme MediScribe \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:MediScribeTests/FHIRExportTests
```

### Model Setup

MediScribe uses **MedGemma 4b** (MLX format). The model is **not included** in this repository.

1. Obtain the model from its official source (subject to [Health AI Developer Foundations Terms of Use](https://developers.google.com/health-ai-developer-foundations/terms))
2. Place the model files at `MediScribe/Models/medgemma-4b-it/`

The `MediScribe/Models/` directory is gitignored to prevent accidental inclusion of large binary files.

---

## Clinical Context

### Intended Users

Qualified healthcare professionals operating within their local scope of practice:
- Primary care physicians, nurses, nurse practitioners
- Clinical officers in low-resource settings
- NGO-supported and humanitarian healthcare workers

### Deployment Contexts

- Rural and remote primary care
- NGO-run and mobile clinics
- Humanitarian medical missions
- Settings with intermittent or no internet connectivity

### Non-Uses (Strictly Enforced)

MediScribe must never be used to:
- Provide or infer diagnoses
- Assess disease likelihood, probability, severity, or urgency
- Recommend treatments, investigations, or management
- Determine triage or disposition
- Replace or override clinical judgment

---

## Disclaimer

MediScribe is **not a medical device** and does not provide medical advice, diagnosis, or treatment recommendations. All outputs are intended solely to support documentation and communication by qualified healthcare professionals. Clinical responsibility remains entirely with the treating clinician.

---

## Licensing

The source code is licensed under the **Apache 2.0 License**. See [LICENSE](LICENSE) for details.

The **MedGemma** model is governed separately by the [Health AI Developer Foundations Terms of Use](https://developers.google.com/health-ai-developer-foundations/terms) and is not included in this repository.
