# MediScribe Design System Rules

**Framework**: SwiftUI (iOS/iPadOS 17.0+)
**Architecture**: MVVM with Core Data persistence
**Purpose**: Clinical documentation support app for rural healthcare settings

---

## 1. Token Definitions

### Color Tokens

**Location**: `UI/FieldOptimizedComponents.swift` (hardcoded) + `Features/*/` view files

**Current Implementation**:
- No centralized token system
- Colors defined inline in SwiftUI views
- SwiftUI Color extensions would be ideal

**Recommended Structure**:
```swift
// Domain/Design/ColorTokens.swift
enum ColorToken {
    // Status Colors (Safety-Critical)
    static let success = Color(red: 0.2, green: 0.8, blue: 0.2)     // Green
    static let warning = Color(red: 1.0, green: 0.8, blue: 0.0)     // Orange
    static let error = Color(red: 1.0, green: 0.2, blue: 0.2)       // Red
    static let info = Color(red: 0.0, green: 0.5, blue: 1.0)        // Blue

    // Neutral Colors
    static let background = Color(.systemBackground)
    static let surface = Color(.systemGray6)
    static let text = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let border = Color(.separator)

    // Clinical Safety Colors
    static let clinicalReviewRequired = Color(red: 1.0, green: 0.8, blue: 0.0)  // Orange
    static let validationPassed = Color(red: 0.2, green: 0.8, blue: 0.2)        // Green
    static let validationFailed = Color(red: 1.0, green: 0.2, blue: 0.2)        // Red
}
```

### Typography Tokens

**Location**: Implicit in SwiftUI (uses system fonts)

**Current Implementation**:
- Uses SwiftUI system font sizes: `.title`, `.headline`, `.body`, `.caption`
- No custom typography system

**Recommended Structure**:
```swift
// Domain/Design/TypographyTokens.swift
enum Typography {
    // Titles (Clinical Headers)
    static let pageTitle = Font.system(size: 28, weight: .bold)      // Page headers
    static let sectionTitle = Font.system(size: 22, weight: .semibold) // Section headers

    // Body Text (Reading)
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyRegular = Font.system(size: 16, weight: .regular)
    static let bodySmall = Font.system(size: 14, weight: .regular)

    // Labels (Form Fields)
    static let label = Font.system(size: 16, weight: .semibold)
    static let labelSmall = Font.system(size: 14, weight: .semibold)

    // Captions (Hints, Secondary Info)
    static let caption = Font.system(size: 12, weight: .regular)
    static let captionSmall = Font.system(size: 11, weight: .regular)

    // Monospace (Code, Values)
    static let monospace = Font.system(size: 13, weight: .regular, design: .monospaced)
}
```

### Spacing Tokens

**Location**: Implicit in SwiftUI (uses padding modifiers)

**Current Implementation**:
- Hardcoded padding values in views
- Common values: 8, 12, 16, 20, 24 points

**Recommended Structure**:
```swift
// Domain/Design/SpacingTokens.swift
enum Spacing {
    static let xs: CGFloat = 4      // Minimal spacing
    static let sm: CGFloat = 8      // Compact spacing
    static let md: CGFloat = 12     // Default spacing
    static let lg: CGFloat = 16     // Large spacing
    static let xl: CGFloat = 20     // Extra large
    static let xxl: CGFloat = 24    // Double extra large
    static let xxxl: CGFloat = 32   // Triple extra large
}
```

### Border & Radius Tokens

**Current Implementation**:
- `.cornerRadius(8)` hardcoded throughout
- No border radius scale

**Recommended Structure**:
```swift
// Domain/Design/BorderTokens.swift
enum BorderRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}

enum BorderWidth {
    static let thin: CGFloat = 1
    static let medium: CGFloat = 2
    static let thick: CGFloat = 3
}
```

---

## 2. Component Library

### Architecture Pattern

**Location**: `UI/FieldOptimizedComponents.swift` + `Features/*/`

**Current Components**:
- `FieldOptimizedComponents.swift` - Reusable UI elements
- Feature-specific views in `Features/{Notes,Imaging,Labs,Referrals,Settings}/`
- MVVM pattern with ViewModels

### Key Components

