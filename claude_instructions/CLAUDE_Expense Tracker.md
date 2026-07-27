# CLAUDE.md — Non-negotiable rules for this repo

> Read this in full before starting any task. These rules apply regardless of how the
> task is phrased in a prompt. If a prompt conflicts with this file, this file wins.
> Read `docs/PROJECT_CONTEXT.md` next for product context.

## 1. Visual fidelity is a spec, not a suggestion

Before writing any UI code for a screen:
- Open the relevant file in `design/mockups/` and/or `design/wireframes/` for that screen.
- Extract the exact hex colors, font family/sizes, spacing, and component states
  (empty, loading, error) used in the mockup.
- List these tokens in your working notes before writing SwiftUI code.

A screen is not "done" until:
- A simulator screenshot of the built screen has been taken (via iOS Simulator MCP).
- That screenshot has been compared side-by-side against the mockup for the same screen.
- Any deviation (color, spacing, missing state, missing interaction) is either fixed or
  explicitly logged as a deviation with a reason — never silently dropped.

Generic system defaults (default SwiftUI Form/List styling, default fonts, no color
system) are **not** an acceptable substitute for a mockup that specifies a real design
system. If SwiftUI can't match something exactly, get as close as possible and say so —
don't quietly fall back to defaults.

## 2. Nothing is "done" without live, executed proof

Never report a feature as working based on "the code looks correct." Required evidence
before claiming a feature is complete:

- **Build:** it compiles clean (via Xcode MCP / `xcodebuild`) — show the result, not just
  "should build."
- **Run:** it was launched on the simulator and the actual user flow was tapped through
  (via iOS Simulator MCP), not just visually inspected as static code.
- **Data:** for any feature that reads or writes data, the actual row was verified in the
  live Supabase project (via Supabase MCP) — query the table after the action and show
  the row exists with correct values, not assumed.
- **Auth:** for any authenticated request, explicitly trace and confirm the session token
  is captured after login/OTP verification AND attached as an `Authorization: Bearer`
  header on that specific request. "It has an API key" is not the same as "it has a user
  session." State which one is happening.

If full end-to-end proof isn't possible in a given session (e.g. a manual step is
required), say exactly what was and wasn't verified — don't round up to "done."

## 3. Sequence hard problems, don't let them silently break easy ones

If a subsystem (e.g. real auth, RLS policies) is genuinely hard to get right in one pass,
sequence the work so the rest of the app is testable independently first:

- Build and verify CRUD against a known test user / permissive policy first.
- Add real auth (OTP, session handling, RLS) as its own explicit, separately-verified step.
- Never ship a write-path that *looks* complete (compiles, has a button, has a form) but
  is silently broken because the hard part (auth propagation, RLS, schema types) was
  skipped or assumed. If something is stubbed, say so in the code comment and in the
  session log — don't let it pass as finished.

## 4. Feature completeness is checked against the spec, not memory

Before declaring a phase complete, go through the relevant files in `design/wireframes/`
and the phase brief in `docs/` line by line. For each listed interaction (tap-to-edit,
swipe-to-delete, filter, sort, FAB, empty/loading/error states, etc.), confirm it's either:
- implemented, or
- explicitly deferred with a stated reason (e.g. "out of scope per brief section X").

A phase is not complete if features are silently missing with no note explaining why.

## 5. Session log update is a blocking step, not optional

At the end of every session, `docs/PROJECT_CONTEXT.md` session log **must** be updated
with: what was built, any deviations from the brief and why, and open questions. This is
part of the definition of done, not a nice-to-have. Do not end a session — or claim a
phase is finished — without this update.

## 6. How to report back

When reporting a completed task, include:
1. A short plain-language summary of what was built.
2. Screenshot evidence for any UI work.
3. The definition-of-done checklist from the relevant brief, checked off item by item —
   with a one-line note on how each item was verified (not just "done").
4. Any deviations from the spec, and why.
5. Open questions, if any, before starting the next phase.

If something could not be verified, say so plainly rather than presenting it as complete.

## 7. Tooling assumptions

This project expects the following MCP servers to be available in Claude Code (see
`SETUP.md` for connection steps). Use them for verification, not just code generation:
- Xcode MCP (build, diagnostics)
- iOS Simulator MCP (run, tap, screenshot)
- Supabase MCP (query tables, check RLS/auth config, read logs)
- Gmail MCP (read OTP emails for end-to-end login testing)

If a tool isn't connected yet, say so explicitly rather than skipping the verification
step it would have enabled.

## 8. Build for scale by default, not as an afterthought

Don't write code that only works correctly for one test user with a handful of rows.
Default to these habits on any new or touched code, regardless of current user count:

- **Paginate list queries.** Any fetch of expenses (or any other growing table) must use
  a date range or limit/offset — never fetch a whole unbounded table. This applies even
  while there's only one test user; retrofit it later.
- **Index what you filter on.** Any column used in a `WHERE` clause or an RLS policy
  (`user_id`, date columns) should have a database index. This is cheap to add now,
  expensive to discover missing later.
- **Design for many rows per user, not a handful.** Assume a real user will eventually
  have years of transactions, not 10.
- **Be aware of Supabase connection-pooling limits** for the current plan tier, and flag
  it if a feature's design would exhaust pooled connections at moderate concurrency — but
  don't let this block shipping the current phase.

**Sequencing note:** this section does not mean pausing current bug-fix or feature work
to retrofit scale optimizations right now. It means: from this point forward, default to
the scalable version of a pattern instead of the naive one when writing new code, since
fixing it later is more expensive than doing it right the first time. Getting Phase 1
correctly working still comes first.
