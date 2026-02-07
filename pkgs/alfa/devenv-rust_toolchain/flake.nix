{
  description = "A Nix-flake-based Rust development environment";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    nixpkgs.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    nixpkgs-master.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-master";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, nixpkgs-master, utils }:
    let
      overlays = [
        rust-overlay.overlays.default
        (final: prev: {
          rustToolchain = prev.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        })
      ];
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
        pkgs-master = import nixpkgs-master { inherit overlays system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs, pkgs-master }: {
        default = pkgs-master.mkShell {
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
      });
    };
}
