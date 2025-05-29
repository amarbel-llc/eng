{
  description = "a bash script that takes an HTML file and uses Chromium to
  render it as a PDF. Chromium is not from nix right now because of Darwin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "nixpkgs/release-24.11";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        name = "html-to-pdf";

        buildInputs = with pkgs; [
          httpie
          jq
          websocat
          chromium
        ];

        html-to-pdf = (
          pkgs.writeScriptBin name (builtins.readFile ./html-to-pdf.bash)
        ).overrideAttrs(old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });

      in rec {
        packages.html-to-pdf = pkgs.symlinkJoin {
          name = name;
          paths = [ html-to-pdf ] ++ buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
        };

        defaultPackage = packages.html-to-pdf;

        devShells.default = pkgs.mkShell {
          packages = (with pkgs; [
            httpie
            jq
            websocat
          ]);

          inputsFrom = [];
        };
      }
    );
}
