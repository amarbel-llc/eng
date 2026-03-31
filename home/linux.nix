{
  pkgs,
  lib,
  pkgs-master,
  inputs,
  ...
}:
let
  system = "x86_64-linux";
in
{
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  news.display = "silent";

  home.packages =
    # Common packages (from nixpkgs-master)
    (with pkgs-master; [
      age
      asdf
      asdf-vm
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
      gopls
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
    ])
    # Common packages (from nixpkgs stable)
    ++ (with pkgs; [
      csvkit
      gftp
    ])
    # Linux-specific packages
    ++ (with pkgs; [
      espanso-wayland
      fuzzel
      keyd
      mako
      niri
      pcsclite
      pinentry-gnome3
      rofi
      wlogout
    ])
    # Repo packages
    ++ [
      inputs.crap.packages.${system}.default
      inputs.dodder.packages.${system}.default
      inputs.ess-ess-hatch.packages.${system}.default
      inputs.just-us.packages.${system}.default
      inputs.moxy.packages.${system}.default
      inputs.nebulous.packages.${system}.default
      inputs.pivy.packages.${system}.default
      inputs.shdoc.packages.${system}.default
      inputs.ssh-agent-mux.packages.${system}.default
      inputs.tommy.packages.${system}.default
    ]
    # Infrastructure packages (explicit)
    # bob-all bundles gh man pages that collide with the standalone gh package,
    # so give it lower priority.
    ++ [
      inputs.purse-first.packages.${system}.purse-first
      (lib.lowPrio inputs.bob.packages.${system}.default)
      inputs.bob.packages.${system}.tap-dancer-bash
    ];
}
