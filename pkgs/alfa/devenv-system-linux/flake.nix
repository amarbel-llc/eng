{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-24.11";
    utils.url = "github:numtide/flake-utils";

    kmonad = {
      url = "git+https://github.com/kmonad/kmonad?submodules=1&dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , utils
    , kmonad
    }:
    let
      system = "x86_64-linux";

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
            espanso-wayland
            kmonad.packages.${system}.default
            keyd
          ];
        };
      };
    };
}
