{
  pkgs,
  lib,
  pkgs-master,
  inputs,
  ...
}:
{
  imports = [
    ./fish.nix
    ./git.nix
  ];

  programs.home-manager.enable = true;

  news.display = "silent";

  home.packages =
    (with pkgs-master; [
      age
      asdf
      asdf-vm
      claude-code
      coreutils
      crush
      curl
      dash
      eternal-terminal
      expect
      ffmpeg
      figlet
      fontconfig
      fswatch
      fh
      freeze
      gawk
      gh
      git
      git-secret
      glow
      gnumake
      gnuplot
      gopls
      gpgme
      graphviz
      gum
      helix
      httpie
      hub
      imagemagick
      j2cli
      jinja2-cli
      jq
      markscribe
      melt
      mods
      neovim
      nixpkgs-fmt
      pandoc
      paperkey
      parallel
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
    ++ (with pkgs; [
      csvkit
    ]);

  # Kitty terminal
  programs.kitty = {
    enable = true;
    font = {
      name = "Input Mono";
      size = 18.0;
    };
    shellIntegration.mode = "no-title";
    settings = {
      tab_bar_style = "custom";
      tab_title_template = "\" {index}: {title} \"";
      tab_bar_edge = "top";
      text_composition_strategy = "legacy";
      window_padding_width = 1;
      confirm_os_window_close = 0;
      macos_quit_when_last_window_closed = "yes";
      macos_option_as_alt = "yes";
      allow_remote_control = "yes";
    };
    keybindings = {
      "ctrl+q>r" = "load_config_file";
      "ctrl+q>:" = "show_scrollback";
      "ctrl+q>v" = ''launch --allow-remote-control --type=overlay nvim -c "normal! G"'';
      "ctrl+c" = "copy_or_noop";
      "cmd+v" = "paste_from_clipboard";
      "ctrl+q>c" = "new_tab";
      "ctrl+q>n" = "next_tab";
      "ctrl+q>p" = "previous_tab";
      "ctrl+q>x" = "close_tab";
      "ctrl+q>1" = "goto_tab 1";
      "ctrl+q>2" = "goto_tab 2";
      "ctrl+q>3" = "goto_tab 3";
      "ctrl+q>4" = "goto_tab 4";
      "ctrl+q>5" = "goto_tab 5";
      "ctrl+q>6" = "goto_tab 6";
      "ctrl+q>7" = "goto_tab 7";
      "ctrl+q>8" = "goto_tab 8";
      "ctrl+q>9" = "goto_tab 9";
      "ctrl+q>0" = "goto_tab 10";
    };
    themeFile = "Solarized_Dark";
  };

  # Custom kitty tab bar renderer
  xdg.configFile."kitty/tab_bar.py".source = ./kitty-tab_bar.py;

  # Direnv with nix-direnv integration
  programs.direnv = {
    enable = true;
    package = pkgs-master.direnv;
    nix-direnv.enable = true;
    config = {
      whitelist.prefix = [ "$HOME/eng" ];
    };
    stdlib = ''
      layout_flake_with_hook() {
        use_flake "$@"

        local result_share
        result_share="$(realpath ./result/share 2>/dev/null)" || true

        if [[ -n "$result_share" && -d "$result_share" ]]; then
          if [[ ":''${XDG_DATA_DIRS:-}:" != *":''${result_share}:"* ]]; then
            export XDG_DATA_DIRS="''${result_share}''${XDG_DATA_DIRS:+:''${XDG_DATA_DIRS}}"
          fi
        fi
      }

      on_direnv_loaded() {
        echo "correct"
      }

      direnv_apply_hooks() {
        on_direnv_loaded
      }
    '';
  };
}
