{
  description = "a bash script that takes an HTML file and uses Chromium to
  render it as a PDF. Chromium is not from nix right now because of Darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";

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
