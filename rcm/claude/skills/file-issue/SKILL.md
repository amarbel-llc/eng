---
arguments:
- description: Issue title (concise)
  name: title
  required: true
- description: Target repo (OWNER/REPO). Defaults to cwd's remote
  name: repo
  required: false
description: File a GitHub issue for later triage
user-invocable: true
---

# File Issue

Capture an idea or bug as a GitHub issue for later triage.

## Steps

1.  **Create the issue** using `get-hubbed issue-create` with the provided title
2.  **Body** --- include enough context for a future agent to act on it:
    - For bugs: steps to reproduce and/or a code snippet that could be used to
      write a failing test proving the incorrect behavior
    - For features/ideas: what the problem or idea is, with enough context to
      act on later. If substantial enough for an FDR, note that
3.  **Say "captured"** and continue the current task immediately

## Constraints

- Do not research feasibility, estimate effort, discuss trade-offs, or ask
  whether to pursue it now
- Do not create an FDR, ADR, or RFC --- just capture and move on
- If no repo is specified, use the current directory's git remote
- Triage happens in a separate session, never mid-task
