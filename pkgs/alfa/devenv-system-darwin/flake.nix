{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    nix-darwin.url = "github:nix-darwin/nix-darwin-25.05";

    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };

    brew = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      utils,
      brew-api,
      nix-darwin,
      brew,
    }:
    utils.lib.eachSystem
      [
        "x86_64-darwin"
        "aarch64-darwin"
      ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ brew.overlays.default ];
          };

          casks = with pkgs.brewCasks; [
            kitty
          ];
        in
        {
          packages = {
            default =
              with pkgs;
              symlinkJoin {
                name = "system-packages";
                paths = [
                  nix-darwin
                  pinentry_mac
                  reattach-to-user-namespace
                ]
                ++ casks;
              };
          };
        }
      );
}
