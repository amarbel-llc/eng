#! /usr/bin/env -S bash -e
# @brief updates keyd config

if ! command -v keyd >/dev/null; then
  exit 0
fi

DIR_KEYD_CONFIG_HOME="$HOME/.config/keyd/"

if [[ ! -d $DIR_KEYD_CONFIG_HOME ]]; then
  exit 0
fi

# Skip the prompt if /etc/keyd/ is already in sync with the source. Mirror
# the production rsync (no --delete), so files present only in /etc/keyd/
# are NOT a diff the apply step would resolve — ignore them. If /etc/keyd/
# is missing entirely (first install), fall through to the prompt.
if [[ -d /etc/keyd ]]; then
  DIFF_OUTPUT="$(diff -rq "$DIR_KEYD_CONFIG_HOME" /etc/keyd/ 2>/dev/null | grep -v '^Only in /etc/keyd' || true)"
  if [[ -z $DIFF_OUTPUT ]]; then
    exit 0
  fi
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
