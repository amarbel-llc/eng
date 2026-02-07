{
  description = "a bash script that takes an HTML file and uses Chromium to
  render it as a PDF. Chromium is not from nix right now because of Darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    nixpkgs-master.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        pkgs-master = import nixpkgs-master {
          inherit system;
        };

        name = "html-to-pdf";

        buildInputs =
          with pkgs-master;
          [
            httpie
            jq
            websocat
          ]
          ++ lib.optional (!pkgs-master.stdenv.isDarwin) pkgs.chromium;

        html-to-pdf =
          (pkgs-master.writeScriptBin name (builtins.readFile ./html-to-pdf.bash)).overrideAttrs
            (old: {
              buildCommand = "${old.buildCommand}\n patchShebangs $out";
            });

      in
      {
        packages.default = pkgs-master.symlinkJoin {
          name = name;
          paths = [ html-to-pdf ] ++ buildInputs;
          buildInputs = [ pkgs-master.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
        };

        devShells.default = pkgs-master.mkShell {
          packages = (
            with pkgs-master;
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
