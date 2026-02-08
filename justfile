export PATH := join(env_var('HOME'), "eng", "result", "bin") + ":" + env_var('PATH')

default: build

clean-nix:
  nix-store --gc

clean: clean-nix

update-kitty:
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
  pkexec ln -s "$(which kitty)" /usr/bin/kitty
  pkexec ln -s "$(which kitten)" /usr/bin/kitten

nix_nixpkgs_stable_git_branch := "nixos-25.11"
nix_nixpkgs_stable_darwin_git_branch := nix_nixpkgs_stable_git_branch + "-darwin"

export file_nixpkgs_git_master_sha := "nixpkgs-git-master.git-sha"
export file_nixpkgs_stable_git_sha := "nixpkgs-stable-git.git-sha"
export file_nixpkgs_stable_darwin_git_sha := "nixpkgs-stable-darwin-git.git-sha"

# TODO add flake-utils
update-nixpkgs:
  #!/usr/bin/env bash

  set -euo pipefail

  # Track visited flakes to avoid cycles
  declare -A visited

  echo "Fetching nixpkgs unstable git master digest..." >&2
  nix_nixpkgs_git_master_digest="$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/master | awk '{print $1}')"
  echo "Fetched nixpkgs unstable git master digest: ${nix_nixpkgs_git_master_digest}" >&2
  echo ${nix_nixpkgs_git_master_digest} > {{file_nixpkgs_git_master_sha}}

  echo "Fetching nixpkgs stable git {{nix_nixpkgs_stable_git_branch}} digest..." >&2
  nix_nixpkgs_stable_git_digest="$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/{{nix_nixpkgs_stable_git_branch}} | awk '{print $1}')"
  echo "Fetched nixpkgs stable git {{nix_nixpkgs_stable_git_branch}} digest: ${nix_nixpkgs_stable_git_digest}" >&2
  echo ${nix_nixpkgs_stable_git_digest} > {{file_nixpkgs_stable_git_sha}}

  echo "Fetching nixpkgs stable_darwin git {{nix_nixpkgs_stable_darwin_git_branch}} digest..." >&2
  nix_nixpkgs_stable_darwin_git_digest="$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/{{nix_nixpkgs_stable_darwin_git_branch}} | awk '{print $1}')"
  echo "Fetched nixpkgs stable_darwin git {{nix_nixpkgs_stable_darwin_git_branch}} digest: ${nix_nixpkgs_stable_darwin_git_digest}" >&2
  echo ${nix_nixpkgs_stable_darwin_git_digest} > {{file_nixpkgs_stable_darwin_git_sha}}


# Update flakes in main eng repo (excludes repos/)
update-nix:
  UPDATE_FLAKES_EXCLUDE="./repos/*" ./bin/update_flakes.bash

# Update flakes in repos/ (separate git repositories)
update-nix-repos:
  ./bin/update_flakes.bash repos

# Update all flakes (main repo + repos/)
update-nix-all: update-nix update-nix-repos

update: update-nix

build-nix:
  nix build --show-trace

build-nix-darwin:
  sudo darwin-rebuild switch --flake ./rcm/tag-darwin/config/nix-darwin
  # sudo nix run nix-darwin/master -- switch --flake "$(readlink "$HOME/.config/nix-darwin")"

[working-directory: "rcm"]
build-rcm: build-rcm-hooks-pre-up build-rcm-hooks-post-up
  env PATH="/usr/bin:$PATH" rcup

[working-directory: "rcm"]
build-rcm-rcrc:
  # TODO
  cp rcrc ~/.rcrc

[working-directory: "rcm/hooks/pre-up"]
@build-rcm-hooks-pre-up:
  chmod +x *

[working-directory: "rcm/hooks/post-up"]
@build-rcm-hooks-post-up:
  chmod +x *

build: build-nix build-rcm
