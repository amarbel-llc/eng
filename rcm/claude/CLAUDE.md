- if running within a git worktree (such as `spinclass/<worktree-name>`), do not
  interface with root git directory at all; use worktree exclusively
- use function names that are descriptive-enough to avoid redundant comments
- if git committing fails due to gpg-signing, DO NOT try to commit without a
  signature, instead ask the user to unlock the agent
