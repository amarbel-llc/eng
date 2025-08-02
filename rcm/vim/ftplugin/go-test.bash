#! /usr/bin/env -S bash -e

# TODO move this to dev/dev-flake-templates/go
# PATH="$PATH:$(realpath "$(dirname "$0")/result/bin")"

test_one() (
  set -e
  no="$1"
  file="$2"
  pkg="$(dirname "$file")"
  tmp="$(mktemp -d)"
  trap "rm -r '$tmp'" EXIT

  pkg_rel="$(realpath --relative-to=. "$pkg")"

  if ! go test -c "./$pkg_rel/" -o "$tmp/tester" >"$tmp/out" 2>&1; then
    echo "not ok $no $pkg # failed to build tester" >&2
    cat "$tmp/out"
    exit 1
  fi

  if [[ ! -e "$tmp/tester" ]]; then
    echo "ok $no $pkg # no tests" >&2
    exit 0
  fi

  if ! "$tmp/tester" -test.v -test.timeout 1s >"$tmp/out" 2>&1; then
    echo "not ok $no $pkg" >&2
    cat "$tmp/out"
    exit 1
  fi

  echo "ok $no $pkg" >&2
)

echo "1..$#" >&2

export -f test_one
n_prc="$(nproc --all)"
parallel "-j$n_prc" test_one "{#}" "{}" ::: "$@"
