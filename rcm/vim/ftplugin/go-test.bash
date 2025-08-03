#! /usr/bin/env -S bash -e

# TODO move this to dev/dev-flake-templates/go
# PATH="$PATH:$(realpath "$(dirname "$0")/result/bin")"

dir_script="$(dirname "$0")"
export dir_script

test_one() (
  set -e
  no="$1"
  file="$2"
  pkg="$(dirname "$file")"
  tmp="$(mktemp -d)"
  trap "rm -r '$tmp'" EXIT

  pkg_rel="$(realpath --relative-to=. "$pkg")"

  go_test_compile() {
    go test -c "./$pkg_rel/" -o "$tmp/tester"
  }

  if ! go_test_compile >"$tmp/out" 2>&1; then
    echo "not ok $no $pkg # failed to build tester" >&2
    cat "$tmp/out"
    exit 1
  fi

  if [[ ! -e "$tmp/tester" ]]; then
    echo "ok $no $pkg # no tests" >&2
    exit 0
  fi

  go_test_format() {
    "$dir_script"/go-test-format.bash ./"$pkg"
  }

  go_test() {
    set -o pipefail
    "$tmp/tester" -test.count=1 -test.v -test.timeout 1s | go_test_format
  }

  if ! go_test >"$tmp/out" 2>&1; then
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
