{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/bd708996359444aa54ea97e10779ebc1eb6dad34";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8bb5646e0bed5dbd3ab08c7a7cc15b75ab4e1d0f";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

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
                  pinentry_mac
                  reattach-to-user-namespace
                ]
                ++ casks;
              };
          };
        }
      );
}
