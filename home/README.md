# Home-Manager Modules

Home-manager modules for declarative user environment management. See
AGENTS.md's "Home-Manager & Nix-Darwin" section for the full architecture.

## NSS on Non-NixOS Linux

On non-NixOS Linux hosts, nix-built binaries link against nix's glibc (e.g.
2.42), not the system glibc. When these binaries call `getpwuid()` or
`getgrnam()`, glibc reads `/etc/nsswitch.conf` and tries to `dlopen` each NSS
module by name (e.g. `libnss_step_ssh.so.2`, `libnss_sss.so.2`). Since nix's
glibc only searches nix store paths, it can't find the system's NSS libraries,
causing "user ID not found" errors in commands like `whoami`, `git rebase`, and
anything that resolves UIDs.

### Approaches that don't work

**`LD_PRELOAD`:** glibc's NSS mechanism uses `dlopen()` to load modules, which
ignores `LD_PRELOAD`'d libraries. The preloaded library is in the process's
memory but glibc's NSS never calls into it.

**`LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu`:** exposes the system's
`libc.so.6`, and nix binaries (built against glibc 2.42) crash with
`GLIBC_2.42 not found` when they pick up the older system libc.

**Nix-built `libnss_sss.so.2` via `LD_PRELOAD`:** even when the library loads
and connects to the SSSD daemon socket, version mismatch between the nix-built
client (e.g. sssd 2.12.0) and the system daemon (e.g. sssd 2.6.3) causes
lookups to silently return "not found". Additionally, the user may not be in
SSSD at all — some systems resolve users via `step_ssh` or other NSS modules
that SSSD knows nothing about.

### The fix

`~/.config/nix/nss-session.nix` is a host-specific home-manager module deployed
via rcm on systems that need it. It:

1. Creates `~/.local/lib/nss/` at activation time with symlinks to **only** the
   system's NSS libraries (`libnss_step_ssh.so.2`, `libnss_sss.so.2`,
   `libnss_systemd.so.2`)
2. Sets `LD_LIBRARY_PATH` to that directory via `home.sessionVariables`

This lets nix's glibc find the NSS modules via `dlopen` without exposing the
system libc. The symlinks are created at activation time (not build time)
because system libraries aren't available inside the nix build sandbox.

The module is optional — `flake.nix` imports it only when present at
`~/.config/nix/nss-session.nix`. It has no effect on macOS or NixOS.

### Files involved

- `~/.config/nix/nss-session.nix` — the home-manager module (deployed via rcm)
- `flake.nix` — conditionally imports the module when present
- `~/.local/lib/nss/` — created at activation time, contains symlinks only
