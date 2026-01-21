# MediScribe Design Documentation

## Quick Start Guide

This folder contains comprehensive design specifications for MediScribe's field-optimized UI/UX.

---

## 📋 Documentation Structure

### 1. **FigmaDesignSystem.md**
Complete design system specification including:
- Colors (field-optimized, high-contrast)
- Typography (large, readable)
- Spacing (glove-friendly touch targets)
- Components (buttons, cards, inputs)
- Icons (SF Symbols)
- Auto Layout patterns

**Start here first** - Build the design system before creating screens.

### 2. **VitalsEntryScreen.md**
Detailed specification for the field-optimized vitals entry interface:
- Screen layouts (3 screens)
- Component specifications
- Interaction patterns
- Animations and transitions
- Color-coded range indicators
- Accessibility features

**Build this second** - Demonstrates how to use the design system.

### 3. **TODO Items**
- Generate SwiftUI code for Figma components
- Set up design-to-code workflow and handoff process

---

## 🚀 Getting Started (30-Minute Quick Setup)

### Prerequisites
- [ ] Figma account (free tier is fine)
- [ ] Figma Desktop app installed (recommended) or web browser
- [ ] Basic Figma knowledge (create frames, components)

### Step 1: Create Figma File (5 min)

1. **Open Figma**
2. **Create New Design File:**
   - Click "New Design File"
   - Name it: "MediScribe - Design System"
3. **Set Up Pages:**
   - Rename default page to "1. Design System"
   - Add pages: "2. Screens - Notes", "3. Prototypes"

### Step 2: Install Essential Plugins (5 min)

**Required (install via Figma → Plugins → Browse):**
- **Stark** - Accessibility checker (contrast, touch targets)
- **Iconify** - Access to SF Symbols
- **Contrast** - Additional contrast checking

**Recommended:**
- **Figma to SwiftUI** - Code generation (for later)
- **Content Reel** - Generate placeholder content

### Step 3: Import iOS Template (5 min)

1. **Search Figma Community:**
   - Type: "iOS 17 UI Kit"
   - Find official Apple template or community favorite
2. **Duplicate to Your Projects:**
   - Click "Duplicate" button
   - This gives you standard iOS components as starting point
3. **Reference, Don't Copy:**
   - Use as reference for standard iOS patterns
   - We'll modify for field use (larger touch targets, higher contrast)

### Step 4: Build Core Design System (15 min)

**Follow FigmaDesignSystem.md Section 2-6:**

**Colors (3 min):**
- Create 5 semantic colors (Emergency, Warning, Safe, Info, Locked)
- Create color styles in Figma
- Save as "Field/Emergency", "Field/Warning", etc.

**Typography (3 min):**
- Create 4 essential text styles:
  - Field/Title/Large (34pt, Bold)
  - Field/Title/Medium (28pt, Bold)
  - Field/Body/Large (20pt, Semibold)
  - Field/Vitals/Display (48pt, Bold, SF Pro Rounded)

**Spacing (2 min):**
- Document touch target sizes: 60pt min, 80pt recommended
- Set up grid: 6 columns, 16pt gutter, 20pt margins

**First Component - FieldButton (7 min):**
- Create frame: 327 × 80pt
- Add auto layout
- Add icon + label
- Apply color and text styles
- Create component (Ctrl+Alt+K)
- Add variants (Size, Type, State)

---

## 📱 Building Your First Screen (45-60 Minutes)

### Follow VitalsEntryScreen.md

**Screen 1: Vital Selection Grid (20 min)**
1. Create device frame (iPhone 15 Pro: 393 × 852pt)
2. Add navigation bar (use iOS template or build custom)
3. Create Current Values Card
4. Build 2×3 grid of vital selection buttons
5. Apply colors, icons, labels from spec

**Screen 2: Blood Pressure Entry (25 min)**
1. Create new frame (same device size)
2. Build dual input display (systolic/diastolic)
3. Create visual range indicator
4. Build 4×3 number pad
5. Add clear button
6. Apply interactions (number buttons update display)

**Screen 3: Connect with Prototype (15 min)**
1. Switch to Prototype mode (top right)
2. Click BP button → drag to BP entry screen
3. Set interaction: On Tap → Navigate to → Slide Left
4. Click Back button → drag to selection grid → Slide Right
5. Test prototype (▶ button, top right)

---

## 🎨 Design System vs. Screens: What's the Difference?

