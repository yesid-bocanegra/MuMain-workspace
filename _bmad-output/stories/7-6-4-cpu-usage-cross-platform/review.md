# Code Review — Story 7.6.4: Cross-Platform CPU Usage Monitoring

**Story Key:** `7-6-4-cpu-usage-cross-platform`
**Reviewer:** Claude (adversarial code review)
**Date:** 2026-03-25
**Status:** FINDINGS DOCUMENTED

---

## Pipeline Status

| Step | Status | Date |
|------|--------|------|
| 1. Quality Gate | PASSED (re-validated) | 2026-03-25 |
| 2. Code Review Analysis | FINDINGS DOCUMENTED | 2026-03-25 |
| 3. Code Review Finalize | PENDING | — |

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

### Finding 1 — HIGH: Incorrect API documentation — "1.0 = 100% of one core"

| Attribute | Value |
|-----------|-------|
| Severity | HIGH |
| File | `MuMain/src/source/Core/CpuUsage.h:10` |
| Related | `MuMain/src/source/Core/CpuUsage.cpp:68-69` |
| Status | RESOLVED |

**Description:** The header comment states: `Returns CPU utilisation as fractional ratio in [0.0, 1.0] where 1.0 = 100% of one core.` This is mathematically incorrect given the formula in `CpuUsage.cpp:68-69`:

```cpp
double usage = static_cast<double>(processTimeElapsedNs) / (static_cast<double>(wallElapsedNs) * m_numProcessors);
```

With `m_numProcessors` in the denominator, the semantics are:
- 1.0 = 100% of **ALL** cores (fully saturated)
- 100% of **one** core on an 8-core system = 0.125, not 1.0

This misleads callers about the scale. The `RecordCpuUsage` function already multiplies by 100.0 to get a percentage, so a system using 1 core at 100% on an 8-core machine shows ~12.5% — a developer reading the header might think this is wrong.

**Fix Applied:** Changed the comment to: `Returns CPU utilisation as fractional ratio in [0.0, 1.0] where 1.0 = 100% of all cores.` ✅ FIXED

---

### Finding 2 — MEDIUM: Data race on `CPU_AVG` global variable

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/src/source/Main/Winmain.cpp:832,872` |
| Status | OPEN |
| Note | Pre-existing — not introduced by this story |

**Description:** `CPU_AVG` is a non-atomic `double` global (line 832) written by the `RecordCpuUsage` worker thread (line 872) and read by the main/render thread. Under the C++11 memory model, concurrent read/write of a non-atomic variable without synchronization is undefined behavior. The story modified the scaling math in `RecordCpuUsage` (line 848) but did not address the pre-existing data race.

**Suggested Fix:** Change `double CPU_AVG = 0.0;` to `std::atomic<double> CPU_AVG{0.0};` — `std::atomic<double>` is lock-free on modern x86/ARM64. Out-of-scope for this story; recommend a follow-up tech-debt item.

---

### Finding 3 — MEDIUM: `std::thread cpuUsageRecorder` never joined or detached

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/src/source/Main/Winmain.cpp:1423-1428` |
| Status | OPEN |
| Note | Pre-existing — not introduced by this story |

**Description:** `std::thread cpuUsageRecorder(RecordCpuUsage)` is created at line 1423. `WinMain` returns at line 1428 without joining or detaching the thread. If the thread is still running at destructor time, C++ calls `std::terminate()`. The thread loop checks `while (!Destroy)` but there's no guarantee it has exited by the time the destructor runs.

**Suggested Fix:** Add `cpuUsageRecorder.join();` after `DestroyWindow();` (line 1426), or `cpuUsageRecorder.detach();` immediately after creation if fire-and-forget is intended. Out-of-scope for this story.

---

### Finding 4 — MEDIUM: AC-5 test does not cover the syscall-failure error path

| Attribute | Value |
|-----------|-------|
| Severity | MEDIUM |
| File | `MuMain/tests/core/test_cpu_usage.cpp:59-69` |
| Related | `MuMain/src/source/Core/CpuUsage.cpp:29-33` |
| Status | OPEN |

**Description:** AC-5 requires: "If per-process timing is unavailable, the implementation returns 0.0 and logs a diagnostic via `g_ErrorReport.Write()` — it does NOT crash or assert." The test only verifies rapid calls don't crash and return `>= 0.0`:

```cpp
for (int i = 0; i < 5; ++i)
{
    double usage = cpu->GetUsage();
    REQUIRE(usage >= 0.0);
}
```

