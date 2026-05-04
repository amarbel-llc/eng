# Conditional caldav plugin in mkCircus

## Problem

`lib/circus.nix` always bundles the caldav clown plugin into the eng circus
(`basePlugins` at `lib/circus.nix:27-44`). On hosts that don't have the caldav
secret store provisioned, `clown` still loads the caldav plugin and waits out
its startup timeout before continuing — visible as a several-second hang on
every `clown` invocation. We want per-host opt-out.

## Goals

- Per-host opt-out of the caldav clown plugin via the existing identity
  mechanism, mirroring the pattern used for `identity.piggyGuid` in
  `home/linux.nix:20` and `home/darwin.nix:15`.
- Default-on: hosts with no `enableCaldav` field in their identity continue to
  receive caldav exactly as today.
- Identity reading stays home-manager-scoped — no top-level flake changes, no
  pollution of pure-eval flake-check paths.
- The standalone `inputs.bob.packages.${system}.caldav` binary stays installed
  on every host. Only the *clown plugin slot* is gated.

## Non-goals

- Gating the caldav binary itself. Binary availability is not a blocker; ad-hoc
  invocation of `caldav` outside clown should keep working on every host.
- A general "conditional plugin" framework. One flag for one plugin today; if
  more conditional plugins arrive later, generalize then.
- Changes to `bin/bootstrap-identity.mjs`. New identities omit the field, which
  correctly takes the default-on path.

## Design

### 1. Add `enableCaldav` parameter to `lib/circus.nix`

```nix
{
  pkgs,
  inputs,
  engSelf,
  system,
  extraPlugins ? [ ],
  enableCaldav ? true,
}:
let
  engPlugin = pkgs.runCommand "eng-plugin" { } '' ... '';
  engPluginFlake = { ... };

  caldavPlugin = {
    flake = {
      packages.${system}.default = inputs.bob.packages.${system}.caldav;
      rev = inputs.bob.rev or inputs.bob.dirtyRev or "dirty";
    };
    dirs = [ "share/purse-first/caldav" ];
  };

  basePlugins = [
    { flake = inputs.moxy;      dirs = [ "share/purse-first/moxy" ]; }
    { flake = inputs.spinclass; dirs = [ "share/purse-first/spinclass" ]; }
    { flake = engPluginFlake;   dirs = [ "share/purse-first/eng" ]; }
  ] ++ lib.optional enableCaldav caldavPlugin;
  ...
}
```

Notes:

- The default `enableCaldav ? true` preserves current behavior for every
  existing call site (flake top-level, eng-* overlays).
- Caldav is moved out of the inline `basePlugins` literal and into a named
  `caldavPlugin` binding so the `lib.optional` gate is one obvious line.
- The `inputs.bob.packages.${system}.caldav` reference still evaluates
  unconditionally (it's just a value in scope), but the resulting plugin entry
  is only included when the flag is on. This is intentional — keeping the
  reference unconditional lets `lib/circus.nix` stay agnostic to whether `bob`
  is a "needed" input.

### 2. New `home/circus.nix` module

```nix
{
  identity,
  inputs,
  pkgs,
  system,
  ...
}:
{
  _module.args.engCircus = (import ../lib/circus.nix {
    inherit pkgs inputs system;
    engSelf = inputs.self;
    enableCaldav = identity.enableCaldav or true;
  }).circus.packages.default;
}
```

Exposes `engCircus` as a module arg so `home/repo-packages.nix` can consume it
without re-importing `lib/circus.nix` itself.

Wired into both `home/linux.nix` and `home/darwin.nix` via their `imports`
list, the same way `home/piggy-agent.nix` is wired in.

### 3. Update `home/repo-packages.nix`

Replace `inputs.self.packages.${system}.circus` (line 61) with the new
`engCircus` module arg.

```nix
{ engCircus, ... }: {
  home.packages = [
    ...
    engCircus  # was: inputs.self.packages.${system}.circus
  ];
}
```

`inputs.self.packages.${system}.circus` is left in place at the flake-output
level — `nix run`, CI, and eng-* overlays continue to consume the caldav-on
default.

### 4. Per-host opt-out

Hosts without caldav secrets edit their identity file:

- Linux: `~/.config/identity.nix` adds `enableCaldav = false;`
- Darwin: `/etc/nix-darwin/identity.json` adds `"enableCaldav": false`

Then run `just build-home`. No code changes; no commits.

## Rollback

Single-step: remove the `enableCaldav = false;` line from the host's identity
file and run `just build-home`. The default-on path takes over, caldav is
back.

If the flag-introduction itself misbehaves (e.g. an eval error in
`home/circus.nix`), `git revert` the introducing commit. The three changed
files (`lib/circus.nix`, new `home/circus.nix`, `home/repo-packages.nix`) are
self-contained — no other code depends on the new wiring.

Dual-architecture period and promotion criteria are not applicable: this
change is strictly additive with a backward-compatible default. Old behavior
is the default; hosts opt out individually at their own pace, and there is no
"new world" to promote to.

## Verification

- **Caldav-off host** (e.g. a host without secrets): set
  `enableCaldav = false;`, run `just build-home`, run `clown` and confirm the
  caldav-startup timeout no longer occurs.
- **Default host** (no `enableCaldav` field): run `just build-home` before and
  after the change. The home-manager-installed circus derivation should hash
  identically. Verify with `nix path-info --json
  /etc/profiles/per-user/$USER/bin/clown` (or the eng circus derivation
  output) before and after — paths should match on default hosts.
- **Pure flake check**: `nix flake check` (without `--impure`) still passes.
  No new top-level identity reads.
- **eng-* overlay compat**: an overlay that imports `lib/circus.nix` and
  passes only `extraPlugins` (without specifying `enableCaldav`) still
  produces a caldav-on circus.

## Files touched

- `lib/circus.nix` — add `enableCaldav ? true` parameter; restructure
  `basePlugins` to use `lib.optional`.
- `home/circus.nix` — **NEW**. Re-import `lib/circus.nix` with the per-host
  flag and expose the result as a `_module.args.engCircus`.
- `home/linux.nix` — add `./circus.nix` to `imports`.
- `home/darwin.nix` — add `./circus.nix` to `imports`.
- `home/repo-packages.nix` — accept `engCircus` module arg; replace
  `inputs.self.packages.${system}.circus` reference (line 61).
