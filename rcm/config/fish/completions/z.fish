
complete \
  --command z \
  --no-files \
  --keep-order \
  --arguments "(__z_complete)"

# TODO examine using the local script but remotely to remain consistent
function __z_complete_remote --description 'provide completions for remote hosts'
  set -l host vm-sfriedenberg

  # Try to fetch remote worktrees via SSH with timeout
  set -l remote_paths (ssh -o ConnectTimeout=2 $host "find ~/eng*/worktrees -mindepth 2 -maxdepth 3 -type d 2>/dev/null | sed 's|^$HOME/||'" 2>/dev/null)

  if test $status -eq 0
    for remote_path in $remote_paths
      set -l path_parts (string split / $remote_path)

      # Format: eng<area>/worktrees/<repo> (new worktree)
      if test (count $path_parts) -eq 3
        printf "%s:%s/\t%s\n" $host $remote_path "remote: new worktree"

      # Format: eng<area>/worktrees/<repo>/<worktree> (existing)
      else if test (count $path_parts) -eq 4
        printf "%s:%s\t%s\n" $host $remote_path "remote: existing worktree"
      end
    end
  end
end

function __z_complete
  # Local completions
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

  # Remote completions
  __z_complete_remote
end

