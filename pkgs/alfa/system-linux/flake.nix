{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    nixpkgs-master.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
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
