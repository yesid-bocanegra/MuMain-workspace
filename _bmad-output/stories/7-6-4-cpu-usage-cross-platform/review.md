# Code Review — Story 7.6.4: Cross-Platform CPU Usage Monitoring

**Story Key:** `7-6-4-cpu-usage-cross-platform`
**Reviewer:** Claude (adversarial code review)
**Date:** 2026-03-25
**Status:** FINDINGS DOCUMENTED

---

## Pipeline Status

| Step | Status | Date |
|------|--------|------|
| 1. Quality Gate | PASSED | 2026-03-25 |
| 2. Code Review Analysis | FINDINGS DOCUMENTED | 2026-03-25 |
| 3. Code Review Finalize | pending | — |

## Quality Gate

**Status:** PASSED
**Date:** 2026-03-25
**Components:** 1 backend (mumain — cpp-cmake)

### Quality Gate Progress

| Phase | Status |
|-------|--------|
| Backend Local (lint) | PASSED |
| Backend Local (build) | PASSED |
| Backend Local (coverage) | PASSED (no coverage configured) |
| Backend SonarCloud | N/A (not configured) |
| Frontend Local | N/A (no frontend component) |
| Frontend SonarCloud | N/A (no frontend component) |
| Schema Alignment | N/A (no frontend component) |

### Quality Gate Summary

| Gate | Status | Iterations | Issues Fixed |
|------|--------|------------|--------------|
| Backend (1 component) | PASSED | 0 | 0 |
| Frontend (0 components) | N/A | — | — |
| **Overall** | **PASSED** | **0** | **0** |

### Non-Deterministic Checks

| Check | Status | Notes |
|-------|--------|-------|
| SonarCloud | N/A | No SONAR_TOKEN / project keys configured |
| Schema Alignment | N/A | No frontend component |
| AC Compliance | N/A | Infrastructure story (C++ cross-platform migration) |
| E2E Test Quality | N/A | No frontend/E2E tests |
| App Startup | N/A | Game client binary (not a server) |

---

## Findings

### Finding 1 — BLOCKER: Return value semantic change breaks all callers

| Attribute | Value |
|-----------|-------|
| Severity | BLOCKER |
| File | `MuMain/src/source/Core/CpuUsage.cpp:58-69` |
| Related | `MuMain/src/source/Main/Winmain.cpp:847`, `MuMain/src/source/Scenes/SceneManager.cpp:503-504` |

**Description:** `GetUsage()` now returns a fractional ratio in `[0.0, 1.0]` (the story explicitly normalised this from the legacy `[0, 100+]` percentage). However, the two callers were NOT updated:

1. `RecordCpuUsage()` (`Winmain.cpp:847`) clamps to `std::max(0.0, std::min(100.0, currentUsage))` — the upper bound `100.0` is irrelevant when the max is `1.0`.
2. `SceneManager.cpp:503` renders `CPU_AVG` as `"CPU: %.1f%%"` — expects a percentage value.

**Impact:** The CPU debug overlay will display "CPU: 0.4%" instead of the correct "CPU: 40.0%", making the diagnostic output functionally useless. The rolling average will also be incorrect because all 60 recorded samples are in `[0.0, 1.0]` but treated as percentages.

**Suggested Fix:** Either:
- (A) Update `RecordCpuUsage()` to multiply by 100 before clamping/storing: `currentUsage *= 100.0;`, OR
- (B) Update `SceneManager.cpp` format string to `"CPU: %.1f%%"` with `CPU_AVG * 100.0`, OR
- (C) Change `CpuUsage::GetUsage()` back to returning `[0, 100]` for backward compatibility (not recommended — [0,1] is the cleaner API).

---

### Finding 2 — HIGH: Unsigned integer underflow risk in CPU time delta

| Attribute | Value |
|-----------|-------|
| Severity | HIGH |
| File | `MuMain/src/source/Core/CpuUsage.cpp:48` |

**Description:**
```cpp
uint64_t processTimeElapsedNs = currentProcessTimeNs - m_lastProcessTimeNs;
```
Both operands are `uint64_t`. If `currentProcessTimeNs < m_lastProcessTimeNs` (e.g., OS bug, VM live migration, cgroup change), unsigned subtraction wraps to `~0ULL`, producing a huge value. The usage clamping at lines 61-68 catches this (returns 1.0), but it masks the root cause and produces a misleading 100% CPU spike with no diagnostic.

**Suggested Fix:** Add a signed comparison guard before the subtraction:
```cpp
if (currentProcessTimeNs < m_lastProcessTimeNs)
{
    g_ErrorReport.Write(L"CpuUsage: process time went backwards — returning 0.0\r\n");
    m_lastProcessTimeNs = currentProcessTimeNs;
    m_lastCheckTime = now;
    return 0.0;
}
```

---

