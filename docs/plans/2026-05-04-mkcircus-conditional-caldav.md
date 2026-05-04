# Conditional caldav plugin in mkCircus — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use eng:subagent-driven-development to implement this plan task-by-task.

**Goal:** Add a per-host `identity.enableCaldav` flag (default `true`) that, when `false`, drops the caldav clown plugin from the eng circus on that host — eliminating the clown plugin-startup timeout on hosts without caldav secrets.

**Architecture:** Add `enableCaldav ? true` parameter to `lib/circus.nix`. New `home/circus.nix` module re-imports `lib/circus.nix` per-host with `enableCaldav = identity.enableCaldav or true` and exposes the result as a `_module.args.engCircus`. `home/repo-packages.nix` consumes that module arg instead of `inputs.self.packages.${system}.circus`. The flake-output-level circus stays caldav-on for `nix run`/CI/eng-* overlays.

**Tech Stack:** Nix flakes, home-manager, nix-darwin, the existing identity mechanism (`/etc/nix-darwin/identity.json` on macOS, `~/.config/identity.nix` on Linux), `lib.optional` for conditional list elements.

**Rollback:** `git revert` the introducing commits — three files change (`lib/circus.nix`, new `home/circus.nix`, `home/repo-packages.nix`) plus two one-line wires (`home/linux.nix`, `home/darwin.nix`). For per-host opt-out reversal, delete `enableCaldav = false;` from the host's identity file and run `just build-home`.

**Design doc:** `docs/plans/2026-05-04-mkcircus-conditional-caldav-design.md`

---

## A note on verification in a Nix-config repo

There are no unit tests for `lib/circus.nix` or the home-manager modules. The
semantic check we actually care about — "is the caldav plugin wired in?" — is
directly observable from a built circus derivation: `nix path-info -r
<circus-path> | grep -- '-caldav-'` returns a hit if and only if `bob`'s
caldav package is part of the closure.

That gives us three direct semantic checks:

| Condition                              | Closure contains `-caldav-` |
|----------------------------------------|----------------------------|
| Default-flag host (no `enableCaldav`)  | yes                        |
| `enableCaldav = false`                 | no                         |
| `enableCaldav = true`                  | yes                        |

Plus the standard build-doesn't-break checks (`nix flake check`, the actual
home-manager rebuild).

The flag-off case is verified operationally on a real target host (Task 3) —
flip the flag, rebuild, observe the closure no longer contains caldav and
clown's plugin-startup timeout is gone.

---

## Task 1: Add `enableCaldav` parameter to `lib/circus.nix`

**Promotion criteria:** N/A. Default-on preserves current behavior.

**Files:**
- Modify: `lib/circus.nix`

**Step 1: Add the parameter and refactor `basePlugins`**

Open `lib/circus.nix`. Replace the entire file contents with:

```nix
# Build the eng circus (clown wrapper + bundled plugins) for a given system.
# Imported by ~/eng/flake.nix directly, and by ~/eng-* overlays that want
# to add extra plugins on top of the base eng plugin set.
{
  pkgs,
  inputs,
  engSelf,
  system,
  extraPlugins ? [ ],
  enableCaldav ? true,
}:
let
  inherit (pkgs) lib;

  engPlugin = pkgs.runCommand "eng-plugin" { } ''
    mkdir -p $out/share/purse-first
    cp -r ${../plugins/eng} $out/share/purse-first/eng
  '';

  engPluginFlake = {
    packages.${system}.default = engPlugin;
    rev = engSelf.rev or engSelf.dirtyRev or "dirty";
  };

  caldavPlugin = {
    flake = {
      packages.${system}.default = inputs.bob.packages.${system}.caldav;
      rev = inputs.bob.rev or inputs.bob.dirtyRev or "dirty";
    };
    dirs = [ "share/purse-first/caldav" ];
  };

  basePlugins = [
    {
      flake = inputs.moxy;
      dirs = [ "share/purse-first/moxy" ];
    }
    {
      flake = inputs.spinclass;
      dirs = [ "share/purse-first/spinclass" ];
    }
    {
      flake = engPluginFlake;
      dirs = [ "share/purse-first/eng" ];
    }
  ]
  ++ lib.optional enableCaldav caldavPlugin;

  circus = inputs.clown.lib.${system}.mkCircus {
    plugins = basePlugins ++ extraPlugins;
  };
in
{
  inherit circus engPlugin;
}
```

