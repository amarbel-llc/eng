{
  # TODO extract into own repo and make a proper flake
  description = "Pinned version of ssh-agent-mux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";
  };


  outputs = { self, nixpkgs, nixpkgs-stable, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        version = "0.1.6";
      in
      rec {
        # 📦 Define the package within the 'packages' output
        packages.ssh-agent-mux = pkgs.rustPlatform.buildRustPackage {
          pname = "ssh-agent-mux";
          inherit version;

          # Fetch the source from the Crates.io tarball
          src = pkgs.fetchCrate {
            crateName = "ssh-agent-mux";
            inherit version;
            hash = "sha256-4ZBGKdXQF87s/7Xl2cjtXW6Cb8oIgLxluOG1+KoSvoI=";
          };

          # The hash for the vendored dependencies (Cargo.lock)
          cargoHash = "sha256-o/7BWBvwgnqEAKCa63jmuT8ma6pmC+7SYHxUUKTPxNM=";

          doCheck = false;

          meta = with pkgs.lib; {
            description = "Combine keys from multiple SSH agents into a single agent socket.";
            homepage = "https://github.com/overhacked/ssh-agent-mux";
            platforms = platforms.linux ++ platforms.darwin;
          };
        };

        packages.default = packages.ssh-agent-mux;

        # 🐚 Define a simple devShell for testing
        devShells.default = pkgs.mkShell {
          packages = [ self.packages.${system}.ssh-agent-mux ];
        };
      }
    );
}
