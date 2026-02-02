{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    dodder.url = "github:friedenberg/dodder?dir=go";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      utils,
      dodder,
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

        packages = {
          inherit (pkgs)
            age
            asdf
            asdf-vm
            bats
            coreutils
            crush
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

          gnupg = (pkgs.gnupg.override { withPcsc = true; });

          inherit (pkgs-stable)
            csvkit
            gftp
            ;

          dodder = dodder.packages.${system}.default;
        };

      in
      {
        packages.default = pkgs.symlinkJoin {
          failOnMissing = true;
          name = "system-packages";
          paths = builtins.attrValues packages;
        };

        devShells.default = pkgs.mkShell {
          packages = builtins.attrValues packages;
        };
      }
    ));
}
