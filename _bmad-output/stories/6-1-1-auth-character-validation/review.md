# Code Review — Story 6-1-1: Authentication & Character Management Validation

**Reviewer:** Claude Opus 4.6 (adversarial)
**Date:** 2026-03-21
**Story Status at Review:** review
**Pipeline Step:** CODE_REVIEW (adversarial findings only — no fixes applied)

---

## Pipeline Status

| Step | Status | Date |
|------|--------|------|
| 1. Quality Gate | PASSED | 2026-03-21 |
| 2. Code Review Analysis | COMPLETE | 2026-03-21 |
| 3. Code Review Finalize | pending | — |

## Quality Gate

**Status: PASSED**

### Components Resolved

| Component | Tags | Type | Path |
|-----------|------|------|------|
| mumain | backend | cpp-cmake | ./MuMain |
| project-docs | documentation | documentation | ./_bmad-output |

### Backend Quality Gate — mumain

| Check | Status | Notes |
|-------|--------|-------|
| format-check | PASSED | 711/711 files, 0 violations |
| lint (cppcheck) | PASSED | 711/711 files, 0 errors |
| build | SKIPPED | macOS cannot compile Win32/DirectX (CI-only) |
| test | SKIPPED | macOS cannot compile Win32/DirectX (CI-only) |
| coverage | N/A | No coverage configured yet |
| SonarCloud | N/A | Not configured for this project |

### Frontend Quality Gate

No frontend components affected by this story.

### Schema Alignment

N/A — C++ game client, no backend/frontend DTO drift to track.

### AC Compliance

Skipped — infrastructure story type (no Playwright or integration test AC compliance checks).

### App Startup Verification

Skipped — C++ Win32 game client cannot run on macOS. Build and runtime validation are CI-only (MinGW cross-compile). Per `.pcc-config.yaml`: `skip_checks: [build, test]`.

---

## Findings

### Finding 1 — HIGH: ATDD phantom completions — 12 MUGame-linked tests marked done but SKIP at runtime

**File:** `_bmad-output/stories/6-1-1-auth-character-validation/atdd.md`
**Lines:** 59-71 (Implementation Checklist, "MUGame-Linked" section)

**Description:** The ATDD checklist marks 12 items as `[x]` complete in the "Catch2 Unit Tests — MUGame-Linked" section, but ALL of these tests compile behind `#ifdef MU_SCENE_TESTS_ENABLED` which is never defined in CMakeLists.txt. At runtime, these tests emit `SKIP` and are never executed. The AC-to-Test Mapping table (lines 29-38) correctly shows "SKIP (needs MUGame)" status, but the Implementation Checklist contradicts this by marking them as complete.

**Impact:** Creates a false sense of test coverage. The tests for AC-1 (scene init state), AC-3 (CharacterSelectionState), AC-5 (selection bounds, frame timing), and AC-6 (clear selection, disconnect reset) have ZERO actual execution coverage.

**Suggested Fix:** Change the 12 MUGame-linked items from `[x]` to `[ ]` or mark them as `[~]` with a "SKIP — pending MUGame linkage" annotation. Alternatively, add `target_compile_definitions(MuTests PRIVATE MU_SCENE_TESTS_ENABLED)` and `target_link_libraries(MuTests PRIVATE MUGame)` to CMakeLists.txt to enable execution.

---

### Finding 2 — MEDIUM: Out-of-bounds rejection tests don't verify state preservation

**File:** `MuMain/tests/scenes/test_auth_character_validation.cpp`
**Lines:** 244-254

**Description:** The two out-of-bounds SECTION tests operate on a freshly constructed `CharacterSelectionState` (initial `selectedIndex = -1`). After calling `SelectCharacter(-1)` or `SelectCharacter(MAX_CHARACTERS_PER_ACCOUNT)`, the test only checks `HasSelection() == false`. Since the initial state is already "no selection," this assertion would pass even if SelectCharacter were a no-op or corrupted state to -1. The test doesn't prove the call was rejected — it only proves the post-state matches the pre-state by coincidence.

