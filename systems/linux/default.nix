# systems/linux/default.nix
{ pkgs }:
{
  packages = {
    inherit (pkgs)
      espanso-wayland
      fuzzel
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
