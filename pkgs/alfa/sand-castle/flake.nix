{
  description = "sandbox abstraction that uses bubblewrap on linux or
  sandbox-exec on macos";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8bb5646e0bed5dbd3ab08c7a7cc15b75ab4e1d0f";
    nixpkgs.url = "github:NixOS/nixpkgs/bd708996359444aa54ea97e10779ebc1eb6dad34";
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
        };

        pkgInfo =
          if pkgs.stdenv.isLinux then
            {
              src = ./linux.bash;

              buildInputs = (
                with pkgs;
                [
                  bubblewrap
                  gum
                ]
              );

              replacements = ''
                --replace "@bwrap@" "${pkgs.bubblewrap}/bin/bwrap" \
                --replace "@gum@" "${pkgs.gum}/bin/gum"
              '';
            }
          else
            {
              src = ./darwin.bash;

              buildInputs = (
                with pkgs;
                [
                  gum
                ]
              );

              replacements = ''
                --replace "@gum@" "${pkgs.gum}/bin/gum"
              '';
            };

        sand-castle = pkgs.stdenv.mkDerivation {
          name = "sand-castle";
          buildInputs = pkgInfo.buildInputs;
          src = pkgInfo.src;
          dontUnpack = true;

          installPhase = ''
            mkdir -p $out/bin

            substitute $src $out/bin/sand-castle \
              ${pkgInfo.replacements}

            chmod +x $out/bin/sand-castle
          '';
        };

        devShell = pkgs.mkShell {
          buildInputs = [
          ];

          inputsFrom = [
            devenv-nix.devShells.${system}.default
            devenv-shell.devShells.${system}.default
          ];
        };
      in
      {
        packages.default = sand-castle;
        packages.sand-castle = sand-castle;

        devShells.default = devShell;
      }
    );
}
