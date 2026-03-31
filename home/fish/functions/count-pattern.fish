# vim: set syntax=fish:

function count-pattern
  ag $argv[1] \
  --only-matching \
  --nofile \
  --nocolor \
  --nobreak \
  -- $argv[2..] \
  | sort \
  | uniq -c \
  | sort -r \
  | sort -nr
end