### Design System (Abstract)
- **Reusable components** (buttons, cards, inputs)
- **Color styles** (named colors used throughout)
- **Text styles** (typography settings)
- **Spacing rules** (margins, padding, grids)
- **Lives on:** "1. Design System" page

**Think:** Your component library / toolkit

### Screens (Concrete)
- **Specific layouts** (Notes List, Vitals Entry, etc.)
- **Uses components** from design system
- **Shows real content** (actual vital signs, patient data)
- **Shows user flow** (how screens connect)
- **Lives on:** "2. Screens - Notes" page

**Think:** Your actual app interface

### Workflow
```
Design System → Build Screens → Create Prototype → Test → Iterate
      ↑                                                      ↓
      └──────────────────────────────────────────────────────┘
```

---

## 🔧 Common Figma Techniques for MediScribe

### Auto Layout (Essential!)

**What it is:** Makes components responsive and flexible

**How to use:**
1. Select frame
2. Press Shift+A (or click + in Auto Layout section)
3. Set direction (Horizontal/Vertical)
4. Set spacing between items (12pt, 16pt, etc.)
5. Set padding (20pt all sides)

**Why it matters:** Components adapt to content, easier to maintain

### Components vs. Instances

**Component (Master):**
- The original, editable version
- Has purple icon
- Lives in Design System page
- Changes here affect all instances

**Instance (Copy):**
- Used in your screens
- Has purple diamond icon
- Linked to master component
- Can override text/colors but not structure

**Create component:** Select frame → Ctrl+Alt+K (Mac) / Ctrl+Alt+K (Win)

### Variants (Component States)

**What it is:** Different versions of same component

**Example - FieldButton:**
- Size: Large | ExtraLarge
- Type: Primary | Secondary | Destructive
- State: Default | Pressed | Disabled

**How to create:**
1. Create component
2. Right panel → Click "+" next to Variants
3. Add properties (Size, Type, State)
4. Create all combinations
5. Style each variant

**Why it matters:** One component, many states = easier to manage

### Prototyping Interactions

**Basic interactions:**
1. Switch to Prototype mode (top right)
2. Click element (e.g., button)
3. Drag blue connector to target screen
4. Set interaction:
   - Trigger: On Tap (or On Click)
   - Action: Navigate to
   - Animation: Slide Left (or other)
   - Duration: 300ms
5. Test with ▶ button

---

## ✅ Quality Checklist

### Before Moving to Development

**Design System:**
- [ ] All colors have contrast ratio ≥4.5:1 (check with Stark)
- [ ] All text styles are named and saved
- [ ] Components are created (not just frames)
- [ ] Components have variants for different states
- [ ] Documentation shows how to use each component

**Vitals Entry Screens:**
- [ ] All touch targets are ≥60pt (check with Stark)
- [ ] Color coding is consistent (red=critical, amber=warning, green=safe)
- [ ] SF Symbols used correctly (same weight throughout)
- [ ] Layouts work at different text sizes (test at 200%)
- [ ] Prototype flows work (tap buttons, navigate between screens)

**Field Testing:**
- [ ] Print key screens at actual size (100% scale)
- [ ] Test tapping accuracy with stylus (simulates glove)
- [ ] Test readability outdoors in bright light
- [ ] Time complete workflow (goal: <2 minutes for all vitals)

---

## 🎯 Success Criteria

### You'll know it's ready when:

**Design System:**
- ✅ You can build a new button in <2 minutes by using FieldButton component
- ✅ Changing a color style updates all screens automatically
- ✅ All developers can inspect and get exact values (colors, spacing, fonts)

**Vitals Entry:**
- ✅ Prototype feels smooth and natural
- ✅ All interactions work (tap buttons, see feedback)
- ✅ A clinician can test the prototype and complete vital entry in <2 minutes
- ✅ Touch targets are large enough to tap with gloved finger

---

## 📊 Project Phases

### Phase 1: Foundation (You are here)
- [x] Design system documentation created
- [x] Vitals entry screen specification created
- [ ] Design system built in Figma
- [ ] Vitals entry screens designed in Figma
- [ ] Prototype created and tested

**Time estimate:** 2-3 hours for design system + screens

### Phase 2: Expansion
- [ ] Multi-select symptoms/risks screen
- [ ] Dynamic medication list screen
- [ ] Note signing flow
- [ ] SBAR handoff view

**Time estimate:** 1-2 hours per screen

### Phase 3: Development Handoff
- [ ] Generate SwiftUI code (TODO item)
- [ ] Create design tokens file
- [ ] Document interaction patterns
- [ ] Set up design-to-code workflow (TODO item)

