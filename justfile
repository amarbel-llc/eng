default: \
    update-git \
    build-nix \
    build-home \
    update-login-shell \
    deploy-flake-lock \
    build-rcm \
    install-zmx

# Format every recognized file in the current tree using treefmt. Honors a
# project-local treefmt.toml at the git root if present; otherwise uses eng's
# baked treefmt-nix config (see ./treefmt.nix).
fmt-all *args:
  treefmt {{args}}

# TODO implement a check that enforces no active claude sessions, worktrees, or
# sweatshops open. This is because upgrading the entire environment can break
# existing sessions
check-active_sessions:

update: update-git bump-nixpkgs update-repos

update-git:
  git sync

# git syncs all repos in ~/eng/repos
update-repos:
  tap-dancer exec-parallel "cd {} && git pull" ::: "$HOME/eng/repos/"*

# Refresh flake.lock to pick up upstream movement on branch-ref inputs
# (e.g. nixpkgs stable on nixos-25.11). SHA-pinned inputs like
# nixpkgs-master are unaffected — those only move via `just bump-nixpkgs`.
update-nix-flake:
  nix flake update

# push flake.lock to origin
deploy-flake-lock:
  #!/usr/bin/env bash
  set -euo pipefail
  if git diff --quiet flake.lock; then
    echo "flake.lock unchanged, skipping deploy"
    exit 0
  fi
  git add flake.lock
  git commit -m "update flake.lock"
  git push

# build, validate, and install purse-first marketplace (framework skills)
install-purse-first:
  #!/usr/bin/env bash
  set -euo pipefail
  store_path="$(nix build .#purse-first-marketplace --no-link --print-out-paths)"
  purse-first validate "$store_path/.claude-plugin/marketplace.json"
  purse-first install "$store_path"

install-mcp mcp:
  #!/usr/bin/env bash
  set -euo pipefail
  store_path="$(nix build .#{{mcp}} --no-link --print-out-paths)"
  purse-first validate "$store_path/.claude-plugin/marketplace.json"
  purse-first install "$store_path"

# build and validate purse-first marketplace without installing
validate-purse-first:
  #!/usr/bin/env bash
  set -euo pipefail
  store_path="$(nix build .#purse-first-marketplace --no-link --print-out-paths)"
  purse-first validate "$store_path/.claude-plugin/marketplace.json"

# build zmx outside the flake and link to ~/.local/bin
install-zmx:
  #!/usr/bin/env bash
  set -euo pipefail
  gcroot="$HOME/.local/share/nix/gcroots/zmx"
  mkdir -p "$(dirname "$gcroot")" "$HOME/.local/bin"
  nix build github:amarbel-llc/zmx#default --refresh --out-link "$gcroot"
  ln -sf "$gcroot/bin/zmx" "$HOME/.local/bin/zmx"

install-niri-session:
  #!/usr/bin/env bash
  set -euo pipefail
  if [[ "$(uname)" != "Linux" ]]; then
    gum log --level info "not Linux, skipping niri session install"
    exit 0
  fi
  src="$HOME/.local/share/wayland-sessions/niri.desktop"
  if [[ ! -f "$src" ]]; then
    gum log --level error "niri.desktop not found — run 'just build-rcm' first"
    exit 1
  fi
  pkexec install -m 644 "$src" /usr/share/wayland-sessions/niri.desktop

test-integration:
  nix develop ./envs/integration-test --command just -f envs/integration-test/justfile test

# Sanity check for eng#41: verifies the darwin nix-daemon accepts
# __impure derivations (impure-derivations experimental feature) AND that
# /usr/bin/sandbox-exec is whitelisted in allowed-impure-host-deps. Builds
# a throwaway __impure derivation that execs /usr/bin/sandbox-exec; a
# successful build proves both daemon settings are live.
# Remove once FDR-0001 tracer has its own coverage.
[group('debug')]
[macos]
debug-impure-derivations-smoke:
  #!/usr/bin/env bash
  set -euo pipefail
  # Use the flake registry's `nixpkgs` rather than eng's full flake to
  # keep eval cheap — this smoke test only needs runCommand, not the
  # full eng dep graph.
  nix build --impure --no-link --print-out-paths \
    --expr '(builtins.getFlake "nixpkgs").legacyPackages.${builtins.currentSystem}.runCommand "eng-41-impure-smoke" {
      __impure = true;
      __impureHostDeps = [ "/usr/bin/sandbox-exec" ];
    } "/usr/bin/sandbox-exec -n no-internet /usr/bin/true && touch $out"'

