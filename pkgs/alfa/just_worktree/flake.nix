{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    utils.url = "github:numtide/flake-utils";
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