#### Clinical Input Components
```
Domain/Components/
├── ClinicalInputs/
│   ├── VitalsInputView.swift         # Temperature, HR, BP, RR, O2 Sat
│   ├── OrganSystemExamInputView.swift # Structured exam entry
│   ├── ChiefComplaintInputView.swift  # Chief complaint entry
│   └── HistoryInputView.swift         # HPI, past history
├── ClinicalReview/
│   ├── ClinicalReviewToggleView.swift # "I have reviewed" checklist
│   ├── SignatureView.swift            # Clinician signature/approval
│   └── LimitationsStatementView.swift # Mandatory safety disclaimers
└── ClinicalDisplay/
    ├── FindingsDisplayView.swift      # Read-only findings display
    ├── LabResultsDisplayView.swift    # Read-only lab results
    └── SOAPNoteDisplayView.swift      # Read-only SOAP note display
```

#### Form Components
```
FieldOptimizedComponents.swift includes:
- LargeNumberPad               # For numeric vital signs input
- MultiSelectDropdown         # For selecting multiple items
- DynamicListInput           # For adding/removing items
- TextField variants         # For text entry
- DatePicker variants        # For date selection
```

### Component Documentation Pattern

Each component should have:
```swift
/// Component Name
///
/// **Purpose**: Clinical use case (e.g., "Capture vital signs with large touch targets")
///
/// **Safety Notes**: Any clinical safety constraints
///
/// **Accessibility**: VoiceOver labels, dynamic type support
///
/// **Example**:
/// ```swift
/// VitalsInputView(vitals: $vitals)
/// ```
struct ComponentName: View {
    // Implementation
}
```

---

## 3. Frameworks & Libraries

### UI Framework
- **SwiftUI** - Primary UI framework (iOS 17.0+)
- **Combine** - Reactive data flow in ViewModels

### Data Persistence
- **Core Data** - Local database
  - Model: `MediScribe.xcdatamodeld` (Version 5)
  - Entities: Note, Finding, Referral, SOAPNote, Patient
  - Encrypted fields for sensitive data

### Styling Approach
- **SwiftUI Native** - No external styling libraries
- **View Modifiers** - Reusable styling via `.modifier()`
- **Environment** - Shared values via `.environment()`

### Key Libraries
- **CryptoKit** - Application-level encryption
- **AVFoundation** - Camera access for imaging/labs
- **MLX-Swift** (Phase 6) - On-device model inference

### Build System
- **Xcode Build System** - Standard iOS build
- **Swift Package Manager** - Dependency management
- **xcodeproj Ruby gem** - Project file automation

---

## 4. Asset Management

### Image Assets

**Location**: `Assets.xcassets/`

**Organization**:
```
Assets.xcassets/
├── AppIcon.appiconset/
├── LaunchScreen/
├── Colors/                    # Color sets
│   ├── Primary/
│   ├── Secondary/
│   └── Semantic/ (Status colors)
└── Icons/                     # System icons (SF Symbols)
```

**Naming Convention**:
- Prefix with feature: `notes_`, `imaging_`, `labs_`, `referrals_`, `settings_`
- Use descriptive names: `findings_validated`, `clinician_review_pending`
- Example: `imaging_findings_validated` for a success icon

### Image Usage Pattern
```swift
// Use SF Symbols for consistency
Image(systemName: "checkmark.circle.fill")
    .foregroundColor(.green)

// Avoid custom images unless necessary for branding
// Custom images stored in Assets.xcassets with 1x, 2x, 3x variants
Image("custom_logo")
    .resizable()
    .scaledToFit()
```

### Document/Data Assets
- Model files: `~/MediScribe/models/medgemma-1.5-4b-it-mlx/` (external, not in bundle)
- Test fixtures: `MediScribeTests/fixtures/` (sample images, lab reports)

---

## 5. Icon System

### Icon Library
- **SF Symbols** (Apple's system icons) - Primary source
- **No custom icon fonts** - Avoid custom icon sets

### SF Symbols Usage
```swift
// Standard patterns
Image(systemName: "checkmark.circle.fill")        // Checkmark (validated)
Image(systemName: "exclamationmark.triangle.fill") // Warning
Image(systemName: "xmark.circle.fill")            // Error
Image(systemName: "info.circle.fill")             // Information
Image(systemName: "camera.fill")                  // Camera
Image(systemName: "list.clipboard")               // Notes/documents
Image(systemName: "chart.bar")                    // Analytics/results

