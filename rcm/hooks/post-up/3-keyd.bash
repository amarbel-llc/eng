#! /usr/bin/env -S bash -e
# @brief updates keyd config

if ! command -v keyd >/dev/null; then
  exit 0
fi

DIR_KEYD_CONFIG_HOME="$HOME/.config/keyd/"

if [[ ! -d $DIR_KEYD_CONFIG_HOME ]]; then
  exit 0
fi

FILE_KEYD_CONFIG_UP="/usr/local/bin/keyd-config-up"

if [[ ! -e $FILE_KEYD_CONFIG_UP ]]; then
  cat - >&2 <<-EOM
  keyd-config-up script not installed
  copy the following to $FILE_KEYD_CONFIG_UP:

EOM

  cat - <<-EOM
  #! /usr/bin/env -S bash -e

  DIR_KEYD_CONFIG_HOME="${1}"

  if [[ -z "$DIR_KEYD_CONFIG_HOME" ]]; then
    echo "No keyd config home supplied, aborting" >&2
    exit 1
  fi

  sudo rsync -a --chmod=D755,F644 --chown=root:root "$DIR_KEYD_CONFIG_HOME" /etc/keyd/
  sudo systemctl restart keyd
  sudo systemctl status keyd
EOM
fi

gum log -l warn "TODO update $(basename "$0") to install $FILE_KEYD_CONFIG_UP automatically"

if ! gum confirm "Update keyd config?" --default=false; then
  exit 0
fi

# assuming we're on linux because keyd exists

pkexec bash "$FILE_KEYD_CONFIG_UP" "$DIR_KEYD_CONFIG_HOME"
