# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Overview

Nix-based monorepo aggregating devenv templates, system packages, dotfiles
(rcm), and 30+ project repos. Published to FlakeHub as `friedenberg/eng` on
every push to master. CI builds on x86_64-linux, x86_64-darwin, and
aarch64-darwin.

## Build & Update Commands

``` sh
just build              # Build Nix packages + install dotfiles via rcup
just build-nix          # Nix packages only (nix build --show-trace)
just build-rcm          # Dotfiles only via rcup

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
devenvs similarly, e.g. `use flake "$HOME/eng/devenvs/go"`.

## Repository Layout

  -------------------------------------------------------------------------------
  Directory                                   Purpose
  ------------------------------------------- -----------------------------------
  `flake.nix`                                 Top-level aggregator of all
                                              packages

  `devenvs/`                                  25 language-specific dev shells
                                              (go, rust, python, nix, shell,
                                              etc.)

  `systems/{common,darwin,linux}/`            Platform-specific package
                                              collections (\~70 tools)

  `pkgs/alfa/`                                Core Nix packages (18 packages)

  `repos/`                                    30+ separate git repos (dodder,
                                              lux, grit, nix-mcp-server, etc.)

  `rcm/`                                      Dotfiles managed by rcup with
                                              tag-based platform targeting

  `bin/`                                      Utility scripts
                                              (update_flakes.bash)

  `docs/`                                     nix-patterns.md, system-patterns.md
  -------------------------------------------------------------------------------

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
emerge during implementation go to `TODO.md`, not into the current task (see
Mid-Task Idea Capture in `~/.claude/CLAUDE.md`).

Push back on "while we're here" additions. Each change should be independently
verifiable and independently revertable.

Exception: if the new idea reveals that the current approach is fundamentally
wrong, stop and re-plan rather than bolting on fixes.

## External Integration Verification

Code interacting with external systems requires verification against the real
system before committing. Unit tests alone are insufficient.

What counts: CLI subprocesses, OS services, hardware/tokens, network protocols,
file formats consumed by other tools, crypto round-trips.

Required before commit:
1. Run against the real system (or integration test environment), not a mock
2. Verify the round-trip (sign AND verify, install AND uninstall+reinstall)
3. Note what was verified in the commit message

## Key Projects in repos/

- **dodder** --- Distributed zettelkasten-like blob store (Go). NATO-phonetic
  module hierarchy (`alfa`→`bravo`→...→`india`)
- **lux** --- LSP multiplexer with MCP support (Go). Configured via `lsps.toml`
- **grit** --- Git MCP server (Go)
- **nix-mcp-server** --- Nix CLI operations MCP (Rust). JSON-RPC 2.0 over
  stdin/stdout
- **ssh-agent-mux** --- SSH agent multiplexer (Rust)

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

## Feature Lifecycle

Cross-cutting features (conventions, tools, infrastructure) that span multiple
repos use FDR/ADR/RFC records with lifecycle tracking:

- **FDR** documents what the feature does (always required)
- **ADR** documents why a particular approach was chosen (when alternatives exist)
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
