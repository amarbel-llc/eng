{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
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
            termdown
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
