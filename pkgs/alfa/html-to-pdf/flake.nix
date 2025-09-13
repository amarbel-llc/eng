{
  description = "a bash script that takes an HTML file and uses Chromium to
  render it as a PDF. Chromium is not from nix right now because of Darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";
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

      in {
        packages.default = pkgs.symlinkJoin {
          name = name;
          paths = [ html-to-pdf ] ++ buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
        };

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
