# Upstream Sync Documentation and Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a human runbook and repository skill for repeatable, merge-friendly synchronization of `MuMain/main` with `fork/main`.

**Architecture:** Keep human operational guidance in `docs/upstream-sync.md` and agent enforcement in `.agents/skills/sync-upstream/SKILL.md`. Both use the same branch model: pinned upstream SHA, temporary integration branch, retained rollback ref, normal merge commit, validation before advancing `main`, and small PR branches based on upstream.

**Tech Stack:** Git, Markdown, CMake, CTest, repository agent skills

---

### Task 1: Add Human Upstream-Sync Runbook

**Files:**
- Create: `docs/upstream-sync.md`

- [ ] **Step 1: Write branch and remote model**

Document `fork/main` as upstream, `origin/main` as downstream, and state that shared `main` uses merges only—never rebase or force push.

- [ ] **Step 2: Write guarded sync procedure**

Include exact commands for clean-tree verification, fetching, pinning SHA values, creating rollback/integration branches, merging the pinned SHA, validation, fast-forwarding `main`, normal push, and integration-branch deletion.

- [ ] **Step 3: Write conflict and validation rules**

Require semantic three-way review, prohibit blind whole-file `ours`/`theirs`, preserve downstream architecture, run `git diff --check`, native macOS build, full test-tree build, and CTest.

- [ ] **Step 4: Write rollback and upstream-PR procedures**

Document pre-publish abandonment, published `git revert -m 1 <merge-sha>`, rollback-ref retention, and PR branches created from pinned `fork/main`.

- [ ] **Step 5: Verify runbook commands**

Run:

```bash
rg -n "fork/main|origin/main|--no-ff|--ff-only|git revert -m 1|ctest" docs/upstream-sync.md
```

Expected: each required workflow element appears at least once.

### Task 2: Add Repository Sync Skill

**Files:**
- Create: `.agents/skills/sync-upstream/SKILL.md`

- [ ] **Step 1: Add valid skill metadata**

Use:

```yaml
---
name: sync-upstream
description: Use when updating MuMain from its upstream fork, resolving upstream merge conflicts, checking downstream divergence, or preparing upstream pull-request branches
---
```

- [ ] **Step 2: Encode preflight and rollback invariants**

Require execution inside `MuMain`, clean worktree, fetched/pinned upstream SHA, exact downstream SHA, dated rollback branch, and temporary integration branch. Halt rather than stash, discard, reset, or overwrite user changes.

- [ ] **Step 3: Encode merge and conflict workflow**

Require `git merge --no-ff <pinned-sha>`, semantic conflict review, downstream architecture preservation, conflict-marker checks, and no mass formatting.

- [ ] **Step 4: Encode validation and publication workflow**

Require native build and all registered CTest tests before fast-forwarding `main`; require ordinary `git push origin main`; forbid rebase and force push.

- [ ] **Step 5: Encode rollback and PR workflow**

Require final report with rollback SHA, merge SHA, validation results, divergence, and preferred published rollback command. Require upstream PR branches to start from pinned upstream SHA.

- [ ] **Step 6: Verify skill size and metadata**

Run:

```bash
wc -w .agents/skills/sync-upstream/SKILL.md
sed -n '1,12p' .agents/skills/sync-upstream/SKILL.md
```

Expected: concise skill under 500 words with valid YAML frontmatter.

### Task 3: Link and Validate Documentation

**Files:**
- Modify: `docs/index.md`
- Validate: `docs/upstream-sync.md`
- Validate: `.agents/skills/sync-upstream/SKILL.md`

- [ ] **Step 1: Add documentation index entry**

Add `Upstream Sync` under CI/CD, describing merge-friendly fork synchronization, rollback, and upstream PR preparation.

- [ ] **Step 2: Validate links and placeholders**

Run:

```bash
test -f docs/upstream-sync.md
test -f .agents/skills/sync-upstream/SKILL.md
rg -n "Upstream Sync" docs/index.md
! rg -n "TBD|TODO|PLACEHOLDER" docs/upstream-sync.md .agents/skills/sync-upstream/SKILL.md
git diff --check
```

Expected: all commands succeed with no placeholder or whitespace errors.

- [ ] **Step 3: Review focused diff**

Run:

```bash
git diff -- docs/upstream-sync.md .agents/skills/sync-upstream/SKILL.md docs/index.md
```

Expected: only approved runbook, skill, and index changes appear.

- [ ] **Step 4: Commit implementation**

```bash
git add docs/upstream-sync.md .agents/skills/sync-upstream/SKILL.md docs/index.md
git commit -m "docs: add upstream sync workflow"
```
