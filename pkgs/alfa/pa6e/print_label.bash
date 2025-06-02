#! /usr/bin/env -S bash -ex

qr="$1"
nix run . label.md
img="$(realpath "label.md-trimmed.html.pdf.png")"
mv "$img" old/label.png
pushd old
uv run peripage -p A6p -m "$peri_secondary" -i "label.png" -c 2 -b 30

sleep 10

if [[ -n "$qr" ]]; then
  uv run peripage -p A6p -m $peri_secondary -q "$qr" -c 2
fi
