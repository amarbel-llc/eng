eng-rcm(7)

# NAME

eng-rcm - rcm dotfile management

# DESCRIPTION

The *eng* repository uses *rcm* (thoughtbot's rc file management suite)
to deploy configuration files that are not managed by home-manager. The
two systems coexist: home-manager handles programmatically generated
configs (SSH, fish, direnv, kitty, git), while rcm handles static files
that are shared across machines or maintained by hand.

# DIRECTORY LAYOUT

The rcm dotfiles live under _~/eng/rcm/_:

```
rcm/
├── rcrc                    # rcm configuration (DOTFILES_DIRS, tags)
├── config/                 # shared configs (all platforms)
│   ├── ssh/rcm/            # SSH config fragments
│   ├── spinclass/          # spinclass sweatfile
│   ├── lux/                # lux LSP configs
│   └── nvim/               # neovim LSP configs
├── local/bin/              # user scripts deployed to ~/.local/bin
├── hooks/post-up/          # scripts run after rcup
├── tag-darwin/             # macOS-specific configs
│   ├── config/nix-darwin/  # nix-darwin modules
│   ├── config/hammerspoon/ # window management
│   └── Alfred.alfredpreferences/
├── tag-ssh-client/         # SSH client configs (non-server machines)
└── tag-home_manager-obsolete/  # migrated configs (reference only)
```

Child repositories have their own _rcm/_ directories with
repo-specific dotfiles. See *eng-etsy*(7).

# TAGS

rcm tags are platform or role selectors. Active tags are configured in
_rcrc_ or passed to *rcup -t*:

*tag-darwin*
	macOS-specific: nix-darwin modules, Hammerspoon, Alfred workflows.

*tag-ssh-client*
	SSH client configs. Applied on workstations, not on servers.

*tag-home_manager-obsolete*
	Configs migrated to home-manager. Kept for reference; not deployed.

# RCM VS HOME-MANAGER

*Home-manager* is preferred for configs that:
- Depend on Nix store paths (e.g. pivy-agent binary path in launchd plist)
- Are generated from structured data (e.g. SSH config from Nix attrsets)
- Need conditional logic per platform

*rcm* is preferred for configs that:
- Are static files shared verbatim across machines
- Predate the home-manager migration and work fine as-is
- Are maintained in child repos (eng-etsy) independently

# DEPLOYING

Run *rcup* to symlink dotfiles into place:

```
rcup -d ~/eng/rcm -t darwin -t ssh-client
```

The *rcrc* file at _~/eng/rcm/rcrc_ sets default directories and tags
so plain *rcup* works.

Post-up hooks in _hooks/post-up/_ run after deployment:
- *0-perms.bash* — fixes file permissions (e.g. SSH keys)
- *1-templates.bash* — processes j2 templates

# CHILD REPO RCM

Child repos (e.g. _~/eng-etsy/rcm/_) contain their own dotfiles. They
are deployed with a separate *rcup -d* invocation or by adding the
directory to *DOTFILES_DIRS* in _rcrc_.

# SEE ALSO

*eng*(7), *eng-etsy*(7), *rcup*(1), *rcrc*(5), *lsrc*(1)
