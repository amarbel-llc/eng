
complete \
  --command git \
  --condition "__fish_seen_subcommand_from rm; and not __fish_contains_opt cached" \
  --long-option "cached" \
  --exclusive \
  --description "unstage and remove paths only from the index. Working tree files, whether modified or not, will be left alone."

complete \
  --command git \
  --condition "__fish_seen_subcommand_from rm" \
  --short-option "r" \
  --exclusive \
  --description "recursive removal when a leading directory name is given."

