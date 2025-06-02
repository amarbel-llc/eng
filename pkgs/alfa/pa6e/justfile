
secret-edit:
  git secret reveal
  ${EDITOR:-${VISUAL:-vi}} .env
  git secret hide
  git add .env.secret
  git add .gitsecret

deploy:
  rm -fr dist
  uv build
  uv publish

version-edit:
  #! /bin/bash -e

  git diff --exit-code -s || (echo "unstaged changes, refusing to release" && exit 1)

  file_version="./pyproject.toml"

  ${EDITOR:-${VISUAL:-vi}} "$file_version"
  git add "$file_version"
  git diff --exit-code -s "$file_version" || (echo "version wasn't changed" && exit 1)
  git commit -m "bumped version to $(cat "$file_version")"

release: version-edit && deploy
  git push origin
  # version="$("$file_version")"
  # git diff --exit-code -s || (echo "unstaged changes, refusing to release" && exit 1)
  # git tag "$version" -m "$version"
