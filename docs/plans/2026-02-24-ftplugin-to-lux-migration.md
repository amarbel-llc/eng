# Ftplugin-to-Lux Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move formatter configuration from vim ftplugin files into lux, delete the stale ftplugin flake, and strip vim configs to editor-only settings.

**Architecture:** Lux already serves as the LSP multiplexer for neovim. Its formatter routing (chain/fallback modes with `flake =` references) replaces the ftplugin flake's `./result/bin/` approach entirely. Vim ftplugins retain only settings lux cannot handle (tab width, comments, textwidth, makeprg, errorformat).

**Tech Stack:** Lux (LSP multiplexer), Nix (formatter installation via flake refs), neovim (editor), rcm (dotfile management)

**Design doc:** `docs/plans/2026-02-24-ftplugin-to-lux-migration-design.md`

---

### Task 1: Create lux formatters.toml

**Files:**
- Create: `rcm/config/lux/formatters.toml`

**Step 1: Create the formatter config**

```toml
[[formatter]]
name = "golines"
flake = "nixpkgs#golines"
args = ["--max-len=80", "--no-chain-split-dots", "--shorten-comments", "--write-output"]
mode = "stdin"

[[formatter]]
name = "gofumpt"
flake = "nixpkgs#gofumpt"
mode = "stdin"

[[formatter]]
name = "shfmt"
flake = "nixpkgs#shfmt"
args = ["-s", "-i=2"]
mode = "stdin"

[[formatter]]
name = "prettier"
flake = "nixpkgs#prettier"
args = ["--stdin-filepath", "{file}"]
mode = "stdin"

[[formatter]]
name = "jq"
flake = "nixpkgs#jq"
args = ["."]
mode = "stdin"

[[formatter]]
name = "pandoc"
flake = "nixpkgs#pandoc"
args = ["--columns=80", "-f", "markdown", "-t", "markdown"]
mode = "stdin"
```

**Step 2: Commit**

```bash
git add rcm/config/lux/formatters.toml
git commit -m "add lux formatters.toml with golines, gofumpt, shfmt, prettier, jq, pandoc"
```

---

### Task 2: Update lux filetype configs with formatter references

**Files:**
- Modify: `rcm/config/lux/filetype/go.toml`
- Modify: `rcm/config/lux/filetype/bash.toml`
- Modify: `rcm/config/lux/filetype/typescript.toml`
- Create: `rcm/config/lux/filetype/json.toml`
- Create: `rcm/config/lux/filetype/markdown.toml`

**Step 1: Update go.toml**

```toml
extensions = ["go"]
language_ids = ["go"]
lsp = "gopls"
formatters = ["golines", "gofumpt"]
formatter_mode = "chain"
lsp_format = "never"
```

**Step 2: Update bash.toml**

```toml
extensions = ["sh", "bash"]
language_ids = ["bash", "sh"]
lsp = "bash-language-server"
formatters = ["shfmt"]
formatter_mode = "chain"
lsp_format = "never"
```

**Step 3: Update typescript.toml**

```toml
extensions = ["ts", "tsx", "js", "jsx"]
language_ids = ["typescript", "typescriptreact", "javascript", "javascriptreact"]
lsp = "typescript-language-server"
formatters = ["prettier"]
formatter_mode = "chain"
lsp_format = "never"
```

**Step 4: Create json.toml**

```toml
extensions = ["json"]
formatters = ["jq"]
formatter_mode = "chain"
lsp_format = "never"
```

**Step 5: Create markdown.toml**

```toml
extensions = ["md", "markdown"]
formatters = ["pandoc"]
formatter_mode = "chain"
lsp_format = "never"
```

**Step 6: Commit**

```bash
git add rcm/config/lux/filetype/
git commit -m "add formatter references to lux filetype configs"
```

---

### Task 3: Strip vim ftplugins to editor-only settings

**Files:**
- Modify: `rcm/vim/ftplugin/go.vim`
- Modify: `rcm/vim/ftplugin/sh.vim`
- Modify: `rcm/vim/ftplugin/bash.vim`
- Modify: `rcm/vim/ftplugin/bats.vim`
- Modify: `rcm/vim/ftplugin/markdown.vim`
- Delete: `rcm/vim/ftplugin/javascript.vim`
- Delete: `rcm/vim/ftplugin/json.vim`

