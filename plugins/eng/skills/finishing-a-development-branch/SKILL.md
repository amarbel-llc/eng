# Finishing a Development Branch

## Overview

Guide completion of development work by verifying context, presenting clear
options, and handling chosen workflow.

**Core principle:** Verify tests → Verify context → Present options → Execute
choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to
complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

``` bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**

    Tests failing (<N> failures). Must fix before completing:

    [Show failures]

    Cannot proceed with merge/PR until tests pass.

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Verify Context for Future Sessions

**Before proceeding, verify that sufficient context exists for a future session
(human or agent) to understand and continue this work.**

Check each item and report status:

1.  **CLAUDE.md** --- If this work introduced new conventions, build commands,
    or patterns, are they reflected in the relevant CLAUDE.md file(s)?
2.  **FDR/ADR/RFC** --- If the work meets the feature lifecycle criteria
    (cross-cutting feature, architectural decision, interface contract), does an
    appropriate record exist?
3.  **GitHub issues** --- Are related issues updated or closed? Are follow-up
    tasks captured as issues (per mid-task idea capture)?
4.  **Commit messages** --- Do they explain the *why*, not just the *what*?

**Report format:**

    Context check:
    - CLAUDE.md: ✓ no new conventions | ⚠ needs update (describe)
    - FDR/ADR/RFC: ✓ not needed | ✓ exists | ⚠ missing (describe)
    - GitHub issues: ✓ up to date | ⚠ needs attention (describe)
    - Commit messages: ✓ adequate | ⚠ needs improvement (describe)

**If any items need attention:** Fix them before proceeding to Step 3. For
CLAUDE.md and records, make the updates. For commit messages, offer to amend or
squash.

**If all items pass:** Continue to Step 3.

### Step 3: Determine Base Branch

``` bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 4: Present Options

Present exactly these 2 options:

    Implementation complete. What would you like to do?

    1. Merge back to <base-branch> locally
    2. Push and create a Pull Request

    Which option?

**Don't add explanation** - keep options concise.

### Step 5: Execute Choice

#### Option 1: Merge Locally

    grit checkout (repo_path, ref: "<base-branch>")
    grit pull (repo_path)

Merge the feature branch (grit has no merge tool --- use Bash):

``` bash
git merge <feature-branch>
```

Verify tests on merged result, then cleanup:

``` bash
git branch -d <feature-branch>
```

Then: Cleanup worktree (Step 6)

#### Option 2: Push and Create PR

**Two-part PR description: human context + agent detail.**

1.  **Agent drafts** a technical summary of the changes (what changed, why, test
    plan).

2.  **Ask the user** for their PR description --- the human motivation, context,
    or open questions. Use AskUserQuestion with a free-text prompt:

        What would you like to say in the PR description? (I'll append my
        technical summary in a blockquote below yours.)

3.  **Compose the PR body** with the user's text first, then the agent's summary
    in a blockquote with a robot header:

``` markdown
<user's description>

> 🤖 The following was authored by the Claude LLM 🤖
>
> <agent's technical summary — changes, rationale, test plan>
```

4.  **Push and create:**

<!-- -->

    grit push (repo_path, set_upstream: true)

    get-hubbed pr_create (
      repo: "<owner>/<repo>",
      title: "<title>",
      head: "<feature-branch>",
      body: "<composed body>"
    )

The user MUST provide a description --- do not proceed without one. If the
response is empty, ask again.

Then: Cleanup worktree (Step 6)

### Step 6: Cleanup Worktree

Check if in worktree:

``` bash
git worktree list | grep $(git branch --show-current)
```

If yes:

``` bash
git worktree remove <worktree-path>
```

## Quick Reference

  Option              Merge   Push   Cleanup Worktree   Cleanup Branch
  ------------------- ------- ------ ------------------ ----------------
  1\. Merge locally   ✓       \-     ✓                  ✓
  2\. Create PR       \-      ✓      ✓                  \-

## Common Mistakes

**Skipping test verification** - **Problem:** Merge broken code, create failing
PR - **Fix:** Always verify tests before offering options

**Skipping context verification** - **Problem:** Future sessions lack context to
understand or continue the work - **Fix:** Always check CLAUDE.md, records,
issues, and commit messages

**Open-ended questions** - **Problem:** "What should I do next?" → ambiguous -
**Fix:** Present exactly 2 structured options

## Red Flags

**Never:** - Proceed with failing tests - Merge without verifying tests on
result - Skip the context verification step - Force-push without explicit
request

**Always:** - Verify tests before offering options - Verify context before
offering options - Present exactly 2 options - Clean up worktree after executing
choice

## Integration

**Called by:** - **subagent-driven-development** (Step 7) - After all tasks
complete - **executing-plans** (Step 5) - After all batches complete

**Pairs with:** - **working-within-spinclass-sessions** - Defines session
constraints this skill operates within
