#! /bin/bash -e

laptop="eDP-1"

swaymsg output "*" scale 1.8

if grep -q open /proc/acpi/button/lid/*/state; then
  notify-send -t 5000 "lid open"

  # Default wallpaper (more resolutions are available in /usr/share/backgrounds/sway/)
  # TODO
  output "$laptop" bg /usr/share/backgrounds/sway/Sway_Wallpaper_Blue_1920x1080.png fill

  swaymsg output "$laptop" enable
else
  notify-send -t 5000 "lid closed"
  swaymsg output "$laptop" disable
fi
