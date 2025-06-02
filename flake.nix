{
  inputs = {
    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2411.717296.tar.gz";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";

    system-packages-common.url =
      "path:./dev-flake-templates/system-packages-common";

    system-packages-darwin.url =
      "path:./dev-flake-templates/system-packages-darwin";

    system-packages-linux.url =
      "path:./dev-flake-templates/system-packages-linux";

    # devenv
    devenv-go.url = "path:./pkgs/alfa/devenv-go";
    devenv-nix.url = "path:./pkgs/alfa/devenv-nix";
    devenv-shell.url = "path:./pkgs/alfa/devenv-shell";

    bash.url = "path:./pkgs/alfa/bash";
    ssh.url = "path:./pkgs/alfa/ssh";
    chrest.url = "path:./pkgs/bravo/chrest";
    html-to-pdf.url = "path:./pkgs/alfa/html-to-pdf";

    pa6e.url = "path:./pkgs/alfa/pa6e";
    pa6e.inputs.html-to-pdf.follows = "html-to-pdf";

    zit.url = "path:./pkgs/bravo/zit/go/zit";
    zit.inputs.devenv-go.follows = "devenv-go";
    zit.inputs.devenv-shell.follows = "devenv-shell";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , utils
    , system-packages-common
    , system-packages-darwin
    , system-packages-linux
    , devenv-go
    , devenv-nix
    , devenv-shell
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
            system-packages-common.packages.${system}.default

            {
              x86_64-linux = system-packages-linux;
              x86_64-darwin = system-packages-darwin;
            }.${system}.packages.${system}.default

            bash.packages.${system}.default
            ssh.packages.${system}.default
            zit.packages.${system}.default
            # chrest.packages.${system}.default
            html-to-pdf.packages.${system}.default
            pa6e.packages.${system}.default
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
