{
  description = "Monorepo containing system packages and project repos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-master.url = "github:NixOS/nixpkgs/ae921939fcbd44874664477bd1d22543c10a8306";
    nixpkgs-amarbel.url = "github:amarbel-llc/nixpkgs";
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

    # Third-party package collection (AI coding agents and dev tools).
    # Not following our nixpkgs: upstream targets nixpkgs-unstable and
    # their binary cache (cache.numtide.com) is keyed off that pin —
    # overriding to nixos-25.11 would risk breakage and lose the cache.
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

    # keep sorted
    bob = {
      url = "github:amarbel-llc/bob";
      inputs.purse-first.follows = "purse-first";
      # Bob expects the amarbel-llc nixpkgs fork (overlays.default adds
      # gomod2nix and bun2nix helpers used by its package builds). Pre-
      # 2026-04 it accepted any nixpkgs; HEAD does not.
      inputs.nixpkgs.follows = "nixpkgs-amarbel";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    clown = {
      url = "github:amarbel-llc/clown";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    chrest = {
      url = "github:amarbel-llc/chrest";
      inputs.nixpkgs.follows = "nixpkgs-amarbel";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    dodder = {
      url = "github:amarbel-llc/dodder";
      inputs.nixpkgs.follows = "nixpkgs-amarbel";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    ess-ess-hatch = {
      url = "github:amarbel-llc/ess-ess-hatch";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    madder = {
      url = "github:amarbel-llc/madder";
      inputs.nixpkgs.follows = "nixpkgs-amarbel";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    maneater = {
      url = "github:amarbel-llc/maneater";
      inputs.nixpkgs.follows = "nixpkgs-amarbel";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
      inputs.bob.follows = "bob";
    };
    moxy = {
      url = "github:amarbel-llc/moxy";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.bob.follows = "bob";
    };
    nebulous = {
      url = "github:amarbel-llc/nebulous";
      inputs.nixpkgs.follows = "nixpkgs-amarbel";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    piggy = {
      url = "github:amarbel-llc/piggy";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
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
      inputs.nixpkgs.follows = "nixpkgs-amarbel";
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
      inputs.nixpkgs.follows = "nixpkgs-amarbel";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
      # Guarded by pathExists so `nix flake check` succeeds in pure mode on
      # Linux (where the file is absent). On macOS, use --impure to read it.
      hasDarwinIdentity = builtins.pathExists /etc/nix-darwin/identity.json;
      darwinIdentity =
        if hasDarwinIdentity
        then builtins.fromJSON (builtins.readFile /etc/nix-darwin/identity.json)
        else null;

      # Builder for home-manager (extra)specialArgs, shared by the Linux
      # and darwin branches below. See ./home/special-args.nix for the
      # full rationale — short version: adding a new pinned-tree input
      # (AGENTS.md → "Wrapper-Pinned Packages") should be a one-line
      # change in that file, not a three-site edit here.
      mkHomeSpecialArgs = import ./home/special-args.nix { inherit inputs; };
    in
    (nixpkgs.lib.optionalAttrs (builtins.getEnv "HOME" != "") {
      # Gated on non-empty HOME so pure-mode evaluators (e.g. the
      # flakehub-push `nix flake show --all-systems` job, `nix flake
      # check` without --impure) don't trip on the absolute-path
      # `import /${homeDir}/.config/identity.nix` below. Local flows
      # that need this attribute (home-manager switch) already run with
      # --impure, where HOME is set.
      homeConfigurations.linux =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          homeDir = builtins.getEnv "HOME";
          linuxIdentity = import (/${homeDir}/.config/identity.nix);
          # On non-NixOS Linux, nix-built binaries use nix's glibc which
          # can't find system NSS modules (step_ssh, sss, systemd) for
          # user/group resolution. The nss-session.nix module creates an
          # isolated symlink directory pointing to the system's NSS libraries
          # and sets LD_LIBRARY_PATH to it. Deployed via rcm on hosts that
          # need it; absent on NixOS and macOS.
          # See AGENTS.md "NSS on Non-NixOS Linux".
          nssSessionPath = /${homeDir}/.config/nix/nss-session.nix;
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

    })
    // (
      if hasDarwinIdentity then
        {
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
      else
        { }
    )
    // (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        nonRepoInputs = import ./home/non-repo-inputs.nix;

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
        # trees added for the wrapper-pinning strategy in AGENTS.md.
        repoPackages =
          let
            candidates = builtins.removeAttrs inputs nonRepoInputs;
            hasDefaultPackage =
              _name: input:
              (input ? packages) && (input.packages ? ${system}) && (input.packages.${system} ? default);
          in
          builtins.mapAttrs (
            _name: input: input.packages.${system}.default
          ) (pkgs.lib.filterAttrs hasDefaultPackage candidates);

        # In-tree Claude Code plugin: development-workflow skills (vendored
        # from bob, with cross-references rewritten to the eng: namespace)
        # plus a code-reviewer agent. Lives at plugins/eng/. Wrapped in a
        # derivation, then in a tiny flake-shaped attrset, so mkCircus
        # consumes it the same way it consumes real flake inputs (it
        # only reads .packages.${system}.default, plus optional .rev).
        engPlugin = pkgs.runCommand "eng-plugin" { } ''
          mkdir -p $out/share/purse-first
          cp -r ${./plugins/eng} $out/share/purse-first/eng
        '';

        engPluginFlake = {
          packages.${system}.default = engPlugin;
          rev = self.rev or self.dirtyRev or "dirty";
        };

        # Bob ships several plugin trees inside `bob.packages.default`
        # (caldav, lux, tap-dancer, etc.). We only consume caldav, but
        # mkCircus reads `flake.packages.${system}.default`, which would
        # pull in the others as a side-effect. Wrap caldav alone into a
        # flake-shaped attrset so mkCircus sees just it.
        caldavPluginFlake = {
          packages.${system}.default = bob.packages.${system}.caldav;
          rev = bob.rev or bob.dirtyRev or "dirty";
        };

        circus = inputs.clown.lib.${system}.mkCircus {
          plugins = [
            { flake = inputs.moxy;      dirs = [ "share/purse-first/moxy" ]; }
            { flake = inputs.spinclass; dirs = [ "share/purse-first/spinclass" ]; }
            { flake = caldavPluginFlake; dirs = [ "share/purse-first/caldav" ]; }
            { flake = engPluginFlake;   dirs = [ "share/purse-first/eng" ]; }
          ];
        };

        doc = pkgs.stdenvNoCC.mkDerivation {
          pname = "eng-doc";
          version = "0.1.0";
          src = ./doc;
          nativeBuildInputs = [ pkgs.scdoc ];
          dontUnpack = true;
          dontBuild = true;
          installPhase = ''
            mkdir -p $out/share/man/man7
            for f in $src/*.7.scd; do
              scdoc < "$f" > "$out/share/man/man7/$(basename "$f" .scd)"
            done
          '';
        };

        # The eng-baked wrapper carries the global default config from
        # ./treefmt.nix; the cwd-aware shell wrapper below prefers a per-project
        # treefmt.toml when one exists at the git root, so individual repos can
        # override eng's defaults.
        treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
          imports = [ ./treefmt.nix ];
          _module.args.tommy = inputs.tommy.packages.${system}.default;
        };
        treefmtBaked = treefmtEval.config.build.wrapper;
        treefmtCwd = pkgs.writeShellScriptBin "treefmt" ''
          set -euo pipefail
          root=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)
          if [ -f "$root/treefmt.toml" ]; then
            exec ${pkgs.treefmt}/bin/treefmt "$@"
          fi
          exec ${treefmtBaked}/bin/treefmt "$@"
        '';

        packages = pkgs.symlinkJoin {
          name = "eng";
          paths =
            builtins.attrValues platformPackages
            ++ builtins.attrValues repoPackages
            ++ [
              purse-first.packages.${system}.purse-first
              bob.packages.${system}.caldav
              bob.packages.${system}.tap-dancer-bash
              circus.packages.default
              engPlugin
              inputs.moxy.packages.${system}.default
              doc
              treefmtCwd
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

        # `nix fmt` runs the cwd-aware treefmt wrapper.
        formatter = treefmtCwd;

        # `nix flake check` validates that the tree is formatted.
        checks.formatting = treefmtEval.config.build.check self;

        devShells =
          let
            allPackages = platformPackages // repoPackages;
          in
          builtins.mapAttrs (name: pkg: pkgs.mkShell { packages = [ pkg ]; }) allPackages
          // {
            default = pkgs.mkShell {
              packages = builtins.attrValues allPackages ++ [ treefmtCwd ];
            };
          };
      }
    ));
}
