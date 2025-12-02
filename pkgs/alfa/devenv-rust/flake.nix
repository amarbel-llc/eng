{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8bb5646e0bed5dbd3ab08c7a7cc15b75ab4e1d0f";
    nixpkgs.url = "github:NixOS/nixpkgs/bd708996359444aa54ea97e10779ebc1eb6dad34";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, utils, rust-overlay, nixpkgs-stable }:
    (utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
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
                      extensions = [ "rust-src" "rustfmt" ];
                    };
              })
            ];
          };

        in

        rec {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              rustToolchain
              openssl
              pkg-config
              cargo-deny
              cargo-edit
              cargo-watch
              rust-analyzer
            ];
          };
        })
    );
}