The actual error path — `mu_get_process_cpu_times()` returning `false`, triggering `g_ErrorReport.Write()` and returning `0.0` — is never exercised. The ATDD checklist marks AC-5 as `[x]` (fully covered) but the failure-mode behavior is untested.

**Suggested Fix:** Accept as-is with documentation caveat — the failure path cannot be tested without mocking `getrusage`/`GetProcessTimes`, which requires dependency injection not present in this singleton design. Add a comment to the ATDD noting partial coverage. Alternatively, add a `#ifdef MU_TESTING` path to force failure in a dedicated test.

---

### Finding 5 — LOW: Dead code — `usage < 0.0` check can never execute

| Attribute | Value |
|-----------|-------|
| Severity | LOW |
| File | `MuMain/src/source/Core/CpuUsage.cpp:71-74` |
| Status | OPEN |

**Description:** At line 71, `usage` is computed as `uint64_t / (positive_double * positive_int)`. Since `processTimeElapsedNs` is `uint64_t` (always >= 0), `wallElapsedNs` is guaranteed > 0 (line 63 returns if <= 0), and `m_numProcessors >= 1`, the result can never be negative. The `usage < 0.0` branch is dead code.

**Suggested Fix:** Remove the `usage < 0.0` check, or add a comment acknowledging it as intentional defense-in-depth. Minor — no functional impact.

---

### Finding 6 — LOW: `mu_get_process_cpu_times` does not validate pointer arguments

| Attribute | Value |
|-----------|-------|
| Severity | LOW |
| File | `MuMain/src/source/Platform/PlatformCompat.h:2437,2453` |
| Status | OPEN |

**Description:** Both the Win32 and POSIX overloads of `mu_get_process_cpu_times` dereference `kernelNs` and `userNs` without null pointer checks. The function is internal-only with a single call site (`CpuUsage.cpp:29`) that always passes valid stack variables, so the practical risk is negligible.

**Suggested Fix:** Accept as-is — the function is internal with a controlled call site. Adding null checks would add overhead for a scenario that can't occur. Optionally, add an `assert(kernelNs && userNs)` for debug builds.

---

## Summary

| Severity | Count | IDs | Status |
|----------|-------|-----|--------|
| BLOCKER | 0 | — | — |
| HIGH | 1 | F1 | ✅ RESOLVED |
| MEDIUM | 3 | F2, F3, F4 | OPEN (2 pre-existing, 1 inherent) |
| LOW | 2 | F5, F6 | OPEN (acceptable) |
| **Total** | **6** | | **1 RESOLVED, 5 OPEN** |

**Verdict:** No BLOCKERs. HIGH finding (F1 — incorrect documentation) **RESOLVED in this analysis pass**. Two MEDIUM findings (F2, F3) are pre-existing concurrency issues out-of-scope — recommend tech-debt items. One MEDIUM finding (F4) is an inherent limitation of singleton design — accept with documentation. Two LOW findings are acceptable as-is (dead code, lack of null checks on internal function).

**Action items completed:** F1 ✅ Documentation corrected from "100% of one core" to "100% of all cores"

---

## ATDD Coverage

| AC | ATDD Status | Actual Coverage | Verification | Notes |
|----|-------------|-----------------|--------------|-------|
| AC-1 | `[x]` (script) | Script-validated | 2026-03-25 | `check-win32-guards.py` exits 0 |
| AC-2 | `[x]` (build) | Build-validated | 2026-03-25 | No Win32 headers in CpuUsage.cpp |
| AC-3 | `[x]` | **Covered** | 2026-03-25 | `hardware_concurrency() > 0` test |
| AC-4 | `[x]` | **Covered** | 2026-03-25 | Range [0.0, 1.0] test after sleep |
| AC-5 | `[x]` | **Partial** | 2026-03-25 | Tests crash-safety only; syscall-failure error path untested (see F4) |
| AC-6 | `[x]` (script) | Script-validated | 2026-03-25 | `./ctl check` exits 0 |
| AC-STD-1 | `[x]` (manual) | Format-validated | 2026-03-25 | `std::chrono::steady_clock`, clang-format clean |
| AC-STD-2 | `[x]` | **Covered** | 2026-03-25 | 3 test cases in test_cpu_usage.cpp |
| AC-STD-13 | `[x]` (script) | Script-validated | 2026-03-25 | `./ctl check` exits 0 |
| AC-STD-15 | `[x]` (manual) | Git safety verified | 2026-03-25 | No force push or incomplete rebase |

**ATDD Accuracy:** 9 of 10 ACs accurately reflected. AC-5 is marked fully covered but actual test coverage is partial (crash-safety only, not the error-path behavior). Overall ATDD accuracy: **90%**.
