{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    nixpkgs-master.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-master";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      rust-overlay,
      nixpkgs-master,
    }:
    (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        pkgs-master = import nixpkgs-master {
          inherit system;
          overlays = [
            rust-overlay.overlays.default
            (final: prev: {
              rustToolchain =
                let
                  rust = prev.rust-bin;
                in
                if builtins.pathExists ./rust-toolchain.toml then
                  rust.fromRustupToolchainFile ./rust-toolchain.toml
                else if builtins.pathExists ./rust-toolchain then
                  rust.fromRustupToolchainFile ./rust-toolchain
                else
                  rust.stable.latest.default.override {
                    extensions = [
                      "rust-src"
                      "rustfmt"
                    ];
                  };
            })
          ];
        };

      in

      rec {
        devShells.default = pkgs-master.mkShell {
          packages = [
            pkgs-master.rustToolchain
            pkgs.openssl
            pkgs.pkg-config
            pkgs-master.cargo-deny
            pkgs-master.cargo-edit
            pkgs-master.cargo-watch
            pkgs-master.rust-analyzer
          ];
        };
      }
    ));
}
