{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/d981d41ffe5b541eae3782029b93e2af5d229cc2";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/09eb77e94fa25202af8f3e81ddc7353d9970ac1b";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      nixpkgs-stable,
    }:
    utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          inherit (pkgs.stdenv.hostPlatform) parsed;
          version = "0.1.0";
          os = parsed.kernel.name;
          arch = parsed.cpu.name;
          binaryName = "zmx-${os}-${arch}";

          download = pkgs.writeShellApplication {
            name = "download";

            runtimeInputs = with pkgs; [
              gnutar
              wget
            ];

            text = ''
              dir_output="$PWD"

              function download_one() {
                os_arch="$1"

                url="https://zmx.sh/a/zmx-${version}-$os_arch.tar.gz"

                {
                  dir_archive="$(mktemp -d)"
                  pushd "$dir_archive"

                  wget -O archive.tar.gz "$url"
                  tar xf archive.tar.gz
                  mv zmx "$dir_output/zmx-''${os_arch/#macos/darwin}"
                }
              }

              os_arch_combos=(
                "linux-x86_64"
                "linux-aarch64"
                "macos-x86_64"
                "macos-aarch64"
              )

              for os_arch in "''${os_arch_combos[@]}"; do
                download_one "$os_arch"
              done
            '';
          };
        in
        {
          apps.download = {
            type = "app";
            program = "${download}/bin/download";
          };

          packages.default = pkgs.stdenv.mkDerivation {
            pname = "zmx";
            version = version;

            src = ./.;

            # nativeBuildInputs = pkgs.lib.optionals isLinux [ pkgs.autoPatchelfHook ];
            # buildInputs = pkgs.lib.optionals isLinux [ pkgs.stdenv.cc.cc.lib ];

            installPhase = ''
              mkdir -p $out/bin
              cp ${binaryName} $out/bin/zmx
              chmod +x $out/bin/zmx
            '';
          };
        }
      );
}
