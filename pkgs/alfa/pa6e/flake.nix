{
  description = "a bash script that takes an HTML file and uses Chromium to
  render it as a PDF. Chromium is not from nix right now because of Darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    html-to-pdf.url = "github:friedenberg/eng?dir=pkgs/alfa/html-to-pdf";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      utils,
      html-to-pdf,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        name = "pa6e-markdown-to-html";

        buildInputs =
          with pkgs;
          [
            uv
            imagemagick
            pandoc
            html-to-pdf.packages.${system}.default
          ]
          ++ (lib.optionals pkgs.stdenv.isLinux [ pkgs.bluez ]);

        pa6e-markdown-to-html =
          (pkgs.writeScriptBin name (builtins.readFile ./markdown-to-html.bash)).overrideAttrs
            (old: {
              buildCommand = "${old.buildCommand}\n patchShebangs $out";
            });

        # to include all the templates and styles
        src = self;

        defaultPackage = pkgs.symlinkJoin {
          name = name;

          paths = [
            pa6e-markdown-to-html
            src
          ]
          ++ buildInputs;

          buildInputs = [
            pkgs.makeWrapper
          ];

          postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
        };

        defaultDevShell =
          if pkgs.stdenv.isLinux then
            pkgs.mkShell {
              packages = (buildInputs);

              LD_LIBRARY_PATH = [ "${pkgs.bluez.out}/lib" ];
            }
          else
            pkgs.mkShell { };

      in
      {
        packages.default = defaultPackage;
        devShells.default = defaultDevShell;
      }
    );
}
