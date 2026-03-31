complete \
  --command make \
  --no-files \
  --arguments "(__make_complete_targets)"

complete \
  --command make \
  --no-files \
  --old-option rpn \
  --description "Print debugging info" \

complete \
  --command make \
  --no-files \
  --short-option r \
  --long-option no-builtin-rules \
  --description "Eliminate use of the built-in implicit rules" \

complete \
  --command make \
  --no-files \
  --short-option p \
  --long-option print-data-base \
  --description "Print the data base that results from reading the makefiles" \

complete \
  --command make \
  --no-files \
  --short-option n \
  --long-option dry-run \
  --description "Print the commands that would be executed, but do not execute them" \

function __make_complete_targets
  make -pn ^ /dev/null \
  | $HOME/.config/fish/completions/__make_print_targets.awk
end
