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


  # if test -n "$SSH_CLIENT" -a -n "$TMUX"
  #   echo $prefix$_

  # else if set -q ZMX_SESSION
  #   echo -n "$prefix[$ZMX_SESSION] $_"

  # else if test -n "$TMUX" -a -n "$ssh_config_current_alias"
  #   echo $prefix$ssh_config_current_alias

  # else if test -z "$TMUX" -a -n "$ssh_config_current_alias"
  #   echo "$prefix$ssh_config_current_alias: " (prompt_pwd)

  # else
  #   echo $prefix$_

  # end
end

