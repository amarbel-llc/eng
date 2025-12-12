{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/d981d41ffe5b541eae3782029b93e2af5d229cc2";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/09eb77e94fa25202af8f3e81ddc7353d9970ac1b";
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
