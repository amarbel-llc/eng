
# TODO add support for ssh hosts
function z --description 'attach to or create an existing zmx session for a given directory'
  switch (count $argv)

    # use current directory
    case 0
      set -l z_path (string replace --regex "^$HOME/" '' $PWD)
      __z_attach_to_path $argv

    # use provided directory
    case 1
      if test -d $HOME/$argv
        zmx attach $arg_path_components
        return $status
      end

      if __z_has_session $argv
        zmx attach $arg_path_components
        return $status
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
  exec zmx attach $argv
end
