
function z-merge --description 'merge current worktree back and detach from zmx session'
  set -l current_path (string replace --regex "^$HOME/" '' $PWD)
  set -l arg_path_components (string split / $current_path)

  set -l eng_area $arg_path_components[1]
  set -l repo $arg_path_components[3]
  set -l worktree $arg_path_components[4]

  if not test $arg_path_components[2] = worktrees
    gum log -t error "not in a worktree directory: $PWD"
    return 1
  end

  set -l repo_path $HOME/$eng_area/repos/$repo
  set -l worktree_path $HOME/$current_path

  if not test -d $repo_path
    gum log -t error "repository not found: $repo_path"
    return 1
  end

  gum log -t info "merging worktree: $worktree"

  pushd $repo_path
  git merge --no-ff $worktree -m "Merge worktree: $worktree"
  set -l merge_status $status
  popd

  if test $merge_status -ne 0
    gum log -t error "merge failed, not removing worktree"
    return $merge_status
  end

  gum log -t info "removing worktree: $worktree_path"
  git -C $repo_path worktree remove $worktree_path

  gum log -t info "detaching from zmx session"
  zmx detach
end
