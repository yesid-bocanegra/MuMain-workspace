# Upstream Synchronization

Use this runbook to merge `fork/main` into downstream `MuMain/main` without rewriting shared history.

## Branch Model

- `fork/main` — upstream source of truth.
- `origin/main` — downstream product branch.
- `main` accepts upstream through merge commits. Never rebase or force-push shared `main`.
- Upstream pull-request branches start from `fork/main`, not downstream `main`.

Enable reusable conflict resolutions once:

```bash
git config rerere.enabled true
git config rerere.autoupdate true
```

## Sync Upstream

Run from `MuMain/`. Stop if the worktree is dirty; do not stash or discard unknown work.

```bash
git switch main
git status --short --branch
git fetch --prune fork
git fetch --prune origin

downstream_sha=$(git rev-parse main)
upstream_sha=$(git rev-parse fork/main)
sync_date=$(date +%Y-%m-%d)

git rev-list --left-right --count "$upstream_sha...$downstream_sha"
git branch "rollback/pre-upstream-merge-$sync_date" "$downstream_sha"
git switch -c "integration/upstream-$sync_date" "$downstream_sha"
git merge --no-ff "$upstream_sha"
```

Pinning `upstream_sha` prevents a moving remote branch from changing scope during validation.

## Resolve Conflicts

For each conflict:

1. Compare base, downstream, and upstream versions.
2. Preserve downstream architecture and local product behavior.
3. Incorporate upstream bug fixes and compatible features.
4. Do not accept whole-file `ours` or `theirs` without checking lost behavior.
5. Do not mass-format upstream files during synchronization; formatting-only rewrites make future merges harder.

Before committing:

```bash
git diff --name-only --diff-filter=U
git diff --check
git grep -n -E '^(<<<<<<< |>>>>>>> )' -- 'src/source/*'
git commit --no-edit
```

The unmerged-file and conflict-marker commands must return no matches.

## Validate

Build native macOS target:

```bash
cmake --preset macos-arm64
cmake --build --preset macos-arm64-debug
```

Build and run all registered tests:

```bash
cmake -S . -B build-test -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build build-test -j8
ctest --test-dir build-test --output-on-failure
rm -rf build-test
```

Run focused integrity checks:

```bash
git diff --check "rollback/pre-upstream-merge-$sync_date..HEAD"
git merge-base --is-ancestor "$upstream_sha" HEAD
git status --short --branch
```

Whole-tree format or lint failures may predate the merge. Record them separately. Never fix unrelated full-tree debt as part of upstream synchronization.

## Publish

Advance downstream only after build and tests pass:

```bash
merge_sha=$(git rev-parse HEAD)
git switch main
git merge --ff-only "integration/upstream-$sync_date"
git push origin main
git branch -d "integration/upstream-$sync_date"
```

Retain rollback branch until merged result is confirmed stable.

## Roll Back

Before publication, abandon integration branch and return to `main`; downstream remains unchanged.

After publication, preserve history with merge revert:

```bash
git switch main
git revert -m 1 "$merge_sha"
git push origin main
```

Do not reset and force-push published `main`.

## Prepare Upstream Pull Requests

Create small branches from current upstream:

```bash
git fetch --prune fork
upstream_sha=$(git rev-parse fork/main)
git switch -c upstream-pr/<change-name> "$upstream_sha"
git cherry-pick <selected-downstream-commit>
```

Remove product-only dependencies, validate the focused change, then push branch to `origin`. Do not merge downstream `main` into an upstream PR branch unless upstream explicitly requests the complete downstream delta.
