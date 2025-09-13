{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";
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

            # TODO add library functions
            postBuild = ''
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
