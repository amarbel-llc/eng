function __fish_contains_empty_args --description "Checks if the current commandline is empty other than a command"
  if test (count (commandline -cpo)) -eq 1
    return 0
  end

  return 1
end
