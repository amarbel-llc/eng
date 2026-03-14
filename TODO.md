
## flake.lock deduplication (106 nodes, only 34 unique)

- [ ] add `purse-first.follows` on dodder/just-us/pivy/ssh-agent-mux — eliminates ~40 nodes (test all repos against consolidated rev)
- [ ] add deep follows for `just-us.inputs.rust` devenv inputs (nixpkgs, nixpkgs-master, utils) — eliminates ~6 nodes
- [ ] add deep follows for `pivy.inputs.sandcastle` subtree (devenv-nix, devenv-node) — eliminates ~6 nodes
- [ ] add `dodder.inputs.nixpkgs-master.follows = "nixpkgs-master"` — eliminates 1 node
- [ ] make purse-first's own transitive deps (fh, crane, gomod2nix) followable from top-level — eliminates ~8 nodes
- [x] chrest/flake.nix: `devenv-js` still points to `amarbel-llc/eng?dir=devenvs/js` — purse-first has `devenvs/node` but no `devenvs/js`

## Test assertion quality guard

- [ ] add CLAUDE.md rule: when modifying test assertions, new assertions must validate at least as much structure as the originals. If a change reduces assertion specificity (e.g., structured YAML blocks → bare prefix matching), that's a red flag — the test is no longer verifying meaningful behavior. Never mechanically rewrite assertions to match new output without evaluating whether they still test something.

## Transcript analysis: eng CLAUDE.md additions

- [x] add instruction: verify nix package exists with `nix eval` or `chix search` BEFORE writing flake.nix; don't guess attribute paths
- [ ] add instruction: run single test first to validate env setup; use `head`/`tail` to limit test output in context

## SSH agent forwarding + ControlMaster stale socket issue

- [ ] fix: ControlMaster reuses sessions where forwarded agent socket is dead (ControlPersist outlives the forwarding channel); evaluate `StreamLocalBindUnlink yes`, shorter `ControlPersist`, or refreshing agent forwarding on existing master

## Mako notifications

- [ ] Per-session Claude Code notification grouping: use Notification hook to send custom `kitten notify` with session/cwd in title + `app-name=claude-code`, then hide the default kitty notification via mako criteria `invisible=1`

## Transcript analysis: ~/.claude/CLAUDE.md additions

- [x] amend mid-task idea capture: cross-repo TODOs go in the relevant repo's TODO.md, not the current one

## Multi-marketplace integration

- [ ] FDR: integrated dev/test environment for multi-marketplace local development
