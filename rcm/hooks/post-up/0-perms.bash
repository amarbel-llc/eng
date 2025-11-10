#! /usr/bin/env -S bash -e

export PATH="$HOME/eng/result/bin:$PATH"

gum log -l info "updating directory permissions"

chmod 700 "$HOME"/.config/ssh
chmod 700 "$HOME"/.config/gnupg

chmod 600 "$HOME"/.config/ssh/*
chmod 600 "$HOME"/.config/gnupg/*

# disabled for now because `*.pub` is used in sshconfig `IdentityFile` fields,
# and OpenSSH treats that as a private key
# chmod 644 $HOME/.config/ssh/*.pub
