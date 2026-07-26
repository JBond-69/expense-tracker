# Expense Tracker

A personal iOS expense tracker that replaces Splitwise for daily personal spend tracking. Core differentiator: expenses are captured **passively** via email/SMS and tagged with a single tap, instead of manual multi-field entry.

## Features

- **Passive Capture**: Automatically ingest expense notifications from Gmail and SMS
- **1-Tap Tagging**: Receive push notifications and categorize expenses in one tap
- **Smart Learning**: Expense categorization improves over time based on corrections
- **Local-First**: Data stored locally (Phase 1) → Cloud sync with Supabase (Phase 2+)
- **Multi-Account Support**: Connect multiple Gmail accounts for full bank alert coverage

## Tech Stack

- **App**: SwiftUI + SwiftData (iOS native)
- **Backend**: Supabase (Postgres + Edge Functions)
- **Email**: Gmail API (OAuth, read-only)
- **SMS**: iOS Shortcuts automation
- **Classification**: Claude API (via Supabase Edge Functions)
- **Notifications**: Apple Push Notification service (APNs)

## Project Structure

```
expense-tracker/
├── docs/               # Documentation (roadmap, context, working templates)
├── ios/                # iOS app (SwiftUI)
├── backend/            # Supabase backend (Phase 2+)
├── design/             # UI/UX design (wireframes, Figma, components)
└── .github/            # CI/CD workflows
```

## Getting Started

### Phase 1: Manual Entry (Local Storage)
```bash
cd ios
open ExpenseTracker.xcodeproj
# Build & run in Xcode
```

### Phase 2: Backend Setup
See `backend/README.md` for Supabase configuration.

### Phase 3: Gmail Auto-Capture
See `docs/ROADMAP.md` for integration timeline.

## Quick Links

- [Project Knowledge Base](docs/PROJECT_CONTEXT.md)
- [Product Roadmap](docs/ROADMAP.md)
- [Design System](design/README.md)
- [Backend Setup](backend/README.md)

## Requirements

- iOS 15.0+
- Xcode 14+
- For backend: Supabase account + Google Cloud project (for Gmail OAuth)

## Roadmap

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Manual entry + local storage | ✅ Complete |
| 2 | Supabase backend + multi-account support | 🔄 In Progress |
| 3 | Gmail auto-capture + tag via notification | 🚀 Planned |
| 4 | SMS capture (iOS Shortcuts) | 🚀 Planned |
| 5 | Learning loop + reporting | 🚀 Planned |

## Author

**Prannoy** — Product Manager & Solo Builder

## License

MIT License — see LICENSE file for details
