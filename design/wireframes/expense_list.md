# Expense List Screen — Wireframe

## Purpose
Display all user expenses in a scrollable list. Primary interaction surface for viewing history and manually adding new expenses.

## Layout

```
┌─────────────────────────────┐
│       Expenses              │  ← Header
├─────────────────────────────┤
│  Filter  Sort  Options      │  ← Action bar
├─────────────────────────────┤
│                             │
│  ₹5,000  Coffee             │  ← Expense item
│  May 26  Café                │     Tap to edit/delete
│                             │
│  ₹1,200  Uber               │
│  May 26  Transport           │
│                             │
│  ₹150    Lunch              │
│  May 25  Food                │
│                             │
│  ₹25,000 Rent               │
│  May 1   Bills               │
│                             │
├─────────────────────────────┤
│          [ + ]              │  ← FAB (Floating Action Button)
│      Add Expense            │
└─────────────────────────────┘
```

## Components

### Header
- **Title:** "Expenses"
- **Optional:** Period selector (This Month / Last 30 Days / All)

### Action Bar
- **Filter icon** — Filter by category
- **Sort icon** — Sort by date, amount, category
- **Menu icon** — More options (export, settings)

### Expense Item
- **Amount** — Large, bold, left-aligned (₹ symbol + number)
- **Category icon** — Colored icon (Food, Transport, etc.)
- **Description** — Merchant/category name (gray, secondary)
- **Date** — Small text (May 26)
- **Background:** Light gray, rounded corners
- **Tap:** Edit / Delete options via swipe or long-press

### FAB (Floating Action Button)
- **Color:** Primary blue (#007AFF)
- **Icon:** Plus sign
- **Position:** Bottom-right corner
- **Tap:** Open Add Expense screen

## Interactions

1. **Pull to refresh:** Refreshes list from cloud (Phase 2+)
2. **Swipe left on item:** Reveal Delete button
3. **Tap on item:** Open Edit Expense modal
4. **Tap FAB:** Open Add Expense screen
5. **Tap Filter:** Show category filter picker
6. **Tap Sort:** Show sort options (date asc/desc, amount asc/desc)

## States

### Empty State
```
┌─────────────────────────────┐
│                             │
│          📊                 │
│   No expenses yet           │
│   Tap + to add one          │
│                             │
│          [ + ]              │
│      Add Expense            │
│                             │
└─────────────────────────────┘
```

### Loading State
- List shows skeleton cards (gray placeholders)
- Shimmer animation while loading

### Error State
- Retry button if cloud sync fails
- Error message: "Failed to load expenses. Tap to retry."

## Typography

- **Header:** 34pt, Bold (SF Pro Display)
- **Amount:** 20pt, Semibold (SF Pro Text)
- **Description:** 15pt, Regular (SF Pro Text)
- **Date:** 13pt, Regular, gray (SF Pro Text)

## Spacing

- **Top padding:** 16pt from safe area
- **Item margin:** 8pt horizontal, 12pt vertical
- **FAB position:** 24pt from bottom, 24pt from right

## Accessibility

- **Touch target:** Items ≥60pt tall (comfortable tap)
- **Text contrast:** 4.5:1 ratio (WCAG AA)
- **VoiceOver:** "₹5000 Coffee expense on May 26, tap to edit"
- **Dynamic Type:** Supports up to 200%

## Notes

- *Phase 1:* Basic list with manual add/delete
- *Phase 2:* Add cloud sync indicator (small refresh icon)
- *Phase 3:* Add "Recently auto-captured" badge
- *Phase 5:* Add summary row (total spend this month)
