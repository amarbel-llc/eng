function fish_title
  # TODO stop kitty from shownig just the command title
  set -l prefix ""

  if set -q fish_private_mode
    set prefix 🔒
  end

  if set -q ZMX_SESSION
    set prefix $prefix"z.$ZMX_SESSION"
  end

  echo $prefix (prompt_pwd)
end

