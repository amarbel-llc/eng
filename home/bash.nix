{ pkgs-master, ... }:
{
  programs.bash = {
    enable = true;

    # Boromir-style dev VMs hand out /bin/bash as the login shell via
    # the directory service (SSSD/LDAP). Standalone home-manager
    # cannot edit that, so we hop into fish from .bash_profile on
    # interactive logins. The fish path is the literal nix store path
    # so we don't depend on PATH having been populated yet.
    profileExtra = ''
      export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE="$HOME/.config/gcloud/credential_helper.sh"

      if [[ $- == *i* ]]; then
        SHELL=${pkgs-master.fish}/bin/fish exec ${pkgs-master.fish}/bin/fish -l
      fi
    '';
  };
}
