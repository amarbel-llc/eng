# pkgs/alfa

Nix flake packages organized into two categories.

## Formatting

All flake.nix files are formatted using `nixfmt` via the formatter defined in `devenv-nix`:

```sh
nix fmt pkgs/alfa/devenv-nix
```

To format all devenv flakes:

```sh
for f in pkgs/alfa/devenv-*/flake.nix; do
  nix fmt --inputs-from pkgs/alfa/devenv-nix "$(dirname "$f")"
done
```

## devenv-* (Development Environments)

Language-specific and tool-specific development environments. Each provides a `devShells.default` for use with `nix develop`.

Examples: `devenv-python`, `devenv-rust`, `devenv-go`, `devenv-js`

See [docs/devenv-patterns.md](../../docs/devenv-patterns.md) for pattern documentation.

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
