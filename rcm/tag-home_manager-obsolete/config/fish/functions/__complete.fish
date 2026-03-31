function __complete --description "helper function to generate commandline completions"
  __complete_from $command_path
  return $status
end