**Time estimate:** 3-4 hours for full handoff

### Phase 4: Field Testing
- [ ] Test with actual clinicians
- [ ] Test outdoors in sunlight
- [ ] Test with gloves
- [ ] Iterate based on feedback

**Time estimate:** 1 week (including scheduling, testing, iteration)

---

## 🆘 Troubleshooting

### Common Issues

**"My button isn't updating everywhere"**
- **Problem:** You edited an instance, not the master component
- **Solution:** Go to Design System page, find the master component (purple icon), edit there

**"My touch targets are too small"**
- **Problem:** Using standard iOS sizes (44pt)
- **Solution:** Minimum 60pt, recommended 80pt for field use

**"Colors look washed out"**
- **Problem:** Not enough contrast
- **Solution:** Use Stark plugin to check, aim for ≥7:1 ratio

**"Prototype doesn't work"**
- **Problem:** Interactions not set up correctly
- **Solution:** Switch to Prototype mode, check blue connectors exist

**"Auto Layout is confusing"**
- **Problem:** It takes practice!
- **Solution:** Watch Figma's official "Auto Layout" tutorial (YouTube), it's 15 minutes and very clear

---

## 📚 Learning Resources

### Figma Essentials
- **Figma YouTube Channel:** "Design Systems in Figma" (15 min)
- **Figma Learn:** "Creating Components" (Interactive tutorial)
- **Apple HIG:** Human Interface Guidelines (Reference)

### Field-Specific Design
- **Medical UI/UX:** Epic Haiku app (real-world example)
- **Accessibility:** WebAIM Contrast Checker
- **Touch Targets:** Material Design guidelines (references)

### MediScribe Context
- Read: `CLAUDE.md` (safety philosophy)
- Read: `TODO.md` (implementation priorities)
- Read: Field Medical Notes design guide (clinical workflows)

---

## 🤝 Getting Help

### Figma Community
- **Figma Forum:** Ask design questions
- **Figma Friends:** Slack community
- **YouTube:** Tons of tutorials

### MediScribe Specific
- GitHub Issues: Report design system gaps
- Team reviews: Schedule design critique sessions
- Clinical feedback: Test with actual users

---

## 📈 Tracking Progress

### Current Status

**Design System:**
- Documentation: ✅ Complete
- Implementation: ⏳ In Progress
- Testing: ⏸️ Not Started

**Vitals Entry:**
- Specification: ✅ Complete
- Design: ⏳ In Progress
- Prototype: ⏸️ Not Started

**Next Screens:**
- Multi-select: 📝 Planned
- Medication list: 📝 Planned
- Signing flow: 📝 Planned

---

## 🎬 Next Actions

### This Week (Priority 1)
1. [ ] Set up Figma file with pages
2. [ ] Install Stark and Iconify plugins
3. [ ] Create 5 core color styles
4. [ ] Create 4 core text styles
5. [ ] Build FieldButton component with variants

### Next Week (Priority 2)
1. [ ] Build remaining design system components
2. [ ] Create vitals selection grid screen
3. [ ] Create BP entry screen with number pad
4. [ ] Set up prototype interactions
5. [ ] Test prototype flow

### Following Week (Priority 3)
1. [ ] Print screens for glove testing
2. [ ] Test outdoors for sunlight readability
3. [ ] Iterate based on findings
4. [ ] Share with team for feedback
5. [ ] Begin development handoff

---

## 📝 Notes & Tips

### Design Philosophy
- **Field-first:** Design for worst-case (gloves, sun, stress)
- **Speed over beauty:** Fast data entry is priority #1
- **Safety by design:** Visual hierarchy for critical information
- **Fail gracefully:** Clear error states, easy recovery

### Keyboard Shortcuts (Figma)
- **F:** Create frame
- **T:** Add text
- **R:** Draw rectangle
- **Shift+A:** Auto layout
- **Ctrl+Alt+K:** Create component
- **Ctrl+G:** Group layers
- **Space+Drag:** Pan canvas
- **Cmd/Ctrl+/** Search/insert anything

### Version Control
- **Save versions:** File → Save to Version History
- **Name them:** "Design system v1", "Vitals entry complete"
- **Save often:** Before major changes
- **Compare versions:** File → Show Version History

---

**Welcome to MediScribe Design!** 🚑

Start with the design system, build the vitals entry screen, and you'll have a solid foundation for the entire app.

Questions? Check troubleshooting section or consult the detailed specs.

**Let's build something that saves lives.** 💚
