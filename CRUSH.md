# CRUSH.md - Monorepo Development Guide

## Build & Test Commands

- **Build all**: `just build` (builds Nix packages + rcm configs)
- **Build Nix only**: `just build-nix` or `nix build`
- **Update all flakes**: `just update` (updates all 62+ flakes recursively)
- **Update nixpkgs refs**: `just update-nixpkgs` (updates SHA files)
- **Clean**: `just clean` (runs `nix-store --gc`)

### Subproject Commands

Each subproject has its own `justfile` or build system. Common patterns:
- **Go projects**: `just build`, `just test`, `go test -v ./path/to/package` (single test)
- **Rust projects**: `cargo build`, `cargo test`, `cargo test <test_name>` (single test)
- **Python projects**: Check `pyproject.toml` for test commands
- **Nix projects**: `nix build`, `nix develop`

## Repository Structure

- **`pkgs/alfa/`**: Core utilities (devenv flakes, ssh-agent-mux, pa6e, etc.)
- **`pkgs/bravo/`**: Main projects (dodder, chrest, fat_ass, sweatshop, resume-builder)
- **`pkgs/dev-flake-templates/`**: Nix flake templates for various languages
- **`rcm/`**: Dotfiles managed by rcup (vim, tmux, fish, ssh configs)
- **`playgrounds/`**: Experimental code and prototypes
- **`go/`**: Shared Go module cache

## Code Style Guidelines

### Nix Files
- Format with `nixfmt-rfc-style` before committing
- Use `let...in` for local bindings
- Prefer `pkgs.` prefix for package references
- Flakes use NATO phonetic ordering in `pkgs/alfa/` and `pkgs/bravo/`

### Shell Scripts
- Use `set -euo pipefail` at the top
- Indent with 2 spaces
- Use `[[ ]]` for conditionals, not `[ ]`
- Quote all variables: `"$var"` not `$var`

### Go Projects
- Import order: `std` first, then external crates, then internal modules
- Use `goimports` and `gofumpt` for formatting
- Follow NATO phonetic module organization (alfa → bravo → charlie → etc.)
- Never dereference `sku.Transacted` pointers in dodder - use `ResetWith` pattern

### Rust Projects
- Format: `cargo fmt`, Lint: `cargo clippy`
- Indent: 4 spaces (enforced by .editorconfig)
- Use `Result<T, E>` for error handling
- Import grouping: `std`, external crates, internal modules

## Development Workflow

1. Enter dev shell: `nix develop` or rely on direnv (`.envrc` auto-loads)
2. Make changes in subproject directories
3. Run subproject-specific tests/builds
4. Format code before committing (Nix: `nixfmt-rfc-style`, Shell: `shfmt -s -i=2 -w`)
5. Commit changes (do NOT commit unless explicitly asked)

## Important Notes

- This is a Nix-based monorepo with 62+ flakes
- Each flake in `pkgs/` is independently buildable
- Top-level `flake.nix` aggregates all subproject packages
- Use `just` for task automation (justfiles throughout)
- Dotfiles are managed via `rcup` (see `rcm/` directory)
