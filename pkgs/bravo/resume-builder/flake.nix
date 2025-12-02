{
  description = "a justfile that takes a Pandoc-flavored markdown file and
  renders it as a resume in various formats";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/bd708996359444aa54ea97e10779ebc1eb6dad34";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8bb5646e0bed5dbd3ab08c7a7cc15b75ab4e1d0f";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    utils-pandoc.url = "github:friedenberg/dev-flake-templates?dir=pandoc";
    html-to-pdf.url = "github:friedenberg/eng?dir=pkgs/alfa/html-to-pdf";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, utils, utils-pandoc, html-to-pdf }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        name = "resume-builder";

        buildInputs = with pkgs; [
          pandoc
          just
          html-to-pdf
        ];

        resume-builder = (
          pkgs.writeScriptBin name (builtins.readFile ./justfile)
        ).overrideAttrs (old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });

        # to include all the templates and styles
        src = ./.;

      in
      rec {
        defaultPackage = packages.resume-builder;
        packages.resume-builder = pkgs.symlinkJoin {
          name = name;
          paths = [
            resume-builder
            src
          ] ++ buildInputs;

          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
        };

        devShells.default = pkgs.mkShell {
          packages = (with pkgs; [
            pandoc
            just
            html-to-pdf.packages.${system}.html-to-pdf
            resume-builder
          ]);

          inputsFrom = [ ];
        };
      }
    );
}
