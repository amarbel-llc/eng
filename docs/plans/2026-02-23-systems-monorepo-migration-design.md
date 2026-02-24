# Systems Subflake Monorepo Migration

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to
> implement this plan task-by-task.

**Goal:** Eliminate all `path:` flake inputs from the top-level `flake.nix` by
migrating `systems/{common,darwin,linux}` to the `default.nix` + thin wrapper
pattern.

**Architecture:** Extract logic from each `systems/*/flake.nix` into a
`default.nix` (plain Nix function taking instantiated `pkgs` sets). The
top-level flake imports `default.nix` directly via a `buildSystems` helper that
uses `pkgs.stdenv.isDarwin`/`isLinux` for platform filtering. Each sub-flake
retains a thin wrapper for standalone/direnv use.

**Tech Stack:** Nix flakes, nixpkgs stable + master

---

### Task 1: Create `systems/common/default.nix`

**Files:**
- Create: `systems/common/default.nix`

**Step 1: Create the default.nix function**

Extract the package set from `systems/common/flake.nix` into a plain function.
The function takes `{ pkgs, pkgs-master }` (already instantiated with
`config.allowUnfree = true` by the caller) and returns `{ packages; }`.

```nix
# systems/common/default.nix
{ pkgs, pkgs-master }:
{
  packages = {
    inherit (pkgs-master)
      age
      asdf
      asdf-vm
      bats
      claude-code
      coreutils
      crush
      curl
      curlftpfs
      dash
      ddrescue
      direnv
      eternal-terminal
      expect
      ffmpeg
      figlet
      fish
      fontconfig
      fswatch
      fh
      freeze
      gawk
      gh
      git
      git-secret
      glibcLocales
      glow
      gnumake
      gnuplot
      gpgme
      graphviz
      gum
      helix
      hostess
      httpie
      hub
      imagemagick
      isolyzer
      j2cli
      jinja2-cli
      jq
      lftp
      libcdio
      markscribe
      melt
      mods
      neovim
      nix-direnv
      nixpkgs-fmt
      ocrmypdf
      pandoc
      paperkey
      parallel
      pay-respects
      plantuml
      pop
      rcm
      rsync
      shellcheck
      shfmt
      silver-searcher
      skate
      socat
      sshpass
      termdown
      timidity
      timg
      tldr
      tmux
      tree
      uv
      vhs
      watchexec
      websocat
      wget
      yubico-piv-tool
      yt-dlp
      zstd
      ;

    inherit (pkgs)
      csvkit
      gftp
      ;
  };
}
```

**Step 2: Verify it parses**

Run: `nix-instantiate --parse systems/common/default.nix`
Expected: Outputs the parsed AST without errors.

**Step 3: Commit**

```
git add systems/common/default.nix
git commit -m "Add systems/common/default.nix for monorepo migration"
```

---

### Task 2: Convert `systems/common/flake.nix` to thin wrapper

**Files:**
- Modify: `systems/common/flake.nix`

**Step 1: Replace flake.nix body with thin wrapper**

The wrapper imports `./default.nix` and passes its own instantiated pkgs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
    }:
    (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          config.allowUnfree = true;
          inherit system;
        };
        pkgs-master = import nixpkgs-master {
          config.allowUnfree = true;
          inherit system;
        };
        result = import ./default.nix { inherit pkgs pkgs-master; };
      in
      {
        packages =
          result.packages
          // {
            default = pkgs-master.symlinkJoin {
              failOnMissing = true;
              name = "system-packages";
              paths = builtins.attrValues result.packages;
            };
          };

        devShells.default = pkgs-master.mkShell {
          packages = builtins.attrValues result.packages;
        };
      }
    ));
}
```

**Step 2: Verify standalone flake still works**

Run: `nix flake show ./systems/common`
Expected: Shows `packages` and `devShells` for each default system.

**Step 3: Commit**

```
git add systems/common/flake.nix
git commit -m "Convert systems/common/flake.nix to thin wrapper"
```

---

### Task 3: Create `systems/darwin/default.nix`

**Files:**
- Create: `systems/darwin/default.nix`

**Step 1: Create the default.nix function**

Darwin only uses stable `pkgs`:

```nix
# systems/darwin/default.nix
{ pkgs }:
{
  packages = {
    inherit (pkgs)
      pinentry_mac
      reattach-to-user-namespace
      ;
  };
}
```

**Step 2: Verify it parses**

Run: `nix-instantiate --parse systems/darwin/default.nix`
Expected: Outputs the parsed AST without errors.

**Step 3: Commit**

```
git add systems/darwin/default.nix
git commit -m "Add systems/darwin/default.nix for monorepo migration"
```

---

### Task 4: Convert `systems/darwin/flake.nix` to thin wrapper

**Files:**
- Modify: `systems/darwin/flake.nix`

**Step 1: Replace flake.nix body with thin wrapper**

Preserves `eachSystem` with darwin-only architectures:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
    }:
    utils.lib.eachSystem
      [
        "x86_64-darwin"
        "aarch64-darwin"
      ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          result = import ./default.nix { inherit pkgs; };
        in
        {
          packages =
            result.packages
            // {
              default = pkgs.symlinkJoin {
                failOnMissing = true;
                name = "system-packages";
                paths = builtins.attrValues result.packages;
              };
            };

          devShells.default = pkgs.mkShell {
            packages = builtins.attrValues result.packages;
          };
        }
      );
}
```

**Step 2: Verify standalone flake still works**

Run: `nix flake show ./systems/darwin`
Expected: Shows `packages` and `devShells` for darwin systems only.

