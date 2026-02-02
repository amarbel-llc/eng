{
  description = "vim and neovim editor with tree-sitter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
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
