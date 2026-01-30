# MediScribe Component Build Guides for Figma

**Target**: SwiftUI developers building clinical interfaces for iOS/iPadOS
**Framework**: SwiftUI + Core Data
**Design System**: See `DESIGN_SYSTEM.md` for tokens

---

## Table of Contents

1. [Clinical Input Components](#clinical-input-components)
   - [Large Number Pad](#large-number-pad)
   - [Vitals Input Fields](#vitals-input-fields)
   - [Chief Complaint Input](#chief-complaint-input)

2. [Clinical Review Components](#clinical-review-components)
   - [Clinician Review Toggle](#clinician-review-toggle)
   - [Limitations Statement Card](#limitations-statement-card)
   - [Signature Approval Button](#signature-approval-button)

3. [Clinical Display Components](#clinical-display-components)
   - [SOAP Note Display Card](#soap-note-display-card)
   - [Findings Display Card](#findings-display-card)
   - [Lab Results Display Card](#lab-results-display-card)

4. [Form Components](#form-components)
   - [Clinical Text Field](#clinical-text-field)
   - [Multi-Select Dropdown](#multi-select-dropdown)
   - [Dynamic List Item](#dynamic-list-item)

---

# Clinical Input Components

## Large Number Pad

**Purpose**: Field-optimized number input for vital signs (large touch targets, minimal taps)

**Use Cases**:
- Blood pressure entry (systolic/diastolic)
- Temperature input
- Heart rate entry
- Respiratory rate entry
- Oxygen saturation input

### Step 1: Create Main Frame (10 min)

1. **New frame**: 393 × 500pt (iPhone width)
2. **Name it**: `NumberPad/Default`
3. **Fill**: Light background color (use Design/Surface color token)
4. **Grid**: Enable 6-column grid, 16pt gutter for alignment

### Step 2: Add Display Area (5 min)

1. **Create frame**: 360 × 80pt (within the main frame)
2. **Position**: Top, 16pt margins
3. **Name**: `DisplayArea`
4. **Fill**: Dark background (use Design/Background)
5. **Border**: 1pt separator color
6. **Radius**: 8pt

**Add text inside DisplayArea**:
- Rectangle: 360 × 60pt for input value display
- Text: "0" (placeholder)
  - Font: SF Pro Display, 48pt, Bold
  - Color: Primary text color
  - Alignment: Right-aligned, 16pt padding

### Step 3: Create Number Buttons Grid (20 min)

1. **Create 4×3 grid** of buttons (4 columns, 3 rows)
2. **Button frame**: 80 × 80pt each
3. **Spacing**: 8pt between buttons
4. **Container frame**: 344 × 272pt (4 cols × 80pt + 24pt spacing + 16pt padding)

**Button Layout** (left to right, top to bottom):
```
[1]  [2]  [3]  [Clear]
[4]  [5]  [6]  [0]
[7]  [8]  [9]  [Backspace]
```

### Step 4: Design Individual Button (for each number)

**Button Structure** (80×80pt):

1. **Background**:
   - Fill: Clinical/Primary color (e.g., blue)
   - Corner radius: 8pt
   - Opacity: 100% default

2. **Text Label**:
   - Content: "1" (or respective number)
   - Font: SF Pro Display, 32pt, Semibold
   - Color: White
   - Alignment: Center
   - Vertical: Middle

3. **Add Auto Layout**:
   - Direction: Vertical
   - Alignment: Center
   - Padding: 0 (text is centered)

### Step 5: Design Special Buttons

**Clear Button** (top-right):
- Background: Warning color (orange/yellow)
- Text: "C" or icon (X symbol)
- Font: 28pt, Semibold
- Interaction: On tap → clear all

**Backspace Button** (bottom-right):
- Background: Secondary color (gray)
- Icon: SF Symbol "delete.left.fill"
- Size: 24pt
- Interaction: On tap → remove last digit

**Zero Button** (larger, spans 2 columns):
- Width: 168pt (2 buttons + 8pt spacing)
- All other properties same as number buttons

### Step 6: Create Component with Variants (10 min)

1. **Select all buttons + display**: `Cmd+Alt+K` (Mac) or `Ctrl+Alt+K` (Win)
2. **Name component**: `NumberPad`
3. **Right panel**: Click "+" next to "Variants"
4. **Add variant property**: `State`
5. **Add values**: `Default`, `Pressed`, `Disabled`

**Default State**: As designed above

**Pressed State**:
- When a button is tapped, reduce opacity to 85%
- Add slight scale down (98%)

**Disabled State**:
- All buttons: opacity 50%
- Display text: opacity 75%

### Step 7: Document in Figma

Add notes to the component:
```
NumberPad Component

Used for: Vital signs input (BP, HR, Temp, RR, O2 Sat)

States:
- Default: Ready for input
- Pressed: User tapping a number
- Disabled: When input is locked

Touch Target: 80×80pt min (exceeds 60pt requirement)
Spacing: 8pt between buttons for gloved input

Interactions:
- Number buttons: Add to input display
- Clear (C): Reset display to "0"
- Backspace: Remove last digit entered

Development Notes:
- SwiftUI: Use @State for input value
- Accessibility: Each button needs VoiceOver label
- Animation: ~200ms scale when pressed
```

### SwiftUI Implementation Reference

```swift
struct NumberPadComponent: View {
    @State private var inputValue = "0"

    var body: some View {
        VStack(spacing: 16) {
            // Display area
            HStack {
                Spacer()
                Text(inputValue)
                    .font(.system(size: 48, weight: .bold))
                    .padding(.trailing, 16)
            }
            .frame(height: 60)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            // Number pad grid (4×3)
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    NumberButton("1", action: { append("1") })
                    NumberButton("2", action: { append("2") })
                    NumberButton("3", action: { append("3") })
                    ClearButton(action: { clear() })
                }
                // ... more rows
            }
        }
        .padding(16)
    }

    private func append(_ digit: String) {
        if inputValue == "0" {
            inputValue = digit
        } else {
            inputValue += digit
        }
    }

    private func clear() {
        inputValue = "0"
    }
}

struct NumberButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.blue)
                .cornerRadius(8)
        }
        .frame(height: 80)
        .accessibility(label: Text("Number \(label)"))
    }
}
```

---

## Vitals Input Fields

**Purpose**: Individual input fields for vital signs with validation and range indicators

**Use Cases**:
- Temperature input with °C/°F toggle
- Heart rate input with normal range indicator
- Blood pressure input (paired fields: systolic/diastolic)

### Step 1: Create Temperature Input Field (15 min)

**Frame**: 360 × 100pt

1. **Label Section** (top):
   - Text: "Temperature"
   - Font: 16pt, Semibold
   - Color: Primary text
   - Padding: 12pt top

2. **Input Row** (middle):
   - Background frame: 360 × 60pt
   - Border: 1pt, separator color
   - Radius: 8pt

   **Inside input row**:
   - Text input area: 280 × 60pt (left side)
     - Placeholder: "37.2"
     - Font: 28pt, Semibold
     - Color: Primary text
     - Padding: 12pt left

   - Unit toggle: 70 × 60pt (right side)
     - Buttons: "°C" | "°F"
     - Font: 16pt, Semibold
     - Active button: Blue background, white text
     - Inactive button: Light gray background, dark text

3. **Status Indicator** (bottom):
   - Text: "Normal (36.5 - 37.5°C)"
   - Font: 12pt, Regular
   - Color: Green (safe range)
   - Padding: 8pt top

### Step 2: Add Range Indicators (10 min)

Below the input field, add colored bar showing temperature ranges:

```
[BLUE: <36.5°C] [GREEN: 36.5-37.5°C] [ORANGE: 37.5-38.5°C] [RED: >38.5°C]
```

- Each section height: 8pt
- Total width: 360pt
- Corner radius: 4pt
- Add white indicator line at current input value position

### Step 3: Create Heart Rate Field (10 min)

**Frame**: 360 × 100pt

Similar to Temperature but:
- Label: "Heart Rate"
- Input format: "72" (no decimals)
- Unit: "bpm" (static, not toggleable)
- Range indicator text: "Normal (60 - 100 bpm)"
- Color coding: Green (60-100), Orange (50-60, 100-120), Red (<50, >120)

### Step 4: Create Blood Pressure Field (15 min)

**Frame**: 360 × 120pt

Two input fields stacked:

1. **Systolic**:
   - Label: "Systolic"
   - Input placeholder: "120"
   - Unit: "mmHg"
   - Normal range: 90-120

2. **Diastolic**:
   - Label: "Diastolic"
   - Input placeholder: "80"
   - Unit: "mmHg"
   - Normal range: 60-80

**Status display**: "Normal (SYS: 90-120, DIA: 60-80)"

**Color coding**:
- Green: Both within normal ranges
- Orange: One slightly elevated
- Red: Either significantly elevated or low

### Step 5: Make Components (10 min)

1. **Select entire Temperature field** → `Cmd+Alt+K`
2. **Name**: `VitalsInput/Temperature`
3. **Add variants**: `State` → `Default`, `Focused`, `Error`, `Disabled`
4. **Repeat for**: Heart Rate, Blood Pressure

**Focused State**:
- Border: 2pt, primary color
- Background slight highlight

**Error State**:
- Border: 2pt, red
- Status text: red, shows error message
- Example: "Please enter value 35-40°C"

**Disabled State**:
- Background opacity: 75%
- Text opacity: 60%
- Input not tappable

### SwiftUI Reference

```swift
struct TemperatureInputField: View {
    @State private var temperature = ""
    @State private var isFahrenheit = false
    @State private var validationError: String? = nil

    var temperatureStatus: (text: String, color: Color) {
        guard let temp = Double(temperature) else {
            return ("No input", .gray)
        }

        if temp < 36.5 {
            return ("Low", .blue)
        } else if temp <= 37.5 {
            return ("Normal", .green)
        } else if temp <= 38.5 {
            return ("Fever", .orange)
        } else {
            return ("High Fever", .red)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Temperature")
                .font(.system(size: 16, weight: .semibold))

            HStack {
                TextField("37.2", text: $temperature)
                    .font(.system(size: 28, weight: .semibold))
                    .padding(.leading, 12)
                    .keyboardType(.decimalPad)

                Picker(selection: $isFahrenheit, label: Text("")) {
                    Text("°C").tag(false)
                    Text("°F").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.trailing, 12)
                .frame(width: 70)
            }
            .frame(height: 60)
            .border(Color.gray.opacity(0.3))
            .cornerRadius(8)

            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(temperatureStatus.color)
                    .font(.system(size: 8))

                Text(temperatureStatus.text)
                    .font(.system(size: 12))
                    .foregroundColor(temperatureStatus.color)
            }
        }
    }
}
```

---

## Chief Complaint Input

**Purpose**: Multi-line text input for patient's primary complaint

**Frame**: 360 × 160pt

### Step 1: Create Input Field (10 min)

1. **Label**:
   - Text: "Chief Complaint"
   - Font: 16pt, Semibold
   - Padding: 12pt top

2. **Text Area** (120pt height):
   - Border: 1pt, separator color
   - Radius: 8pt
   - Padding: 12pt all sides
   - Placeholder: "Patient reports..."
   - Font: 16pt, Regular
   - Supports multi-line input (vertical scroll if needed)

3. **Character Counter** (bottom):
   - Text: "0 / 500 characters"
   - Font: 12pt, Regular
   - Color: Secondary text color
   - Alignment: Right

### Step 2: Add Status Indicator (5 min)

- Green check: When input > 10 characters
- Orange warning: When input > 400 characters
- Red error: When input = 500 characters (limit reached)

### Step 3: Create Component (5 min)

1. **Select all** → `Cmd+Alt+K`
2. **Name**: `Input/ChiefComplaint`
3. **Variants**: `State` → `Empty`, `Focused`, `Filled`, `Error`

**Empty**: Placeholder visible, counter shows 0/500

**Focused**:
- Border: 2pt, primary color
- Cursor visible

**Filled**:
- Text entered
- Counter updates
- Border: 1pt gray

**Error**:
- Border: 2pt red
- Message: "Please provide more detail (min. 10 characters)"

---

# Clinical Review Components

## Clinician Review Toggle

**Purpose**: Mandatory confirmation that clinician has reviewed AI-generated content before saving

**Frame**: 360 × 80pt

### Step 1: Create Toggle Button (15 min)

**Container**:
- Background: Light blue (info color at 10% opacity)
- Border: 1pt, info color
- Radius: 8pt
- Padding: 16pt all sides

**Content Layout** (Auto Layout, Horizontal):

1. **Checkbox** (left):
   - Frame: 24 × 24pt
   - Border: 2pt, info color
   - Radius: 4pt
   - **Checked state**:
     - Background: Info color (blue)
     - Icon: Checkmark (SF Symbol "checkmark")
     - Icon color: White
   - **Unchecked state**:
     - Background: Transparent
     - Border: 2pt, info color

2. **Text** (center, flexible):
   - Content: "I have reviewed this content and confirm it is accurate"
   - Font: 16pt, Regular
   - Color: Primary text
   - Line height: 1.5
   - Padding: 12pt left (from checkbox)

3. **Info Icon** (right):
   - Icon: "info.circle" (SF Symbol)
   - Size: 20 × 20pt
   - Color: Info color
   - Optional: On tap, show tooltip

### Step 2: Create Tooltip (optional, 10 min)

Small card that appears on info icon tap:

```
"All AI-generated content must be reviewed by a
clinician before it can be saved to the patient
record. This ensures accuracy and safety."
```

- Max width: 280pt
- Background: Dark overlay (80% opacity)
- Text color: White
- Font: 14pt, Regular
- Padding: 12pt
- Corner radius: 8pt
- Arrow pointing to icon

### Step 3: Make Component (5 min)

1. **Select entire toggle** → `Cmd+Alt+K`
2. **Name**: `Clinical/ReviewToggle`
3. **Variants**: `State` → `Unchecked`, `Checked`, `Disabled`

**Unchecked**:
- Checkbox: empty, border visible
- Background: light blue

**Checked**:
- Checkbox: filled blue with checkmark
- Background: light blue (slightly darker)

**Disabled**:
- Entire component: 50% opacity
- Not interactive

### Step 4: Add Interaction (5 min)

In Figma Prototype mode:

1. Click toggle component
2. Drag to alternate state (checked ↔ unchecked)
3. Set trigger: `On Tap`
4. Set action: `Toggle` or swap between variants

### SwiftUI Reference

```swift
struct ClinicalReviewToggle: View {
    @State private var isReviewed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: isReviewed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isReviewed ? .blue : .blue.opacity(0.3))
                    .onTapGesture {
                        withAnimation {
                            isReviewed.toggle()
                        }
                    }

                VStack(alignment: .leading, spacing: 0) {
                    Text("I have reviewed this content")
                        .font(.system(size: 16, weight: .semibold))
                    Text("All AI-generated content must be reviewed before saving")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .lineLimit(2)

                Spacer()

                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .padding(16)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
```

---

## Limitations Statement Card

**Purpose**: Display mandatory safety disclaimer that appears in AI-generated content

**Frame**: 360 × 120pt

### Step 1: Create Card Container (5 min)

- Background: Orange/yellow (warning color at 5% opacity)
- Border: 1pt, warning color
- Radius: 8pt
- Padding: 16pt all sides

### Step 2: Add Content (10 min)

**Header Row**:
- Icon: "exclamationmark.circle.fill" (SF Symbol, 20 × 20pt)
- Color: Warning color (orange)
- Text: "Limitations Statement"
- Font: 14pt, Semibold
- Color: Warning color

**Body Text**:
- Content: "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."
- Font: 13pt, Regular
- Color: Primary text
- Line height: 1.5
- Spacing: 8pt from header

### Step 3: Make Component (5 min)

1. **Select all** → `Cmd+Alt+K`
2. **Name**: `Safety/LimitationsStatement`
3. **No variants needed** (static display)

### Step 4: Add Notes

```
This component displays different text based on the feature:

Imaging Findings:
"This summary describes visible image features only and
does not assess clinical significance or provide a diagnosis."

Lab Results:
"This extraction shows ONLY the visible values from the
laboratory report and does not interpret clinical
significance or provide recommendations."

SOAP Notes:
"This note was generated by AI and requires clinician
review and modification before use."
```

### SwiftUI Reference

```swift
struct LimitationsStatementCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))

                Text("Limitations Statement")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
            }

            Text(text)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)
                .lineLimit(3)
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}
```

---

## Signature Approval Button

**Purpose**: Large button for clinician to sign/approve and save content

**Frame**: 360 × 60pt

### Step 1: Create Button (10 min)

**Background**:
- Color: Primary/Success color (blue or green)
- Radius: 8pt

**Content** (Auto Layout, Horizontal, centered):

1. **Icon** (left):
   - Icon: "checkmark.seal.fill" (SF Symbol)
   - Size: 20 × 20pt
   - Color: White
   - Spacing: 8pt from text

2. **Text** (center):
   - Content: "Sign & Save"
   - Font: 18pt, Semibold
   - Color: White
   - Alignment: Center

### Step 2: Add Padding (5 min)

- Vertical padding: 12pt top/bottom
- Horizontal padding: 16pt left/right
- Min height: 60pt (accessibility requirement)

### Step 3: Make Component (5 min)

1. **Select button** → `Cmd+Alt+K`
2. **Name**: `Clinical/SignButton`
3. **Variants**: `State` → `Default`, `Pressed`, `Disabled`, `Loading`

**Default**:
- Background: Blue
- Text: White
- Scale: 100%

**Pressed**:
- Background: Darker blue (90% of original)
- Scale: 95% (slight shrink on tap)

**Disabled**:
- Background: Gray (50% opacity)
- Text: Gray (60% opacity)
- Not interactive

**Loading**:
- Background: Blue
- Text: Hidden
- Add spinner: Animated circle (SF Symbol "hourglass.circle")
- Spinner size: 24pt
- Animation: Continuous rotation

### Step 4: Add Interaction (5 min)

1. Click button
2. Drag to "Loading" state
3. Trigger: On Tap
4. Animation: Push (200ms)

Then:

1. Add another interaction (from Loading back to Default)
2. Delay: 2000ms (simulate saving)
3. Animation: None

### SwiftUI Reference

```swift
struct SignApprovalButton: View {
    @State private var isLoading = false
    let onSign: () -> Void

    var body: some View {
        Button(action: {
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isLoading = false
                onSign()
            }
        }) {
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                    Text("Saving...")
                        .font(.system(size: 18, weight: .semibold))
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Sign & Save")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(Color.blue)
        .cornerRadius(8)
        .disabled(isLoading)
    }
}
```

---

# Clinical Display Components

## SOAP Note Display Card

**Purpose**: Read-only display of AI-generated SOAP note sections

**Frame**: 360 × variable (expands with content)

### Step 1: Create SOAP Section Header (5 min each)

**For each section (S/O/A/P)**:

1. **Header**:
   - Background: Section color (S=Blue, O=Green, A=Orange, P=Purple)
   - Padding: 12pt
   - Radius: 8pt (top only, no radius on bottom)

2. **Header content**:
   - Icon: SF Symbol representing section
     - S: "person.fill"
     - O: "stethoscope"
     - A: "brain.head.profile"
     - P: "checklist"
   - Text: "Subjective" (or respective section)
   - Font: 16pt, Semibold
   - Color: White

3. **Body**:
   - Background: Light gray (Color(.systemGray6))
   - Padding: 16pt all sides
   - Radius: 8pt (bottom only)
   - Border bottom: 1pt separator

4. **Text content**:
   - Font: 16pt, Regular
   - Color: Primary text
   - Line height: 1.6
   - Selectable (for copying)

### Step 2: Create Full SOAP Card (15 min)

Stack all 4 sections vertically with 0pt spacing between header/body:

```
[S Header]
[S Body]
[O Header]
[O Body]
[A Header]
[A Body]
[P Header]
[P Body]
```

- Total padding: 16pt around all sections
- Spacing between complete sections: 16pt

### Step 3: Add Edit Button (optional, 5 min)

- Position: Top-right of card
- Icon: "pencil.circle.fill" (SF Symbol)
- Size: 28 × 28pt
- Color: Primary
- On tap: Navigate to edit screen

### Step 4: Make Component (5 min)

1. **Select entire card** → `Cmd+Alt+K`
2. **Name**: `Display/SOAPNoteCard`
3. **Variants**: `State` → `Default`, `Edited`, `Signed`

**Default**:
- As designed above
- Edit button visible
- "Not signed" indicator

**Edited**:
- All sections: slightly different background (to show changes)
- Edit button visible
- "Pending signature" indicator

**Signed**:
- Edit button hidden
- Add checkmark badge: "Signed by Dr. Smith at 14:30"
- Lock icon in corner

### SwiftUI Reference

```swift
struct SOAPNoteDisplayCard: View {
    let soapNote: SOAPNoteData
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Subjective
            SOAPSection(
                title: "Subjective",
                icon: "person.fill",
                backgroundColor: Color.blue,
                content: soapNote.subjective.chiefComplaint
            )

            // Objective
            SOAPSection(
                title: "Objective",
                icon: "stethoscope",
                backgroundColor: Color.green,
                content: soapNote.objective.physicalExaminationFindings
            )

            // Assessment
            SOAPSection(
                title: "Assessment",
                icon: "brain.head.profile",
                backgroundColor: Color.orange,
                content: soapNote.assessment.problemStatement
            )

            // Plan
            SOAPSection(
                title: "Plan",
                icon: "checklist",
                backgroundColor: Color.purple,
                content: soapNote.plan.nextSteps
            )
        }
        .padding(16)
    }
}

struct SOAPSection: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(.white)
            .padding(12)
            .background(backgroundColor)
            .cornerRadius(8, corners: [.topLeft, .topRight])

            Text(content)
                .font(.system(size: 16, weight: .regular))
                .lineLimit(nil)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
        }
    }
}
```

---

## Findings Display Card

**Purpose**: Read-only display of AI-generated imaging findings

**Frame**: 360 × variable

### Step 1: Create Findings Header (5 min)

- Title: "Imaging Findings"
- Font: 18pt, Semibold
- Padding: 12pt
- Spacing: 8pt from content

### Step 2: Add Finding Sections (10 min)

For each anatomical region (Lungs, Pleural, Heart, Bones):

1. **Region Header**:
   - Text: "Lungs" (expandable/collapsible)
   - Font: 16pt, Semibold
   - Icon: Chevron down (expandable)
   - Background: Light background

2. **Region Content**:
   - List of findings
   - Font: 14pt, Regular
   - Bullet points
   - Padding: 16pt left indent

3. **Normal/Abnormal Badge** (optional):
   - Color: Green (no findings) or Orange (findings present)
   - Text: "No acute findings" or "See findings below"

### Step 3: Add Limitations Statement (5 min)

Include LimitationsStatement component at bottom

### Step 4: Make Component (5 min)

1. **Select card** → `Cmd+Alt+K`
2. **Name**: `Display/FindingsCard`
3. **Variants**: `State` → `Default`, `Reviewed`

---

## Lab Results Display Card

**Purpose**: Display extracted laboratory results in organized categories

**Frame**: 360 × variable

### Step 1: Create Lab Result Item (10 min)

**Item layout** (60pt height):

- Test name: 200pt (left)
  - Font: 14pt, Semibold
  - Color: Primary text

- Value: 80pt (center)
  - Font: 18pt, Semibold
  - Color: Primary text
  - Alignment: Right

- Unit: 60pt (right)
  - Font: 14pt, Regular
  - Color: Secondary text
  - Alignment: Right

- Optional: Reference range below (small gray text)

### Step 2: Group by Category (10 min)

1. **Category Header**:
   - Text: "Complete Blood Count"
   - Font: 16pt, Semibold
   - Background: Category color
   - Padding: 12pt

2. **Result Items** (stacked):
   - Border: 1pt separator between items
   - Padding: 12pt vertical

3. **Example**:
   ```
   [CBC Header]
   White Blood Cell Count  7.2  K/uL
   Red Blood Cell Count    4.8  M/uL
   Hemoglobin            14.2  g/dL
   [Metabolic Panel Header]
   Glucose                 95   mg/dL
   Creatinine             0.9  mg/dL
   ```

### Step 3: Add Color Coding (10 min)

Add optional range indicator badges:

- Green badge: "Normal" (value within reference range)
- Orange badge: "Low" or "High" (slightly abnormal)
- Red badge: "Critical" (significantly out of range)

Position: Right side, next to value

### Step 4: Make Component (5 min)

1. **Select card** → `Cmd+Alt+K`
2. **Name**: `Display/LabResultsCard`
3. **Variants**: `State` → `Default`, `Reviewed`, `Complete`

---

# Form Components

## Clinical Text Field

**Purpose**: Standard text input for clinical notes, patient names, comments

**Frame**: 360 × 80pt

### Step 1: Create TextField (10 min)

**Container**:
- Frame: 360 × 60pt
- Background: White
- Border: 1pt, separator color
- Radius: 8pt
- Padding: 12pt horizontal, 10pt vertical

**Label** (above):
- Text: "Patient Name" (configurable)
- Font: 14pt, Semibold
- Color: Primary text
- Spacing: 8pt from input

**Input text**:
- Placeholder: "Enter name..."
- Font: 16pt, Regular
- Color: Primary text
- Cursor color: Primary

### Step 2: Add States (10 min)

Create variants:

1. **Default**:
   - Border: 1pt gray
   - Background: White

2. **Focused**:
   - Border: 2pt primary color
   - Background: Light primary color (5% opacity)
   - Cursor visible

3. **Filled**:
   - Border: 1pt gray
   - Text entered
   - Clear button: Small X icon (right side)

4. **Error**:
   - Border: 2pt red
   - Background: Light red (5% opacity)
   - Error message below: "This field is required"
   - Font: 12pt, Regular, red color

5. **Disabled**:
   - Background: Light gray (75% opacity)
   - Text: Disabled gray
   - Not interactive

### Step 3: Make Component (5 min)

1. **Select field** → `Cmd+Alt+K`
2. **Name**: `Input/TextField`
3. **Add variants**: `State`

---

## Multi-Select Dropdown

**Purpose**: Select multiple items from a list (symptoms, medications, allergies)

**Frame**: 360 × variable

### Step 1: Create Closed Dropdown (10 min)

**Button state** (60pt height):
- Background: White
- Border: 1pt separator
- Radius: 8pt
- Padding: 12pt horizontal

**Content**:
- Label (left): "Select symptoms..."
- Icon (right): Chevron down
- Selected count: "2 selected" (shows when items selected)

### Step 2: Create Expanded List (15 min)

**List container** (opens below button):
- Background: White
- Border: 1pt
- Radius: 8pt
- Max height: 300pt (scrollable if more items)
- Spacing: 0 (items touch)

**List items** (40pt each):
- Checkbox: 24 × 24pt (left)
  - Checked: Blue background, white checkmark
  - Unchecked: Empty, 1pt border
- Item text: 200pt (center)
  - Font: 14pt, Regular
  - Selectable

- Divider: 1pt between items

**Search field** (optional, top):
- Frame: Full width, 44pt
- Placeholder: "Search..."
- Icon: Magnifying glass

### Step 3: Add Counter (5 min)

Show selected count below button:
- Font: 12pt, Regular
- Color: Secondary text
- Example: "3 of 12 selected"

### Step 4: Make Component (10 min)

1. **Select button** → `Cmd+Alt+K`
2. **Name**: `Input/MultiSelectDropdown`
3. **Main variants**: `State` → `Closed`, `Open`, `Filled`
4. **Sub-variants**: `Count` → `None`, `One`, `Multiple`

---

## Dynamic List Item

**Purpose**: Add/remove items from lists (medications, allergies, past medical history)

**Frame**: 360 × 50pt per item

### Step 1: Create List Item (10 min)

**Container**:
- Frame: 360 × 50pt
- Background: Light background
- Border: 1pt bottom separator
- Padding: 12pt horizontal, 8pt vertical

**Content** (Auto Layout, Horizontal):

1. **Drag handle** (optional, left):
   - Icon: "line.3.horizontal" (SF Symbol)
   - Color: Secondary
   - Width: 24pt

2. **Item text** (flexible):
   - Font: 16pt, Regular
   - Color: Primary text
   - Padding: 8pt left

3. **Delete button** (right):
   - Icon: "xmark.circle.fill"
   - Size: 24 × 24pt
   - Color: Red
   - On tap: Remove item

### Step 2: Add Item States (10 min)

1. **Default**:
   - Text visible
   - Delete button visible

2. **Editing**:
   - Background: Light blue (highlight)
   - Drag handle visible
   - Delete button more prominent

3. **Empty state**:
   - Text: "No items added"
   - Font: 14pt, Regular
   - Color: Secondary text
   - Alignment: Center
   - Padding: 24pt vertical

### Step 3: Create Add Item Button (10 min)

**Button** (60pt height):
- Icon: "plus.circle.fill"
- Text: "Add item"
- Color: Primary blue
- Background: Light blue (10% opacity)
- Border: 1pt dashed, primary color
- Radius: 8pt

### Step 4: Make Component (5 min)

1. **Select item** → `Cmd+Alt+K`
2. **Name**: `Input/DynamicListItem`
3. **Variants**: `State` → `Default`, `Editing`, `Empty`

---

## Summary

This guide provides step-by-step instructions for 10+ core components. Each component includes:

✅ Dimensions and spacing specifications
✅ Color and typography tokens
✅ State variants (Default, Focused, Error, Disabled, etc.)
✅ Interaction patterns and animations
✅ SwiftUI implementation reference code
✅ Accessibility considerations

**Next Steps**:

1. Designers: Follow guides above to build each component in Figma
2. Create main "Design System" page in Figma with all components
3. Create "Components" library page
4. Set up Code Connect mappings to link Figma components to SwiftUI code
5. Share with development team for implementation

**Questions?** Refer to `DESIGN_SYSTEM.md` for design tokens and architectural patterns.

