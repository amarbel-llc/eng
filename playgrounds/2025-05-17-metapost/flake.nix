{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.22.tar.gz";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
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
