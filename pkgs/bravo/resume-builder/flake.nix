{
  description = "a justfile that takes a Pandoc-flavored markdown file and
  renders it as a resume in various formats";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";
    utils-pandoc.url  = "github:friedenberg/dev-flake-templates?dir=pandoc";
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
        ).overrideAttrs(old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });

        # to include all the templates and styles
        src = ./.;

      in rec {
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

          inputsFrom = [];
        };
      }
    );
}
