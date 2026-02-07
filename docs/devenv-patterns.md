# Devenv Patterns Documentation

A living document tracking the current state of flake.nix patterns across devenv packages, serving as a reference for consolidation and improvement efforts.

**Note**: System packages (`system-common`, `system-darwin`, `system-linux`) are documented separately in [system-patterns.md](system-patterns.md).

## Overview

### Purpose
This document captures the existing architectural patterns used across the devenv ecosystem in `pkgs/alfa/`. It serves as:
- A reference for understanding current implementations
- A baseline for tracking improvements
- A guide for maintaining consistency across packages

### Goals
1. **Consolidation** - Reduce pattern variation where possible
2. **Stable-first** - Default to stable nixpkgs, override to master when necessary
3. **Consistency** - Align similar packages on common patterns

## Outputs Structure

### Current Patterns

#### devShells Only (23 packages - 79%)
The minimal pattern, providing only a development shell:
```nix
devShells.${system}.default = pkgs.mkShell {
  packages = [ ... ];
};
```
Used by: `devenv-bats`, `devenv-elixir`, `devenv-haskell`, `devenv-haxe`, `devenv-js`, `devenv-kotlin`, `devenv-latex`, `devenv-lua`, `devenv-ocaml`, `devenv-protobuf`, `devenv-python`, `devenv-ruby`, `devenv-rust`, `devenv-rust_toolchain`, `devenv-scala`, `devenv-shell`, `devenv-zig`, and others

#### packages + devShells (3 packages - 12%)
Exports both installable packages and development shell:
```nix
packages.${system}.default = pkgs.symlinkJoin { ... };
devShells.${system}.default = pkgs.mkShell { ... };
```
Used by: `devenv-php`, `devenv-nix`, `devenv-go`

#### symlinkJoin Aggregation
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

#### overlays Export (5 packages - 19%)
Exports overlays for nixpkgs customization:
```nix
overlays = [(final: prev: {
  jdk = prev.jdk20;
  sbt = prev.sbt.override { jre = jdk; };
})];
```
Used by: `devenv-node`, `devenv-scala`, `devenv-kotlin`, `devenv-rust_toolchain`, `devenv-go`

## Architecture Specification

### Two System Support Patterns

#### 1. utils.lib.eachDefaultSystem (15 packages - 58%)
Implicit system detection via flake-utils:
```nix
outputs = { self, nixpkgs, utils, ... }:
  utils.lib.eachDefaultSystem (system:
    let pkgs = import nixpkgs { inherit system; };
    in { devShells.default = pkgs.mkShell { ... }; }
  );
```
Used by: `devenv-bats`, `devenv-digital_ocean`, `devenv-direnv`, `devenv-go`, `devenv-java`, `devenv-js`, `devenv-lua`, `devenv-nix`, `devenv-pandoc`, `devenv-php`, `devenv-python`, `devenv-qmk`, `devenv-ruby`, `devenv-rust`, `devenv-shell`

#### 2. nixpkgs.lib.genAttrs with Explicit List (11 packages - 42%)
Manual system enumeration:
```nix
let
  supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f { ... });
in {
  devShells = forEachSupportedSystem ({ pkgs }: { default = pkgs.mkShell { ... }; });
}
```
Used by: `devenv-elixir`, `devenv-haskell`, `devenv-haxe`, `devenv-kotlin`, `devenv-latex`, `devenv-node`, `devenv-ocaml`, `devenv-protobuf`, `devenv-rust_toolchain`, `devenv-scala`, `devenv-zig`

## Stable vs Master Strategy

### Naming Convention

All packages follow the **stable-first** naming convention:
- `nixpkgs` - Points to stable commit (the default)
- `nixpkgs-master` - Points to master/unstable commit (available for override)

This ensures stable is the default while master remains easily accessible for packages that need bleeding-edge versions.

### Common Input Commits

All packages share common input commits:
- **Stable** (`nixpkgs`): `github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211`
- **Master** (`nixpkgs-master`): `github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634`
- **flake-utils**: `https://flakehub.com/f/numtide/flake-utils/0.1.102`

### Nixpkgs Usage Patterns

#### Stable Only (19 packages - 73%)
Uses only stable nixpkgs (the default):
```nix
let pkgs = import nixpkgs { inherit system; };
```
Used by: `devenv-bats`, `devenv-digital_ocean`, `devenv-direnv`, `devenv-elixir`, `devenv-haskell`, `devenv-haxe`, `devenv-java`, `devenv-js`, `devenv-kotlin`, `devenv-latex`, `devenv-lua`, `devenv-nix`, `devenv-node`, `devenv-ocaml`, `devenv-pandoc`, `devenv-protobuf`, `devenv-qmk`, `devenv-ruby`, `devenv-scala`, `devenv-shell`, `devenv-zig`

#### Mixed Stable/Master (7 packages - 27%)
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


## Package Reference Table

