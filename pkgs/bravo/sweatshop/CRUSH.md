# CRUSH.md - Sweatshop Development Guide

## Build & Run Commands
```bash
nix build                    # Build sweatshop package
nix run                      # Run sweatshop directly
nix develop                  # Enter dev shell with tools
./result/bin/sweatshop       # Run built binary
```

## Sweatshop Commands
```bash
sweatshop run                # Create and attach to new sweatshop
sweatshop run-temp           # Create temp sweatshop (auto-destroy on exit)
sweatshop attach ID          # Attach to existing sweatshop
sweatshop list               # List all sweatshops
sweatshop diff [ID]          # Show changes in sweatshop
sweatshop pull [ID]          # Pull changes to main branch
sweatshop destroy ID         # Destroy sweatshop
sweatshop destroy -a         # Destroy all sweatshops
```

## Lint & Format Commands
```bash
nixfmt-rfc-style flake.nix   # Format Nix files (REQUIRED before commit)
shellcheck *.sh              # Lint shell scripts (REQUIRED before commit)
shfmt -s -i=2 -w *.sh        # Format shell scripts (REQUIRED before commit)
```

## Code Style Guidelines

### Shell Scripts
- Use `set -euo pipefail` at the top of all scripts
- Indent with 2 spaces (enforced by shfmt -i=2)
- Use `[[ ]]` for conditionals, not `[ ]`
- Quote all variables: `"$var"` not `$var`
- Use `local` for function variables
- Disable shellcheck warnings with inline comments when necessary
- Use `$GUM` variable for gum commands (substituted by Nix build)

### Nix Files
- Format with `nixfmt-rfc-style` (RFC 166 style)
- Use `let...in` for local bindings
- Prefer `pkgs.` prefix for package references
- Use `inherit` for passing through attributes
- Add tool paths to buildInputs and substitute placeholders in installPhase

### UI/UX
- Use `gum` (Charm) for interactive prompts and styled output
- `gum confirm` for yes/no prompts
- `gum style` for colored/formatted messages
- `gum spin` for long-running operations

### Commit Policy
**CRITICAL**: Always commit changes after completing tasks. Run lint/format commands before committing.

### Security Considerations
- All filesystem access is sandboxed via bubblewrap
- Root filesystem is read-only (`--ro-bind / /`)
- Working directory mounted at `/mnt` with write access
- Home directories isolated with tmpfs
- Git hidden from agent (`GIT_DIR=/dev/null`)
