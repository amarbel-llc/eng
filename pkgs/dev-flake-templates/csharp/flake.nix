{
  description = "A Nix-flake-based C# development environment";

  inputs.utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  inputs.nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";

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
          packages = with pkgs; [
            #dotnet-sdk_6
            dotnet-sdk_7
            #dotnet-sdk_8
            omnisharp-roslyn
            mono
            msbuild
          ];
        };
      });
    };
}
