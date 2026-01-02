#! /usr/bin/env -S bash -e
# @brief updates /etc/shells

gum log -l warn "TODO fix updating /bin/fish as it's currently broken due to policy-kit errors"
exit 0

EXE_NEW_FISH="$(readlink "$(which fish)")"

if ! gum confirm "Update /bin/fish to $EXE_NEW_FISH?" --default=false; then
  exit 0
fi

EXE_SYSTEM_FISH=/bin/fish

pkexec sudo ln -sf "$EXE_NEW_FISH" "$EXE_SYSTEM_FISH"
