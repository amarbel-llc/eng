
function __source_if_exists
  for some_path in $argv
    if not test -e $some_path
      continue
    end

    source $some_path
  end
end
