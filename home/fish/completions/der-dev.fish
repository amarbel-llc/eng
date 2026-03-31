
complete \
  --command der-dev \
  --no-files \
  --arguments "(__der_dev_complete)"

function __der_dev_complete
  set -l in_progress (commandline -ct)
  set -l cmd (commandline -p --tokenize)
  set cmd $cmd[1] complete -in-progress=$in_progress $cmd[2..]
  $cmd
end
