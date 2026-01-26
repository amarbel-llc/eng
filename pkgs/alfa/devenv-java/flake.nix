{
  description = "A Nix-flake-based Java development environment";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
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

        # pkgs-stable = import nixpkgs-stable {
        #   inherit system;
        # };

        packages = {
          inherit (pkgs)
            gradle
            jdk
            jdt-language-server
            maven
            ;

          # inherit (pkgs-stable)
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
