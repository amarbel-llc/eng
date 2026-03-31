
function __zmx_commands
  printf '
attach\tCreate or attach to a session
detach\tDetach all clients from current session (ctrl+\ for current client)
list\tList active sessions
kill\tKill a session and all attached clients
version\tShow version information
help\tShow this help message
'
end

function __zmx_sessions
  zmx list | awk '{split($1, a, "="); $2=$2; $3=$3; print a[2] "\t" $2 ", " $3}'
end

complete \
  --command zmx \
  --condition "__fish_contains_empty_args" \
  --no-files \
  --arguments "(__zmx_commands)"

complete \
  --command zmx \
  --no-files \
  --condition "__fish_seen_subcommand_from attach; and not __fish_seen_subcommand_from --" \
  --arguments "(__zmx_sessions)"

complete \
  --command zmx \
  --no-files \
  --condition "__fish_seen_subcommand_from kill; and not __fish_seen_subcommand_from --" \
  --arguments "(__zmx_sessions)"
