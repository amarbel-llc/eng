{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nixpkgs-stable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2411.717296.tar.gz";
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
              # pinentry
              parallel
              plantuml
              rcm
              rsync
              shellcheck
              shfmt
              silver-searcher
              socat
              sshpass
              thefuck
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
