{
  description = "Monorepo containing devenv templates and system packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/3e20095fe3c6cbb1ddcef89b26969a69a1570776";
    nixpkgs-master.url = "github:NixOS/nixpkgs/e034e386767a6d00b65ac951821835bd977a08f7";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

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
      inputs.purse-first.follows = "crap";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    dodder = {
      url = "github:amarbel-llc/dodder";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };
    ess-ess-hatch = {
      url = "github:amarbel-llc/ess-ess-hatch";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-master.follows = "nixpkgs-master";
      inputs.utils.follows = "utils";
    };
    gcloud-auth-proxy = {
      url = "github:amarbel-llc/gcloud-auth-proxy";
      inputs.nixpkgs.follows = "nixpkgs";
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
    ssh-agent-mux = {
      url = "github:amarbel-llc/ssh-agent-mux";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };
    zmx = {
      url = "github:amarbel-llc/zmx";
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
      bob,
      purse-first,
      ...
    }@inputs:
    (utils.lib.eachDefaultSystem (
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
          "bob"
          "purse-first"
        ];

        # Repos whose default package isn't named "default"
        repoPackageOverrides = {
          zmx = "zmx-libvterm";
        };

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
