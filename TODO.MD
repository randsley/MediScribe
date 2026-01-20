# Project TODOs

## Security

-   **Implement Application-Level Encryption for `FieldNote` data:**
    *   Currently, `noteData` stored in Core Data relies on iOS Data Protection (device-level encryption).
    *   Implement explicit application-level encryption for `noteData` before saving to Core Data.
    *   Consider encryption method (e.g., AES-256) and secure key management (e.g., iOS Keychain).
    *   This is crucial for protecting sensitive patient information beyond device-level security.

## Notes Feature Enhancements

-   **Implement complex UI inputs in `NoteEditorView`:**
    *   Multi-select for `associatedSymptoms`, `keyRisks`, `redFlags`.
    *   Dynamic input for `Focused Exam`, `Point-of-Care Tests`, `Working Diagnoses`, `Differentials`, `Immediate Actions`, `Medications Given`.
    *   Refine `VitalsInputView` for better user experience and validation.
-   **Refine Note Update Logic:**
    *   Currently, saving an edited note creates a new entry. Implement logic to update an existing `Note` entity in Core Data instead of always creating a new one.

## General

-   **Expand Test Coverage:** Add unit tests for validators, model managers, and new features.
-   **Set up Continuous Integration (CI):** Re-introduce a CI workflow for automated builds and tests.
