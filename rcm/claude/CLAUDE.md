
- my github username is `friedenberg`
- my github org for personal projects is `amarbel-llc`
- prefer commands defined in justfiles
- prefer nix-based building and testing
- when performing new tasks that are done frequent, consider suggesting adding to the justfile
- prefer using direnv+nix-flakes and my devenv flakes from `github.com/amarbel-llc/eng?dir=devenvs`
- function names that are descriptive-enough to avoid redundant comments
- exclusively use the `nix` mcp when in a nix-backed project
- exclusively use `lux` mcp to interact with the codebase for projects whose
  languages and files are supported

# Tests

- format output in TAP-14 (when reasonable) and use amarbel-llc/tap-dancer
- use `bats` from amarbel-llc/batman for CLI-testing

# Formatting

- for shell-scripts, use `shfmt`
- for nix, use `nix fmt`
- always use my devenv- flakes for new projects if they're available. if not available, ask if a new one should be created
- always use the nixpkgs (stable) and nixpkgs-master (unstable) pattern from my `eng` repo, defaulting to stable for new projects that use nix
- the nix-mcp-server must be used to interact with nix
- if git committing fails due to gpg-signing, DO NOT try to commit without a signature, instead ask the user to unlock the agent
