{
  description = "A flake providing moreutils without GNU Parallel";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/09eb77e94fa25202af8f3e81ddc7353d9970ac1b";
    nixpkgs.url = "github:NixOS/nixpkgs/d981d41ffe5b541eae3782029b93e2af5d229cc2";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs = { self, nixpkgs, utils, nixpkgs-stable }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Custom derivation that removes 'parallel'
        moreutils-no-parallel = pkgs.moreutils.overrideAttrs (oldAttrs: {
          postInstall = (oldAttrs.postInstall or "") + ''
            rm $out/bin/parallel
            rm $out/share/man/man1/parallel.1*
          '';
        });
      in
      {
        packages.default = moreutils-no-parallel;

        devShells.default = pkgs.mkShell {
          buildInputs = [ moreutils-no-parallel ];
        };
      }
    );
}