
complete \
  --command z \
  --no-files \
  --keep-order \
  --arguments "(__z_complete)"

# TODO add support for ssh hosts
function __z_complete
  set -l areas $HOME/eng*

  for area in $HOME/eng*
    set -l area (string replace --regex "^$HOME/" '' $area)

    for repo in $HOME/$area/repos/*
      set -l repo (string replace --regex "^$HOME/$area/repos/" '' $repo)
      printf "%s/\t%s\n" $area/worktrees/$repo "new worktree"

      for worktree in $HOME/$area/worktrees/$repo/*
        set -l worktree (string replace --regex "^$HOME/$area/worktrees/$repo/" '' $worktree)
        printf "%s\t%s\n" $area/worktrees/$repo/$worktree "existing worktree"
      end
    end
  end
end

