function allow
  argparse --name="allow" -N1 -X1 "c/cert" -- $argv
  or return

  # if not test -x $argv
  #   echo "$argv is not an executable" >&2
  #   exit 1
  # end

  if test -z $_flag_cert
    set -l sha (santactl fileinfo --key SHA-256 $argv)
    su -l daddy -c "sudo santactl rule --allow --sha256 $sha"
  else
    set -l sha (santactl fileinfo --cert-index 1 --key SHA-256 $argv)
    su -l daddy -c "sudo santactl rule --allow --certificate --sha256 $sha"
  end
end
