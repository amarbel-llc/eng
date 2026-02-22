{
  description = "Monorepo containing devenv templates and system packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    common.url = "path:./systems/common";
    darwin.url = "path:./systems/darwin";
    linux.url = "path:./systems/linux";

    # keep sorted
    # and-so-can-you-repo.url = "github:amarbel-llc/and-so-can-you-repo";
    # dodder.url = "github:amarbel-llc/dodder";
    # ess-ess-hatch.url = "github:amarbel-llc/ess-ess-hatch";
    # get-hubbed.url = "github:amarbel-llc/get-hubbed";
    # grit.url = "github:amarbel-llc/grit";
    # just-us.url = "github:amarbel-llc/just-us";
    # lux.url = "github:amarbel-llc/lux";
    # nix-mcp-server.url = "github:amarbel-llc/nix-mcp-server";
    # pivy.url = "github:amarbel-llc/pivy";
    # potato.url = "github:amarbel-llc/potato";
    # purse-first.url = "github:amarbel-llc/purse-first";
    # sandcastle.url = "github:amarbel-llc/sandcastle";
    # shdoc.url = "github:amarbel-llc/shdoc";
    # ssh-agent-mux.url = "github:amarbel-llc/ssh-agent-mux";
    # sweatshop.url = "github:amarbel-llc/sweatshop";
    # zmx.url = "github:amarbel-llc/zmx";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
      common,
      darwin,
      linux,
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
          "common"
          "darwin"
          "linux"
        ];

        # Repos whose default package isn't named "default"
        repoPackageOverrides = {
          zmx = "zmx-libvterm";
        };

        # Conditionally include platform-specific packages
        platformPackages =
          (builtins.removeAttrs (common.packages.${system} or { }) [ "default" ])
          // (builtins.removeAttrs (darwin.packages.${system} or { }) [ "default" ])
          // (builtins.removeAttrs (linux.packages.${system} or { }) [ "default" ]);

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
