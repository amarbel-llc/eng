function __fish_complete_empty
  complete \
    --command $argv[1] \
    --condition "__fish_contains_empty_args" \
    --no-files \
    --arguments (echo $argv[2..-1])
end

