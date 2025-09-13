{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";

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
