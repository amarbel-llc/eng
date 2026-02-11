#!/usr/bin/env bash
set -euo pipefail

project="$1"
source_dir="pkgs/alfa/$project"
target_dir="repos/$project"

# Validate source exists
[[ -d "$source_dir" ]] || {
  gum style --foreground 196 "Error: $source_dir not found"
  exit 1
}

gum style --foreground 212 "Migrating $project to repos/"

# Create target directory and initialize git
mkdir -p "$target_dir"
cd "$target_dir"
git init
git branch -m main

# Copy files
rsync -av "../../$source_dir/" ./

# Initial commit
git add .
git commit -m "Initial commit: Migrated $project from monorepo

Migrated from friedenberg/eng:$source_dir

This project was previously part of the monorepo but has been
extracted to its own repository for better maintainability."

# Skip GitHub repo creation - user will create manually
gum style --foreground 212 "Skipping GitHub repo creation (will be created manually later)"

# Validate build
gum style --foreground 212 "Validating build..."
nix flake check && nix build

gum style --foreground 82 "✓ Successfully migrated $project locally"
gum style --foreground 212 "Note: GitHub repo needs to be created manually"
