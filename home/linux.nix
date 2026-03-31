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
      mako
      niri
      pcsclite
      pinentry-gnome3
      rofi
      wlogout
    ]);
}
