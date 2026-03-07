
- [ ] figure out why flake.lock is huge
- [ ] chrest/flake.nix: `devenv-js` still points to `amarbel-llc/eng?dir=devenvs/js` — purse-first has `devenvs/node` but no `devenvs/js`

## Transcript analysis: CLAUDE.md additions

### eng root CLAUDE.md
- [ ] add instruction: `develop_run` rejects shell metacharacters; use `env` as command for env vars (`command: "env", args: ["VAR=val", "cmd"]`)
- [ ] add instruction: verify nix package exists with `nix eval` or `chix search` BEFORE writing flake.nix; don't guess attribute paths
- [ ] add instruction: cross-repo TODOs go in the relevant repo's TODO.md, not the current one
- [ ] add instruction: include stop conditions in sub-agent delegation ("if X fails, STOP and report back")
- [ ] add instruction: run single test first to validate env setup; use `head`/`tail` to limit test output in context
- [ ] add instruction: never `nix search` against remote nixpkgs SHA (2+ min eval); use `chix search` tool instead
- [ ] add instruction: prefer sequential work in main context over sub-agents for dependent steps

### dodder CLAUDE.md
- [ ] add instruction: ALWAYS use `just test*` recipes; NEVER run bats/go-test/fixture-generation directly
- [ ] add instruction: BATS fixture tests use `get_fixture_type_sig` for signatures; fresh-store tests use `--regexp`
- [ ] add instruction: NEVER call `errors.Is` when err might be EOF; use `errors.IsEOF()` guard first
- [ ] add instruction: when bumping store version, do NOT remove old version's codec/gob support
- [ ] add instruction: document "lock" dual meaning — content locks (metadata) vs filesystem mutex (LockSmith)
- [ ] add instruction: trailing whitespace matters in dodder output; use `xxd` to debug invisible mismatches

### purse-first / lux CLAUDE.md
- [ ] add instruction: use `/tmp/lux-test-*` for socket paths, not `t.TempDir()` — worktree paths exceed 108-byte `sun_path` limit
- [ ] add instruction: BATS tests need `--allow-unix-sockets` for daemon tests in sandcastle
- [ ] add instruction: `tools -> service` import OK; `service -> tools` creates cycle; use func types to break
- [ ] add instruction: use polling-with-timeout for async test assertions, not `time.Sleep`
- [ ] add instruction: use `-run TestName` or `just test-lux`, not full-package `nix develop` runs

## Transcript analysis: tool / MCP improvements

- [ ] skills that spawn explore agents should instruct: "use Glob before Read on directories, never Read a directory path"
- [ ] add `env` command examples to `develop_run` tool description or skill docs
- [ ] default `log_tail: 50` on `chix build` calls to avoid token overflow

## Transcript analysis: skill improvements

- [ ] explore sub-agents should use Glob/Grep tools, not bash grep/ls/find
- [ ] all delegation prompts should include explicit stop conditions for error recovery
- [ ] sub-agent-driven-development skill: add guidance to keep sequential dependent tasks in main context
