function fish_prompt --description 'Write out the prompt'
  set -l last_status $status
  printf ' '

  if not set -q __fish_prompt_normal
    set -g __fish_prompt_normal (set_color normal)
  end

  # PWD
  set_color $fish_color_cwd
  #echo -n (prompt_pwd)
  set_color normal

  set -g __fish_git_prompt_showuntrackedfiles true
  set -g __fish_git_prompt_showcolorhints true
  set -g __fish_git_prompt_showdirtystate true
  printf '%s ' (fish_git_prompt)
  set -l parens

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1
    set -l stash_count (git stash list | count)

    if test $stash_count -gt 0
      set -a parens "stashed: $stash_count"
    end

    set -l worktree_count (git worktree list | count)

    if test $stash_count -gt 1
      set -a parens "worktrees: $worktree_count"
    end
  end

  set -l job_count (jobs | wc -l)

  if test $job_count -gt 0
    set -a parens "jobs: $job_count"
  end

  if test (count $parens) -gt 0
    printf '(%s) ' (string join ", " $parens)
  end

  if set -q bell_on_exit
    printf '🔔 ' $stash_count
  end

  if not test $last_status -eq 0
    set_color $fish_color_error
  end

  if set -q VIRTUAL_ENV
    echo -n -s (set_color -b blue white) "(" (basename "$VIRTUAL_ENV") ")" (set_color normal) " "
  end

  echo ''

  if test "$TERMKIT_HOST_APP" = "Cathode"
    echo -n "> "
  else
    echo -n "\$ "
  end

  set_color normal
end
