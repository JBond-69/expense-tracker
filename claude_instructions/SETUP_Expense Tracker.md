# One-time environment setup — Claude Code on your Mac

Run these once, in Terminal, from inside the `expense-tracker` repo. Requires Xcode
already installed (you have this).

## 1. Apple's native Xcode MCP (ships with Xcode 26.3+)

In Xcode: **Settings → Intelligence tab** → enable MCP.

Then in Terminal:
```
claude mcp add --transport stdio xcode -- xcrun mcpbridge
```

## 2. iOS Simulator MCP (tap, type, swipe, screenshot the running app)

```
claude mcp add ios-simulator -- npx ios-simulator-mcp
```
Requires an iOS Simulator already installed via Xcode (you have this).

## 3. Supabase MCP (query tables, check RLS/auth, read logs)

Get your Supabase project URL and a service-role or personal access token from your
Supabase dashboard (Project Settings → API), then:
```
claude mcp add supabase -- npx -y @supabase/mcp-server-supabase --access-token=YOUR_TOKEN
```
Exact flags can change — if this errors, check
https://supabase.com/docs for their current Claude Code / MCP setup guide and adjust.

**Note:** this token can read/write your whole project. Keep it out of any file you
commit to GitHub — set it as a local environment variable if possible instead of pasting
it directly into the command history.

## 4. Gmail MCP (read OTP emails for full login-flow testing)

```
claude mcp add gmail --transport http https://gmailmcp.googleapis.com/mcp/v1
```
This will prompt an OAuth login on first use — approve read access to the Gmail account
that receives your OTP codes.

## Verify everything connected

```
claude mcp list
```
You should see all four servers listed as connected. If one shows an error, the message
will usually say what's missing (Node.js, a browser, a missing token, etc.).

## After this is done

Start your next Claude Code session with:
> "Read CLAUDE.md and docs/PROJECT_CONTEXT.md. Fix the auth token bug in AuthManager.swift
> and ExpenseManager.swift, then verify Add/Edit/Delete work end-to-end using the MCP
> tools before reporting back."

That single prompt, combined with CLAUDE.md's rules, should be enough for Claude Code to
fix the bug, prove it fixed, and tell you honestly what it did — instead of you finding
out later that it didn't.
