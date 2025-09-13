{
  description = "a bash script that takes an HTML file and uses Chromium to
  render it as a PDF. Chromium is not from nix right now because of Darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";

    html-to-pdf.url = "github:friedenberg/eng?dir=pkgs/alfa/html-to-pdf";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, utils, html-to-pdf }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        name = "pa6e-markdown-to-html";

        buildInputs = with pkgs; [
          uv
          bluez
          imagemagick
          pandoc
          html-to-pdf.packages.${system}.default
        ];

        pa6e-markdown-to-html = (
          pkgs.writeScriptBin name (builtins.readFile ./markdown-to-html.bash)
        ).overrideAttrs (old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });

        # to include all the templates and styles
        src = self;

      in
      {
        packages.default = pkgs.symlinkJoin {
          name = name;

          paths = [
            pa6e-markdown-to-html
            src
          ] ++ buildInputs;

          buildInputs = [
            pkgs.makeWrapper
          ];

          postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
        };

        devShells.default = pkgs.mkShell {
          packages = (with pkgs; [
            bluez
            uv
            imagemagick
            pandoc
            html-to-pdf.packages.${system}.default
          ]);

          LD_LIBRARY_PATH = [ "${pkgs.bluez.out}/lib" ];

          inputsFrom = [ ];
        };
      }
    );
}
