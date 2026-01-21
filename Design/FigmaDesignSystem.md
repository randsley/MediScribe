# MediScribe Figma Design System

## Complete Setup Guide

This document provides step-by-step instructions for creating MediScribe's design system in Figma, optimized for field medical environments.

---

## 1. Figma File Structure

### Project Organization

```
MediScribe Design/
├── 📐 1. Design System
│   ├── Page: Colors
│   ├── Page: Typography
│   ├── Page: Spacing & Layout
│   ├── Page: Components
│   └── Page: Icons
│
├── 📱 2. Screens - Notes
│   ├── Frame: Notes List
│   ├── Frame: New Note
│   ├── Frame: Vitals Entry ⭐
│   ├── Frame: Assessment
│   ├── Frame: Plan
│   └── Frame: Sign Note
│
├── 📱 3. Screens - Imaging
├── 📱 4. Screens - Labs
├── 📱 5. Screens - Settings
│
└── 🔄 6. Prototypes
    ├── Emergency Note Flow
    ├── Routine Note Flow
    └── Handoff Flow
```

---

## 2. Design System - Colors

### Primary Field Palette

Create a color style for each with Auto Layout frames:

#### Semantic Colors (Clinical Context)

**Emergency / Critical**
- Name: `Field/Emergency`
- Value: `#DC2626` (Red 600)
- Use: Critical vitals, urgent actions, triage red
- Contrast: White text (21:1 ratio)

**Warning / Caution**
- Name: `Field/Warning`
- Value: `#F59E0B` (Amber 500)
- Use: Abnormal vitals, edit mode, triage yellow
- Contrast: Black text (8.5:1 ratio)

**Safe / Success**
- Name: `Field/Safe`
- Value: `#10B981` (Green 500)
- Use: Normal vitals, save actions, triage green
- Contrast: White text (4.5:1 ratio)

**Information**
- Name: `Field/Info`
- Value: `#3B82F6` (Blue 500)
- Use: Details, view mode, informational
- Contrast: White text (8:1 ratio)

**Locked / Signed**
- Name: `Field/Locked`
- Value: `#8B5CF6` (Violet 500)
- Use: Signed notes, addenda
- Contrast: White text (7:1 ratio)

#### Neutral Colors

**Backgrounds**
- `Background/Primary`: `#FFFFFF` (White)
- `Background/Secondary`: `#F9FAFB` (Gray 50)
- `Background/Tertiary`: `#F3F4F6` (Gray 100)

**Text**
- `Text/Primary`: `#111827` (Gray 900)
- `Text/Secondary`: `#6B7280` (Gray 500)
- `Text/Disabled`: `#D1D5DB` (Gray 300)

**Borders**
- `Border/Default`: `#E5E7EB` (Gray 200)
- `Border/Focus`: `#3B82F6` (Blue 500)

#### Triage Colors (START System)

- `Triage/Red`: `#DC2626` (Immediate)
- `Triage/Yellow`: `#F59E0B` (Delayed)
- `Triage/Green`: `#10B981` (Minor)
- `Triage/Black`: `#1F2937` (Deceased/Expectant)

### How to Create in Figma

1. **Create Color Styles:**
   - Select a rectangle
   - Fill with color value
   - Right sidebar → Styles → "+" → Create Color Style
   - Name using slash notation (e.g., `Field/Emergency`)

2. **Create Color Documentation Frame:**
   - Create frame (1200×1600px)
   - For each color:
     - Rectangle (200×200px) with color
     - Label with name and hex value
     - Sample text showing contrast
     - Usage description

---

## 3. Design System - Typography

### Type Scale (Field-Optimized)

All sizes are **larger than standard iOS** for glove-friendly, outdoor readability.

#### Font Family
- **Primary:** SF Pro (Apple System Font)
- **Monospace:** SF Mono (for vitals, codes, IDs)

#### Type Styles

**Field/Title/Large**
- Font: SF Pro Display Bold
- Size: 34pt
- Line Height: 41pt
- Use: Screen titles, section headers

