# AGENTS.md

This file provides guidance to AI coding agents when working with code in this
repository.

## Overview

Nix-based monorepo aggregating system packages, dotfiles (rcm), and 30+ project
repos. Published to FlakeHub as `amarbel-llc/eng` on every push to master. CI
builds on x86_64-linux and aarch64-darwin.

## Running Devloop Commands

Use the `just-us-agents` MCP tool to execute justfile recipes, not raw `just`
invocations via Bash. The MCP tool gives structured recipe discovery
(`list-recipes`, `show-recipe`) and reaches child justfiles in subdirectories.

**Before running commands like `go test`, `go vet`, `cargo test`, `cargo
clippy`, `nix build`, or any other build/test/lint command, check for an
existing recipe.** This repo and its sub-repos almost always have a recipe
already wired up for the devloop you want — running the underlying tool
directly bypasses the recipe's environment setup, flags, and conventions.

Workflow:

1. `just-us-agents list-recipes` to discover what's available (includes
   recipes from child justfiles, shown with `dir/recipe` prefix).
2. `just-us-agents show-recipe <name>` if you want to see what it does
   before running.
3. `just-us-agents run-recipe <name>` to execute it.

Only fall back to running the underlying tool directly when no recipe exists,
and consider whether one should be added (mark new debug/exploration recipes
with the `debug` or `explore` groups per `~/.claude/CLAUDE.md`).

## Build & Update Commands

``` sh
just build              # Build all: nix packages + home-manager/darwin + rcm dotfiles
just build-nix          # Nix packages only (nix build --show-trace)
just build-home         # Home-manager / nix-darwin switch (see below)
just build-nix-darwin   # sudo darwin-rebuild switch --impure --flake .
just build-rcm          # Dotfiles only via rcup

just install-purse-first  # Build + validate + install purse-first marketplace
just install-bob          # Build + validate + install bob marketplace
just validate-purse-first # Build + validate only (no install)
just validate-bob         # Build + validate only (no install)

just bump-nixpkgs       # Bump nixpkgs-master pin to upstream HEAD,
                        # refresh flake.lock, build to verify, print
                        # version diff, and commit. Canonical entry
                        # point for moving the master pin.
just update-nix-flake   # nix flake update (refreshes lockfile only;
                        # SHA-pinned inputs like nixpkgs-master unaffected)
just update-nix-repos   # Cascade master SHA to repos/* flakes (no commit)

just clean              # nix-store --gc
```

Format nix files: `lux fmt path/to/flake.nix`

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

