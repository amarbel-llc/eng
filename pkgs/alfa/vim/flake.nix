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
            name = "vim";

            paths = [
              pkgs.vim
            ];

            buildInputs = [
              pkgs.makeWrapper
            ];

            postBuild = ''
              wrapProgram $out/bin/vim \
                --add-flags '-u "$XDG_CONFIG_HOME/vim/vimrc"' \
                --prefix PATH : $out/bin
            '';
          };
        }
      )
    );
}
