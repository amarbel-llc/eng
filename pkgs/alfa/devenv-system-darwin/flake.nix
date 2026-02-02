{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
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
