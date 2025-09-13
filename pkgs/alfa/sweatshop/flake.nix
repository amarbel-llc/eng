{
  description = "Sandboxed AI code-editing agent using bubblewrap. Only supports
  claude code for now";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    flake-utils.url = "github:numtide/flake-utils";
    devenv-nix.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-nix";
    devenv-shell.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-shell";
  };

  outputs = { self, nixpkgs, flake-utils, devenv-nix, devenv-shell, nixpkgs-stable, utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        sweatshop = pkgs.stdenv.mkDerivation {
          name = "sweatshop";
          src = ./sweatshop.sh;
          buildInputs = [ pkgs.bubblewrap pkgs.claude-code ];
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out/bin
            substitute $src $out/bin/sweatshop \
              --replace "@bwrap@" "${pkgs.bubblewrap}/bin/bwrap" \
              --replace "@claude-code@" "${pkgs.claude-code}/bin/claude"
            chmod +x $out/bin/sweatshop
          '';
        };
      in
      {
        packages.default = sweatshop;
        packages.sweatshop = sweatshop;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            ripgrep
            bubblewrap
            sweatshop
          ];

          shellHook = ''
          '';

          inputsFrom = [
            devenv-nix.devShells.${system}.default
            devenv-shell.devShells.${system}.default
          ];
        };

        apps.default = {
          type = "app";
          program = "${sweatshop}/bin/sweatshop";
        };
      });
}
