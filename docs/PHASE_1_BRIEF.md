# Phase 1 Task Brief — Auth + Expense CRUD (Supabase-backed)

> Hand this file to Claude Code, run from inside the `expense-tracker` repo. Read `docs/PROJECT_CONTEXT.md` and `docs/WORKING_TEMPLATE.md` first for full context.

## Goal
Build a real, testable, multi-device iOS app: login (email/OTP) + expense add/edit/delete/list, wired to a live Supabase backend — matching the approved mockup in `design/mockups/Expense Tracker.dc.html` exactly for these screens:
- Login / OTP
- Home (Expenses view for current + past months)
- Add / Edit expense
- Ignored transactions (list of items marked "not an expense" — UI only for now, no auto-capture yet)

**Explicitly out of scope for this phase** (do not build): Credits/Investments/Savings tabs, recurring groups, insights, export, Gmail sync, SMS sync, push notifications. These are later phases — stub the nav tabs if needed so the design isn't broken, but no functionality behind them.

## Why this phase exists (context for Claude Code, not just a checklist)
Original Phase 1 was local-only, no auth. That decision was superseded — Prannoy wants real login for multi-device access, so auth has to be foundational, not retrofitted. This phase merges what used to be "Phase 1" and "Phase 2 backend" into one.

## Steps

### 1. Supabase project setup
- Prannoy creates a Supabase project (he needs to do this — Claude Code cannot create third-party accounts)
- Claude Code: define schema —
  - `users` (handled by Supabase Auth)
  - `expenses`: id, user_id (FK), amount, merchant, category, date, notes, source (default 'manual'), is_expense (bool), reason_if_not_expense (nullable), created_at
  - Categories: Food, Transport, Shopping, Bills, Travel, Entertainment, Health, Other (matches existing `ExpenseCategory` enum from old Phase 1 code — reuse this list)
- Enable Row Level Security so users only see their own expenses

### 2. Auth flow (SwiftUI)
- Build login/OTP screens matching `design/mockups/Expense Tracker.dc.html` visually
- Use Supabase Auth's email OTP flow (magic-link or OTP-code, whichever matches the mockup's UI more closely — check the mockup)
- Handle session persistence so users stay logged in across app launches

### 3. Expense CRUD (SwiftUI + Supabase)
- Reuse logic/structure from old Phase 1 code (`ios/ExpenseTracker/` in repo — reference only) but replace SwiftData with Supabase client calls
- Home screen: list expenses grouped by month, current month total, matching mockup's card layout
- Add/Edit: form matching mockup, writes to Supabase
- Delete: swipe-to-delete or from edit screen, matching mockup interaction
- Ignored tab: simple list view of expenses where `is_expense = false` (no logic needed yet to create these — that comes in Phase 2 with the notification-tag flow; for now this can just be an empty state or manually-testable list)

### 4. Visual fidelity
- Match `design/mockups/Expense Tracker.dc.html` for layout, spacing, colors, typography as closely as SwiftUI allows
- `ios-frame.jsx` and `support.js` in `design/mockups/` are supporting prototype files, not code to port — use them only if they clarify an interaction detail

## Definition of done
- Prannoy can sign up / log in with OTP on his real iPhone
- Prannoy can add, edit, delete an expense and see it reflected instantly
- Data persists in Supabase (verify: log out, log in again, or reinstall app — data survives)
- Visually matches the approved mockup for the four in-scope screens
- `docs/PROJECT_CONTEXT.md` session log updated with what was built and any deviations from this brief

## After this phase
Report back what was built, any deviations from this brief and why, and any open questions — before starting Phase 2 (Gmail auto-capture).
