# systems/linux/default.nix
{ pkgs }:
{
  packages = {
    inherit (pkgs)
      espanso-wayland
      keyd
      mako
      pcsclite
      pinentry-gnome3
      rofi
      wlogout
      ;
  };
}
