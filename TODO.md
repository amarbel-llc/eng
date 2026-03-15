
## flake.lock deduplication (106 nodes, only 34 unique)

- [ ] add `purse-first.follows` on dodder/just-us/pivy/ssh-agent-mux — eliminates ~40 nodes (test all repos against consolidated rev)
- [ ] add deep follows for `just-us.inputs.rust` devenv inputs (nixpkgs, nixpkgs-master, utils) — eliminates ~6 nodes
- [ ] add deep follows for `pivy.inputs.sandcastle` subtree (devenv-nix, devenv-node) — eliminates ~6 nodes
- [ ] add `dodder.inputs.nixpkgs-master.follows = "nixpkgs-master"` — eliminates 1 node
- [ ] make purse-first's own transitive deps (fh, crane, gomod2nix) followable from top-level — eliminates ~8 nodes
- [x] chrest/flake.nix: `devenv-js` still points to `amarbel-llc/eng?dir=devenvs/js` — purse-first has `devenvs/node` but no `devenvs/js`

## Test assertion quality guard

- [ ] add CLAUDE.md rule: when modifying test assertions, new assertions must validate at least as much structure as the originals. If a change reduces assertion specificity (e.g., structured YAML blocks → bare prefix matching), that's a red flag — the test is no longer verifying meaningful behavior. Never mechanically rewrite assertions to match new output without evaluating whether they still test something.

## Transcript analysis: eng CLAUDE.md additions

- [x] add instruction: verify nix package exists with `nix eval` or `chix search` BEFORE writing flake.nix; don't guess attribute paths
- [ ] add instruction: run single test first to validate env setup; use `head`/`tail` to limit test output in context

## SSH agent forwarding + ControlMaster stale socket issue

- [ ] fix: ControlMaster reuses sessions where forwarded agent socket is dead (ControlPersist outlives the forwarding channel); evaluate `StreamLocalBindUnlink yes`, shorter `ControlPersist`, or refreshing agent forwarding on existing master

## Mako notifications

- [ ] Per-session Claude Code notification grouping: use Notification hook to send custom `kitten notify` with session/cwd in title + `app-name=claude-code`, then hide the default kitty notification via mako criteria `invisible=1`

## Transcript analysis: ~/.claude/CLAUDE.md additions

- [x] amend mid-task idea capture: cross-repo TODOs go in the relevant repo's TODO.md, not the current one

## Nix mkShell `env` doesn't expand shell variables

- [ ] audit all devenvs for `env` attributes containing `$HOME`, `$USER`, or other shell variables — these are set as literal strings by `mkShell`, not shell-expanded. Move to `shellHook` with `export`. Fixed in `devenvs/go` (bob + purse-first), may exist elsewhere.

## Multi-marketplace integration

- [ ] FDR: integrated dev/test environment for multi-marketplace local development

## github actions

- [ ] failed build:       error: Cannot build '/nix/store/jbpw34mfy3lwp5vlm3y53pdss4knwhc3-community-mirrors.txt.drv'.
             Reason: required system or feature not available
             Required system: 'aarch64-linux' with features {}
             Current system: 'x86_64-linux' with features {benchmark, big-parallel, kvm, nixos-test, uid-range}
      error: Cannot build '/nix/store/fa3sq9h0kmfbyzb8sglxm8n00ci5r5ir-zig-aarch64-linux-0.15.2.tar.xz.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/39xy35wp9pwcp4v4zqw6zd0raqhldq57-zig-aarch64-linux-0.15.2.tar.xz
      unpacking 'https://api.flakehub.com/f/pinned/NixOS/nixpkgs/0.2505.811770%2Brev-78e34d1667d32d8a0ffc3eba4591ff256e80576e/019a23fb-89f0-7302-a573-f6bf7dde9cf5/source.tar.gz' into the Git cache...
      error: Build failed due to failed dependency
      error: Cannot build '/nix/store/g2m8mayrixasv1m8j13h820pfw0kl5nd-zig-0.15.2.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/kb17p751fj6zmfhc2lr814kvak5byq0w-zig-0.15.2
      error: Build failed due to failed dependency
      error: Cannot build '/nix/store/mhci6lfc62avgip7ilbp8hq1qdvwk9jf-zig.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/wyji691lypgbjwr8masr2ifqfjnsmbrg-zig
      error: Build failed due to failed dependency
      error: Cannot build '/nix/store/s6r8mvvv7pqsd5yha2mv9mkyzy6ij9xh-zig-hook.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/hmi9vx5ksnr106j9gqhw4rymw97y28ya-zig-hook
      error: Build failed due to failed dependency
      error: Cannot build '/nix/store/26hncdv1j38f9pk33fckf5gzc734jj2a-zig2nix.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/jy0hir86r34c7drqv47wwan9w5ffgrwq-zig2nix
      error: Build failed due to failed dependency
      error: Cannot build '/nix/store/pb0nlq68yg16z1sa4da9djw0sccma574-zon2json.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/7bphkaly96qf3yxga64694yvflgw5hns-zon2json
      error: Build failed due to failed dependency
      error: Cannot build '/nix/store/k5rqicy203nb92jv1aqxrwrgfwgsmvzm-zon2json.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/c63nccf4bf3bxzmz54l9840ssc3zbx74-zon2json
      error:
             … while evaluating attribute 'inventory'
               at /tmp/flakehub_push_outputsLmCG3o/flake.nix:122:23:
                121|               inherit docs;
                122|               inherit inventory;
                   |                       ^
                123|             };

             … while evaluating attribute 'devShells'

             … while evaluating attribute 'children'
               at /tmp/flakehub_push_outputsLmCG3o/flake.nix:23:46:
                 22|
                 23|             mkChildren = children: { inherit children; };
                   |                                              ^
                 24|

             (stack trace truncated; use '--show-trace' to show the full, detailed trace)

             error: Build failed due to failed dependency


