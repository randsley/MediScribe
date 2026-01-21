# Field-Optimized Vitals Entry Screen

## Complete Design Specification

This document provides detailed specifications for designing MediScribe's field-optimized vitals entry screen in Figma.

---

## Overview

**Purpose:** Enable rapid, accurate vital signs entry in challenging field conditions (gloves, movement, stress, sunlight).

**Key Requirements:**
- ✅ Large touch targets (80-100pt minimum)
- ✅ One vital at a time (reduce cognitive load)
- ✅ Visual feedback for ranges (normal/warning/critical)
- ✅ Minimal typing (number pad only)
- ✅ Quick navigation between vitals
- ✅ Clear progress indication
- ✅ Instant validation

**User Flow:**
```
Tap "Record Vitals" → Select Vital Type → Enter Value → See Visual Feedback →
Confirm → Next Vital → Repeat → Save All → Return to Note
```

---

## Screen 1: Vital Selection Grid

### Frame Specifications

**Device:** iPhone 15 Pro (393 × 852pt)
**Frame Name:** `Notes/Vitals-Entry/01-Selection`

### Layout Structure

```
┌─────────────────────────────────────┐
│ Status Bar (59pt)                   │
├─────────────────────────────────────┤
│ Navigation Bar (44pt)               │
│   ← Cancel    Record Vitals    Save │
├─────────────────────────────────────┤
│                                     │
│ Current Values Card (160pt)         │
│                                     │
├─────────────────────────────────────┤
│                                     │
│ Vital Selection Grid (500pt)       │
│   [BP]  [HR]                        │
│   [RR]  [SpO2]                      │
│   [Temp] [GCS]                      │
│                                     │
└─────────────────────────────────────┘
```

### 1. Navigation Bar (Top)

