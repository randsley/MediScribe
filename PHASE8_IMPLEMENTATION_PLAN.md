# Phase 8 Implementation Plan: Advanced Features & Optimization

## Overview

Phase 8 builds on the completed Phase 6 MLX integration by adding advanced features that improve user experience and clinical utility:

1. **Step 1: Streaming Token Generation** - Display model output in real-time as tokens are generated
2. **Step 2: Multi-Language Support** - Enable interface and prompt generation in Spanish, French, and Portuguese
3. **Step 3: Offline Sync Improvements** - Add background task queueing for better offline-first workflows
4. **Step 4: Model Fine-Tuning Framework** - Create infrastructure for medical domain-specific model adaptation

**Recommended Priority**: Execute in order above (Streaming → Languages → Sync → Fine-tuning) because:
- Streaming has highest immediate impact on user experience
- Each step builds on previous ones
- Manageable scope prevents context overload
- Progressive validation of architecture changes

---

## Phase 8 Prerequisites

✅ Phase 6 Complete: MLX-Swift integration, real model inference, safety validators working
✅ Safety Audit Passed: 62/62 tests passing with 100% compliance
✅ Performance Benchmarks Met: All targets validated (<10s generation, <3GB memory)
✅ Core Data v5: SOAPNote entity with encryption working
✅ Build Infrastructure: Xcode 15.x, iOS 17.0+, Swift 5.9+
✅ Test Framework: XCTest with in-memory Core Data stores ready

---

## Step 1: Streaming Token Generation

### Objective

Replace current non-streaming generation (user sees blank screen for 5-10s, then full note appears) with streaming interface where tokens appear in real-time. Provides visual feedback and reduces perceived latency.

### Architecture Overview

**Current Flow**:
```
User taps "Generate"
  → MLXModelBridge.generate() runs to completion (5-10s blocking)
  → Full text returned
  → Display in UI
  → User sees nothing until done
```

**New Flow**:
```
User taps "Generate"
  → MLXModelBridge.generateStreaming() returns AsyncThrowingStream<String>
  → Each token appears immediately as it's generated
  → UI updates in real-time
  → User sees progress + perceived faster response
```

### Implementation Breakdown

#### 1.1: Modify MLXModelBridge for Streaming

**File**: `Domain/ML/MLXModelLoader.swift`

**Changes**:
1. Add streaming generation method alongside existing `generate()`:
```swift
static func generateStreaming(
    prompt: String,
    maxTokens: Int = 1024,
    temperature: Float = 0.3,
    topK: Int = 50
) -> AsyncThrowingStream<String, Error> {
    // Return stream that yields tokens as generated
}
```

2. Implementation approach:
```swift
return AsyncThrowingStream { continuation in
    Task {
        do {
            let tokens = try tokenizeText(prompt)
            var generatedTokens: [Int32] = []

            for i in 0..<maxTokens {
                let nextToken = try sampleToken(...)
                generatedTokens.append(nextToken)

                // Yield token to stream
                let decodedToken = try detokenizeIds([nextToken])
                continuation.yield(decodedToken)

                if nextToken == eosTokenId {
                    break
                }
            }

            continuation.finish()
        } catch {
            continuation.finish(throwing: error)
        }
    }
}
```

3. Keep existing `generate()` method for backwards compatibility (used by tests, non-streaming features)

**Testing**:
- Unit test: Stream produces tokens sequentially
- Unit test: Stream terminates on EOS token
- Unit test: Stream throws on invalid input
- Performance test: Token latency acceptable (<200ms per token)

#### 1.2: Update SOAP Note Generator for Streaming

**File**: `Domain/Services/SOAPNoteGenerator.swift`

**Changes**:
1. Add streaming generation method:
```swift
func generateSOAPNoteStreaming(
    from context: PatientContext
) -> AsyncThrowingStream<SOAPStreamUpdate, Error>
```

2. Return updates with progress tracking:
```swift
struct SOAPStreamUpdate {
    let section: SOAPSection  // .subjective, .objective, .assessment, .plan
    let token: String
    let totalTokensReceived: Int
}

enum SOAPSection {
    case subjective
    case objective
    case assessment
    case plan
}
```

3. Implementation:
```swift
let stream = MLXModelBridge.generateStreaming(prompt, maxTokens: 1024, temperature: 0.2)

for try await token in stream {
    // Parse token to determine which section it belongs to
    // Yield SOAPStreamUpdate with section and token
    // Continue until JSON parsing completes or max tokens reached
}
```

**Challenge**: JSON streaming - model might output incomplete JSON initially. Handle by:
- Accumulate tokens until valid JSON structure detected
- Only yield when section boundary found (e.g., "subjective": complete value)
- Or yield raw tokens and let UI handle accumulation

