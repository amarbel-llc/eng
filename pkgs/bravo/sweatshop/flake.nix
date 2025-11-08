{
  description = "Sandboxed AI code-editing agent using bubblewrap. Only supports
  claude code for now";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    devenv-nix.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-nix";
    devenv-shell.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-shell";
  };

  outputs =
    {
      self,
      nixpkgs,
      devenv-nix,
      devenv-shell,
      nixpkgs-stable,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        sweatshop = pkgs.stdenv.mkDerivation {
          name = "sweatshop";
          src = ./sweatshop.sh;
          buildInputs = [
            pkgs.bubblewrap
            pkgs.claude-code
          ];
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

          shellHook = '''';

          inputsFrom = [
            devenv-nix.devShells.${system}.default
            devenv-shell.devShells.${system}.default
          ];
        };

        apps.default = {
          type = "app";
          program = "${sweatshop}/bin/sweatshop";
        };
      }
    );
}