// Clinical specific
Image(systemName: "heart.fill")                   // Vitals
Image(systemName: "doc.text.magnifyingglass")    // Review required
Image(systemName: "lock.fill")                    // Encrypted/secure
Image(systemName: "checkmark.seal.fill")         // Signed/approved
```

### Icon Sizing
```swift
enum IconSize {
    static let small: CGFloat = 16      // Inline icons
    static let medium: CGFloat = 24     // Standard UI icons
    static let large: CGFloat = 32      // Section headers
    static let xlarge: CGFloat = 48     // Feature highlights
}
```

---

## 6. Styling Approach

### SwiftUI View Modifiers

**Location**: `UI/FieldOptimizedComponents.swift` + Feature-specific views

**Global Modifiers**:
```swift
// Domain/Design/ViewModifiers.swift
struct ClinicalCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color(.systemGray6))
            .cornerRadius(BorderRadius.md)
            .overlay(RoundedRectangle(cornerRadius: BorderRadius.md)
                .stroke(Color.gray.opacity(0.2), lineWidth: BorderWidth.thin))
    }
}

extension View {
    func clinicalCard() -> some View {
        modifier(ClinicalCardModifier())
    }
}
```

### Responsive Design

**Approach**: Use SwiftUI's built-in responsive features
```swift
@Environment(\.horizontalSizeClass) var sizeClass

VStack {
    if sizeClass == .compact {
        // iPhone layout
        VStack { /*...*/ }
    } else {
        // iPad layout
        HStack { /*...*/ }
    }
}
```

**Device Targets**:
- iPhone: Portrait-only (landscape support added later)
- iPad: Full-screen and split-view support
- Minimum size: iPhone SE

### Dark Mode Support
- **Automatic**: Use semantic colors (Color(.systemBackground))
- **Custom colors**: Define both light and dark variants
- **Testing**: Test on light and dark mode devices

---

## 7. Project Structure

### Directory Organization
```
MediScribe/
├── MediScribe/                    # App entry point
│   ├── MediScribeApp.swift       # @main entry
│   ├── ContentView.swift          # Initial view router
│   ├── Persistence.swift          # Core Data setup
│   └── MediScribe.xcdatamodeld/  # Data model (v5)
│
├── UI/                            # Shared UI components
│   ├── RootView.swift            # Tab bar navigation
│   ├── SettingsView.swift        # Settings
│   └── FieldOptimizedComponents.swift # Reusable components
│
├── Features/                      # Feature modules (clinical)
│   ├── Notes/
│   │   ├── SOAPNoteGeneratorView.swift
│   │   ├── SOAPNoteInputView.swift
│   │   ├── SOAPNoteReviewView.swift
│   │   └── NotesHomeView.swift
│   ├── Imaging/
│   │   ├── ImagingGenerateView.swift
│   │   ├── ImagingHistoryView.swift
│   │   └── ImagingHomeView.swift
│   ├── Labs/
│   │   ├── LabsProcessView.swift
│   │   ├── LabsHistoryView.swift
│   │   └── LabsHomeView.swift
│   └── Referrals/
│       ├── ReferralCreationView.swift
│       ├── ReferralDetailView.swift
│       └── ReferralsHomeView.swift
│
└── Domain/                        # Business logic & models
    ├── ML/                        # AI/Model layer
    │   ├── MLXModelLoader.swift
    │   ├── MLXModelBridge.swift
    │   ├── MLXImagingModel.swift
    │   └── Prompts/
    │       ├── ImagingPrompts.swift
    │       ├── LabPrompts.swift
    │       └── SOAPPrompts.swift
    ├── Models/                    # Data models
    │   ├── ImagingFindingsSummary.swift
    │   ├── LabResultsSummary.swift
    │   ├── SOAPNoteData.swift
    │   └── CoreData/              # Generated CD classes
    ├── Services/                  # Business logic
    │   ├── SOAPNoteGenerator.swift
    │   ├── SOAPNoteRepository.swift
    │   └── SOAPNoteParser.swift
    ├── Validators/                # Safety validation
    │   ├── FindingsValidator.swift
    │   ├── LabResultsValidator.swift
    │   └── TextSanitizer.swift
    ├── Security/                  # Encryption
    │   ├── EncryptionService.swift
    │   └── KeychainManager.swift
    └── Design/                    # Token definitions (planned)
        ├── ColorTokens.swift
        ├── TypographyTokens.swift
        ├── SpacingTokens.swift
        └── ViewModifiers.swift
