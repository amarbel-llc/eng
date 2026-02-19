# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Git aliases implemented as standalone bash scripts with a `.git-alias` extension. The filename minus the extension becomes the git alias name (e.g., `status.git-alias` → `git status`). The `config-aliases.rcm-script` dynamically discovers all `*.git-alias` symlinks in `~/.config/git/aliases/` and generates a `[alias]` gitconfig section with `! /path/to/script` entries.

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

Aliases with multiple logical steps use the bash library from tap-dancer (`amarbel-llc/tap-dancer`) for structured TAP version 14 output. Currently used by: `cob`, `cobu`, `merge-and-cleanup`.

```bash
# shellcheck disable=1091
TAP_DANCER_LIB="$(dirname "$(readlink -f "$0")")/result/share/tap-dancer/lib"
source "${TAP_DANCER_LIB}/load.bash"

tap_plan <N>
tap_run "description" command arg1 arg2
tap_skip "description" "reason"
```

The `result` symlink is produced by `nix build` of the local `flake.nix` (which pulls in `tap-dancer-bash`). The build runs automatically during `rcup` via `config-aliases.rcm-script`. Scripts resolve their real path via `readlink -f` to find the `result` symlink in the source directory.

`tap_run` automatically emits `ok`/`not ok` based on exit code and bails out on failure by default. Use `tap_run --no-bail` to continue after failure.

Single-command aliases (the majority) do not use tap-dancer.

## Adding a New Alias

1. Create a new file in this directory with a `.git-alias` extension following the script conventions above
2. The filename (minus `.git-alias`) becomes the alias name — use descriptive hyphenated names (not abbreviations)
3. `rcup` will symlink it; `config-aliases.rcm-script` will pick it up automatically
