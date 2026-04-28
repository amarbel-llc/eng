# Working Within Spinclass Sessions

## Overview

When Claude operates inside a spinclass worktree session, several constraints
and environmental differences apply. This skill documents what is different so
Claude behaves correctly without trial-and-error.

**Announce at start:** "I'm operating inside a spinclass session --- applying
session constraints."

## Detecting a Spinclass Session

Check for the `SPINCLASS_SESSION` environment variable:

``` bash
echo "$SPINCLASS_SESSION"
# Format: <repo-dirname>/<branch-name>
# Example: bob/feature-xyz
```

If set, you are inside a spinclass session. Apply all constraints below.

## Constraints

### 1. Path Isolation

When `disallow-main-worktree: true` is set in the sweatfile (common default), a
PreToolUse hook **denies** any tool invocation that accesses the main repo root:

- **Affected tools:** Read, Write, Edit, Glob, Grep, Find, Bash
- **Denied when:** A path resolves to inside the main repo but outside the
  session worktree (symlinks are resolved before comparison)
- **Error:**
  `"Path X is in the main worktree. Restrict operations to the session worktree."`

**What to do:** - Use only paths within the worktree - Do not reference the
parent repo's files directly - If you need information from the main repo, ask
the user

### 2. Environment Variables

Spinclass injects these into the session:

  --------------------------------------------------------------------------------
  Variable                       Value                 Purpose
  ------------------------------ --------------------- ---------------------------
  `SPINCLASS_SESSION`            `<repo>/<branch>`     Identifies the active
                                                       session

  `TMPDIR`                       `<worktree>/.tmp`     Isolated temp directory

  `CLAUDE_CODE_TMPDIR`           `<worktree>/.tmp`     Same, for Claude Code
                                                       specifically
  --------------------------------------------------------------------------------

Use `$TMPDIR` for any temporary files --- it keeps artifacts inside the
worktree.

### 3. Git Context

You are in a **git worktree**, not the main repo:

- `.git` is a **file** (pointer), not a directory
- Commits happen on the worktree's branch, isolated from main
- Do not interact with the root git directory (per global CLAUDE.md)
- Use the worktree exclusively for all git operations

### 4. Permission Tiers

Spinclass manages Claude Code permissions through curated tiers:

- **Auto-approval:** Tool invocations matching curated rules are silently
  approved with `"[spinclass] auto-approved: <permission> (<tier> tier)"`
- **Snapshot tracking:** A baseline snapshot is written at session start. New
  permissions added during the session are captured for post-session review
- **Post-session review:** The user runs `spinclass perms review` after the
  session to promote, keep, or discard new permission rules

**What this means:** Don't be surprised by auto-approvals. Don't try to modify
permission files directly --- spinclass manages them.

### 5. Stop Hooks

A sweatfile may configure a `[hooks] stop` command that runs when the session
ends:

- If the hook **fails**, it **blocks session exit**
- Failure output is written to `/tmp/stop-hook-<session-id>`
- A second invocation (after fixing) allows exit

**What to do:** If you encounter a stop hook failure, investigate the output
file and fix the issue rather than retrying blindly.

### 6. Finishing Work

Use the **finishing-a-development-branch** skill when work is complete. Do not:

- Manually run `git merge` to integrate back
- Manually delete the worktree
- Manually clean up the branch

Spinclass handles the full lifecycle (merge, rebase, cleanup) through its CLI
and the finishing skill's structured options.

## Quick Reference

  Normal Repo                 Spinclass Session
  --------------------------- ------------------------------------------
  Full repo access            Worktree-only access (path isolation)
  System `$TMPDIR`            Worktree-local `.tmp`
  `.git/` is a directory      `.git` is a file (worktree pointer)
  Manual permission prompts   Tiered auto-approval + snapshot tracking
  Free exit                   Stop hooks may block exit
  Manual merge/cleanup        Use finishing-a-development-branch skill

## Red Flags

**Never:** - Access main repo paths when path isolation is active - Modify
`.claude/settings.local.json` or permission files directly - Bypass stop hook
failures - Run raw `git worktree remove` or `git branch -D` --- use the
finishing skill

**Always:** - Check `SPINCLASS_SESSION` to confirm you're in a session - Use
worktree-relative paths for all file operations - Use `$TMPDIR` for temporary
files - Finish work through the finishing-a-development-branch skill

## Integration

**Pairs with:** - **finishing-a-development-branch** --- structured completion
of session work - **subagent-driven-development** --- tasks execute inside
spinclass sessions - **executing-plans** --- plan batches execute inside
spinclass sessions
