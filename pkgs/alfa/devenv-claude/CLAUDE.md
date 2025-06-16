# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a sandboxed Claude Code implementation using Nix flakes and bubblewrap for secure filesystem isolation. The project consists of:

1. **Configuration Proposal** (`claude-sandboxed-config-proposal.md`): Detailed specification for TOML-based filesystem access configuration
2. **Nix Implementation** (`flake.nix`): Builds `claude-sandboxed` wrapper using bubblewrap for isolation
3. **Sandboxing Architecture**: Uses bubblewrap to create isolated environments with controlled filesystem access

## Development Commands

### Build and Run
```bash
# Build the sandboxed claude-code
nix build

# Run the sandboxed version
nix run

# Enter development shell
nix develop

# Run directly with arguments
./result/bin/claude-sandboxed [args]
```

### Available Tools
- `ripgrep`: Fast text search (available in dev shell)
- `bubblewrap`: Sandboxing tool for creating isolated environments
- `claude-sandboxed`: Main sandboxed claude-code wrapper

### Code Formatting
Before committing changes, ensure code is properly formatted:

```bash
# Format Nix files
nixfmt-rfc-style flake.nix

# Check and format shell scripts
shellcheck *.sh
shfmt -w *.sh
```

**Requirements:**
- All `flake.nix` changes must be formatted with `nixfmt-rfc-style`
- All shell scripts must pass `shellcheck` validation
- All shell scripts must be formatted with `shfmt`

## AI Code Contributions

After making changes and running tests and ensuring they all pass, commit all
the changes and set the commit message to a summary of the prompt and what was
done to address it.

## Architecture

### Sandboxing Implementation
The `claude-sandboxed` script in `flake.nix:17-49` implements security isolation:
- **Read-only root filesystem**: `--ro-bind / /`
- **Working directory mount**: `--bind "$CURRENT_DIR" /mnt`
- **Isolated home directories**: `--tmpfs /home` and `--tmpfs /root`
- **Essential device access**: Limited `/dev` bindings for null, zero, random, urandom, tty
- **Network sharing**: `--share-net` for internet access
- **Process isolation**: `--unshare-all` with specific exceptions

### Configuration System
The proposal in `claude-sandboxed-config-proposal.md` defines a comprehensive TOML-based configuration format with:
- **Path mounting**: Maps virtual paths to host filesystem locations
- **Access control**: Fine-grained read/write/execute permissions
- **Security constraints**: Path traversal protection, resource limits
- **Multi-environment support**: Development, analysis, and restricted sandbox configurations

### Key Security Features
- Path canonicalization prevents directory traversal
- Configurable symlink handling
- Resource limits (file size, disk usage, operation rate)
- Explicit path denial patterns
- Mount-point permission validation
