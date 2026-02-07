# Nix Flake Patterns Documentation

A living document tracking the current state of flake.nix patterns across the repository, serving as a reference for consolidation and improvement efforts.

**Note**: System packages (`system-common`, `system-darwin`, `system-linux`) are documented separately in [system-patterns.md](system-patterns.md).

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

All flake.nix files should be formatted using `nixfmt` via the `fmt` app exported by `devenv-nix`:

```sh
# Format all devenv flakes
nix run ./pkgs/alfa/devenv-nix#fmt -- pkgs/alfa/devenv-*/flake.nix

# Format a single flake
nix run ./pkgs/alfa/devenv-nix#fmt -- pkgs/alfa/devenv-go/flake.nix

# Format any flake
nix run ./pkgs/alfa/devenv-nix#fmt -- path/to/flake.nix
```

The `devenv-nix` flake exports:
- `formatter.${system}` - for use with `nix fmt`
- `apps.${system}.fmt` - for direct invocation via `nix run`

## Nixpkgs Naming Conventions

### Current State (Inconsistent)

There are currently **two different naming conventions** in use:

#### devenv-* Packages (stable-first)
Used by all packages in `pkgs/alfa/devenv-*/`:
- `nixpkgs` → stable commit (`fa83fd837f3098e3e678e6cf017b2b36102c7211`)
- `nixpkgs-master` → unstable/rolling commit (`54b154f971b71d260378b284789df6b272b49634`)

#### Non-devenv Packages (unstable-first)
Used by all other flakes in the repository:
- `nixpkgs` → unstable/rolling commit (`54b154f971b71d260378b284789df6b272b49634`)
- `nixpkgs-stable` → stable commit (`fa83fd837f3098e3e678e6cf017b2b36102c7211`)

### Common Input Commits

Both conventions use the same underlying commits:
- **Stable**: `github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211`
- **Unstable/Rolling**: `github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634`
- **flake-utils**: `https://flakehub.com/f/numtide/flake-utils/0.1.102`

### Rationale

| Convention | Primary Use Case | Reasoning |
|------------|------------------|-----------|
| stable-first (devenv) | Development environments | Stability for runtimes; master for latest tooling |
| unstable-first (non-devenv) | Applications, system packages | Latest features by default; stable as fallback |

---

# Devenv Packages

Development environment packages in `pkgs/alfa/devenv-*/`.

## Outputs Structure

### devShells Only (79%)
The minimal pattern, providing only a development shell:
```nix
devShells.${system}.default = pkgs.mkShell {
  packages = [ ... ];
};
```
Used by: `devenv-bats`, `devenv-elixir`, `devenv-haskell`, `devenv-js`, `devenv-kotlin`, `devenv-latex`, `devenv-lua`, `devenv-ocaml`, `devenv-protobuf`, `devenv-python`, `devenv-ruby`, `devenv-rust`, `devenv-rust_toolchain`, `devenv-scala`, `devenv-shell`, `devenv-zig`, and others

### packages + devShells (12%)
Exports both installable packages and development shell:
```nix
packages.${system}.default = pkgs.symlinkJoin { ... };
devShells.${system}.default = pkgs.mkShell { ... };
```
Used by: `devenv-php`, `devenv-nix`, `devenv-go`

### symlinkJoin Aggregation
Combines multiple packages into a single derivation:
```nix
packages.default = pkgs.symlinkJoin {
  name = "combined-packages";
  paths = builtins.attrValues packages;
};
```

Alternative using buildEnv (`devenv-direnv`):
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
Used by: `devenv-node`, `devenv-scala`, `devenv-kotlin`, `devenv-rust_toolchain`, `devenv-go`

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
Used by: `devenv-bats`, `devenv-digital_ocean`, `devenv-direnv`, `devenv-elixir`, `devenv-haskell`, `devenv-java`, `devenv-js`, `devenv-kotlin`, `devenv-latex`, `devenv-lua`, `devenv-nix`, `devenv-node`, `devenv-ocaml`, `devenv-pandoc`, `devenv-protobuf`, `devenv-qmk`, `devenv-ruby`, `devenv-scala`, `devenv-shell`, `devenv-zig`

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
Used by: `devenv-go`, `devenv-php`, `devenv-python`, `devenv-rust`, `devenv-rust_toolchain`

**Strategy**: Language runtimes (go, python, node, etc.) use stable for reliability. Dev tooling (LSPs, linters, formatters) use master for latest features.

