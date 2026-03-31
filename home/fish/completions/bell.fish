
complete -c bell -f -a "(__bell_complete_sound_args)"

function __bell_complete_sound_args
  find /System/Library/Sounds -type f -print0 | xargs -0 -L1 -I_ bash -c "basename -s .aiff '_'"
end
