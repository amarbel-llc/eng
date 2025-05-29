#! /bin/bash -e

PATH="$HOME/eng/pkgs/zit/go/zit/build:$HOME/eng/result/bin:$HOME/eng/pkgs/chrest/go/build:$PATH"

export EDITOR="$HOME/.local/bin/vim"

pushd "$HOME/workspace" >/dev/null
exec "$@"
