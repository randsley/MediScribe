# Project TODOs

## Security

### Extend Application-Level Encryption to Additional Entities

**Status**: FieldNote encryption is ✅ COMPLETE. Infrastructure is in place (EncryptionService, KeychainManager, AES-256-GCM).

**Future Tasks** - Extend encryption to remaining patient-identified health data:

-   **Finding Entity** (Imaging and Labs data):
    *   Encrypt `findingsJSON` field (imaging findings, lab results)
    *   Encrypt `imageData` field (medical images, lab report scans)
    *   Add `setFindings()` and `getFindings()` methods following Note pattern
    *   Implement migration for existing unencrypted findings
    *   Update Imaging and Labs features to use encrypted storage

-   **Referral Entity**:
    *   Encrypt `clinicalSummary`, `reason`, and other text fields
    *   Add encryption methods following established pattern
    *   Implement migration support

-   **Patient Entity**:
    *   Encrypt demographics (name, DOB, medical record number)
    *   Consider impact on search/filtering performance
    *   May require encrypted search or tokenization approach

-   **NoteAddendum Entity**:
    *   Encrypt `addendumText` field
    *   Maintain referential integrity with parent Note

**Infrastructure**: Reuse existing `EncryptionService` and `KeychainManager` - no additional security infrastructure needed.

## Notes Feature Enhancements

-   **✅ Implement field-optimized UI inputs in `NoteEditorView`:**
    *   ✅ Multi-select grids for `associatedSymptoms`, `keyRisks`, `redFlags`
    *   ✅ Dynamic list inputs for `Point-of-Care Tests`, `Working Diagnoses`, `Differentials`, `Immediate Actions`, `Medications Given`
    *   ✅ Organ system-based exam input for `Focused Exam` (structured by system)
    *   ✅ Replaced `VitalsInputView` with `FieldOptimizedVitalsView` (large number pad, better UX)
    *   ✅ Multi-regional suggestion lists (WHO + East/Central Africa + South/Southeast Asia + Latin America)

## General

-   **Expand Test Coverage:** Add unit tests for validators, model managers, and new features.

---

## Completed Security Tasks

-   **✅ GitHub Actions CI:**
    *   **Status**: COMPLETE
    *   **Workflow**: `.github/workflows/ci.yml`
    *   **Triggers**: Push and PR to `main` branch
    *   **Steps**: Build (Debug) → Unit Tests (MediScribeTests)
    *   **Runner**: macOS 14 with Xcode 15.4, iPhone 15 Simulator
    *   **Features**: DerivedData caching, test result artifacts, concurrency control

-   **✅ Deprecated ClinicalNote Entity:**
    *   **Status**: COMPLETE - Entity removed in Core Data model version 2
    *   **Reason**: Superseded by Note entity which provides encryption, signing, and addenda support
    *   **Migration**: Lightweight migration handles automatic removal (entity was unused)

-   **✅ Application-Level Encryption for `FieldNote` data:**
    *   **Status**: COMPLETE - Implemented in commit effd465
    *   **Implementation**: AES-256-GCM encryption using CryptoKit
    *   **Key Management**: iOS Keychain storage via KeychainManager
    *   **Note Entity Methods**: `setFieldNote()` and `getFieldNote()` for encrypted storage
    *   **Migration**: Automatic migration of legacy unencrypted noteData
    *   **Test Coverage**: Comprehensive tests in EncryptionServiceTests.swift
    *   **Files**: Domain/Security/EncryptionService.swift, Domain/Security/KeychainManager.swift
