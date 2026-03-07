
- [ ] figure out why flake.lock is huge
- [ ] chrest/flake.nix: `devenv-js` still points to `amarbel-llc/eng?dir=devenvs/js` — purse-first has `devenvs/node` but no `devenvs/js`

## Transcript analysis: eng CLAUDE.md additions

- [ ] add instruction: verify nix package exists with `nix eval` or `chix search` BEFORE writing flake.nix; don't guess attribute paths
- [ ] add instruction: never `nix search` against remote nixpkgs SHA (2+ min eval); use `chix search` tool instead
- [ ] add instruction: run single test first to validate env setup; use `head`/`tail` to limit test output in context

## Transcript analysis: ~/.claude/CLAUDE.md additions

- [ ] amend mid-task idea capture: cross-repo TODOs go in the relevant repo's TODO.md, not the current one

## Transcript analysis: skill improvements

- [ ] sub-agent exploration: instruct "use Glob/Grep tools, never bash grep/ls/find; use Glob before Read on directories, never Read a directory path"
- [ ] sub-agent delegation: include explicit stop conditions for error recovery ("if X fails, STOP and report back")
- [ ] sub-agent-driven-development skill: add guidance to keep sequential dependent tasks in main context rather than spawning sub-agents
