# UI Components — Specification

All reusable components used across the Expense Tracker app. These map 1:1 to SwiftUI components in the codebase.

---

## Buttons

### Primary Button
**Usage:** Main action (Save, Confirm, Add)

- **Background:** `primary` (#007AFF)
- **Text:** White, 17pt semibold
- **Padding:** 16pt vertical, 24pt horizontal
- **Border Radius:** 12pt
- **States:**
  - **Normal:** Full opacity, slight shadow
  - **Pressed:** Darken 20%, scale 0.98
  - **Disabled:** Gray (#CCCCCC), no shadow
- **Min Touch Size:** 44pt height

**SwiftUI:**
```swift
.frame(height: 44)
.background(Color.primary)
.cornerRadius(12)
.disabled(isDisabled)
```

### Secondary Button
**Usage:** Alternative action (Cancel, Clear)

- **Background:** Transparent / Light Gray (#F2F2F7)
- **Text:** `primary` (#007AFF), 17pt semibold
- **Padding:** 16pt vertical, 24pt horizontal
- **Border:** 1pt, `primary` color
- **Border Radius:** 12pt
- **States:**
  - **Normal:** Outlined
  - **Pressed:** Background lightens
  - **Disabled:** Gray text + border

### Danger Button
**Usage:** Destructive action (Delete)

- **Background:** `error` (#FF3B30)
- **Text:** White, 17pt semibold
- **Padding:** 16pt vertical, 24pt horizontal
- **Border Radius:** 12pt
- **States:** Same as Primary

---

## Input Fields

### Text Input
**Usage:** Merchant name, notes

- **Background:** `surface` (white)
- **Border:** 1pt, light gray (#E5E5EA)
- **Padding:** 12pt (internal)
- **Border Radius:** 12pt
- **Text Style:** 17pt, regular
- **Placeholder:** Gray (#999999)
- **States:**
  - **Normal:** Light gray border
  - **Focused:** Blue border (2pt), shadow
  - **Error:** Red border
- **Min Height:** 48pt

### Numeric Input (Amount)
**Usage:** Expense amount

- **Same as Text Input**
- **Keyboard:** Number pad (decimal)
- **Prefix:** Currency symbol (₹)
- **Text Alignment:** Right-aligned

### Date Input
**Usage:** Expense date

- **Trigger:** Tap to show calendar picker
- **Display Format:** "May 26, 2026" or "26/05/2026"
- **Default:** Today's date

---

## Category Picker

### Category Pill
**Usage:** Individual category in picker

- **Background:** Light category color (e.g., #FFE5E5 for Food)
- **Icon:** Category icon (24×24pt)
- **Label:** Category name (13pt, centered below icon)
- **Size:** 80×100pt (width × height)
- **Padding:** 8pt around icon
- **Border Radius:** 12pt
- **States:**
  - **Normal:** Light tint
  - **Selected:** Darker tint + checkmark overlay
  - **Pressed:** Slight zoom animation

### Category Grid
**Usage:** Layout for category picker

- **Columns:** 3 per row (phone), 4 per row (tablet)
- **Gap:** 12pt (between items)
- **Padding:** 16pt (around grid)
- **Scrollable:** If more categories added

### Category Mapping
| Category | Icon | Color | Emoji |
|----------|------|-------|-------|
| Food | 🍔 | #FFE5E5 | Red tint |
| Transport | 🚕 | #E5F5FF | Blue tint |
| Shopping | 🛍️ | #FFF5E5 | Orange tint |
| Bills | 📄 | #F5F5F5 | Gray tint |
| Travel | ✈️ | #E5FFE5 | Green tint |
| Entertainment | 🎬 | #F5E5FF | Purple tint |
| Health | 💊 | #FFE5F5 | Pink tint |
| Other | ⭐ | #F5F5F5 | Gray tint |

---

## Expense Card

**Usage:** List item displaying single expense

- **Background:** `surface` (white)
- **Border Radius:** 12pt
- **Padding:** 16pt
- **Shadow:** Light (iOS system)
- **Layout:**
  ```
  [Icon] ₹5,000  Coffee
         May 26   Café
  ```

**Components:**
- **Icon:** Category icon (40×40pt), colored
- **Amount:** 17pt, semibold, left-aligned
- **Description:** 13pt, regular, gray
- **Date:** 13pt, regular, gray, bottom-right

**States:**
- **Normal:** Standard appearance
- **Swiped Left:** Reveal Delete button
- **Tapped:** Slight highlight, opens detail/edit modal

---

## Floating Action Button (FAB)

**Usage:** Primary add action

- **Shape:** Circle
- **Size:** 56×56pt (iOS standard)
- **Background:** `primary` (#007AFF)
- **Icon:** Plus sign (SF Symbols `plus.circle.fill`), white, 24pt
- **Position:** Bottom-right, 24pt from edges
- **Shadow:** Elevated (dark shadow)
- **States:**
  - **Normal:** Full opacity
  - **Pressed:** Darken 20%, scale 0.95
- **Animation:** Bounce on appearance

---

## Notification / Alert

### Toast (Bottom Alert)
**Usage:** Confirmation (Expense saved, Deleted)

- **Position:** Bottom of screen, 24pt safe area
- **Background:** Dark gray (#333333)
- **Text:** White, 15pt, centered
- **Padding:** 12pt vertical, 16pt horizontal
- **Border Radius:** 12pt
- **Auto-dismiss:** 2–3 seconds
- **Animation:** Slide up, fade out

### Full-Screen Modal (Phase 3)
**Usage:** Notification tagging on push

- **Overlay:** Semitransparent black (80% opacity)
- **Card:** Center-bottom, rounded top corners
- **Content:** Merchant, amount, date (read-only) + category picker
- **Buttons:** Confirm, "Not an Expense"
- **Swipe Dismiss:** Optional (swipe down to dismiss)

---

## Placeholders & Empty States

### Skeleton Loading
- Gray (#E5E5EA) rounded rectangles
- Animate shimmer effect (left to right)
- Duration: 1.5 seconds
- Used when loading list from cloud

### Empty State Icon
- Large icon (80×80pt)
- Placeholder icon (📊, 💰, etc.)
- Subtitle text: "No expenses yet. Tap + to add one."

---

## Accessibility

### All Components
- **Touch Targets:** Minimum 44pt × 44pt
- **Text Contrast:** 4.5:1 ratio (WCAG AA)
- **Labels:** VoiceOver-friendly semantic labels
- **Focus Indicators:** Clear focus ring (blue outline)
- **Dynamic Type:** Resize appropriately up to 200%

### Example VoiceOver Labels
- Button: "Save expense button, double tap to activate"
- Expense Item: "₹5000 Coffee expense on May 26, double tap to edit"
- Category: "Food category, selected, double tap to deselect"

---

## Sizing & Spacing

### Padding / Margins (8pt Grid)
- `xs` = 4pt
- `sm` = 8pt (default)
- `md` = 16pt (standard)
- `lg` = 24pt (section)
- `xl` = 32pt (page)

### Touch Targets
- Minimum: 44pt × 44pt
- Preferred: 48pt × 48pt (comfortable tapping)
- FAB: 56pt × 56pt (iOS standard)

### Typography Scale
- Display: 34pt, Bold
- Heading: 17pt, Semibold
- Body: 17pt, Regular
- Caption: 13pt, Regular
- Tiny: 11pt, Regular (timestamps, metadata)

---

## Dark Mode

All colors have dark mode equivalents (Phase 1.5 or later):

| Light | Dark |
|-------|------|
| #FFFFFF (surface) | #1C1C1E |
| #F2F2F7 (background) | #000000 |
| #000000 (text primary) | #FFFFFF |
| #999999 (text secondary) | #666666 |
| #E5E5EA (border) | #333333 |

---

## Design-to-Code Mapping

| Component | SwiftUI | Notes |
|-----------|---------|-------|
| Button (Primary) | `Button` + `.buttonStyle(.primary)` | Custom style |
| Input (Text) | `TextField` + `.modifier(.inputStyle)` | Custom modifier |
| Input (Date) | `DatePicker` | Built-in |
| Category Pill | `VStack` + custom styling | Reusable component |
| Expense Card | Custom `ExpenseRowView` | Extracted to component |
| FAB | `Button` positioned with `.frame()` | Custom positioning |
| Toast | `Notification` + `.transition()` | Custom view |

---

## Component Status

| Component | Phase 1 | Phase 2 | Phase 3 | Status |
|-----------|---------|---------|---------|--------|
| Button (Primary) | ✅ | ✅ | ✅ | Complete |
| Input (Text) | ✅ | ✅ | ✅ | Complete |
| Input (Date) | ✅ | ✅ | ✅ | Complete |
| Category Picker | ✅ | ✅ | ✅ | Complete |
| Expense Card | ✅ | ✅ | ✅ | Complete |
| FAB | ✅ | ✅ | ✅ | Complete |
| Toast | ⚠️ | ✅ | ✅ | Planned |
| Notification Modal | — | — | ⚠️ | Phase 3 |

---

## Notes

- All component specs map to `/ios/ExpenseTracker/Views/Components/`
- When adding new components, update this file + Figma UI Kit
- Review component design before development begins
- QA: Verify on actual device (not just simulator)
