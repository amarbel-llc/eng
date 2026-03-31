#! /usr/bin/env -S awk -F: -f

/# Files/ {
  searching = 1
}

/^[^\s\t#].+:/ {
  if (searching && found_target)
    printf "%s\ttarget\n", $1
}

{
  found_target = 1
}

/^# Not a target/ {
  found_target = 0
}
