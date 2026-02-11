{
  description = "Monorepo containing devenv templates and system packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    system-common.url = "path:./systems/system-common";
    system-darwin.url = "path:./systems/system-darwin";
    system-linux.url = "path:./systems/system-linux";

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
      system-common,
      system-darwin,
      system-linux,
    }:
    (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Conditionally include platform-specific packages
        platformPackages =
          (builtins.removeAttrs (system-common.packages.${system} or { }) [ "default" ])
          // (builtins.removeAttrs (system-darwin.packages.${system} or { }) [ "default" ])
          // (builtins.removeAttrs (system-linux.packages.${system} or { }) [ "default" ]);

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
