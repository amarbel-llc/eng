{
  pkgs,
  pkgs-master,
  lib,
  ...
}:
let
  fishDir = ./fish;

  # Build attrset of xdg.configFile entries from a directory
  # e.g. mkFishFiles "functions" ./fish/functions ".fish" produces
  # { "fish/functions/foo.fish".source = ./fish/functions/foo.fish; ... }
  mkFishFiles =
    subdir: srcDir: suffix:
    let
      files = builtins.filter (f: lib.hasSuffix suffix f) (builtins.attrNames (builtins.readDir srcDir));
    in
    builtins.listToAttrs (
      map (f: {
        name = "fish/${subdir}/${f}";
        value = {
          source = srcDir + "/${f}";
        };
      }) files
    );
in
{
  programs.fish = {
    enable = true;
    package = pkgs-master.fish;

    shellInit = ''
      # Nix setup
      set -e NIX_PATH
      set -e GIT_SSH_COMMAND
      if test -f $HOME/.nix-profile/etc/profile.d/nix.fish
        source $HOME/.nix-profile/etc/profile.d/nix.fish
      end
      if test -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      end
      fish_add_path /nix/var/nix/profiles/default/bin
      fish_add_path $HOME/.nix-profile/bin

      # Paths
      fish_add_path $HOME/.local/bin
      fish_add_path -a /opt/homebrew/bin

      # EDITOR is set via home.sessionVariables

      # XDG completions watcher
      function __update_fish_complete_path_from_xdg --on-variable XDG_DATA_DIRS
        if not set -q XDG_DATA_DIRS; return; end

        for dir in (string split : -- $XDG_DATA_DIRS)
          set -l comp_dir "$dir/fish/vendor_completions.d"
          if test -d "$comp_dir"
            if not contains -- "$comp_dir" $fish_complete_path
              set -a fish_complete_path "$comp_dir"
            end
          end
        end
      end

      # Run once at load time for initial XDG_DATA_DIRS
      __update_fish_complete_path_from_xdg
    '';

    interactiveShellInit = ''
      # Cow bell on process exit
      function __cow_bell_on_process_exit --on-event fish_postexec
        set -l postexec_status $pipestatus

        if not set -q bell_on_exit
          return
        end

        __cow-bell $postexec_status
      end

      # Hush MOTD unless it has changed
      if test -f /etc/motd
        mkdir -p ~/.local/state

        if not cmp -s ~/.local/state/hushlogin /etc/motd
          tee ~/.local/state/hushlogin < /etc/motd
        end
      end
    ''
    + lib.optionalString pkgs.stdenv.isDarwin ''
      # SSH agent via launchd
      set -l launchd_ssh_auth_sock (launchctl getenv SSH_AUTH_SOCK)

      if ! test -S $launchd_ssh_auth_sock
        return
      end

      mkdir -p $HOME/.local/state/ssh

      ln -sf $launchd_ssh_auth_sock $HOME/.local/state/ssh/launchd-agent.sock
    ''
    + lib.optionalString pkgs.stdenv.isLinux ''
      # Locale archive for nix on non-NixOS Linux
      set -gx LOCALE_ARCHIVE /usr/lib/locale/locale-archive
    ''
    + ''
      # SSH client agent bootstrapping (skip if we're the SSH host)
      if test -z "$SSH_CLIENT"
        mkdir -p $HOME/.local/state/ssh

        set -l SSH_OLD_AUTH_SOCK $SSH_AUTH_SOCK

        if not test -S $HOME/.local/state/ssh/ssh-agent.sock
          rm -f $HOME/.local/state/ssh/ssh-agent.sock
          eval (ssh-agent -c) >/dev/null
          ln -s $SSH_AUTH_SOCK $HOME/.local/state/ssh/ssh-agent.sock
          set -e SSH_AUTH_SOCK
        end

        # Clean up stale ControlMaster sockets
        for sock in $HOME/.local/state/ssh/cm-*
          if not test -S $sock
            rm -f $sock
          end
        end

        set -gx SSH_AUTH_SOCK $SSH_OLD_AUTH_SOCK
      end

      # SSH host alias detection (only on SSH connections, top-level shell)
      if test $SHLVL -le 1; and test -n "$SSH_CLIENT"
        set -l ssh_alias_file $HOME/.config/ssh/alias
        if test -f $ssh_alias_file
          set -gx SSH_ALIAS (string trim (cat $ssh_alias_file))
        end

        mkdir -p $HOME/.local/state/ssh
        set -l file_ssh_client_agent $HOME/.local/state/ssh/ssh_client-agent.sock

        if test -L $file_ssh_client_agent; and not test -S $file_ssh_client_agent
          rm -f $file_ssh_client_agent
        end

        if test -S $file_ssh_client_agent
          gum log -t info "ssh-agent reused from: "(prompt_pwd $file_ssh_client_agent)
          set -x SSH_AUTH_SOCK $file_ssh_client_agent

        else if test -S $SSH_AUTH_SOCK
          gum log -t info "ssh-agent newly set: $SSH_AUTH_SOCK"
          ln -sf $SSH_AUTH_SOCK $file_ssh_client_agent
          set -x SSH_AUTH_SOCK $file_ssh_client_agent

        else if test -n "$SSH_AUTH_SOCK"
          gum log -t warn "ssh-agent set to non-sock file: $SSH_AUTH_SOCK!"

        else
          gum log -t warn "No ssh-agent forwarded set!"
        end
      end
    '';
  };

  xdg.configFile =
    # Functions (complete .fish files with function...end wrappers)
    mkFishFiles "functions" (fishDir + "/functions") ".fish"
    # Completions (.fish files)
    // mkFishFiles "completions" (fishDir + "/completions") ".fish"
    # Completions (non-.fish files like .awk)
    // mkFishFiles "completions" (fishDir + "/completions") ".awk"
    # conf.d (theme and key bindings)
    // mkFishFiles "conf.d" (fishDir + "/conf.d") ".fish"
    # Static assets
    // {
      "fish/fish.txt".source = fishDir + "/fish.txt";
    };
}
