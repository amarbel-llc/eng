{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/bd708996359444aa54ea97e10779ebc1eb6dad34";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8bb5646e0bed5dbd3ab08c7a7cc15b75ab4e1d0f";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      utils,
    }:
    (utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-linux"
      ]
      (
        system:
        let

          pkgs = import nixpkgs {
            inherit system;
          };

          pkgs-stable = import nixpkgs-stable {
            inherit system;
          };

        in
        {
          packages.default =
            with pkgs;
            symlinkJoin {
              name = "system-packages";
              paths = [
                espanso-wayland
                keyd
                pcsclite
                pinentry-gnome3
                shpool
              ];
            };
        }
      )
    );
}