**Decision**: Recommend yielding raw tokens + section boundary indicators, let UI handle reconstruction. Simpler and more robust.

**Testing**:
- Unit test: Stream produces section updates
- Unit test: Valid JSON can be reconstructed from stream
- Integration test: Generator validates partial outputs
- UI test: Views respond to streaming updates

#### 1.3: Update ViewModels to Handle Streaming

**File**: `Features/Notes/SOAPNoteViewModel.swift`

**Changes**:
1. Add streaming state:
```swift
@Published var streamingState: StreamingState = .idle
@Published var partialSOAPNote: SOAPNote = SOAPNote()
@Published var generationProgress: Float = 0.0

enum StreamingState {
    case idle
    case generating
    case validating
    case complete
    case failed(Error)
}
```

2. Add streaming generation method:
```swift
@MainActor
func generateSOAPNoteStreaming() async {
    streamingState = .generating
    partialSOAPNote = SOAPNote()

    do {
        let stream = generator.generateSOAPNoteStreaming(from: context)

        for try await update in stream {
            // Accumulate tokens by section
            switch update.section {
            case .subjective:
                partialSOAPNote.subjective += update.token
            case .objective:
                partialSOAPNote.objective += update.token
            case .assessment:
                partialSOAPNote.assessment += update.token
            case .plan:
                partialSOAPNote.plan += update.token
            }

            generationProgress = min(0.95, Float(update.totalTokensReceived) / 1024.0)
        }

        // Validate complete output
        streamingState = .validating
        try validateSOAPNote(partialSOAPNote)

        streamingState = .complete
    } catch {
        streamingState = .failed(error)
    }
}
```

3. Keep existing `generateSOAPNote()` for backwards compatibility (non-streaming paths, tests)

**Testing**:
- Unit test: ViewModel state transitions correctly
- Unit test: Tokens accumulate correctly by section
- UI test: Progress indicator updates
- Integration test: Complete workflow (generate → validate → save)

#### 1.4: Update UI Views for Streaming Display

**File**: `Features/Notes/SOAPNoteReviewView.swift`

**Changes**:
1. Add streaming UI elements:
```swift
@State private var displayedText: [SOAPSection: String] = [:]
@State private var showGenerationProgress = false
```

2. Update generate button:
```swift
Button(action: { Task { await viewModel.generateSOAPNoteStreaming() } }) {
    switch viewModel.streamingState {
    case .idle:
        Label("Generate Note", systemImage: "sparkles")
    case .generating, .validating:
        HStack {
            ProgressView()
            Text("Generating... \(Int(viewModel.generationProgress * 100))%")
        }
    case .complete:
        Label("Generate Complete", systemImage: "checkmark.circle.fill")
    case .failed:
        Label("Generation Failed", systemImage: "exclamationmark.circle.fill")
    }
}
.disabled(viewModel.streamingState == .generating || viewModel.streamingState == .validating)
```

3. Display streaming output in real-time:
```swift
VStack {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Section("Subjective") {
                Text(viewModel.partialSOAPNote.subjective)
                    .redacted(reason: viewModel.streamingState == .generating ? .placeholder : [])
            }
            // Repeat for objective, assessment, plan
        }
    }

    // Show validation state
    if case .validating = viewModel.streamingState {
        HStack {
            ProgressView()
            Text("Validating for safety...")
        }
        .padding()
    }
}
```

4. Alternative: Token-by-token animation
```swift
// For mobile performance, accumulate tokens and update every 100ms
// instead of on each token for smooth rendering
```

**Testing**:
- UI test: Progress indicator displays
- UI test: Text appears in real-time
- UI test: Button states transition correctly
- Performance test: UI updates don't block token generation

### Files Modified in Step 1

1. `Domain/ML/MLXModelLoader.swift` - Add `generateStreaming()` method
2. `Domain/Services/SOAPNoteGenerator.swift` - Add streaming wrapper
3. `Features/Notes/SOAPNoteViewModel.swift` - Add streaming state management
4. `Features/Notes/SOAPNoteReviewView.swift` - Update UI for streaming display
5. New: `Domain/Models/StreamingModels.swift` - Define `SOAPStreamUpdate`, streaming enums

### Verification Steps - Step 1

**Build Verification**:
```bash
xcodebuild build -project MediScribe.xcodeproj \
  -scheme MediScribe \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
# Expected: BUILD SUCCEEDED
```

**Unit Test Verification**:
```bash
xcodebuild test -project MediScribe.xcodeproj \
  -scheme MediScribe \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:MediScribeTests/MLXModelBridgeTests
# Expected: All streaming tests pass
```

**Manual Testing**:
- [ ] App launches without crashes
- [ ] SOAP note generation starts immediately with progress indicator
- [ ] Tokens appear in real-time (text grows as generation continues)
- [ ] Progress percentage updates frequently
- [ ] Validation runs after generation completes
- [ ] Complete note saves after clinician review
- [ ] No UI blocking during token generation

