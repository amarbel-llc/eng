{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs = { self, nixpkgs, utils, nixpkgs-stable }:
    (utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          packages.default = pkgs.symlinkJoin {
            name = "bash";

            paths = [
              pkgs.bashInteractive
            ];

            buildInputs = [
              pkgs.makeWrapper
            ];

            postBuild = pkgs.lib.optionalString pkgs.stdenv.isLinux ''
              wrapProgram $out/bin/bash \
                --set LOCALE_ARCHIVE \
                ${pkgs.glibcLocales}/lib/locale/locale-archive \
                --prefix PATH : $out/bin
            '';
          };
        }
      )
    );
}
