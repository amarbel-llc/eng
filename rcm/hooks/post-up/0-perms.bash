#! /usr/bin/env -S bash -e

chmod 700 "$HOME"/.config/ssh
chmod 700 "$HOME"/.config/gnupg

chmod 600 "$HOME"/.config/ssh/*
chmod 600 "$HOME"/.config/gnupg/*

# disabled for now because `*.pub` is used in sshconfig `IdentityFile` fields,
# and OpenSSH treats that as a private key
# chmod 644 $HOME/.config/ssh/*.pub
