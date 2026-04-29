# Switch from pivy-agent to piggy on the eng dev boxes

**Status:** BLOCKED on amarbel-llc/piggy#60 and #61 (v1.0 parity gaps).
Implementation cannot begin until both close.
**Captured:** 2026-04-29
**Trigger:** piggy-agent's home-manager module landed
(amarbel-llc/piggy#52), and `piggy agent` itself wraps C `pivy-agent`
post-`79658e1`. We can swap the `services.pivy-agent` module for
`services.piggy-agent` on this dev box and the macOS laptop without
changing the underlying C agent. The mux + SSH config layers above can
stay flat through the swap.
**Targets:** Linux dev box (this machine), macOS laptop.
**Strategy:** Path A — block the eng rollout on upstream piggy
parity. The eng integration is v1.0's integration test for the
home-manager module; if the integration target needs per-user
workarounds, v1.0 isn't done.

## v1.0 parity blockers

These are the hard preconditions. The eng rollout cannot start until
both close.

- **#60** — `services.piggy-agent` does not propagate `SSH_ASKPASS` /
  `SSH_ASKPASS_REQUIRE` to `home.sessionVariables`. Site 1 of the
  SSH_ASKPASS contract.
- **#61** — `services.piggy-agent` agent-process env does not export
  `SSH_CONFIRM` / `SSH_NOTIFY_SEND`. Site 2 of the SSH_ASKPASS
  contract.

Both on milestone v1.0.0 (#4). Sister-issue cross-link in each.

## Current state

Three layers, both platforms:

| layer | socket | manager | source |
|---|---|---|---|
| pivy-agent (PIV hw) | `~/.local/state/ssh/pivy-agent.sock` | systemd user (Linux) / launchd `net.cooperi.pivy-agent` (Darwin) | `home/pivy-agent.nix` |
| ssh-agent-mux | `~/.local/state/ssh/mux-agent.sock` | systemd user / launchd `net.ross-williams.ssh-agent-mux` | `home/ssh-agent-mux.nix` |
| (Darwin only) launchd built-in ssh-agent | `~/.local/state/ssh/launchd-agent.sock` | macOS | `home/fish.nix` interactive init symlinks `launchctl getenv SSH_AUTH_SOCK` |

Mux multiplexer config at `~/.config/ssh-agent-mux/ssh-agent-mux.toml`
(rcm-deployed, not nix-managed) lists one upstream agent named `pivy`
pointing at `pivy-agent.sock`.

Shell env (`rcm/env`):

```
export PIVY_AUTH_SOCK="$HOME/.local/state/ssh/pivy-agent.sock"
export SSH_AUTH_SOCK="$HOME/.local/state/ssh/mux-agent.sock"
```

`bin/bootstrap-identity.bash:27` reads keys from `PIVY_AUTH_SOCK` to
populate the `gitSigningKey` field; SSH commit-signing routes through
SSH-agent (`key::ssh-…` format), so the same hardware that authenticates
SSH also signs git.

`flake.nix` already declares `inputs.piggy` (locked at `79658e1`,
which has the wrap-C-pivy posture). `repos/piggy/flake.nix` exports
`homeManagerModules.piggy-agent` and `nixosModules.piggy-agent`.

`home/linux.nix` imports `pivy-agent.nix` only when `!isSshHost`;
`home/darwin.nix` always imports it. Whatever this plan proposes
should preserve the `isSshHost` gate.

## What "switching to piggy" means

Two distinct things are bundled in the user-facing phrase:

1. **Service-management swap.** Replace
   `home/pivy-agent.nix` with the upstream
   `services.piggy-agent` home-manager module from the piggy flake.
   The launcher logic (socket cleanup, askpass wiring, multi-instance
   support) is now maintained as part of piggy's own release surface
   instead of forked locally.
2. **Dispatch-layer addition.** The `services.piggy-agent` module
   defaults to `package = pkgs.piggy`, which routes through `piggy
   agent`'s clap layer before exec'ing C `pivy-agent`. The clap
   prelude is a no-op for the agent process itself (it just
   exec(3)s) — the layer's value is consistency with the rest of
   the `piggy <X>` surface and a single place to add agent-side
   piggy features later (e.g. when #58 / #59 maturation lands and
   the Rust agent becomes the dispatch target).

Both can land independently; (1) is the high-value change. (2) costs
one extra exec at boot.

## SSH_ASKPASS contract — must not regress

Today's askpass surface lives in three distinct places. Naïvely
dropping `home/pivy-agent.nix` will silently lose env vars that
downstream binaries read; the failure mode is a surprise GUI dialog
landing on the desktop instead of the configured pivy-askpass —
exactly the escape we already mitigated for the test harness in #35.

**Site 1: User-shell env (`home.sessionVariables`).**
`home/pivy-agent.nix` today exports:

- `SSH_ASKPASS = ${pivy}/libexec/pivy/pivy-askpass`
- `SSH_ASKPASS_REQUIRE = force`

These reach every interactive shell and any process the shell
launches. Piggy's module sets only `home.sessionVariables.SSH_AUTH_SOCK`
(in single-instance mode) — nothing askpass-related.

**Resolution:** filed as upstream piggy issue **#60** (v1.0 parity
blocker). Once closed, setting `services.piggy-agent.askpass = …`
will mirror to `home.sessionVariables` automatically; `home/piggy-
agent.nix` does not carry a workaround.

**Site 2: Agent-process env (systemd `Service.Environment` / launchd
`EnvironmentVariables`).** Today the agent itself sees four askpass-
adjacent vars:

- `SSH_ASKPASS` (= pivy-askpass)
- `SSH_ASKPASS_REQUIRE` (= force)
- `SSH_CONFIRM` (= pivy-askpass)
- `SSH_NOTIFY_SEND` (= pivy-notify)

Piggy's launcher script exports `SSH_ASKPASS` and `SSH_ASKPASS_REQUIRE`
(when `services.piggy-agent.askpass` is set) and nothing else. The
last two are pivy-agent-specific and are NOT modeled by the piggy
module's option set today.

**Resolution:** filed as upstream piggy issue **#61** (v1.0 parity
blocker). The recommended fix is two new first-class module options
(`confirm`, `notifySend`) modeling these as proper pivy-agent surface
area; the launcher script then exports them. `home/piggy-agent.nix`
sets the options; no per-user `Service.Environment` / launchd
`EnvironmentVariables` override.

