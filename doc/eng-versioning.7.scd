eng-versioning(7)

# NAME

eng-versioning - versioning and release practices for amarbel-llc repositories

# DESCRIPTION

This document describes the versioning strategies observed across the
*amarbel-llc* GitHub organization as of April 2026, identifies the most
mature patterns, and prescribes a gold-standard release workflow that new
and existing repositories should converge on.

The three most mature repositories — *moxy*, *clown*, and *madder* — share
a common release skeleton built on justfile recipes, signed git tags, and
auto-generated changelogs. Repositories that lack this machinery (spinclass,
chrest, and others) should adopt it.

# PRINCIPLES

. Every repository has exactly one version source of truth.
. Versions follow semantic versioning (MAJOR.MINOR.PATCH).
. Git tags are signed and verified after push.
. Compiled binaries report their real version at runtime.
. Release automation is justfile-first; CI extends it, not replaces it.

# SINGLE VERSION SOURCE OF TRUTH

Each repository must store its version in exactly one canonical location.
All other consumers (Nix, ldflags, CLI --version) read from that location.

There are two acceptable patterns:

*version.txt at repo root*
	A plain text file containing the bare semver string (e.g. _0.1.0_).
	Read in Nix via _builtins.readFile ./version.txt_. Language-agnostic.
	Used by: *clown*.

*Named variable in flake.nix*
	A Nix let-binding (e.g. _moxyVersion = "0.4.10";_) in the outputs
	section. Works well when the flake already contains substantial build
	logic. Used by: *moxy*.

*Anti-pattern:* hardcoded version strings scattered across multiple files
(Go source, Nix derivation, browser extension manifest) that drift out of
sync. This is the current state of *chrest*, which has three divergent
version strings.

# TAG NAMING

*Standard Go binary or Nix package at repo root*
	Tags use the _v_ prefix: *v0.1.0*, *v0.4.10*.
	Used by: *moxy*, *clown*.

*Go module not at repo root*
	Tags use a path prefix matching the module directory: *go/v0.0.7*.
	This is required by the Go module proxy for sub-directory modules.
	Used by: *madder*.

*Monorepo sub-packages*
	Tags use the full package path: *packages/tap-dancer/go/v0.1.0*.
	Used by: *bob*.

All tags MUST be annotated and signed (_git tag -s_).

# JUSTFILE RELEASE RECIPES

Every repository should provide two recipes in the *maint* group.

These recipes depend on *gum* (charmbracelet/gum) for terminal UI logging.
It should be included in the flake's devShell inputs.

*just tag <version> <message>*
	Creates a signed annotated tag, pushes it to origin, and verifies the
	signature. The _v_ prefix (or _go/v_ for sub-directory modules) is
	added by the recipe — callers pass the bare semver.

*just release <version>*
	Bumps the version source of truth, commits, auto-generates a
	changelog from _git log_ since the previous tag, and delegates to
	_just tag_.

The auto-generated changelog uses one line per commit in the format
_- <subject line>_, covering all commits between the previous tag and
HEAD. This is the tag message body, not a separate file. Example:

```
release v0.2.0

- fix: handle empty config gracefully
- feat: add --verbose flag
- refactor: extract proxy loop
```

## Reference: tag recipe

```
[group("maint")]
tag version message:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="v{{version}}"
    prev=$(git tag --sort=-v:refname -l "v*" | head -1)
    if [[ -n "$prev" ]]; then
        gum log --level info "Previous: $prev"
        git log --oneline "$prev"..HEAD
    fi
    git tag -s -m "{{message}}" "$tag"
    gum log --level info "Created tag: $tag"
    git push origin "$tag"
    gum log --level info "Pushed $tag"
    git tag -v "$tag"
```

## Reference: tag recipe (sub-directory Go module)

For repositories where go.mod lives in a subdirectory (e.g. _go/_), the
tag prefix must match the module path so that the Go module proxy resolves
it. The log is scoped to only commits touching that directory.

```
[group("maint")]
tag version message:
    #!/usr/bin/env bash
    set -euo pipefail
    tag="go/v{{version}}"
    prev=$(git tag --sort=-v:refname -l "go/v*" | head -1)
    if [[ -n "$prev" ]]; then
        gum log --level info "Previous: $prev"
        git log --oneline "$prev"..HEAD -- go/
    fi
    git tag -s -m "{{message}}" "$tag"
    gum log --level info "Created tag: $tag"
    git push origin "$tag"
    gum log --level info "Pushed $tag"
    git tag -v "$tag"
```

## Reference: release recipe

```
[group("maint")]
release version:
    #!/usr/bin/env bash
    set -euo pipefail
    # Bump the version source of truth.
    # Adapt this line to your repo: version.txt, flake.nix, etc.
    echo "{{version}}" > version.txt
    git add version.txt
    git commit -m "release v{{version}}"
    prev=$(git tag --sort=-v:refname -l "v*" | head -1)
    header="release v{{version}}"
    if [[ -n "$prev" ]]; then
        summary=$(git log --format='- %s' "$prev"..HEAD)
        msg="$header"$'\n\n'"$summary"
    else
        msg="$header"
    fi
    just tag "{{version}}" "$msg"
```

## Reference: release recipe (sub-directory Go module)

```
[group("maint")]
release version:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "{{version}}" > version.txt
    git add version.txt
    git commit -m "release v{{version}}"
    prev=$(git tag --sort=-v:refname -l "go/v*" | head -1)
    header="release v{{version}}"
    if [[ -n "$prev" ]]; then
        summary=$(git log --format='- %s' "$prev"..HEAD -- go/)
        if [[ -n "$summary" ]]; then
            msg="$header"$'\n\n'"$summary"
        else
            msg="$header"
        fi
    else
        msg="$header"
    fi
    just tag "{{version}}" "$msg"
```

