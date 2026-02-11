{
  description = "Monorepo containing devenv templates and system packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    common.url = "path:./systems/common";
    darwin.url = "path:./systems/darwin";
    linux.url = "path:./systems/linux";

    # Temporarily commented out - these depend on devenv which has been migrated
    # lux.url = "github:amarbel-llc/lux";
    # nix-mcp-server.url = "github:amarbel-llc/nix-mcp-server";
    # ssh-agent-mux.url = "github:amarbel-llc/ssh-agent-mux";
    # zmx.url = "github:sfriedenberg-etsy/zmx";
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

        # Repository packages (temporarily disabled during migration)
        repoPackages = { };

      in
      {
        packages =
          platformPackages
          // repoPackages
          // {
            # Aggregate all available system packages for this platform
            all-systems = pkgs.symlinkJoin {
              name = "all-systems";
              paths = builtins.attrValues platformPackages;
            };

            # Aggregate all repository packages
            all-repos = pkgs.symlinkJoin {
              name = "all-repos";
              paths = builtins.filter (p: p != null) (builtins.attrValues repoPackages);
            };

            # Aggregate everything
            all = pkgs.symlinkJoin {
              name = "all";
              paths =
                (builtins.attrValues platformPackages)
                ++ (builtins.filter (p: p != null) (builtins.attrValues repoPackages));
            };
          };

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
