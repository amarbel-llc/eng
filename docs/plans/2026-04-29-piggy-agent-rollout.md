# Switch from pivy-agent to piggy on the eng dev boxes

**Status:** READY for Phase 0 (2026-04-29). Both v1.0 parity blockers
landed on amarbel-llc/piggy master earlier today; rollout proceeds
when the operator picks it up.
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

## v1.0 parity blockers (resolved)

These were the hard preconditions. Both closed on 2026-04-29:

- **#60** — `services.piggy-agent` propagates `SSH_ASKPASS` /
  `SSH_ASKPASS_REQUIRE` to `home.sessionVariables` (single-instance
  mode only). Closed by piggy commit `d2374da`. Site 1 of the
  SSH_ASKPASS contract.
- **#61** — `services.piggy-agent` exports `SSH_CONFIRM` /
  `SSH_NOTIFY_SEND` to the agent process via two new first-class
  options (`confirm`, `notifySend`). Closed by piggy commit
  `b3f2b7a`. Site 2 of the SSH_ASKPASS contract.

`b3f2b7a` also refactored the agent-process static env vars
(SSH_ASKPASS, SSH_ASKPASS_REQUIRE, SSH_CONFIRM, SSH_NOTIFY_SEND) off
the launcher script and onto the systemd `Service.Environment` /
launchd `EnvironmentVariables` surface, so they're now inspectable
from a unit query without touching `/proc` or the launchd plist.

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