| Package | System Pattern | Outputs | Nixpkgs Strategy | Special Inputs |
|---------|---------------|---------|------------------|----------------|
| `devenv-bats` | eachDefaultSystem | devShells | stable | - |
| `devenv-digital_ocean` | eachDefaultSystem | devShells, packages | stable | - |
| `devenv-direnv` | eachDefaultSystem | devShells, packages | stable | - |
| `devenv-elixir` | genAttrs | devShells | stable | - |
| `devenv-go` | eachDefaultSystem | devShells, packages, overlays | stable + master | gomod2nix |
| `devenv-haskell` | genAttrs | devShells | stable | - |
| `devenv-haxe` | genAttrs | devShells | stable | - |
| `devenv-java` | eachDefaultSystem | devShells, packages | stable | - |
| `devenv-js` | eachDefaultSystem | devShells | stable | - |
| `devenv-kotlin` | genAttrs | devShells, overlays | stable | - |
| `devenv-latex` | eachDefaultSystem | devShells | stable | - |
| `devenv-lua` | eachDefaultSystem | devShells | stable | - |
| `devenv-nix` | eachDefaultSystem | devShells, packages | stable | fh |
| `devenv-node` | eachDefaultSystem | devShells | stable | - |
| `devenv-ocaml` | genAttrs | devShells | stable | - |
| `devenv-pandoc` | eachDefaultSystem | devShells | stable | devenv-lua |
| `devenv-php` | eachDefaultSystem | devShells, packages | stable + master | - |
| `devenv-protobuf` | genAttrs | devShells | stable | - |
| `devenv-python` | eachDefaultSystem | devShells | stable + master | - |
| `devenv-qmk` | eachDefaultSystem | devShells, packages | stable | - |
| `devenv-ruby` | eachDefaultSystem | devShells | stable | - |
| `devenv-rust` | eachDefaultSystem | devShells | stable + master | rust-overlay |
| `devenv-rust_toolchain` | genAttrs | devShells, overlays | stable + master | rust-overlay |
| `devenv-scala` | genAttrs | devShells, overlays | stable | - |
| `devenv-shell` | eachDefaultSystem | devShells | stable | - |
| `devenv-zig` | genAttrs | devShells | stable | - |

## Summary Statistics

| Metric | Count | Percentage |
|--------|-------|------------|
| Total devenv packages | 26 | 100% |
| Using eachDefaultSystem | 17 | 65% |
| Using genAttrs | 9 | 35% |
| With packages output | 6 | 23% |
| With overlays export | 4 | 15% |
| Stable-only nixpkgs | 21 | 81% |
| Mixed stable/master | 5 | 19% |

## Known Issues

Some packages have pre-existing issues unrelated to the stable-first pattern:

### devenv-digital_ocean
**Issue**: Requires `allowUnfree = true` for the `docker` package.
**Workaround**: Add to your nix configuration:
```nix
nixpkgs.config.allowUnfree = true;
```

### devenv-elixir
**Issue**: Uses deprecated `darwin.apple_sdk` which has been removed.
**Status**: Needs migration to `darwin.apple_sdk_11_0` per [nixpkgs migration guide](https://nixos.org/manual/nixpkgs/stable/#sec-darwin-legacy-frameworks).

### devenv-haxe
**Issue**: Depends on `mbedtls-2.28.10` which is marked as insecure.
**Workaround**: Add to your nix configuration:
```nix
nixpkgs.config.permittedInsecurePackages = [ "mbedtls-2.28.10" ];
```

## Future Direction

### Goals for Improvement

1. **Default to Stable**
   - New packages should use `nixpkgs-stable` as primary source
   - Only use unstable for packages not available or broken in stable
   - Reduces build churn and improves reproducibility

2. **Easy Override Mechanism**
   - Establish a consistent pattern for switching between stable/master
   - Consider a helper function or common module for this purpose

3. **Consolidate Similar Strategies**
   - Align system support patterns (prefer `eachDefaultSystem` where possible)
   - Standardize outputs structure for similar package types
   - Unify overlay patterns for JVM-based languages

4. **Increase Consistency**
   - Adopt common naming conventions
   - Standardize package composition approaches
   - Document and enforce patterns via templates

### Recommended Standard Pattern

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/<stable-commit>";        # stable (default)
    nixpkgs-master.url = "github:NixOS/nixpkgs/<master-commit>"; # master (override)
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1";
  };

  outputs = { self, nixpkgs, nixpkgs-master, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };              # stable by default
        pkgs-master = import nixpkgs-master { inherit system; }; # available for override
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # stable packages (runtimes, core tools)
          ] ++ (with pkgs-master; [
            # master packages (LSPs, linters, formatters)
          ]);
        };
      }
    );
}
```

### Example: Mixed Stable/Master (Go)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    nixpkgs-master.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs = { self, nixpkgs, nixpkgs-master, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgs-master = import nixpkgs-master { inherit system; };
      in {
        devShells.default = pkgs-master.mkShell {
          packages = [
            pkgs.go                    # runtime from stable
            pkgs-master.gopls          # LSP from master
            pkgs-master.golangci-lint  # linter from master
          ];
        };
      }
    );
}
```

---

*Last updated: 2026-02-07*
