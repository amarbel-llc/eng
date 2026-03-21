# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Overview

Nix-based monorepo aggregating devenv templates, system packages, dotfiles
(rcm), and 30+ project repos. Published to FlakeHub as `friedenberg/eng` on
every push to master. CI builds on x86_64-linux and aarch64-darwin.

## Build & Update Commands

``` sh
just build              # Build Nix packages + install dotfiles via rcup
just build-nix          # Nix packages only (nix build --show-trace)
just build-rcm          # Dotfiles only via rcup

just install-purse-first  # Build + validate + install purse-first marketplace
just install-bob          # Build + validate + install bob marketplace
just validate-purse-first # Build + validate only (no install)
just validate-bob         # Build + validate only (no install)

just update-nixpkgs     # Fetch latest stable/master commit SHAs
just update-nix         # Update flake inputs in eng (excludes repos/)
just update-nix-repos   # Update all repos/ flake inputs in parallel
just update-nix-all     # Both of the above

just clean              # nix-store --gc
```

Format nix files: `nix run ./devenvs/nix#fmt -- path/to/flake.nix`

## Nix Flake Architecture

The top-level `flake.nix` aggregates all subprojects into a single `symlinkJoin`
package. It imports every repo as a flake input and collects their default
packages plus platform-specific packages from `systems/{common,darwin,linux}`.

### Adding Nix Packages

Before adding a package to a flake.nix, verify it exists using `nix eval` or the
`chix search` MCP tool. Do not guess attribute paths --- if the first eval
fails, check whether the tool should come from a language package manager (npm,
cargo, pip) instead of nixpkgs.

### Stable-First Nixpkgs Convention

Every flake uses this pattern --- do not deviate:

- `nixpkgs` → stable branch (runtimes, core tools)
- `nixpkgs-master` → master/unstable (LSPs, linters, formatters, latest
  features)
- `utils` → `flake-utils` from FlakeHub
- Variables: `pkgs = import nixpkgs`, `pkgs-master = import nixpkgs-master`

Pinned SHAs are stored in `nixpkgs-git-master.git-sha`,
`nixpkgs-stable-git.git-sha`, and `nixpkgs-stable-darwin-git.git-sha`.

### Direnv Integration

The repo `.envrc` loads `devenvs/nix` and `devenvs/shell`. Subprojects reference
devenvs via flake inputs,
e.g. `go.url = "github:amarbel-llc/purse-first?dir=devenvs/go"`.

### Multi-Marketplace Architecture

Two marketplaces are built and installed separately to avoid
`.claude-plugin/marketplace.json` collision in `symlinkJoin`:

- **purse-first** --- framework library + CLI + 8 framework skills
- **bob** --- MCP servers (grit, get-hubbed, lux, chix, mgp) + 26 workflow
  skills

Both are in `infraInputs` so their marketplace outputs are excluded from
auto-import. The `symlinkJoin` includes `purse-first.packages.purse-first` (CLI
only) and `bob.packages.default` (all packages without the marketplace wrapper).
Each marketplace is built, validated, and installed independently via
`just install-purse-first` and `just install-bob`.

Update order: purse-first before bob (bob depends on purse-first via `follows`).
Restart Claude Code sessions after install to pick up new plugin config.

## Repository Layout

  -----------------------------------------------------------------------------
  Directory                               Purpose
  --------------------------------------- -------------------------------------
  `flake.nix`                             Top-level aggregator of all packages

  `devenvs/`                              Symlinks to purse-first devenvs
                                          (`github:amarbel-llc/purse-first`).
                                          25 language-specific dev shells (go,
                                          rust, python, nix, shell, etc.)

  `systems/{common,darwin,linux}/`        Platform-specific package collections
                                          (\~70 tools)

  `pkgs/alfa/`                            Core Nix packages (18 packages)

  `repos/`                                30+ separate git repos (dodder, lux,
                                          grit, nix-mcp-server, etc.)

  `rcm/`                                  Dotfiles managed by rcup with
                                          tag-based platform targeting

  `bin/`                                  Utility scripts (update_flakes.bash)

  `docs/`                                 nix-patterns.md, system-patterns.md
  -----------------------------------------------------------------------------

### NATO Phonetic Module Hierarchy

Used in dodder and pkgs/ to enforce dependency direction and prevent cycles:

`alfa` (foundational, no deps) → `bravo` → `charlie` → ... → `india` (top-level)

Each layer may only depend on layers below it.

## Code Style

- **Nix**: Format with `nixfmt-rfc-style` (available via
  `nix run ./devenvs/nix#fmt`)
- **Shell**: `set -euo pipefail`, 2-space indent, `[[ ]]` conditionals, quote
  all vars. Format with `shfmt -s -i=2`