**Site 3: SSH_AUTH_SOCK ordering.** Piggy's module sets
`home.sessionVariables.SSH_AUTH_SOCK = piggy-agent.sock` when
`instances` is empty. `rcm/env` sets `SSH_AUTH_SOCK = mux-agent.sock`.
The user wants the mux value, not the upstream-agent value. Resolution
depends on which file the user shell sources later. The clean fix is
to USE the module's multi-instance mode so it does not touch
`SSH_AUTH_SOCK` at all:

```nix
services.piggy-agent.instances.default = {
  guid = …;
  socketPath = "$HOME/.local/state/ssh/pivy-agent.sock";
  askpass = "${pkgs.pivy}/libexec/pivy/pivy-askpass";
  confirm = "${pkgs.pivy}/libexec/pivy/pivy-askpass";    # post-#61
  notifySend = "${pkgs.pivy}/libexec/pivy/pivy-notify";  # post-#61
};
```

Effect: unit name becomes `piggy-agent-default` (cosmetic), and the
module's `home.sessionVariables.SSH_AUTH_SOCK` block is skipped
entirely (`lib.mkIf (!hasInstances)` short-circuits). `rcm/env` keeps
sole control over the user-facing `SSH_AUTH_SOCK`. This is a
documented module behavior, not a parity gap; not filed against
piggy.

**Phase 1 step 5 askpass-regression checklist** (added to the existing
verification list — see Phases below):

- `env | rg ^SSH_` in a fresh shell shows the same four
  `SSH_ASKPASS*`/`SSH_CONFIRM`/`SSH_NOTIFY_SEND` values as before
  the swap, plus the same `SSH_AUTH_SOCK = mux-agent.sock`.
- `cat /proc/$(pgrep -f piggy-agent)/environ | tr '\0' '\n' | rg ^SSH_`
  on Linux (or the launchd equivalent on Darwin: `launchctl print
  gui/$(id -u)/<label> | rg SSH_`) shows the same four agent-side
  vars as the previous pivy-agent process did.
