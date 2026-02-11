# Security Policy

## Overview

MediScribe handles sensitive patient health data, including clinical notes, imaging findings, laboratory results, and referral documentation. All stored data is encrypted using AES-256-GCM. We take security seriously and appreciate responsible disclosure of vulnerabilities.

---

## Reporting a Vulnerability

**Do not report security vulnerabilities through public GitHub issues.**

Public disclosure before a fix is available could expose users and their patients to unnecessary risk. Please report security issues privately using one of the following methods:

- **GitHub private vulnerability reporting:** Use the **"Report a vulnerability"** button on the [Security tab](../../security/advisories/new) of this repository. This creates a private advisory visible only to maintainers.
- **Email:** If you are unable to use GitHub's private reporting, contact the project maintainers directly. Check the repository's contact information for the current address.

Please include as much of the following as possible:

- A clear description of the vulnerability and its potential impact
- Steps to reproduce the issue
- The component or file(s) involved
- Any proof-of-concept code or screenshots (in private only)
- Your assessment of severity

We will acknowledge receipt within **5 business days** and aim to provide an initial assessment within **10 business days**. We will keep you informed throughout the remediation process and credit you in the security advisory unless you prefer to remain anonymous.

---

## Scope

### In Scope

The following are considered security issues for MediScribe:

**Patient data protection**
- Any vulnerability that could expose unencrypted patient health data stored in Core Data
- Any flaw in the AES-256-GCM encryption implementation (`Domain/Security/EncryptionService.swift`)
- Any flaw in the Keychain-based key management (`Domain/Security/KeychainManager.swift`) that could expose or leak encryption keys
- Any pathway through which encrypted patient data could be decrypted or exfiltrated without device access and authentication

**Clinical safety controls**
- Any vulnerability that allows AI-generated content to bypass the runtime safety validators (`Domain/Validators/`)
- Any flaw that permits AI-generated content to be saved, shared, or exported without confirmed clinician review
- Any vulnerability that enables forbidden phrases or diagnostic language to pass through the safety gate undetected

**FHIR export integrity**
- Any flaw that causes AI-generated content to be exported as clinically authoritative FHIR resources (e.g., `Condition` with `verificationStatus: confirmed`) when it should be exported as `ClinicalImpression` with `status: preliminary`
- Any vulnerability in the export pipeline that could attach incorrect patient identifiers to exported records

**Data leakage**
- Any unintended transmission of patient data to external servers or services
- Any logging behaviour that captures and persists unencrypted patient health data

**Authentication and access control**
- Any flaw that allows access to patient records without device authentication
- Any vulnerability in the signing or review attestation mechanism that allows records to be marked as clinician-reviewed without actual review

### Out of Scope

The following are **not** considered security vulnerabilities for this project:

- Vulnerabilities in the MedGemma model itself or its training data — report these to Google via the [Health AI Developer Foundations](https://developers.google.com/health-ai-developer-foundations) programme
- The pre-existing MLX simulator linker limitation (`_MTLIOErrorDomain`/`_MTLTensorDomain`) — this is a known build environment constraint, not a security issue
- Issues that require physical, unlocked device access to exploit — MediScribe stores data locally and relies on iOS device encryption and authentication as the outer security perimeter
- Social engineering attacks against end users
- Denial of service against the local application
- Issues in third-party Swift packages (mlx-swift, swift-transformers) — report these to their respective maintainers

---

## Severity Classification

We use the following severity levels to triage reports:

| Severity | Description | Examples |
|---|---|---|
| **Critical** | Direct exposure of unencrypted patient data or complete bypass of safety controls | Encryption key exposed; safety validator entirely bypassable |
| **High** | Significant weakening of data protection or safety architecture | Partial bypass of forbidden phrase detection; partial key leakage |
| **Medium** | Indirect risk to data integrity or safety guarantees | Incorrect FHIR resource status in edge cases; audit trail gaps |
| **Low** | Minor issues with limited impact | Non-sensitive information disclosure; cosmetic misrepresentation of review status |

---

## Security Architecture Summary

Understanding MediScribe's security architecture helps contextualise what constitutes a vulnerability.

### Data Encryption

All patient health data stored in Core Data is encrypted at the application layer using **AES-256-GCM** (CryptoKit) before being written to the database. This includes:

| Entity | Encrypted fields |
|---|---|
| `Note` (FieldNote) | Note content |
| `Finding` | Findings JSON, image data |
| `NoteAddendum` | Addendum text |
| `Referral` | Clinical summary, reason |

Encryption keys are stored in the **iOS Keychain**. The device's built-in data protection (hardware encryption) provides an additional outer layer. Patient data is never transmitted to external servers.

### Safety Validation

All AI-generated content passes through runtime validation before presentation:

- `FindingsValidator` — imaging findings
- `LabResultsValidator` — lab result extractions
- `SOAPNoteValidator` — SOAP note content

Validation is fail-closed: if validation fails for any reason, output is blocked entirely.

### Clinician Review Gate

AI-generated content cannot be saved, shared, or exported until a clinician has explicitly confirmed review. This is enforced at the model layer; there is no pathway to bypass it programmatically within the application's intended architecture.

### FHIR Export Safety Mapping

AI-generated content is always exported as:
- `ClinicalImpression` (not `Condition`)
- `DiagnosticReport` with `status: preliminary`
- With a `Provenance` resource attributing the content to the AI model

The export service validates review status before generating any FHIR bundle.

---

## Supported Versions

MediScribe does not yet have a formal versioning scheme. Security fixes are applied to the `main` branch. There are no legacy branches receiving backported fixes at this time.

---

## Disclosure Policy

We follow a **coordinated disclosure** approach:

1. Reporter submits a private vulnerability report.
2. Maintainers acknowledge receipt within 5 business days.
3. Maintainers assess and reproduce the issue within 10 business days.
4. A fix is developed and tested privately.
5. A patched release is prepared.
6. A security advisory is published on GitHub, crediting the reporter (unless anonymity is preferred).
7. The reporter may publish their own disclosure after the advisory is public.

We ask that reporters allow reasonable time for a fix to be developed before any public disclosure. We will not take legal action against researchers acting in good faith under this policy.

---

## Acknowledgements

We are grateful to the security research community for helping keep MediScribe and the patients it serves safe. Responsible disclosures are credited in GitHub Security Advisories unless the reporter requests otherwise.
