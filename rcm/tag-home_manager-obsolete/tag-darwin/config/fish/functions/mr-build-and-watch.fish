
function mr-build-and-watch
  argparse --name=mr-build-and-watch \
    'f/file=' \
    'changed_files=+' \
    'c/clear=?' \
    -- $argv
  or return

  function __mr-build-and-watch-echo
    echo (date) $argv
  end

  function __mr-build-and-watch-term_title
    set -l prefix $argv[1]
    echo -ne "\033]0;"$prefix" mr-build-and-watch\007"
  end

  function __mr-build-and-watch-building
    __mr-build-and-watch-term_title 🟡
  end

  function __mr-build-and-watch-success
    __mr-build-and-watch-term_title 🟢
    bell &
  end

  function __mr-build-and-watch-failure
    __mr-build-and-watch-term_title 🔴
    bell Sosumi &
  end

  function __mr-build-and-watch-exec --inherit-variable _flag_f
    set -l cmd_make make

    if set -q _flag_f
      set -a cmd_make --file $_flag_f
    end

    __mr-build-and-watch-building

    if $cmd_make $argv
      set -l success $status
      __mr-build-and-watch-success
    else
      set -l success $status
      __mr-build-and-watch-failure
    end
  end

  if set -q _flag_c
    clear
  end

  if test (count $_flag_changed_files) -gt 0
    __mr-build-and-watch-echo changes detected: $_flag_changed_files
  end

  __mr-build-and-watch-exec $argv

  echo

  if set -q _MR_BUILD_AND_WATCH_ONCE
    return $success
  end

  set -l excludes

  for f in (make --silent exclude $argv)
    set -a excludes --exclude (string trim $f)
  end

  set -l watch

  for f in (make --silent watch $argv)
    set -a watch (string trim $f)
  end

  if test (count $watch) -eq 0
    set watch (pwd)
  end

  echo watching $watch >&2
  echo excluding $excludes >&2

  set -l xargs_cmd mr-build-and-watch

  if set -q _flag_f
    set -a xargs_cmd --file $_flag_f
  end

  env _MR_BUILD_AND_WATCH_ONCE=1 \
    fswatch -or $excludes $watch \
    | xargs -I{} -L1 fish -c "$xargs_cmd --changed_files {} -- $argv"
end
