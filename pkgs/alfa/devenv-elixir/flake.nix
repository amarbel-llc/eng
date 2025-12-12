{
  description = "A Nix-flake-based Elixir development environment";

  inputs.utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  inputs.nixpkgs-stable.url = "github:NixOS/nixpkgs/09eb77e94fa25202af8f3e81ddc7353d9970ac1b";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/d981d41ffe5b541eae3782029b93e2af5d229cc2";

  outputs = { self, nixpkgs, nixpkgs-stable, utils }:
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
            (with pkgs.darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices ]);
        };
      });
    };
}
