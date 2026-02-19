# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Git aliases implemented as standalone bash scripts. Each file is an executable script whose filename becomes the git alias name (e.g., `status` → `git status`). The `config-aliases.rcm-script` dynamically discovers all scripts via symlinks in `~/.config/git/aliases/` and generates a `[alias]` gitconfig section with `! /path/to/script` entries.

## Script Conventions

Every alias script follows this pattern:

```bash
#! /usr/bin/env -S bash -e
# @file <filename>
# @brief <one-line description>

git <command> "$@"
```

- Shebang uses `-S bash -e` for fail-fast
- `@file` must match the filename exactly
- `@brief` is a lowercase sentence fragment (no period)
- Format with `shfmt -s -i=2`

## TAP-14 Output (Multi-Step Aliases)

Aliases with multiple logical steps use the `tap-writer` library from batman (`amarbel-llc/batman`) for structured TAP version 14 output. Currently used by: `checkout-branch`, `checkout-branch-upstream`, `merge-and-cleanup`.

```bash
# shellcheck disable=1091
source "${BATS_LIB_PATH}/tap-writer/load.bash"

tap_plan <N>
tap_run "description" command arg1 arg2
tap_skip "description" "reason"
```

`tap_run` automatically emits `ok`/`not ok` based on exit code and bails out on failure by default. Use `tap_run --no-bail` to continue after failure.

Single-command aliases (the majority) do not use tap-writer.

## Adding a New Alias

1. Create a new file in this directory following the script conventions above
2. The filename becomes the alias name — use descriptive hyphenated names (not abbreviations)
3. `rcup` will symlink it; `config-aliases.rcm-script` will pick it up automatically