# VERSION EMBEDDING

## Go binaries

The ldflags _-X_ flag targets a specific Go package variable. For
repositories with a single binary, use _main.version_ and _main.commit_
directly. For repositories with multiple commands under cmd/, declare
the variables in a shared internal package (e.g.
internal/buildinfo/buildinfo.go) and target the ldflags at the full
import path: _-X example.com/repo/internal/buildinfo.version_. Each cmd
entry imports the package and references buildinfo.Version.

Declare link-time variables and a version subcommand in *main.go*:

```
var (
    version = "dev"
    commit  = "unknown"
)

func main() {
    if len(os.Args) > 1 && (os.Args[1] == "version" ||
        os.Args[1] == "--version" || os.Args[1] == "-v") {
        fmt.Printf("%s %s+%s\n", os.Args[0], version, commit)
        os.Exit(0)
    }
    // ...
}
```

If the project uses a CLI framework (e.g. *command.App* from purse-first),
set _app.Version = version + "+" + commit_ instead — the framework
provides *--version* automatically.

Inject the variables via *-ldflags* in the Nix build. The
_amarbel-llc/gomod2nix_ overlay provides *buildGoApplication*; the
_ldflags_ attribute is a list of strings passed to the Go linker:

```
myVersion = lib.trim (builtins.readFile ./version.txt);
myCommit = self.shortRev or self.dirtyShortRev or "dirty";

buildGoApplication {
    pname = "example";
    version = myVersion;
    ldflags = [
        "-X main.version=${myVersion}"
        "-X main.commit=${myCommit}"
    ];
    # ... other attrs
};
```

Note that the derivation's _version_ attribute and the _-X main.version_
flag should both read from the same source of truth.

And in the justfile's *build-go* recipe for development builds:

```
build-go:
    go build -ldflags "-X main.version=$(cat version.txt) \
        -X main.commit=$(git rev-parse --short HEAD)" ./cmd/...
```

## Nix shell wrappers

For projects that produce shell scripts rather than compiled binaries
(e.g. *clown*), interpolate the version directly into the wrapper at Nix
build time using string interpolation with the version variable.

# CI/CD

## FlakeHub rolling (baseline)

Every repository should publish to FlakeHub on merge to master. This is
the .github/workflows/nix.yml pattern already present in most repos. It
uses _DeterminateSystems/flakehub-push_ with _rolling: true_.

## Tag-triggered release (for repos that ship artifacts)

A repository should ship artifacts if any of these apply:

- It produces a CLI binary consumed outside the Nix ecosystem (e.g. via
  Homebrew, curl-to-bash install scripts, or direct download).
- It is a Go module imported by external consumers who need tagged
  releases for _go get_ version resolution.
- It is a standalone tool that non-Nix users run directly.

Repositories consumed exclusively as Nix flake inputs (e.g. spinclass,
madder) do not need artifact releases — FlakeHub rolling and signed tags
are sufficient.

Repositories that do ship artifacts should add a *release.yml* workflow
triggered on tag push:

```
on:
  push:
    tags:
      - "v*"
```

This workflow builds per-platform artifacts via _nix build_, then creates
a GitHub Release with auto-generated notes. See moxy's release.yml for
the full reference.

## Homebrew tap updates

If the project has a Homebrew tap, add a *just bump-formula* recipe that:
. Verifies release assets are published
. Downloads tarballs and computes sha256 hashes
. Renders the formula from a template
. Opens a PR against the tap repository

# CURRENT STATE BY REPOSITORY

The following table summarizes the versioning maturity of each
amarbel-llc repository as of April 2026.

*moxy* — MATURE
	Tags: v0.1.0..v0.4.10 (15 tags). Version in flake.nix. ldflags
	injection. just release + tag. CI release on tag push. GitHub
	Releases with tarballs. Homebrew tap automation.

*clown* — MATURE
	Tags: v0.0.1..v0.1.2 (3 tags). Version in version.txt. Shell
	interpolation at build time. just release + tag. No CI release.

*madder* — PARTIAL
	Tags: go/v0.0.1..go/v0.0.7 (7 tags). Ships CLI binaries (madder,
	madder-cache) consumed as a Nix flake input — no artifact release
	needed, but ldflags should still be wired so the binaries report
	their version at runtime. Nix version hardcoded and stale (0.0.1
	vs tags at 0.0.7). No ldflags. Has just release + tag recipes
	already. Has multiple cmd/ entries so ldflags should target a
	shared internal package. No CI release needed (flake-only).

*spinclass* — MINIMAL
	No tags. Version 0.1.0 in flake.nix. ldflags plumbing exists but
	is not wired. FlakeHub rolling only.

*chrest* — MINIMAL
	No tags. Three divergent version strings (Go 0.1.0, Nix 0.0.1,
	extension 1.16.0). No ldflags. FlakeHub rolling only.

*bob* — MINIMAL
	One sub-package tag (packages/tap-dancer/go/v0.1.0). No root-level
	versioning.

*dodder, maneater, nebulous, tommy, piggy, pa6e* — NONE
	No tags, no version machinery.

# MIGRATION CHECKLIST

For each repository that needs to adopt the gold standard:

. Pick version source of truth (version.txt or flake.nix variable)
. Add _just tag_ and _just release_ recipes to the maint group
. For Go binaries: add ldflags variables and wire them in Nix + justfile
. Ensure Nix package version reads from the source of truth
. If shipping artifacts: add release.yml triggered on v\* tag push
. Reconcile any divergent version strings into the single source

# SEE ALSO

*eng*(7), *moxy*(1), *moxin*(7)
