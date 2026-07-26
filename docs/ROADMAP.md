# Product Roadmap

## High-Level Vision

Replace Splitwise for personal daily expense tracking by automating the most friction-heavy step: instead of manually entering expenses, the app captures them passively from email/SMS and the user tags them in **one tap**. This is the core value prop.

---

## Phase Breakdown

### Phase 1: Manual Capture (SwiftUI + SwiftData)
**Goal:** Prove the daily tracking habit works before automating.  
**MVP Features:**
- Add/edit/delete expenses manually
- Category selection (Food, Transport, Shopping, Bills, Travel, Entertainment, Health, Other)
- Date picker
- Amount input (INR)
- Local storage (SwiftData)
- Simple list view

**Timeline:** ✅ Complete  
**Owner:** Prannoy (testing in Xcode)  
**Success Metric:** Use it daily for 2 weeks without friction

---

### Phase 2: Supabase Backend
**Goal:** Move from local-only to cloud sync. Foundation for Phases 3–5.  
**Features:**
- Supabase project setup (Postgres + Auth)
- User authentication (simple email/password or OAuth)
- `expenses` table schema
- `connected_accounts` table (for multi-Gmail support)
- Cloud sync from SwiftUI (SwiftData + sync adapter)
- Supabase Edge Functions scaffold (for Phase 3)

**Timeline:** Not started  
**Owner:** Claude (architecture)  
**Success Metric:** User can log in, add expense locally, see it in Supabase dashboard

---

### Phase 3: Gmail Auto-Capture + Notification Tagging
**Goal:** Core value prop. User receives push notification → taps → categorizes in one action.  
**Features:**
- Gmail OAuth setup (read-only scope)
- Email ingestion webhook / polling (ingest @bank alerts)
- Claude API extraction (parse amount, merchant, date from email)
- Push notification to user
- On-notification categorization (SwiftUI widget or full-screen modal)
- Correction feedback loop (user's tap feeds back into few-shot prompt)
- Multi-Gmail-account support (Phase 2 `connected_accounts` table)

**Timeline:** 6–8 weeks from Phase 2 start  
**Owner:** Claude (architecture + Edge Functions)  
**Success Metric:** 95%+ extraction accuracy; user tags 10+ bank alerts per week with <1 tap per expense

---

### Phase 4: SMS Capture (iOS Shortcuts)
**Goal:** Cover bank SMS alerts (not all banks send email).  
**Features:**
- iOS Shortcuts automation setup guide (user runs once)
- SMS → webhook forwarding (no native SMS API on iOS)
- Same extraction + notification flow as Phase 3
- One-time setup, then automated

**Timeline:** 2 weeks after Phase 3  
**Owner:** Prannoy + Claude (Shortcut design + backend)  
**Success Metric:** SMS alerts auto-captured; user setup takes <5 min

---

### Phase 5: Learning Loop + Reporting
**Goal:** Auto-categorization improves over time; user gains insights.  
**Features:**
- Correction history logging (every manual override)
- Few-shot prompt improvement (feed recent corrections to Claude API)
- Monthly reports (spend by category, trends)
- Category breakdown chart
- Ability to export data (CSV)

**Timeline:** After Phase 4  
**Owner:** Claude (prompt engineering + reporting)  
**Success Metric:** Manual correction rate drops from 30% → 5% over 2 months

---

## MVP = Phases 1–3
- Phase 1: Prove habit (manual entry works)
- Phase 2: Foundation (cloud sync ready)
- Phase 3: Core value (passive capture + 1-tap tag)

After Phase 3, app is **feature-complete for daily use**. Phases 4–5 are refinements.

---

## Tech Decisions

| Decision | Rationale | Status |
|----------|-----------|--------|
| iOS only (not Android, not web) | Solo project; iOS is primary device; can expand later | ✅ Locked |
| SwiftUI + SwiftData | Native, modern, minimal dependencies | ✅ Locked |
| Supabase (not Firebase, not custom backend) | Free tier; built-in Auth + Postgres + Edge Functions | ✅ Locked |
| Gmail API (not bank APIs) | No per-bank integration overhead; covers ~95% of banks | ✅ Locked |
| Claude API for classification | Few-shot learning; improves without retraining | ✅ Locked |
| iOS Shortcuts for SMS | Only viable path for SMS on iOS (no native API) | ✅ Locked |

---

## Open Questions

- [ ] **Gmail OAuth setup:** Who owns Google Cloud project setup? (Prannoy)
- [ ] **Supabase project:** Create account + first project (Prannoy)
- [ ] **APNs certificate:** Required for push notifications (Prannoy + Claude)
- [ ] **Category list:** Hardcoded now; allow user-editable later? (TBD in Phase 5)
- [ ] **Multi-currency:** INR assumed; add picker later? (Phase 5 candidate)

---

## Success Criteria (by Phase)

| Phase | Criteria |
|-------|----------|
| 1 | Daily use for 2+ weeks without friction |
| 2 | Cloud sync works; user sees data in Supabase |
| 3 | 95%+ extraction accuracy; <1 tap per expense |
| 4 | SMS setup <5 min; SMS alerts auto-captured |
| 5 | Correction rate drops from 30% → 5% |

---

## Notes

- This roadmap is **not fixed**. If testing Phase 1 reveals friction, pivot.
- Prannoy is the PM and daily user; feedback drives priorities.
- Claude is the tech lead; owns architecture + handing off to Claude Code for implementation.
