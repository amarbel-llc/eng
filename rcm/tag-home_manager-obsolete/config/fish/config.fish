# vim: set syntax=fish:

for file in (find ~/.config/fish -iname '*-config.fish' -print0 | string split0 | sort)
  __source_if_exists $file
end

