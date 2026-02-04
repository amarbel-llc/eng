
# TODO add support for ssh hosts
function z --wraps zmx --description 'attach to or create an existing zmx session for a given directory'
  switch (count $argv)

    # use current directory
    case 0
      set -l session_name (__z_get_session_name_or_directory_for_path $PWD)
      zmx attach $session_name $SHELL
      return $status

    # use provided directory or session name
    case 1 2
      if test -d $argv[1]
        pushd $argv[1]
        set -l session_name (__z_get_session_name_or_directory_for_path $argv)

        if test -n $argv[2]
          if not command -q $argv[2]
            set -l session_name $session_name.$argv[2]
          end
        end

        zmx attach $session_name $SHELL
        return $status
      else
        zmx attach $argv $SHELL
        return $status
      end

    # use provided directory or session name and run provided util
    case '*'
      set -l util $argv[2..]
      set -l util_name $argv[2]

      if test -d $argv[1]
        pushd $argv[1]
        set -l session_name (__z_get_session_name_or_directory_for_path $argv[1]).$util_name
        zmx attach $session_name $SHELL -c $util
        return $status
      else
        zmx attach $argv[1].$util_name $SHELL -c $util
        return $status
      end

  end
end

function __z_get_session_name_or_directory_for_path
  if test -f "$argv/TERMTABS_NAME"
    string trim (cat "$argv/TERMTABS_NAME")
    return $status
  end

  echo (basename "$argv" | tr -d ".")
  return $status
end
