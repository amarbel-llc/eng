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
            --tmpfs /tmp \
            --bind "$HOME/.config/claude" /tmp/config \
            --bind "$HOME/.local/share/claude" /tmp/data \
            --chdir /mnt \
            --tmpfs /home \
            --tmpfs /root \
            --setenv XDG_CONFIG_HOME /tmp/config \
            --setenv XDG_DATA_HOME /tmp/data \
            --setenv CLAUDE_CONFIG_DIR /tmp/config \
            --setenv CLAUDE_DATA_DIR /tmp/data \
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
