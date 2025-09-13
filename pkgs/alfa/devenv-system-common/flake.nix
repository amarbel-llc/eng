{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
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
