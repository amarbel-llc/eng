#! /usr/bin/env -S bash -e

our_bash="$(readlink "$HOME/eng/result/bin/bash")"
mkdir -p ~/.config/direnv/
cat - > ~/.config/direnv/direnv.toml <<-EOM
bash_path = "$our_bash"
EOM