Note: This will fail on a Linux-only machine since there are no outputs for the
current system. Verify the flake parses: `nix flake metadata ./systems/darwin`

**Step 3: Commit**

```
git add systems/darwin/flake.nix
git commit -m "Convert systems/darwin/flake.nix to thin wrapper"
```

---

### Task 5: Create `systems/linux/default.nix`

**Files:**
- Create: `systems/linux/default.nix`

**Step 1: Create the default.nix function**

Linux uses stable `pkgs` for all packages but `pkgs-master` is needed by the
thin wrapper for symlinkJoin/mkShell. The default.nix only needs `pkgs`:

```nix
# systems/linux/default.nix
{ pkgs }:
{
  packages = {
    inherit (pkgs)
      espanso-wayland
      keyd
      mako
      pcsclite
      pinentry-gnome3
      rofi
      wlogout
      ;
  };
}
```

**Step 2: Verify it parses**

Run: `nix-instantiate --parse systems/linux/default.nix`
Expected: Outputs the parsed AST without errors.

**Step 3: Commit**

```
git add systems/linux/default.nix
git commit -m "Add systems/linux/default.nix for monorepo migration"
```

---

### Task 6: Convert `systems/linux/flake.nix` to thin wrapper

**Files:**
- Modify: `systems/linux/flake.nix`

**Step 1: Replace flake.nix body with thin wrapper**

Preserves `eachSystem` with linux-only architectures:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
    }:
    (utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-linux"
      ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          pkgs-master = import nixpkgs-master {
            inherit system;
          };
          result = import ./default.nix { inherit pkgs; };
        in
        {
          packages =
            result.packages
            // {
              default = pkgs-master.symlinkJoin {
                failOnMissing = true;
                name = "system-packages";
                paths = builtins.attrValues result.packages;
              };
            };

          devShells.default = pkgs-master.mkShell {
            packages = builtins.attrValues result.packages;
          };
        }
      )
    );
}
```

**Step 2: Verify standalone flake still works**

Run: `nix flake show ./systems/linux`
Expected: Shows `packages` and `devShells` for linux systems.

**Step 3: Commit**

```
git add systems/linux/flake.nix
git commit -m "Convert systems/linux/flake.nix to thin wrapper"
```

---

### Task 7: Update top-level `flake.nix`

**Files:**
- Modify: `flake.nix`

**Step 1: Remove path inputs**

Remove these 3 input blocks from `inputs`:

```nix
    common = {
      url = "path:./systems/common";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    darwin = {
      url = "path:./systems/darwin";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    linux = {
      url = "path:./systems/linux";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
```

**Step 2: Update outputs function**

Remove `common`, `darwin`, `linux` from the destructured args and `...`:

```nix
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
      ...
    }@inputs:
```

**Step 3: Add `buildSystems` helper and update `platformPackages`**

Replace the current `platformPackages` computation with:

```nix
        buildSystems =
          let
            pkgs-unfree = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            pkgs-master-unfree = import nixpkgs-master {
              inherit system;
              config.allowUnfree = true;
            };
          in
          {
            common = import ./systems/common {
              pkgs = pkgs-unfree;
              pkgs-master = pkgs-master-unfree;
            };
          }
          // (
            if pkgs.stdenv.isDarwin then
              {
                darwin = import ./systems/darwin { pkgs = pkgs-unfree; };
              }
            else
              { }
          )
          // (
            if pkgs.stdenv.isLinux then
              {
                linux = import ./systems/linux { pkgs = pkgs-unfree; };
              }
            else
              { }
          );

        platformPackages = builtins.foldl' (acc: sys: acc // sys.packages) { } (
          builtins.attrValues buildSystems
        );
```

Note: `pkgs` (without `allowUnfree`) is instantiated first for `stdenv` checks
and repo packages. Separate `pkgs-unfree` / `pkgs-master-unfree` are used for
system packages that need unfree.

**Step 4: Update infraInputs**

Remove `"common"`, `"darwin"`, `"linux"` from the list:

```nix
        infraInputs = [
          "self"
          "nixpkgs"
          "nixpkgs-master"
          "utils"
        ];
```

**Step 5: Verify top-level flake parses**

Run: `nix flake show`
Expected: Shows `packages` and `devShells` with all platform packages present
for the current system.

**Step 6: Commit**

```
git add flake.nix
git commit -m "Replace systems/ path inputs with direct default.nix imports"
```

---

### Task 8: Regenerate flake.lock

**Files:**
- Modify: `flake.lock`

**Step 1: Regenerate the lock file**

Run: `nix flake lock`
Expected: Removes all `"type": "path"` entries from `flake.lock`.

**Step 2: Verify no path entries remain**

Run: `grep -c '"type": "path"' flake.lock`
Expected: `0`

**Step 3: Commit**

```
git add flake.lock
git commit -m "Regenerate flake.lock without path inputs"
```

---

### Task 9: Full build verification

**Step 1: Build the top-level package**

Run: `nix build --show-trace`
Expected: Builds successfully. The `eng` symlinkJoin includes all platform and
repo packages.

**Step 2: Verify standalone subflakes**

Run on current platform:
```bash
nix flake show ./systems/common
nix flake metadata ./systems/darwin
nix flake show ./systems/linux
```
Expected: Each subflake's outputs are intact.

**Step 3: Format nix files**

Run: `nix run ./devenvs/nix#fmt -- systems/common/default.nix systems/darwin/default.nix systems/linux/default.nix systems/common/flake.nix systems/darwin/flake.nix systems/linux/flake.nix flake.nix`

If formatting changes are made, commit:
```
git add -A
git commit -m "Format nix files"
```