[group('debug')]
[linux]
debug-impure-derivations-smoke:
  @echo "darwin-only sanity check (eng#41)"

clean-nix:
  nix-store --gc

# remove stale direnv layout caches from ~/.cache/direnv
clean-direnv-cache:
  rm -rf ~/.cache/direnv/layouts/*

# remove stale .direnv flake profiles across all projects (regenerate on next cd)
clean-direnv:
  find ~/eng -name .direnv -type d -exec rm -rf {} +

# remove result symlinks left by nix build (not included in clean by default)
clean-result-symlinks:
  find ~/eng -name result -type l -not -path ~/eng/result -delete

clean: clean-result-symlinks clean-direnv-cache clean-direnv clean-nix

# update /bin/fish symlink, /etc/shells, and the fish GC root
#
# When fish is upgraded via home-manager, $SHELL ends up pointing at the new
# nix store path. sudo validates inherited $SHELL against /etc/shells and
# refuses to run if it's not listed ("incident has been reported"), so this
# recipe both registers the store path in /etc/shells and strips $SHELL when
# invoking sudo so the command can run from the just-upgraded environment.
#
# The /bin/fish symlink is not itself a GC root — the fish store path it
# points to is only protected as long as it's reachable from the active
# home-manager profile. To keep /bin/fish from going dangling after a stale
# generation gets GC'd, we also pin the fish store path via an indirect GC
# root under ~/.local/share/nix/gcroots.
update-login-shell:
  #!/usr/bin/env bash
  set -euo pipefail
  if [[ "$(uname)" != "Linux" ]]; then
    # TODO add support for updating darwin shell
    gum log --level info "not Linux, skipping fish login shell update"
    exit 0
  fi

  target="$(readlink -f "$(which fish)")"
  # Walk up from .../bin/fish to the package store path itself so the GC
  # root protects the whole package, not just the binary path inside it.
  fish_store_path="${target%/bin/fish}"

  # Both pkexec and sudo check the caller's $SHELL against /etc/shells and
  # refuse (pkexec exits 127 with "This incident has been reported.") if the
  # current fish store path has been GC'd out. Strip SHELL in both branches
  # so the recipe can bootstrap after a nixpkgs bump.
  if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    privesc=(env -u SHELL pkexec)
  else
    privesc=(env -u SHELL sudo)
  fi

  # Step 1: register the resolved fish path in /etc/shells (idempotent).
  if ! grep -Fxq "$target" /etc/shells; then
    gum log --level info "adding $target to /etc/shells"
    "${privesc[@]}" tee -a /etc/shells > /dev/null <<<"$target"
  fi

  # Step 2: pin the fish store path as an indirect GC root so /bin/fish
  # can't be orphaned by `nix-store --gc`. Idempotent — re-running with a
  # new store path just repoints the existing gcroot.
  gcroot="$HOME/.local/share/nix/gcroots/login-shell-fish"
  mkdir -p "$(dirname "$gcroot")"
  nix-store --add-root "$gcroot" --indirect --realise "$fish_store_path" > /dev/null

  # Step 3: update /bin/fish symlink to point at the resolved fish path.
  current="$(readlink -f /bin/fish 2>/dev/null || true)"
  if [[ "$target" == "$current" ]]; then
    gum log --level info "/bin/fish already up to date"
    exit 0
  fi
  gum log --level info "updating /bin/fish -> $target"
  "${privesc[@]}" ln -sf "$target" /bin/fish

update-kitty:
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
  pkexec sh -c "ln -sf $HOME/.local/kitty.app/bin/kitty /usr/bin/kitty && ln -sf $HOME/.local/kitty.app/bin/kitten /usr/bin/kitten"

export file_nixpkgs_git_master_sha := "nixpkgs-git-master.git-sha"

# Fetch the latest nixpkgs master SHA and write it to the pin file.
# Implementation detail of `bump-nixpkgs` — not meant to be invoked directly.
_fetch-nixpkgs-master-sha:
  #!/usr/bin/env bash
  set -euo pipefail
  gum log --level info "fetching nixpkgs master HEAD"
  sha="$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/master | awk '{print $1}')"
  if [[ -z "$sha" ]]; then
    gum log --level error "failed to resolve nixpkgs master"
    exit 1
  fi
  gum log --level info "nixpkgs master = $sha"
  echo "$sha" > {{file_nixpkgs_git_master_sha}}

# Bump nixpkgs-master to the latest upstream HEAD: rewrites the SHA literal
# in flake.nix, refreshes flake.lock, builds to verify, prints a sentinel
# package version diff, and commits the result. The commit only touches
# flake.nix, flake.lock, and the SHA pin file — any unrelated staged
# changes are left alone.
bump-nixpkgs:
  #!/usr/bin/env bash
  set -euo pipefail

  # Capture the current pin so we can diff versions after the bump.
  old_sha="$(grep -oE 'nixpkgs-master\.url = "github:NixOS/nixpkgs/[0-9a-f]{40}"' flake.nix | grep -oE '[0-9a-f]{40}')"
  if [[ -z "$old_sha" ]]; then
    gum log --level error "could not find nixpkgs-master SHA literal in flake.nix"
    exit 1
  fi

  just _fetch-nixpkgs-master-sha
  new_sha="$(cat {{file_nixpkgs_git_master_sha}})"

  if [[ "$old_sha" == "$new_sha" ]]; then
    gum log --level info "nixpkgs-master already at $new_sha — no-op"
    exit 0
  fi

  gum log --level info "bumping nixpkgs-master: $old_sha → $new_sha"
  sed -i -E "/nixpkgs-master\.url/ s|(github:NixOS/nixpkgs/)[0-9a-f]{40}|\\1${new_sha}|" flake.nix

  gum log --level info "refreshing flake.lock"
  nix flake update nixpkgs-master

  gum log --level info "building eng to verify"
  nix build --show-trace

  # Sentinel package version diff. Each side is one eval over the
  # nixpkgs ref; if the eval fails (e.g. attribute renamed), we just
  # skip that sentinel rather than failing the whole bump. The rendered
  # diff is captured into $version_diff so it can go into the commit
  # body.
  gum log --level info "computing version diff"
  versions_expr='p: { fish = p.fish.version or "?"; git = p.git.version or "?"; gopls = p.gopls.version or "?"; }'
  version_diff=""
  if old_versions="$(nix eval --json --apply "$versions_expr" "github:NixOS/nixpkgs/${old_sha}#legacyPackages.x86_64-linux" 2>/dev/null)" \
    && new_versions="$(nix eval --json --apply "$versions_expr" "github:NixOS/nixpkgs/${new_sha}#legacyPackages.x86_64-linux" 2>/dev/null)"; then
    version_diff="$(jq -nr --argjson old "$old_versions" --argjson new "$new_versions" '
      ($old | keys) as $names
      | $names[]
      | "  \(.): \($old[.]) → \($new[.])"
    ')"
    echo "$version_diff"
  else
    gum log --level warn "version diff eval failed — skipping"
  fi

  # Commit only the bump-related paths so unrelated staged changes in
  # the index are not swept into this commit.
  gum log --level info "committing bump"
  commit_msg="bump nixpkgs-master: ${old_sha:0:7} → ${new_sha:0:7}"
  if [[ -n "$version_diff" ]]; then
    commit_msg="$(printf '%s\n\n%s\n' "$commit_msg" "$version_diff")"
  fi
  git commit flake.nix flake.lock {{file_nixpkgs_git_master_sha}} -m "$commit_msg"

# Update flakes in main eng repo (excludes repos/ and worktrees/)
update-nix:
  UPDATE_FLAKES_EXCLUDE="./repos/* ./worktrees/*" ./bin/update_flakes.bash

# Pull a sub-repo, cascade eng's nixpkgs-master SHA into its flake.nix,
# refresh its flake.lock, and stage the changes for human review. Does
# NOT auto-commit, push, or run the sub-repo's default just recipe —
# those are footguns when fanned out across 30+ repos.
[no-exit-message]
_update-repo-full dir:
  #!/usr/bin/env bash
  set -euo pipefail

  dir="$(realpath "{{dir}}")"
  eng_dir="{{justfile_directory()}}"

  if [[ ! -f "$dir/flake.nix" ]]; then
    exit 0
  fi

  cd "$dir"

  if ! git remote -v | grep -qE 'friedenberg|amarbel-llc'; then
    exit 0
  fi

  master_sha="$(cat "$eng_dir/{{file_nixpkgs_git_master_sha}}")"

  git pull --rebase

  if grep -q 'nixpkgs-master\.url' flake.nix; then
    sed -i -E "/nixpkgs-master\.url/ s|(github:NixOS/nixpkgs/)[0-9a-f]{40}|\\1${master_sha}|" flake.nix
  fi

  nix flake update

  if ! git diff --quiet flake.nix flake.lock; then
    git add flake.nix flake.lock
    gum log --level info "$(basename "$dir"): staged flake.nix + flake.lock"
  fi

# Update flakes in repos/ in parallel (separate git repositories)
update-nix-repos:
  tap-dancer exec-parallel -j 1 "just _update-repo-full {}" ::: repos/*/

