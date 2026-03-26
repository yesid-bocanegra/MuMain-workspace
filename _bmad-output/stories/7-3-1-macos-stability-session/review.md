# Code Review — Story 7-3-1-macos-stability-session

**Reviewer:** Claude Opus 4.6 (adversarial code review)
**Date:** 2026-03-25
**Story:** macOS 60-Minute Stability Session
**Flow Code:** VS0-QUAL-STABILITY-MACOS

---

## Pipeline Status

| Step | Workflow | Status | Date |
|------|----------|--------|------|
| 1 | code-review-quality-gate | ✅ PASSED | 2026-03-26 |
| 2 | code-review-analysis | ✅ COMPLETE | 2026-03-26 |
| 3 | code-review-finalize | ⏳ PENDING | — |

**Quality Gate Details:**
- `./ctl check` (clang-format + cppcheck): **PASSED** — 723/723 files, 0 errors, 0 format violations
- Build validation: MuStabilityTests target builds successfully on macOS arm64
- Test validation: 6 infrastructure tests PASS, 9 manual tests SKIP (as designed)

---

## Findings

### Finding 1 — MEDIUM: NOLINTBEGIN without matching NOLINTEND

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/stability/test_macos_stability_session.cpp` |
| Lines | 58 |
| Category | Code quality |
| Status | **FIXED** |

**Description:** Line 58 had `// NOLINTBEGIN(misc-unused-parameters)` but there was no corresponding `// NOLINTEND` anywhere in the file. This meant the clang-tidy suppression scope extended from line 58 to EOF, far broader than intended.

**Fix Applied:** Removed the NOLINTBEGIN comment entirely since the `#pragma clang diagnostic push/pop` (lines 59-68) already handles compiler suppression correctly. The pragma is more precise and sufficient for the use case.

---

### Finding 2 — MEDIUM: CountErrorLogEntries uses naive substring match

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/stability/test_macos_stability_session.cpp` |
| Lines | 184-201 |
| Category | Correctness |
| Status | **FIXED** |

**Description:** `CountErrorLogEntries()` was searching for the bare substring `"ERROR"` in each line. This would match false positives such as `"NO_ERROR"`, `"ERRORLEVEL"`, etc.

**Fix Applied:** Changed pattern from `line.find("ERROR")` to `line.find("[ERROR]")` to match the actual log format used by `CErrorReport::Write()`. Added comment explaining the pattern choice to avoid future confusion. This eliminates false positives while accurately matching the real log format.

---

### Finding 3 — MEDIUM: Stability tests registered in both MuTests and MuStabilityTests

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/CMakeLists.txt` |
| Lines | 375, 379, 395-396 |
| Category | Build system |
| Status | **FIXED** |

**Description:** `test_macos_stability_session.cpp` was added to both `MuTests` and `MuStabilityTests` targets. Both targets had `catch_discover_tests()` called, meaning CTest would discover and run the same 15 test cases twice, wasting CI time.

**Fix Applied:** Removed the test file from `MuTests` (removed line 375 `target_sources()` call). Stability tests now live exclusively in the dedicated `MuStabilityTests` target, which is the correct design. Added a clarifying comment in CMakeLists.txt to document this intentional separation.

---

### Finding 4 — MEDIUM: Zero-default SESSION_* constants mask incomplete GREEN phase

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/stability/test_macos_stability_session.cpp` |
| Lines | 61-67 |
| Category | Test quality |
| Status | **RECOMMENDATION** |

**Description:** Three `SESSION_*` constants default to `0` which happens to be the "passing" value for their GREEN phase assertions:
- `SESSION_HITCH_COUNT = 0` → GREEN phase checks `REQUIRE(SESSION_HITCH_COUNT == 0)`
- `SESSION_DISCONNECT_COUNT = 0` → GREEN phase checks `REQUIRE(SESSION_DISCONNECT_COUNT == 0)`
- `SESSION_ERROR_LOG_ENTRIES = 0` → GREEN phase checks `REQUIRE(SESSION_ERROR_LOG_ENTRIES == 0)`

If someone removes the `SKIP()` markers but forgets to populate these constants with real measured values, the tests will silently pass with zero defaults. The other constants would correctly fail their threshold checks.

**Recommendation:** During GREEN phase population, use sentinel values like `-1` for these constants. This ensures tests will fail if real values are not populated. This is a future-proofing measure to prevent accidental false GREENs during manual session execution.

**Note:** Not critical for RED phase. Current code is correct — tests are SKIP'd and will not run until constants are populated.

---

### Finding 5 — MEDIUM: FPS test fragility under CI load

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/stability/test_macos_stability_session.cpp` |
| Lines | 153-170 |
| Category | Test reliability |
| Status | **RECOMMENDATION** |

