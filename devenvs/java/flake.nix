{
  description = "A Nix-flake-based Java development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
    }:
    (utils.lib.eachDefaultSystem (
      system:
      let
        # javaVersion = 25; # Change this value to update the whole stack

        # overlays = [
        #   (final: prev: rec {
        #     jdk = prev."jdk${toString javaVersion}";
        #     gradle = prev.gradle.override { java = jdk; };
        #     maven = prev.maven.override { inherit jdk; };
        #   })
        # ];

        pkgs = import nixpkgs {
          inherit system;
        };

        # pkgs-master = import nixpkgs-master {
        #   inherit system;
        # };

        packages = {
          inherit (pkgs)
            gradle
            jdk
            jdt-language-server
            maven
            ;

          # inherit (pkgs-master)
          #   ;
        };

      in

      {
        inherit packages;

        devShells.default = pkgs.mkShell {
          packages = builtins.attrValues packages;
        };
      }
    ));
}
