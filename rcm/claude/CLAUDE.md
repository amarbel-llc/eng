- if running within a git worktree (such as `spinclass/<worktree-name>`), do not
  interface with root git directory at all; use worktree exclusively
- use function names that are descriptive-enough to avoid redundant comments
- if git committing fails due to gpg-signing, DO NOT try to commit without a
  signature, instead ask the user to unlock the agent

## Mid-Task Idea Capture

When a new idea, improvement, or tangent emerges mid-task — from me or from
something you notice — do not explore it. Instead:

1. Append one line to `TODO.md` in the nearest repo root: `- [ ] <idea>`
2. Say "captured" and continue the current task immediately

Do not: create an FDR, research feasibility, estimate effort, discuss trade-offs,
or ask if I want to pursue it now. The answer is always no — capture and continue.

If the idea is substantial enough for an FDR, note that in the TODO line
(`- [ ] FDR: <idea>`). Triage happens in a separate session, never mid-task.

This matters because divergent thinking mid-task is my biggest productivity risk.
The capture must feel complete enough to let the thought go. One line is enough.