Notes:
- `enableCaldav ? true` is the only new parameter. Default preserves
  current behavior.
- `caldavPluginFlake` is renamed `caldavPlugin` because it is now the full
  plugin entry (flake + dirs), not just the flake half. This keeps the
  `lib.optional` line readable.
- `lib` is bound from `pkgs.lib` to call `lib.optional` (previously not used in
  this file).

**Step 2: Verify pure-eval flake check still passes**

Run: `nix flake check --no-build`
Expected: no errors. Pure-eval paths must still work; we did not introduce any
new top-level identity reads.

**Step 3: Verify default-flag circus still includes caldav**

Run:
```bash
circus_path="$(nix build .#circus --impure --no-link --print-out-paths)"
nix path-info -r "$circus_path" | grep -- '-caldav-'
```
Expected: at least one matching line — `bob`'s caldav derivation is in the
closure, confirming the default-on path still wires it through.

If `grep` exits non-zero (no match): the refactor accidentally dropped caldav
from the default path. Re-inspect `basePlugins` and the `lib.optional` clause
in `lib/circus.nix` — the default `enableCaldav ? true` should keep caldav in.

**Step 4: Stage and commit**

```bash
git add lib/circus.nix
git commit -m "lib/circus: add enableCaldav parameter (default true)

Default-on preserves current behavior at every existing call site
(flake.nix top-level, eng-* overlays). Subsequent commits will wire
this through home-manager so per-host identity can opt out.

:clown: https://github.com/amarbel-llc/clown"
```

---

## Task 2: Create `home/circus.nix` module

**Promotion criteria:** N/A.

**Files:**
- Create: `home/circus.nix`
- Modify: `home/linux.nix`
- Modify: `home/darwin.nix`

**Step 1: Write `home/circus.nix`**

Create `home/circus.nix` with this exact content:

```nix
# Per-host eng circus, gated on identity.enableCaldav.
#
# Re-imports lib/circus.nix with the per-host flag and exposes the
# resulting clown wrapper as the module arg `engCircus`, consumed by
# home/repo-packages.nix.
#
# The flake-output-level circus (self.packages.${system}.circus,
# defined in flake.nix via lib/circus.nix) stays caldav-on so
# `nix run`, CI, and eng-* overlays are unaffected.
{
  identity,
  inputs,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  engCircusBundle = import ../lib/circus.nix {
    inherit pkgs inputs system;
    engSelf = inputs.self;
    enableCaldav = identity.enableCaldav or true;
  };
in
{
  _module.args.engCircus = engCircusBundle.circus.packages.default;
}
```

**Step 2: Add the import to `home/linux.nix`**

Open `home/linux.nix`. In the `imports` list at line 13–22, add `./circus.nix`
right after `./repo-packages.nix`:

```nix
  imports = [
    ./common.nix
    ./repo-packages.nix
    ./circus.nix
  ]
  ++ lib.optionals (!isSshHost) [
    ./ssh-agent-mux.nix
  ]
  ++ lib.optionals (!isSshHost && identity.piggyGuid or null != null) [
    ./piggy-agent.nix
  ];
```

**Step 3: Add the import to `home/darwin.nix`**

Open `home/darwin.nix`. In the `imports` list at line 10–17, add
`./circus.nix` right after `./repo-packages.nix`:

