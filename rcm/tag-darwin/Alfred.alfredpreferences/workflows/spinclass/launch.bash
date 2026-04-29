#!/bin/bash -e

arg="$1"
action="${arg%%:*}"
value="${arg#*:}"

case "$action" in
new)
  "/Applications/Nix Apps/kitty.app/Contents/MacOS/kitty" --directory "$value" sc new
  ;;
attach)
  "/Applications/Nix Apps/kitty.app/Contents/MacOS/kitty" sc new "$value"
  ;;
esac
