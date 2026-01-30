# Phase 4: UI Integration - Implementation Guide

## Overview

Phase 4 implements SwiftUI user interfaces for SOAP note generation, review, and management, integrating all backend services created in Phases 2-3.

## Status: COMPLETE ✓

### Completed Components

#### 1. SOAP Note ViewModel (Step 11)
**File**: `Features/Notes/SOAPNoteViewModel.swift`

Main state management for the entire SOAP workflow:

**Published Properties**:
```swift
@Published var generationState: GenerationState
@Published var currentNote: SOAPNoteData?
@Published var validationErrors: [SOAPValidationError]
@Published var isReviewed: Bool
@Published var streamingTokens: String

// Input form state
@Published var patientAge: String
@Published var patientSex: String
@Published var chiefComplaint: String
@Published var temperature: String
@Published var heartRate: String
// ... vital signs properties
@Published var medicalHistory: [String]
@Published var medications: [String]
@Published var allergies: [String]

// Error handling
@Published var showError: Bool
@Published var errorMessage: String
```

**Key Methods**:
```swift
func generateSOAPNote() async throws
  ├── Validates user input
  ├── Builds VitalSigns from string inputs
  ├── Creates PatientContext
  ├── Calls SOAPNoteGenerator
  └── Stores result in repository

func markAsReviewed(clinicianID: String) throws
  ├── Calls repository.markReviewed()
  └── Updates UI state

func signNote(clinicianID: String) throws
  ├── Finalizes note in repository
  └── Updates validation status

func exportAsText() -> String
  └── Retrieves formatted plain text

func resetForm()
  └── Clears all input fields
```

**Computed Properties**:
```swift
var isReadyToGenerate: Bool
  └── Checks required fields (age, chief complaint)

var canReview: Bool
  └── Checks note exists and validation passed

var canSign: Bool
  └── Checks note is reviewed
```

**Generation State**:
```swift
enum GenerationState: Equatable
├── idle: Ready for input
├── generating: In progress
├── complete: Ready for review
├── signed: Finalized
└── error(Error): Failed
```

#### 2. SOAP Note Input View (Step 11)
**File**: `Features/Notes/SOAPNoteInputView.swift`

Form for collecting patient information:

**Sections**:
1. **Patient Information**
   - Age (number input)
   - Sex (Picker: M/F/Other)
   - Chief complaint (text field)

2. **Vital Signs**
   - Temperature (°C)
   - Heart Rate (bpm)
   - Respiratory Rate (breaths/min)
   - Systolic BP (mmHg)
   - Diastolic BP (mmHg)
   - Oxygen Saturation (%)

3. **Medical History**
   - Dynamic list with add/remove buttons
   - Individual delete buttons
   - Text input with plus button

4. **Current Medications**
   - Same dynamic list pattern as medical history
   - Easy add/remove interface

5. **Allergies**
   - Same dynamic list pattern
   - Prominent display for safety

6. **Safety Notice**
   - AI-assisted documentation statement
   - Clinician review requirement
   - Clinician responsibility reminder

7. **Generate Button**
   - Disabled until required fields filled
   - Shows progress indicator while generating
   - Blue/enabled state indicates ready

**Features**:
- Dynamic array management (add/remove items)
- Input validation
- Numeric keyboard for numbers
- Form-based UI pattern
- Accessibility-friendly layout

#### 3. SOAP Note Review View (Step 11)
**File**: `Features/Notes/SOAPNoteReviewView.swift`

Comprehensive review interface with validation feedback:

**Sections**:
1. **Validation Status Banner**
   - Shows validation errors if any
   - Green checkmark if valid
   - Orange warnings if minor issues
   - Red critical if blocking

2. **SOAP Note Display**
   - **Subjective**: Chief complaint, HPI, PMHx, meds, allergies
   - **Objective**: Vital signs with formatted display, physical exam
   - **Assessment**: Clinical impression, differentials
   - **Plan**: Interventions, follow-up, education

3. **Limitations Statement**
   - Blue info banner
   - Reminds clinician of AI limitations
   - Safety-first messaging

4. **Review Actions**
   - "Mark as Reviewed" button (if not reviewed)
   - Review confirmation display (if reviewed)
   - "Sign Note" button (if reviewed)
   - "Export as Text" button
   - "Done" button

**Error Display**:
- Shows all validation errors with field names
- Color-coded by severity
- Clear error messages
- Actionable feedback

**Review Workflow**:
1. Clinician reads note
2. Clinician clicks "Mark as Reviewed"
3. UI updates to show reviewed status
4. Clinician can then sign the note
5. Signing finalizes the document

