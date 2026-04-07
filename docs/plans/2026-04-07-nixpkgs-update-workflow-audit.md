# nixpkgs update workflow audit

**Status:** resolved by PATH Z (see `~/.claude/plans/valiant-gathering-neumann.md`)
**Captured:** 2026-04-07
**Resolved:** 2026-04-07
**Trigger:** while bumping fish from 4.2.1 → 4.5.0 via `programs.fish.package = pkgs-master.fish`, the fish 4.5 update was committed but **not yet verified** because the host's `/etc/shells` does not list the new fish store path, so login shell switching is broken. Revisit and fully test the fish update before doing the bigger workflow rework below.

## Open follow-ups before this audit lands

- [ ] Verify the fish 4.5 bump actually works end-to-end (`just build-home` then a fresh login session uses fish 4.5).
- [x] Fix `/etc/shells` so the new fish store path is registered. **Done in commit `f425536`** — `update-login-shell` now appends the resolved store path to `/etc/shells` idempotently and strips `$SHELL` when invoking sudo so the recipe can run from a just-upgraded environment. Commit `46ef119` also pins the fish store path as an indirect GC root via `~/.local/share/nix/gcroots/login-shell-fish` so `nix-store --gc` can't orphan `/bin/fish`.
- [ ] Confirm the fish 4.3 → 4.5 migration runs cleanly once and the `fish_frozen_key_bindings.fish` workaround can be retired.

## Resolution

The audit's bugs and friction (sections below) are resolved by **PATH Z**, a hybrid pinning strategy implemented in this same session. See `~/.claude/plans/valiant-gathering-neumann.md` for the implementation plan. Summary:

- Stable `nixpkgs` moved to a branch ref (`github:NixOS/nixpkgs/nixos-25.11`). Bumps now happen via `nix flake update`. Deleted `nixpkgs-stable-git.git-sha` and `nixpkgs-stable-darwin-git.git-sha`.
- `nixpkgs-master` keeps its SHA literal in `flake.nix` (rollback ergonomics).
- New `bump-nixpkgs` recipe is the canonical entry point: fetch new master SHA → sed-replace literal → `nix flake update nixpkgs-master` → `nix build` → version diff → stage. No `fh add`, no FlakeHub round-trip.
- The `update` mega-recipe is fixed to call `bump-nixpkgs` (was previously a no-op for the master pin).
- `_update-repo-full` no longer auto-commits/pushes, no longer runs each sub-repo's default `just` recipe, and uses the same `sed` cascade.
- `bin/update_flakes.bash` walker shape preserved; `fh add` calls replaced with line-anchored `sed`.

What's still open from the audit, deferred to follow-ups:

- **Sub-repos in `repos/`** still pin both stable and master as SHA literals. Migrating each one to a branch ref for stable would be a separate per-repo cleanup. The `update-nix-repos` cascade only touches the master SHA today; sub-repo stable bumps still require manual `nix flake update nixpkgs` per repo.
- **Version visibility** at bump time is implemented for sentinel packages (fish, git, claude-code, gopls). Adding more sentinels is a one-line change in the `bump-nixpkgs` recipe.

---

## How `update-nixpkgs` / `update-nix` works today

```
just update-nixpkgs   →  writes 3 files: nixpkgs-{git-master,stable-git,stable-darwin-git}.git-sha
                         (does NOT touch flake.nix)

just update-nix       →  bin/update_flakes.bash walks every flake.nix recursively
                         for each, runs `fh add github:NixOS/nixpkgs/$SHA` to rewrite the URL
                         then `nix flake update` to refresh the lockfile

just update           →  update-git → update-nixpkgs → update-nix-flake → update-repos
                         (update-nix-flake is just `nix flake update`)
```

## Bugs and friction found

### 1. `just update` does not actually bump nixpkgs

The mega-recipe runs `update-nixpkgs` (writes new SHAs to the side files) and then `update-nix-flake` (`nix flake update`). Neither step touches `flake.nix`'s hardcoded SHAs. To actually propagate the bump you have to remember to run `just update-nix` separately, which is *not* in the `update` chain. Right now `just update` is roughly a no-op for the nixpkgs pin — it just leaves the .git-sha files modified-but-uncommitted. **Biggest reliability problem.**

