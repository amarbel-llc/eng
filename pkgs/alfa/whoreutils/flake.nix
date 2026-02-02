{
  description = "A flake providing moreutils without GNU Parallel";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
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