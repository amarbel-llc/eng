{
  identity,
  lib,
  pkgs,
  pkgs-master,
  ...
}:
let
  gitDir = ./git;

  aliasFiles = builtins.filter (f: lib.hasSuffix ".git-alias" f) (
    builtins.attrNames (builtins.readDir (gitDir + "/aliases"))
  );

  # Generate [alias] gitconfig section from .git-alias files in the directory.
  # Replaces config-aliases.rcm-script.
  aliasConfigText = lib.concatStringsSep "\n" (
    [
      "# vim: ft=gitconfig"
      ""
      "[alias]"
    ]
    ++ map (
      f:
      let
        name = lib.removeSuffix ".git-alias" f;
      in
      "\t${name} = ! ~/.config/git/aliases/${f}"
    ) (lib.sort (a: b: a < b) aliasFiles)
  );

  # Deploy alias scripts to ~/.config/git/aliases/
  aliasXdgFiles = builtins.listToAttrs (
    map (f: {
      name = "git/aliases/${f}";
      value = {
        source = gitDir + "/aliases/${f}";
        executable = true;
      };
    }) aliasFiles
  );

  signingKeyBare = lib.removePrefix "key::" identity.gitSigningKey;

  # Shared git settings included by both the home-manager config and
  # hand-written identity configs (e.g. config-etsy).
  commonConfigText = ''
    # vim: ft=gitconfig

    [core]
    	whitespace = nowarn
    	excludesFile = ~/.config/git/ignore
    [diff]
    	colormoved = default
    	colormovedws = allow-indentation-change
    [pretty]
    	nice = format:%w(120,0,44)%C(auto)%h %<(14)%Cred%cr %<(18)%C(blue)%aN%Creset - %s%C(auto)%w(120,0,0)%+d
    	hist = format:%C(auto)%h%Creset - %s %C(blue)[%aN] %Cgreen(%ad) %C(bold blue)%Creset%C(auto)%+d%Creset
    [push]
    	default = current
    [rebase]
    	autosquash = true
    	autoStash = true
    	updateRefs = true
    [log]
    	mailmap = true
    [mergetool]
    	prompt = false
    	keepBackup = false
    [merge]
    	conflictstyle = diff3
    	tool = vimdiff
    	autostash = true
    [mergetool "vimdiff"]
    	path = editor
    [merge "ours"]
    	driver = true
    [pull]
    	rebase = true
    [advice]
    	detachedHead = false
    	skippedCherryPicks = false
    [init]
    	defaultBranch = master
  '';

in
{
  programs.git = {
    enable = true;
    package = pkgs-master.git;

    ignores = [
      "**/.claude/settings.local.json"
      "**/.claude/.settings-snapshot.json"
      "*.old"
      ".DS_Store"
      ".claude/settings.local.json"
      ".direnv/"
      ".envrc"
      ".projections.json"
      ".tmp/"
      "TERMTABS_NAME"
      "result"
      ".secrets.env"
      ".dodder/"
      ".dodder-workspace"
      "moxyfile"
      ".spinclass/"
    ];

    settings = {
      user = {
        name = identity.gitUserName;
        email = identity.gitUserEmail;
        signingKey = identity.gitSigningKey;
      };
      commit.gpgsign = true;
      gpg.format = "ssh";
      "gpg \"ssh\"" = {
        program = "ssh-keygen";
        allowedSignersFile = "~/.config/ssh/keys-allowed_signers-user";
      };
    };

    includes = [
      { path = "~/.config/git/config-common"; }
      { path = "~/.config/git/config-aliases"; }
    ];
  };

  xdg.configFile = aliasXdgFiles // {
    "git/config-common".text = commonConfigText;
    "git/config-aliases".text = aliasConfigText;
    "ssh/keys-allowed_signers-user".text = "${identity.gitUserEmail} ${signingKeyBare}\n";
    "ssh/config".text = "Include ~/.config/ssh/rcm/config\n";
  };
}
