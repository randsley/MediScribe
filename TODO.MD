# Project TODOs

## Security

### Extend Application-Level Encryption to Additional Entities

**Status**: FieldNote, Finding, NoteAddendum, and Referral encryption are ✅ COMPLETE. Infrastructure is in place (EncryptionService, KeychainManager, AES-256-GCM).

**Future Tasks** - Extend encryption to remaining patient-identified health data:

-   **Patient Entity**:
    *   Encrypt demographics (name, DOB, medical record number)
    *   Consider impact on search/filtering performance
    *   May require encrypted search or tokenization approach

**Infrastructure**: Reuse existing `EncryptionService` and `KeychainManager` - no additional security infrastructure needed.

## Notes Feature Enhancements

-   **✅ Implement field-optimized UI inputs in `NoteEditorView`:**
    *   ✅ Multi-select grids for `associatedSymptoms`, `keyRisks`, `redFlags`
    *   ✅ Dynamic list inputs for `Point-of-Care Tests`, `Working Diagnoses`, `Differentials`, `Immediate Actions`, `Medications Given`
    *   ✅ Organ system-based exam input for `Focused Exam` (structured by system)
    *   ✅ Replaced `VitalsInputView` with `FieldOptimizedVitalsView` (large number pad, better UX)
    *   ✅ Multi-regional suggestion lists (WHO + East/Central Africa + South/Southeast Asia + Latin America)

## General

-   **✅ Expand Test Coverage:** Unit tests added for validators (SOAPNoteValidator, FindingsValidator, LabResultsValidator), FHIR export (25 tests in FHIRExportTests.swift), SOAPNote Core Data, and view model error handling.

---

## Completed Security Tasks

-   **✅ GitHub Actions CI:**
    *   **Status**: COMPLETE
    *   **Workflow**: `.github/workflows/ci.yml`
    *   **Triggers**: Push and PR to `main` branch
    *   **Steps**: Build (Debug) → Unit Tests (MediScribeTests)
    *   **Runner**: macOS 15 with Xcode 16.x, iPhone 16 Simulator
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

-   **✅ Application-Level Encryption for `Finding` Entity:**
    *   **Status**: COMPLETE - Implemented in commit fcfbba5
    *   **Implementation**: AES-256-GCM encryption using existing EncryptionService
    *   **Finding Entity Methods**:
        *   `setFindingsJSON()` / `getFindingsJSON()` for JSON string encryption
        *   `setFindings()` / `getFindings()` for typed Codable encryption
        *   `setImage()` / `getImage()` for image data encryption
    *   **Migration**: `getFindingsJSONWithMigration()`, `getImageWithMigration()`, `migrateToEncryptedStorage()`
    *   **Core Data Model**: Version 3 with `encryptedFindingsData`, `encryptedImageData`, `isEncrypted` fields
    *   **Updated Features**: ImagingGenerateView, LabsProcessView (save), ImagingHistoryView (display)
    *   **Test Coverage**: 14 tests in FindingEncryptionTests.swift
    *   **Files**: Domain/Models/CoreData/Finding+CoreDataClass.swift, Finding+CoreDataProperties.swift

-   **✅ Application-Level Encryption for `NoteAddendum` Entity:**
    *   **Status**: COMPLETE
    *   **Implementation**: AES-256-GCM encryption using existing EncryptionService
    *   **NoteAddendum Entity Methods**:
        *   `setAddendumText()` / `getAddendumText()` for addendum text encryption
    *   **Migration**: `getAddendumTextWithMigration()`, `migrateToEncryptedStorage()`
    *   **Core Data Model**: Version 4 with `encryptedAddendumText`, `isEncrypted` fields
    *   **Updated Features**: Note+CoreDataClass (addAddendum), NoteDetailView (display)
    *   **Test Coverage**: 14 tests in NoteAddendumEncryptionTests.swift
    *   **Files**: Domain/Models/CoreData/NoteAddendum+CoreDataClass.swift, NoteAddendum+CoreDataProperties.swift

-   **✅ Application-Level Encryption for `Referral` Entity:**
    *   **Status**: COMPLETE
    *   **Implementation**: AES-256-GCM encryption using existing EncryptionService
    *   **Referral Entity Methods**:
        *   `setClinicalSummary()` / `getClinicalSummary()` for clinical summary encryption
        *   `setReason()` / `getReason()` for referral reason encryption
    *   **Migration**: `getClinicalSummaryWithMigration()`, `getReasonWithMigration()`, `migrateToEncryptedStorage()`
    *   **Core Data Model**: Version 4 with `encryptedClinicalSummary`, `encryptedReason`, `isEncrypted` fields
    *   **Test Coverage**: 20 tests in ReferralEncryptionTests.swift
    *   **Files**: Domain/Models/CoreData/Referral+CoreDataClass.swift, Referral+CoreDataProperties.swift
