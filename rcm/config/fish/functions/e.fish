set -l editor_name (basename $EDITOR)

function e --inherit-variable editor_name --wraps=$editor_name
  printf '\033]2;%s\033\\' $editor_name
  $EDITOR $argv
end
