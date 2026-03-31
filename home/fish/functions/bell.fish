function bell
  function __bell_macos
    set -l sound glass

    if test (count $argv) -gt 0
      set sound $argv[1]
    end

    set sound (string sub -l1 (string upper $sound))(string sub -s2 $sound)

    afplay /System/Library/Sounds/$sound.aiff &
    disown $last_pid
  end

  switch (uname -s)
    case "Darwin"
      __bell_macos $argv

    case '*'
      tput bel
  end
end