**Frame:** 393 × 44pt
**Background:** Background/Primary (#FFFFFF)
**Border Bottom:** 1pt, Border/Default (#E5E7EB)

**Content (Auto Layout, Horizontal, Space Between):**

**Left: Cancel Button**
- Text: "Cancel"
- Style: Field/Body/Regular
- Color: Field/Info (#3B82F6)
- Padding: 20pt left
- Touch Target: Extends to 44×44pt minimum

**Center: Title**
- Text: "Record Vitals"
- Style: Field/Title/Medium (28pt, Bold)
- Color: Text/Primary (#111827)

**Right: Save Button**
- Text: "Save"
- Style: Field/Body/Regular (Semibold)
- Color: Field/Safe (#10B981)
- Padding: 20pt right
- State: Disabled (gray) if no vitals entered

### 2. Current Values Card

**Frame:** 353 × 160pt (393 - 40pt margins)
**Position:** 20pt from screen edges
**Background:** Background/Secondary (#F9FAFB)
**Border:** 2pt, Border/Default (#E5E7EB)
**Corner Radius:** 12pt
**Padding:** 20pt all sides

**Header:**
- Text: "Current Values"
- Style: Field/Body/Large (20pt, Semibold)
- Color: Text/Primary
- Margin Bottom: 12pt

**Vital Values Grid (Auto Layout, Vertical, 8pt spacing):**

Each row structure:
```
[Label (60pt width)] [Value (flex)] [Edit Indicator (24pt)]
```

**Row Example - Blood Pressure:**
```
HStack, Space Between:
├── Label: "BP" (Field/Body/Regular, Text/Secondary)
├── Value: "120/80 mmHg" (Field/Body/Regular, Text/Primary or "--" if not entered)
└── Icon: chevron.forward (16pt, #9CA3AF) if entered, circle (16pt, #D1D5DB) if empty
```

**All Six Vital Rows:**
1. BP (Blood Pressure)
2. HR (Heart Rate)
3. RR (Respiratory Rate)
4. SpO2 (Oxygen Saturation)
5. Temp (Temperature)
6. GCS (Glasgow Coma Scale)

**Color Coding for Values:**
- Not entered: `--` in Text/Disabled (#D1D5DB)
- Normal: Text/Primary (#111827)
- Warning: Field/Warning (#F59E0B)
- Critical: Field/Emergency (#DC2626)

### 3. Vital Selection Grid

**Frame:** 353 × 500pt
**Position:** 24pt below Current Values Card
**Layout:** 2 columns, 3 rows, 16pt gaps

**Grid Layout (Auto Layout):**
```
Row 1: [Blood Pressure] [Heart Rate]
Row 2: [Resp Rate]      [SpO2]
Row 3: [Temperature]    [GCS]
```

### Vital Selection Button Component

**Dimensions:** 168.5 × 150pt (each button)
**Background:** Field/Info (#3B82F6)
**Corner Radius:** 12pt
**Border:** 2pt, transparent (becomes colored on press)

**Layout (Auto Layout, Vertical, Center/Center, 12pt gap):**

**Icon (Top):**
- Size: 48×48pt
- Color: White
- Weight: Bold
- SF Symbol specific to vital type

**Label (Middle):**
- Style: Field/Body/Large (20pt, Semibold)
- Color: White
- Text: Vital name (e.g., "Blood Pressure")

**Unit (Bottom):**
- Style: Field/Caption (14pt, Medium)
- Color: White with 80% opacity
- Text: Unit (e.g., "mmHg")

**Status Indicator (Top Right Corner, Absolute Position):**
- Circle: 24×24pt
- Background: White
- Border: 2pt, #3B82F6
- Icon: checkmark (12pt, #3B82F6) if value entered, empty if not

### Vital Button Specifications

**1. Blood Pressure Button**
- Icon: `heart.fill`
- Label: "Blood Pressure"
- Unit: "mmHg"
- Color: `#3B82F6` (Blue)

**2. Heart Rate Button**
- Icon: `waveform.path.ecg`
- Label: "Heart Rate"
- Unit: "bpm"
- Color: `#EF4444` (Red-ish, distinct from blue)

**3. Respiratory Rate Button**
- Icon: `lungs.fill`
- Label: "Resp Rate"
- Unit: "/min"
- Color: `#06B6D4` (Cyan)

**4. SpO2 Button**
- Icon: `drop.fill`
- Label: "SpO2"
- Unit: "%"
- Color: `#8B5CF6` (Purple)

**5. Temperature Button**
- Icon: `thermometer`
- Label: "Temperature"
- Unit: "°C"
- Color: `#F59E0B` (Amber)

**6. GCS Button**
- Icon: `brain.head.profile`
- Label: "GCS"
- Unit: "/15"
- Color: `#10B981` (Green)

### Button States

**Default:**
- Background: Vital-specific color
- Border: 2pt transparent
- Shadow: Light elevation (Y: 2pt, Blur: 8pt, 8% black)

**Pressed:**
- Background: Darker shade (-20% brightness)
- Scale: 98%
- Border: 2pt, white with 20% opacity
- Shadow: None

**Completed (has value):**
- Status indicator shows checkmark
- Slight glow effect (optional)

---

## Screen 2: Number Pad Entry (Blood Pressure Example)

### Frame Specifications

**Device:** iPhone 15 Pro (393 × 852pt)
**Frame Name:** `Notes/Vitals-Entry/02-BP-Entry`

### Layout Structure

```
┌─────────────────────────────────────┐
│ Navigation Bar                      │
│   ← Back    Blood Pressure     Done │
├─────────────────────────────────────┤
│                                     │
│ Vital Icon & Name (80pt)            │
│                                     │
├─────────────────────────────────────┤
│                                     │
│ Dual Input Display (140pt)          │
│   [Systolic]  /  [Diastolic]        │
│                                     │
├─────────────────────────────────────┤
│                                     │
│ Visual Range Indicator (60pt)       │
│   [──●────────] Normal               │
│                                     │
├─────────────────────────────────────┤
│                                     │
│ Number Pad (350pt)                  │
│   [1] [2] [3]                       │
│   [4] [5] [6]                       │
│   [7] [8] [9]                       │
│   [<] [0] [→]                       │
│                                     │
├─────────────────────────────────────┤
│                                     │
│ Clear Button (60pt)                 │
│                                     │
└─────────────────────────────────────┘
```

### 1. Navigation Bar

**Left: Back Button**
- Icon: `chevron.left` (20pt)
- Text: "Back"
- Color: Field/Info
- Action: Return to selection grid

**Center: Title**
- Icon + Text: `heart.fill` "Blood Pressure"
- Style: Field/Title/Medium
- Color: Text/Primary

**Right: Done Button**
- Text: "Done"
- Style: Field/Body/Large (Semibold)
- Color: Field/Safe
- State: Disabled (gray) if values incomplete

### 2. Vital Icon & Name Header

**Frame:** 393 × 80pt
**Background:** Vital-specific color (#3B82F6 for BP)
**Layout:** Horizontal, Center/Center, 12pt gap

**Icon:**
- SF Symbol: `heart.fill`
- Size: 40×40pt
- Color: White

**Name:**
- Text: "Blood Pressure"
- Style: Field/Title/Medium (28pt, Bold)
- Color: White

### 3. Dual Input Display (Blood Pressure)

**Frame:** 353 × 140pt
**Background:** Background/Secondary (#F9FAFB)
**Border:** 2pt, Border/Default
**Corner Radius:** 12pt
**Margin:** 20pt horizontal

**Layout (Auto Layout, Horizontal, Center/Center, 20pt gap):**

```
[Systolic Input] [Separator] [Diastolic Input]
    (140pt)         (20pt)       (140pt)
```

**Input Field Component (Systolic/Diastolic):**

**Container:** 140 × 120pt

**Label (Top):**
- Text: "Systolic" or "Diastolic"
- Style: Field/Caption (14pt, Medium)
- Color: Text/Secondary
- Alignment: Center

**Value Display:**
- Text: "120" or "---" if empty
- Style: Field/Vitals/Display (48pt, Bold, SF Pro Rounded)
- Color: Text/Primary or Text/Disabled
- Alignment: Center
- Margin Top: 8pt

**Unit (Bottom):**
- Text: "mmHg"
- Style: Field/Caption
- Color: Text/Secondary
- Alignment: Center
- Margin Top: 4pt

**Active Field Indicator:**
- Border: 3pt, Field/Info (#3B82F6) around active field
- Background: White for active field

**Separator (Middle):**
- Text: "/"
- Style: Field/Vitals/Display (48pt)
- Color: Text/Secondary (#6B7280)

### 4. Visual Range Indicator

**Frame:** 353 × 60pt
**Margin:** 20pt horizontal, 16pt below input display

**Purpose:** Show if current value is normal, warning, or critical

**Layout (Auto Layout, Vertical, 8pt gap):**

**Range Bar:**
- Frame: 313 × 8pt (353 - 40pt for labels)
- Background: Gradient
  - Left (0-70): `#DC2626` (Critical Low)
  - Middle (70-160): `#10B981` (Normal)
  - Right (160-220): `#DC2626` (Critical High)
- Corner Radius: 4pt

**Indicator Dot:**
- Circle: 20×20pt
- Fill: White
- Border: 3pt, matches current zone color
- Shadow: Medium elevation
- Position: Calculated based on current value (animated)

**Status Label:**
- Text: "Normal", "Low", "High", or "Critical"
- Style: Field/Body/Regular (18pt, Semibold)
- Color: Matches zone (Green for normal, Amber for warning, Red for critical)
- Alignment: Center
- Margin Top: 4pt

**Reference Values (Small Text Below):**
- Left: "Low (<90)"
- Center: "Normal (90-140)"
- Right: "High (>180)"
- Style: Field/Caption (14pt)
- Color: Text/Secondary

### 5. Number Pad

**Frame:** 353 × 350pt
**Margin:** 20pt horizontal, 20pt below range indicator
**Layout:** Auto Layout, 4 rows × 3 columns, 12pt gaps

**Number Button Component:**
- Size: 107 × 80pt (calculated: (353 - 24pt gaps) / 3)
- Background: Background/Tertiary (#F3F4F6)
- Border: 2pt, Border/Default (#E5E7EB)
- Corner Radius: 8pt
- Shadow: Light elevation

**Number Label:**
- Text: "1", "2", "3", etc.
- Style: Field/Vitals/Display scaled to 36pt
- Color: Text/Primary (#111827)
- Weight: Bold
- Alignment: Center

**Grid Layout:**
```
Row 1: [1]  [2]  [3]
Row 2: [4]  [5]  [6]
Row 3: [7]  [8]  [9]
Row 4: [←]  [0]  [→]
```

**Special Buttons (Row 4):**

**Left Arrow (←) - Delete Last Digit:**
- Icon: `delete.left.fill`
- Size: 28pt
- Color: Field/Emergency (#DC2626)
- Background: Field/Emergency with 10% opacity

**Zero (0):**
- Same as number buttons

**Right Arrow (→) - Move to Next Field:**
- Icon: `arrow.right`
- Size: 28pt
- Color: Field/Info (#3B82F6)
- Background: Field/Info with 10% opacity
- State: Disabled if diastolic field is empty

**Button States:**

**Default:**
- Background: #F3F4F6
- Border: 2pt, #E5E7EB

**Pressed:**
- Background: #E5E7EB (darker gray)
- Scale: 96%
- Duration: 100ms

**Disabled:**
- Opacity: 40%
- Non-interactive

### 6. Clear Button

**Frame:** 353 × 60pt
**Position:** 20pt from bottom (above safe area)
**Background:** Field/Emergency (#DC2626)
**Corner Radius:** 12pt

**Label:**
- Text: "Clear All"
- Style: Field/Body/Large (20pt, Semibold)
- Color: White
- Alignment: Center

**Pressed State:**
- Background: Darker red (#B91C1C)
- Scale: 98%

---

## Screen 3: Single Value Entry (Heart Rate, SpO2, etc.)

### Frame Specifications

**Device:** iPhone 15 Pro (393 × 852pt)
**Frame Name:** `Notes/Vitals-Entry/03-HR-Entry`

**Difference from BP:** Single input field instead of dual

### Simplified Input Display

**Frame:** 353 × 140pt
**Single centered input field**

**Container:** 280 × 120pt (centered)

**Layout (Auto Layout, Vertical, Center/Center, 8pt gap):**

**Label:**
- Text: "Heart Rate"
- Style: Field/Caption
- Color: Text/Secondary
- Alignment: Center

**Value Display:**
- Text: "75" or "---"
- Style: Field/Vitals/Display (64pt instead of 48pt - larger for single value)
- Color: Text/Primary
- Alignment: Center

**Unit:**
- Text: "bpm"
- Style: Field/Vitals/Unit (18pt)
- Color: Text/Secondary
- Alignment: Center

**Number Pad:**
- Same as BP entry but simpler
- Bottom row: `[←] [0] [✓]`
- Right button (✓) confirms and returns to selection grid

---

## Screen 4: Temperature Entry (with Decimal)

**Frame Name:** `Notes/Vitals-Entry/04-Temp-Entry`

**Special Feature:** Decimal point button

**Number Pad Layout:**
```
Row 1: [1]  [2]  [3]
Row 2: [4]  [5]  [6]
Row 3: [7]  [8]  [9]
Row 4: [.]  [0]  [✓]
```

**Decimal Button (.):**
- Background: Field/Info with 10% opacity
- Color: Field/Info
- Disabled after first decimal entered
- Maximum 1 decimal place for temperature

**Validation:**
- Min: 30.0°C
- Max: 45.0°C
- Warning: <35.0 or >39.0
- Critical: <32.0 or >41.0

---

## Interaction Patterns

### 1. Entering Blood Pressure

**User Flow:**
```
1. Tap BP button on selection grid
2. Screen transitions to BP entry (slide left)
3. Systolic field is active (blue border)
4. User taps numbers: 1 → 2 → 0
5. Display updates in real-time: "1" → "12" → "120"
6. Visual indicator moves on range bar
7. User taps → (right arrow) or "/" separator
8. Diastolic field becomes active
9. User taps: 8 → 0
10. Done button enables (turns green)
11. User taps Done or → to confirm
12. Screen transitions back to selection grid (slide right)
13. BP row in Current Values updates: "120/80 mmHg" (green if normal)
14. BP button shows checkmark
```

### 2. Quick Entry Flow

**Power User Optimization:**
```
Selection Grid → BP (auto-focus systolic) → Type 120 → Auto-advance to diastolic →
Type 80 → Auto-confirm → Back to grid → HR auto-opens → Type 75 → Confirm → etc.
```

**Auto-advance rules:**
- After 3 digits in systolic (e.g., 120), auto-advance to diastolic
- After 3 digits in single-value vital (e.g., HR: 120), auto-confirm
- Prevents need to tap Done/Next for common values

### 3. Visual Feedback

**Real-time indicators:**
- Value updates on each keypress (no lag)
- Range indicator animates smoothly (300ms ease-out)
- Color changes when crossing thresholds (normal → warning)
- Haptic feedback on button presses (light impact)
- Haptic feedback on threshold crossings (warning: light, critical: heavy)

### 4. Error Prevention

**Invalid inputs:**
- Heart Rate >220: Warning overlay "Value seems high. Confirm?"
- SpO2 >100: Blocked, shows "SpO2 cannot exceed 100%"
- Temperature <30 or >45: Warning overlay
- BP Systolic < Diastolic: Warning "Systolic is usually higher"

---

## Animations & Transitions

### Screen Transitions

**Grid → Entry:**
- Type: Push (slide left)
- Duration: 300ms
- Easing: Ease-out
- Vital button scales down to icon in nav bar

**Entry → Grid:**
- Type: Pop (slide right)
- Duration: 300ms
- Easing: Ease-in
- Icon expands back to button

### Number Entry Animation

**Digit appears:**
- Fade in + scale up (from 0.8 to 1.0)
- Duration: 150ms
- Easing: Spring (slight bounce)

**Range Indicator Movement:**
- Position animates to new value
- Duration: 300ms
- Easing: Ease-out
- Color transition if crossing threshold: 200ms

### Button Press

**All buttons:**
- Scale: 100% → 96% → 100%
- Duration: Down 100ms, Up 150ms
- Easing: Ease-out
- Haptic: Light impact on press

---

## Color-Coded Range Definitions

### Blood Pressure (Systolic)
- **Critical Low:** <90 mmHg (Red)
- **Low:** 90-100 mmHg (Amber)
- **Normal:** 100-140 mmHg (Green)
- **High:** 140-180 mmHg (Amber)
- **Critical High:** >180 mmHg (Red)

### Heart Rate
- **Critical Low:** <40 bpm (Red)
- **Low:** 40-50 bpm (Amber)
- **Normal:** 50-100 bpm (Green)
- **High:** 100-120 bpm (Amber)
- **Critical High:** >120 bpm (Red)

### Respiratory Rate
- **Critical Low:** <10 /min (Red)
- **Low:** 10-12 /min (Amber)
- **Normal:** 12-20 /min (Green)
- **High:** 20-30 /min (Amber)
- **Critical High:** >30 /min (Red)

### SpO2
- **Critical:** <88% (Red)
- **Low:** 88-92% (Amber)
- **Normal:** 92-100% (Green)

### Temperature (Celsius)
- **Hypothermia:** <35°C (Red)
- **Low:** 35-36°C (Amber)
- **Normal:** 36-37.5°C (Green)
- **Fever:** 37.5-39°C (Amber)
- **High Fever:** >39°C (Red)

### GCS (Glasgow Coma Scale)
- **Critical:** 3-8 (Red)
- **Moderate:** 9-12 (Amber)
- **Mild:** 13-14 (Amber)
- **Normal:** 15 (Green)

---

## Responsive Behavior (iPad)

### iPad Adaptations

**Grid Layout:**
- 3 columns instead of 2
- Buttons: 250 × 150pt (larger)
- More spacing between elements

**Number Pad:**
- Centered with max-width: 400pt
- Buttons: 120 × 80pt
- Does not fill full width (better for thumb reach on larger screen)

**Current Values Card:**
- Max width: 600pt, centered
- Two-column layout for vital values

---

## Accessibility Features

### Dynamic Type Support

**Text scaling:**
- All text uses text styles (scales with system settings)
- Layout adjusts (vertical scrolling if needed)
- Minimum button size maintained (never shrinks below 60pt)

### VoiceOver Labels

**Selection Grid Buttons:**
- Label: "Blood Pressure, not entered" or "Blood Pressure, 120 over 80, normal"
- Hint: "Double tap to enter or edit blood pressure"

**Number Buttons:**
- Label: "1", "2", "3", etc.
- No hint needed (self-explanatory)

**Status Indicators:**
- Label includes range status: "Blood pressure 120 over 80, normal range"

### Color Independence

**Never rely on color alone:**
- Range indicators use icons (checkmark, warning triangle, exclamation)
- Status text always present ("Normal", "High", "Critical")
- Borders/shapes differentiate states

---

## Figma Prototype Interactions

### Create These Interactions in Prototype Mode

**Selection Grid:**
1. BP Button → On Tap → Navigate to BP Entry Screen (Slide Left)
2. HR Button → On Tap → Navigate to HR Entry Screen (Slide Left)
3. (Repeat for all 6 vitals)

**BP Entry Screen:**
1. Number buttons → On Tap → Show pressed state (100ms) → Reset
2. Back button → On Tap → Navigate to Selection Grid (Slide Right)
3. Done button → On Tap → Navigate to Selection Grid (Slide Right)
4. Right arrow → On Tap → Highlight diastolic field

**Testing the Prototype:**
- Test with finger (simulates touch)
- Test with stylus (simulates glove)
- Time the flow (goal: <90 seconds for all 6 vitals)

---

## Component Library Checklist

Before building screens, ensure these components exist:

### From Design System
- [ ] FieldButton (all variants)
- [ ] FieldVitalCard
- [ ] FieldNumberPad (create if doesn't exist)
- [ ] FieldStatusBadge
- [ ] Navigation Bar (iOS standard or custom)

### New Components for Vitals
- [ ] VitalSelectionButton (6 variants for each vital type)
- [ ] VitalInputDisplay (single and dual variants)
- [ ] VitalRangeIndicator (with animated dot)
- [ ] CurrentValuesRow (reusable vital status row)

---

## Export Specifications for Development

### Assets to Export

**Icons (as SVG):**
- All vital type icons (heart.fill, etc.)
- Navigation icons (back, checkmark, etc.)
- Status icons (checkmark.circle, warning, etc.)

**Colors (as code):**
- Export color styles as hex values
- Include range threshold values

**Spacing (as constants):**
- Touch targets: 60pt, 80pt, 100pt
- Margins: 20pt
- Gaps: 12pt, 16pt, 24pt

---

## Testing Checklist

### Before Handoff to Development

**Visual Testing:**
- [ ] All colors meet contrast requirements (use Stark)
- [ ] All touch targets ≥60pt (use Stark or measure tool)
- [ ] Layouts work at different text sizes
- [ ] iPad layout looks good at larger size

**Interaction Testing:**
- [ ] Prototype flows work smoothly
- [ ] All buttons have visual feedback
- [ ] Back navigation works from all screens
- [ ] Error states are designed

**Glove Testing:**
- [ ] Print key screens at actual size
- [ ] Test tapping accuracy with stylus (simulate glove)
- [ ] Time complete workflow (should be <2 minutes)

**Sunlight Testing:**
- [ ] Print screens on paper
- [ ] Test readability outdoors in full sun
- [ ] Verify color distinctions are visible

---

## Next Steps After Vitals Entry Design

**Priority Order:**
1. ✅ Vitals Entry (this screen)
2. → Multi-Select Symptoms/Risks screen
3. → Dynamic Medication List screen
4. → Note Signing flow
5. → SBAR Handoff view improvements

---

## Resources & References

**Apple Guidelines:**
- HIG: Entering Data
- HIG: Tappable Elements
- Apple Health app vitals interface

**Medical Standards:**
- Normal vital sign ranges (by age)
- Clinical color coding conventions
- Emergency medicine workflows

**Field Testing:**
- Glove compatibility testing protocol
- Sunlight readability testing
- Stress scenario simulations

---

**Last Updated:** January 2026
**Version:** 1.0
**Screen Status:** Ready for Figma implementation
**Next Review:** After user testing with clinicians
