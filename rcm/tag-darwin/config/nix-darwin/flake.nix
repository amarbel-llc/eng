{
  description = "Example nix-darwin system flake";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    nixpkgs-master.url = "github:NixOS/nixpkgs/e034e386767a6d00b65ac951821835bd977a08f7";
    nixpkgs.url = "github:NixOS/nixpkgs/3e20095fe3c6cbb1ddcef89b26969a69a1570776";
    nix-darwin.url = "github:nix-darwin/nix-darwin/08585aacc3d6d6c280a02da195fdbd4b9cf083c2";
    nix-plist-manager.url = "github:sushydev/nix-plist-manager";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nixpkgs-master,
      utils,
      nix-plist-manager,
    }:
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#11298
      darwinConfigurations."11298" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };

        modules = [
          ./modules/system.nix
          ./modules/apps.nix
          nix-plist-manager.darwinModules.default

          # inputs.home-manager.darwinModules.home-manager
          # {
          #   home-manager.useGlobalPkgs = true;
          #   home-manager.useUserPackages = true;
          #   home-manager.users.sfriedenberg = import ./modules/home-manager.nix;
          # }
        ];
      };
    };
}
