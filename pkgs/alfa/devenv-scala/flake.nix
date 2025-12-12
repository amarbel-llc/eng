{
  description = "A Nix-flake-based Scala development environment";

  inputs.utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  inputs.nixpkgs-stable.url = "github:NixOS/nixpkgs/09eb77e94fa25202af8f3e81ddc7353d9970ac1b";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/d981d41ffe5b541eae3782029b93e2af5d229cc2";

  outputs = { self, nixpkgs, nixpkgs-stable, utils }:
    let
      javaVersion = 20;
      overlays = [
        (final: prev: rec {
          jdk = prev."jdk${toString javaVersion}";
          sbt = prev.sbt.override { jre = jdk; };
          scala = prev.scala_3.override { jre = jdk; };
        })
      ];
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [ scala sbt coursier ];
        };
      });
    };
}
