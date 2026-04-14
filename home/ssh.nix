{
  identity,
  lib,
  ...
}:
let
  signingKeyBare = lib.removePrefix "key::" identity.gitSigningKey;
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
        UserKnownHostsFile ~/.config/ssh/rcm/known_hosts ~/.config/ssh/rcm/known_hosts-user
    '';

    "ssh/keys-allowed_signers-user".text = "${identity.gitUserEmail} ${signingKeyBare}\n";
  };
}
