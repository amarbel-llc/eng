---
arguments:
- description: Issue number or URL
  name: issue
  required: true
description: Fix a GitHub issue with test-first workflow
user-invocable: true
---

# Fix GitHub Issue

Fix the specified GitHub issue using a test-first approach.

## Steps

1.  **Read the issue** using `get-hubbed resource-read` with
    `get-hubbed://issues?number=<N>`
2.  **Identify the repo** --- if the issue is in a different repo than cwd, say
    so and stop
3.  **Find the reproduction case** --- read relevant source files to understand
    the bug. If the issue lacks a clear reproduction case, ask the user before
    proceeding
4.  **Write a failing test** that reproduces the bug. Run it to confirm it
    fails. Use `just test-*` recipes, never raw `go test`/`bats`/`cargo test`
5.  **Implement the fix** --- smallest change that addresses the stated problem
6.  **Rebuild and run tests:**
    - Use `just build` or the repo's build recipe before testing
    - Run the failing test first to confirm it passes
    - Run the full suite with `just test` to confirm no regressions
7.  **Commit** with message: `fix: <summary> (closes #<number>)`
8.  **Comment on the issue** using `get-hubbed issue-comment` saying the fix is
    in commit `<sha>`. Do not close the issue --- the reporter is responsible
    for verifying and closing

## Constraints

- One commit per issue. Do not batch fixes
- Do not expand scope beyond what the issue describes. New discoveries go to
  `get-hubbed issue-create`, not into this fix
- If the fix belongs in a different repo than the issue, say so and stop --- do
  not implement cross-repo fixes without confirmation
- Never bypass just recipes for build or test commands
