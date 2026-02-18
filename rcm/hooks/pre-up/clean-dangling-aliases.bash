#! /usr/bin/env -S bash -e
# @brief remove dangling symlinks from git aliases directory

find "$HOME/.config/git/aliases/" -type l -xtype l -delete 2>/dev/null || true