---

## Step 2: Multi-Language Support

### Objective

Enable MediScribe interface and clinical documentation support in Spanish, French, and Portuguese for international NGO deployment. Includes UI localization + prompt generation in target language.

### Architecture Overview

**Languages Supported**:
1. English (current default)
2. Spanish (es_ES, es_MX)
3. French (fr_FR, fr_CA)
4. Portuguese (pt_PT, pt_BR)

**Components to Localize**:
1. UI strings (buttons, labels, sections, errors)
2. Model prompts (must work with multilingual MedGemma variant)
3. Validation messages
4. Safety guidelines in prompts
5. Limitations statements (translated but exact match still enforced)

### Implementation Breakdown

#### 2.1: Set Up Localization Infrastructure

**File**: New `Resources/Localizable.xcstrings`

**Approach**: Use Xcode 15+ xcstrings format for native Apple localization

**Actions**:
1. Create `Localizable.xcstrings` in Xcode project
2. Extract all user-facing strings from codebase
3. Provide translations for Spanish, French, Portuguese

**Coverage Areas**:
- UI labels: "Generate SOAP Note", "Review & Sign", "Clinician Review Required"
- Section headers: "Subjective", "Objective", "Assessment", "Plan"
- Error messages: "Unable to generate compliant output. Please document manually."
- Safety disclaimers: "This content is draft. Clinician review required."
- Form labels: "Patient Name", "Age", "Chief Complaint", "Vital Signs"

**Translations Required** (~150 strings):
- Spanish translator provided
- French translator provided
- Portuguese translator provided

**Testing**:
- Build test: No missing translations
- UI test: All languages display correctly
- Accessibility test: Strings don't overflow UI elements

#### 2.2: Add Language Selection Setting

**File**: `Features/Settings/SettingsView.swift`

**Changes**:
1. Add language picker:
```swift
Picker("Language", selection: $viewModel.selectedLanguage) {
    Text("English").tag(Language.english)
    Text("Español").tag(Language.spanish)
    Text("Français").tag(Language.french)
    Text("Português").tag(Language.portuguese)
}
```

2. Persist selection to User Defaults:
```swift
struct AppSettings {
    @AppStorage("selectedLanguage") var language: String = "en"
}
```

3. Update app environment when language changes:
```swift
.environment(\.locale, Locale(identifier: selectedLanguageCode))
```

**Testing**:
- UI test: Language picker appears in Settings
- Unit test: Language selection persists across app launches
- UI test: UI updates immediately when language changed

#### 2.3: Multilingual Prompt Engineering

**File**: `Domain/Prompts/LocalizedPrompts.swift` (NEW)

**Changes**:
1. Create language-specific prompt builders:
```swift
struct LocalizedPromptBuilder {
    let language: Language

    func buildSOAPPrompt(from context: PatientContext) -> String {
        switch language {
        case .english:
            return EnglishPrompts.soAPPrompt(context)
        case .spanish:
            return SpanishPrompts.soAPPrompt(context)
        case .french:
            return FrenchPrompts.soAPPrompt(context)
        case .portuguese:
            return PortuguesePrompts.soAPPrompt(context)
        }
    }
}
```

2. Each language maintains safety constraints:
```swift
struct SpanishPrompts {
    static func soAPPrompt(_ context: PatientContext) -> String {
        """
        Eres un asistente de documentación clínica. Genera una nota SOAP basada en el contexto del paciente.

        RESTRICCIONES DE SEGURIDAD CRÍTICAS:
        - NO diagnostiques ni hagas diagnósticos
        - NO recomiendes tratamientos
        - Solo describe lo que está en el contexto
        - El contenido es BORRADOR - revisión clínica requerida

        [Rest of prompt in Spanish with same safety guidelines]
        """
    }
}
```

3. Critical: Limitations statements translated but validated exactly:
```swift
// English (validated as exact match)
let englishLimitations = "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."

// Spanish (still validated as exact match in Spanish)
let spanishLimitations = "Este resumen describe solo las características visibles de la imagen y no evalúa significancia clínica ni proporciona diagnóstico."

// Validator must accept both forms for their respective languages
```

**Challenge**: Maintaining safety across languages
- Forbidden phrase detection must work in all languages
- Text sanitization logic applies universally
- Model must respond in selected language (verify with few-shot examples in prompt)

**Decision**: Include language specification in prompt header + few-shot examples in target language to guide model

**Testing**:
- Unit test: SOAP prompt generated in correct language
- Unit test: Safety disclaimers present in target language
- Integration test: Model generates response in target language
- Safety test: Forbidden phrases detected in Spanish/French/Portuguese variants

