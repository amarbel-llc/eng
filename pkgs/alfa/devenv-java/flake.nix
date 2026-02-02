{
  description = "A Nix-flake-based Java development environment";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
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
