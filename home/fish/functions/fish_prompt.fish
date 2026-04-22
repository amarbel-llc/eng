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

  printf '%s' (fish_git_prompt)
  set -l parens

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1
    set -l conflict_count (git diff --name-only --diff-filter=U 2>/dev/null | count)

    if test $conflict_count -gt 0
      printf ' %s⚠%s' (set_color red) (set_color normal)
    end

    set -l latest_tag (git tag --sort=-creatordate 2>/dev/null | head -n1)

    if test -n "$latest_tag"
      set -l ahead (git rev-list --count $latest_tag..HEAD 2>/dev/null)
      set -l behind (git rev-list --count HEAD..$latest_tag 2>/dev/null)
      set -l tag_segment "tag: $latest_tag"

      if test -n "$ahead" -a "$ahead" != 0
        set tag_segment "$tag_segment "(set_color green)"+$ahead"(set_color normal)
      end

      if test -n "$behind" -a "$behind" != 0
        set tag_segment "$tag_segment "(set_color red)"-$behind"(set_color normal)
      end

      set -a parens $tag_segment
    end

    set -l stash_count (git stash list | count)

    if test $stash_count -gt 0
      set -a parens "stashes: $stash_count"
    end

    set -l worktree_count (math (git worktree list | count) - 1)

    if test $worktree_count -gt 0
      set -a parens "worktrees: $worktree_count"
    end
  end

  printf ' '

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
