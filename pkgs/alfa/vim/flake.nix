{
  description = "vim and neovim editor with tree-sitter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/bd708996359444aa54ea97e10779ebc1eb6dad34";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8bb5646e0bed5dbd3ab08c7a7cc15b75ab4e1d0f";
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
