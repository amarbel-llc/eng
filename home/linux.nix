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
    ./repo-packages.nix
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
