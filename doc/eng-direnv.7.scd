eng-direnv(7)

# NAME

eng-direnv - direnv environment chain

# DESCRIPTION

The *eng* environment uses *direnv* to manage per-directory environment
variables and Nix devshell activation. Directories form a chain via
*source_up*, allowing child repositories to inherit from parent
environments.

# CHAIN

The direnv chain from a child repo like _~/eng-etsy_ resolves as:

. _~/eng-etsy/.envrc_ — child repo entry point
. _~/eng/.envrc_ — parent (reached via *source_up*)
. _~/.envrc_ — user root (reached via *source "\$HOME/.envrc"*)

Each level can load *.env* files (via *dotenv*), add to *PATH*, and
export variables.

# ROOT ENVRC

_~/.envrc_ is deployed by home-manager and is intentionally minimal.
It exists so that *source_up* from _~/eng/.envrc_ has a target.

# ENG ENVRC

_~/eng/.envrc_ sources the root and loads _~/eng/.env_:

```
source "$HOME/.envrc"
dotenv "$HOME/.env"
```

Note: _~/eng/.env_ may not exist — *dotenv* will error if absent. Use
*dotenv_if_exists* for optional files.

# CHILD REPO ENVRC

Child repos use *source_up* to inherit from _~/eng/.envrc_, then load
their own environment files:

```
source_up
dotenv_if_exists .env
dotenv .secrets.env
export JIRA_API_TOKEN="$(security find-generic-password ...)"
PATH_add "$PWD/bin"
```

The *source_up* directive walks parent directories until it finds
another _.envrc_ file.

# LAYOUT FLAKE WITH HOOK

The direnv stdlib (defined in _home/common.nix_) includes a custom
*layout_flake_with_hook* function that extends *use_flake* by adding
_./result/share_ to *XDG_DATA_DIRS*. This makes man pages, shell
completions, and other data from the Nix build result available in the
shell without explicit configuration.

# ENV FILE CONVENTIONS

*.env*
	Non-secret environment variables. Version-controlled. Loaded via *dotenv* or *dotenv_if_exists*.

*.secrets.env*
	Credentials and tokens. Not version-controlled. Loaded via *dotenv*.

*.env.local*
	Per-machine overrides. Not version-controlled. Loaded via *dotenv_if_exists*.

# DIRENV CONFIGURATION

Home-manager configures direnv in _home/common.nix_:

- *nix-direnv* integration is enabled for cached Nix shells
- Whitelist prefix is set to *\$HOME/eng* so all subdirectories are
  trusted
- The stdlib defines *layout_flake_with_hook* and hook functions

# TROUBLESHOOTING

*Variable not in environment despite being in .env*
	Check that the .envrc actually loads the .env file. Run *direnv status* to see which files are watched.

*direnv reload doesn't work in Claude Code sessions*
	Known limitation. Restart the session with a *direnv reload* in the parent shell between sessions.

# FILES

_~/.envrc_
	User root envrc.

_~/eng/.envrc_
	Parent repo envrc.

_~/eng/.env_
	Parent repo non-secret variables.

# SEE ALSO

*eng*(7), *eng-etsy*(7), *direnv*(1), *direnv-stdlib*(1)
