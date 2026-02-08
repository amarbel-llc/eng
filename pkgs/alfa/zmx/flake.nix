{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      nixpkgs-master,
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

          package = pkgs.stdenv.mkDerivation {
            pname = "zmx";
            version = version;

            src = ./.;

            # nativeBuildInputs = pkgs.lib.optionals isLinux [ pkgs.autoPatchelfHook ];
            # buildInputs = pkgs.lib.optionals isLinux [ pkgs.stdenv.cc.cc.lib ];

            installPhase = ''
              mkdir -p $out/bin
              cp ${binaryName} $out/bin/zmx
              chmod +x $out/bin/zmx

              mkdir -p $out/share/fish/vendor_completions.d
              cp completions/zmx.fish $out/share/fish/vendor_completions.d/
            '';
          };
        in
        {
          apps.download = {
            type = "app";
            program = "${download}/bin/download";
          };

          packages.default = package;

          devShells.default = pkgs.mkShell {
            buildInputs = [ package ];
            # shellHook = ''
            #   export fish_complete_path="''${fish_complete_path:+''$fish_complete_path}${package}/share/fish/vendor_completions.d"
            # '';
            packages = [ package ];
          };
        }
      );
}