```nix
  imports = [
    ./common.nix
    ./repo-packages.nix
    ./circus.nix
    ./ssh-agent-mux.nix
  ]
  ++ lib.optionals (identity.piggyGuid or null != null) [
    ./piggy-agent.nix
  ];
```

**Step 4: Verify home-manager evaluates**

On Linux:
Run: `nix eval .#homeConfigurations.linux.config.home.username --impure --raw`
Expected: prints your username (the home-manager config evaluates without
errors).

On Darwin (skip on Linux):
Run: `nix eval .#darwinConfigurations.<hostname>.config.system.primaryUser --impure --raw`
Expected: prints your username.

If either fails with "infinite recursion" or "missing argument": the
`_module.args.engCircus` declaration is correct — re-check `home/circus.nix`
for typos in the parameter list.

**Step 5: Verify pure-eval flake check still passes**

Run: `nix flake check --no-build`
Expected: no errors.

**Step 6: Stage and commit**

```bash
git add home/circus.nix home/linux.nix home/darwin.nix
git commit -m "home/circus: per-host engCircus module arg gated on identity.enableCaldav

Re-imports lib/circus.nix with enableCaldav from identity, exposes the
resulting clown wrapper as _module.args.engCircus. No consumer yet — the
next commit switches home/repo-packages over.

:clown: https://github.com/amarbel-llc/clown"
```

---

## Task 3: Switch `home/repo-packages.nix` to consume `engCircus`

**Promotion criteria:** N/A.

**Files:**
- Modify: `home/repo-packages.nix`

**Step 1: Add `engCircus` to the parameter list**

Open `home/repo-packages.nix`. At line 1–6 the current header is:

```nix
{
  inputs,
  pkgs,
  lib,
  ...
}:
```

Change it to:

```nix
{
  inputs,
  pkgs,
  lib,
  engCircus,
  ...
}:
```

**Step 2: Replace the circus reference**

In `home/repo-packages.nix`, find this line (around line 61):

```nix
      inputs.self.packages.${system}.circus
```

Replace it with:

```nix
      engCircus
```

**Step 3: Update the surrounding comment** (lines 55–59 currently)

The comment block above the moxy/circus lines references how circus is
sourced. Update it to reflect the per-host construction. Replace this:

```nix
      # moxy and clown are excluded from the auto-imported repoPackages
      # (see home/non-repo-inputs.nix). moxy is consumed directly here;
      # clown comes in via circus, which is the eng-composed mkCircus
      # bundle (clown wrapper + moxy/spinclass/caldav/eng plugins),
      # exposed as self.packages.${system}.circus by flake.nix.
```

…with this:

```nix
      # moxy and clown are excluded from the auto-imported repoPackages
      # (see home/non-repo-inputs.nix). moxy is consumed directly here;
      # clown comes in via engCircus, the per-host eng-composed mkCircus
      # bundle (clown wrapper + moxy/spinclass/eng plugins, plus caldav
      # when identity.enableCaldav is true). engCircus is supplied by
      # home/circus.nix as a module arg.
```

**Step 4: Verify home-manager evaluates**

On Linux:
Run: `nix eval .#homeConfigurations.linux.config.home.packages --impure --apply 'pkgs: builtins.length pkgs'`
Expected: prints an integer (the package count). No errors.

On Darwin: replace with the corresponding `darwinConfigurations` path.

**Step 5: Verify default-flag home-manager-installed clown still includes caldav**

On a default-flag host (no `enableCaldav` field in identity), the
home-manager-installed clown wrapper's closure must still include caldav.

On Linux:
```bash
home_path="$(nix eval .#homeConfigurations.linux.config.home.path --impure --raw)"
nix path-info -r "$home_path" | grep -- '-caldav-'
```

On Darwin: replace with the darwin equivalent (`darwinConfigurations.<hostname>.config.home-manager.users.<username>.home.path`).

Expected: at least one matching line.

If empty: the wiring is dropping caldav even with the default flag. Re-inspect:
- `home/circus.nix` reads `identity.enableCaldav or true` (the `or true` is
  present).
