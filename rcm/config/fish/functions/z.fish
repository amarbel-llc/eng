
function __z_parse_target --description 'parse target into host and path components'
  set -l target $argv[1]

  if string match -q '*:*' -- $target
    set -l parts (string split ':' -- $target)
    echo $parts[1]  # host
    echo $parts[2]  # path
  else
    echo ""  # no host
    echo $target  # path
  end
end

function __z_attach_remote --description 'attach to zmx session on remote host'
  set -l host $argv[1]
  set -l path $argv[2]

  gum log -t info "connecting to remote session on $host: $path"
  ssh -t $host "zmx attach $path"
  return $status
end

function z --description 'attach to or create an existing zmx session for a given directory'
  switch (count $argv)

    # use current directory
    case 0
      set -l z_path (string replace --regex "^$HOME/" '' $PWD)
      __z_attach_to_path $z_path

    # use provided directory or remote target
    case 1
      # Parse target to check if it's remote
      set -l parse_result (__z_parse_target $argv[1])
      set -l host $parse_result[1]
      set -l path $parse_result[2]

      # Handle remote session
      if test -n "$host"
        __z_attach_remote $host $path
        return $status
      end

      # Handle local session (existing logic)
      if test -d $HOME/$argv
        zmx attach $argv
        set -l zmx_status $status
        __z_cd_to_repo $argv
        return $zmx_status
      end

      if __z_has_session $argv
        zmx attach $argv
        set -l zmx_status $status
        __z_cd_to_repo $argv
        return $zmx_status
      end

      __z_attach_to_path $argv
      return $status

    case '*'
      gum log -t error more than one argument provided
      return 1
  end
end

function __z_has_session
  zmx list | awk '{split($1, a, "="); $2=$2; $3=$3; print a[2]}' | grep -q $argv>/dev/null
end

function __z_cd_to_repo
  set -l arg_path_components (string split / $argv[1])

  set -l eng_area $arg_path_components[1]
  set -l repo $arg_path_components[3]

  if not test $arg_path_components[2] = worktrees
    return 0
  end

  set -l repo_path $HOME/$eng_area/repos/$repo
  if test -d $repo_path
    cd $repo_path
  end
end

# eng*<area>/worktrees/<repo>/<worktree>
function __z_attach_to_path
  set -l arg_path_components (string split / $argv[1])

  set -l eng_area $arg_path_components[1]
  set -l repo $arg_path_components[3]
  set -l worktree $arg_path_components[4]

  if not test $arg_path_components[2] = worktrees
    gum log -t error invalid path provided: $argv
    return 1
  end

  set -l repo_path $HOME/$eng_area/repos/$repo
  echo repo_path: $repo_path
  echo argv: $argv

  mkdir -p $HOME/$argv

  git -C $repo_path worktree add $HOME/$argv

  pushd $HOME/$argv
  zmx attach $argv
  popd

  cd $repo_path
end
