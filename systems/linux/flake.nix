{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
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

          packages = {
            inherit (pkgs)
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
              ;
          };

        in
        {
          packages =
            packages
            // {
              default = pkgs-master.symlinkJoin {
                failOnMissing = true;
                name = "system-packages";
                paths = builtins.attrValues packages;
              };
            };

          devShells.default = pkgs-master.mkShell {
            packages = builtins.attrValues packages;
          };
        }
      )
    );
}
