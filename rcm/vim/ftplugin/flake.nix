{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs = { self, nixpkgs, utils, nixpkgs-stable }:
    (utils.lib.eachDefaultSystem
      (system:
        let

          pkgs = import nixpkgs {
            inherit system;
          };

          golines = with pkgs; buildGoModule rec {
            pname = "golines";
            name = "golines";
            version = "0.11.0";

            src = fetchFromGitHub {
              owner = "segmentio";
              repo = "golines";
              rev = "v${version}";
              sha256 = "sha256-2K9KAg8iSubiTbujyFGN3yggrL+EDyeUCs9OOta/19A=";
            };

            vendorSha256 = "sha256-rxYuzn4ezAxaeDhxd8qdOzt+CKYIh03A9zKNdzILq18=";
          };

          gofumpt = with pkgs; buildGoModule rec {
            pname = "gofumpt";
            name = "gofumpt";
            version = "0.5.0";

            # currently fails with an error bc of this garbage:
            # https://github.com/mvdan/gofumpt/blob/39163cc6b32cdf077a3cf08a68379851560cf81f/main_test.go#L17
            doCheck = false;

            src = fetchFromGitHub {
              owner = "mvdan";
              repo = "gofumpt";
              rev = "v${version}";
              sha256 = "sha256-3buGLgxAaAIwLXWLpX+K7VRx47DuvUI4W8vw4TuXSts=";
            };

            vendorSha256 = "sha256-W0WKEQgOIFloWsB4E1RTICVKVlj9ChGSpo92X+bjNEk=";
          };

        in
        rec {
          packages = {
            all = pkgs.symlinkJoin {
              name = "all";
              paths =
                with
                pkgs;
                [
                  bash
                  bats
                  gofumpt
                  golines
                  gotools
                  jq
                  pandoc
                  parallel
                  shellcheck
                  shfmt
                  # must be last due to bs in postBuild
                  go_1_19
                  nodePackages.eslint
                  nodePackages.prettier
                ];

              postBuild = ''
                for f in "$out/lib/node_modules/.bin/"*; do
                  path="$(readlink --canonicalize-missing "$f")"
                  ln -s "$path" "$out/bin/$(basename $f)"
                done

                find \
                  "$out/share/go/bin/" \
                  ! -type d \
                  -exec mv {} "$out/bin/" \;
              '';
            };

            default = packages.all;
          };

          # devShells.default = pkgs.mkShell {
          #   buildInputs = with pkgs; [
          #     fish
          #     go
          #     gopls
          #     gotools
          #   ];
          # };
        })
    );
}
