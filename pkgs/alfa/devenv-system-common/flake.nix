{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.22.tar.gz";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";
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

      in
      {
        packages = {
          default = with pkgs; symlinkJoin {
            failOnMissing = true;
            name = "system-packages";
            paths = [
              age
              asdf
              asdf-vm
              bats
              # cdparanoia
              coreutils
              csvkit
              curl
              curlftpfs
              dash
              ddrescue
              direnv
              ffmpeg
              figlet
              fish
              fontconfig
              fswatch
              fh
              gawk
              pkgs-stable.gftp
              git
              git-secret
              glibcLocales
              gnumake
              (pkgs.gnupg.override { withPcsc = true; })
              gnuplot
              gpgme
              graphviz
              hostess
              httpie
              hub
              imagemagick
              isolyzer
              jq
              just
              lftp
              libcdio
              # moreutils
              neovim
              nix-direnv
              nixpkgs-fmt
              ocrmypdf
              pandoc
              paperkey
              parallel
              pay-respects
              # pcsclite
              # pinentry
              plantuml
              rcm
              rsync
              shellcheck
              shfmt
              silver-searcher
              socat
              sshpass
              timidity
              timg
              tldr
              tmux
              tree
              uv
              watchexec
              websocat
              wget
              yubico-piv-tool
              yt-dlp
              # yubikey-manager
              zstd
            ];
          };
        };
      })
    );
}
