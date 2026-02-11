# Nix Flake Patterns Documentation

A living document tracking the current state of flake.nix patterns across the repository, serving as a reference for consolidation and improvement efforts.

**Note**: System packages (`common`, `darwin`, `linux`) are documented separately in [system-patterns.md](system-patterns.md).

## Overview

### Purpose
This document captures the existing architectural patterns used across all flake.nix files in the repository. It serves as:
- A reference for understanding current implementations
- A baseline for tracking improvements
- A guide for maintaining consistency across packages

### Goals
1. **Consolidation** - Reduce pattern variation where possible
2. **Consistency** - Align similar packages on common patterns
3. **Documentation** - Track current state and future direction

## Formatting

All flake.nix files should be formatted using `nixfmt` via the `fmt` app exported by the nix devenv:

```sh
# Format all devenv flakes
nix run ./devenvs/nix#fmt -- devenvs/*/flake.nix

# Format a single flake
nix run ./devenvs/nix#fmt -- devenvs/go/flake.nix

# Format any flake
nix run ./devenvs/nix#fmt -- path/to/flake.nix
```

The nix devenv flake exports:
- `formatter.${system}` - for use with `nix fmt`
- `apps.${system}.fmt` - for direct invocation via `nix run`

## Nixpkgs Naming Convention

All flakes use the **stable-first** naming convention:

- `nixpkgs` → stable (the default)
- `nixpkgs-master` → unstable/rolling (for latest features)

### Variable Naming

- `pkgs = import nixpkgs` → stable packages (default)
- `pkgs-master = import nixpkgs-master` → unstable packages (when needed)

### Updating Nixpkgs

Use the justfile commands to update all flakes consistently:

```sh
# Fetch latest commit SHAs
just update-nixpkgs

# Update all flakes using fh
just update-nix
```

The `bin/update_flakes.bash` script uses `fh` (FlakeHub CLI) to update:
- `nixpkgs` → latest stable branch commit
- `nixpkgs-master` → latest master branch commit
- `utils` → latest flake-utils

### Rationale

| Input | Points To | Use Case |
|-------|-----------|----------|
| `nixpkgs` | stable | Language runtimes, core tools, reliability |
| `nixpkgs-master` | unstable | LSPs, linters, formatters, latest features |

---

# Devenv Packages

Development environment packages in `devenvs/`.

## Outputs Structure

### devShells Only (79%)
The minimal pattern, providing only a development shell:
```nix
devShells.${system}.default = pkgs.mkShell {
  packages = [ ... ];
};
```
Used by: `bats`, `elixir`, `haskell`, `js`, `kotlin`, `latex`, `lua`, `ocaml`, `protobuf`, `python`, `ruby`, `rust`, `rust_toolchain`, `scala`, `shell`, `zig`, and others

### packages + devShells (12%)
Exports both installable packages and development shell:
```nix
packages.${system}.default = pkgs.symlinkJoin { ... };
devShells.${system}.default = pkgs.mkShell { ... };
```
Used by: `php`, `nix`, `go`

### symlinkJoin Aggregation
Combines multiple packages into a single derivation:
```nix
packages.default = pkgs.symlinkJoin {
  name = "combined-packages";
  paths = builtins.attrValues packages;
};
```

Alternative using buildEnv (`direnv`):
```nix
packages.default = pkgs.buildEnv {
  name = "direnv";
  paths = [ direnv ];
};
```

### overlays Export (19%)
Exports overlays for nixpkgs customization:
```nix
overlays = [(final: prev: {
  jdk = prev.jdk20;
  sbt = prev.sbt.override { jre = jdk; };
})];
```
Used by: `node`, `scala`, `kotlin`, `rust_toolchain`, `go`

## System Support Pattern

All devenv packages use `utils.lib.eachDefaultSystem` for implicit system detection via flake-utils:
```nix
outputs = { self, nixpkgs, utils, ... }:
  utils.lib.eachDefaultSystem (system:
    let pkgs = import nixpkgs { inherit system; };
    in { devShells.default = pkgs.mkShell { ... }; }
  );
```

## Nixpkgs Usage Patterns

### Stable Only (73%)
Uses only stable nixpkgs (the default):
```nix
let pkgs = import nixpkgs { inherit system; };
```
Used by: `bats`, `digital_ocean`, `direnv`, `elixir`, `haskell`, `java`, `js`, `kotlin`, `latex`, `lua`, `nix`, `node`, `ocaml`, `pandoc`, `protobuf`, `qmk`, `ruby`, `scala`, `shell`, `zig`

### Mixed Stable/Master (27%)
Runtime from stable, tooling from master:
```nix
let
  pkgs = import nixpkgs { inherit system; };           # stable (runtime)
  pkgs-master = import nixpkgs-master { inherit system; };  # master (tooling)
in {
  packages = {
    inherit (pkgs) runtime-package;
    inherit (pkgs-master) lsp-server linter formatter;
  };
}
```
Used by: `go`, `php`, `python`, `rust`, `rust_toolchain`

**Strategy**: Language runtimes (go, python, node, etc.) use stable for reliability. Dev tooling (LSPs, linters, formatters) use master for latest features.

## Devenv Package Reference

