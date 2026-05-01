{
  config,
  identity,
  lib,
  ...
}:
let
  signingKeyBare = lib.removePrefix "key::" identity.gitSigningKey;
  isSshHost = identity.isSshHost or false;
  knownHostsFiles =
    if isSshHost
    then "~/.config/ssh/known_hosts"
    else "~/.config/ssh/rcm/known_hosts ~/.config/ssh/rcm/known_hosts-user";
in
{
  xdg.configFile = {
    "ssh/config".text = ''
      # vim: ft=sshconfig

      Include ~/.config/ssh/rcm/config-client
      Include ~/.config/ssh/config-recurse
      Include ~/.config/ssh/rcm/config-user

      Include ~/.config/ssh/config-local

      Host *
        UserKnownHostsFile ${knownHostsFiles}
    '';

    "ssh/keys-allowed_signers-user".text = "${identity.gitUserEmail} ${signingKeyBare}\n";
  };

  # Stock OpenSSH only consults ~/.ssh/config; only the Debian/Ubuntu build
  # falls back to ~/.config/ssh/config. Symlink so any nix-built ssh in any
  # closure (e.g. pkgs.sshfs's wrapped openssh) resolves the same Host
  # aliases as /usr/bin/ssh, without needing the wrapped openssh from
  # ess-ess-hatch on PATH.
  home.file.".ssh/config".source = config.xdg.configFile."ssh/config".source;
}
