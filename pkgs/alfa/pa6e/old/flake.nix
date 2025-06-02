{
  description = "a bash script that takes an HTML file and uses Chromium to
  render it as a PDF. Chromium is not from nix right now because of Darwin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "nixpkgs/release-24.11";
    utils.url = "github:numtide/flake-utils";

    chromium-html-to-pdf = {
      url = "github:friedenberg/chromium-html-to-pdf";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, utils, chromium-html-to-pdf }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        name = "pa6e-markdown-to-html";
        buildInputs = with pkgs; [
          bluez
          imagemagick
          pandoc
          chromium-html-to-pdf.packages.${system}.html-to-pdf
        ];
        pa6e-markdown-to-html = (
          pkgs.writeScriptBin name (builtins.readFile ./markdown-to-html.bash)
        ).overrideAttrs(old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });

        # to include all the templates and styles
        src = ./.;

      in rec {
        packages.pa6e-markdown-to-html = pkgs.symlinkJoin {
          name = name;
          paths = [ pa6e-markdown-to-html src ] ++ buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
        };

        defaultPackage = packages.pa6e-markdown-to-html;

        devShells.default = pkgs.mkShell {
          packages = (with pkgs; [
            bluez
            uv
            imagemagick
            pandoc
            chromium-html-to-pdf.packages.${system}.html-to-pdf
          ]);

          LD_LIBRARY_PATH = [ "${pkgs.bluez.out}/lib" ];

          inputsFrom = [];
        };
      }
    );
}
