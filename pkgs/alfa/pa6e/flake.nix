{
  description = "a bash script that takes an HTML file and uses Chromium to
  render it as a PDF. Chromium is not from nix right now because of Darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
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
