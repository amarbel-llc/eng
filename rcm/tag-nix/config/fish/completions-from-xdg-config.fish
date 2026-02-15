function __update_fish_complete_path_from_xdg --on-variable XDG_DATA_DIRS
  if not set -q XDG_DATA_DIRS; return; end

  for dir in (string split : -- $XDG_DATA_DIRS)
    set -l comp_dir "$dir/fish/vendor_completions.d"
    if test -d "$comp_dir"
      if not contains -- "$comp_dir" $fish_complete_path
        set -a fish_complete_path "$comp_dir"
      end
    end
  end
end

# Run once at load time for initial XDG_DATA_DIRS
__update_fish_complete_path_from_xdg
