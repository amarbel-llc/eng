# systems/linux/default.nix
{ pkgs, pkgs-master }:
{
  packages = {
    # Linux-only entries that need glibc-only paths or otherwise don't
    # build on darwin. Mirrored on the home-manager side by home/linux.nix.
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
      mako
      niri
      pcsclite
      pinentry-gnome3
      rofi
      wlogout
      ;
  };
}
