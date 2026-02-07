{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    nixpkgs-master.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    devenv-lua.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-lua";
  };

  outputs = { self, nixpkgs, utils, devenv-lua, nixpkgs-master }:
    (utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

        in

        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              pandoc
            ];

            inputsFrom = [
              devenv-lua.devShells.${system}.default
            ];
          };
        })
    );
}
