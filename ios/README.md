# ExpenseTracker iOS — Phase 1

SwiftUI app for expense tracking with Supabase backend.

## Features (Phase 1)

- Email/OTP authentication
- Add, edit, delete expenses
- Monthly expense list with totals
- Category-based organization
- Ignored transactions tab

## Building

1. Open `ExpenseTracker.xcodeproj` in Xcode
2. Select your development team in Build Settings
3. Build and run on simulator or device

## Architecture

- **Views/**: SwiftUI screens (Login, Home, Add/Edit, Ignored)
- **Managers/**: AuthManager (OTP flow), ExpenseManager (CRUD)
- **Models/**: Expense data structure
- **ExpenseTrackerApp.swift**: App entry point

## Authentication

Uses Supabase email OTP flow. Session persisted in UserDefaults.

## Data

Expense data synced to Supabase `expenses` table with Row Level Security (users see only their own data).

## Next Steps

- Implement real Supabase sync (currently mock)
- Add push notifications for auto-capture
- Gmail/SMS integration for expense discovery
