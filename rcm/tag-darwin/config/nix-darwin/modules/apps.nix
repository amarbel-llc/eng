{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./apps-local.nix
  ];

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "none";
      upgrade = true;
      extraFlags = [
        "--verbose"
      ];
    };

    taps = [
      "FelixKratz/formulae"
    ];

    brews = [
      {
        name = "borders";
        start_service = true;
        restart_service = true;
      }

      {
        name = "sketchybar";
        start_service = true;
        restart_service = true;
      }
    ];

    casks = [
      "alfred"
      "bartender"
      "espanso"
      "finicky"
      "font-hack-nerd-font"
      "gcloud-cli"
      "hammerspoon"
      "karabiner-elements"
      "kitty"
      "tailscale-app"
    ];

    # Mac App Store apps (mas search <app name> to find the ID)
    masApps = {
      Cathode = 499233976;
      CheatSheet = 529456740;
      LocalSend = 1661733229;
      Meeter = 1510445899;
      Mousepose = 405904955;
      Okta = 490179405;
      PCalc = 403504866;
      Shush = 496437906;
      Soulver = 413965349;
      YubiKey = 638161122;
      Yubico = 1497506650;
      xScope = 889428659;
    };
  };
}