- `lib/circus.nix` defaults `enableCaldav ? true`.
- `home/repo-packages.nix` consumes `engCircus`.

**Step 6: Run a real home-manager build**

Run: `just build-home`
Expected: build completes successfully.

**Step 7: Stage and commit**

```bash
git add home/repo-packages.nix
git commit -m "home/repo-packages: consume per-host engCircus module arg

Was: inputs.self.packages.\${system}.circus (always caldav-on).
Now: engCircus from home/circus.nix (gated on identity.enableCaldav).

The flake-output-level circus is unchanged for nix run / CI / eng-*
overlays.

:clown: https://github.com/amarbel-llc/clown"
```

---

## Task 4: Operational verification on a caldav-off host

**Promotion criteria:** N/A.

**Files:** none modified by this repo. Identity files are per-host config.

**Step 1: Identify a host without caldav secrets**

Pick a host where `clown` currently shows the caldav-startup timeout. This is
the verification target.

**Step 2: Edit the host's identity file**

On Linux: edit `~/.config/identity.nix` and add `enableCaldav = false;` to the
attribute set.

On Darwin: edit `/etc/nix-darwin/identity.json` (requires `sudo`) and add
`"enableCaldav": false` to the JSON object.

**Step 3: Rebuild home-manager**

Run: `just build-home`
Expected: build succeeds.

**Step 4: Verify the caldav plugin is gone from the closure**

Run:
```bash
nix path-info -r "$(readlink -f $(which clown))" | grep -- '-caldav-'
```
Expected: `grep` exits non-zero (no match). The home-manager-installed clown
wrapper no longer pulls caldav into its closure.

**Step 5: Verify the operational symptom is gone**

Run: `clown --help` (or whatever the user's habitual clown invocation is —
the original symptom was the startup hang).
Expected: starts without the multi-second caldav plugin-startup timeout.

**Step 6: Reverse-rollback test**

Confirm the rollback path works: remove the `enableCaldav = false;` line,
run `just build-home`, then re-run the closure check from Step 4 — this time
expecting at least one `-caldav-` match.

After confirming, restore the `enableCaldav = false;` line if this is the
desired steady state for that host.

**Step 7: No commit**

Identity file edits are per-host config, not tracked in this repo.

---

## Task 5 (optional): Document the new identity field

**Promotion criteria:** N/A.

**Files:**
- Modify: `AGENTS.md`
- Modify: `doc/eng.7.scd` (only if eng-the-manpage describes identity fields)

**Step 1: Decide whether to document**

Check whether `AGENTS.md` and `doc/eng.7.scd` already enumerate identity
fields. If they only describe identity at a high level (username, home
directory) without listing optional flags like `piggyGuid` or `isSshHost`,
**skip this task** — adding only `enableCaldav` would be inconsistent.

If they do enumerate optional fields, add an entry for `enableCaldav` next to
`piggyGuid`, with one-line semantics: *"set `false` to drop the caldav clown
plugin from the per-host eng circus; defaults to `true`"*.

**Step 2: Stage and commit** (only if changes were made)

```bash
git add AGENTS.md doc/eng.7.scd
git commit -m "docs: document identity.enableCaldav

:clown: https://github.com/amarbel-llc/clown"
```

---

## Final verification checklist

Before considering the work complete:

- [ ] After Task 1: `nix build .#circus` succeeds and the closure contains
  `-caldav-` (default-on path preserved).
- [ ] After Task 3: home-manager-installed clown's closure contains
  `-caldav-` on a default-flag host.
- [ ] `nix flake check --no-build` passes (pure eval still works).
- [ ] On a target caldav-off host: `enableCaldav = false;` plus `just
  build-home` removes `-caldav-` from the closure and eliminates the
  clown plugin-startup timeout.
- [ ] Reverse rollback (remove the line, rebuild) restores `-caldav-` to
  the closure.
