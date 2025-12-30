{
  description = "shdoc - documentation generator for shell scripts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      utils,
    }:
    utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ]
      (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          packages.default = pkgs.stdenv.mkDerivation {
            pname = "shdoc";
            version = "1.2";

            src = pkgs.fetchFromGitHub {
              owner = "reconquest";
              repo = "shdoc";
              rev = "v1.2";
              sha256 = "sha256-oBOXeISPv43VgE6bzPzr6BvVfFwDo1Wx7ekp07w9h6s=";
            };

            dontBuild = true;

            buildInputs = [ pkgs.gawk ];
            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              mkdir -p $out/bin

              cp shdoc $out/bin/
              cp ${./shdoc-fish_completion} $out/bin/shdoc-fish_completion

              wrapProgram $out/bin/shdoc --prefix PATH : ${pkgs.gawk}/bin

              # wrapProgram $out/bin/shdoc-fish_completion --prefix PATH : ${pkgs.gawk}/bin
            '';
          };
        }
      );
}