#### 2.4: Extend Safety Validators for Multilingual

**File**: `Domain/Validators/TextSanitizer.swift`

**Changes**:
1. Add language detection:
```swift
class MultilingualTextSanitizer {
    func detectLanguage(_ text: String) -> Language {
        // Use linguistic analysis or model hint from context
        // Default to app's selected language
    }

    func sanitizeAndDetectForbidden(
        _ text: String,
        language: Language
    ) throws -> Bool {
        let sanitized = sanitize(text, for: language)
        return detectForbiddenPhrases(sanitized, language: language)
    }
}
```

2. Language-specific forbidden phrase lists:
```swift
private let forbiddenPhrases: [Language: [String]] = [
    .english: ["diagnosis", "diagnose", "cancer", "pneumonia", ...],
    .spanish: ["diagnóstico", "diagnosticar", "cáncer", "neumonía", ...],
    .french: ["diagnostic", "diagnostiquer", "cancer", "pneumonie", ...],
    .portuguese: ["diagnóstico", "diagnosticar", "câncer", "pneumonia", ...]
]
```

3. Language-specific sanitization:
```swift
func sanitize(_ text: String, for language: Language) -> String {
    var sanitized = text.lowercased()

    // Remove diacritics (works for Romance languages)
    sanitized = sanitized.folding(options: .diacriticInsensitive, locale: .current)

    // Remove language-specific punctuation
    switch language {
    case .french:
        // French: remove « and » guillemets
        sanitized = sanitized.replacingOccurrences(of: "[«»]", with: "", options: .regularExpression)
    case .spanish, .portuguese:
        // Spanish/Portuguese: remove inverted punctuation
        sanitized = sanitized.replacingOccurrences(of: "[¿¡]", with: "", options: .regularExpression)
    default:
        break
    }

    return sanitized
}
```

**Testing**:
- Unit test: Spanish forbidden phrases detected (e.g., "neumonía")
- Unit test: French forbidden phrases detected (e.g., "pneumonie")
- Unit test: Portuguese forbidden phrases detected (e.g., "pneumonia")
- Safety test: Obfuscation attempts blocked across languages

#### 2.5: Update Core Data for Language Storage

**File**: `MediScribe.xcdatamodeld/` (add language attribute)

**Changes**:
1. Add `generationLanguage` attribute to SOAPNote entity:
```
generationLanguage: String, Optional, default: "en"
```

2. Rationale: Clinical audit trail - shows what language clinician reviewed in

**Testing**:
- Unit test: Language persists when saving note
- Query test: Can filter notes by language

### Files Modified in Step 2

1. `Resources/Localizable.xcstrings` - NEW: All UI string translations
2. `Features/Settings/SettingsView.swift` - Add language picker
3. `Domain/Prompts/LocalizedPrompts.swift` - NEW: Language-specific prompts
4. `Domain/Validators/TextSanitizer.swift` - Add multilingual support
5. `Domain/Services/SOAPNoteGenerator.swift` - Use localized prompts
6. `Domain/ML/ImagingModelManager.swift` - Use localized prompts for imaging
7. `MediScribe.xcdatamodeld/` - Add generationLanguage attribute

### Verification Steps - Step 2

**Localization Verification**:
```bash
# Check for missing translations
xcodebuild -project MediScribe.xcodeproj \
  -scheme MediScribe \
  -configuration Release build 2>&1 | grep -i "missing localizable"
```

**Language Settings Test**:
- [ ] Settings view shows language picker
- [ ] Language selection persists after app restart
- [ ] UI updates to selected language immediately
- [ ] All user-facing text translated in selected language

**Multilingual Safety Test**:
- [ ] Generate SOAP note in Spanish - output in Spanish, passes validation
- [ ] Generate SOAP note in French - output in French, passes validation
- [ ] Generate SOAP note in Portuguese - output in Portuguese, passes validation
- [ ] Forbidden phrases blocked in all languages

**Model Behavior Test**:
- [ ] Imaging findings generated in selected language
- [ ] Lab results labels translated (test names in local language if possible)
- [ ] Safety disclaimers appear in selected language

---

## Step 3: Offline Sync Improvements

### Objective

Enable robust background task queueing for scenarios where clinician works offline, then syncs when connection available. Improves workflow for intermittent connectivity settings.

### Architecture Overview

**Current State**: App works offline (no network dependency), but complex workflows with multiple notes aren't queued intelligently.

**New State**:
- Background queue tracks pending operations
- Tasks retry intelligently with exponential backoff
- Sync status visible to user
- Conflict resolution (if notes modified remotely)

### Implementation Breakdown

#### 3.1: Create Sync Queue Infrastructure

**File**: `Domain/Services/SyncQueueManager.swift` (NEW)

