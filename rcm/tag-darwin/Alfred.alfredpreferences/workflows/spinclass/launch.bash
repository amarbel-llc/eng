#!/bin/bash -e

PATH="$HOME/eng/result/bin:$PATH"

arg="$1"
action="${arg%%:*}"
value="${arg#*:}"

case "$action" in
  new)
    /Applications/kitty.app/Contents/MacOS/kitty --directory "$value" sc new
    ;;
  attach)
    /Applications/kitty.app/Contents/MacOS/kitty sc new "$value"
    ;;
esac
