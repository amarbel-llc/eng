
function __cow_bell_on_process_exit --on-event fish_postexec
  set -l postexec_status $pipestatus

  if not set -q bell_on_exit
    return
  end

  __cow-bell $postexec_status
end