**Step 1: Rewrite go.vim (editor-only)**

Remove `b:conform` and `b:testprg`. Keep listchars and makeprg:

```vim

" Invisible tabs for Go
setlocal list listchars=tab:\ \ ,trail:·,nbsp:·

" pipes have to be escaped in makeprg
let &l:makeprg = "bash -c '( go vet ./... 2>&1 \\| sed \"s/^vet: //g\" ) && go build -o /dev/null'"
```

**Step 2: Rewrite sh.vim (editor-only)**

Remove `s:path_bin`, `b:conform`, and `makeprg` (shellcheck diagnostics come via
bash-language-server in lux). Keep tab settings:

```vim

" Softtabs, 2 spaces
setlocal tabstop=2
setlocal shiftwidth=2
setlocal shiftround
setlocal expandtab
```

**Step 3: Rewrite bash.vim (editor-only)**

Remove `equalprg` and `s:path`. Keep tab settings:

```vim

" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set shiftround
set expandtab
```

**Step 4: Rewrite bats.vim (editor-only)**

Remove `s:path_bin` references. Keep wrap, listchars, makeprg, errorformat, and
syntax. Note: `makeprg` uses `shellcheck` and `bats` from `$PATH` (project
devshell) instead of `s:path_bin`:

```vim

" tests have long literals
setlocal wrap textwidth=0 wrapmargin=0
setlocal list listchars=tab:▸\ ,trail:·,nbsp:·

setlocal equalprg=shfmt\ %
let &l:makeprg = "bash -c 'shellcheck -f gcc % && bats --jobs 8 --tap % >&1'"

let &l:comments = "b:#"
let &l:commentstring = "#%s"

"not ok 1 can_output_organize
"TODO-P4 fix issue with lines followed by `# skip` causing processing issues
setlocal efm=%Enot\ ok\ %*\\d\ %m,
"# (from function `assert_output' in file zz-test/test_helper/bats-assert/src/assert_output.bash, line 194,
"#  in test file zz-test/failed_organize.bats, line 59)
setlocal efm+=%Z%.%#\ in\ test\ file\ %f\\,\ line\ %l)
"#   `assert_output "$(cat "$expected_organize")"' failed
"#
"# -- output differs --
"# expected (5 lines):
"#   ---
"#   * ok
"#   ---
"#
"#   - [one/uno] wow
"# actual (2 lines):
"#   Removed etikett 'ok' from zettel 'one/uno'
"#   [one/uno a6afa0a9dd71704237c33136470573f052c9b4d53584f80e1d2d03ed745cab6d] (updated)
"# --
"#
setlocal efm+=%C%.%#

augroup BatsSyntax
  au!
  autocmd Syntax <buffer> setlocal syntax=bash
augroup END
```

**Step 5: Rewrite markdown.vim (editor-only)**

Remove commented `s:path_bin` and `equalprg`:

```vim

