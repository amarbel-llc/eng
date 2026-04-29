---
name: poc
version: 0.1.0
description: "[WIP] Scope and run a proof-of-concept experiment. Use when the user says \"let's POC X\", \"prove out X\", \"let's try the X experiment\", \"scratch/spike/throwaway\". Do NOT use for tracer bullets or \"build the real X\" requests."
user-invocable: true
---

# Proof of Concept

> **WIP** --- this skill is a draft extracted from two POC sessions
> (nixpkgs/plain-linden, chrest/cool-pine) and has not been validated on a
> fresh POC yet. Treat the steps as a starting shape; expect revisions.

A POC is **not** a tracer bullet. It's a throwaway experiment with hardcoded
constants designed to validate one hypothesis. Config, flags, modes, and
"configurability" are anti-goals. Small prod-code additions are OK if tagged.

> "we're doing a POC, not a tracer bullet, so you can actually hard code things
> and avoid cli flags instead" --- the user

## Core discipline

- **Hardcoded constants at the top of the driver file.** No CLI flags, no env
  vars, no config files. A `const ( ... )` block or equivalent.
- **Always-on.** If the POC needs a server, it's built into the driver binary,
  not a separate process with a toggle.
- **OS-chosen resources over configured ones.** `net.Listen("tcp", "127.0.0.1:0")`
  and read `listener.Addr()` to form the URL the rest of the binary uses.
- **Binary self-asserts.** The driver exits 0/1 with a `PASS`/`FAIL` log line.
  Any bats wrapper is 3 lines: `run timeout N "$BIN"`, assert `status -eq 0`.

## Steps

1.  **Scope paragraph** --- before touching code, write a short "here's the
    shape I'd propose":
    - Driver file(s) and path(s)
    - Hypothesis (one sentence)
    - Pass/fail assertion
    - Known risks / out-of-scope items
    - Phases (see step 3)

    Wait for user approval before writing anything.

2.  **Pick the shape and location:**
    - **Isolated mini-project** (new flake, new language, nothing bleeds into
      prod): start in `.tmp/<name>-poc/` with its own flake and justfile.
      Graduates to `zz-pocs/<name>-poc/`.
    - **Prod-adjacent probe** (touches existing code paths, may grow a sliver
      of prod API): driver at `<lang-dir>/cmd/<project>-exporel[-<variant>]/main.go`
      (Go) or the repo's matching `cmd/` convention. Tests at `zz-bats_explore/`
      (new dir, sibling of the main tests). Any prod-code additions tagged
      `// Added for <repo>#<issue> POC`.

3.  **Phased validation, stop on red.** Stage the POC as: host sanity -->
    artifact/build --> sandboxed experiment. If any stage fails, summarize and
    check in with the user. Don't chain hypotheses.

4.  **Justfile recipes in an `explore` or `debug` group:** `bootstrap`,
    `nix-build` or `test-bats-explore`, `clean`, plus any `regen-*` helpers. Do
    not wire into the main `test` recipe.

5.  **Per-stage issue comments** --- on each green stage, `get-hubbed
    issue-comment` with the numbered flow, the verdict, side-findings, and
    still-open items.

6.  **Graduation** (POC is green and worth keeping):
    - If isolated: `folio-external cp` from `.tmp/<name>-poc/` --> `zz-pocs/<name>-poc/`
    - `git add -N` any untracked paths (nix builds only see tracked files),
      then `grit add` + `grit commit`
    - `mcp__spinclass__merge-this-session` with `git_sync: true`
    - Final issue comment linking to the commit/PR

## Constraints

- **Do not add CLI flags, env vars, or config files** to make the POC
  "configurable". Constants at the top of the file, period.
- **Do not wire POC tests into the main `test` recipe.** `zz-bats_explore/`
  stays separate; `explore`/`debug` justfile groups stay separate.
- **One up-front exploration subagent max.** After that, research inline ---
  the POC is small enough to hold in one head.
- **Under a live worktree, `rm -f flake.lock` before each `nix develop`** in
  `.tmp/` to dodge NAR-hash mismatches. For untracked paths that `nix build`
  can't see, `git add -N`.
- **Small prod-API additions are fine** (one function, one field) if tagged
  `// Added for <repo>#<issue> POC`. Anything larger is a follow-up, not POC
  scope.
- **Scope tests before writing them, check in with the user.** E2E vs probe is
  a scoping decision the user owns.
- **Do not turn the POC into the real implementation in the same session.**
  The POC either stays in `zz-pocs/` / `cmd/*-exporel/` or gets rewritten as
  proper code in a follow-up.
