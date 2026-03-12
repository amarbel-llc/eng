#!/bin/bash -e

laptop="eDP-1"

if grep -q open /proc/acpi/button/lid/*/state; then
  notify-send -t 5000 "lid open"
  niri msg output "$laptop" on
else
  notify-send -t 5000 "lid closed"
  niri msg output "$laptop" off
fi