### 2. `nixpkgs-stable-darwin-git.git-sha` is dead state

Fetched on every `update-nixpkgs`, never consumed. Not read by `flake.nix`, not read by `update_flakes.bash`. Either Darwin should have its own pin (the convention says it does) or the file should be deleted. Right now it's a trap — looks meaningful, isn't.

### 3. The .git-sha files are decoupled from flake.nix

Two sources of truth: the side files and the URL strings inside `flake.nix`. They drift unless `update-nix` is run. `git status` after `update-nixpkgs` shows three modified files but no signal that the work is half-done.

### 4. `fh add` rewrite is fragile

Each invocation of `update-nix` calls `fh add` for every flake to textually rewrite the URL. Detection is grep-based (`grep -q 'nixpkgs-master' flake.nix`), which would false-positive on a comment. Also requires network access to FlakeHub and an `fh` auth token just to bump a pin. And `fh add` reformats the file — any local cosmetic deviation gets normalized.

### 5. No version visibility

After a bump you see SHA churn in `git diff` and a much bigger diff in `flake.lock`, but nothing tells you "fish 4.2.1 → 4.6.0". You only find out at `darwin-rebuild`/`home-manager switch` time, which is the worst place to discover a regression.

### 6. No build verification before commit

`_update-repo-full` (used by `update-nix-repos`) commits `flake.lock` and pushes before any `nix build`. `update-nix` itself doesn't even build. A bump that breaks the flake gets committed and pushed.

### 7. `_update-repo-full` runs `just` (default recipe) in every repo

26-line shell recipe pulls, rewrites flake.nix, refreshes lockfile, then `if [[ -f justfile ]]; then just; fi` — i.e. runs whatever the default target is in each of 30+ repos. Slow, unpredictable, hard to reason about.

### 8. The recursive walker doesn't deduplicate work across the rcm/repos forest

It tracks `visited` per-run, but every full run still re-evaluates many overlapping flakes.

## Proposed reworks (not yet committed to)

In priority order:

### A. Move SHAs out of flake.nix and into the .git-sha files as the single source of truth

Have flake.nix read them via `lib.fileContents ./nixpkgs-git-master.git-sha` (or `builtins.readFile` with a `lib.removeSuffix "\n"`). Then bumping is just `update-nixpkgs && nix flake update && nix build`. No `fh add`, no recursive rewriter, no hidden state, no FlakeHub round-trip, no grep-based detection. The eng repo becomes the canonical pin and `flake.lock` follows naturally. Constraint: trailing newline handling.

### B. Replace `update-nixpkgs` + `update-nix` with one `bump-nixpkgs` recipe that:

1. Fetches SHAs (current update-nixpkgs)
2. `nix flake update`
3. `nix build` to verify
4. Diffs old vs new versions of a few sentinel packages (`fish`, `git`, `claude-code`) and prints `name: oldver → newver`
5. Stages but doesn't commit — leaves the diff for human review

### C. Fix the `update` mega-recipe

Either include the actual bump step or rename it to something honest like `pull-everything`.

### D. Delete `nixpkgs-stable-darwin-git.git-sha`

Unless someone wants to actually wire it up. CLAUDE.md says it exists, but nothing reads it.

### E. Decouple repos/ updates from eng/ updates entirely

Each repo has its own flake and its own bump cadence. The current `_update-repo-full` recipe is a footgun — it auto-commits + pushes lockfile changes across every repo with no per-repo verification. Remove the auto-push and let each repo's own CI / human review handle it.

### F. Stop running `just` (default) in every repo from `_update-repo-full`

That's the line most likely to nuke an afternoon. Either make it explicit (`just build-nix` only) or drop it.

## The big lever

**A** is the dominant simplification — once SHAs live in the .git-sha files and flake.nix reads them, almost everything else simplifies or disappears. **B** is mostly justfile glue on top. **C**, **D**, **E**, **F** are independent cleanups that can land separately.

## Open question

Should the bump recipe build *all* outputs (eng + every repo flake reachable from inputs) or just the top-level eng flake? The current `update-nix` walks every flake; the proposed `bump-nixpkgs` only touches the top one. There's a middle ground: bump eng's pin, build eng (which builds everything that uses pkgs-master), and only walk repos/ as a separate explicit action.
