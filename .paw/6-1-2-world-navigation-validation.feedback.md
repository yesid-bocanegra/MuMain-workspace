# Pipeline Feedback — Story 6-1-2-world-navigation-validation

## Failed Step: code-review
## Regression Target: code-review

## Failure Details

📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/tests/CMakeLists.txt
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad-output/test-scenarios/epic-6/world-navigation-validation.md
💬 Now let me read the source headers referenced by the test to verify correctness of assertions.
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/World/ZzzPath.h
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/World/MapManager.h
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/Data/MoveCommandData.h
💬 Let me check the constants referenced by the tests.
🔎 Grepping: FACTOR_PATH_DIST
🔎 Grepping: EPathNodeState
🔎 Grepping: #define private|friend.*test|friend.*Test
🔎 Grepping: TW_SAFEZONE|TW_CHARACTER|TW_NOMOVE|TW_ACTION|TW_HEIGHT|TW_CAMERA_UP
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/Core/mu_define.h
💬 Now I have all the information needed. Let me verify the ATDD checklist accuracy and create the review.md.

**Step 3: ATDD Verification** — `EstimateCostToGoal` is declared private in `ZzzPath.h:77`, but the test calls it directly. This means Phase 3 checklist items are marked complete despite a compilation barrier.

**Step 4: Create review.md** with all findings.
✏️  Writing: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad-output/stories/6-1-2-world-navigation-validation/review.md
💬 The semgrep hook warning is just a missing token — the file was written successfully.

**Code review workflow complete.** Created `_bmad-output/stories/6-1-2-world-navigation-validation/review.md` with 6 findings:

| # | Severity | Issue |
|---|----------|-------|
| 1 | **BLOCKER** | `PATH::EstimateCostToGoal` is private — test calls it directly at 4 locations, won't compile |
| 2 | MEDIUM | `_bCanMove` test has vacuous assertions (sets value, reads it back — tests nothing) |
| 3 | MEDIUM | ATDD checklist marks EstimateCostToGoal test complete despite compilation barrier |
| 4 | LOW | Empty `#ifdef MU_WORLD_NAVIGATION_TESTS_ENABLED` body — enabling flag silently removes SKIP stubs with no replacement |
| 5 | LOW | Incomplete non-overlapping bitmask check (redundant with individual value checks) |
| 6 | LOW | Comment hardcodes magic numbers 5/7 instead of naming FACTOR_PATH_DIST constants |

**Key blocker:** The test at lines 229–248 calls `path.EstimateCostToGoal()` which is a `private` method in `ZzzPath.h:77`. The macOS quality gate (`./ctl check`) only runs format+lint — it doesn't compile — so this was not caught. Fix requires either a `friend` declaration (pattern used by `test_sdlgpubackend.cpp`) or making the method accessible.

📋 Result:
The semgrep hook warning is just a missing token — the file was written successfully.

**Code review workflow complete.** Created `_bmad-output/stories/6-1-2-world-navigation-validation/review.md` with 6 findings:

| # | Severity | Issue |
|---|----------|-------|
| 1 | **BLOCKER** | `PATH::EstimateCostToGoal` is private — test calls it directly at 4 locations, won't compile |
| 2 | MEDIUM | `_bCanMove` test has vacuous assertions (sets value, reads it back — tests nothing) |
| 3 | MEDIUM | ATDD checklist marks EstimateCostToGoal test complete despite compilation barrier |
| 4 | LOW | Empty `#ifdef MU_WORLD_NAVIGATION_TESTS_ENABLED` body — enabling flag silently removes SKIP stubs with no replacement |
| 5 | LOW | Incomplete non-overlapping bitmask check (redundant with individual value checks) |
| 6 | LOW | Comment hardcodes magic numbers 5/7 instead of naming FACTOR_PATH_DIST constants |

**Key blocker:** The test at lines 229–248 calls `path.EstimateCostToGoal()` which is a `private` method in `ZzzPath.h:77`. The macOS quality gate (`./ctl check`) only runs format+lint — it doesn't compile — so this was not caught. Fix requires either a `friend` declaration (pattern used by `test_sdlgpubackend.cpp`) or making the method accessible.


## Action Required

Address ALL issues above before proceeding. Do NOT mark story complete until all gaps are filled.