# Update apt package index, upgrade installed packages, prune orphans.
# Single pkexec call so the three apt-get invocations share one auth prompt.
update-apt:
  pkexec sh -c 'apt-get update && apt-get upgrade -y && apt-get autoremove -y'

# Update installed Flatpak apps and runtimes. Note: system-scope installs
# raise their own polkit prompt via flatpak-system-helper, separate from
# update-apt's pkexec auth.
update-flatpak:
  flatpak update -y

# Run all non-Nix system package updates (Ubuntu/Linux).
update-system: update-apt update-flatpak

build-home: build-nix
  #!/usr/bin/env bash
  set -euo pipefail
  if [[ "$(uname)" == "Darwin" ]]; then
    identity_file="/etc/nix-darwin/identity.json"
  else
    identity_file="$HOME/.config/identity.nix"
  fi
  if [[ ! -f "$identity_file" ]]; then
    gum log --level error "$identity_file not found"
    gum log --level info "run 'bin/bootstrap-identity.mjs' to create it"
    exit 1
  fi
  if [[ "$(uname)" == "Darwin" ]]; then
    sudo darwin-rebuild switch --impure --flake .
  else
    nix run home-manager -- switch -b backup --impure --flake .#linux
  fi

build-nix:
  nix build --show-trace

build-nix-darwin:
  sudo darwin-rebuild switch --impure --flake .