**Field/Title/Medium**
- Font: SF Pro Bold
- Size: 28pt
- Line Height: 34pt
- Use: Card titles, sub-sections

**Field/Body/Large**
- Font: SF Pro Semibold
- Size: 20pt
- Line Height: 28pt
- Use: Button labels, primary content

**Field/Body/Regular**
- Font: SF Pro Regular
- Size: 18pt
- Line Height: 25pt
- Use: Body text, descriptions

**Field/Body/Small**
- Font: SF Pro Medium
- Size: 16pt
- Line Height: 22pt
- Use: Secondary information

**Field/Caption**
- Font: SF Pro Medium
- Size: 14pt
- Line Height: 20pt
- Use: Labels, hints, timestamps

**Field/Vitals/Display**
- Font: SF Pro Rounded Bold
- Size: 48pt
- Line Height: 52pt
- Use: Vital signs display, large numbers

**Field/Vitals/Unit**
- Font: SF Pro Medium
- Size: 16pt
- Line Height: 20pt
- Use: Units (mmHg, bpm, %, °C)

### How to Create in Figma

1. **Create Text Styles:**
   - Create text layer
   - Set font, size, weight, line height
   - Right sidebar → Text Styles → "+" → Create Text Style
   - Name: `Field/Title/Large`

2. **Create Typography Documentation Frame:**
   - Show each style with sample text
   - Include size, weight, line height
   - Show in different colors (dark on light, light on dark)

---

## 4. Design System - Spacing & Layout

### Grid System

**Base Unit:** 8pt

**iPhone Grid:**
- Columns: 6
- Gutter: 16pt
- Margin: 20pt (left/right)

**iPad Grid:**
- Columns: 12
- Gutter: 20pt
- Margin: 40pt (left/right)

### Spacing Scale

Create spacing documentation with these values:

**Touch Targets**
- `Spacing/Touch/Minimum`: **60pt** (absolute minimum)
- `Spacing/Touch/Comfortable`: **80pt** (recommended)
- `Spacing/Touch/Large`: **100pt** (critical actions)

**Component Spacing**
- `Spacing/Compact`: 8pt (tight grouping)
- `Spacing/Standard`: 16pt (default)
- `Spacing/Relaxed`: 24pt (section spacing)
- `Spacing/Loose`: 32pt (major sections)

**Screen Padding**
- `Spacing/Screen/Horizontal`: 20pt
- `Spacing/Screen/Vertical`: 24pt

**Safe Areas**
- Top: 59pt (with status bar)
- Bottom: 34pt (home indicator on modern iPhones)
- Tab Bar: 83pt (standard iOS tab bar)

### Corner Radius

- `Radius/Small`: 8pt (input fields, small cards)
- `Radius/Medium`: 12pt (buttons, cards)
- `Radius/Large`: 16pt (modals, sheets)
- `Radius/XLarge`: 24pt (hero cards)

### Shadows (Use Sparingly - Field Visibility)

**Light Elevation**
- Y: 2pt, Blur: 8pt, Color: #00000014 (8% black)

**Medium Elevation**
- Y: 4pt, Blur: 16pt, Color: #0000001F (12% black)

---

## 5. Design System - Components

### Component Library Structure

Create these as Figma components with variants:

#### 1. FieldButton (Primary Component)

**Variants:**
- **Size:** Large (80pt), ExtraLarge (100pt)
- **Type:** Primary, Secondary, Destructive
- **State:** Default, Pressed, Disabled

**Large/Primary/Default:**
```
Frame: 327 × 80pt (full width minus margins)
Fill: Field/Safe (#10B981)
Corner Radius: 12pt
Padding: 24pt horizontal, 24pt vertical

Content (Auto Layout, Horizontal, 12pt gap):
├── Icon (SF Symbol, 24pt, Bold, White)
└── Label (Field/Body/Large, White)
```

