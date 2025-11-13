{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.22.tar.gz";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      utils,
      fh,
    }:
    (utils.lib.eachDefaultSystem (
      system:
      let

        pkgs = import nixpkgs {
          config.allowUnfree = true;
          inherit system;
        };

        pkgs-stable = import nixpkgs-stable {
          config.allowUnfree = true;
          inherit system;
        };

      in
      {
        packages = {
          default =
            with pkgs;
            symlinkJoin {
              failOnMissing = true;
              name = "system-packages";
              paths = [
                age
                asdf
                asdf-vm
                bats
                coreutils
                crush
                csvkit
                curl
                curlftpfs
                dash
                ddrescue
                direnv
                eternal-terminal
                ffmpeg
                figlet
                fish
                fontconfig
                fswatch
                fh
                freeze
                gawk
                pkgs-stable.gftp
                gh
                git
                git-secret
                glibcLocales
                glow
                gnumake
                (pkgs.gnupg.override { withPcsc = true; })
                gnuplot
                gpgme
                graphviz
                gum
                helix
                hostess
                httpie
                hub
                imagemagick
                isolyzer
                j2cli
                jinja2-cli
                jq
                just
                lftp
                libcdio
                markscribe
                melt
                mods
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
                plantuml
                pop
                rcm
                rsync
                shellcheck
                shfmt
                silver-searcher
                skate
                socat
                sshpass
                timidity
                timg
                tldr
                tmux
                tree
                uv
                vhs
                watchexec
                websocat
                wget
                yubico-piv-tool
                yt-dlp
                yubikey-manager
                zstd
              ];
            };
        };
      }
    ));
}
