{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.22.tar.gz";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , utils
    , fh
    }:
    (utils.lib.eachDefaultSystem
      (system:
      let

        pkgs = import nixpkgs
          {
            inherit system;
          };

        pkgs-stable = import nixpkgs-stable
          {
            inherit system;
          };

        tex = pkgs.texlive.withPackages (ps: [
          ps.metapost
          ps.dvisvgm
          ps.dvipng # for preview and export as html
        ]);

      in
      {
        packages = {
          default = with pkgs; symlinkJoin {
            failOnMissing = true;
            name = "system-packages";
            paths = [
              tex
            ];
          };
        };
      })
    );
}
