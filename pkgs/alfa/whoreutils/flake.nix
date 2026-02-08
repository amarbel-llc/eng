{
  description = "A flake providing moreutils without GNU Parallel";

  inputs = {
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs = { self, nixpkgs, utils, nixpkgs-master }:
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