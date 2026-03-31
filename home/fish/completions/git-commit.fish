
complete \
  --command git \
  --condition "__fish_seen_subcommand_from commit" \
  --long-option "fixup" \
  --description "Construct a commit message for use with rebase --autosquash."

complete \
  --command git \
  --no-files \
  --keep-order \
  --condition "__fish_seen_subcommand_from commit; and __fish_contains_opt fixup" \
  --arguments "(__git_complete_commits_since_master)"

