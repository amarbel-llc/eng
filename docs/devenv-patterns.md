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

### Current Approaches

All packages share common input commits:
- **Unstable/Master**: `github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634`
- **Stable**: `github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211`
- **flake-utils**: `https://flakehub.com/f/numtide/flake-utils/0.1.102`

#### Master Only (15 packages - 52%)
Uses only unstable nixpkgs:
```nix
let pkgs = import nixpkgs { inherit system; };
```
Used by: `devenv-bats`, `devenv-digital_ocean`, `devenv-haskell`, `devenv-haxe`, `devenv-java`, `devenv-js`, `devenv-kotlin`, `devenv-latex`, `devenv-lua`, `devenv-ocaml`, `devenv-pandoc`, `devenv-protobuf`, `devenv-qmk`, `devenv-ruby`, `devenv-scala`, `devenv-shell`, `devenv-zig`

#### Stable-First (2 packages - 7%)
Uses only stable nixpkgs:
```nix
let pkgs = import nixpkgs-stable { inherit system; };
```
Used by: `devenv-direnv`, `devenv-nix`

#### Master-First with Selective Stable (10 packages - 34%)
Primary unstable with specific packages from stable:
```nix
let
  pkgs = import nixpkgs { inherit system; };
  pkgs-stable = import nixpkgs-stable { inherit system; };
in {
  packages = {
    inherit (pkgs) tool1 tool2;
    inherit (pkgs-stable) specific-stable-tool;
  };
}
```
Used by: `devenv-elixir`, `devenv-go`, `devenv-node`, `devenv-php`, `devenv-python`, `devenv-rust`, `devenv-rust_toolchain`


## Package Reference Table

| Package | System Pattern | Outputs | Nixpkgs Strategy | Special Inputs |
|---------|---------------|---------|------------------|----------------|
| `devenv-bats` | eachDefaultSystem | devShells | master | - |
| `devenv-digital_ocean` | eachDefaultSystem | devShells, packages | master | - |
| `devenv-direnv` | eachDefaultSystem | devShells, packages | stable-only | - |
| `devenv-elixir` | genAttrs | devShells | master + stable | - |
| `devenv-go` | eachDefaultSystem | devShells, packages, overlays | master + stable | gomod2nix |
| `devenv-haskell` | genAttrs | devShells | master | - |
| `devenv-haxe` | genAttrs | devShells | master | - |
| `devenv-java` | eachDefaultSystem | devShells, packages | master | - |
| `devenv-js` | eachDefaultSystem | devShells | master | - |
| `devenv-kotlin` | genAttrs | devShells, overlays | master | - |
| `devenv-latex` | genAttrs | devShells | master | - |
| `devenv-lua` | eachDefaultSystem | devShells | master | - |
| `devenv-nix` | eachDefaultSystem | devShells, packages | stable-only | fh |
| `devenv-node` | genAttrs | devShells, overlays | master + stable | - |
| `devenv-ocaml` | genAttrs | devShells | master | - |
| `devenv-pandoc` | eachDefaultSystem | devShells | master | devenv-lua |
| `devenv-php` | eachDefaultSystem | devShells, packages | master + stable | - |
| `devenv-protobuf` | genAttrs | devShells | master | - |
| `devenv-python` | eachDefaultSystem | devShells | master + stable | - |
| `devenv-qmk` | eachDefaultSystem | devShells, packages | master | - |
| `devenv-ruby` | eachDefaultSystem | devShells | master | - |
| `devenv-rust` | eachDefaultSystem | devShells | master + stable | rust-overlay |
| `devenv-rust_toolchain` | genAttrs | devShells, overlays | master + stable | rust-overlay |
| `devenv-scala` | genAttrs | devShells, overlays | master | - |
| `devenv-shell` | eachDefaultSystem | devShells | master | - |
| `devenv-zig` | genAttrs | devShells | master | - |

## Summary Statistics

| Metric | Count | Percentage |
|--------|-------|------------|
| Total devenv packages | 26 | 100% |
| Using eachDefaultSystem | 15 | 58% |
| Using genAttrs | 11 | 42% |
| With packages output | 3 | 12% |
| With overlays export | 5 | 19% |
| Master-only nixpkgs | 15 | 58% |
| Stable-only nixpkgs | 2 | 8% |
| Mixed stable/master | 9 | 35% |

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
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1";
  };

  outputs = { self, nixpkgs-stable, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs-stable { inherit system; };
        pkgs-unstable = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # stable packages here
          ] ++ (with pkgs-unstable; [
            # unstable-only packages here
          ]);
        };
      }
    );
}
```

---

*Last updated: 2026-02-07*
