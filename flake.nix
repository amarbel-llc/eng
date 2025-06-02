{
  inputs = {
    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2411.717296.tar.gz";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";

    # devenv
    devenv-go.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-go";
    devenv-js.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-js";
    devenv-nix.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-nix";
    devenv-shell.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-shell";
    devenv-system-common.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-system-common";
    devenv-system-linux.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-system-linux";
    devenv-system-darwin.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-system-darwin";

    bash.url = "github:friedenberg/eng?dir=pkgs/alfa/bash";
    ssh.url = "github:friedenberg/eng?dir=pkgs/alfa/ssh";

    html-to-pdf.url = "github:friedenberg/eng?dir=pkgs/alfa/html-to-pdf";

    pa6e.url = "github:friedenberg/eng?dir=pkgs/alfa/pa6e";
    pa6e.inputs.html-to-pdf.follows = "html-to-pdf";

    chrest.url = "github:friedenberg/eng?dir=pkgs/bravo/chrest";
    chrest.inputs.devenv-go.follows = "devenv-go";
    chrest.inputs.devenv-js.follows = "devenv-js";

    zit.url = "github:friedenberg/eng?dir=pkgs/bravo/zit/go/zit";
    zit.inputs.devenv-go.follows = "devenv-go";
    zit.inputs.devenv-shell.follows = "devenv-shell";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , utils
    , devenv-go
    , devenv-js
    , devenv-nix
    , devenv-shell
    , devenv-system-common
    , devenv-system-darwin
    , devenv-system-linux
    , bash
    , ssh
    , zit
    , chrest
    , html-to-pdf
    , pa6e
    }:
    (utils.lib.eachDefaultSystem
      (system:
      let

        pkgs = import nixpkgs {
          inherit system;
        };


      in
      {
        packages.default = pkgs.symlinkJoin {
          failOnMissing = true;
          name = "source";
          paths = [
            devenv-system-common.packages.${system}.default

            {
              x86_64-linux = devenv-system-linux;
              x86_64-darwin = devenv-system-darwin;
            }.${system}.packages.${system}.default

            bash.packages.${system}.default
            # chrest.packages.${system}.default
            html-to-pdf.packages.${system}.default
            pa6e.packages.${system}.default
            ssh.packages.${system}.default
            zit.packages.${system}.default
          ];
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [
            devenv-nix.devShells.${system}.default
          ];
        };
      })
    );
}
