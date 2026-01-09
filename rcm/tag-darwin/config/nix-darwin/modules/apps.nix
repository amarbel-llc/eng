{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.neovim
    pkgs.git
  ];

  homebrew = {
    enable = true;
    casks = [
      "aerospace"
      "alfred"
      "amethyst"
      "bartender"
      "espanso"
      "finicky"
      "font-hack-nerd-font"
      "gcloud-cli"
      "helium"
      "karabiner-elements"
      "kitty"
      "sketchybar"
      "tailscale-app"
      "visual-studio-code"
    ];
  };
}
