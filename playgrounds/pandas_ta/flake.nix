{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/0590cd39f728e129122770c029970378a79d076a";
    nixpkgs-master.url = "github:NixOS/nixpkgs/e91b6d2274ad8a171dbae66723cd6d9afd36e508";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    python.url = "github:amarbel-llc/bob?dir=devenvs/python";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-master
    , utils
    , python
    ,
    }:
    utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };

    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [ ];

        inputsFrom = [
          python.devShells.${system}.default
        ];
      };
    }
    );
}