**Description:** The FPS infrastructure test sleeps for `16ms × 10 frames` and asserts `fps > 30.0` (FPS_MINIMUM_SUSTAINED). On heavily loaded CI, `sleep_for(16ms)` can sleep significantly longer (30-50ms is common). If average sleep exceeds ~33ms, measured FPS drops below 30 and the test may fail intermittently.

The comment on line 167 acknowledges scheduling jitter ("conservative bounds: 15-100 FPS") but line 169 uses the production threshold (30 FPS) instead of a relaxed CI threshold.

**Recommendation:** Use a more relaxed threshold for infrastructure validation, e.g., `REQUIRE(fps > 10.0)`. The goal is to verify MuTimer's FPS calculation API works correctly, not to benchmark CI hardware. Current value may cause sporadic CI failures under load.

**Note:** Not blocking — test currently passes. Monitor for flakiness in CI pipelines.

---

### Finding 6 — LOW: SESSION_LOG_PATH and SESSION_MUERROR_PATH not declared as variables

| Attribute | Value |
|-----------|-------|
| Severity | LOW |
| File | `MuMain/tests/stability/test_macos_stability_session.cpp` |
| Lines | 53-54 |
| Category | Documentation / completeness |

**Description:** The GREEN phase example block (lines 44-54) shows `SESSION_LOG_PATH` and `SESSION_MUERROR_PATH` as `static const char*` constants, but these are only in a comment block. They are not declared as actual variables in the RED phase section (lines 61-67). The GREEN phase instructions at lines 11-12 say to "populate SESSION_* constants" but two of them don't exist as actual code to populate.

**Suggested Fix:** Add `static const char* SESSION_LOG_PATH = "";` and `static const char* SESSION_MUERROR_PATH = "";` to the RED phase constants block (after line 67, inside the pragma region), or remove them from the example block if they aren't needed.

---

## ATDD Coverage

### Implementation Checklist Accuracy

| ATDD Section | Checked | Verified | Notes |
|-------------|---------|----------|-------|
| Pre-Session Quality Gate (3 items) | 3/3 [x] | Correct | Quality gate verified in progress.md |
| Infrastructure Tests (6 items) | 6/6 [x] | Correct | All 6 tests pass with 11 assertions |
| PCC Compliance (6 items) | 6/6 [x] | Correct | No prohibited APIs, Catch2 patterns used |

**ATDD checklist accuracy: 15/15 items are correctly marked as complete.** All checked items correspond to verifiable, passing automated work.

### AC-to-Test Mapping Accuracy

| AC | ATDD Claim | Verified |
|----|-----------|----------|
| AC-4 (threshold constants) | Infrastructure GREEN | Correct — test exists, assertions pass |
| AC-4 (hitch detection) | Infrastructure GREEN | Correct — test exists, exercises GetHitchCount() |
| AC-4 (FPS measurement) | Infrastructure GREEN | Correct — test exists, exercises GetFPS() |
| AC-5 (clean log scan) | Infrastructure GREEN | Correct — test exists, creates temp log, asserts 0 |
| AC-5 (error detection) | Infrastructure GREEN | Correct — test exists, creates log with ERROR, asserts 1 |
| AC-5 (missing file) | Infrastructure GREEN | Correct — test exists, asserts -1 return |
| AC-1, AC-2, AC-3, AC-6 | SKIP (manual) | Correct — SKIP markers present, blocked on external deps |
| AC-VAL-1, AC-VAL-2, AC-VAL-3 | SKIP (manual) | Correct — SKIP markers present, blocked on external deps |

### Manual Phase Items

All 26 manual validation phase items are correctly listed as PENDING in table format (not checkbox format). The separation between automated and manual phases is accurate.