| Package | Outputs | Nixpkgs Strategy | Special Inputs |
|---------|---------|------------------|----------------|
| `bats` | devShells | stable | - |
| `digital_ocean` | devShells, packages | stable | - |
| `direnv` | devShells, packages | stable | - |
| `elixir` | devShells | stable | - |
| `go` | devShells, packages, overlays | stable + master | gomod2nix |
| `haskell` | devShells | stable | - |
| `java` | devShells, packages | stable | - |
| `js` | devShells | stable | - |
| `kotlin` | devShells | stable | - |
| `latex` | devShells | stable | - |
| `lua` | devShells | stable | - |
| `nix` | devShells, packages, formatter, apps | stable | fh |
| `node` | devShells | stable | - |
| `ocaml` | devShells | stable | - |
| `pandoc` | devShells | stable | lua |
| `php` | devShells, packages | stable + master | - |
| `protobuf` | devShells | stable | - |
| `python` | devShells | stable + master | - |
| `qmk` | devShells, packages | stable | - |
| `ruby` | devShells | stable | - |
| `rust` | devShells | stable + master | rust-overlay |
| `rust_toolchain` | devShells | stable + master | rust-overlay |
| `scala` | devShells | stable | - |
| `shell` | devShells | stable | - |
| `zig` | devShells | stable | - |

## Devenv Statistics

| Metric | Count | Percentage |
|--------|-------|------------|
| Total devenv packages | 25 | 100% |
| Using eachDefaultSystem | 25 | 100% |
| With packages output | 6 | 24% |
| Stable-only nixpkgs | 20 | 80% |
| Mixed stable/master | 5 | 20% |

## Package-Specific Configuration

Some packages require special nixpkgs configuration:

| Package | Configuration | Reason |
|---------|--------------|--------|
| `digital_ocean` | `config.allowUnfree = true` | docker is unfree |
| `elixir` | Uses `apple_sdk_11_0` | Migrated from deprecated `apple_sdk` |

---

# Non-Devenv Packages

All other flake.nix files outside of `pkgs/alfa/devenv-*/`.

## Package Categories

### systems/
System and utility packages:
- `common`, `darwin`, `linux` - Platform package aggregations
- `vim`, `bash`, `ssh`, `glyphs` - Tool configurations
- `claude`, `savvy-cli`, `html-to-pdf` - Applications
- `sand-castle`, `zmx`, `thcon` - Utilities

### pkgs/bravo
Project packages:
- `chrest` - Browser extension (with Go backend)
- `dodder` - Tools and utilities
- `fat_ass` - Python projects
- `resume-builder`, `shdoc`, `sweatshop` - Various tools

### pkgs/charlie
- `resume` - Resume generation

### repos/
Standalone repositories:
- `ssh-agent-mux` - SSH agent multiplexer (Rust)
- `zmx` - Zig project

### Other Locations
- Root `flake.nix` - Main repository flake
- `playgrounds/` - Experimental projects
- `rcm/` - Configuration management

## Non-Devenv Nixpkgs Patterns

### Stable-First Pattern
```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/<stable-commit>";
  nixpkgs-master.url = "github:NixOS/nixpkgs/<unstable-commit>";
  utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
};
```

Used by all non-devenv packages including:
- Root `flake.nix`
- All `pkgs/bravo/*` packages
- All `systems/*` packages
- `repos/ssh-agent-mux`, `repos/zmx`

### Common Additional Inputs

| Input | Source | Used By |
|-------|--------|---------|
| `go` | `github:friedenberg/eng?dir=devenvs/go` | Go projects |
| `rust` | `github:friedenberg/eng?dir=devenvs/rust` | Rust projects |
| `nix` | `github:friedenberg/eng?dir=devenvs/nix` | Nix projects |
| `rust-overlay` | `github:oxalica/rust-overlay` | Rust projects |
| `gomod2nix` | `github:nix-community/gomod2nix` | Go projects |
| `nix-darwin` | `github:LnL7/nix-darwin` | macOS system config |
| `uv2nix` | pyproject ecosystem | Python projects |

---

# Recommended Pattern

All flakes should use the stable-first pattern:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/<stable-commit>";
    nixpkgs-master.url = "github:NixOS/nixpkgs/<unstable-commit>";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1";
  };

  outputs = { self, nixpkgs, nixpkgs-master, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgs-master = import nixpkgs-master { inherit system; };
      in {
        # Use pkgs (stable) for runtimes and core tools
        # Use pkgs-master (unstable) for LSPs, linters, formatters
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.go                     # runtime from stable
            pkgs-master.gopls           # LSP from master
            pkgs-master.golangci-lint   # linter from master
          ];
        };
      }
    );
}
```

---

# Future Direction

## Completed Goals

1. **Unified System Pattern** - All packages use `eachDefaultSystem`
2. **Consistent Formatting** - All flakes formatted with `nixfmt`
3. **Runtime vs Tooling Split** - Runtimes from stable, tooling from master
4. **Unified Naming Convention** - All flakes use `nixpkgs`/`nixpkgs-master` (stable-first)

## Remaining Goals

1. **Unify Overlay Patterns** - Standardize overlay patterns for JVM-based languages
2. **Document All Packages** - Complete reference tables for non-devenv packages

---

*Last updated: 2026-02-07*