[working-directory: "rcm"]
build-rcm: build-rcm-hooks-pre-up build-rcm-hooks-post-up
  env PATH="/usr/bin:$PATH" rcup < /dev/null

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

# reload launchd agents that home-manager manages (macOS only).
# launchctl load is a no-op for already-loaded services, so this is
# safe to run unconditionally after build-home.
[macos]
load-agents:
  #!/usr/bin/env bash
  set -euo pipefail
  for plist in \
    ~/Library/LaunchAgents/net.ross-williams.ssh-agent-mux.plist \
    ~/Library/LaunchAgents/net.cooperi.pivy-agent.plist; do
    if [[ -f "$plist" ]]; then
      launchctl load "$plist" 2>/dev/null || true
      gum log --level info "loaded $(basename "$plist")"
    fi
  done

[linux]
load-agents:
  @true

validate: build-nix
  nix flake check --impure

build: build-nix build-rcm build-home load-agents

# Top 20 processes by CPU and by memory.
[group('debug')]
[linux]
debug-top-procs:
  #!/usr/bin/env bash
  set -uo pipefail
  echo "=== top 20 by CPU ==="
  ps -eo pid,ppid,user,pcpu,pmem,rss,stat,start,time,comm,args --sort=-pcpu | head -21
  echo
  echo "=== top 20 by RSS ==="
  ps -eo pid,ppid,user,pcpu,pmem,rss,stat,start,time,comm,args --sort=-rss | head -21

# Load average, memory pressure, swap activity, run-queue + blocked counts.
[group('debug')]
[linux]
debug-system-load:
  #!/usr/bin/env bash
  set -uo pipefail
  echo "=== uptime / load ==="
  uptime
  echo
  echo "=== free -h ==="
  free -h
  echo
  echo "=== vmstat 1 5 (run-queue 'r', blocked 'b', swap si/so, cpu wa%) ==="
  vmstat 1 5
  echo
  echo "=== PSI: /proc/pressure ==="
  for f in /proc/pressure/cpu /proc/pressure/memory /proc/pressure/io; do
    [ -r "$f" ] && { echo "--- $f"; cat "$f"; }
  done

