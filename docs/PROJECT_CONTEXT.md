# Expense Tracker — Project Knowledge Base

> Purpose of this file: so any new chat (Claude.ai or Claude Code) can pick up this project with zero re-explaining. Update it at the end of every session — treat it as the source of truth, not the chat history.

## 1. What this is
A personal iOS expense tracker, built solo, to replace Splitwise for daily personal use (not for splitting bills with others — just tracking own spend). Core differentiator vs. existing apps: expenses are captured passively (email/SMS) and tagged via a single tap on a notification, instead of manual multi-field entry.

## 2. Roles
- **Prannoy = Product Manager.** Owns scope, priorities, daily usage/testing, and product decisions.
- **Claude (this chat) = tech lead / architect.** Owns technical decisions, planning, phase breakdown, and hands off implementation work to Claude Code.
- **Claude Code = builder.** Runs in the actual repo, writes/edits code, commits.

## 3. Hard platform constraints (don't relitigate these)
- **No bank API integration** — ruled out early (integration overhead too high for a personal project).
- **iOS cannot read SMS content** — no permission exists for this, for any app. This is an OS-level wall, not a gap in our build.
- **SMS workaround:** iOS Shortcuts automation ("When I receive a message containing X") → forwards text to a webhook we control. This is the only viable path for SMS capture on iPhone. Planned for Phase 4.
- **Email is fully capturable** via Gmail API (OAuth, read-only scope) — this is the primary automated-capture channel.

## 4. Product decisions made so far
- Platform: **iOS only** (native SwiftUI), not web, not Android.
- Local-first for Phase 1 (SwiftData), moving to Supabase for sync once backend exists.
- Notification-tap-to-tag is the core UX loop: user gets a push → taps → confirms category or marks "not an expense" + reason → this correction feeds back into future auto-categorization (few-shot, not a trained model).
- Currency assumed INR in UI (`.currency(code: "INR")`) — confirm/change if wrong.
- **Multi-Gmail-account sync: confirmed feasible, planned for Phase 2.** Reason: Prannoy has multiple bank accounts, and different banks/accounts send alert emails to different Gmail IDs — this is about bank-alert coverage, not a personal/work split. Gmail OAuth is per-account (standard, no blocker) — each connected Gmail gets its own token pair. Schema needs a `connected_accounts` table (email + encrypted access/refresh tokens), and every ingested expense gets tagged with which account it came from. Since the driver is coverage (not separating contexts), account source can stay invisible metadata rather than a user-facing filter — revisit only if a need to filter by account/bank surfaces later.

## 5. Phase roadmap (MVP = Phases 1–3)

| Phase | Purpose | PM focus | Status |
|---|---|---|---|
| 1. Manual capture (SwiftUI + SwiftData) | Prove daily usage habit before automating | Use it daily, flag friction | ✅ Built — needs Prannoy to run in Xcode & test |
| 2. Backend (Supabase) | Invisible plumbing — cloud storage, needed before Phase 3 can work. Includes `connected_accounts` table for multi-Gmail support (bank alerts land across multiple Gmail IDs) | Confirm app feels unchanged | Not started |
| 3. Gmail auto-capture + tag-via-notification | Core value prop: passive capture, 1-tap tagging | Extraction accuracy + tagging speed | Not started |
| 4. SMS capture (iOS Shortcuts) | Cover bank SMS alerts, thin addition on top of Phase 3 pipeline | One-time Shortcut setup | Not started |
| 5. Learning loop + reporting | Auto-tag accuracy improves over time; monthly/category insights | How much manual correction is still needed | Not started |

## 6. Tech stack
- **App:** SwiftUI, SwiftData (local), iOS native
- **Backend:** Supabase (Postgres + Auth + Edge Functions) — free tier
- **Classification/extraction:** Claude API called from a Supabase Edge Function
- **Push notifications:** APNs
- **Email ingestion:** Gmail API (OAuth, read-only)
- **SMS ingestion:** iOS Shortcuts automation → webhook (no native SMS API)

## 7. Repo structure
```
expense-tracker/
  docs/
    PROJECT_CONTEXT.md          <- this file
    ROADMAP.md                  <- phase timeline
  ios/
    ExpenseTracker/
      ExpenseTrackerApp.swift
      Models/Expense.swift
      Views/ExpenseListView.swift
      Views/AddEditExpenseView.swift
  backend/                      <- Phase 2, not yet created
  design/                       <- UI/UX, wireframes, Figma
```

## 8. Open questions / not yet decided
- Supabase project not yet created (need Prannoy to create account + project)
- Gmail OAuth credentials not yet set up (need Google Cloud project)
- Category list is currently hardcoded (Food, Transport, Shopping, Bills, Travel, Entertainment, Health, Other) — may want user-editable categories later
- No multi-currency handling yet, INR hardcoded

## 9. Session log
*(Append a dated entry each session — a few lines: what was built/decided, what's next.)*

- **2026-07-26 (Session 1):** Defined roadmap, ruled out bank integration and iOS SMS reading, built Phase 1 (SwiftUI + SwiftData CRUD app). Repo + KB structure created. Confirmed multi-Gmail-account sync is feasible (per-account OAuth), driven by multiple bank accounts alerting to different Gmail IDs — added `connected_accounts` table as a Phase 2 requirement, account source to stay invisible metadata (not a UI filter) unless that need surfaces later. Next: Phase 2 (Supabase backend).
- **2026-07-26 (Session 2):** Created GitHub repository structure with full project layout including Design folder. Generated initial docs, README, .gitignore, LICENSE. Ready to push to GitHub.