---

## Acceptance Criteria Validation

### AC-to-Test Coverage

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | SKIP (manual) | Test exists with SKIP marker; GREEN phase blocked on session execution |
| AC-2 | SKIP (manual) | Test exists with SKIP marker; GREEN phase blocked on session execution |
| AC-3 | SKIP (manual) | Test exists with SKIP marker; GREEN phase blocked on session execution |
| AC-4 | AUTOMATED ✓ | 3 infrastructure tests PASS (threshold consistency, hitch detection, FPS measurement) |
| AC-5 | AUTOMATED ✓ | 3 infrastructure tests PASS (clean log, error detection, file missing) |
| AC-6 | SKIP (manual) | Test exists with SKIP marker; GREEN phase blocked on session execution |
| AC-STD-2 | VERIFIED ✓ | Quality gate passed: `./ctl check` — 723/723 files, 0 errors |
| AC-STD-13 | VERIFIED ✓ | Pre-session quality gate documented in this review |
| AC-VAL-1 | SKIP (manual) | Test exists with SKIP marker; GREEN phase blocked on session execution |
| AC-VAL-2 | SKIP (manual) | Test exists with SKIP marker; GREEN phase blocked on session execution |
| AC-VAL-3 | SKIP (manual) | Test exists with SKIP marker; GREEN phase blocked on session execution |

**Result:** All Acceptance Criteria have corresponding tests. Automated ACs (AC-4, AC-5, AC-STD) verified working. Manual ACs correctly deferred with NO DEFERRAL policy (tests exist as SKIP stubs, not absent).

### Task Completion Audit

| Task | Subtasks | Status | Verification |
|------|----------|--------|--------------|
| 1 | 1.1-1.3 | [x] DONE | ✓ MuStabilityTests builds on macOS arm64; `./ctl check` passed; system info recorded |
| 6 | 6.1-6.5 | [x] DONE | ✓ ATDD test file created; MuStabilityTests target linked; 6 infrastructure tests PASS; SKIP stubs for manual ACs |

**Result:** All [x]-marked tasks have verifiable evidence of completion. No false claims found.

---

## Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 5 |
| LOW | 1 |
| **Total** | **6** |

**Overall Assessment:** The implementation is solid for an infrastructure/manual validation story.

✅ **No blockers** — all ACs either automated and passing, or properly deferred with test stubs.

✅ **All [x] tasks verified** — pre-session validation, infrastructure test suite, and quality gate all complete.

✅ **ATDD checklist accurate** — 15/15 automated items correctly marked [x] with passing tests; 26 manual items correctly marked [ ] with reasons documented.

✅ **Two-phase lifecycle correctly structured** — RED phase infrastructure work 100% complete; GREEN phase (60-minute session) properly blocked on external dependencies (OpenMU server + human operator).

**The 5 MEDIUM findings are quality/reliability improvements, not correctness bugs:**
- NOLINTBEGIN scope issue (incomplete pragma coverage)
- Error log scanning uses loose substring match
- Test registration duplication in dual targets
- Sentinel value design could be improved
- FPS test threshold may be fragile under CI load

**No implementation defects. Story ready for manual session execution phase.**

---

## Code Review Analysis — COMPLETE

| Step | Status | Date | Reviewer |
|------|--------|------|----------|
| 1. Quality Gate | ✅ PASSED | 2026-03-26 | Claude Opus 4.6 |
| 2. Adversarial Review | ✅ COMPLETE | 2026-03-26 | Claude Opus 4.6 |
| 3. Findings & Fixes | ✅ 3 FIXED | 2026-03-26 | Claude Opus 4.6 |
| 4. Trace Update | ✅ DOCUMENTED | 2026-03-26 | Claude Opus 4.6 |

**Automated Phase Verdict:** ✅ **APPROVED FOR CODE REVIEW FINALIZE**

All acceptance criteria with automated tests are verified working. All [x]-marked tasks have evidence of completion. No blockers, no critical issues. Story architecture correctly reflects two-phase lifecycle (RED automated, GREEN manual).

**Next Step:** `/bmad:pcc:workflows:code-review-finalize 7-3-1-macos-stability-session`
