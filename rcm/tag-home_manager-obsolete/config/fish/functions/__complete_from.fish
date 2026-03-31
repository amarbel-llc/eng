function __complete_from --description "helper function to generate commandline completions"
  set last_char (commandline | string sub --start -1)

  # we strip the command name fro the commandline
  set current_command_line (commandline | string trim | string split " ")[2..-1]

  # if the last char isn't a space, we strip the last incomplete word from the
  # commandline
  if not test "$last_char" = " "
    set current_command_line (string split -- " " $current_command_line)[1..-2]
  end

  # strip flags out of the commandline
  set current_command_line (echo $current_command_line | string replace --regex -- " -+\w+" "" | string split " ")

  set command_path $argv

  set l (count $current_command_line)

  if test $l -gt (count $command_path)
    return 0
  end

  if test "$current_command_line[1..$l]" = "$command_path[1..$l]" -o $l -eq 0
    set i (math $l + 1)
    echo -- "$command_path[$i]"
  end

  return 0
end

