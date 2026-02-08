
- my github username is `friedenberg`
- prefer commands defined in justfiles
- prefer nix-based building and testing
- when performing new tasks that are done frequent, consider suggesting adding to the justfile
- prefer using direnv+nix-flakes and my devenv flakes from github.com/friedenberg/eng?dir=pkgs/alfa
- function names that are descriptive-enough to avoid redundant comments
- exclusively use the `nix-mcp-server` when in a nix-backed project
- exclusively use `lux` to interact with the codebase for projects whose
  languages and files are supported

# Scripts

- prefer using the `gum` package for log output

# Tests

- format output in TAP-14 (when reasonable)
- use `bats` for CLI-testing (like integration tests, use my project `dodder` as
  inspiration)

# Formatting

- for shell-scripts, use `shfmt`
- for nix, use `nix fmt`
- always use my devenv- flakes for new projects if they're available. if not available, ask if a new one should be created
- always use the nixpkgs (stable) and nixpkgs-master (unstable) pattern from my `eng` repo, defaulting to stable for new projects that use nix
- the nix-mcp-server must be used to interact with nix
- if git committing fails due to gpg-signing, DO NOT try to commit without a signature, instead ask the user to unlock the agent