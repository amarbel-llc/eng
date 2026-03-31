function __fish_complete_tail_files
  complete \
    --command $argv[1] \
    --condition "__fish_seen_subcommand_from --" \
    --force-files
end

