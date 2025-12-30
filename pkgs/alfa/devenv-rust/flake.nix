{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
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