#### 4. SOAP Note Generation View (Step 12)
**File**: `Features/Notes/SOAPNoteGeneratorView.swift`

Main container view managing the entire workflow:

**State Machine**:
```
SOAPNoteInputView
    ↓
SOAPNoteGeneratingView (with streaming)
    ↓
SOAPNoteReviewView
    ↓
Done
```

**Sub-views**:
- **SOAPNoteInputView**: User enters patient data
- **SOAPNoteGeneratingView**: Shows progress, streaming tokens
- **SOAPNoteReviewView**: Review and sign
- **SOAPNoteListView**: Previous notes
- **SOAPNoteDetailView**: Full note display

**Features**:
- View state management based on generation status
- Error display with recovery options
- Streaming output preview
- Progress indication
- Safety warnings

#### 5. Supporting Components
**File**: `Features/Notes/SOAPNoteGeneratorView.swift`

**Helper Components**:
```swift
SOAPNoteGeneratingView
  ├── ProgressView
  ├── Streaming token display
  └── Safety notice

SOAPNoteListView
  ├── Empty state with CTA
  ├── List of previous notes
  ├── Filtering by status
  └── Delete capability

StatusBadge
  ├── Color-coded status display
  ├── unvalidated: orange
  ├── validated: blue
  ├── reviewed/signed: green
  └── blocked: red

SectionHeader
  ├── Icon + title
  └── Used in detail views

DetailRow
  ├── Label + value
  └── Consistent formatting
```

## Architecture

```
Features/Notes/
├── SOAPNoteViewModel.swift
│   └── @MainActor class managing all state
│
├── SOAPNoteInputView.swift
│   └── Form for patient data input
│
├── SOAPNoteReviewView.swift
│   └── Review, validation, signing
│
├── SOAPNoteGeneratorView.swift
│   ├── Main container
│   ├── SOAPNoteGeneratingView
│   ├── SOAPNoteListView
│   └── SOAPNoteDetailView
│
└── PHASE4_IMPLEMENTATION.md (this file)

Integration with Domain Layer:
├── Domain/Models/SOAPNoteData.swift
├── Domain/Services/SOAPNoteGenerator.swift
├── Domain/Services/SOAPNoteParser.swift
└── Domain/Services/SOAPNoteRepository.swift
```

## User Flows

### Generate New SOAP Note
```
1. SOAPNoteGeneratorView displays SOAPNoteInputView
2. User fills form:
   - Demographics (age, sex, chief complaint)
   - Vital signs
   - Medical history/meds/allergies
3. User taps "Generate SOAP Note"
4. ViewModel validates input
5. Switches to SOAPNoteGeneratingView
6. Shows progress + streaming tokens
7. On completion, switches to SOAPNoteReviewView
8. User reviews note
9. User clicks "Mark as Reviewed"
10. User can then "Sign Note"
11. Note stored with audit trail
```

### Review Previous Notes
```
1. User taps list button
2. SOAPNoteListView shows all notes
3. User can filter by status
4. User taps note to view detail
5. SOAPNoteDetailView shows full content
6. Can export as text or view metadata
```

### Review and Sign
```
1. Note in SOAPNoteReviewView
2. Clinician reads all sections
3. Checks for validation warnings
4. Clicks "Mark as Reviewed"
5. Reviews turn green
6. Clinician clicks "Sign Note"
7. Enters clinician ID
8. Note status → signed
9. Audit trail updated
```

## Data Flow

### Input to Generation
```
User Input (Form)
    ↓
SOAPNoteViewModel.generateSOAPNote()
    ↓
Validate input (age, chief complaint)
    ↓
Build VitalSigns (from strings)
    ↓
Create PatientContext
    ↓
SOAPNoteGenerator.generateSOAPNote()
    ↓
MLX Model inference
    ↓
SOAPNoteParser.parseSOAPNote()
    ↓
Validate output (required fields, blocked phrases)
    ↓
SOAPNoteRepository.save()
    ↓
Core Data persistence (encrypted)
    ↓
Update UI state
```

## Safety Features

### Input Validation
- Required field checking (age, chief complaint)
- Numeric validation for vital signs
- Empty list handling

### Output Validation
- JSON structure validation
- Required field checking
- Blocked phrase detection
- Error reporting with field specificity

### Review Workflow
- Mandatory clinician review toggle
- Review status tracking
- Signing capability for finalization
- Clinician ID recording
- Timestamp tracking

### Encryption
- Automatic encryption by repository
- Transparent to UI
- No plaintext PHI in display

## Testing Checklist

