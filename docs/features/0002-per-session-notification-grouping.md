---
status: exploring
date: 2026-03-13
promotion-criteria: notifications from distinct Claude Code sessions appear as separate grouped items in mako; dismissing one session's group does not affect others
---

# Per-Session Notification Grouping

## Problem Statement

Claude Code sends desktop notifications through kitty via OSC 99 escape
sequences. Every notification arrives at mako with identical metadata
(`app-name=kitty`, `summary=Claude Code`) regardless of which Claude Code
session produced it. When running multiple sessions, their notifications merge
into a single undifferentiated group, making it impossible to dismiss one
session's notifications without affecting another's. The notifications also
persist indefinitely since kitty sets no expiry timeout.

## Interface

A Claude Code **Notification hook** reads `session_id` and `cwd` from the hook's
JSON input and sends a replacement notification via `kitten notify` with
session-identifying information in the title and a distinct `app-name`. Mako
criteria hide the original generic notification and group the replacements
per-session.

**Notification chain (current):**

    Claude Code → OSC 99 → kitty → D-Bus (app-name=kitty, summary="Claude Code") → mako

**Notification chain (proposed):**

    Claude Code → OSC 99 → kitty → D-Bus (app-name=kitty, summary="Claude Code") → mako [invisible]
                ↘ Notification hook → kitten notify → D-Bus (app-name=claude-code, summary="Claude Code [<session>]") → mako [visible, grouped]

**Components:**

1. **Hook script** — reads stdin JSON, extracts `session_id`/`cwd`, calls
   `kitten notify` with a per-session title and custom app-name.
2. **Mako config** — hides the default kitty notification, groups and
   auto-expires the hook-sent replacements.

## Limitations

- Notification hooks **cannot suppress the original notification**. The original
  must be hidden via mako's `invisible=1` criteria rather than prevented at the
  source. Both notifications are sent over D-Bus; mako filters the display.
- The hook runs as a side-effect after the original notification is dispatched.
  There may be a brief flash of the original before mako applies criteria.
- `kitten notify` must be available on `$PATH` (shipped with kitty).
- This approach is specific to kitty + mako on Wayland. Other terminal/
  notification daemon combinations would need different strategies.
