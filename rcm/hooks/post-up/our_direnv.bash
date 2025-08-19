#! /usr/bin/env -S bash -e

git_root="$(git rev-parse --show-toplevel)"
our_direnv="$(readlink "$git_root/result/bin/direnv")"
echo 'generating `~/.config/fish/direnv-config.fish`' >&2
"$our_direnv" hook fish > ~/.config/fish/direnv-config.fish

echo 'formatting `~/.config/fish/direnv-config.fish`' >&2
vim \
  -e \
  -s \
  --clean \
  -c 'normal gg=G' \
  -c 'wq' \
  ~/.config/fish/direnv-config.fish \
  </dev/null

echo 'direnv config updated.' >&2
echo 'If fish shows an error like `fish: Command not found: /nix/store/*/bin/direnv`:' >&2
echo 'run `exec fish` to reload the config.' >&2
