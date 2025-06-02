{
  inputs = {
    nixpkgs-stable.url = "nixpkgs/release-24.11";
    utils.url = "github:numtide/flake-utils";

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
    { self
    , nixpkgs
    , nixpkgs-stable
    , utils
    , brew-api
    , brew
    }:
    let
      system = "x86_64-darwin";

      pkgs = import nixpkgs
        {
          inherit system;
        };

    in
    {
      packages.${system} = {
        default = with pkgs; symlinkJoin {
          name = "system-packages";
          paths = [
            pinentry-mac
            reattach-to-user-namespace
          ];
        };
      };
    };
}
