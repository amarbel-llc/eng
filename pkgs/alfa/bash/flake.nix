{
  inputs = {
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
            name = "bash";

            paths = [
              pkgs.bashInteractive
            ];

            buildInputs = [
              pkgs.makeWrapper
            ];

            postBuild = "
              wrapProgram $out/bin/bash --set LOCALE_ARCHIVE ${pkgs.glibcLocales}/lib/locale/locale-archive --prefix PATH : $out/bin
            ";
          };
        }
      )
    );
}
