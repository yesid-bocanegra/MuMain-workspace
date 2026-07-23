# Upstream Sync Runbook and Skill Design

## Goal

Keep `MuMain/main` current with `fork/main` through ordinary merge commits while preserving downstream history, supporting small upstream pull requests, and maintaining a tested rollback path.

## Deliverables

1. `docs/upstream-sync.md` — human-facing operational runbook.
2. `.agents/skills/sync-upstream/SKILL.md` — agent workflow for safe, repeatable synchronization.
3. `docs/index.md` — navigation entry for the runbook.

No automation script is added. Conflict resolution requires project-aware judgment, and existing Git, CMake, and CTest commands are sufficient.

## Branch Model

- `fork/main` is upstream source of truth.
- `origin/main` is downstream product branch.
- Upstream changes enter downstream through merge commits; shared `main` is never rebased or force-pushed.
- Upstream pull-request branches start from current `fork/main` and contain only selected upstreamable commits.

## Sync Workflow

1. Confirm `MuMain` is on `main` with clean working tree.
2. Fetch `fork` and `origin`.
3. Record current downstream SHA and fetched upstream SHA.
4. Create dated rollback and integration branches at downstream SHA.
5. Merge pinned upstream SHA into integration branch with `--no-ff`.
6. Resolve conflicts by preserving downstream architecture while incorporating upstream behavior.
7. Run conflict-marker and whitespace checks.
8. Run macOS native build and complete 85-test CTest suite.
9. Report whole-tree format or lint failures separately when they predate or exceed merge scope; never mass-format during upstream sync.
10. Fast-forward `main` to validated integration commit.
11. Push `origin/main` normally.
12. Delete integration branch and retain rollback branch until stability is confirmed.

## Rollback

Preferred published rollback:

```bash
git revert -m 1 <merge-commit>
git push origin main
```

This preserves public history. Hard reset and force push are forbidden for normal rollback. Before publication, abandoning integration branch leaves `main` unchanged.

## Upstream Pull Requests

Create each PR branch from fetched `fork/main`, then cherry-pick or reimplement only the relevant downstream change. Never base an upstream PR on downstream `main` unless upstream explicitly requests the complete product delta.

## Skill Safety Rules

- Halt on dirty `MuMain` worktree.
- Pin upstream SHA after fetch; do not chase a moving branch during one run.
- Never modify parent-workspace unrelated changes.
- Never rebase or force-push shared `main`.
- Never use whole-file `ours` or `theirs` without reviewing lost behavior.
- Never advance `main` when native build or tests fail.
- Keep exact rollback SHA and merge SHA in final report.

## Validation

- Skill frontmatter uses valid `name` and trigger-only `description`.
- Runbook commands match configured remotes and documented build/test commands.
- `docs/index.md` links to runbook.
- Markdown links and referenced paths resolve.
- Skill stays concise and contains no unnecessary scripts or duplicated project background.
