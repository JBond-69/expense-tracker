# Design Mockups — Expense Tracker Phase 1

Interactive prototypes and design files for Phase 1 (Auth + Expense CRUD).

## Files

### `Expense Tracker.dc.html`
**Main interactive mockup** — Open in browser  
Shows all Phase 1 screens:
- Login / OTP flow
- Home (Expense list)
- Add / Edit expense modal
- Ignored transactions tab

Use this to verify visual fidelity during development. Reference for:
- Layout & spacing
- Colors & typography
- Button placement
- Form field styles
- Empty states

### `ios-frame.jsx`
Support file for the HTML mockup — defines iOS frame styling

### `support.js`
Support file for the HTML mockup — provides utility functions

---

## How to Use

1. **Open mockup:** Double-click `Expense Tracker.dc.html` to view in browser
2. **Reference design:** Compare built SwiftUI screens to mockup
3. **Check interactions:** Click through to verify tap targets, animations, flows
4. **Inspect styles:** Use browser DevTools to check colors, fonts, spacing

---

## Phase 1 Requirements

Per `docs/PHASE_1_BRIEF.md`, build these four screens:

1. **Login / OTP**
   - Email input
   - OTP code entry (or magic link, per mockup)
   - Submit button

2. **Home (Expense List)**
   - Month selector
   - List of expenses grouped by month
   - Monthly total
   - Swipe to delete
   - FAB to add expense

3. **Add / Edit Expense**
   - Amount input
   - Merchant/description
   - Category picker
   - Date picker
   - Notes (optional)
   - Save/Cancel

4. **Ignored Transactions**
   - Simple list of expenses marked "not an expense"
   - Empty state for now
   - Full functionality in Phase 2

---

## Design Tokens

Reference `design/ui_kit/components.md` for:
- Button styles
- Input field specs
- Category pill colors
- Typography scale
- Spacing grid

---

## Notes

- These are **interactive prototypes**, not final Figma designs
- SwiftUI implementation may vary slightly due to platform constraints
- Approved for Phase 1 development
- Any deviations must be documented in `docs/PROJECT_CONTEXT.md` session log

