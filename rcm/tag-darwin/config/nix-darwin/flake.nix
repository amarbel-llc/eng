{
  description = "Example nix-darwin system flake";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    nixpkgs-master.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
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