### Finding 3 — MEDIUM: Test singleton state leaks between Catch2 test cases

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/core/test_cpu_usage.cpp:36, 63` |

**Description:** `CpuUsage::Instance()` returns a Meyers singleton whose state persists across Catch2 SECTIONs and TEST_CASEs. The AC-4 test's second SECTION ("second call after sleep") depends on the singleton being already initialised from the first SECTION or a prior call. The AC-5 test case inherits all prior state. This violates test isolation — if execution order changes or internal behaviour is timing-sensitive, tests may fail spuriously.

**Impact:** Low in practice (tests check ranges, not exact values), but the coupling makes future test maintenance fragile.

**Suggested Fix:** Document the singleton dependency with a comment, or consider adding a private `Reset()` method gated behind a test-only `#ifdef MU_TESTING` for future test isolation.

---

### Finding 4 — MEDIUM: No thread-safety documentation or enforcement on singleton

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/src/source/Core/CpuUsage.cpp:25-70` (Impl::GetUsage) |
| Related | `MuMain/src/source/Main/Winmain.cpp:1422` |

**Description:** `CpuUsage::Instance()` is a Meyers singleton (thread-safe construction per C++11). However, `Impl::GetUsage()` reads and writes `m_lastProcessTimeNs`, `m_lastCheckTime`, and `m_bInitialized` without any synchronisation. Currently only `RecordCpuUsage()` (running in its own `std::thread` at `Winmain.cpp:1422`) calls `GetUsage()`, so there is no active data race. But the public API exposes a raw pointer to a mutable singleton with no documentation that it is not thread-safe.

**Impact:** No active bug, but a future caller from another thread would silently introduce a data race.

**Suggested Fix:** Add a comment to `CpuUsage.h` on the `GetUsage()` declaration: `// NOT thread-safe — must only be called from a single thread`.

---

### Finding 5 — LOW: Stale RED-phase comments in test file

| Attribute | Value |
|-----------|-------|
| Severity | LOW |
| File | `MuMain/tests/core/test_cpu_usage.cpp:1-12` |

**Description:** The file header comments still say "RED PHASE — tests compile and run on macOS/Linux without Win32 APIs" and reference Tasks 3.1-3.4 as future work ("Tests become GREEN once..."). The implementation is complete and the story is in review — these comments are now misleading.

**Suggested Fix:** Update header to reflect GREEN status, or remove the task-tracking comments and keep only the AC-to-test mapping comments that remain accurate.

---

### Finding 6 — LOW: Dead code guard for `m_numProcessors == 0`

| Attribute | Value |
|-----------|-------|
| Severity | LOW |
| File | `MuMain/src/source/Core/CpuUsage.cpp:53` |

**Description:**
```cpp
if (wallElapsedNs <= 0 || m_numProcessors == 0)
```
The constructor at line 18-19 guarantees `m_numProcessors >= 1` (falls back to 1 if `hardware_concurrency()` returns 0). The `m_numProcessors == 0` branch can never execute.

**Impact:** Harmless dead code, but suggests the defensive check was cargo-culted rather than reasoned about.

**Suggested Fix:** Remove the `m_numProcessors == 0` clause, or document it as a defensive guard against future constructor changes.

---

## Summary

| Severity | Count | IDs |
|----------|-------|-----|
| BLOCKER | 1 | F1 |
| HIGH | 1 | F2 |
| MEDIUM | 2 | F3, F4 |
| LOW | 2 | F5, F6 |
| **Total** | **6** | |

**Verdict:** BLOCKER — Story cannot ship without fixing Finding 1 (return value range mismatch with callers).

---

## ATDD Coverage

| AC | ATDD Status | Actual Coverage | Notes |
|----|-------------|-----------------|-------|
| AC-1 | `[ ]` (script) | Script-validated | `check-win32-guards.py` — not an automated test |
| AC-2 | `[ ]` (build) | Build-validated | Compile check — removal of Win32 types verified by build |
| AC-3 | `[x]` | **Covered** | `test_cpu_usage.cpp:24-28` — checks `hardware_concurrency() > 0` |
| AC-4 | `[x]` | **Covered but see F1** | `test_cpu_usage.cpp:34-57` — checks [0.0, 1.0] range. Test passes but caller expects [0, 100] |
| AC-5 | `[x]` | **Covered** | `test_cpu_usage.cpp:62-72` — 5 rapid calls, checks `>= 0.0` |
| AC-6 | `[ ]` (script) | Script-validated | `./ctl check` — not an automated test |
| AC-STD-1 | `[ ]` (manual) | Format-validated | clang-format clean (quality gate) |
| AC-STD-2 | `[x]` | **Covered** | All 3 TEST_CASEs present and exercise core/cpu |
| AC-STD-13 | `[ ]` (script) | Script-validated | `./ctl check` passes |
| AC-STD-15 | `[ ]` (manual) | Manual | Git safety — verified by inspection |

**ATDD Note:** The AC-to-Test Mapping table in `atdd.md` shows all status boxes as `[ ]` (unchecked), but the Implementation Checklist and PCC Compliance Checklist are all `[x]`. The mapping table statuses should be updated to reflect actual GREEN phase status for AC-3, AC-4, AC-5, and AC-STD-2.
