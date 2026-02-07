{
  description = "A Nix-flake-based Elixir development environment";

  inputs.utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
  inputs.nixpkgs-master.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";

  outputs = { self, nixpkgs, nixpkgs-master, utils }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = (with pkgs; [ elixir ]) ++
            # Linux only
            pkgs.lib.optionals (pkgs.stdenv.isLinux) (with pkgs; [ gigalixir inotify-tools libnotify ]) ++
            # macOS only
            pkgs.lib.optionals (pkgs.stdenv.isDarwin) (with pkgs; [ terminal-notifier ]) ++
            pkgs.lib.optionals (pkgs.stdenv.isDarwin) (with pkgs.darwin.apple_sdk_11_0.frameworks; [ CoreFoundation CoreServices ]);
        };
      });
    };
}