**Pin form (eng's top-level `flake.nix`):**

- `nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11"` --- branch ref. Bumps
  happen automatically via `nix flake update` (or `just update-nix-flake`)
  whenever the release branch advances.
- `nixpkgs-master.url = "github:NixOS/nixpkgs/<sha>"` --- SHA literal,
  mirrored in `nixpkgs-git-master.git-sha`. Only moves via
  `just bump-nixpkgs`, which fetches the new SHA, edits the literal,
  refreshes the lockfile, builds to verify, prints a sentinel-package
  version diff, and stages the changes for review. Rolling back to a
  previous SHA is a one-line edit to `flake.nix` followed by
  `nix flake update nixpkgs-master`.

Sub-repo flakes in `repos/` still use SHA literals for both inputs
today; `just update-nix-repos` cascades the master SHA into them via a
line-anchored `sed` (no `fh add`, no FlakeHub round-trip) and stages
each repo's changes for review. Their stable pin is unaffected by the
cascade — bump it standalone with `nix flake update nixpkgs` per
sub-repo if needed.

### Wrapper-Pinned Packages

When a specific package needs to be held back at an older version while
the rest of `nixpkgs-master` continues to move (e.g. a regression in the
latest release that we can't work around), pin it via a **dedicated
frozen flake input** consumed only by a home-manager wrapper — not by
overriding `nixpkgs-master` itself.

Pattern:

1. Add a new input in `flake.nix` with a SHA literal pointing at the
   last known-good nixpkgs revision, e.g.
   `nixpkgs-<name>-pinned.url = "github:NixOS/nixpkgs/<sha>"`.
   Do not `follows` anything — it must stay frozen.
2. Add the import to `home/special-args.nix` as `pkgs-<name>-pinned`.
   This is the ONLY place the pinned tree needs to be wired into
   home-manager plumbing — the helper returned by that file is shared
   by both `homeConfigurations.linux` and the nested home-manager block
   inside `darwinConfigurations.${hostname}`, so a single line here
   reaches both platforms. Do not thread it directly through
   `flake.nix` — that's the pre-consolidation pattern (see #18) and
   guarantees drift between the two branches.
3. In `home/wrappers.nix`, define a `writeShellScriptBin` wrapper that
   `exec`s the binary from the pinned tree. This wrapper becomes the
   sole authoritative `$PATH` entry for that command.
4. Remove the package from `systems/common/default.nix` (and anywhere
   else in the flake that would otherwise place an unpinned copy into
   a user-visible profile). Two sources of the same command on PATH is
   a footgun.
5. `just bump-nixpkgs` leaves the pinned input alone — its `sed` is
   anchored to `nixpkgs-master.url` specifically. Verify that the
   sentinel `versions_expr` in the bump recipe does not reference the
   pinned package (it would just report master's version, which is
   misleading).

Rolling back the pin: delete the input, revert `home/wrappers.nix` to
use `pkgs-master.<package>`, re-add the package to `systems/common`,
and restore any removed sentinel entries. One commit.

Current wrapper pins: none.

### Home-Manager & Nix-Darwin

User environment and macOS system settings are managed declaratively via
home-manager and nix-darwin. Configs live in `home/` and
`rcm/tag-darwin/config/nix-darwin/modules/`.

**Two platform paths:**

- **macOS**: `darwinConfigurations.${hostname}` --- nix-darwin manages system
  defaults (dock, finder, touchID, fish shell) + Homebrew (casks, brews, App
  Store apps). Home-manager is integrated as a nix-darwin module.
- **Linux**: `homeConfigurations.linux` --- standalone home-manager
  configuration.

**Home-manager modules** (`home/`):

- `identity.nix` --- username, home directory (macOS reads
  `/etc/nix-darwin/identity.json`, Linux uses env vars)
- `common.nix` --- shared packages, fish, direnv, kitty
- `darwin.nix` / `linux.nix` --- platform-specific entry points (import common +
  repo-packages)
- `git.nix` --- git config with dynamic alias generation from
  `home/git/aliases/*.git-alias`
- `repo-packages.nix` --- aggregates default packages from all repo flake inputs

**Nix-darwin modules** (`rcm/tag-darwin/config/nix-darwin/modules/`):

- `system.nix` --- macOS system defaults, TouchID + YubiKey PIV sudo, fish shell
- `apps.nix` --- Homebrew taps, brews, casks, Mac App Store apps
- `home-manager.nix` --- wires home-manager into nix-darwin

**Build commands:**

- `just build-home` --- on macOS runs `darwin-rebuild switch --impure`, on Linux
  runs `home-manager switch --impure`. Creates `/etc/nix-darwin/identity.json`
  on first run (prompts for git identity).
- `just build-nix-darwin` --- macOS system rebuild only.
- `just build` includes `build-home` in its sequence.

**YubiKey PIV smart card:** macOS login and sudo are configured to accept
YubiKey PIV authentication alongside TouchID. PAM is managed in `system.nix`
(`pam_smartcard.so`). Initial setup and re-pairing use
`bin/setup-piv-smartcard-pairing.bash` (see script header for troubleshooting).
The pivy-agent for SSH (`home/pivy-agent.nix`) is separate from macOS smart card
login.

**RCM migration:** user-level dotfiles (fish, direnv, git, kitty) have migrated
to home-manager. Old rcm versions archived in `rcm/tag-home_manager-obsolete/`.
RCM still manages platform-specific app configs (aerospace, karabiner,
hammerspoon, etc.) and SSH/vim configs.

### NSS on Non-NixOS Linux

Nix-built binaries can't resolve user/group IDs on non-NixOS Linux because
nix's glibc can't find system NSS modules. See `home/README.md` for the full
explanation and the symlink-based fix in `~/.config/nix/nss-session.nix`.

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
  Directory                              Purpose
  -------------------------------------- --------------------------------------
  `flake.nix`                            Top-level aggregator of all packages

  `envs/`                                Nix dev shells (integration-test)

  `systems/{common,darwin,linux}/`       Platform-specific package collections
                                         (\~70 tools)

  `home/`                                Home-manager modules (fish, git,
                                         direnv, kitty, packages)

  `repos/`                               30+ separate git repos (dodder, lux,
                                         grit, nix-mcp-server, etc.)

  `rcm/`                                 Dotfiles managed by rcup with
                                         tag-based platform targeting

  `bin/`                                 Utility scripts (update_flakes.bash)

  `docs/`                                Plans, features, and decision records
  -----------------------------------------------------------------------------

### NATO Phonetic Module Hierarchy

Used in dodder to enforce dependency direction and prevent cycles:

`alfa` (foundational, no deps) → `bravo` → `charlie` → ... → `india` (top-level)

Each layer may only depend on layers below it.

## Code Style

- **Nix**: Format with `nixfmt-rfc-style` (via `lux fmt`)
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
- **New project** --- creating a new flake or package

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
`nix flake check` - **CLI integration**: `bats` framework

**Run a single test first** to validate the environment before running the full
suite. Use `head`/`tail` to limit test output in context --- don't paste
hundreds of lines of test output.

**Assertion quality guard:** When modifying test assertions, new assertions must
validate at least as much structure as the originals. Never mechanically rewrite
assertions to match new output without evaluating whether they still test
meaningful behavior. If a change reduces assertion specificity (e.g. structured
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
- Subprojects have their own AGENTS.md files --- check for them when working in
  repos/
