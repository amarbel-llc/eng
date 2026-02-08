{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
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

          pkgs-master = import nixpkgs-master {
            inherit system;
          };

        in
        {
          packages.default =
            with pkgs-master;
            symlinkJoin {
              name = "system-packages";
              paths = [
                espanso-wayland
                keyd
                mako
                pcsclite
                pinentry-gnome3
                rofi
                wlogout
                # kitty
                # lxsession
                # sway
              ];
            };
        }
      )
    );
}
