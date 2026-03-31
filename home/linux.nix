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
  imports = [ ./common.nix ];

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