Location:
   src/flake_info.rs:314


## github actions

- [ ] failed build:       error: Cannot build '/nix/store/jbpw34mfy3lwp5vlm3y53pdss4knwhc3-community-mirrors.txt.drv'.
             Reason: required system or feature not available
             Required system: 'aarch64-linux' with features {}
             Current system: 'x86_64-linux' with features {benchmark, big-parallel, kvm, nixos-test, uid-range}
      error: Cannot build '/nix/store/fa3sq9h0kmfbyzb8sglxm8n00ci5r5ir-zig-aarch64-linux-0.15.2.tar.xz.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/39xy35wp9pwcp4v4zqw6zd0raqhldq57-zig-aarch64-linux-0.15.2.tar.xz
      unpacking 'https://api.flakehub.com/f/pinned/NixOS/nixpkgs/0.2505.811770%2Brev-78e34d1667d32d8a0ffc3eba4591ff256e80576e/019a23fb-89f0-7302-a573-f6bf7dde9cf5/source.tar.gz' into the Git cache...
      error: Build failed due to failed dependency
      error: Cannot build '/nix/store/g2m8mayrixasv1m8j13h820pfw0kl5nd-zig-0.15.2.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/kb17p751fj6zmfhc2lr814kvak5byq0w-zig-0.15.2
      error: Build failed due to failed dependency
      error: Cannot build '/nix/store/mhci6lfc62avgip7ilbp8hq1qdvwk9jf-zig.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/wyji691lypgbjwr8masr2ifqfjnsmbrg-zig
      error: Build failed due to failed dependency
      error: Cannot build '/nix/store/s6r8mvvv7pqsd5yha2mv9mkyzy6ij9xh-zig-hook.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/hmi9vx5ksnr106j9gqhw4rymw97y28ya-zig-hook
      error: Build failed due to failed dependency
      error: Cannot build '/nix/store/26hncdv1j38f9pk33fckf5gzc734jj2a-zig2nix.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/jy0hir86r34c7drqv47wwan9w5ffgrwq-zig2nix
      error: Build failed due to failed dependency
      error: Cannot build '/nix/store/pb0nlq68yg16z1sa4da9djw0sccma574-zon2json.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/7bphkaly96qf3yxga64694yvflgw5hns-zon2json
      error: Build failed due to failed dependency
      error: Cannot build '/nix/store/k5rqicy203nb92jv1aqxrwrgfwgsmvzm-zon2json.drv'.
             Reason: 1 dependency failed.
             Output paths:
               /nix/store/c63nccf4bf3bxzmz54l9840ssc3zbx74-zon2json
      error:
             … while evaluating attribute 'inventory'
               at /tmp/flakehub_push_outputsLmCG3o/flake.nix:122:23:
                121|               inherit docs;
                122|               inherit inventory;
                   |                       ^
                123|             };

             … while evaluating attribute 'devShells'

             … while evaluating attribute 'children'
               at /tmp/flakehub_push_outputsLmCG3o/flake.nix:23:46:
                 22|
                 23|             mkChildren = children: { inherit children; };
                   |                                              ^
                 24|

             (stack trace truncated; use '--show-trace' to show the full, detailed trace)

             error: Build failed due to failed dependency


Location:
   src/flake_info.rs:314

- [ ] modify nix workflows to be cancelled and replaced by new pushes:
  <https://github.com/amarbel-llc/eng/actions/workflows/nix.yml>

