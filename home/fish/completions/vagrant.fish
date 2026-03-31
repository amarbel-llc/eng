

complete \
  -c vagrant \
  -f \
  -n "__fish_seen_subcommand_from box remove" \
  -a "(__fish_print_vagrant_boxes)"

function __fish_print_vagrant_boxes
  set -l boxes (vagrant box list)

  if test $status -eq 0
    echo -n $boxes | awk '{print $1}'
  end
end