`flake.nix` already declares `inputs.piggy`; the lock currently
points at `79658e1` (pre-#60/#61). Phase 0 runs `nix flake update
piggy` to pick up `b3f2b7a` (post-fix). `repos/piggy/flake.nix`
exports `homeManagerModules.piggy-agent` and
`nixosModules.piggy-agent`.

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

**Resolution:** **closed** in piggy commit `d2374da` (#60). Setting
`services.piggy-agent.askpass = …` now mirrors to `home.session
Variables.SSH_ASKPASS` and `SSH_ASKPASS_REQUIRE` in single-instance
mode; multi-instance mode skips the propagation parallel to
`SSH_AUTH_SOCK` (the module can't pick a winner). `home/piggy-
agent.nix` does NOT carry a workaround.

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

**Resolution:** **closed** in piggy commit `b3f2b7a` (#61). Two new
first-class module options shipped: `confirm` (=`SSH_CONFIRM`) and
`notifySend` (=`SSH_NOTIFY_SEND`), both top-level and per-instance.
Same commit refactored the static agent-process env vars off the
launcher script onto `systemd.user.services.<unit>.Service.Environment`
(Linux) and `launchd.agents.<unit>.config.EnvironmentVariables`
(Darwin). `home/piggy-agent.nix` sets the options; no per-user
overrides.

**Site 3: SSH_AUTH_SOCK ordering.** Piggy's module sets
`home.sessionVariables.SSH_AUTH_SOCK = piggy-agent.sock` in
single-instance mode (when `instances = {}`). `rcm/env` sets
`SSH_AUTH_SOCK = mux-agent.sock`. The user wants the mux value, not
the upstream-agent value.

We're running ONE pivy-agent (this isn't a multi-instance setup) so
we use single-instance shape and override the module's emission with
`lib.mkForce` to point at the mux socket:

```nix
services.piggy-agent = {
  enable = true;
  guid = …;  # see Phase 0
  socketPath = "$HOME/.local/state/ssh/pivy-agent.sock";
  askpass = "${pkgs.pivy}/libexec/pivy/pivy-askpass";
  confirm = "${pkgs.pivy}/libexec/pivy/pivy-askpass";    # post-#61
  notifySend = "${pkgs.pivy}/libexec/pivy/pivy-notify";  # post-#61
};

# Reclaim SSH_AUTH_SOCK from the module, which would otherwise
# point shells at the upstream pivy-agent socket directly. We want
# shells to talk to the mux above pivy-agent.
home.sessionVariables.SSH_AUTH_SOCK = lib.mkForce
  "$HOME/.local/state/ssh/mux-agent.sock";
```

The override is explicit and survives any shell-init source-order
changes. `SSH_ASKPASS`/`SSH_ASKPASS_REQUIRE` propagation from #60
works as designed in single-instance mode; no extra
`home.sessionVariables` block needed.

The cleaner long-term shape inverts the module's default: piggy
SHOULD NOT claim `home.sessionVariables.SSH_AUTH_SOCK` automatically.
The mux-in-front pattern (ssh-agent-mux multiplexing pivy-agent +
software-keys agent + 1Password agent + …) is common enough that
"the agent's socket is the user's primary `SSH_AUTH_SOCK`" is the
wrong default — it composes badly with every multi-agent setup.
Proposed shape:

```nix
services.piggy-agent.setSshAuthSock = mkOption {
  type = types.bool;
  default = false;  # mux-in-front friendly
  description = ''
    Set `home.sessionVariables.SSH_AUTH_SOCK` to this agent's
    socket. Default false because in mux-in-front setups the mux
    owns the user-facing SSH_AUTH_SOCK and clobbering it from
    here breaks the chain. Set to true if piggy IS the user's
    primary agent (no mux).
  '';
};
```

Users without a mux flip it to `true` and get the same
auto-management the module does today. Users with a mux (or any
multi-agent setup) get the right behavior for free, no
`lib.mkForce` needed.

Tracked as a follow-up piggy issue (sister to #60/#61, same
parity-of-defaults concern, possibly a v1.0 blocker depending on
how aggressive we want to be about shipping the inverted default
before broader adoption). Until that issue lands, the
`lib.mkForce` override above is the right escape hatch.

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

Configure the new module in single-instance shape:

```nix
services.piggy-agent = {
  enable = true;
  guid = …;  # see Phase 0 — pick from current pivy-agent state
  socketPath = "$HOME/.local/state/ssh/pivy-agent.sock";
  askpass = "${pkgs.pivy}/libexec/pivy/pivy-askpass";
  confirm = "${pkgs.pivy}/libexec/pivy/pivy-askpass";    # post-#61
  notifySend = "${pkgs.pivy}/libexec/pivy/pivy-notify";  # post-#61
};

home.sessionVariables.SSH_AUTH_SOCK = lib.mkForce
  "$HOME/.local/state/ssh/mux-agent.sock";
```

The `lib.mkForce` override reclaims `SSH_AUTH_SOCK` from the module's
single-instance default (per "SSH_AUTH_SOCK ordering" above). Mux
config unchanged. `PIVY_AUTH_SOCK` env unchanged.
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

- [x] **#60 closed** in piggy `d2374da` — services.piggy-agent
  emits SSH_ASKPASS / SSH_ASKPASS_REQUIRE in home.sessionVariables
  when askpass is set (single-instance only).
- [x] **#61 closed** in piggy `b3f2b7a` — services.piggy-agent
  emits SSH_CONFIRM / SSH_NOTIFY_SEND on the agent unit's env via
  first-class `confirm` and `notifySend` options. Same commit
  hoisted SSH_ASKPASS* off the launcher onto the unit env.
- [ ] `nix flake update piggy` in `~/eng` to advance from `79658e1`
  → `b3f2b7a` (or whatever master is by the time you do this). Verify
  `nix flake metadata` shows the expected SHA and that the lock file
  diff is just the piggy input.
- [ ] Confirm the piggy flake exports the package attribute we'll
  pin to. Likely `inputs.piggy.packages.${system}.piggy`. Verify
  with `nix eval .#inputs.piggy.packages.${currentSystem} --apply
  builtins.attrNames`.
- [ ] Capture the current pivy-agent's GUID (use `pivy-tool list`
  and read the active card's GUID). The new
  `services.piggy-agent.guid` pins to this exact hex.
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
- [ ] **Verify single-instance + lib.mkForce override evaluates as
  expected.** Build the home-manager generation off-system (or just
  do step 3 of Phase 1 below — the enable=false dry run), and
  confirm the rendered `~/.config/zsh/.zshenv` (or fish equivalent)
  has `SSH_AUTH_SOCK = $HOME/.local/state/ssh/mux-agent.sock`, NOT
  `pivy-agent.sock`. If the override didn't take, home-manager would
  flag a definition conflict — `lib.mkForce` is the priority knob
  that makes our value win.

### Phase 1 — Linux dev box (this machine)

Smallest blast radius. If it breaks, everything's local and revertible.

1. **Add the piggy module import** to `home/linux.nix` next to (not
   instead of) `./pivy-agent.nix`. Wrap in `lib.mkIf
   (!isSshHost)` to match the existing gate.
2. **Write `home/piggy-agent.nix`** with `services.piggy-agent`
   configured per Option X (single-instance, same socket path as
   pivy-agent.sock). Set `enable = false` initially. Use the module's
   top-level options (post-#60 and post-#61):
   - `askpass = "${pkgs.pivy}/libexec/pivy/pivy-askpass"` — reaches
     the agent process via the unit env (per #61's refactor) AND
     the user shell via `home.sessionVariables` (per #60).
   - `confirm = "${pkgs.pivy}/libexec/pivy/pivy-askpass"` and
     `notifySend = "${pkgs.pivy}/libexec/pivy/pivy-notify"` per
     #61.

   Plus the `lib.mkForce` override that reclaims `SSH_AUTH_SOCK`
   from the module:
   ```nix
   home.sessionVariables.SSH_AUTH_SOCK = lib.mkForce
     "$HOME/.local/state/ssh/mux-agent.sock";
   ```
   This is the only per-user override the rollout carries. The
   askpass propagation in single-instance mode comes from the
   module itself (#60); we only override the one knob the module
   gets wrong for users-with-mux.
3. **Build and switch with both modules present, piggy disabled.**
   `just build-home && home-manager switch`. This proves the new
   module evaluates; nothing changes at runtime. Confirm
   `home.sessionVariables` did not change (`env | rg ^SSH_`).
4. **Disable pivy-agent + enable piggy-agent in one switch.** Edit
   `home/pivy-agent.nix` to `lib.mkIf false …` (or import-gate from
   `home/linux.nix`); flip `services.piggy-agent.enable = true`.
   `home-manager switch`.
5. **Verify** in this order, BEFORE doing anything else:
   - `systemctl --user status piggy-agent` is active.
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
  `launchd.agents.piggy-agent` entry; verify it picks up
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
  contract" above. The four-var contract is now owned end-to-end by
  the piggy module after #60 (`d2374da`) and #61 (`b3f2b7a`); no
  per-user overrides in this rollout.
- **`SSH_AUTH_SOCK` ordering.** Documented above. Resolution:
  single-instance shape + `lib.mkForce` override on
  `home.sessionVariables.SSH_AUTH_SOCK` to point at the mux socket.
  Verified at evaluation time (definition conflict surfaces at
  `home-manager switch` if the override is missing) and at runtime
  in Phase 1 step 5.
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
  process — both halves sourced from the piggy module's first-class
  options (post-#60 and post-#61). The only per-user override is
  the `lib.mkForce` reclaim of `home.sessionVariables.SSH_AUTH_SOCK`
  to point at `mux-agent.sock`.

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
  `SSH_ASKPASS_REQUIRE` in user-shell `home.sessionVariables`.
  Closed by `d2374da`.
- **amarbel-llc/piggy#61** — v1.0 parity gap: `SSH_CONFIRM` /
  `SSH_NOTIFY_SEND` in agent-process env. Closed by `b3f2b7a` (also
  refactored static agent env vars onto the unit definition).
- `doc/eng-ssh.7.scd` — current architecture description; needs an
  update at Phase 3 (or a small note now that "pivy-agent" in the
  doc refers to the listener-by-name, which may be `piggy
  agent` after Phase 1).