**Structure**:
```swift
class SyncQueueManager: ObservableObject {
    @Published var pendingOperations: [SyncOperation] = []
    @Published var syncState: SyncState = .idle

    func queueOperation(_ operation: SyncOperation) throws
    func processPendingOperations() async throws
    func retryOperation(_ id: UUID) async throws
}

struct SyncOperation: Codable {
    let id: UUID
    let operationType: OperationType
    let entityID: UUID
    let timestamp: Date
    var retryCount: Int = 0
    var lastError: String?

    enum OperationType {
        case saveSOAPNote(noteID: UUID)
        case saveImagingFinding(findingID: UUID)
        case saveLabResult(resultID: UUID)
    }
}

enum SyncState {
    case idle
    case syncing
    case paused  // User explicitly paused
    case error(Error)
}
```

**Persistence**: Store queue in Core Data for durability across app launches
- Create `SyncQueueItem` entity in Core Data model v6

**Testing**:
- Unit test: Operations queue correctly
- Unit test: Queue persists across app restart
- Integration test: Queue processes operations in order

#### 3.2: Add Background Task Support

**File**: `MediScribe/MediScribeApp.swift`

**Changes**:
1. Request background tasks:
```swift
import BackgroundTasks

@UIApplicationMain
struct MediScribeApp: App {
    init() {
        registerBackgroundTasks()
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.mediscribe.syncQueue",
            using: nil
        ) { task in
            handleSyncQueueTask(task as! BGProcessingTask)
        }
    }

    private func handleSyncQueueTask(_ task: BGProcessingTask) {
        let queue = SyncQueueManager.shared

        Task {
            do {
                try await queue.processPendingOperations()
                task.setTaskCompleted(success: true)
            } catch {
                // Reschedule for later
                scheduleSyncQueueTask()
                task.setTaskCompleted(success: false)
            }
        }
    }

    private func scheduleSyncQueueTask() {
        let request = BGProcessingTaskRequest(identifier: "com.mediscribe.syncQueue")
        request.requiresNetworkConnectivity = false
        try? BGTaskScheduler.shared.submit(request)
    }
}
```

