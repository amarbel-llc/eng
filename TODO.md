
## flake.lock deduplication (106 nodes, only 34 unique)

- [ ] add `purse-first.follows` on dodder/just-us/pivy/ssh-agent-mux — eliminates ~40 nodes (test all repos against consolidated rev)
- [ ] add deep follows for `just-us.inputs.rust` devenv inputs (nixpkgs, nixpkgs-master, utils) — eliminates ~6 nodes
- [ ] add deep follows for `pivy.inputs.sandcastle` subtree (devenv-nix, devenv-node) — eliminates ~6 nodes
- [ ] add `dodder.inputs.nixpkgs-master.follows = "nixpkgs-master"` — eliminates 1 node
- [ ] make purse-first's own transitive deps (fh, crane, gomod2nix) followable from top-level — eliminates ~8 nodes
- [x] chrest/flake.nix: `devenv-js` still points to `amarbel-llc/eng?dir=devenvs/js` — purse-first has `devenvs/node` but no `devenvs/js`

## Transcript analysis: eng CLAUDE.md additions

- [x] add instruction: verify nix package exists with `nix eval` or `chix search` BEFORE writing flake.nix; don't guess attribute paths
- [ ] add instruction: run single test first to validate env setup; use `head`/`tail` to limit test output in context

## Transcript analysis: ~/.claude/CLAUDE.md additions

- [x] amend mid-task idea capture: cross-repo TODOs go in the relevant repo's TODO.md, not the current one
