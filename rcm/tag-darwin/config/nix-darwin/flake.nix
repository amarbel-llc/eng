{
  description = "Example nix-darwin system flake";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
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
