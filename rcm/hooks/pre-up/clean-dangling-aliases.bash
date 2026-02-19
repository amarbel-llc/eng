#! /usr/bin/env -S bash -e
# @brief remove dangling symlinks from git aliases directory

aliases_dir="$HOME/.config/git/aliases/"

[[ -d "$aliases_dir" ]] || exit 0

find "$aliases_dir" -type l ! -exec test -e {} \; -delete
