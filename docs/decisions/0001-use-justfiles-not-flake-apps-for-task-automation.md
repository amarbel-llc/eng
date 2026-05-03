---
status: accepted
date: 2026-05-03
decision-makers: friedenberg
---

# Use justfiles for project task automation, not flake `apps`

## Context and Problem Statement

Every project under `~/eng/` ships a `justfile` for build, test, release, and
ad-hoc explore/debug recipes, and a `flake.nix` for reproducible packaging and
devshells. Flake `apps` (`apps.<system>.<name>`, runnable via `nix run .#name`)
overlap with justfile recipes in that both expose named, runnable commands
scoped to a project. Should we collapse onto `apps` and retire justfiles?

## Decision Drivers

* Recipe-as-dependency chains (`default: build test`, `test: test-go test-bats
  test-mcp test-flake-check`) are the backbone of every project's CI surface.
* `just --list` with `[group(...)]` and doc comments is the primary discovery
  surface for `explore-*`, `debug-*`, and `release` recipes.
* Sub-directory justfiles (`just go/build`, `just zz-tests_bats/test-targets`)
  let each subtree own its own task namespace without coupling to the root.
* Per-recipe startup cost matters when chains run 5+ recipes during dev loops.
* Migration cost: dozens of recipes per repo, across ~15 repos.

## Considered Options

* **Keep justfiles, leave flake outputs to `packages` / `devShells` / `checks`.**
* **Migrate everything to flake `apps`.**
* **Hybrid: `apps` for self-contained recipes (release line, explore/debug),
  `just` for orchestration.**

## Decision Outcome

Chosen option: **Keep justfiles**, because the gaps in `apps` are exactly the
features we use most (recipe deps, groups, `--list` discoverability, sub-dir
namespaces), and `apps` provides nothing today's setup lacks.

### Consequences

* Good, because the existing `default: build test`, `test: a b c d` orchestration
  keeps working with no per-invocation eval overhead.
* Good, because `[group('explore')]` / `[group('release')]` / `[group: 'debug']`
  continue to segregate ad-hoc recipes from production ones in `just --list`.
* Good, because sub-dir justfiles (`just go/build`, `just zz-tests_bats/test`)
  remain the canonical pattern for subtree-owned task namespaces.
* Bad, because we keep depending on `just` as a tool outside the flake — devshells
  must continue to provide it.
* Bad, because recipes that wrap nix-built artifacts (`nix build .#x && ./result/bin/x`)
  remain a manual two-step instead of a single `nix run .#x`.
* Neutral, because `flake.nix` and `justfile` continue to coexist with clear roles:
  flake owns reproducible packaging and devshells; justfile owns task orchestration.

### Confirmation

No action required — existing repos already follow this pattern. New repos
should add a justfile alongside `flake.nix` rather than reaching for `apps`.

## Pros and Cons of the Options

### Keep justfiles

* Good, because zero migration cost.
* Good, because `just`'s `--list` UX (groups, doc comments, parameter names with
  defaults) has no equivalent in `nix flake show`.
* Good, because recipe deps form a cheap DAG; a chain of 5 recipes pays one
  shell startup, not 5× nix evals.
* Neutral, because we still depend on `just` being on PATH (provided by every
  devshell in the tree).
* Bad, because justfiles are not reproducibility-locked the way flake outputs
  are — a recipe can silently depend on something not in `runtimeInputs`.

### Migrate to flake `apps`

* Good, because dependencies become explicit via `runtimeInputs` (closer to
  reproducible).
* Good, because `nix run` works against a remote flake ref without cloning.
* Bad, because the `apps` schema is deliberately minimal — only `type` and
  `program` are supported per the nix manual (`nix3-run.html#apps`). No groups,
  no descriptions, no parameter declarations, no recipe-as-dep chains.
* Bad, because `default: build test` requires a hand-written orchestrator that
  pays N× eval cost.
* Bad, because `just --list`'s discoverability collapses to a flat
  `nix flake show` listing with attribute names only.
* Bad, because sub-directory justfiles (`just go/build`) have no clean analog —
  nested `apps.<sys>.go.build` isn't standard for `nix run` resolution.

### Hybrid (apps for self-contained, just for orchestration)

* Good, because the parts that fit `apps` cleanly (release-line `tag`/`bump-version`/
  `release`, standalone explore/debug recipes) get the reproducibility win.
* Bad, because contributors now have to know which mechanism owns which recipe —
  cognitive overhead with no commensurate payoff while justfiles still exist.
* Bad, because the orchestration core (`default`, `test`) still needs justfiles,
  so we never get to retire them.

## More Information

* Nix manual on `apps` schema: <https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-run.html#apps>
* Nix manual on `nix flake check` validation of apps:
  <https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-flake-check.html#evaluation-checks>
* Surveyed justfiles when making this decision: `repos/dodder/justfile`,
  `repos/moxy/justfile`, `repos/chrest/justfile`, `repos/spinclass/justfile` —
  all use `[group(...)]`, recipe-as-dep chains, and (where present) sub-dir
  justfile delegation.
