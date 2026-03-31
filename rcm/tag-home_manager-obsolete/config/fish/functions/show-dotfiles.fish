function show-dotfiles
  find $argv -maxdepth 1 -name '.*' -type f -o -name '.*' -type d | sort
end
