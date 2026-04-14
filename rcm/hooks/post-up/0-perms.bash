#! /usr/bin/env -S bash -e
# @brief updates permissions

# /usr/bin/find ~/.* -xtype l -delete

gum log -l info "updating directory permissions"

chmod 700 "$HOME"/.config/ssh
chmod 700 "$HOME"/.config/ssh/rcm

chmod 600 "$HOME"/.config/ssh/rcm/*

# disabled for now because `*.pub` is used in sshconfig `IdentityFile` fields,
# and OpenSSH treats that as a private key
# chmod 644 $HOME/.config/ssh/rcm/*.pub
#
: "${XDG_CACHE_HOME:=$HOME/.cache}"
mkdir -p "$XDG_CACHE_HOME"
chmod 700 "$HOME"
