{
  description = "Monorepo containing devenv templates and system packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    common.url = "path:./systems/common";
    darwin.url = "path:./systems/darwin";
    linux.url = "path:./systems/linux";

    # keep sorted
    and-so-can-you-repo.url = "github:amarbel-llc/and-so-can-you-repo";
    lux.url = "github:amarbel-llc/lux";
    nix-mcp-server.url = "github:amarbel-llc/nix-mcp-server";
    pivy.url = "github:amarbel-llc/pivy";
    purse-first.url = "github:amarbel-llc/purse-first";
    shdoc.url = "github:amarbel-llc/shdoc";
    ssh-agent-mux.url = "github:amarbel-llc/ssh-agent-mux";
    z.url = "path:../z";
    zmx.url = "github:sfriedenberg-etsy/zmx";
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

        # Provide a simple devShell for working in this repo
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            git
            gum
            just
            nix
          ];
        };
      }
    ));
}
