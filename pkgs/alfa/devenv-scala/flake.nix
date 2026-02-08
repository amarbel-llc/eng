{
  description = "A Nix-flake-based Scala development environment";

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
