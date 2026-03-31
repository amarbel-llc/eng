
# hushing motd unless it has changed
if test -f /etc/motd
  mkdir -0 ~/.local/state

  if not cmp -s ~/.local/state/hushlogin /etc/motd
    tee ~/.local/state/hushlogin < /etc/motd
  end
end

