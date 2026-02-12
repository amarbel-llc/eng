{
  description = "Monorepo containing devenv templates and system packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    common.url = "path:./systems/common";
    darwin.url = "path:./systems/darwin";
    linux.url = "path:./systems/linux";

    lux.url = "github:amarbel-llc/lux";
    nix-mcp-server.url = "github:amarbel-llc/nix-mcp-server";
    pivy.url = "github:amarbel-llc/pivy";
    ssh-agent-mux.url = "github:amarbel-llc/ssh-agent-mux";
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
      lux,
      nix-mcp-server,
      pivy,
      ssh-agent-mux,
      zmx,
    }:
    (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Conditionally include platform-specific packages
        platformPackages =
          (builtins.removeAttrs (common.packages.${system} or { }) [ "default" ])
          // (builtins.removeAttrs (darwin.packages.${system} or { }) [ "default" ])
          // (builtins.removeAttrs (linux.packages.${system} or { }) [ "default" ]);

        # Repository packages
        repoPackages = {
          lux = lux.packages.${system}.default;
          nix-mcp-server = nix-mcp-server.packages.${system}.default;
          pivy = pivy.packages.${system}.default;
          ssh-agent-mux = ssh-agent-mux.packages.${system}.default;
          zmx = zmx.packages.${system}.zmx-libvterm;
        };

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
