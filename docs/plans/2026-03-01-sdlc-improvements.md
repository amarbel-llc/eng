---
status: testing
date: 2026-03-01
promotion-criteria: "Two consecutive 2-week reviews showing zero fix-after-fix cascades at external boundaries and zero same-day infrastructure reverts"
---

# SDLC Improvement Plan

## Context and Problem Statement

Review of ~300 commits across 33 repos (Feb 14-28, 2026) revealed three
high-impact patterns that waste development effort:

1. **Fix-after-fix cascades** at external system boundaries (~15 wasted commits
   across direnv, pivy, ECDSA, ssh-agent-mux)
2. **Premature infrastructure changes without rollback paths** (lux LSP migration
   reverted in 24h, git alias rename reverted next morning)
3. **Inconsistent use of design documents** despite zero-defect correlation when
   used

## Decision Drivers

- Root cause for #1: no integrated test environment; only production catches
  boundary bugs
- Root cause for #2: no rollback strategy requirement in planning skills
- Root cause for #3: no lifecycle tracking for cross-cutting features

## Decision Outcome

Five interventions implemented:

1. **Integration test environment** (`devenvs/integration-test/`) --- `nix
   develop` shell with SoftHSM2, direnv, ssh-agent, and BATS helpers for
   automated boundary testing
2. **Rollback/dual-architecture strategies** --- built into brainstorming and
   writing-plans skills as mandatory sections
3. **Feature lifecycle tracking** --- FDR/ADR/RFC extended with `exploring →
   proposed → experimental → testing → accepted` lifecycle and problem-first
   template
4. **Semver convention** --- versioning rules in purse-first CLAUDE.md with
   `bump-version` just recipe; semver/FDR integration tracked as first
   `exploring` FDR
5. **Documentation guardrails** --- planning thresholds, scope discipline,
   external integration verification requirements, and repo-level integration
   tables in CLAUDE.md files

## Consequences

### Good

- Boundary bugs caught before commit via integration test suite
- Infrastructure changes require explicit rollback strategy
- Feature lifecycle visible across repos via FDR status
- Planning threshold prevents scope creep on multi-file changes

### Bad

- Additional overhead for changes meeting planning threshold
- Integration test environment adds maintenance burden
- New contributors must learn lifecycle states

## Review Process

Every 2 weeks, starting 2026-03-15:

1. **Count cascades:** `git log --all --oneline --since=2.weeks` across repos ---
   flag any commit sequence where 2+ consecutive commits fix the same external
   integration (target: 0)
2. **Count reverts:** search for "revert", "undo", "roll back" in the same log
   --- flag any infrastructure change reverted within 48h (target: 0)
3. **Decide:** if both targets met for two consecutive reviews, promote status to
   `accepted`; otherwise note what failed and whether interventions need adjusting

## More Information

- Evidence: ~300 commits across 33 repos, Feb 14-28, 2026
- First exploring FDR: `repos/purse-first/docs/features/0002-semver-fdr-integration.md`
- Integration test environment: `devenvs/integration-test/`
