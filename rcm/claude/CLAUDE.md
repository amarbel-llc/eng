- if running within a git worktree (such as `spinclass/<worktree-name>`), do not
  interface with root git directory at all; use worktree exclusively
- use function names that are descriptive-enough to avoid redundant comments
- if git committing fails due to gpg-signing, DO NOT try to commit without a
  signature, instead ask the user to unlock the agent

## Mid-Task Idea Capture

If I instruct you to create a todo, follow these instructions:

1. Create a GitHub issue in the repo the idea belongs to (for friedenberg or
   amarbel-llc repos). Use the `get-hubbed issue_create` MCP tool. Keep the
   title concise and the body minimal — just enough context to act on later.
2. Say "captured" and continue the current task immediately

Do not: create an FDR, research feasibility, estimate effort, discuss trade-offs,
or ask if I want to pursue it now. Just capture and continue.

If the idea is substantial enough for an FDR, note that in the issue body.
Triage happens in a separate session, never mid-task.

### TODO.md Migration

Repos under friedenberg/ and amarbel-llc/ are migrating from `TODO.md` files to
GitHub Issues for task management. When working in a repo that still has a
`TODO.md`, offer to migrate its contents to GitHub Issues and remove the file.

## JSON

- use `jq` for parsing `JSON` files, data, or MCP responses. Do not use python
  for this
