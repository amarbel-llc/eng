# General

- if running within a git worktree (such as `.worktrees/<worktree-name>`), do
  not interface with root git directory at all; use worktree exclusively
  - when deciding where to research the repo, agents MUST use the worktree
- use function names that are descriptive-enough to avoid redundant comments
- if git committing fails due to gpg-signing, DO NOT try to commit without a
  signature, instead ask the user to unlock pivy-agent (the SSH agent that also
  serves as the GPG signing agent)
- when debugging or exploring, DO NOT use ad hoc bash scripts or python scripts,
  instead use ad-hoc justfile recipes. mark them with debug or explore groups

# Worktrees and spinclass

- **Do NOT call `EnterWorktree`.** Sessions already run inside a
  spinclass-managed worktree at `.worktrees/<name>`. Why: spinclass worktrees
  are workers, not subject-scoped branches — multiple series of commits and
  merges through the same worktree is expected. After a
  `spinclass merge-this-session`, start the next piece of work from the same
  worktree (new branch via `git checkout -b` if needed), not a new one.

- DO NOT create new git branches for work unless explicitly instructed to by the
  user. You are almost always running in a spinclass session, and those
  worktrees and branches are meant as generic, multi-sequence workers -- do not
  offer to create PR's, treat merge-this-session as the create-PR-and-merge
  flow.

# Mid-Task Idea Capture

If I instruct you to create a todo, use the `/eng:file-issue` skill. Also use
`/eng:file-issue` when you encounter a blocking issue in one of my repositories
during work --- file it and continue rather than trying to fix it in the current
task. If I give you a GitHub issue to fix, use the `/fix-issue` skill.

# Closing GitHub issues

- When a commit or PR resolves a tracked issue, put `Closes #N` (or
  `Fixes #N` / `Resolves #N`) in the message so GitHub auto-closes on merge.
  Don't close issues manually and don't comment-then-close --- let the merge
  do the work.
- Don't mention or summarize this convention back to me. Using the
  auto-close facility is a given; flagging it ("note: I used `Closes #N`")
  wastes a turn.

# Environment

- `direnv reload` within Claude sessions NEVER works as expected. If the
  devshell needs to change (new packages, updated flake inputs), ask the user to
  restart the session with a `direnv reload` in between. Do not attempt to run
  `direnv reload` or `direnv allow` from within the session.
- `nix build` against a dirty git tree only includes **git-tracked files**.
  Untracked files (new `.go` files, new directories, new flake inputs) are
  invisible to the build even though the working tree sees them. Symptom: `go
  build ./...` passes but `nix build` fails with "cannot find module providing
  package" or similar, and the unpacked source archive path is identical across
  runs despite your edits. Fix: `git add` the new path before re-running
  `nix build`. No commit needed — staging is enough.

# Debugging

- **Signs you are flailing:** you have tried 2+ hypotheses without confirming
  any, you are surprised by a result but immediately jump to the next theory,
  you are reading code 3+ layers deep without checking intermediate assumptions,
  or you are writing fixes before understanding the root cause.
- **When any of those signs appear:** STOP. Summarize what you know, what is
  surprising, and what assumptions remain untested. Present this to the user and
  wait for direction before continuing. Do not chain hypotheses without checking
  in.
- **Verify before declaring "already fixed":** when investigating a bug, check
  edge cases (type aliases, qualified names, primitive wrappers, cross-package
  references) that may not be covered by the obvious code path. Do not conclude
  an issue is resolved until the specific reproduction case passes.
- **Front-load constraints:** before proposing an approach, state what is
  unavailable in the environment (e.g. no glibc-static, no GNOME on Sway) and
  what has already been tried. This avoids wasting cycles on dead-end
  approaches.
