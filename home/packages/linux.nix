# Single source of truth for linux-only package set.
#
# Imported by both:
#   - home/linux.nix             (home-manager home.packages on linux)
#   - systems/linux/default.nix  (eng/result symlinkJoin via flake.nix)
#
# Excluded packages (provided by dedicated modules instead):
#   - mako   → services.mako in home/linux.nix
{ pkgs, pkgs-master }:
{
  inherit (pkgs-master)
    curlftpfs
    ddrescue
    glibcLocales
    hostess
    isolyzer
    libcdio
    ocrmypdf
    timidity
    ;

  inherit (pkgs)
    espanso-wayland
    fuzzel
    gftp
    keyd
    niri
    pcsclite
    pinentry-gnome3
    rofi
    wlogout
    ;
}
