# Design System — Expense Tracker

## Overview

This folder contains all design assets, wireframes, UI specifications, and user flows for the Expense Tracker iOS app. The design evolves as the product matures across phases.

---

## Design Philosophy

**Simplicity First.** The app's core value is reducing friction—this extends to the UI. Every screen should have a single primary action. Cognitive load is the enemy.

**One-Tap Actions.** Core interaction model: notification tap → single categorization choice → done. No multi-step modals.

**Accessible by Default.** Support dynamic type, high contrast mode, and reduce motion preferences.

---

## Folder Structure

### `wireframes/`
Low-fidelity flows for each major screen. Markdown-based, ASCII diagrams OK.

- `login_flow.md` — Authentication screens
- `expense_list.md` — Main list view, sorting, filtering
- `add_expense.md` — Manual entry + category picker
- `notification_tagging.md` — Push notification + quick categorization

### `figma/`
Links to live Figma files (design + prototypes).

- `PROJECT_LINKS.md` — URLs to Figma projects (UI Kit, Wireframes, High-Fi Screens)

### `assets/`
Exported design files, icons, illustrations.

- `icons/` — App icons, tab bar icons, category icons (SVG preferred)
- `illustrations/` — Onboarding, empty states, error states
- `color_palette.md` — Color definitions (semantic + raw)

### `ui_kit/`
Reusable component specs. Used by engineering to build SwiftUI components.

- `components.md` — Button styles, input fields, category pills, expense cards
- `typography.md` — Font families, sizes, weights (mapping to iOS dynamic type)
- `spacing.md` — Padding, margins, gap standards (8pt grid)

### `user_flows/`
Diagrams of key interaction patterns.

- `passive_capture.md` — Email → extract → notify → tag → store
- `manual_entry.md` — Add expense screen flow
- `categorization.md` — Category picker + correction feedback

---

## Current Design Status

### Phase 1 (Manual Entry)
✅ Basic list, add/edit forms designed  
🔄 Figma wireframes in progress  
📋 Color palette defined (light mode; dark mode TBD)

### Phase 2 (Backend)
🚀 No new screens; backend is invisible

### Phase 3 (Auto-Capture + Notification Tagging)
🚀 Notification UI (alert style vs. full-screen modal)
🚀 Quick categorization picker
🚀 On-notification confirmation flow

### Phase 4 (SMS)
🚀 Treated identically to email (no separate UI)

### Phase 5 (Learning + Reporting)
🚀 Monthly report screens
🚀 Category breakdown chart
🚀 Trend analysis

---

## Design Tokens

### Colors

**Semantic (Light Mode)**
- `primary` — Action color (taps, links) — #007AFF (iOS Blue)
- `secondary` — Subtle interactive elements — #5AC8FA (Light Blue)
- `success` — Confirmation, checkmarks — #34C759 (Green)
- `warning` — Caution, alerts — #FF9500 (Orange)
- `error` — Errors, destructive actions — #FF3B30 (Red)
- `background` — Page background — #F2F2F7 (Light Gray)
- `surface` — Cards, modals — #FFFFFF (White)
- `text.primary` — Main text — #000000
- `text.secondary` — Disabled, metadata — #999999

### Typography

- **Display** — SF Pro Display, 34pt, Bold (titles)
- **Heading** — SF Pro Text, 17pt, Semibold (section titles)
- **Body** — SF Pro Text, 17pt, Regular (content)
- **Caption** — SF Pro Text, 13pt, Regular (metadata, timestamps)

**Note:** Use iOS Dynamic Type sizing (`.title`, `.body`, `.caption`) to respect user accessibility settings.

### Spacing (8pt Grid)

- `xs` = 4pt (rare, only for inline spacing)
- `sm` = 8pt (default padding within elements)
- `md` = 16pt (padding between elements)
- `lg` = 24pt (padding between sections)
- `xl` = 32pt (page-level padding)

---

## Key Screens

### Home (Expense List)
- List of expenses (recent first)
- Pull-to-refresh
- FAB (floating action button) to add manually
- Tap to edit/delete
- Filter/sort options (Phase 2+)

### Add/Edit Expense
- Amount input (numeric keyboard)
- Date picker (calendar)
- Category picker (grid or dropdown)
- Notes field (optional)
- Save/Cancel buttons

### Category Picker
- Grid layout (2 or 3 columns)
- Icon + label for each category
- Selected state (checkmark + highlight)
- Tap to confirm

### Notification Tagging (Phase 3)
- Push notification arrives
- User taps → full-screen modal appears
- Shows extracted merchant, amount, date
- Category picker (quick tap)
- "Not an expense" option with reason picker
- Confirm saves to database

---

## Accessibility Checklist

- [ ] All text meets WCAG AA contrast (4.5:1 for body)
- [ ] Touch targets ≥44pt (iOS standard)
- [ ] Support VoiceOver (semantic labels)
- [ ] Support Dynamic Type up to 200%
- [ ] Support High Contrast mode
- [ ] Support Reduce Motion preference
- [ ] Test with Screen Reader enabled

---

## Design Review Process

1. **Wireframes:** Markdown/ASCII sketches for quick feedback
2. **Figma:** Clickable prototypes for interaction testing
3. **Code Review:** Engineering confirms UI matches spec before building
4. **QA:** Visual regression on device

---

## Tools & Resources

- **Wireframing:** Markdown + Figma
- **Prototyping:** Figma
- **Icon Design:** Sketch / Figma
- **Color Reference:** [SF Symbols](https://developer.apple.com/sf-symbols/) (for standard icons)
- **Accessibility Testing:** Xcode Accessibility Inspector + VoiceOver

---

## Next Steps

- [ ] Create Figma project (Phase 1 wireframes)
- [ ] Define icon library (using SF Symbols or custom)
- [ ] Test notification UI prototype on device (Phase 3)
- [ ] Document component library mapping (design → SwiftUI)

