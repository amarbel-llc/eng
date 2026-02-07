{
  description = "A Nix-flake-based Scala development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    nixpkgs-master.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
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
        javaVersion = 20;
        overlays = [
          (final: prev: rec {
            jdk = prev."jdk${toString javaVersion}";
            sbt = prev.sbt.override { jre = jdk; };
            scala = prev.scala_3.override { jre = jdk; };
          })
        ];
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            scala
            sbt
            coursier
          ];
        };
      }
    ));
}
