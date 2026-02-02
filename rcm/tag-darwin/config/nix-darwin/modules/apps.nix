{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
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
        restart_service = true;
      }

      {
        name = "sketchybar";
        restart_service = true;
      }
    ];

    casks = [
      "alfred"
      "amethyst"
      "bartender"
      "espanso"
      "finicky"
      "font-hack-nerd-font"
      "gcloud-cli"
      "hammerspoon"
      "helium"
      "karabiner-elements"
      "kitty"
      "tailscale-app"
      "visual-studio-code"
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
      xScope = 889428659;
      Yubico = 1497506650;
      YubiKey = 638161122;
    };
  };
}
