{
  description = "Example nix-darwin system flake";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs, nixpkgs-stable, utils,
    }:
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#11298
      darwinConfigurations."11298" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };

        modules = [
          ./modules/system.nix
          ./modules/apps.nix

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
