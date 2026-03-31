{
  description = "nix-darwin system flake";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    nixpkgs-master.url = "github:NixOS/nixpkgs/e034e386767a6d00b65ac951821835bd977a08f7";
    nixpkgs.url = "github:NixOS/nixpkgs/3e20095fe3c6cbb1ddcef89b26969a69a1570776";
    nix-darwin.url = "github:nix-darwin/nix-darwin/08585aacc3d6d6c280a02da195fdbd4b9cf083c2";
    nix-plist-manager.url = "github:sushydev/nix-plist-manager";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nixpkgs-master,
      utils,
      nix-plist-manager,
      home-manager,
    }:
    let
      # Read identity from a file outside the flake boundary.
      # Create ~/.config/nix-darwin/identity.json with:
      #   { "username": "youruser", "homeDirectory": "/Users/youruser", "hostname": "yourhostname" }
      identity = builtins.fromJSON (builtins.readFile /etc/nix-darwin/identity.json);

      pkgs-master = import nixpkgs-master {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };
    in
    {
      # Build darwin flake using:
      # $ sudo darwin-rebuild switch --impure --flake .
      darwinConfigurations.${identity.hostname} = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit identity inputs pkgs-master;
        };

        modules = [
          ./modules/system.nix
          ./modules/apps.nix
          nix-plist-manager.darwinModules.default

          home-manager.darwinModules.home-manager
          {
            users.users.${identity.username} = {
              name = identity.username;
              home = identity.homeDirectory;
            };

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = {
              inherit inputs pkgs-master;
            };
            home-manager.users.${identity.username} = import ./modules/home-manager.nix;
          }
        ];
      };
    };
}
