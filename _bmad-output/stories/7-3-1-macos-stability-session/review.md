# Code Review — Story 7-3-1-macos-stability-session

**Reviewer:** Claude Opus 4.6 (adversarial code review)
**Date:** 2026-03-25
**Story:** macOS 60-Minute Stability Session
**Flow Code:** VS0-QUAL-STABILITY-MACOS

---

## Quality Gate

**Status:** Pending — run by pipeline

| Check | Result |
|-------|--------|
| lint (`./ctl check`) | Pending |
| build (`cmake --build`) | Pending |
| test (`ctest`) | Pending |

---

## Findings

### Finding 1 — MEDIUM: NOLINTBEGIN without matching NOLINTEND

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/stability/test_macos_stability_session.cpp` |
| Lines | 58 |
| Category | Code quality |

**Description:** Line 58 has `// NOLINTBEGIN(misc-unused-parameters)` but there is no corresponding `// NOLINTEND` anywhere in the file. This means the clang-tidy suppression scope extends from line 58 to EOF, which is far broader than intended. The suppression was only meant to cover the `SESSION_*` constants on lines 61-67.

**Additionally:** The check name `misc-unused-parameters` is incorrect — the actual issue being suppressed is unused const variables, not unused parameters. The pragma on lines 59-60/68 (`-Wunused-const-variable`) handles the compiler warning correctly, but the NOLINT comment is misleading and targets the wrong clang-tidy check.

**Suggested Fix:** Either (a) add `// NOLINTEND(misc-unused-parameters)` after line 68 and correct the check name to `clang-diagnostic-unused-const-variable`, or (b) remove the NOLINT comment entirely since the `#pragma clang diagnostic push/pop` already handles the suppression correctly.

---

### Finding 2 — MEDIUM: CountErrorLogEntries uses naive substring match

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/stability/test_macos_stability_session.cpp` |
| Lines | 184-201 |
| Category | Correctness |

**Description:** `CountErrorLogEntries()` searches for the bare substring `"ERROR"` in each line. This will match false positives such as `"NO_ERROR"`, `"ERRORLEVEL"`, `"[TERROR]"`, or any word containing "ERROR" as a substring. The actual `g_ErrorReport.Write()` log format uses `[ERROR]` with brackets, so a more precise match like `"[ERROR]"` would avoid false positives while accurately matching the real log format.

**Suggested Fix:** Change `line.find("ERROR")` to `line.find("[ERROR]")` to match the actual log format used by `CErrorReport::Write()`.

---

### Finding 3 — MEDIUM: Stability tests registered in both MuTests and MuStabilityTests

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/CMakeLists.txt` |
| Lines | 375, 379, 395-396 |
| Category | Build system |

**Description:** `test_macos_stability_session.cpp` is added as a source to both `MuTests` (line 375) and `MuStabilityTests` (line 379). Both targets have `catch_discover_tests()` called (lines 395-396), which means CTest will discover and register the same 15 test cases twice — once under `MuTests` and once under `MuStabilityTests`. Running `ctest` without a filter will execute every stability test case twice, wasting CI time and potentially causing confusion if one target passes but the other fails for environment reasons.

**Suggested Fix:** Either (a) remove line 375 (`target_sources(MuTests PRIVATE stability/test_macos_stability_session.cpp)`) so stability tests only live in `MuStabilityTests`, or (b) keep both but add a comment explaining why dual-registration is intentional (e.g., MuTests for CI regression, MuStabilityTests for isolated builds).

---

### Finding 4 — MEDIUM: Zero-default SESSION_* constants mask incomplete GREEN phase

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/stability/test_macos_stability_session.cpp` |
| Lines | 61-67 |
| Category | Test quality |

**Description:** Several `SESSION_*` constants default to `0` which happens to be the "passing" value for their GREEN phase assertions:
- `SESSION_HITCH_COUNT = 0` → GREEN phase checks `REQUIRE(SESSION_HITCH_COUNT == 0)` — passes without population
- `SESSION_DISCONNECT_COUNT = 0` → GREEN phase checks `REQUIRE(SESSION_DISCONNECT_COUNT == 0)` — passes without population
- `SESSION_ERROR_LOG_ENTRIES = 0` → GREEN phase checks `REQUIRE(SESSION_ERROR_LOG_ENTRIES == 0)` — passes without population

If someone removes the `SKIP()` markers but forgets to populate these constants with real measured values, the tests will pass vacuously with the zero defaults. The other constants (`SESSION_DURATION_MINUTES = 0.0`, `SESSION_MIN_FPS = 0.0`) would correctly fail their threshold checks, but these three would silently pass.

**Suggested Fix:** Use sentinel values that would fail the GREEN phase assertions, e.g., `SESSION_HITCH_COUNT = -1`, `SESSION_DISCONNECT_COUNT = -1`, `SESSION_ERROR_LOG_ENTRIES = -1`. Then the GREEN phase assertions `REQUIRE(x == 0)` would fail until real values are populated.

---

### Finding 5 — MEDIUM: FPS test fragility under CI load

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/stability/test_macos_stability_session.cpp` |
| Lines | 153-170 |
| Category | Test reliability |

**Description:** The FPS infrastructure test sleeps for `16ms × 10 frames` and then asserts `fps > 30.0` (FPS_MINIMUM_SUSTAINED). On a heavily loaded CI machine, `sleep_for(16ms)` can sleep significantly longer (30-50ms is common under contention). If average sleep exceeds ~33ms, the measured FPS drops below 30 and the test fails. This is a flaky test pattern.

The comment on line 167 acknowledges this ("Allow scheduling jitter — conservative bounds: 15-100 FPS") but the assertion at line 169 uses the production threshold (30 FPS) rather than a relaxed CI-appropriate threshold.

**Suggested Fix:** Use a more relaxed threshold for the infrastructure test, e.g., `REQUIRE(fps > 10.0)` — the goal is to verify MuTimer's FPS calculation works correctly, not to benchmark CI hardware. Alternatively, compute expected FPS from actual measured elapsed time rather than using a fixed threshold.

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

## Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| HIGH | 0 |
| MEDIUM | 5 |
| LOW | 1 |
| **Total** | **6** |

**Overall Assessment:** The implementation is solid for an infrastructure/manual validation story. No blockers. The 5 MEDIUM findings are all quality/reliability improvements rather than correctness bugs. The ATDD checklist accurately reflects the implementation state. The two-phase story model (automated RED + manual GREEN) is well-documented and correctly structured.
