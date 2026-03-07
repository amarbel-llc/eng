---
name: cross-repo-todo-triage
description: Use when consolidating, prioritizing, or auditing TODO items across multiple repositories in a monorepo, or when checking which TODOs may already be completed
---

# Cross-Repo TODO Triage

## Overview

Technique for discovering, consolidating, and investigating TODO items across a
multi-repo codebase using parallel exploration agents to verify completion status
without building or running code.

## When to Use

- Periodic backlog grooming across a monorepo
- Before planning when TODOs are scattered across repos
- When worktrees may have divergent TODO state
- When suspecting items may already be fixed but not removed

## Core Pattern

### Phase 1: Discovery

Parallel `Glob` for `**/TODO.md` and `**/TODO`. Skip vendored/upstream files.

### Phase 2: Read and Deduplicate

Read all TODO files in parallel. For worktrees, compare against canonical
(master branch) copy -- worktrees may be stale or have unique items not yet
merged.

### Phase 3: Consolidate and Prioritize

Merge all unique open items into a single list. Group by:

| Priority | Criteria                                  |
| -------- | ----------------------------------------- |
| P0       | Data loss, crashes, security              |
| P1       | Broken tests, build failures              |
| P2       | Small targeted improvements (1-file fixes) |
| P3       | Test infrastructure, migration            |
| P4+      | Feature work, documentation debt, exploration |

### Phase 4: Parallel Completion Investigation

Fan out 4-8 Explore agents, each with a thematically coherent subset of items.
Each agent:

1. Reads the specific source files referenced by the TODO
2. Checks recent git history for changes to those files
3. Reports: fixed, still present, or partially done

**Agent scoping rules:**

- Group items by repo or theme (not one agent per item)
- Constrain to "read source and git log only -- do NOT build or run"
- Give each agent the exact file paths and function names from the TODO
  descriptions

### Phase 5: Report

Produce two lists:

- **Can close**: items where code evidence confirms completion
- **Confirmed open**: items where relevant code is unchanged

## Quick Reference

| Step                    | Tool                  | Parallelism  |
| ----------------------- | --------------------- | ------------ |
| Find TODOs              | Glob                  | 2 parallel   |
| Read files              | Read per file         | all parallel |
| Read worktree variants  | Read per worktree     | all parallel |
| Investigate completion  | Explore agent per group | all parallel |

## Common Mistakes

- **Reading worktrees as authoritative** -- worktrees diverge from master;
  always compare
- **One agent per item** -- too many agents, too little context per agent. Group
  4-7 items per agent by theme
- **Forgetting to scope agents** -- without "do NOT build or run," agents will
  try to compile and test
- **Skipping git history** -- source code alone may look unchanged but a fix
  could be on an unmerged branch (check worktree branches too)
