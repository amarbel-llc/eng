{
  description = "A Nix-flake-based Java development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
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
