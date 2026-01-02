function fish_title
  set -l prefix ""

  if set -q fish_private_mode
    set prefix 🔒
  end

  if set -q ZMX_SESSION
    echo $prefix"z.$ZMX_SESSION"
  else
    echo $prefix""(prompt_pwd)
  end
end

