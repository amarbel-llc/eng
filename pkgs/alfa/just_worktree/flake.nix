{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/bd708996359444aa54ea97e10779ebc1eb6dad34";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8bb5646e0bed5dbd3ab08c7a7cc15b75ab4e1d0f";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs = { self, nixpkgs, utils, nixpkgs-stable }:
    (utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          packages.default = pkgs.writeShellScriptBin "wrapped-prog" ''
            #!/usr/bin/env bash
            set -euo pipefail
            
            # Create timestamp for worktree directory
            target="''${1:-default}"
            timestamp="$(date +"%Y-%m-%d-%H-%M")"
            id="just_worktree-$target-$timestamp"
            worktree_dir="$(mktemp -d -t "$id-XXXXXX")"
            git branch "$id"
            
            git worktree add "$worktree_dir" "$id"
            git diff HEAD | git -C "$worktree_dir" apply --3way

            prefix="$(git rev-parse --show-prefix)"
            
            pushd "$worktree_dir/$prefix" || exit 1
            ${pkgs.just}/bin/just "$@"
            popd
            git worktree remove "$worktree_dir"
            rm -rf "$worktree_dir"
            git merge "$id"
            git branch -d "$id"
          '';
        }
      )
    );
}
