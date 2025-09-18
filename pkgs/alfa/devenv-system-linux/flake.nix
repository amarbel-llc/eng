{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";

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
