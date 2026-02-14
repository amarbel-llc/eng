
set __git_complete_aliases_commit commit
set __git_complete_aliases_checkout co checkout
set __git_complete_aliases_branch br branch
set __git_complete_aliases_show show


__fish_complete_empty \
  git \
  $__git_complete_aliases_commit \
  $__git_complete_aliases_checkout \
  $__git_complete_aliases_branch \
  $__git_complete_aliases_show \
  merge \
  worktree \
  rm

complete \
  --command git \
  --condition "__fish_contains_empty_args" \
  --no-files \
  --arguments "(shdoc-fish_completion $HOME/.config/git/aliases/*)"

complete \
  --command git \
  --no-files \
  --condition "__fish_seen_subcommand_from merge $__git_complete_aliases_checkout; and not __fish_seen_subcommand_from --" \
  --arguments "(__git_complete_branches)"

complete \
  --command git \
  --no-files \
  --condition "__fish_seen_subcommand_from worktree; and __fish_seen_subcommand_from remove" \
  --arguments "(__git_complete_worktrees)"

source $HOME/.config/fish/completions/git-commit.fish
source $HOME/.config/fish/completions/git-diff.fish
source $HOME/.config/fish/completions/git-rm.fish

__fish_complete_tail_files git

# COMPLETIONS

function __git_complete_commits_since_master
  #set merge_base (git merge-base --fork-point master HEAD)
  git log --format="%h%x09%s"
end

function __git_complete_branches
  git branch \
  --sort=-committerdate \
  --format "%(refname:short)%09%(creatordate:relative)"
end

function __git_complete_worktrees
  git worktree list --porcelain | while read -l line
    if string match -q 'worktree *' $line
      set -l path (string replace 'worktree ' '' $line)
      printf "%s\n" $path
    end
  end
end

# CONDITIONS

function __git_complete_needs_branch
  return (__fish_seen_subcommand_from \
    merge show \
    $__git_complete_aliases_checkout \
    $__git_complete_aliases_show \
    $__git_complete_aliases_branch; or \
    __fish_contains_opt fixup \
    )
end

