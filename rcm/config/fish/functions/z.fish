
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

function __z_post_zmx --description 'offer rebase and merge after zmx exits for worktree paths'
  set -l z_path $argv[1]
  set -l arg_path_components (string split / $z_path)

  if not test $arg_path_components[2] = worktrees
    return 0
  end

  set -l eng_area $arg_path_components[1]
  set -l repo $arg_path_components[3]
  set -l worktree $arg_path_components[4]

  set -l repo_path $HOME/$eng_area/repos/$repo
  set -l worktree_path $HOME/$z_path

  set -l default_branch (git -C $repo_path branch --show-current)

  if test -z "$default_branch"
    gum log -t warn "could not determine default branch"
    return 0
  end

  set -l action (gum choose --header "Post-zmx actions for $worktree:" \
    "Pull + Rebase + Merge + Remove worktree + Push" \
    "Rebase + Merge + Remove worktree + Push" \
    "Rebase + Merge + Remove worktree" \
    "Rebase + Merge" \
    "Rebase")

  if test -z "$action"
    return 0
  end

  if string match -q "Pull *" -- $action
    git -C $repo_path pull
    if test $status -ne 0
      gum log -t error "pull failed"
      return 1
    end
    gum log -t info "pulled $default_branch from origin"
  end

  git -C $worktree_path rebase $default_branch
  if test $status -ne 0
    gum log -t error "rebase failed"
    return 1
  end
  gum log -t info "rebased $worktree onto $default_branch"

  if string match -q "*Rebase" -- $action
    return 0
  end

  git -C $repo_path merge $worktree --ff-only
  if test $status -ne 0
    gum log -t error "merge failed (not fast-forward)"
    return 1
  end
  gum log -t info "merged $worktree into $default_branch"

  if string match -q "*Merge" -- $action
    return 0
  end

  git -C $repo_path worktree remove $HOME/$z_path
  gum log -t info "removed worktree $worktree"

  git -C $repo_path branch -d $worktree
  if test $status -ne 0
    gum log -t error "failed to delete branch $worktree"
    return 1
  end
  gum log -t info "deleted branch $worktree"

  if string match -q "*Remove worktree" -- $action
    return 0
  end

  git -C $repo_path push origin $default_branch
  if test $status -ne 0
    gum log -t error "push failed"
    return 1
  end
  gum log -t info "pushed $default_branch to origin"
end

function z --description 'attach to or create an existing zmx session for a given directory'
  switch (count $argv)

    # use current directory
    case 0
      set -l z_path (string replace --regex "^$HOME/" '' $PWD)
      __z_attach_to_path $z_path

    # use provided directory or remote target
    case 1
      set -l parse_result (__z_parse_target $argv[1])
      set -l host $parse_result[1]
      set -l path $parse_result[2]

      if test -n "$host"
        __z_attach_remote $host $path
        return $status
      end

      if test -d $HOME/$argv; or __z_has_session $argv
        __z_attach_existing $argv
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

function __z_attach_existing --description 'attach to existing zmx session and run post-zmx hooks'
  set -l z_path $argv[1]

  zmx attach $z_path
  set -l zmx_status $status
  __z_cd_to_repo $z_path
  __z_post_zmx $z_path
  return $zmx_status
end

function __z_create_worktree --description 'create a new git worktree and apply rcm-worktrees overlay'
  set -l eng_area $argv[1]
  set -l repo_path $argv[2]
  set -l worktree_path $argv[3]

  mkdir -p $worktree_path
  git -C $repo_path worktree add $worktree_path
  __z_apply_rcm_worktrees_overlay $eng_area $worktree_path
end

function __z_apply_rcm_worktrees_overlay --description 'copy rcm-worktrees dotfiles into a worktree'
  set -l eng_area $argv[1]
  set -l worktree_path $argv[2]

  set -l rcm_worktrees $HOME/$eng_area/rcm-worktrees
  if not test -d $rcm_worktrees
    return 0
  end

  for src in (find $rcm_worktrees -type f)
    set -l rel (string replace "$rcm_worktrees/" "" $src)
    set -l dest $worktree_path/.$rel
    if not test -f $dest
      mkdir -p (dirname $dest)
      cp $src $dest
    end
  end
end

# eng*<area>/worktrees/<repo>/<worktree>
function __z_attach_to_path
  set -l arg_path_components (string split / $argv[1])

  set -l eng_area $arg_path_components[1]
  set -l repo $arg_path_components[3]

  if not test $arg_path_components[2] = worktrees
    gum log -t error invalid path provided: $argv
    return 1
  end

  set -l repo_path $HOME/$eng_area/repos/$repo
  set -l worktree_path $HOME/$argv

  __z_create_worktree $eng_area $repo_path $worktree_path

  pushd $worktree_path
  zmx attach $argv
  popd

  cd $repo_path
  __z_post_zmx $argv
end