- A deliberate **failed** unlock attempt (e.g. wrong PIN via the
  test harness askpass set as `SSH_ASKPASS=…/piggy-test-askpass.sh`
  briefly) renders a `[piggy-test-askpass]`-prefixed banner on
  stderr — NOT a GUI dialog. This is the escape-detection path
  from amarbel-llc/piggy#35. If a GUI dialog appears, `SSH_ASKPASS_
  REQUIRE=force` is not propagating; STOP and roll back.

## Design choice: socket path

The single highest-leverage decision. The mux config, `rcm/env`,
`bootstrap-identity.bash`, and SSH config (`ForwardAgent` to the mux,
which forwards to whatever upstream agent owns each key) all
hardcode `pivy-agent.sock`.

Three options:

### Option X — keep `pivy-agent.sock`, just change who listens (recommended)

Configure the new module:

```nix
services.piggy-agent.instances.default = {
  guid = …;  # see Phase 0 — pick from current pivy-agent state
  socketPath = "$HOME/.local/state/ssh/pivy-agent.sock";
  askpass = "${pkgs.pivy}/libexec/pivy/pivy-askpass";
  confirm = "${pkgs.pivy}/libexec/pivy/pivy-askpass";    # post-#61
  notifySend = "${pkgs.pivy}/libexec/pivy/pivy-notify";  # post-#61
};
```

Use multi-instance shape (per "SSH_AUTH_SOCK ordering" above) so the
module does not touch the user-facing `SSH_AUTH_SOCK`. Mux config
unchanged. `PIVY_AUTH_SOCK` env unchanged.
`bootstrap-identity.bash` unchanged. SSH config unchanged. Cutover
is one home-manager switch; rollback is one revert + switch.

The semantic mismatch (the file is called `pivy-agent.sock` but
piggy is the listener) lives in one place — the home-manager module
config — and is removed in Phase 3.

### Option Y — rename to `piggy-agent.sock` (planned end-state, gated on Phase 1+2 stability)

Use the module's default socket
(`$XDG_STATE_HOME/piggy/piggy-agent.sock`). Touches:

- `~/.config/ssh-agent-mux/ssh-agent-mux.toml` — change the upstream
  agent's `socket-path` (and rename `name = "pivy"` → `"piggy"` to
  reflect reality).
- `rcm/env` — rename `PIVY_AUTH_SOCK` → `PIGGY_AUTH_SOCK`, or add
  the new var alongside and keep the old as an alias for a
  transition window.
- `bin/bootstrap-identity.bash` — read from the new var.
- `bin/bootstrap-identity.mjs` — same.
- `doc/eng-ssh.7.scd` — describe the new socket layout.
- Any remote dev box that talks back into the mux config (rcm
  deploys this file) needs the rename too.

Cleaner end-state, more moving parts, more places a half-rolled-out
state can hide. Not optional — this is the planned end-state — but
the swap risk is loaded into Phase 1 and Phase 2; this is the cleanup
once we know the new agent is stable.

### Option Z — parallel-run

Run both `pivy-agent` and `piggy-agent` for a verification window;
add a second upstream entry in the mux config so the keys are
visible from either path; observe; then remove pivy-agent.

Safest if we worry about lock-up scenarios; adds a third agent
process and a non-trivial mux config edit. Skip unless Phase 1
surfaces something surprising.

**Recommendation: Option X for the cutover; Option Y is the planned
end-state, gated only on Phase 1+2 stability; Option Z as escape
hatch.**

## Phases

### Phase 0 — Preconditions

Read-only / no-mutation work to derisk the actual swap.

- [ ] **#60 closed** (services.piggy-agent emits SSH_ASKPASS /
  SSH_ASKPASS_REQUIRE in home.sessionVariables when askpass is set).
- [ ] **#61 closed** (services.piggy-agent emits SSH_CONFIRM /
  SSH_NOTIFY_SEND in agent-process env via first-class options).
- [ ] `nix flake update piggy` in `~/eng` to pick up the post-fix
  piggy SHA. Verify `nix flake metadata` shows the expected SHA.
- [ ] Confirm the piggy flake exports the package attribute we'll
  pin to. Likely `inputs.piggy.packages.${system}.piggy`. Verify
  with `nix eval .#inputs.piggy.packages.${currentSystem} --apply
  builtins.attrNames`.
- [ ] Capture the current pivy-agent's GUID (use `pivy-tool list`
  and read the active card's GUID). The new
  `services.piggy-agent.instances.default.guid` pins to this exact
  hex.
- [ ] Snapshot the current mux state: `ssh-add -l` against
  `mux-agent.sock` and `pivy-agent.sock` separately. The post-swap
  output of each should be identical.
- [ ] Confirm `journalctl --user -u pivy-agent -n 20` (Linux) or
  the launchd log (Darwin) shows clean recent operation; we don't
  want to inherit a confused state.
- [ ] **Capture pivy-agent's full env.** Linux: `cat /proc/$(pgrep
  -f pivy-agent)/environ | tr '\0' '\n' | rg ^SSH_ > /tmp/pivy-
  agent-env-before`. Darwin: equivalent via `launchctl print
  gui/$(id -u)/net.cooperi.pivy-agent | rg SSH_`. The new agent's
  env MUST contain the same four `SSH_ASKPASS*`/`SSH_CONFIRM`/
  `SSH_NOTIFY_SEND` strings (point-by-point) once the new module
  options from #60/#61 are wired.
- [ ] **Verify multi-instance evaluates as expected.** Build an
  off-system test of `services.piggy-agent.instances.default = …`
  per Option X via `just test-nix-hm-module` (the smoke recipe
  amarbel-llc/piggy ships) and confirm: unit name
  `piggy-agent-default`, no `home.sessionVariables.SSH_AUTH_SOCK`
  emitted, the SSH_ASKPASS / CONFIRM / NOTIFY_SEND options reach
  the right env destinations.

### Phase 1 — Linux dev box (this machine)

Smallest blast radius. If it breaks, everything's local and revertible.

1. **Add the piggy module import** to `home/linux.nix` next to (not
   instead of) `./pivy-agent.nix`. Wrap in `lib.mkIf
   (!isSshHost)` to match the existing gate.
2. **Write `home/piggy-agent.nix`** with `services.piggy-agent`
   configured per Option X (multi-instance, same socket path as
   pivy-agent.sock). Set `enable = false` initially. Use the module's
   first-class options (post-#60 and post-#61) to set:
   - `askpass = "${pkgs.pivy}/libexec/pivy/pivy-askpass"` —
     propagates to `home.sessionVariables` per #60.
   - `confirm = "${pkgs.pivy}/libexec/pivy/pivy-askpass"` and
     `notifySend = "${pkgs.pivy}/libexec/pivy/pivy-notify"` per
     #61.
   No per-user `home.sessionVariables` overrides, no
   `systemd.user.services.…Service.Environment` overrides — the
   module owns the SSH_* contract end-to-end.
3. **Build and switch with both modules present, piggy disabled.**
   `just build-home && home-manager switch`. This proves the new
   module evaluates; nothing changes at runtime. Confirm
   `home.sessionVariables` did not change (`env | rg ^SSH_`).
4. **Disable pivy-agent + enable piggy-agent in one switch.** Edit
   `home/pivy-agent.nix` to `lib.mkIf false …` (or import-gate from
   `home/linux.nix`); flip `services.piggy-agent.enable = true`.
   `home-manager switch`.
5. **Verify** in this order, BEFORE doing anything else:
   - `systemctl --user status piggy-agent-default` is active.
   - `ls -l ~/.local/state/ssh/pivy-agent.sock` exists and is
     owned by piggy-agent.
   - `SSH_AUTH_SOCK=$HOME/.local/state/ssh/pivy-agent.sock ssh-add
     -L` lists the same keys as before the swap.
   - `ssh-add -l` (against mux) lists the same keys (i.e. the mux
     reconnected to the new listener).
   - **`env | rg ^SSH_` in a fresh shell** shows the same
     `SSH_AUTH_SOCK = mux-agent.sock`, `SSH_ASKPASS`,
     `SSH_ASKPASS_REQUIRE`, `SSH_CONFIRM`, `SSH_NOTIFY_SEND` as
     captured in Phase 0.
   - **`cat /proc/$(pgrep -f piggy-agent)/environ | tr '\0' '\n'
     | rg ^SSH_`** matches the `SSH_*` snapshot from Phase 0.
   - `git commit -S --allow-empty -m smoke` succeeds — gpg-signing
     via SSH agent still works.
   - `ssh <a-real-host>` succeeds with `-v` showing the right
     IdentityAgent (mux-agent.sock).
   - **Failed-unlock smoke test.** Briefly export `SSH_ASKPASS=
     …/piggy-test-askpass.sh` (no `PIGGY_TEST_FIB_PIN`) in a
     subshell and trigger an unlock; confirm a `[piggy-test-
     askpass]`-prefixed stderr banner appears, NOT a GUI dialog.
     If a dialog appears, STOP — `SSH_ASKPASS_REQUIRE=force` is
     not propagating; revert immediately.
6. **24h soak.** Use the box normally. Watch for: PIN-prompt
   loops, askpass dialogs landing in unexpected places, mux
   complaining about missing upstream, slow agent responses.
7. **Tidy.** Once happy, delete `home/pivy-agent.nix`, drop the
   import from `home/linux.nix`, replace with a link from
   `home/linux.nix` to `home/piggy-agent.nix`. Single
   home-manager switch confirms the file removal builds clean.
   Re-run the askpass checklist after the tidy switch.

### Phase 2 — macOS laptop

Same shape; differences:

- Launchd, not systemd. The piggy-agent module synthesizes a
  `launchd.agents.piggy-agent-default` entry; verify it picks up
  `RunAtLoad = true` and `KeepAlive` semantics matching what the
  current `net.cooperi.pivy-agent` plist sets.
- `SSH_CONFIRM` and `SSH_NOTIFY_SEND` flow through the same
  module options that #61 adds — same nix config across both
  platforms; the launcher script and launchd config emit them
  uniformly.
- The `launchd-agent.sock` symlink (macOS built-in ssh-agent) is
  unrelated; leave it alone.
- Re-run all of Phase 1's askpass checklist on the laptop. The
  signed-commit smoke is especially load-bearing here because the
  user's daily macOS workflow includes signed commits through this
  same agent.
- The Phase 1 step 5 env-comparison commands change shape on
  Darwin (no /proc, no journalctl). Use `launchctl print
  gui/$(id -u)/<label>` for unit env, and `defaults write` /
  `plutil -p` against `~/Library/LaunchAgents/<label>.plist` for
  the launchd config snapshot.

### Phase 3 — Option Y rename across the board

Once Phase 1 and Phase 2 have soaked stably (target: at least one
week each), rename to `piggy-agent.sock`:

1. Add `PIGGY_AUTH_SOCK` to `rcm/env` alongside the existing
   `PIVY_AUTH_SOCK` (both point at the new path during transition).
2. Update `bin/bootstrap-identity.{bash,mjs}` to prefer
   `PIGGY_AUTH_SOCK`.
3. Edit `home/piggy-agent.nix` to drop the explicit `socketPath`
   override (let the module use its default
   `$XDG_STATE_HOME/piggy/piggy-agent.sock`).
4. Update the rcm-deployed `ssh-agent-mux.toml` (rename socket
   path, rename agent name from `pivy` to `piggy`) and re-deploy
   via rcm.
5. Update `doc/eng-ssh.7.scd` to describe the new socket and the
   pivy→piggy listener-name change.
6. After a soak window with no incidents, remove `PIVY_AUTH_SOCK`
   and any compatibility symlinks.

## Rollback

For Phases 1 and 2, rollback per machine is one home-manager generation.

- Phase 1 step 4 → step 3: revert the `enable` flip + the
  `mkIf false`, `home-manager switch`. Pivy-agent comes back at the
  same socket; mux reconnects on its next request.
- Phase 1 step 7 (file removal): keep the deletion in a single
  commit so `git revert` restores the file in one step.
- Phase 3 has no operational rollback — it's a config rename. If a
  shell loses both env vars, source `~/eng/rcm/env` again or open a
  new terminal.

The hardware never moves. PIN cache is lost on each agent swap (one
re-unlock per machine), which is the only user-visible cost.

## Risks and known unknowns

- **Askpass wiring drift.** Documented in detail under "SSH_ASKPASS
  contract" above. The four-var contract MUST be preserved; #60 and
  #61 close the upstream gaps so the module owns the contract.
- **`SSH_AUTH_SOCK` ordering.** Documented above. Resolution: use
  the piggy module's multi-instance mode so it does not touch
  the var; `rcm/env` keeps sole control. Verified in Phase 0.
- **PCSC contention.** Switching the agent doesn't change which
  process holds a PC/SC transaction at any given moment, but the
  brief overlap when one agent is stopping and the other starting
  could surface a "card busy" error. Mitigation: pivy-agent's
  systemd unit and the new piggy launcher both `rm -f` the socket
  in pre-start; the OS will hold the new agent until the old one
  has fully exited.
- **SSH known\_hosts and config unchanged.** Verify by reading
  `man ssh_config`'s description of `IdentityAgent` and confirming
  the home-manager-rendered `~/.config/ssh/config` still names
  `mux-agent.sock`.
- **The piggy module's nixosModules export** (#52) is a thin
  re-export targeting `home-manager.sharedModules`. We import the
  home-manager module directly via `homeManagerModules.piggy-agent`
  here, not the nixos one. Confirm that's the intended shape for a
  single-user dev box.
- **isSshHost gate on Linux only.** `home/darwin.nix` imports
  pivy-agent unconditionally. If the laptop is ever used as a
  jumphost (it currently isn't), this asymmetry will surface;
  out-of-scope for this rollout.

## Open questions

1. **Pin the package attribute or trust `pkgs.piggy`.** If the
   piggy flake is imported as an `inputs.piggy` overlay-style flake
   that adds `pkgs.piggy`, the module's default
   (`mkPackageOption pkgs "piggy"`) does the right thing without
   an explicit `package = …`. If not, we need
   `package = inputs.piggy.packages.${system}.piggy`. Verify in
   Phase 0.
2. **`isSshHost` Darwin gate.** If both platforms gain the gate
   uniformly, that's a separate small cleanup that could land
   alongside Phase 2.
3. **Do we want a `services.piggy-agent` instance for tests?** The
   piggy module supports multi-instance via `instances`; could be
   useful if any of the eng repos want a scratch agent instance for
   integration tests. Out of scope for this rollout.

## Acceptance

The migration is "done" when:

- Both machines run `services.piggy-agent`, not
  `home/pivy-agent.nix`.
- `home/pivy-agent.nix` is deleted from the eng repo.
- All verifications in Phase 1 step 5 (including the askpass
  checklist) pass on both machines.
- A signed git commit, an `ssh` to a real host, and `ssh-add -L` all
  work without touching shell init or `home-manager switch` again.
- The four-var SSH askpass contract from "SSH_ASKPASS contract"
  above holds at runtime in both the user shell and the agent
  process — sourced from the piggy module's first-class options,
  not from per-user overrides.

## References

- `home/pivy-agent.nix` — current launcher module (replaces).
- `home/ssh-agent-mux.nix` — multiplexer service, unchanged.
- `repos/piggy/nix/hm/piggy-agent.nix` — upstream module landing.
- `repos/piggy/flake.nix:284` — `homeManagerModules.piggy-agent` export.
- amarbel-llc/piggy#52 — the home-manager module work that closed
  recently.
- amarbel-llc/piggy#54 — wrap-C posture documentation that
  explains why `pkgs.piggy` and `pkgs.pivy` are interchangeable
  agents post-`79658e1`.
- amarbel-llc/piggy#35 — the askpass-escape incident this rollout
  must NOT reproduce.
- **amarbel-llc/piggy#60** — v1.0 parity gap: `SSH_ASKPASS` /
  `SSH_ASKPASS_REQUIRE` in user-shell `home.sessionVariables`. Eng
  rollout blocked.
- **amarbel-llc/piggy#61** — v1.0 parity gap: `SSH_CONFIRM` /
  `SSH_NOTIFY_SEND` in agent-process env. Eng rollout blocked.
- `doc/eng-ssh.7.scd` — current architecture description; needs an
  update at Phase 3 (or a small note now that "pivy-agent" in the
  doc refers to the listener-by-name, which may be `piggy
  agent` after Phase 1).
