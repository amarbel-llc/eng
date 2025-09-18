{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
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