### ViewModel Tests
- [ ] generateSOAPNote() validates input
- [ ] Input validation rejects empty required fields
- [ ] VitalSigns conversion from strings works
- [ ] markAsReviewed() updates state
- [ ] signNote() finalizes note
- [ ] exportAsText() returns formatted text
- [ ] resetForm() clears all fields
- [ ] isReadyToGenerate computed property works
- [ ] Generation state machine transitions correctly

### Input View Tests
- [ ] Form displays all sections
- [ ] Age field accepts numbers only
- [ ] Sex picker shows options
- [ ] Dynamic lists add/remove items
- [ ] Generate button disabled until ready
- [ ] Generate button enabled when valid
- [ ] Progress indicator shows during generation

### Review View Tests
- [ ] All SOAP sections display correctly
- [ ] Validation errors show with colors
- [ ] Passing validation shows green checkmark
- [ ] Review button updates state
- [ ] Sign button available after review
- [ ] Export to text works
- [ ] Safety notice displays

### List View Tests
- [ ] Empty state displays when no notes
- [ ] List shows notes in reverse chronological
- [ ] Status badges show correct colors
- [ ] Note taps navigate to detail
- [ ] Filter by status works
- [ ] Delete removes notes

## Performance Targets

- Input view load: <100ms
- Generation start: <200ms
- Streaming token display: <50ms per token
- Review view load: <200ms
- Export to text: <500ms
- List view load: <200ms

## Files Created

1. `Features/Notes/SOAPNoteViewModel.swift` (250+ lines)
   - Main state management
   - Generation orchestration
   - Review workflow

2. `Features/Notes/SOAPNoteInputView.swift` (280+ lines)
   - Patient data form
   - Dynamic list management
   - Safety notices

3. `Features/Notes/SOAPNoteReviewView.swift` (320+ lines)
   - Note display
   - Validation feedback
   - Review/signing UI

4. `Features/Notes/SOAPNoteGeneratorView.swift` (380+ lines)
   - Main container
   - State-based view switching
   - List and detail views
   - Helper components

5. `Features/Notes/PHASE4_IMPLEMENTATION.md` (this file)
   - Complete documentation
   - Architecture diagrams
   - Testing guidance

## Dependencies

**Framework**:
- SwiftUI (UI framework)
- Combine (state management)

**Domain Layer Integration**:
- SOAPNoteGenerator (Phase 2)
- SOAPNoteParser (Phase 3)
- SOAPNoteRepository (Phase 3)
- SOAPNoteData (Phase 3)
- ValidationStatus (Phase 3)

**System Frameworks**:
- Foundation (Data types)
- CoreData (Persistence)
- UIKit (UIPasteboard for export)

## Known Limitations

1. **Streaming Not Fully Implemented**
   - Token-by-token callback system not yet connected
   - UI shows placeholder streaming container
   - Ready for MLX integration

2. **Voice Input Not Connected**
   - Voice transcription would feed chief complaint
   - Integration point exists in ViewModel
   - Awaits voice service implementation

3. **Export Options Limited**
   - Currently copies to pasteboard
   - Could add: email, save to files, share sheet
   - Foundation for extension exists

4. **Core Data Model Not Updated**
   - `.xcdatamodeld` file needs SOAPNote entity definition
   - Migration handling not yet added
   - ViewModel assumes it exists

## Next Steps (Phase 5)

1. **Core Data Schema Update**
   - Add SOAPNote entity to `.xcdatamodeld`
   - Define relationships
   - Create migration strategy

2. **MLX Framework Integration**
   - Connect real MLX inference
   - Implement token streaming callbacks
   - Replace placeholder model loading

3. **Voice Input Integration**
   - Connect speech recognition
   - Feed to chief complaint
   - Real-time transcription

4. **Testing Implementation**
   - Unit tests for ViewModel
   - UI tests for views
   - Integration tests for workflow

5. **Refinements**
   - Error handling edge cases
   - Accessibility improvements
   - Performance optimization

## Glossary

- **ViewModel**: State management and business logic
- **Published**: SwiftUI property wrapper for reactive updates
- **GenerationState**: Enum representing workflow state
- **SOAPNoteData**: Typed model from Phase 3
- **SOAPNoteRepository**: Persistence layer
- **Streaming**: Real-time token display during generation
- **Signing**: Clinician finalization of note

## References

- Phase 3: Data models and persistence
- Phase 2: Generation and validation
- CLAUDE.md: Safety requirements
- Domain/Models/SOAPNoteData.swift: Data structures
- Domain/Services/SOAPNoteRepository.swift: Persistence
