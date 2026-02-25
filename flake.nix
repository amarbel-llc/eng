{
  description = "Monorepo containing devenv templates and system packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    # keep sorted
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
    just-us = {
      url = "github:amarbel-llc/just-us";
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
      url = "github:amarbel-llc/zmx/master";
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
      ...
    }@inputs:
    (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Infrastructure inputs that are NOT repos
        infraInputs = [
          "self"
          "nixpkgs"
          "nixpkgs-master"
          "utils"
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
          paths = builtins.attrValues platformPackages ++ builtins.attrValues repoPackages;
        };

      in
      {
        packages.default = packages;

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
