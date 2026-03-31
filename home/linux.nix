{
  pkgs,
  lib,
  pkgs-master,
  inputs,
  ...
}:
{
  imports = [
    ./common.nix
    ./pivy-agent.nix
    ./repo-packages.nix
    ./ssh-agent-mux.nix
  ];

  home.stateVersion = "24.11";

  # Mako notification daemon
  services.mako = {
    enable = true;
    settings = {
      "" = {
        group-by = "app-name,summary";
      };
      "app-name=kitty summary=\"Claude Code\"" = {
        default-timeout = 5000;
      };
    };
  };

  # GTK 3 appearance
  gtk = {
    enable = true;
    theme.name = "Breeze";
    iconTheme.name = "breeze";
    cursorTheme = {
      name = "breeze_cursors";
      size = 24;
    };
    font = {
      name = "Noto Sans";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = false;
      gtk-button-images = true;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-animations = true;
      gtk-menu-images = true;
      gtk-modules = "colorreload-gtk-module";
      gtk-primary-button-warps-slider = false;
      gtk-toolbar-style = 3;
      gtk-xft-dpi = 98304;
    };
  };

  home.packages =
    (with pkgs-master; [
      curlftpfs
      ddrescue
      glibcLocales
      hostess
      isolyzer
      libcdio
      ocrmypdf
      timidity
    ])
    ++ (with pkgs; [
      gftp
    ])
    ++ (with pkgs; [
      espanso-wayland
      fuzzel
      keyd
      niri
      pcsclite
      pinentry-gnome3
      rofi
      wlogout
    ]);
}
