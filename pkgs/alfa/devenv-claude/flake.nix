{
  description = "Sandboxed AI code-editing agent using bubblewrap. Only supports
  claude code for now";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devenv-nix.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-nix";
    devenv-shell.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-shell";
  };

  outputs = { self, nixpkgs, flake-utils, devenv-nix, devenv-shell }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        sweatshop = pkgs.stdenv.mkDerivation {
          name = "sweatshop";
          src = ./sweatshop.sh;
          buildInputs = [ pkgs.bubblewrap pkgs.claude-code ];
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out/bin
            substitute $src $out/bin/sweatshop \
              --replace "@bwrap@" "${pkgs.bubblewrap}/bin/bwrap" \
              --replace "@claude-code@" "${pkgs.claude-code}/bin/claude"
            chmod +x $out/bin/sweatshop
          '';
        };
      in
      {
        packages.default = sweatshop;
        packages.sweatshop = sweatshop;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            ripgrep
            bubblewrap
            sweatshop
          ];

          shellHook = ''
            echo "Claude Code Sandbox Environment"
            echo "Available commands:"
            echo "  sweatshop  - Sandboxed claude-code using git worktree"
            echo ""
            echo "Usage:"
            echo "  sweatshop [-b BRANCH] [-d TEMP_DIR] [claude-args...]"
            echo "    -b BRANCH    Branch to checkout (default: current branch)"
            echo "    -d TEMP_DIR  Temporary directory to use (default: auto-generated)"
            echo ""
            echo "The sandbox creates a git worktree and mounts it at /mnt"
            echo "Worktree is automatically cleaned up on exit"
          '';

          inputsFrom = [
            devenv-nix.devShells.${system}.default
            devenv-shell.devShells.${system}.default
          ];
        };

        apps.default = {
          type = "app";
          program = "${sweatshop}/bin/sweatshop";
        };
      });
}
