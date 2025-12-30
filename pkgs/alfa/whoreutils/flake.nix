{
  description = "A flake providing moreutils without GNU Parallel";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
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