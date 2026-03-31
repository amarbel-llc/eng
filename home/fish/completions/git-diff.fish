
complete \
  --command git \
  --condition "__fish_seen_subcommand_from diff" \
  --long-option "word-diff" \
  --description "Show a word diff"

complete \
  --command git \
  --condition "__fish_seen_subcommand_from diff" \
  --long-option "no-index" \
  --description "Compare two paths on the filesystem regardless of working tree"

