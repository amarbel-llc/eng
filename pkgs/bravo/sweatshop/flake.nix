{
  description = "Sandboxed AI code-editing agent using bubblewrap. Only supports
  claude code for now";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
    devenv-nix.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-nix";
    devenv-shell.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-shell";
    sand-castle.url = "github:friedenberg/eng?dir=pkgs/alfa/sand-castle";
  };

  outputs =
    {
      self,
      nixpkgs,
      devenv-nix,
      devenv-shell,
      sand-castle,
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

        pkg-sand-castle = sand-castle.packages.${system}.default;

        sweatshop = pkgs.stdenv.mkDerivation {
          name = "sweatshop";

          src = ./sweatshop.bash;
          dontUnpack = true;

          buildInputs = with pkgs; [
            claude-code
            gum
            pkg-sand-castle
          ];

          installPhase = ''
            mkdir -p $out/bin
            substitute $src $out/bin/sweatshop \
              --replace "@bwrap@" "${pkg-sand-castle}/bin/sand-castle" \
              --replace "@claude-code@" "${pkgs.claude-code}/bin/claude" \
              --replace "@gum@" "${pkgs.gum}/bin/gum"
            chmod +x $out/bin/sweatshop
          '';
        };

        defaultDevShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            gum
            ripgrep
            pkg-sand-castle
            sweatshop
          ];

          shellHook = '''';

          inputsFrom = [
            devenv-nix.devShells.${system}.default
            devenv-shell.devShells.${system}.default
          ];
        };
      in
      {
        packages.default = sweatshop;
        packages.sweatshop = sweatshop;

        devShells.default = defaultDevShell;

        apps.default = {
          type = "app";
          program = "${sweatshop}/bin/sweatshop";
        };
      }
    );
}
