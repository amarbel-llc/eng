{
  description = "Monorepo containing system packages and project repos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/4590696c8693fea477850fe379a01544293ca4e2";
    nixpkgs-master.url = "github:NixOS/nixpkgs/e2dde111aea2c0699531dc616112a96cd55ab8b5";
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
      url = "github:amarbel-llc/ssh-agent-mux";
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

      darwinPkgsMaster = import nixpkgs-master {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations.linux =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-master = import nixpkgs-master {
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
          extraSpecialArgs = {
            inherit inputs pkgs-master;
            identity = linuxIdentity;
          };
          modules = [
            ./home/identity.nix
            ./home/linux.nix
          ]
          ++ optionalNssModule;
        };

      darwinConfigurations.${darwinIdentity.hostname} = nix-darwin.lib.darwinSystem {
        specialArgs = {
          identity = darwinIdentity;
          inherit inputs;
          pkgs-master = darwinPkgsMaster;
        };

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
            home-manager.extraSpecialArgs = {
              inherit inputs;
              identity = darwinIdentity;
              pkgs-master = darwinPkgsMaster;
            };
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

        # Infrastructure inputs excluded from auto-import.
        # bob and purse-first produce marketplace outputs whose
        # .claude-plugin/marketplace.json would collide in symlinkJoin.
        # Instead, we add the purse-first CLI and bob's full package
        # set to the symlinkJoin manually below.
        infraInputs = [
          "self"
          "nixpkgs"
          "nixpkgs-master"
          "utils"
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

        repoPackages = builtins.mapAttrs (
          name: input: input.packages.${system}.${repoPackageOverrides.${name} or "default"}
        ) (builtins.removeAttrs inputs infraInputs);

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
