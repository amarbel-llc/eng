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
      nixpkgs-master,
      utils,
    }:
    (utils.lib.eachDefaultSystem (
      system:

      let

        pkgs = import nixpkgs {
          config.allowUnfree = true;
          inherit system;
        };

        pkgs-master = import nixpkgs-master {
          config.allowUnfree = true;
          inherit system;
        };

        packages = {
          inherit (pkgs-master)
            age
            asdf
            asdf-vm
            bats
            claude-code
            coreutils
            crush
            curl
            curlftpfs
            dash
            ddrescue
            direnv
            eternal-terminal
            expect
            ffmpeg
            figlet
            fish
            fontconfig
            fswatch
            fh
            freeze
            gawk
            gh
            git
            git-secret
            glibcLocales
            glow
            gnumake
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
            neovim
            nix-direnv
            nixpkgs-fmt
            ocrmypdf
            pandoc
            paperkey
            parallel
            pay-respects
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
            zstd
            # moreutils
            # pcsclite
            ;

          gnupg = (pkgs-master.gnupg.override { withPcsc = true; });

          inherit (pkgs)
            csvkit
            gftp
            ;
        };

      in
      {
        packages =
          packages
          // {
            default = pkgs-master.symlinkJoin {
              failOnMissing = true;
              name = "system-packages";
              paths = builtins.attrValues packages;
            };
          };

        devShells.default = pkgs-master.mkShell {
          packages = builtins.attrValues packages;
        };
      }
    ));
}
