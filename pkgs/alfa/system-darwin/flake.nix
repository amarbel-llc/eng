{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    nix-darwin.url = "github:nix-darwin/nix-darwin";

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
      nixpkgs-master,
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
