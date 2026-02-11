# Contributing to MediScribe

Thank you for your interest in contributing to MediScribe. Before you begin, please read this document carefully. MediScribe is used in real clinical environments by healthcare professionals serving vulnerable patients. Every contribution carries a responsibility to preserve — and where possible strengthen — the clinical safety architecture that underpins the application.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Safety-First Requirement](#safety-first-requirement)
- [Development Environment](#development-environment)
- [Project Structure](#project-structure)
- [Making a Contribution](#making-a-contribution)
- [Safety-Critical Changes](#safety-critical-changes)
- [Running Tests](#running-tests)
- [Pull Request Guidelines](#pull-request-guidelines)
- [What We Welcome](#what-we-welcome)
- [What We Will Not Accept](#what-we-will-not-accept)

---

## Code of Conduct

All contributors are expected to follow the [MediScribe Code of Conduct](CODE_OF_CONDUCT.MD). Please read it before contributing. Particular attention is required for the **Responsible Use of AI in Clinical Documentation** and **Clinical Safety Obligations** sections, which define non-negotiable constraints on contributions.

---

## Safety-First Requirement

MediScribe's primary design constraint is clinical safety. Before contributing any code, understand the following:

**The safety gate must remain intact.** All AI-generated content passes through a runtime validation layer before being presented to a clinician. This layer enforces:

- A fixed JSON schema (unexpected fields are rejected)
- A mandatory limitations statement (exact match required)
- Forbidden phrase detection (diagnostic, probabilistic, and prescriptive language is blocked at runtime)
- Output blocking if any rule is violated (fail closed)

**The clinician review gate must remain mandatory.** AI-generated content cannot be saved, shared, or exported until a clinician has explicitly confirmed review. This is both an architectural and regulatory requirement.

**AI content must never become clinically authoritative.** AI-generated SOAP note content, imaging findings, and lab extractions are always drafts. They are exported as FHIR `ClinicalImpression` (not `Condition`) with `status: preliminary`. This distinction is non-negotiable.

If you are unsure whether a proposed change could affect any of these constraints, open a discussion issue before writing code.

---

## Development Environment

### Requirements

| Tool | Version |
|---|---|
| macOS | Sequoia (15.x) or later |
| Xcode | 16.x or later |
| Swift | 5.10+ |
| iOS deployment target | 17.0+ |
| Ruby (for Xcode project management) | System Ruby or rbenv |

### Setup

```bash
# Clone the repository
git clone https://github.com/randsley/MediScribe.git
cd MediScribe

# Open in Xcode
open MediScribe.xcodeproj
```

### Model Setup

MediScribe requires the **MedGemma 4b** model (MLX format) to run AI features on-device. The model is not included in this repository. Obtain it from its official source (subject to the [Health AI Developer Foundations Terms of Use](https://developers.google.com/health-ai-developer-foundations/terms)) and place it at:

```
MediScribe/Models/medgemma-4b-it/
```

AI features will not function without the model, but all other functionality — Core Data, encryption, FHIR export, validators — can be developed and tested without it.

### Simulator vs Physical Device

Swift compilation succeeds on the iOS Simulator. Full linking (including the MLX framework) requires a physical Apple Silicon device, because MLX references Metal GPU symbols unavailable in the simulator. For most contribution work, the simulator is sufficient.

---

## Project Structure

```
Domain/
├── Export/FHIR/        # FHIR R4 resources, profiles (IPS, EU Base, EHDS), mappers
├── ML/                 # MLX model loader and MedGemma bridge
├── Models/             # Core Data extensions and domain model types
├── Prompts/            # Localised prompt templates
├── Security/           # AES-256-GCM encryption, Keychain manager
├── Services/           # SOAP note generation, SBAR generator
└── Validators/         # Safety validators (see below)

Features/
├── Export/             # FHIRExportView, FHIRBundlePreviewView
├── Imaging/            # Imaging capture, generation, history
├── Labs/               # Lab capture, processing, history
├── Notes/              # SOAP note entry, SBAR, note detail, signing
└── Referrals/          # Referral creation and management

UI/                     # RootView (TabView), SettingsView, shared components
MediScribeTests/        # Unit tests
```

### Validators (safety-critical — read before modifying)

| File | Protects |
|---|---|
| `Domain/Validators/FindingsValidator.swift` | Imaging findings — schema, limitations, forbidden phrases |
| `Domain/Validators/LabResultsValidator.swift` | Lab results — schema, limitations, forbidden phrases |
| `Domain/Validators/SOAPNoteValidator.swift` | SOAP notes — content safety rules |
| `Domain/Validators/TextSanitizer.swift` | Shared text normalisation for forbidden phrase detection |

Changes to any validator require explicit justification and are reviewed with heightened scrutiny. See [Safety-Critical Changes](#safety-critical-changes).

---

## Making a Contribution

### 1. Open an issue first

For anything beyond a small bug fix, open a GitHub issue to discuss the proposed change before writing code. This is especially important for:

- New features or changed behaviour in AI generation pathways
- Any change touching `Domain/Validators/`
- Changes to the clinician review or signing flow
- FHIR export changes that affect resource types, statuses, or profile URIs
- Changes to encryption or key management

### 2. Fork and branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

Use descriptive branch names. Prefix with `feature/`, `fix/`, `docs/`, `test/`, or `refactor/`.

### 3. Write your code

- Follow existing Swift conventions in the codebase (SwiftUI, `@MainActor`, `async/await`)
- Do not introduce external dependencies without prior discussion — the project is intentionally dependency-minimal
- Write or update tests for any new logic (see [Running Tests](#running-tests))
- Do not add diagnostic language, disease names, or interpretive statements to any prompt template or output schema

### 4. Run tests before submitting

All tests must pass before a pull request will be reviewed. See [Running Tests](#running-tests).

### 5. Open a pull request

Follow the [Pull Request Guidelines](#pull-request-guidelines).

---

## Safety-Critical Changes

Changes to the following files or subsystems are subject to an elevated review process:

- `Domain/Validators/` — any validator or the text sanitiser
- `Domain/ML/` — model loading or inference bridge
- `Domain/Security/` — encryption or key management
- `Domain/Prompts/` — prompt templates (forbidden language may be introduced inadvertently)
- Any view that presents AI-generated content to the clinician before review
- The clinician review toggle and signing flow in `Features/Notes/`
- FHIR resource status fields and safety-to-FHIR mapping logic

For these changes, your pull request must include:

1. A clear explanation of *why* the change is necessary
2. An assessment of whether the change could affect output safety (even indirectly)
3. Evidence that the relevant test suite still passes
4. If the change touches forbidden phrase lists or schema rules: a documented clinical or regulatory justification

Changes that reduce the sensitivity of safety validation — even in the name of improving user experience or reducing false positives — will not be accepted without extraordinary justification.

---

## Running Tests

```bash
# Run all unit tests
xcodebuild test \
  -project MediScribe.xcodeproj \
  -scheme MediScribe \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:MediScribeTests

# Run FHIR export tests only
xcodebuild test \
  -project MediScribe.xcodeproj \
  -scheme MediScribe \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:MediScribeTests/FHIRExportTests

# Run validator tests only
xcodebuild test \
  -project MediScribe.xcodeproj \
  -scheme MediScribe \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:MediScribeTests/SOAPNoteValidatorTests
```

The CI pipeline runs automatically on every pull request. A passing CI run is required before merging.

---

## Pull Request Guidelines

- **One logical change per PR.** Avoid bundling unrelated changes.
- **Reference the issue.** Include `Closes #N` or `Related to #N` in the PR description.
- **Describe the change clearly.** Explain what changed, why, and what testing was done.
- **Keep diffs focused.** Avoid reformatting unrelated code in the same commit.
- **Commit message convention:**
  ```
  type: Short imperative summary (max 72 chars)

  Optional body explaining why, not what.
  ```
  Types: `feat`, `fix`, `docs`, `test`, `refactor`, `ci`, `chore`
- **Do not force-push to `main`.** PRs are merged by maintainers after review.

---

## What We Welcome

- Bug fixes with a clear description of the problem and fix
- Test coverage improvements, especially for edge cases in validators
- Documentation improvements (accuracy, clarity, missing information)
- Accessibility and usability improvements that do not affect safety architecture
- Performance improvements with benchmarks
- FHIR export improvements aligned with IPS, EU Lab IG, or EHDS specifications
- Internationalisation and localisation of UI strings
- Support for additional clinical note structures or documentation workflows, provided they pass through the existing safety validation architecture

## What We Will Not Accept

- Changes that weaken, bypass, or remove any safety validation rule
- Changes that allow AI-generated content to be used without clinician review
- Introduction of diagnostic language, disease names, or clinical interpretations in AI output
- External dependencies added without prior discussion and explicit maintainer approval
- Features that shift MediScribe's intended purpose toward clinical decision support, diagnosis, or treatment recommendation
- Code that transmits patient health data to external servers without explicit user action

---

## Questions

If you are unsure about anything in this document, open a GitHub discussion before proceeding. When in doubt, ask — a brief discussion is far preferable to a pull request that cannot be accepted.
