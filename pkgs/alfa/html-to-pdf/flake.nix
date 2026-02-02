{
  description = "a bash script that takes an HTML file and uses Chromium to
  render it as a PDF. Chromium is not from nix right now because of Darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        pkgs-stable = import nixpkgs-stable {
          inherit system;
        };

        name = "html-to-pdf";

        buildInputs =
          with pkgs;
          [
            httpie
            jq
            websocat
          ]
          ++ lib.optional (!pkgs.stdenv.isDarwin) pkgs-stable.chromium;

        html-to-pdf =
          (pkgs.writeScriptBin name (builtins.readFile ./html-to-pdf.bash)).overrideAttrs
            (old: {
              buildCommand = "${old.buildCommand}\n patchShebangs $out";
            });

      in
      {
        packages.default = pkgs.symlinkJoin {
          name = name;
          paths = [ html-to-pdf ] ++ buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
        };

        devShells.default = pkgs.mkShell {
          packages = (
            with pkgs;
            [
              httpie
              jq
              websocat
            ]
          );

          inputsFrom = [ ];
        };
      }
    );
}