## Devenv Package Reference

| Package | Outputs | Nixpkgs Strategy | Special Inputs |
|---------|---------|------------------|----------------|
| `devenv-bats` | devShells | stable | - |
| `devenv-digital_ocean` | devShells, packages | stable | - |
| `devenv-direnv` | devShells, packages | stable | - |
| `devenv-elixir` | devShells | stable | - |
| `devenv-go` | devShells, packages, overlays | stable + master | gomod2nix |
| `devenv-haskell` | devShells | stable | - |
| `devenv-java` | devShells, packages | stable | - |
| `devenv-js` | devShells | stable | - |
| `devenv-kotlin` | devShells | stable | - |
| `devenv-latex` | devShells | stable | - |
| `devenv-lua` | devShells | stable | - |
| `devenv-nix` | devShells, packages, formatter, apps | stable | fh |
| `devenv-node` | devShells | stable | - |
| `devenv-ocaml` | devShells | stable | - |
| `devenv-pandoc` | devShells | stable | devenv-lua |
| `devenv-php` | devShells, packages | stable + master | - |
| `devenv-protobuf` | devShells | stable | - |
| `devenv-python` | devShells | stable + master | - |
| `devenv-qmk` | devShells, packages | stable | - |
| `devenv-ruby` | devShells | stable | - |
| `devenv-rust` | devShells | stable + master | rust-overlay |
| `devenv-rust_toolchain` | devShells | stable + master | rust-overlay |
| `devenv-scala` | devShells | stable | - |
| `devenv-shell` | devShells | stable | - |
| `devenv-zig` | devShells | stable | - |

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
| `devenv-digital_ocean` | `config.allowUnfree = true` | docker is unfree |
| `devenv-elixir` | Uses `apple_sdk_11_0` | Migrated from deprecated `apple_sdk` |

---

# Non-Devenv Packages

All other flake.nix files outside of `pkgs/alfa/devenv-*/`.

## Package Categories

### pkgs/alfa (Non-devenv)
System and utility packages:
- `system-common`, `system-darwin`, `system-linux` - Platform package aggregations
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

### Two-Channel Pattern (Most Common)
```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/<unstable-commit>";
  nixpkgs-stable.url = "github:NixOS/nixpkgs/<stable-commit>";
  utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
};
```

Used by majority of non-devenv packages including:
- Root `flake.nix`
- All `pkgs/bravo/*` packages
- All `pkgs/alfa/system-*` packages
- `repos/ssh-agent-mux`, `repos/zmx`

### Common Additional Inputs

| Input | Source | Used By |
|-------|--------|---------|
| `devenv-go` | `github:friedenberg/eng?dir=pkgs/alfa/devenv-go` | Go projects |
| `devenv-rust` | `github:friedenberg/eng?dir=pkgs/alfa/devenv-rust` | Rust projects |
| `devenv-nix` | `github:friedenberg/eng?dir=pkgs/alfa/devenv-nix` | Nix projects |
| `rust-overlay` | `github:oxalica/rust-overlay` | Rust projects |
| `gomod2nix` | `github:nix-community/gomod2nix` | Go projects |
| `nix-darwin` | `github:LnL7/nix-darwin` | macOS system config |
| `uv2nix` | pyproject ecosystem | Python projects |

---

# Recommended Patterns

## Devenv Pattern (Stable-First)

For development environment packages:

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
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.runtime-package        # stable (runtimes)
            pkgs-master.lsp-server      # master (tooling)
          ];
        };
      }
    );
}
```

## Non-Devenv Pattern (Unstable-First)

For applications and system packages:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/<unstable-commit>";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/<stable-commit>";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgs-stable = import nixpkgs-stable { inherit system; };
      in {
        packages.default = pkgs.buildApplication { ... };
      }
    );
}
```

---

# Future Direction

## Completed Goals

1. **Unified System Pattern** - All packages use `eachDefaultSystem`
2. **Consistent Formatting** - All flakes formatted with `nixfmt`
3. **Runtime vs Tooling Split** (devenv) - Runtimes from stable, tooling from master

## Remaining Goals

1. **Unify Naming Convention** - Resolve the `nixpkgs`/`nixpkgs-master` vs `nixpkgs`/`nixpkgs-stable` inconsistency
2. **Unify Overlay Patterns** - Standardize overlay patterns for JVM-based languages
3. **Document All Packages** - Complete reference tables for non-devenv packages

---

*Last updated: 2026-02-07*
