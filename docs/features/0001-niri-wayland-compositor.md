---
status: exploring
date: 2026-03-12
promotion-criteria: niri session appears on login screen, daily-drivable for one week without falling back to sway
---

# Niri Wayland Compositor

## Problem Statement

The current desktop uses sway, a manual-tiling Wayland compositor. Niri offers a
scrollable-tiling model that may better fit workflows with many side-by-side
windows and frequent workspace rearrangement. Evaluating niri requires making it
available via the existing nix linux system packages and exposing it as a
selectable session on the login screen.
