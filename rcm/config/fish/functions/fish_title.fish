function fish_title
  set -l prefix ""

  if set -q fish_private_mode
    set prefix 🔒
  end

  if set -q SPINCLASS_SESSION
    set prefix $prefix"sc/$SPINCLASS_SESSION"
    echo $prefix
    return
  else if set -q ZMX_SESSION
    set prefix $prefix"z/$ZMX_SESSION"
    echo $prefix
    return
  end

  echo $prefix (prompt_pwd)
end

