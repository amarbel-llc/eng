#! /usr/bin/env -S bash -e
set -euo pipefail

exec @bwrap@ "$@"
