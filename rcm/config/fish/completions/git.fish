
set __git_complete_aliases_commit commit
set __git_complete_aliases_checkout co checkout
set __git_complete_aliases_branch br branch
set __git_complete_aliases_show show
set __git_complete_aliases \
  (git config list --name-only | grep alias | cut -d. -f2)


__fish_complete_empty \
  git \
  $__git_complete_aliases_commit \
  $__git_complete_aliases_checkout \
  $__git_complete_aliases_branch \
  $__git_complete_aliases_show \
  $__git_complete_aliases \
  rm

complete \
  --command git \
  --no-files \
  --condition "__fish_seen_subcommand_from $__git_complete_aliases_checkout; and not __fish_seen_subcommand_from --" \
  --arguments "(__git_complete_branches)"

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

