{
  description = "Sandboxed Claude Code using bubblewrap";

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

        claude-sandboxed = pkgs.writeShellScriptBin "claude-sandboxed" ''
          #!/usr/bin/env bash
          set -euo pipefail
          
          # Default values
          BRANCH="$(git branch --show-current)"
          TEMP_DIR=""
          WORKTREE_PATH=""
          
          # Function to show usage
          usage() {
            echo "Usage: $0 [-b BRANCH] [-d TEMP_DIR] [claude-args...]"
            echo "  -b BRANCH    Branch to checkout (default: main)"
            echo "  -d TEMP_DIR  Temporary directory to use (default: auto-generated)"
            echo "  -h           Show this help message"
            echo ""
            echo "All remaining arguments are passed to claude-code"
            exit 1
          }
          
          # Function to cleanup on exit
          cleanup() {
            local exit_code=$?

            if [[ -n $WORKTREE_PATH && -d $WORKTREE_PATH ]]; then
              echo "Removing worktree: $WORKTREE_PATH" >&2
              git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true
            fi

            if [[ -n $TEMP_DIR && -d $TEMP_DIR ]]; then
              echo "Removing temporary directory: $TEMP_DIR" >&2
              rm -rf "$TEMP_DIR" 2>/dev/null || true
            fi

            # TODO delete the claude branch

            exit $exit_code
          }
          
          # Set up cleanup trap
          trap cleanup EXIT INT TERM
          
          # Parse command line options
          while getopts "b:d:h" opt; do
            case $opt in
            b)
              BRANCH="$OPTARG"
              ;;
            d)
              TEMP_DIR="$OPTARG"
              ;;
            h)
              usage
              ;;
            \?)
              echo "Invalid option: -$OPTARG" >&2
              usage
              ;;
            esac
          done
          
          # Shift to get remaining arguments for claude
          shift $((OPTIND-1))
          
          # Check if we're in a git repository
          if ! git rev-parse --git-dir >/dev/null 2>&1; then
            echo "Error: Not in a git repository" >&2
            exit 1
          fi
          
          # Create temporary directory if not specified
          if [[ -z $TEMP_DIR ]]; then
            TEMP_DIR=$(mktemp -d -t claude-worktree-XXXXXX)
          else
            mkdir -p "$TEMP_DIR"
          fi

          TEMP_ID="$(basename "$TEMP_DIR")"
          
          # Set worktree path
          WORKTREE_PATH="$TEMP_DIR/worktree"
          
          git branch "$TEMP_ID"
          BRANCH="$TEMP_ID"
          echo "Creating linked worktree for branch '$BRANCH' in: $WORKTREE_PATH" >&2
          
          # Create the worktree
          if ! git worktree add "$WORKTREE_PATH" "$BRANCH" 2>/dev/null; then
            echo "Error: Failed to create worktree for branch '$BRANCH'" >&2
            echo "Branch may not exist or worktree already exists for this branch" >&2
            exit 1
          fi
          
          echo "Worktree created successfully" >&2
          echo "Working directory: $WORKTREE_PATH" >&2
          echo "" >&2
          
          # Create necessary directories if they don't exist
          mkdir -p "$HOME/.config/claude"
          mkdir -p "$HOME/.local/share/claude"

          WORKSPACE_PATH="$(realpath --relative-to="$(git rev-parse --show-toplevel)" .)"
          
          ${pkgs.bubblewrap}/bin/bwrap \
            --ro-bind / / \
            --bind "$WORKTREE_PATH" /mnt \
            --tmpfs /tmp \
            --bind "$HOME/.config/claude" /tmp/config \
            --bind "$HOME/.local/share/claude" /tmp/data \
            --chdir "/mnt/$WORKSPACE_PATH" \
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
            ripgrep
            bubblewrap
            claude-sandboxed
          ];

          shellHook = ''
            echo "Claude Code Sandbox Environment"
            echo "Available commands:"
            echo "  claude-sandboxed  - Sandboxed claude-code using git worktree"
            echo ""
            echo "Usage:"
            echo "  claude-sandboxed [-b BRANCH] [-d TEMP_DIR] [claude-args...]"
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
          program = "${claude-sandboxed}/bin/claude-sandboxed";
        };
      });
}
