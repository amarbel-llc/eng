# pkgs/alfa

Nix flake packages organized into two categories.

## Formatting

All flake.nix files are formatted using `nixfmt` via `devenv-nix`:

```sh
# Format all devenv flakes
nix run ./pkgs/alfa/devenv-nix#fmt -- pkgs/alfa/devenv-*/flake.nix

# Format a single flake
nix run ./pkgs/alfa/devenv-nix#fmt -- pkgs/alfa/devenv-go/flake.nix
```

## devenv-* (Development Environments)

Language-specific and tool-specific development environments. Each provides a `devShells.default` for use with `nix develop`.

Examples: `devenv-python`, `devenv-rust`, `devenv-go`, `devenv-js`

See [docs/nix-patterns.md](../../docs/nix-patterns.md) for pattern documentation.

## system-* (System Packages)

Platform-wide package aggregations installed at the system level. These differ from devenv packages:

- **Purpose**: System-wide tooling rather than project-specific environments
- **Outputs**: Focus on `packages.default` via `symlinkJoin` for installation
- **Platform-specific**: `system-darwin` and `system-linux` target specific platforms
- **Scale**: `system-common` aggregates 70+ packages

| Package | Description |
|---------|-------------|
| `system-common` | Cross-platform CLI tools and utilities |
| `system-darwin` | macOS-specific packages (nix-darwin, pinentry_mac, casks) |
| `system-linux` | Linux-specific packages (keyd, mako, rofi, wayland tools) |

See [docs/system-patterns.md](../../docs/system-patterns.md) for pattern documentation.
