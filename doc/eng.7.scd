eng(7)

# NAME

eng - personal development environment monorepo

# DESCRIPTION

The *eng* repository at _~/eng_ is a monorepo that manages the author's
development environment across macOS and Linux. It contains:

- A Nix flake that builds all personal tools into a single *symlinkJoin*
  derivation at _./result_
- Home-manager modules (under _home/_) that configure shell, SSH, agents,
  terminal, direnv, git, and XDG paths
- nix-darwin modules (under _rcm/tag-darwin/config/nix-darwin/_) for
  macOS system configuration
- rcm dotfiles (under _rcm/_) for configuration that predates or falls
  outside home-manager
- Pinned flake inputs for personal projects (pivy, moxy, bob, maneater,
  ssh-agent-mux, spinclass, and others)

Child repositories (like *eng-etsy*) extend this environment via direnv
inheritance and their own flakes. See *eng-direnv*(7).

# REPOSITORY LAYOUT

*flake.nix*
	Top-level flake. Defines homeConfigurations, darwinConfigurations, and per-system packages/devShells.

*home/*
	Home-manager modules. Key files: fish.nix, ssh.nix, pivy-agent.nix, ssh-agent-mux.nix, git.nix, xdg.nix, wrappers.nix.

*rcm/*
	rcm-managed dotfiles. Tags: tag-darwin, tag-ssh-client, tag-home_manager-obsolete. See *eng-rcm*(7).

*systems/*
	Platform-specific Nix package sets: common/, darwin/, linux/.

*doc/*
	Man pages in scdoc format. Compiled during *nix build*.

*repos/*
	Clones of personal project repositories (bob, moxy, pivy, zmx, etc.).

# BUILDING

Build the full environment:

```
cd ~/eng
nix build
```

The result symlink contains all tools under _bin/_, man pages under
_share/man/_, and shell completions under _share/fish/_.

Apply home-manager and nix-darwin configuration:

```
darwin-rebuild switch --flake ~/eng
```

# IDENTITY

Per-host identity lives in a platform-specific file, bootstrapped on
first run of *just build-home* by _bin/bootstrap-identity.mjs_:

- *macOS*: _/etc/nix-darwin/identity.json_ (JSON object)
- *Linux*: _~/.config/identity.nix_ (Nix attribute set)

It drives home-manager's *home.username*, *home.homeDirectory*, git
user config, SSH signing key selection, and the optional flags below.

*Required fields:*

*username*, *homeDirectory*, *hostname*
	macOS only. (Linux reads $USER and $HOME from the environment.)
	*hostname* comes from *scutil --get LocalHostName*.

*gitUserName*, *gitUserEmail*, *gitSigningKey*
	Git committer identity and signing key. *gitSigningKey* is a
	*key::ssh-ed25519 ...* string read by *home/git.nix* and
	*home/ssh.nix*.

*piggyGuid*
	PIV card GUID for piggy-agent (or *null* on hosts without a
	card). When non-null and *isSshHost* is false,
	*home/piggy-agent.nix* is loaded.

*Optional flags* (not written by bootstrap-identity.mjs --- add by hand):

*isSshHost* (default *false*)
	Marks a host as an SSH-only target (no piggy/pivy agents,
	different known_hosts handling). See *home/ssh.nix* and
	*home/linux.nix*.

*loginShellIsBash* (default *false*)
	Linux only. Set *true* on hosts whose login shell is bash;
	*home/bash.nix* then hops into fish for interactive sessions.

*enableCaldav* (default *true*)
	Set *false* on hosts without caldav secrets to drop the caldav
	plugin from the per-host eng circus, eliminating clown's
	plugin-startup timeout. The standalone *caldav* binary stays
	installed regardless. See *home/circus.nix*.

# SEE ALSO

*eng-ssh*(7), *eng-direnv*(7), *eng-rcm*(7), *eng-manpages*(7), *eng-versioning*(7), *eng-etsy*(7)
