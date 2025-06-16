#!/usr/bin/env bash
set -euo pipefail

# Default values
BRANCH="main"
TEMP_DIR=""
WORKTREE_PATH=""

# Function to show usage
usage() {
    echo "Usage: $0 [-b BRANCH] [-d TEMP_DIR]"
    echo "  -b BRANCH    Branch to checkout (default: main)"
    echo "  -d TEMP_DIR  Temporary directory to use (default: auto-generated)"
    echo "  -h           Show this help message"
    exit 1
}

# Function to cleanup on exit
cleanup() {
    local exit_code=$?
    if [[ -n "$WORKTREE_PATH" && -d "$WORKTREE_PATH" ]]; then
        echo "Removing worktree: $WORKTREE_PATH"
        git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true
    fi
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        echo "Removing temporary directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
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

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository" >&2
    exit 1
fi

# Create temporary directory if not specified
if [[ -z "$TEMP_DIR" ]]; then
    TEMP_DIR=$(mktemp -d -t git-worktree-XXXXXX)
else
    mkdir -p "$TEMP_DIR"
fi

# Set worktree path
WORKTREE_PATH="$TEMP_DIR/worktree"

echo "Creating linked worktree for branch '$BRANCH' in: $WORKTREE_PATH"

# Create the worktree
if ! git worktree add "$WORKTREE_PATH" "$BRANCH" 2>/dev/null; then
    echo "Error: Failed to create worktree for branch '$BRANCH'" >&2
    echo "Branch may not exist or worktree already exists for this branch" >&2
    exit 1
fi

echo "Worktree created successfully"
echo "Working directory: $WORKTREE_PATH"
echo ""
echo "Press Enter to continue working in the worktree, or Ctrl+C to exit..."

# Change to the worktree directory
cd "$WORKTREE_PATH"

# Start an interactive shell in the worktree
exec "$SHELL"