{
  config,
  pkgs,
  lib,
  pkgs-master,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    ./fish.nix
    ./git.nix
    ./npm.nix
    ./ssh.nix
    ./xdg.nix
    ./wrappers.nix
  ];

  programs.home-manager.enable = true;
  programs.man = {
    enable = true;
    generateCaches = true;
  };

  # Pinned to the home-manager default (true), made explicit so the
  # comment below has a line to attach to.
  #
  # Building this man page evaluates nixpkgs'
  # `nixos/lib/make-options-doc/default.nix:optionsJSON`, whose
  # `options = builtins.unsafeDiscardStringContext (builtins.toJSON
  # optionsNix)` env var produces the eval-time warning:
  #
  #   warning: Using 'builtins.derivation' to create a derivation named
  #   'options.json' that references the store path '<nixpkgs source>'
  #   without a proper context.
  #
  # The warning is Determinate Nix-specific (added in
  # DeterminateSystems/nix-src#56); upstream Nix does not emit it.
  #
  # Why we accept it today: the `unsafeDiscardStringContext` is
  # deliberate upstream — `optionsNix.<...>.declarations` carries paths
  # into nixpkgs module files, and propagating that context would pull
  # the entire module tree into the manual's closure for what is
  # semantically just text. `disallowedReferences = [ filteredModules
  # libPath pkgsLibPath ]` is the actual correctness guard; the warning
  # is cosmetic.
  #
  # When this becomes unacceptable (e.g. Det Nix promotes the warning
  # to an error, or it spams CI logs we care about): cheap exit is to
  # set this to `false`, which loses `man home-configuration.nix` but
  # eliminates the trigger end-to-end. Upstream tracking issues:
  #   - NixOS/nixpkgs#485682  (open, reopened 2026-02-03 after the
  #     attempted fix in nixpkgs#485913 only shifted the warning from
  #     `builtins.toFile` to `builtins.derivation`)
  #   - nix-community/home-manager#7935
  #   - NixOS/nix#14011  (proposes `builtin:write-file` as proper fix)
  manual.manpages.enable = true;

  news.display = "silent";

  home.packages = builtins.attrValues (
    import ./packages/common.nix { inherit pkgs pkgs-master; }
  );

  home.sessionVariables = {
    EDITOR = "nvim";
    SHELL = "${pkgs-master.fish}/bin/fish";
    TAP_DANCER_LIB = "${inputs.tap.packages.${system}.tap-dancer-bash}/share/tap-dancer/lib";
    ZIG_GLOBAL_CACHE_DIR = "${config.xdg.cacheHome}/zig";
  };

  # Kitty terminal
  programs.kitty = {
    enable = true;
    package = pkgs-master.kitty;
    font = {
      name = "Input Mono";
      size = 18.0;
    };
    shellIntegration.mode = "no-title";
    settings = {
      tab_bar_style = "custom";
      tab_title_template = "\" {index}: {title} \"";
      tab_bar_edge = "top";
      text_composition_strategy = "legacy";
      window_padding_width = 1;
      confirm_os_window_close = 0;
      macos_quit_when_last_window_closed = "yes";
      macos_option_as_alt = "yes";
      allow_remote_control = "yes";
    };
    keybindings = {
      "ctrl+q>r" = "load_config_file";
      "ctrl+q>:" = "show_scrollback";
      "ctrl+q>v" = ''launch --allow-remote-control --type=overlay nvim -c "normal! G"'';
      "ctrl+c" = "copy_or_noop";
      "cmd+v" = "paste_from_clipboard";
      "ctrl+q>c" = "new_tab";
      "ctrl+q>n" = "next_tab";
      "ctrl+q>p" = "previous_tab";
      "ctrl+q>x" = "close_tab";
      "ctrl+q>1" = "goto_tab 1";
      "ctrl+q>2" = "goto_tab 2";
      "ctrl+q>3" = "goto_tab 3";
      "ctrl+q>4" = "goto_tab 4";
      "ctrl+q>5" = "goto_tab 5";
      "ctrl+q>6" = "goto_tab 6";
      "ctrl+q>7" = "goto_tab 7";
      "ctrl+q>8" = "goto_tab 8";
      "ctrl+q>9" = "goto_tab 9";
      "ctrl+q>0" = "goto_tab 10";
    };
    themeFile = "Solarized_Dark";
  };

  # Custom kitty tab bar renderer
  xdg.configFile."kitty/tab_bar.py".source = ./kitty-tab_bar.py;

  # Direnv with nix-direnv integration
  programs.direnv = {
    enable = true;
    package = pkgs-master.direnv;
    nix-direnv.enable = true;
    config = {
      whitelist.prefix = [ "$HOME/eng" ];
    };
    stdlib = ''
      # Append a path to a colon-separated variable if not already present.
      # Appending (not prepending) means devshell entries win on conflicts;
      # home-manager fills gaps the devshell doesn't cover.
      _hm_append_path() {
        local var="$1" new="$2"
        local current="''${!var:-}"
        if [[ ":$current:" != *":$new:"* ]]; then
          export "$var"="''${current:+$current:}$new"
        fi
      }

      # Keep home-manager's binaries, data, and man pages reachable inside
      # nix-direnv devshells, which otherwise replace PATH/XDG_DATA_DIRS with
      # only the devshell's own closure.
      _hm_augment_env() {
        local hm_profile="${config.home.profileDirectory}"
        [[ -d "$hm_profile" ]] || return 0

        _hm_append_path PATH "$hm_profile/bin"
        _hm_append_path XDG_DATA_DIRS "$hm_profile/share"
        # Seed MANPATH with the empty-entry convention (:) if unset, so man(1)
        # still searches system defaults after we append explicit paths.
        [[ -z "''${MANPATH:-}" ]] && export MANPATH=":"
        _hm_append_path MANPATH "$hm_profile/share/man"
      }

      if declare -f use_flake > /dev/null; then
        eval "_hm_orig_use_flake() $(declare -f use_flake | tail -n +2)"
        use_flake() {
          _hm_orig_use_flake "$@"
          _hm_augment_env
        }
      fi

      if declare -f use_nix > /dev/null; then
        eval "_hm_orig_use_nix() $(declare -f use_nix | tail -n +2)"
        use_nix() {
          _hm_orig_use_nix "$@"
          _hm_augment_env
        }
      fi

      on_direnv_loaded() {
        echo "correct"
      }

      direnv_apply_hooks() {
        on_direnv_loaded
      }
    '';
  };
}
