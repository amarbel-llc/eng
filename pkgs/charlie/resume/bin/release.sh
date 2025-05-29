#! /bin/bash -xe

${EDITOR:-${VISUAL:-vi}} ./VERSION
git add ./VERSION
git diff --exit-code -s ./VERSION || (echo "version wasn't changed" && exit 1)
git commit -m "bumped version to $(cat ./VERSION)"
git push origin master

version="v$(cat ./VERSION)"

make

str_snake_case="$(tr "[:upper:]" "[:lower:]" <NAME | tr " " "_")"
file_out_base="build/${str_snake_case}_resume"

git diff --exit-code -s || (echo "unstaged changes, refusing to release" && exit 1)

function run_with_gh_token() {
  set +x
  echo "+ $*"
  GITHUB_TOKEN="$(gpg --quiet --decrypt ~/.config/hub.secret)" "$@"
}

run_with_gh_token hub release create \
  -a "$file_out_base.html" \
  -a "$file_out_base.txt" \
  -a "$file_out_base.pdf" \
  -m "$version" \
  "$version"
