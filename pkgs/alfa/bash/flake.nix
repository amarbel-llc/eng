{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
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
