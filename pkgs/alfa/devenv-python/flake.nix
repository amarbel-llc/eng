{
  description = "A Nix-flake-based Python development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    nixpkgs-master.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
    }:
    (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        pkgs-master = import nixpkgs-master {
          inherit system;
        };

      in

      {
        devShells.default = pkgs-master.mkShell {
          packages = [
            pkgs-master.uv
            pkgs-master.ruff
            (pkgs.python313.withPackages (
              ps: with ps; [
                mypy
                pylsp-mypy
                python-lsp-ruff
                python-lsp-server
              ]
            ))
          ];
        };
      }
    ));
}
