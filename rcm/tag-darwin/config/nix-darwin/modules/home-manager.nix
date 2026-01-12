{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  home.stateVersion = "24.05";
  home.packages = [
    pkgs.bat
    pkgs.fzf
  ];
  programs.zsh.enable = true; # Home Manager will now manage .zshrc

  homebrew = {
    enable = true;

    # "zap" removes apps not listed here; "uninstall" just uninstalls them
    onActivation.cleanup = "zap";

    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    # Homebrew Taps (repositories)
    taps = [
      "homebrew/services"
    ];

    # Command-line tools (brew install)
    brews = [
      "ffmpeg"
    ];

    # GUI Applications (brew install --cask)
    casks = [
      "discord"
      "iterm2"
      "visual-studio-code"
      "spotify"
      "rectangles"
    ];

    # Mac App Store apps (mas search <app name> to find the ID)
    # masApps = {
    #   "Bitwarden" = 1352778147;
    #   "Tailscale" = 1475387142;
    # };
  };
}
