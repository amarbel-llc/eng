#! /usr/bin/env -S bash -e
# @brief updates keyd config

if ! command -v keyd >/dev/null; then
  exit 0
fi

DIR_KEYD_CONFIG_HOME="$HOME/.config/keyd/"

if [[ ! -d $DIR_KEYD_CONFIG_HOME ]]; then
  exit 0
fi

HELPER="$HOME/.local/bin/keyd-config-up"

mkdir -p "$(dirname "$HELPER")"
cat >"$HELPER" <<'EOM'
#! /usr/bin/env -S bash -e

DIR_KEYD_CONFIG_HOME="${1}"

if [[ -z $DIR_KEYD_CONFIG_HOME ]]; then
  echo "No keyd config home supplied, aborting" >&2
  exit 1
fi

sudo rsync -a --chmod=D755,F644 --chown=root:root "$DIR_KEYD_CONFIG_HOME" /etc/keyd/
sudo systemctl restart keyd
sudo systemctl status keyd
EOM
chmod +x "$HELPER"

if ! gum confirm "Update keyd config?" --default=false; then
  exit 0
fi

pkexec bash "$HELPER" "$DIR_KEYD_CONFIG_HOME"