**Impact:** A regression in `SelectCharacter()` that sets `selectedIndex = -1` for invalid inputs (instead of leaving it unchanged) would pass this test undetected.

**Suggested Fix:** Set a valid selection first, then attempt the invalid one, then verify the valid selection is preserved:
```cpp
SECTION("Out-of-bounds index is rejected (index < 0)")
{
    state.SelectCharacter(2); // establish valid selection first
    state.SelectCharacter(-1);
    REQUIRE(state.HasSelection() == true);
    REQUIRE(state.GetSelectedIndex() == 2); // preserved
}
```

---

### Finding 3 — MEDIUM: FrameTimingState exposes public member variables

**File:** `MuMain/src/source/Scenes/SceneManager.h`
**Lines:** 23-25

**Description:** `lastRenderTickCount`, `currentTickCount`, and `lastWaterChange` are public member variables in `FrameTimingState`, while the class provides accessor methods (`UpdateCurrentTime`, `MarkFrameRendered`) for the first two. This breaks encapsulation — any code can directly mutate timing state, bypassing the methods. The test at line 297-302 correctly uses the methods, but production code could bypass them.

**Impact:** Future bugs from direct member modification in production code. The test validates the method-based API but can't protect against direct writes elsewhere.

**Suggested Fix:** Make `lastRenderTickCount`, `currentTickCount`, and `lastWaterChange` private. Add `GetCurrentTickCount()` and `GetLastWaterChange()` accessors for read access. Legacy code using direct access would need updating.

---

### Finding 4 — MEDIUM: `lastWaterChange` violates single responsibility in FrameTimingState

**File:** `MuMain/src/source/Scenes/SceneManager.h`
**Line:** 25

**Description:** `lastWaterChange` is a rendering-specific field (water animation timing) placed inside `FrameTimingState`, which is a frame-rate/timing abstraction. This field has no relation to frame timing — it tracks when water textures were last updated. Mixing rendering-specific state into a timing class violates the Single Responsibility Principle and makes the timing abstraction harder to reason about.

**Impact:** Confuses the class's purpose. Tests for FrameTimingState (lines 282-315) don't test `lastWaterChange` because it's not a timing concern, yet it's part of the same class.

**Suggested Fix:** Move `lastWaterChange` to a separate rendering state struct or to the water rendering system that uses it. This is not urgent but should be tracked as tech debt.

---

### Finding 5 — MEDIUM: SceneCommon.h includes ZzzInfomation.h unnecessarily, forcing MUGame dependency

**File:** `MuMain/src/source/Scenes/SceneCommon.h`
**Line:** 11

**Description:** SceneCommon.h includes `ZzzInfomation.h` with the comment "For MAX_CHARACTERS_PER_ACCOUNT", but `MAX_CHARACTERS_PER_ACCOUNT` is actually defined in `mu_define.h` (line 481). `ZzzInfomation.h` is a heavyweight header that transitively pulls in game-specific types, creating the MUGame dependency that forces 7 out of 9 test cases into SKIP status. If SceneCommon.h included `mu_define.h` directly instead, `CharacterSelectionState` and `SceneInitializationState` could be tested without MUGame linkage.

**Impact:** This single include is the root cause of why most AC-1/3/5/6 tests must be SKIP'd. Fixing it would enable the MUGame-linked tests to run as part of the standard MuTests build, resolving Finding 1 at the source.

**Suggested Fix:** Replace `#include "ZzzInfomation.h"` with `#include "mu_define.h"` in SceneCommon.h. Verify no other symbols from ZzzInfomation.h are needed by the header (none visible in the class definitions).

---

### Finding 6 — LOW: Missing negative test — invalid selection after valid selection

**File:** `MuMain/tests/scenes/test_auth_character_validation.cpp`
**Lines:** 225-255

**Description:** The AC-5 test verifies valid selections (slots 0 and 4) and checks that invalid indices are rejected on a fresh state. However, there is no test that verifies: select a valid slot → attempt an invalid selection → confirm the valid slot is still selected. This is the most important edge case for `SelectCharacter()` — that invalid inputs don't corrupt an existing valid selection.

