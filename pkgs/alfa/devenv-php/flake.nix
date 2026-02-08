{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      nixpkgs-master,
    }:
    (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        pkgs-master = import nixpkgs-master {
          inherit system;
          config.allowUnfree = true;
        };

        selected-packages = with pkgs-master; [
          intelephense
          pkgs.php84Packages.php-codesniffer
          php84Packages.php-cs-fixer
        ];

      in

      {
        packages.default =
          with pkgs-master;
          symlinkJoin {
            name = "devenv-php";
            paths = selected-packages;
          };

        devShells.default = pkgs-master.mkShell {
          packages = selected-packages;
        };
      }
    ));
}
