function __complete_with --description "use in `complete` to generated completions for specific command strings. Last should be a function that generates completions"
  set last_char (commandline | string sub --start -1)

  set current_command_line (commandline | string trim | string split " ")[2..-1]

  if not test "$last_char" = " "
    set current_command_line (string split -- " " $current_command_line)[1..-2]
  end

  set command_path $argv[1..-2]
  set l (count $command_path)
  set completion_function $argv[-1]

  if test "$current_command_line[1..$l]" = "$command_path"
    eval "$completion_function"
    return $status
  end

  __complete_from $command_path
  return $status
end

