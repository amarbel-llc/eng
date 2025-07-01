{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, nixpkgs-stable }:
    (utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          packages.default = pkgs.symlinkJoin {
            name = "gpg";

            paths = [
              pkgs.gnupg
            ];

            buildInputs = [
              pkgs.makeWrapper
            ];

            postBuild = ''
              for prog in $out/bin/*; do
                wrapProgram "$prog" \
                  --prefix PATH : "$out/bin" \
                  --run 'export GNUPGHOME="$XDG_CONFIG_HOME/gnupg"'
              done
            '';
          };
        }
      )
    );
}
