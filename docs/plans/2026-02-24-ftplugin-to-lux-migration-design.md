# Migrate vim ftplugin to lux formatter config

## Problem

The `rcm/vim/ftplugin/` directory bundles a standalone Nix flake that packages
formatters (golines, gofumpt, shfmt, prettier, jq, pandoc, shellcheck, eslint,
bats) alongside vim filetype configs. This is unmaintainable:

- Flake pins stale versions (Go 1.19, gofumpt 0.5.0, golines 0.11.0)
- Formatter config is duplicated between vim ftplugins and lux
- `./result/bin/` symlink trick requires manual `nix build`
- Three places to update when changing formatter settings

Lux already serves as the LSP server for neovim and has full formatter routing
support (chain/fallback modes, `flake =` references for tool installation) but
no `formatters.toml` is configured.

## Design

### 1. Create lux formatter configuration

Create `rcm/config/lux/formatters.toml`:

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

### 2. Update lux filetype configs

Update existing `rcm/config/lux/filetype/*.toml` to reference formatters:

| Filetype | Formatters | Mode | LSP Format |
|----------|-----------|------|------------|
| go | `["golines", "gofumpt"]` | chain | never |
| bash | `["shfmt"]` | chain | never |
| typescript | `["prettier"]` | chain | never |
| python | (none) | - | prefer |
| nix | (none) | - | prefer |
| php | (none) | - | prefer |
| terraform | (none) | - | prefer |

Add new filetype configs:

- `json.toml`: extensions `["json"]`, formatters `["jq"]`, no LSP
- `markdown.toml`: extensions `["md", "markdown"]`, formatters `["pandoc"]`, no LSP

### 3. Strip vim ftplugins to editor-only settings

Keep only editor settings that lux cannot handle (tab width, comments,
textwidth, listchars, makeprg, errorformat):

- `go.vim`: listchars, makeprg (go vet+build)
- `sh.vim`: 2-space softtabs, makeprg (shellcheck)
- `bash.vim`: 2-space softtabs
- `bats.vim`: wrap/textwidth, listchars, makeprg (shellcheck+bats), errorformat,
  syntax=bash
- `gitcommit.vim`: textwidth=72
- `make.vim`: expandtab, softtabstop=2
- `markdown.vim`: textwidth=80
- `terraform.vim`: comment settings
- `tf.vim`: comment settings

Remove all `b:conform`, `equalprg`, and `s:path_bin` references.

Delete entirely:

- `javascript.vim` (only had equalprg/makeprg, both handled by lux)
- `json.vim` (only had equalprg, handled by lux)

### 4. Delete the ftplugin flake

Remove:

- `rcm/vim/ftplugin/flake.nix`
- `rcm/vim/ftplugin/go-format.bash`
- `rcm/vim/ftplugin/eslintrc.json`
- `rcm/vim/ftplugin/php-cs-fixer.php`

### 5. Relocate Go test scripts

Move `go-test.bash` and `go-test-format.bash` from `rcm/vim/ftplugin/` to
`rcm/bin/`. Remove the `./result/bin/` PATH prepend (Go tools come from project
devshells). Update `go.vim` makeprg to reference `go-test.bash` from `$PATH`.

### 6. Future: purse-first neovim packaging (TODO)

Explore a purse-first package type that can ship:

- Neovim ftplugin files
- Lux config fragments (formatters, filetypes)
- Auto-discovery for editor configs
- Composability across multiple packages