- **Go**: `goimports` + `gofumpt`. Follow NATO module hierarchy. Never
  dereference `sku.Transacted` pointers --- use `ResetWith`
- **Rust**: `cargo fmt` + `cargo clippy`, 4-space indent

## Planning Requirements

A design doc + implementation plan (via `brainstorming` and `writing-plans`
skills) is required when ANY of these apply:

- **3+ files modified** --- changes spanning multiple packages or modules
- **External integration** --- code calling CLI tools, OS services, hardware,
  network protocols, or file formats consumed by other tools
- **CLI surface area** --- adding, removing, or renaming user-facing commands,
  flags, or output formats
- **Cross-repo coordination** --- changes that must land in multiple repos/
- **New project** --- creating a new flake, package, or devenv

Not required: single-file bug fixes, documentation, dependency updates,
formatting/linting, test additions for existing behavior.

## Scope Discipline

Prefer the smallest change that addresses the stated problem. New ideas that
emerge during implementation go to GitHub Issues, not into the current task (see
Mid-Task Idea Capture in `~/.claude/CLAUDE.md`).

Push back on "while we're here" additions. Each change should be independently
verifiable and independently revertable.

Exception: if the new idea reveals that the current approach is fundamentally
wrong, stop and re-plan rather than bolting on fixes.

## Fix Ownership

When a bug involves interaction between multiple components or repos, identify
which component owns the fix **before writing code**. Present the diagnosis and
ask which repo/component should change --- do not assume the fix belongs in the
repo you're currently working in.

Signs the fix belongs elsewhere: - The current repo's contract says "expect
well-formed input from X" and X isn't providing it - The fix requires heuristic
detection of another tool's output format - An awk fallback or adapter layer
already exists for this kind of translation

## External Integration Verification

Code interacting with external systems requires verification against the real
system before committing. Unit tests alone are insufficient.

What counts: CLI subprocesses, OS services, hardware/tokens, network protocols,
file formats consumed by other tools, crypto round-trips.

Required before commit: 1. Run against the real system (or integration test
environment), not a mock 2. Verify the round-trip (sign AND verify, install AND
uninstall+reinstall) 3. Note what was verified in the commit message

## Key Projects in repos/

- **dodder** --- Distributed zettelkasten-like blob store (Go). NATO-phonetic
  module hierarchy (`alfa`→`bravo`→...→`india`)
- **lux** --- LSP multiplexer with MCP support (Go). Configured via `lsps.toml`
- **grit** --- Git MCP server (Go)
- **nix-mcp-server** --- Nix CLI operations MCP (Rust). JSON-RPC 2.0 over
  stdin/stdout
- **ssh-agent-mux** --- SSH agent multiplexer (Rust)
- **bob** --- MCP servers, CLI tools, and 26 workflow skills. Marketplace via
  purse-first's `mkMarketplace`

## rcm Dotfiles

Managed by `rcup`. Config in `rcm/rcrc`. Uses tags for platform-specific configs
(`tag-darwin/`, `tag-linux/`, `tag-nix/`, `tag-ssh-client/`, `tag-ssh-host/`).
Git config is modular: `config-common`, `config-signed`, `config-user`, with
aliases split into individual files under `config/git/aliases/`.

## Testing

Each subproject has its own test setup. Common patterns: - **Go**:
`go test -v ./...` or `just test` - **Rust**: `cargo test` - **Nix**:
`nix flake check` - **CLI integration**: `bats` framework (devenv at
`devenvs/bats/`)

**Run a single test first** to validate the environment before running the full
suite. Use `head`/`tail` to limit test output in context --- don't paste
hundreds of lines of test output.

**Assertion quality guard:** When modifying test assertions, new assertions must
validate at least as much structure as the originals. Never mechanically rewrite
assertions to match new output without evaluating whether they still test
meaningful behavior. If a change reduces assertion specificity (e.g. structured
YAML blocks to bare prefix matching), that's a red flag.

## Feature Lifecycle

Cross-cutting features (conventions, tools, infrastructure) that span multiple
repos use FDR/ADR/RFC records with lifecycle tracking:

- **FDR** documents what the feature does (always required)
- **ADR** documents why a particular approach was chosen (when alternatives
  exist)
- **RFC** specifies the interface contract (when multiple repos implement it)

Status lifecycle: `exploring → proposed → experimental → testing → accepted`

Start with an FDR in `exploring` state (problem statement only) before
committing to a solution. Each record includes `promotion-criteria` in its YAML
front matter defining when it advances to the next stage.

## Notes

- GPG signing is required for commits. If signing fails, ask user to unlock
  their agent rather than skipping signatures
- Use `gum` for log output in scripts
- Use `fh` (FlakeHub CLI) for flake input management
- Subprojects have their own CLAUDE.md files --- check for them when working in
  repos/
