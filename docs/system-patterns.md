# System Packages Patterns Documentation

A living document tracking the patterns used in system-* packages for platform-wide package aggregation.

## Overview

### Purpose
System packages (`system-*`) provide platform-wide package collections installed at the system level. Unlike devenv packages which create project-specific development environments, system packages aggregate tools and utilities for the entire system.

### Key Differences from devenv-*

| Aspect | devenv-* | system-* |
|--------|----------|----------|
| Purpose | Project-specific development | System-wide tooling |
| Primary Output | `devShells.default` | `packages.default` |
| Scale | 5-20 packages typically | 10-70+ packages |
| Platform Targeting | Usually cross-platform | Often platform-specific |
| Composition | `mkShell` | `symlinkJoin` |

## Package Reference

### system-common

Cross-platform CLI tools and utilities shared across all systems.

**Pattern**: `utils.lib.eachDefaultSystem`
**Nixpkgs Strategy**: Mixed (master + stable)
**Special Inputs**: `dodder`
**Package Count**: ~70 packages

Key characteristics:
- Uses `symlinkJoin` with `failOnMissing = true` for strict aggregation
- Exports both `packages.default` and `devShells.default`
- Selective use of `pkgs-stable` for specific packages (csvkit, gftp)
- Custom overlays (gnupg with PCSC support)

```nix
packages.default = pkgs.symlinkJoin {
  failOnMissing = true;
  name = "system-packages";
  paths = builtins.attrValues packages;
};
```

### system-darwin

macOS-specific packages and integrations.

**Pattern**: `utils.lib.eachSystem ["x86_64-darwin" "aarch64-darwin"]`
**Nixpkgs Strategy**: Master with overlays
**Special Inputs**: `nix-darwin`, `brew-api`, `brew`
**Package Count**: ~4 packages + casks

Key characteristics:
- Uses `brew-nix` overlay for Homebrew cask integration
- Includes `nix-darwin` for system configuration
- Platform-restricted to Darwin systems only
- Integrates native macOS tools (pinentry_mac, reattach-to-user-namespace)

```nix
pkgs = import nixpkgs {
  inherit system;
  overlays = [ brew.overlays.default ];
};

casks = with pkgs.brewCasks; [ kitty ];
```

### system-linux

Linux-specific packages for desktop/wayland environments.

**Pattern**: `utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"]`
**Nixpkgs Strategy**: Mixed (master + stable available)
**Special Inputs**: None
**Package Count**: ~7 packages

Key characteristics:
- Platform-restricted to Linux systems only
- Focus on desktop environment packages (wayland, keyd, rofi)
- Exports only `packages.default` (no devShell)
- Includes input method and notification tools

```nix
packages.default = pkgs.symlinkJoin {
  name = "system-packages";
  paths = [
    espanso-wayland
    keyd
    mako
    pcsclite
    pinentry-gnome3
    rofi
    wlogout
  ];
};
```

## Architecture Patterns

### Platform-Specific Targeting

System packages use `utils.lib.eachSystem` with explicit platform lists:

```nix
# Darwin only
utils.lib.eachSystem ["x86_64-darwin" "aarch64-darwin"] (system: ...)

# Linux only
utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system: ...)

# Cross-platform
utils.lib.eachDefaultSystem (system: ...)
```

### Package Aggregation

All system packages use `symlinkJoin` for aggregation:

```nix
packages.default = pkgs.symlinkJoin {
  name = "system-packages";
  paths = [ ... ];
  # Optional: strict mode
  failOnMissing = true;
};
```

### External Integrations

| Package | Integration | Purpose |
|---------|-------------|---------|
| system-common | dodder | Custom tooling |
| system-darwin | nix-darwin | macOS system configuration |
| system-darwin | brew-nix | Homebrew cask packages |

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total system packages | 3 |
| Using eachDefaultSystem | 1 |
| Using eachSystem (platform-specific) | 2 |
| With packages output | 3 |
| With devShells output | 1 |
| With overlays | 1 |

## Common Inputs

All system packages share:
- **Unstable/Master**: `github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634`
- **Stable**: `github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211`
- **flake-utils**: `https://flakehub.com/f/numtide/flake-utils/0.1.102`

---

*Last updated: 2026-02-07*
