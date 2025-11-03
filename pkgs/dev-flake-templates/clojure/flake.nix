{
  description = "A Nix-flake-based Clojure development environment";

  inputs.utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  inputs.nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";

  outputs = { self, nixpkgs, nixpkgs-stable, utils }:

    let
      javaVersion = 20;
      overlays = [
        (final: prev: rec {
          jdk = prev."jdk${toString javaVersion}";
          boot = prev.boot.override { inherit jdk; };
          clojure = prev.clojure.override { inherit jdk; };
          leiningen = prev.leiningen.override { inherit jdk; };
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
          packages = with pkgs; [ boot clojure leiningen ];
        };
      });
    };
}