**Large/Primary/Pressed:**
- Fill: Darker green (#059669)
- Scale: 98%

**Large/Primary/Disabled:**
- Fill: #D1D5DB (Gray 300)
- Label: #9CA3AF (Gray 400)

**Create Other Variants:**
- Secondary: Border instead of fill
- Destructive: Red background (#DC2626)
- ExtraLarge: 100pt height

#### 2. FieldNumberPad

**Structure:**
```
Frame: 327 × 480pt
Auto Layout: Vertical, 12pt gap

Components:
├── Display (Frame: 327 × 80pt, Background/Secondary, Center-aligned)
│   └── Number (Field/Vitals/Display, #111827)
│
├── Number Grid (Auto Layout, 3 columns, 12pt gap)
│   ├── Button 1-9 (97 × 60pt each)
│   ├── Button . (decimal, if needed)
│   ├── Button 0
│   └── Button ⌫ (delete, red tint)
│
└── Clear Button (327 × 60pt, Field/Emergency)
```

**Number Button Component:**
- Frame: 97 × 60pt
- Fill: Field/Info with 10% opacity (#3B82F614)
- Corner Radius: 8pt
- Label: Field/Vitals/Display at 32pt
- Border: 2pt, #E5E7EB

#### 3. FieldMultiSelectChip

**Variants:**
- **State:** Unselected, Selected
- **Size:** Regular (auto-width × 60pt)

**Regular/Unselected:**
```
Frame: Auto-width × 60pt
Fill: Background/Tertiary (#F3F4F6)
Border: 2pt, Border/Default (#E5E7EB)
Corner Radius: 8pt
Padding: 16pt horizontal

Content (Auto Layout, Horizontal, 8pt gap):
├── Icon (circle, 20pt, Gray 400)
└── Label (Field/Body/Large, Text/Primary)
```

**Regular/Selected:**
- Fill: Field/Safe with 10% opacity (#10B98114)
- Border: 2pt, Field/Safe (#10B981)
- Icon: checkmark.circle.fill, Field/Safe
- Label: Field/Safe color

#### 4. FieldVitalCard

**Component for displaying single vital:**
```
Frame: 327 × 120pt
Fill: Background/Primary (#FFFFFF)
Border: 2pt, Border/Default (#E5E7EB)
Corner Radius: 12pt
Padding: 20pt

Layout (Auto Layout, Vertical, 12pt gap):
├── Header (Horizontal, space-between)
│   ├── Icon + Label (e.g., "❤️ Heart Rate")
│   └── Status Indicator (circle, 12pt, color-coded)
│
├── Value Display (Horizontal, baseline-aligned)
│   ├── Value (Field/Vitals/Display, "75")
│   └── Unit (Field/Vitals/Unit, "bpm")
│
└── Reference Range (Field/Caption, Secondary, "Normal: 60-100 bpm")
```

**Variants:**
- **Status:** Normal (green), Warning (amber), Critical (red), Unknown (gray)
- **Vital Type:** HR, BP, RR, SpO2, Temp, GCS

#### 5. FieldDynamicListItem

**For medications, actions, symptoms:**
```
Frame: 327 × 60pt
Fill: Field/Info with 5% opacity
Border: 1pt, Border/Default
Corner Radius: 8pt
Padding: 16pt horizontal

Content (Auto Layout, Horizontal, space-between):
├── Label (Field/Body/Regular, Text/Primary)
└── Delete Button (xmark.circle.fill, 24pt, Field/Emergency)
```

#### 6. FieldSection Header

**For grouping related fields:**
```
Frame: 327 × 40pt
Auto Layout, Horizontal, space-between

Components:
├── Title (Field/Title/Medium, Text/Primary)
└── Optional Badge (count, status, etc.)
```

#### 7. FieldStatusBadge

**Variants:**
- **Type:** Draft, Signed, Locked, Reviewed
- **Size:** Small, Medium

**Medium/Signed:**
```
Frame: Auto-width × 32pt
Fill: Field/Locked with 10% opacity
Border: 1pt, Field/Locked
Corner Radius: 16pt (pill shape)
Padding: 12pt horizontal, 6pt vertical

Content (Horizontal, 6pt gap):
├── Icon (lock.fill, 14pt, Field/Locked)
└── Label (Field/Caption, Field/Locked, "Signed")
```

---

## 6. Design System - Icons

### Icon System

**Primary:** SF Symbols (built into iOS)

**Size Scale:**
- Small: 16pt
- Regular: 20pt
- Medium: 24pt
- Large: 28pt
- XLarge: 32pt

**Weight:** Use Bold or Semibold for field visibility

### Key Icons by Category

**Navigation:**
- `doc.text.fill` - Notes
- `camera.fill` - Imaging
- `cross.vial.fill` - Labs
- `arrow.up.doc.fill` - Referrals
- `gear` - Settings

**Vitals:**
- `heart.fill` - Heart Rate
- `waveform.path.ecg` - Blood Pressure
- `lungs.fill` - Respiratory Rate
- `drop.fill` - SpO2
- `thermometer` - Temperature
- `brain.head.profile` - GCS

**Actions:**
- `plus.circle.fill` - Add/Create
- `checkmark.circle.fill` - Confirm/Select
- `xmark.circle.fill` - Delete/Cancel
- `square.and.pencil` - Edit
- `signature` - Sign
- `doc.append` - Addendum
- `square.and.arrow.up` - Share
- `doc.on.doc` - Copy

**Status:**
- `lock.fill` - Locked/Signed
- `lock.open.fill` - Unlocked/Draft
- `exclamationmark.triangle.fill` - Warning
- `info.circle.fill` - Information
- `checkmark.seal.fill` - Reviewed

### How to Use SF Symbols in Figma

1. **Install SF Symbols App** (Mac only, free from Apple)
2. **Export as SVG:**
   - Open SF Symbols app
   - Select icon
   - File → Export Symbol → SVG
3. **Import to Figma:**
   - Drag SVG into Figma
   - Create component
   - Name: `Icon/[name]`
4. **Create Icon Component:**
   - Make variants for different sizes
   - Set color to match style guide

**Alternative:** Use Iconify plugin in Figma (search "sf symbols")

---

## 7. Auto Layout Best Practices

### Component Auto Layout Rules

**All components should use Auto Layout for:**
- Responsive sizing (adapts to content)
- Consistent spacing
- Easy variant creation
- Clean handoff to SwiftUI

**Standard Layout Properties:**

**Buttons:**
- Direction: Horizontal
- Padding: 24pt horizontal, 20-24pt vertical
- Spacing between items: 12pt
- Alignment: Center/Center
- Resizing: Hug contents (horizontal), Fixed (vertical for touch target)

**Cards:**
- Direction: Vertical
- Padding: 20pt all sides
- Spacing between items: 12-16pt
- Alignment: Top/Left
- Resizing: Fill container (horizontal), Hug contents (vertical)

**Lists:**
- Direction: Vertical
- Spacing between items: 12pt
- Alignment: Top/Left
- Resizing: Fill container

---

## 8. Responsive Breakpoints

### Device Frames to Create

**iPhone (Primary Target):**
- iPhone 15 Pro: 393 × 852pt
- iPhone 15 Pro Max: 430 × 932pt
- iPhone SE (3rd gen): 375 × 667pt (minimum support)

**iPad (Secondary):**
- iPad Pro 11": 834 × 1194pt
- iPad Pro 12.9": 1024 × 1366pt

### Layout Adaptations

**iPhone → iPad:**
- Increase grid columns (6 → 12)
- Wider margins (20pt → 40pt)
- Multi-column layouts where appropriate
- Keep touch targets same size (don't shrink)

---

## 9. Accessibility Annotations

### Add These Annotations to Designs

**Touch Targets:**
- Minimum: 60pt (mark in yellow)
- Recommended: 80pt (mark in green)
- Too small: <60pt (mark in red, must fix)

**Contrast Ratios:**
- Use Stark plugin to check all text
- Minimum: 4.5:1 for body text
- Minimum: 7:1 for small text
- Display actual ratio in annotations

**Color Blindness:**
- Use Stark plugin to simulate
- Never rely on color alone
- Add icons or labels for critical states

**Dynamic Type:**
- Design at default size
- Test at largest accessibility size
- Ensure layouts don't break

---

## 10. Creating Your First Component

### Step-by-Step: Create FieldButton Component

1. **Create Base Frame:**
   - Press F (frame tool)
   - Draw: 327 × 80pt
   - Name: "FieldButton"

2. **Add Background:**
   - Select frame
   - Fill: Apply `Field/Safe` color style
   - Corner Radius: 12pt

3. **Add Content with Auto Layout:**
   - Press Shift+A (auto layout)
   - Direction: Horizontal
   - Spacing: 12pt
   - Padding: 24pt horizontal, 24pt vertical
   - Alignment: Center/Center

4. **Add Icon:**
   - Insert SF Symbol or rectangle placeholder
   - Size: 24×24pt
   - Color: White
   - Weight: Bold

5. **Add Label:**
   - Press T (text tool)
   - Type: "Record Vitals"
   - Apply: `Field/Body/Large` text style
   - Color: White

6. **Create Component:**
   - Select entire frame
   - Right-click → Create Component
   - Or: Ctrl+Alt+K (Mac) / Ctrl+Alt+K (Windows)

7. **Add Variants:**
   - Select component
   - Right panel → Click "+" next to variants
   - Add properties:
     - Size: Large, ExtraLarge
     - Type: Primary, Secondary, Destructive
     - State: Default, Pressed, Disabled

8. **Configure Each Variant:**
   - Large/Secondary/Default: Remove fill, add 2pt border
   - Large/Destructive/Default: Change fill to `Field/Emergency`
   - All Disabled: Gray background, gray text

9. **Add to Design System Page:**
   - Copy instance to Design System page
   - Add documentation frame showing all variants
   - Add usage guidelines

---

## 11. Design System Checklist

Before moving to screen design, ensure you have:

### Colors
- [ ] All semantic colors defined
- [ ] Color styles created in Figma
- [ ] Contrast ratios checked (Stark plugin)
- [ ] Color documentation frame complete

### Typography
- [ ] All text styles defined
- [ ] Text styles created in Figma
- [ ] Type scale documentation complete
- [ ] Tested at accessibility sizes

### Spacing
- [ ] Grid system configured
- [ ] Spacing scale documented
- [ ] Touch target sizes defined
- [ ] Safe area margins noted

### Components
- [ ] FieldButton (all variants)
- [ ] FieldNumberPad
- [ ] FieldMultiSelectChip
- [ ] FieldVitalCard
- [ ] FieldDynamicListItem
- [ ] FieldSectionHeader
- [ ] FieldStatusBadge

### Icons
- [ ] Key SF Symbols identified
- [ ] Icon components created (or plugin installed)
- [ ] Icon usage guide documented

### Documentation
- [ ] Cover page with project overview
- [ ] "How to Use" page for developers
- [ ] Component usage examples
- [ ] Do's and Don'ts

---

## 12. Figma Plugins to Install

**Essential (Install First):**
1. **Stark** - Accessibility checking
2. **Iconify** - SF Symbols access
3. **Contrast** - Color contrast verification

**Helpful:**
4. **Auto Layout** - Quick auto layout creation
5. **Content Reel** - Generate realistic medical content
6. **Rename It** - Batch rename layers

**Advanced:**
7. **Figma to SwiftUI** - Code export (for later)
8. **Design System Organizer** - Manage large systems

---

## Next Steps

Once design system is complete:
1. ✅ Review with team for approval
2. ✅ Test color contrast with Stark
3. ✅ Create component documentation
4. → **Move to Field-Optimized Vitals Entry screen design**

---

## Resources

**Figma Learning:**
- Figma YouTube: "Design Systems in Figma"
- Figma Learn: "Creating Components"
- Apple HIG: Human Interface Guidelines

**Design Inspiration:**
- Apple Health app (vitals design)
- Epic Haiku (medical UI)
- Material Design accessibility guidelines

**Accessibility:**
- Apple Accessibility Guidelines
- WCAG 2.1 Level AA standards
- WebAIM Contrast Checker

---

## Support & Questions

Common issues and solutions documented in the project Wiki.

**Last Updated:** January 2026
**Version:** 1.0
**Maintained by:** MediScribe Design Team