**Impact:** A regression where `SelectCharacter(-1)` sets `selectedIndex = -1` (clearing an existing selection) would not be caught.

**Suggested Fix:** Add a section to the AC-5 test case:
```cpp
SECTION("Invalid selection does not clear existing valid selection")
{
    state.SelectCharacter(2);
    state.SelectCharacter(-1);
    REQUIRE(state.HasSelection() == true);
    REQUIRE(state.GetSelectedIndex() == 2);
}
```

---

### Finding 7 — LOW: Unnecessary PlatformCompat.h include in test file

**File:** `MuMain/tests/scenes/test_auth_character_validation.cpp`
**Line:** 38

**Description:** The non-Win32 branch includes both `PlatformTypes.h` (line 37) and `PlatformCompat.h` (line 38). For the always-enabled tests (AC-3, AC-4), only `BYTE` is needed (for the `CLASS_TYPE` enum), which comes from `PlatformTypes.h`. `PlatformCompat.h` adds Win32 API shims (`MessageBox`, `timeGetTime`, etc.) that are not used by any test logic. Including it adds unnecessary compilation overhead and couples tests to the Win32 compatibility layer.

**Impact:** Minor — increases compile time slightly and creates an unnecessary dependency. No functional impact.

**Suggested Fix:** Remove `#include "Platform/PlatformCompat.h"` from line 38 and verify compilation succeeds. If MUGame-linked tests need it (SceneCommon.h → PlatformCompat.h), it would be pulled in transitively by SceneCommon.h inside the `#ifdef MU_SCENE_TESTS_ENABLED` block.

---

## ATDD Coverage

### Summary

| Category | Total | Checked | Actually Executing | Gap |
|----------|-------|---------|-------------------|-----|
| Always-Enabled (AC-3, AC-4) | 8 | 8 | 8 | 0 |
| MUGame-Linked (AC-1, AC-5, AC-6) | 12 | 12 | 0 (SKIP) | **12** |
| Manual Validation (AC-VAL) | 5 | 0 | 0 (human required) | 5 |
| Quality Gate (AC-STD) | 5 | 5 | 5 | 0 |
| **Total** | **30** | **25** | **13** | **17** |

### AC-Level Coverage

| AC | Test Coverage | Executing? |
|----|--------------|------------|
| AC-1 | 2 unit tests (SceneInitializationState init, ResetAll) | SKIP |
| AC-2 | Covered by existing `test_platform_text_input.cpp` | GREEN (external) |
| AC-3 | 1 unit test (MAX_CHARACTERS_PER_ACCOUNT) + 1 SKIP test (CharacterSelectionState) | Partial |
| AC-4 | 7 unit tests (CLASS_TYPE enum values + contiguity) | GREEN |
| AC-5 | 4 SKIP tests (selection bounds, frame timing) | SKIP |
| AC-6 | 2 SKIP tests (ClearSelection, ResetForDisconnect) | SKIP |
| AC-STD-1 | Quality gate passed | GREEN |
| AC-STD-2 | Test suite exists but only 2/9 test cases execute | Partial |
| AC-STD-13 | `./ctl check` 0 errors | GREEN |
| AC-VAL-1..5 | Manual validation pending | Not started |
| AC-VAL-6 | Test scenarios documented | GREEN |

### Key Risk

The story's automated test coverage is significantly lower than the ATDD checklist suggests. Only **2 of 9** Catch2 test cases actually execute (AC-3 constant check + AC-4 enum values). The remaining 7 are SKIP'd, and the 2 placeholder SKIP tests collapse the 7 real tests into 2 SKIP entries. Root cause is Finding 5 (ZzzInfomation.h include) — fixing it would likely enable all tests.

---

## Review Verdict

**BLOCKER COUNT:** 0
**HIGH COUNT:** 1
**MEDIUM COUNT:** 4
**LOW COUNT:** 2

**Recommendation:** No blockers prevent story progression, but Finding 1 (phantom completions) should be acknowledged in the ATDD checklist before marking the story as done. Findings 2 and 5 are high-value improvements that would substantially improve real test coverage.

---

*Code review generated by PCC code-review workflow*
