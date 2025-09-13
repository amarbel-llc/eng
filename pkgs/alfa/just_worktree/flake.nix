{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";
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
