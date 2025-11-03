{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    # devenv
    devenv-go.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-go";
    devenv-js.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-js";
    devenv-nix.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-nix";
    devenv-shell.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-shell";
    devenv-system-common.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-system-common";
    devenv-system-linux.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-system-linux";
    devenv-system-darwin.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-system-darwin";

    bash.url = "github:friedenberg/eng?dir=pkgs/alfa/bash";
    claude.url = "github:friedenberg/eng?dir=pkgs/alfa/claude";
    ssh.url = "github:friedenberg/eng?dir=pkgs/alfa/ssh";
    ssh-agent-mux.url = "github:friedenberg/eng?dir=pkgs/alfa/ssh-agent-mux";
    sweatshop.url = "github:friedenberg/eng?dir=pkgs/bravo/sweatshop";
    vim.url = "github:friedenberg/eng?dir=pkgs/alfa/vim";

    html-to-pdf.url = "github:friedenberg/eng?dir=pkgs/alfa/html-to-pdf";

    pa6e.url = "github:friedenberg/eng?dir=pkgs/alfa/pa6e";
    pa6e.inputs.html-to-pdf.follows = "html-to-pdf";

    chrest.url = "github:friedenberg/eng?dir=pkgs/bravo/chrest";
    chrest.inputs.devenv-go.follows = "devenv-go";
    chrest.inputs.devenv-js.follows = "devenv-js";

    dodder.url = "github:friedenberg/dodder?dir=go";
    dodder.inputs.devenv-go.follows = "devenv-go";
    dodder.inputs.devenv-shell.follows = "devenv-shell";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , utils
      #
    , devenv-go
    , devenv-js
    , devenv-nix
    , devenv-shell
    , devenv-system-common
    , devenv-system-darwin
    , devenv-system-linux
      #
    , bash
    , claude
    , ssh
    , ssh-agent-mux
    , sweatshop
    , vim
      #
    , chrest
    , html-to-pdf
    , pa6e
    , dodder
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
              aarch64-darwin = devenv-system-darwin;
              x86_64-linux = devenv-system-linux;
              x86_64-darwin = devenv-system-darwin;
            }.${system}.packages.${system}.default

            # chrest.packages.${system}.default
            bash.packages.${system}.default
            claude.packages.${system}.default
            dodder.packages.${system}.default
            # html-to-pdf.packages.${system}.default
            # pa6e.packages.${system}.default
            ssh.packages.${system}.default
            ssh-agent-mux.packages.${system}.default
            # sweatshop.packages.${system}.default
            vim.packages.${system}.default
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
