{
  description = "Sandboxed Claude Code using bubblewrap";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        claude-sandboxed = pkgs.writeShellScriptBin "claude-sandboxed" ''
          #!/usr/bin/env bash
          set -euo pipefail
          
          CURRENT_DIR="$(pwd)"
          
          # Create necessary directories if they don't exist
          mkdir -p "$HOME/.config/claude"
          mkdir -p "$HOME/.local/share/claude"
          
          exec ${pkgs.bubblewrap}/bin/bwrap \
            --ro-bind / / \
            --bind "$CURRENT_DIR" /mnt \
            --tmpfs /home \
            --tmpfs /tmp \
            --tmpfs /root \
            --bind "$HOME/.config/claude" /home/claude-config \
            --bind "$HOME/.local/share/claude" /home/claude-data \
            --chdir /mnt \
            --setenv XDG_CONFIG_HOME /home \
            --setenv XDG_DATA_HOME /home \
            --unshare-all \
            --share-net \
            --die-with-parent \
            ${pkgs.claude-code}/bin/claude "$@"
        '';
      in
      {
        packages.default = claude-sandboxed;
        packages.claude-sandboxed = claude-sandboxed;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bubblewrap
            claude-sandboxed
          ];

          shellHook = ''
            echo "Claude Code Sandbox Environment"
            echo "Available commands:"
            echo "  claude-sandboxed  - Sandboxed claude-code (restricted to current directory)"
            echo ""
            echo "To run the sandboxed version:"
            echo "  claude-sandboxed [args]"
          '';
        };

        apps.default = {
          type = "app";
          program = "${claude-sandboxed}/bin/claude-sandboxed";
        };
      });
}
