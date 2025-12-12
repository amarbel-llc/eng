{
  description = "vim and neovim editor with tree-sitter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/d981d41ffe5b541eae3782029b93e2af5d229cc2";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/09eb77e94fa25202af8f3e81ddc7353d9970ac1b";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      nixpkgs-stable,
    }:
    (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      rec {
        packages.default = pkgs.symlinkJoin {
          name = "vim";

          paths = with pkgs; [
            neovim
            nodejs
            tree-sitter
            vim
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

        devShells.default = pkgs.mkShell {
          packages = builtins.attrValues packages;
        };
      }
    ));
}