```

### Navigation Pattern
```swift
// Tab-based navigation at root level
RootView {
    TabView {
        NotesHomeView()      // Notes tab
            .tabItem { Label("Notes", systemImage: "doc.text") }

        ImagingHomeView()    // Imaging tab
            .tabItem { Label("Imaging", systemImage: "photo") }

        LabsHomeView()       // Labs tab
            .tabItem { Label("Labs", systemImage: "chart.bar") }

        ReferralsHomeView()  // Referrals tab
            .tabItem { Label("Referrals", systemImage: "arrow.up.right") }

        SettingsView()       // Settings tab
            .tabItem { Label("Settings", systemImage: "gear") }
    }
}

// Within each feature: NavigationStack for hierarchical navigation
NavigationStack {
    List {
        NavigationLink(value: item) {
            ItemRow(item)
        }
    }
    .navigationDestination(for: Item.self) { item in
        ItemDetailView(item)
    }
}
```

### MVVM Pattern

**ViewModel Pattern**:
```swift
@MainActor
class SomeFeatureViewModel: ObservableObject {
    @Published var state: FeatureState = .idle
    @Published var error: Error? = nil

    private let service: SomeService

    func doAction() async {
        do {
            self.state = .loading
            let result = try await service.perform()
            self.state = .success(result)
        } catch {
            self.error = error
            self.state = .idle
        }
    }
}

// Usage in View
struct SomeFeatureView: View {
    @StateObject private var viewModel = SomeFeatureViewModel()

    var body: some View {
        switch viewModel.state {
        case .idle:
            Text("Ready")
        case .loading:
            ProgressView()
        case .success(let data):
            DataView(data: data)
        }
    }
}
```

---

## 8. Safety-Critical UI Patterns

### Clinical Review Workflow
```swift
VStack {
    // 1. Display content (read-only)
    SOAPNoteDisplayView(note: soapNote)

    // 2. Mandatory safety statement
    VStack {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)
        Text("Mandatory Limitations Statement")
            .font(.headline)
        Text(SafetyStatements.soapNoteLimitations)
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .background(Color.orange.opacity(0.1))
    .cornerRadius(BorderRadius.md)

    // 3. Clinician review toggle (REQUIRED before save)
    Toggle(isOn: $clinicianReviewed) {
        Text("I have reviewed this content")
    }

    // 4. Save button (disabled until reviewed)
    Button("Save Note") {
        saveNote()
    }
    .disabled(!clinicianReviewed)
}
```

### Validation Status Display
```swift
// Color-coded validation status
switch validationStatus {
case .unvalidated:
    HStack {
        Image(systemName: "exclamationmark.circle.fill")
            .foregroundColor(.orange)
        Text("Awaiting Validation")
    }
case .validationFailed:
    HStack {
        Image(systemName: "xmark.circle.fill")
            .foregroundColor(.red)
        Text("Validation Failed - Manual Review Required")
    }
case .validationPassed:
    HStack {
        Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
        Text("Safety Validation Passed")
    }
}
```

---

## 9. Accessibility Guidelines

### VoiceOver Support
```swift
VStack {
    Text("Patient Name")
        .accessibility(identifier: "patientNameLabel")

    TextField("Enter patient name", text: $patientName)
        .accessibility(hint: Text("Required field"))
        .accessibility(label: Text("Patient Name"))
}
```

### Dynamic Type Support
- Use relative font sizes: `.title`, `.headline`, `.body`
- Test with Xcode accessibility inspector
- Minimum touch target: 44x44 points

### Color Contrast
- Text: Minimum WCAG AA (4.5:1)
- UI components: Minimum WCAG AA (3:1)
- Don't rely on color alone (use icons + text)

---

## 10. Testing & Validation

### Preview Support
```swift
#Preview {
    SOAPNoteInputView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
```

### Device Testing Matrix
- iPhone 15 Pro (primary)
- iPad Pro M2 (secondary)
- iPhone SE (minimum size)

### Accessibility Testing
- VoiceOver enabled
- Dynamic Type at 150%
- High Contrast mode enabled
- Keyboard navigation

---

## Summary for Figma Designers

**Key Takeaways**:
1. **SwiftUI Native** - Design for SwiftUI, not web/CSS
2. **Safety-First** - Clinical review gates are non-negotiable
3. **Accessibility** - Large touch targets, high contrast, VoiceOver support
4. **Token-Based** - All colors, spacing, typography should use defined tokens
5. **Device-Aware** - Design for both iPhone and iPad layouts
6. **MVVM Architecture** - Views are "dumb", ViewModels handle logic

**For Code Connect**:
- Map Figma components to SwiftUI Views in `UI/FieldOptimizedComponents.swift` and feature-specific views
- Include safety-critical elements (review toggles, limitations statements)
- Provide variant states (loading, error, success, disabled)
