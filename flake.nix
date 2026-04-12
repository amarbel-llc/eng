{
  description = "Monorepo containing system packages and project repos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-master.url = "github:NixOS/nixpkgs/ae921939fcbd44874664477bd1d22543c10a8306";
    # Frozen tree used only by the claude wrapper in home/wrappers.nix to pin
    # claude-code to 2.1.83. Not followed by anything — bump-nixpkgs leaves it
    # alone because its sed is anchored to `nixpkgs-master.url`. Unpin by
    # removing this input and reverting home/wrappers.nix + systems/common.
    nixpkgs-claude-code-pinned.url = "github:NixOS/nixpkgs/5b471d29a84be70e8f5577258721b89865660493";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-plist-manager = {
      url = "github:sushydev/nix-plist-manager";
    };

    # keep sorted
    bob = {
      url = "github:amarbel-llc/bob";
      inputs.purse-first.follows = "purse-first";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    clown = {
      url = "github:amarbel-llc/clown";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    crap = {
      url = "github:amarbel-llc/crap";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    dodder = {
      url = "github:amarbel-llc/dodder";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.tommy.follows = "tommy";
      inputs.utils.follows = "utils";
    };
    ess-ess-hatch = {
      url = "github:amarbel-llc/ess-ess-hatch";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    just-us = {
      url = "github:amarbel-llc/just-us";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    maneater = {
      url = "github:amarbel-llc/maneater";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
      inputs.tommy.follows = "tommy";
      inputs.bob.follows = "bob";
    };
    moxy = {
      url = "github:amarbel-llc/moxy";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    nebulous = {
      url = "github:amarbel-llc/nebulous";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    piggy = {
      url = "github:amarbel-llc/piggy";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
      inputs.pivy.follows = "pivy";
    };
    pivy = {
      url = "github:amarbel-llc/pivy";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    purse-first = {
      url = "github:amarbel-llc/purse-first";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    shdoc = {
      url = "github:amarbel-llc/shdoc";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    spinclass = {
      url = "github:amarbel-llc/spinclass";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
      inputs.bob.follows = "bob";
    };
    ssh-agent-mux = {
      url = "github:amarbel-llc/ssh-agent-mux/a4b915cbf828e3be1ddc5aea86303f1b3506ba76";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };
    tacky = {
      url = "github:amarbel-llc/tacky";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };
    tommy = {
      url = "github:amarbel-llc/tommy";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };
    xdg = {
      url = "github:amarbel-llc/xdg";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
      home-manager,
      nix-darwin,
      nix-plist-manager,
      bob,
      purse-first,
      ...
    }@inputs:
    let
      # Read identity from /etc/nix-darwin/identity.json (requires --impure).
      # Create the file with: { "username": "...", "homeDirectory": "/Users/...", "hostname": "..." }
      darwinIdentity = builtins.fromJSON (builtins.readFile /etc/nix-darwin/identity.json);

      # Builder for home-manager (extra)specialArgs, shared by the Linux
      # and darwin branches below. See ./home/special-args.nix for the
      # full rationale — short version: adding a new pinned-tree input
      # (CLAUDE.md → "Wrapper-Pinned Packages") should be a one-line
      # change in that file, not a three-site edit here.
      mkHomeSpecialArgs = import ./home/special-args.nix { inherit inputs; };
    in
    {
      homeConfigurations.linux =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          homeDir = builtins.getEnv "HOME";
          linuxIdentity = import (builtins.toPath (homeDir + "/.config/identity.nix"));
          # On non-NixOS Linux, nix-built binaries use nix's glibc which
          # can't find system NSS modules (step_ssh, sss, systemd) for
          # user/group resolution. The nss-session.nix module creates an
          # isolated symlink directory pointing to the system's NSS libraries
          # and sets LD_LIBRARY_PATH to it. Deployed via rcm on hosts that
          # need it; absent on NixOS and macOS.
          # See CLAUDE.md "NSS on Non-NixOS Linux".
          nssSessionPath = builtins.toPath (homeDir + "/.config/nix/nss-session.nix");
          optionalNssModule = if builtins.pathExists nssSessionPath then [ nssSessionPath ] else [ ];
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = (mkHomeSpecialArgs system) // {
            identity = linuxIdentity;
          };
          modules = [
            ./home/identity.nix
            ./home/linux.nix
          ]
          ++ optionalNssModule;
        };

      darwinConfigurations.${darwinIdentity.hostname} =
        let
          # darwinSpecialArgs is reused in two places below:
          #   1. nix-darwin's top-level `specialArgs`
          #   2. the nested `home-manager.extraSpecialArgs`
          # Both sets are intentionally identical. If you ever need them
          # to diverge, split this binding rather than duplicating the
          # mkHomeSpecialArgs call.
          darwinSpecialArgs = (mkHomeSpecialArgs "aarch64-darwin") // {
            identity = darwinIdentity;
          };
        in
        nix-darwin.lib.darwinSystem {
          specialArgs = darwinSpecialArgs;

          modules = [
            ./rcm/tag-darwin/config/nix-darwin/modules/system.nix
            ./rcm/tag-darwin/config/nix-darwin/modules/apps.nix
            nix-plist-manager.darwinModules.default

            home-manager.darwinModules.home-manager
            {
              users.users.${darwinIdentity.username} = {
                name = darwinIdentity.username;
                home = darwinIdentity.homeDirectory;
              };

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";
              home-manager.extraSpecialArgs = darwinSpecialArgs;
              home-manager.users.${darwinIdentity.username} =
                import ./rcm/tag-darwin/config/nix-darwin/modules/home-manager.nix;
            }
          ];
        };
    }
    // (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Inputs intentionally excluded from the auto-imported repo set,
        # even though they MAY expose a `packages.<system>.default`
        # attribute on some systems. The shape filter in `repoPackages`
        # catches inputs with no default package at all (nixpkgs forks,
        # flake-utils, etc.) automatically — only list things here when
        # they have a real default package that we want to keep out of
        # the symlinkJoin:
        #
        # - `self` is the top-level flake itself; auto-importing would
        #   recurse.
        # - `home-manager` exposes a CLI as `packages.<system>.default`.
        #   It is consumed as `.lib` / `.darwinModules` instead.
        # - `nix-darwin` exposes `darwin-rebuild` as `packages.<darwin>.default`.
        # - `nix-plist-manager` likewise exposes a darwin-side package
        #   used only as a darwin module.
        # - `bob` and `purse-first` produce marketplace outputs whose
        #   `.claude-plugin/marketplace.json` would collide in symlinkJoin.
        #   Their non-marketplace packages are spliced in manually below.
        # - `tacky` is darwin-only; it is added manually under the
        #   darwin branch of the symlinkJoin.
        #
        # Adding a new nixpkgs-style frozen input for wrapper-pinning
        # (see CLAUDE.md → "Wrapper-Pinned Packages") requires zero
        # bookkeeping at this list — the shape filter handles it.
        nonRepoInputs = [
          "self"
          "home-manager"
          "nix-darwin"
          "nix-plist-manager"
          "bob"
          "purse-first"
          "tacky"
        ];

        # Repos whose default package isn't named "default"
        repoPackageOverrides = { };

        # Import system packages directly from default.nix
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

        # Shape-filter survivors of the nonRepoInputs exclusion so that
        # any input lacking `packages.<system>.<key>` (typically nixpkgs
        # forks, flake-utils, home-manager, etc.) is silently skipped
        # rather than raising `attribute 'packages' missing`. This makes
        # the flake tolerant of new nixpkgs-style inputs — e.g. frozen
        # trees added for the wrapper-pinning strategy in CLAUDE.md.
        repoPackages =
          let
            candidates = builtins.removeAttrs inputs nonRepoInputs;
            hasDefaultPackage =
              name: input:
              let
                key = repoPackageOverrides.${name} or "default";
              in
              (input ? packages) && (input.packages ? ${system}) && (input.packages.${system} ? ${key});
          in
          builtins.mapAttrs (
            name: input: input.packages.${system}.${repoPackageOverrides.${name} or "default"}
          ) (pkgs.lib.filterAttrs hasDefaultPackage candidates);

        packages = pkgs.symlinkJoin {
          name = "eng";
          paths =
            builtins.attrValues platformPackages
            ++ builtins.attrValues repoPackages
            ++ [
              purse-first.packages.${system}.purse-first
              bob.packages.${system}.default
              bob.packages.${system}.tap-dancer-bash
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              inputs.tacky.packages.${system}.default
            ];
        };

      in
      {
        packages = {
          default = packages;
          purse-first-marketplace = purse-first.packages.${system}.default;
          bob-marketplace = bob.packages.${system}.marketplace;
        };

        devShells =
          let
            allPackages = platformPackages // repoPackages;
          in
          builtins.mapAttrs (name: pkg: pkgs.mkShell { packages = [ pkg ]; }) allPackages
          // {
            default = pkgs.mkShell {
              packages = builtins.attrValues allPackages;
            };
          };
      }
    ));
}
