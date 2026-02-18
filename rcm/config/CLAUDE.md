# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the `rcm/config` directory within the `eng` monorepo — dotfiles managed by `rcup` that get symlinked into `~/.config/`. It contains configuration for git, fish shell, neovim, vim, kitty, gnupg, direnv, just, and thefuck.

Files here are deployed via `rcup` (run from the top-level `just build-rcm`). After editing, `rcup` must be run to update symlinks.

## Structure

- `git/` — Modular git config: `config-user` includes `config-common` and `config-aliases`. Aliases are standalone bash scripts in `git/aliases/` (see `git/aliases/CLAUDE.md` for alias-specific guidance). `config-aliases.rcm-script` auto-generates the `[alias]` section from symlinked scripts at deploy time.
- `fish/` — Fish shell config. `config.fish` auto-sources all `*-config.fish` files. Functions live in `functions/`, completions in `completions/`.
- `nvim/` — Neovim config using lazy.nvim. LSP configs in `lsp/`, plugins in `lua/plugins/`. `after/plugin/init.lua` auto-enables all LSPs found in the `lsp/` directory.
- `just/justfile` — User-level just recipes (GPG reset, timg preview, git-add-and-commit).
- `direnv/direnv.toml.j2` — Jinja2 template; whitelists `$HOME/eng` prefix.
- `gnupg/` — GPG config with SSH-based signing via YubiKey. `gpg-agent.conf.j2` is templated.

## Conventions

- Shell scripts: `set -e` via shebang (`#!/usr/bin/env -S bash -e`), format with `shfmt -s -i=2`
- Git alias scripts: follow `@file`/`@brief` header convention, use descriptive hyphenated names (not abbreviations)
- Multi-step git aliases use `tap-writer` from batman for TAP-14 structured output
- Fish config files use `*-config.fish` suffix to be auto-sourced
- Templated configs use `.j2` extension (Jinja2) and may have companion `.json-script` files
- `.secret` suffix for files containing sensitive data (e.g., `config-user.secret`)
- GPG signing is required for commits; if signing fails, ask user to unlock their agent