let &l:textwidth = 80
```

**Step 6: Delete javascript.vim and json.vim**

```bash
rm rcm/vim/ftplugin/javascript.vim rcm/vim/ftplugin/json.vim
```

**Step 7: Commit**

```bash
git add rcm/vim/ftplugin/go.vim rcm/vim/ftplugin/sh.vim rcm/vim/ftplugin/bash.vim
git add rcm/vim/ftplugin/bats.vim rcm/vim/ftplugin/markdown.vim
git add rcm/vim/ftplugin/javascript.vim rcm/vim/ftplugin/json.vim
git commit -m "strip vim ftplugins to editor-only settings, remove formatter config"
```

---

### Task 4: Delete the ftplugin flake and obsolete files

**Files:**
- Delete: `rcm/vim/ftplugin/flake.nix`
- Delete: `rcm/vim/ftplugin/go-format.bash`
- Delete: `rcm/vim/ftplugin/eslintrc.json`
- Delete: `rcm/vim/ftplugin/php-cs-fixer.php`

**Step 1: Remove files**

```bash
rm rcm/vim/ftplugin/flake.nix
rm rcm/vim/ftplugin/go-format.bash
rm rcm/vim/ftplugin/eslintrc.json
rm rcm/vim/ftplugin/php-cs-fixer.php
```

Also remove the `flake.lock` and `result` symlink if they exist:

```bash
rm -f rcm/vim/ftplugin/flake.lock rcm/vim/ftplugin/result
```

**Step 2: Commit**

```bash
git add rcm/vim/ftplugin/flake.nix rcm/vim/ftplugin/go-format.bash
git add rcm/vim/ftplugin/eslintrc.json rcm/vim/ftplugin/php-cs-fixer.php
git add rcm/vim/ftplugin/flake.lock rcm/vim/ftplugin/result
git commit -m "delete ftplugin flake and obsolete formatter configs"
```

---

### Task 5: Relocate Go test scripts

**Files:**
- Move: `rcm/vim/ftplugin/go-test.bash` -> `rcm/bin/go-test.bash`
- Move: `rcm/vim/ftplugin/go-test-format.bash` -> `rcm/bin/go-test-format.bash`
- Modify: `rcm/vim/ftplugin/go.vim` (update testprg path)

`rcm/bin/` does not currently exist. rcm will install files from this directory
to `~/bin/` (dotfiles convention).

**Step 1: Create rcm/bin/ and move scripts**

```bash
mkdir -p rcm/bin
mv rcm/vim/ftplugin/go-test.bash rcm/bin/go-test.bash
mv rcm/vim/ftplugin/go-test-format.bash rcm/bin/go-test-format.bash
```

**Step 2: Remove stale PATH prepend from go-test.bash**

In `rcm/bin/go-test.bash`, the `dir_script` variable currently points to the
ftplugin directory for `go-test-format.bash`. Since both scripts will now be in
`~/bin/`, update the reference:

The line:
```bash
dir_script="$(dirname "$0")"
```
stays as-is since both scripts will be colocated in `~/bin/`.

**Step 3: Verify go.vim no longer references go-test.bash**

The `b:testprg` line was already removed in Task 3. No further changes needed.

**Step 4: Commit**

```bash
git add rcm/bin/go-test.bash rcm/bin/go-test-format.bash
git add rcm/vim/ftplugin/go-test.bash rcm/vim/ftplugin/go-test-format.bash
git commit -m "move go test scripts from ftplugin to rcm/bin"
```

---

### Task 6: Verify and update rcm excludes

**Files:**
- Check: `rcm/rcrc`

**Step 1: Verify rcrc doesn't need updates**

Check that `rcm/rcrc` EXCLUDES doesn't reference any of the deleted files and
doesn't need new entries for `bin/`. rcm installs everything not in EXCLUDES, so
`bin/go-test.bash` will become `~/bin/go-test.bash` automatically.

The flake.lock and result symlink should be excluded. Check if they're already
excluded or if `vim/ftplugin/flake.lock` and `vim/ftplugin/result` need entries.
Since we deleted them, no exclude needed.

**Step 2: Commit if changes needed**

Only commit if `rcrc` was modified.

---

### Task 7: Smoke test

**Step 1: Run rcup to verify dotfiles install correctly**

```bash
rcup -v 2>&1 | grep -E '(ftplugin|lux|bin/go-test)'
```

Verify:
- `~/.config/lux/formatters.toml` is installed
- `~/.config/lux/filetype/json.toml` and `markdown.toml` are installed
- `~/.vim/ftplugin/` files are updated (no javascript.vim, no json.vim)
- `~/bin/go-test.bash` and `~/bin/go-test-format.bash` are installed
- No `flake.nix`, `go-format.bash`, `eslintrc.json`, or `php-cs-fixer.php` in
  `~/.vim/ftplugin/`

**Step 2: Verify lux loads the formatter config**

Open neovim, edit a `.go` file, and trigger format (however lux formatting is
invoked in your neovim setup). Verify golines+gofumpt chain runs.

**Step 3: Verify lux loads new filetypes**

Open a `.json` file and format. Verify jq runs. Open a `.md` file and format.
Verify pandoc runs.
