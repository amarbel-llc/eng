{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
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
                lxsession
                mako
                pcsclite
                pinentry-gnome3
                rofi
                wlogout
                # sway
              ];
            };
        }
      )
    );
}
