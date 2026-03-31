
function __cow-bell
  set -l postexec_status $argv

  for st in $postexec_status
    if test $st -ne 0
      bell Sosumi
      return
    end
  end

  bell
end
