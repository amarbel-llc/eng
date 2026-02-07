{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.22.tar.gz";
    nixpkgs-master.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-master
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

        pkgs-master = import nixpkgs-master
          {
            inherit system;
          };

        tex = pkgs-master.texlive.withPackages (ps: [
          ps.metapost
          ps.dvisvgm
          ps.dvipng # for preview and export as html
        ]);

      in
      {
        packages = {
          default = with pkgs-master; symlinkJoin {
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
