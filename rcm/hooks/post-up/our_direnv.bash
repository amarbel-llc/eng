#! /usr/bin/env -S bash -e

our_direnv="$(readlink "$HOME/eng/result/bin/direnv")"
"$our_direnv" hook fish > ~/.config/fish/direnv-config.fish

# format the file
vim \
  -e \
  -s \
  --clean \
  -c 'normal gg=G' \
  -c 'wq' \
  ~/.config/fish/direnv-config.fish \
  </dev/null
