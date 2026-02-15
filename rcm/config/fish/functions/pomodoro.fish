function pomodoro
  set -l minutes 5

  if test (count $argv) -gt 0
    set minutes $argv[1]
  end

  # Phase 1 - Pre-break: detach all zmx sessions
  set -l zmx_dir
  if set -q ZMX_DIR
    set zmx_dir $ZMX_DIR
  else if set -q XDG_RUNTIME_DIR
    set zmx_dir $XDG_RUNTIME_DIR/zmx
  else
    set zmx_dir /tmp/zmx-(id -u)
  end

  if test -d $zmx_dir
    for sock in $zmx_dir/*
      if test -S $sock
        printf '\x04\x00\x00\x00\x00' | socat - UNIX-CONNECT:$sock 2>/dev/null
      end
    end
  end

  gum log --level info "Break starting: $minutes minutes"

  # Phase 2 - Countdown: lock terminal and run timer
  set -l saved_stty (stty -g)
  stty -echo -icanon -isig

  function __pomodoro_trap --on-signal INT --on-signal QUIT --on-signal TSTP
  end

  termdown --font banner3 --title "TAKE A BREAK" --blink --critical 30 {$minutes}m 2>/dev/null

  # Phase 3 - Post-break: restore terminal
  stty $saved_stty
  functions -e __pomodoro_trap

  gum log --level info "Break complete!"
  bell
end
