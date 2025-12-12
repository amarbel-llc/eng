{
  description = "A Nix-flake-based Java development environment";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/09eb77e94fa25202af8f3e81ddc7353d9970ac1b";
    nixpkgs.url = "github:NixOS/nixpkgs/d981d41ffe5b541eae3782029b93e2af5d229cc2";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs = { self, nixpkgs, nixpkgs-stable }:
    let
      javaVersion = 20; # Change this value to update the whole stack
      overlays = [
        (final: prev: rec {
          jdk = prev."jdk${toString javaVersion}";
          gradle = prev.gradle.override { java = jdk; };
          maven = prev.maven.override { inherit jdk; };
        })
      ];
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit overlays system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [ gradle jdk maven ];
        };
      });
    };
}
