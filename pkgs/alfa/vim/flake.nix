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