2. Info.plist permissions:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.mediscribe.syncQueue</string>
</array>
```

**Testing**:
- Unit test: Background task request created
- Integration test: Background task executes (simulator-based testing)
- Device test: Queue syncs when app backgrounded

#### 3.3: Smart Retry Logic

**File**: `Domain/Services/SyncQueueManager.swift` (add methods)

**Implementation**:
```swift
func retryOperation(_ operation: SyncOperation) async throws {
    let maxRetries = 5
    let backoffMultiplier: Double = 2.0  // Exponential backoff

    if operation.retryCount >= maxRetries {
        throw SyncError.maxRetriesExceeded(operation)
    }

    // Calculate backoff: 1s, 2s, 4s, 8s, 16s
    let waitTime = pow(backoffMultiplier, Double(operation.retryCount))
    try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))

    // Perform retry
    do {
        try await executeOperation(operation)
        // Remove from queue on success
        remove(operation)
    } catch {
        // Update operation with error
        update(operation, error: error, incrementRetry: true)
    }
}
```

**Testing**:
- Unit test: Backoff times calculated correctly
- Unit test: Max retries enforced
- Integration test: Failed operation retried with backoff

#### 3.4: Sync Status UI

**File**: `Features/Settings/SyncStatusView.swift` (NEW)

**Display**:
```swift
VStack(spacing: 16) {
    HStack {
        Text("Sync Status")
            .font(.headline)
        Spacer()

        switch syncManager.syncState {
        case .idle:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("All Synced")
            }
        case .syncing:
            HStack {
                ProgressView()
                Text("Syncing...")
            }
        case .paused:
            HStack {
                Image(systemName: "pause.circle.fill")
                    .foregroundColor(.orange)
                Text("Paused")
            }
        case .error(let error):
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                Text("Sync Error")
            }
        }
    }

    if !syncManager.pendingOperations.isEmpty {
        Text("\(syncManager.pendingOperations.count) pending operations")
            .font(.caption)
            .foregroundColor(.secondary)

        VStack(spacing: 8) {
            ForEach(syncManager.pendingOperations) { operation in
                HStack {
                    Text(operation.operationType.description)
                        .font(.caption)
                    Spacer()

                    if operation.retryCount > 0 {
                        Text("Retry \(operation.retryCount)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(4)
            }
        }
    }
}
```

**Testing**:
- UI test: Sync status displays correctly
- UI test: Pending operations listed
- UI test: Retry count shown for failed operations

### Files Modified in Step 3

1. `Domain/Services/SyncQueueManager.swift` - NEW: Queue infrastructure
2. `MediScribe/MediScribeApp.swift` - Background task registration
3. `MediScribe.xcdatamodeld/` - NEW: SyncQueueItem entity
4. `Features/Settings/SyncStatusView.swift` - NEW: Sync status UI
5. `Features/Settings/SettingsView.swift` - Add sync status section
6. `Info.plist` - Add background task permissions

### Verification Steps - Step 3

**Build Verification**:
```bash
xcodebuild build -project MediScribe.xcodeproj \
  -scheme MediScribe \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
# Expected: BUILD SUCCEEDED
```

**Queue Functionality Test**:
- [ ] App queues operations when running
- [ ] Queue persists across app restart
- [ ] Settings view shows sync status
- [ ] Pending operations counted correctly

**Background Task Test** (device only):
- [ ] Request background processing
- [ ] Disable WiFi
- [ ] Generate SOAP note (queued offline)
- [ ] Re-enable WiFi
- [ ] App syncs in background
- [ ] Note marked as synced

---

## Step 4: Model Fine-Tuning Framework

### Objective

Create infrastructure for medical domain-specific model adaptation using on-device transfer learning or LoRA (Low-Rank Adaptation). Enables customization for specific clinical contexts without retraining entire model.

### Architecture Overview

**Approach**: LoRA fine-tuning on MLX

- Load base MedGemma 1.5 4B model
- Apply LoRA adapters (~5-10% additional parameters)
- Fine-tune on clinical examples from specific deployment
- Merge adapters for inference or keep separate

**Use Case**: NGO in specific region can fine-tune model on local disease patterns, local terminology, local guidelines.

### Implementation Breakdown

#### 4.1: Create LoRA Infrastructure

**File**: `Domain/ML/LoRAAdapter.swift` (NEW)

**Structure**:
```swift
class LoRAAdapter {
    struct Config {
        let rank: Int = 16  // LoRA rank
        let alphaScaling: Float = 32.0  // alpha = 2 * rank typically
        let targetLayers: [String]  // Which layers to adapt
        let freezeBase: Bool = true  // Keep base model frozen
    }

    let baseModel: MLXModule
    let loraWeights: [String: MLXArray]
    let config: Config

    func forwardWithLoRA(
        input: MLXArray,
        layerName: String
    ) -> MLXArray {
        // Standard forward pass through base layer
        let baseOutput = baseModel.forward(input, layerName: layerName)

        // Add LoRA contribution: output = base_output + alpha/r * A @ B
        if let loraWeights = loraWeights["\(layerName)_lora"] {
            let loraContribution = applyLoRA(input, weights: loraWeights)
            return baseOutput + loraContribution
        }

        return baseOutput
    }
}
```

**Testing**:
- Unit test: LoRA adapter initialized correctly
- Unit test: LoRA weights applied to forward pass
- Performance test: Inference with LoRA within acceptable latency

#### 4.2: Data Collection & Preparation

**File**: `Domain/ML/FineTuningDataset.swift` (NEW)

**Structure**:
```swift
struct FineTuningExample {
    let patientContext: PatientContext
    let clinicianGeneratedSOAP: String  // Ground truth
    let timestamp: Date
    let clinicianID: String
}

class FineTuningDataset {
    var examples: [FineTuningExample] = []

    func addExample(
        context: PatientContext,
        referenceOutput: String
    ) throws {
        // Validate output passes safety validators
        try SOAPResponseParser().validateSOAPFormat(referenceOutput)

        examples.append(FineTuningExample(
            patientContext: context,
            clinicianGeneratedSOAP: referenceOutput,
            timestamp: Date(),
            clinicianID: UserDefaults.standard.string(forKey: "clinicianID") ?? "unknown"
        ))
    }

    func saveToFile(_ path: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(examples)
        try data.write(to: URL(fileURLWithPath: path))
    }
}
```

**UI for Collection**:
- Settings: "Enable training data collection" toggle
- When enabled: After each signed note, prompt "Would you like to use this as training data?"
- Clinician confirms → example added to dataset
- Privacy: All training data stays on device, never sent elsewhere
- Export: Option to export dataset for manual review

**Testing**:
- Unit test: Example added to dataset
- Unit test: Invalid examples rejected
- UI test: Data collection prompt appears

#### 4.3: Fine-Tuning Pipeline

**File**: `Domain/ML/FineTuningManager.swift` (NEW)

**Process**:
```swift
class FineTuningManager {
    let baseModel: MLXModelBridge
    let dataset: FineTuningDataset
    let config: LoRAAdapter.Config

    @Published var trainingProgress: Float = 0.0
    @Published var trainingState: TrainingState = .idle

    enum TrainingState {
        case idle
        case loading
        case training
        case evaluating
        case complete
        case failed(Error)
    }

    func startFineTuning(
        epochs: Int = 3,
        batchSize: Int = 4,
        learningRate: Float = 1e-4
    ) async throws {
        trainingState = .loading

        // 1. Initialize LoRA weights
        let lora = try LoRAAdapter(
            baseModel: baseModel.model,
            config: config
        )

        trainingState = .training

        // 2. Training loop
        for epoch in 0..<epochs {
            let batches = dataset.examples.chunked(into: batchSize)

            for (batchIdx, batch) in batches.enumerated() {
                // Forward pass with LoRA
                let predictions = try batchForward(batch, using: lora)

                // Compute loss
                let loss = computeLoss(predictions, targets: batch)

                // Backward pass (MLX supports automatic differentiation)
                let gradients = try loss.gradients()

                // Update only LoRA weights
                try updateLoRAWeights(lora, gradients: gradients, learningRate: learningRate)

                trainingProgress = Float((epoch * batches.count + batchIdx) / (epochs * batches.count))
            }
        }

        trainingState = .evaluating

        // 3. Evaluate on held-out test set
        let testAccuracy = try evaluateModel(lora, on: dataset.testExamples)

        // 4. Save LoRA weights
        try saveLoRAWeights(lora, testAccuracy: testAccuracy)

        trainingState = .complete
    }
}
```

**Key Constraints**:
- Safety validators still enforced on fine-tuned outputs
- Cannot weaken safety constraints through fine-tuning
- Base model frozen - only LoRA weights change
- Validation on medical data only (confirmed by clinician)

**Testing**:
- Unit test: LoRA weights initialized
- Unit test: Training loop executes without crashes
- Integration test: Fine-tuned model produces valid outputs
- Safety test: Fine-tuned outputs still pass safety validators

#### 4.4: Model Selection & Switching

**File**: `Domain/ML/ImagingModelManager.swift` (extend)

**Changes**:
1. Support multiple model variants:
```swift
class ImagingModelManager: ObservableObject {
    @Published var availableModels: [ModelVariant] = []
    @Published var selectedModel: ModelVariant = .baseMedGemma

    enum ModelVariant {
        case baseMedGemma  // Original 1.5 4B
        case finetuned  // With LoRA adapter

        var modelPath: String {
            switch self {
            case .baseMedGemma:
                return "~/MediScribe/models/medgemma-1.5-4b-it-mlx/"
            case .finetuned:
                return "~/MediScribe/models/medgemma-1.5-4b-it-mlx/"  // Base + LoRA weights
            }
        }
    }
}
```

2. Loading logic:
```swift
func loadSelectedModel() async throws {
    let modelWeights = try MLXModelLoader.loadModel(at: selectedModel.modelPath)

    if selectedModel == .finetuned {
        // Load and merge LoRA weights if available
        let loraWeights = try LoRAAdapter.loadWeights()
        currentModel = try mergeLoRA(modelWeights, loraWeights: loraWeights)
    } else {
        currentModel = modelWeights
    }
}
```

3. UI in Settings:
```swift
Section("Model Selection") {
    Picker("Model Variant", selection: $modelManager.selectedModel) {
        Text("Base Model (MedGemma 1.5)").tag(ModelVariant.baseMedGemma)

        if modelManager.availableModels.contains(.finetuned) {
            Text("Fine-tuned (Custom)").tag(ModelVariant.finetuned)
        }
    }

    if modelManager.selectedModel == .finetuned {
        Text("Using custom fine-tuned model")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
```

**Testing**:
- Unit test: Both model variants load correctly
- UI test: Model selection picker works
- Integration test: Outputs consistent with selected model

### Files Modified in Step 4

1. `Domain/ML/LoRAAdapter.swift` - NEW: LoRA adapter implementation
2. `Domain/ML/FineTuningDataset.swift` - NEW: Dataset collection
3. `Domain/ML/FineTuningManager.swift` - NEW: Training pipeline
4. `Domain/ML/ImagingModelManager.swift` - Add model variant support
5. `Features/Settings/SettingsView.swift` - Add fine-tuning UI
6. `Features/Settings/FineTuningView.swift` - NEW: Training control UI

### Verification Steps - Step 4

**Build Verification**:
```bash
xcodebuild build -project MediScribe.xcodeproj \
  -scheme MediScribe \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
# Expected: BUILD SUCCEEDED
```

**Data Collection Test**:
- [ ] Settings toggle for data collection
- [ ] Prompt appears after signing note
- [ ] Training examples saved locally

**Fine-Tuning UI Test** (device only):
- [ ] Fine-tuning control appears in Settings
- [ ] Can start fine-tuning with sample dataset
- [ ] Progress indicator shows training progress
- [ ] Training completes without crashes

**Model Switching Test**:
- [ ] Both model variants available in settings
- [ ] Selecting model variant works
- [ ] Outputs remain valid after switching

---

## Critical Cross-Phase Considerations

### Safety Preservation (All Steps)

**Non-Negotiable**: Every step must maintain Phase 6 safety standards
- All generated outputs still pass validators
- Forbidden phrases still blocked
- Limitations statements still mandatory
- Clinician review still required
- No relaxation of constraints

**Validation for Step 1**: Streaming tokens are validated in aggregate (full output validated after generation)

**Validation for Step 2**: Multilingual outputs validated in target language (French forbidden phrases detected in French, etc.)

**Validation for Step 3**: Queued operations validated before saving (same validators as non-queued)

**Validation for Step 4**: Fine-tuned outputs validated with base validators + custom validation if needed

### Performance Impact (All Steps)

**Step 1** (Streaming): No inference change, UI handles streaming display. **Impact**: +0-5% overhead for yielding tokens

**Step 2** (Languages): Prompt size may increase slightly. **Impact**: +5-10% token count, +500-1000ms generation time

**Step 3** (Sync): Background processing doesn't affect foreground performance. **Impact**: +50-100MB memory for queue, minimal CPU impact

**Step 4** (Fine-tuning): LoRA adds ~5% parameters. **Impact**: +100-200MB memory, no significant inference latency change

### Testing Strategy (All Steps)

1. **Build Phase**: All steps must compile without warnings
2. **Unit Test Phase**: Each component tested in isolation
3. **Integration Test Phase**: Components tested together
4. **Safety Audit Phase**: All outputs validated, forbidden phrases still blocked
5. **Performance Phase**: Benchmarks remain within Phase 6 targets
6. **Device Phase**: Manual testing on iPhone 15 Pro before release

---

## Success Criteria for Phase 8

Phase 8 is complete when all four steps are implemented and verified:

✅ **Step 1 (Streaming)**:
- Tokens appear in real-time during generation
- Progress indicator updates frequently
- No blocking of UI during token generation
- All existing tests still pass
- Safety validation works on streamed output

✅ **Step 2 (Multi-Language)**:
- Interface available in 4 languages (English, Spanish, French, Portuguese)
- Language setting persists
- Prompts generated in target language
- Model responds in target language
- Forbidden phrases detected in all languages

✅ **Step 3 (Offline Sync)**:
- Operations queue correctly when offline
- Queue persists across app restart
- Sync processes queued operations
- Retry logic with exponential backoff works
- Sync status visible to user

✅ **Step 4 (Fine-Tuning)**:
- LoRA adapter infrastructure in place
- Training data collected from clinician outputs
- Fine-tuning pipeline executes without errors
- Fine-tuned model variant can be selected
- Fine-tuned outputs still pass safety validators

✅ **Overall**:
- All Phase 6 tests still passing (no regressions)
- All safety validators still enforced
- Performance within acceptable bounds
- Device testing completed on iPhone 15 Pro
- User documentation updated

---

## Estimated Effort Per Step

- **Step 1 (Streaming)**: Manageable scope, high impact
- **Step 2 (Multi-Language)**: Large localization effort, moderate code changes
- **Step 3 (Offline Sync)**: Medium complexity, good for robustness
- **Step 4 (Fine-Tuning)**: High complexity, requires ML expertise

**Recommended Approach**: Implement in order (1→2→3→4), completing each step fully before starting next.

**Fallback**: If any step causes instability, revert to stable Phase 6 state and defer to later phase.

---

## Risk Assessment

### Step 1 (Streaming) - Low Risk
- UI updates only, no model changes
- AsyncThrowingStream well-established in Swift
- Easy to rollback to non-streaming

### Step 2 (Multi-Language) - Medium Risk
- Localization is straightforward technical work
- Safety validators must work in all languages (requires validation)
- Prompt engineering may need iteration for quality

### Step 3 (Offline Sync) - Medium Risk
- Background tasks require testing on real device
- Queue persistence must be robust
- Conflict resolution edge cases may appear

### Step 4 (Fine-Tuning) - High Risk
- MLX fine-tuning infrastructure new (not battle-tested)
- Performance characteristics unknown on-device
- Safety constraints during training must be enforced rigorously
- Training data quality affects output quality

**Mitigation**: Each step has clear rollback plan, tested independently before integration.

---

## Next Actions

1. **User Approval**: Review this plan and request any changes
2. **Execute Step 1**: Implement streaming token generation
3. **Verify Step 1**: Run all tests, confirm no regressions, manual testing
4. **Commit Step 1**: Git commit + push
5. **Execute Steps 2-4**: Sequential implementation following same pattern
6. **Final Safety Audit**: Confirm all safety gates still functional
7. **Device Testing**: Real iPhone 15 Pro validation before Phase 7 deployment

---

**Phase 8 Status**: Ready for implementation upon user approval

**Expected Outcome**: MediScribe with advanced features (streaming, localization, offline robustness, customization capability) while maintaining all Phase 6 safety standards.

