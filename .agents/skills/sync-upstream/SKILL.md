---
name: sync-upstream
description: Use when updating MuMain from its upstream fork, resolving upstream merge conflicts, checking downstream divergence, or preparing upstream pull-request branches
---

# Sync Upstream

## Scope

Read workspace runbook `docs/upstream-sync.md`, then operate inside `MuMain`. Treat `fork/main` as upstream and `origin/main` as downstream.

## Non-Negotiable Rules

- Halt on dirty `MuMain` worktree. Never stash, discard, or overwrite unknown work.
- Never rebase or force-push shared `main`.
- Never modify unrelated parent-workspace changes.
- Pin fetched upstream SHA; do not chase later remote movement during same run.
- Never advance `main` when native build or tests fail.
- Never mass-format or remediate unrelated lint debt during sync.

## Workflow

1. Verify `main`, clean status, remotes, and divergence.
2. Fetch `fork` and `origin`; record exact downstream and upstream SHAs.
3. Enable `rerere`.
4. Create `rollback/pre-upstream-merge-YYYY-MM-DD` and `integration/upstream-YYYY-MM-DD` at downstream SHA.
5. Merge pinned upstream SHA with `git merge --no-ff <sha>`.
6. Resolve each conflict through base/downstream/upstream comparison. Preserve downstream architecture while incorporating compatible upstream behavior. Do not use blind whole-file `ours` or `theirs`.
7. Require no unmerged paths, conflict markers, or `git diff --check` failures.
8. Commit merge on integration branch.
9. Run:

```bash
cmake --preset macos-arm64
cmake --build --preset macos-arm64-debug
cmake -S . -B build-test -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build build-test -j8
ctest --test-dir build-test --output-on-failure
```

10. Verify pinned upstream SHA is ancestor of integration result.
11. Fast-forward `main` to integration commit and push `origin main` normally.
12. Delete integration branch. Retain rollback branch until user confirms stability.

## Rollback

Before publication, abandon integration branch. After publication, use:

```bash
git revert -m 1 <merge-sha>
git push origin main
```

Never reset and force-push published `main`.

## Upstream PRs

Start `upstream-pr/<name>` from pinned `fork/main`. Cherry-pick or reimplement only relevant downstream commits; exclude product-only dependencies.

## Final Report

Report upstream SHA, previous downstream SHA, merge SHA, divergence, conflict decisions, build/tests, known baseline gate failures, push result, rollback ref, and revert command.