# Per-device disk I/O. Falls back to /proc/diskstats deltas if iostat is missing.
[group('debug')]
[linux]
debug-disk-io:
  #!/usr/bin/env bash
  set -uo pipefail
  if command -v iostat >/dev/null 2>&1; then
    echo "=== iostat -xz 1 3 ==="
    iostat -xz 1 3
  else
    echo "iostat not installed (sysstat); falling back to /proc/diskstats deltas"
    cat /proc/diskstats > /tmp/diskstats.a
    sleep 2
    cat /proc/diskstats > /tmp/diskstats.b
    diff /tmp/diskstats.a /tmp/diskstats.b || true
  fi
  echo
  echo "=== top 10 processes by I/O wait (D state or high iotime) ==="
  ps -eo pid,user,stat,wchan,comm,args | awk 'NR==1 || $3 ~ /D/'

# Snapshot everything: top procs, load, and disk I/O. Use first when triaging
# unresponsiveness so CPU, memory, and I/O are correlated at the same instant.
[group('debug')]
[linux]
debug-system-snapshot: debug-top-procs debug-system-load debug-disk-io

# Top duplicate packages in eng's runtime closure, sorted by wasted bytes.
# Thin wrapper over doppelgang(1) (amarbel-llc/doppelgang). Forwards extra
# args to `doppelgang dupes`. Pass `build` for build-time scope or
# `--by-owner` to attribute each copy to top-level flake inputs.
[group('debug')]
debug-nix-duplicates *args: build-nix
  ./result/bin/doppelgang dupes --installable {{justfile_directory()}}/result {{args}}

# Trace every closure path matching <pattern> back through the build graph
# via `nix why-depends --derivation`. Defaults to build-time scope so setup
# hooks (install-shell-files, goBuildHook, etc.) are visible.
#
# Usage: just debug-nix-why-depends-name 'install-shell-files$'
[group('debug')]
debug-nix-why-depends-name pattern: build-nix
  ./result/bin/doppelgang why --installable {{justfile_directory()}}/result {{pattern}}

# Refresh plugins/eng/skills/ from the bob flake input. Pulls the bob
# marketplace store path, copies its bundled skills tree into place,
# then chmods the files writable so they can be edited or removed (nix
# store paths are read-only). Skips skills listed in `eng_skipped_skills`
# below (e.g. using-superpowers). Idempotent. After refresh, the
# cross-reference rewrites (bob:/superpowers: -> eng:) need to be re-run
# manually.
[group('explore')]
explore-refresh-eng-skills:
  #!/usr/bin/env bash
  set -euo pipefail
  dest="plugins/eng/skills"
  # Skills present in bob upstream but intentionally excluded from eng.
  eng_skipped_skills=(using-superpowers)
  store_path="$(nix build .#bob-marketplace --no-link --print-out-paths)"
  src="$store_path/share/purse-first/bob/skills"
  if [[ ! -d "$src" ]]; then
    echo "expected skills dir not found at $src" >&2
    exit 1
  fi
  is_skipped() {
    local needle="$1"
    for s in "${eng_skipped_skills[@]}"; do
      [[ "$s" == "$needle" ]] && return 0
    done
    return 1
  }
  bob_skills=()
  for entry in "$src"/*; do
    name="$(basename "$entry")"
    is_skipped "$name" && continue
    bob_skills+=("$name")
  done
  if [[ -d "$dest" ]]; then
    for skill in "${bob_skills[@]}"; do
      target="$dest/$skill"
      if [[ -e "$target" ]]; then
        chmod -R u+w "$target"
        rm -rf "$target"
      fi
    done
  else
    mkdir -p "$dest"
  fi
  # -L dereferences symlinks so we land real files (the marketplace
  # output is a tree of symlinks back into other store paths).
  for skill in "${bob_skills[@]}"; do
    cp -RL "$src/$skill" "$dest/$skill"
  done
  chmod -R u+w "$dest"
  echo "refreshed bob-sourced skills in $dest from $src"
  echo "remember to re-apply eng: cross-reference rewrites if you re-run this"
