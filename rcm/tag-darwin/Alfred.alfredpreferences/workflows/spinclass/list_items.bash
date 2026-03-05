#!/bin/bash -e

PATH="$HOME/eng/result/bin:$PATH"

query="$1"

items_json() {
  local items=()

  if [[ "$query" == new* ]]; then
    for dir in "$HOME/eng/repos" "$HOME/eng-etsy/repos"; do
      [[ -d "$dir" ]] || continue
      for repo in "$dir"/*/; do
        repo="${repo%/}"
        name="${repo##*/}"
        parent="${dir%/repos}"
        parent="${parent##*/}"
        items+=("{\"title\":\"$name\",\"subtitle\":\"$parent/repos/$name\",\"arg\":\"new:$repo\",\"autocomplete\":\"new $name\"}")
      done
    done
  else
    while IFS= read -r session; do
      [[ -n "$session" ]] || continue
      [[ "$session" != "no sessions found"* ]] || continue
      items+=("{\"title\":\"$session\",\"subtitle\":\"attach to session\",\"arg\":\"attach:$session\"}")
    done < <(sc list 2>/dev/null)
  fi

  local joined
  joined=$(printf ",%s" "${items[@]}")
  joined="${joined:1}"

  echo "{\"items\":[${joined}]}"
}

items_json
