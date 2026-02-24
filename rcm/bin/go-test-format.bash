#! /bin/bash -e

dir_rel_to="$1"

while IFS= read -r line; do
  if [[ $line =~ ^[[:space:]]*([^/][^|]*\.go)(.*)$ ]]; then
    filename="${BASH_REMATCH[1]}"
    rest="${BASH_REMATCH[2]}"

    full_path="$dir_rel_to/$filename"

    if [[ -f $full_path ]]; then
      echo "${full_path}${rest}"
    else
      echo "$line"
    fi
  else
    echo "$line"
  fi
done
