# Code Review: Story 7-6-7 — ErrorReport Cross-Platform Crash Diagnostics

**Reviewer**: Adversarial Code Review (PCC Pipeline Step)
**Date**: 2026-03-25
**Story Status at Review**: review

---

## Pipeline Status

| Step | Status |
|------|--------|
| 1. Quality Gate | PASSED |
| 2. Code Review Analysis | COMPLETE |
| 3. Code Review Finalize | Pending |

## Quality Gate

**Status**: PASSED
**Date**: 2026-03-25
**Components**: mumain (backend, cpp-cmake)

| Check | Result | Notes |
|-------|--------|-------|
| lint (`make -C MuMain lint`) | PASS | cppcheck clean |
| format-check (`make -C MuMain format-check`) | PASS | clang-format clean |
| build (cmake + ninja, macOS arm64) | PASS | Native build succeeds with Homebrew LLVM |
| coverage | PASS | No coverage threshold configured yet |
| SonarCloud | N/A | No SONAR_TOKEN configured for cpp-cmake |
| Schema Alignment | N/A | No frontend / no API contracts |
| AC Compliance | Skipped | Infrastructure story — no Playwright/integration AC tests |
| E2E Test Quality | N/A | No frontend |
| App Startup | N/A | Game client binary — no server boot check applicable |

**Iterations**: 0 (all checks passed on first run)
**Issues Fixed**: 0

---

## Findings

### Finding 1 — BLOCKER: Test AC-3/AC-STD-2 calls wrong function; will fail at runtime

- **Severity**: BLOCKER
- **File**: `MuMain/tests/core/test_error_report.cpp`
- **Lines**: 261–273
- **Description**: The test `"AC-3/AC-STD-2 [7-6-7]: WriteSystemInfo populates OS, CPU, and RAM fields"` creates a zero-initialized `ER_SystemInfo si{}` and then calls `g_ErrorReport.WriteSystemInfo(&si)`. However, `CErrorReport::WriteSystemInfo()` (ErrorReport.cpp:297–305) only **logs** the struct fields to the error report — it does **not populate** them. The population is performed by the free function `GetSystemInfo(ER_SystemInfo*)` (ErrorReport.cpp:379–461). The test never calls `GetSystemInfo()`, so `si` remains zero-initialized and all three `REQUIRE` assertions (`m_lpszOS[0] != L'\0'`, `m_lpszCPU[0] != L'\0'`, `m_iMemorySize > 0`) will fail.
- **Suggested Fix**: Call `GetSystemInfo(&si)` before `g_ErrorReport.WriteSystemInfo(&si)` in the test, matching the calling pattern in Winmain.cpp (lines 1001–1005).

### Finding 2 — HIGH: `m_iMemorySize` integer overflow on machines with >2GB RAM

- **Severity**: HIGH
- **File**: `MuMain/src/source/Core/ErrorReport.h` (line 16), `MuMain/src/source/Core/ErrorReport.cpp` (lines 437, 452)
- **Lines**: ErrorReport.h:16, ErrorReport.cpp:437, ErrorReport.cpp:452
- **Description**: `ER_SystemInfo.m_iMemorySize` is declared as `int` (32-bit signed, max ~2.1 billion). On macOS, `sysctlbyname("hw.memsize")` returns the RAM size in bytes as `uint64_t`. For any machine with >= 2GB RAM (i.e., all modern machines), `static_cast<int>(memSize)` produces undefined behavior / wraps to 0 or a negative value. Example: 16GB = 17,179,869,184 bytes, which wraps to 0 when truncated to 32-bit int. On Linux, `memKb * 1024` (KB→bytes) is computed as `long long` but then cast to `int` with the same overflow. The `WriteSystemInfo` line `1 + (si->m_iMemorySize / 1024 / 1024)` will display "RAM: 1MB" or garbage for any modern machine.
- **Suggested Fix**: Either (a) change `m_iMemorySize` to `int64_t` or `uint64_t`, or (b) store the value in MB directly (e.g., `si->m_iMemorySize = static_cast<int>(memSize / (1024 * 1024))`) so the `int` range covers up to ~2TB.

### Finding 3 — MEDIUM: `#ifdef _WIN32` guards remain in HexWrite method body

- **Severity**: MEDIUM
- **File**: `MuMain/src/source/Core/ErrorReport.cpp`
- **Lines**: 228–232
- **Description**: `HexWrite()` contains `#ifdef _WIN32 ... #else ... #endif` to select between MSVC `swprintf` (no size parameter) and C99 `swprintf` (with explicit buffer size). AC-STD-1 requires "zero `#ifdef _WIN32` in ErrorReport.cpp." While the `check-win32-guards.py` script passed (AC-1), this is a literal violation of the stated acceptance criterion. The dev notes acknowledge the `WriteCurrentTime` guard (lines 270–274) as "platform abstraction, not game logic" but do not mention this `HexWrite` guard.
- **Suggested Fix**: Use the `mu_swprintf` macro (already defined in stdafx.h and used elsewhere in `HexWrite`) for the address prefix as well, eliminating the `#ifdef _WIN32` guard entirely.

### Finding 4 — MEDIUM: ATDD checklist marked GREEN without test execution

- **Severity**: MEDIUM
- **File**: `_bmad-output/stories/7-6-7-error-report-cross-platform-diagnostics/atdd.md`
- **Lines**: 6 (Status line)
- **Description**: The ATDD status is marked `GREEN (all tests pass, all tasks complete)` but the cpp-cmake tech profile has `skip_checks: [build, test]` on macOS, and `./ctl check` runs format + lint only — it does not compile or run Catch2 tests. The tests were never actually executed. Finding 1 (BLOCKER) demonstrates that at least one test has a logic error that would cause runtime failure. Claiming GREEN status based on code inspection alone is inaccurate.
- **Suggested Fix**: Update ATDD status to note that GREEN is verified by code inspection and quality gate (lint), not by test execution. Tests require a full build environment (MinGW cross-compile or native Linux/Windows) to run.

### Finding 5 — MEDIUM: `GetSystemInfo` free function name collides with Windows API

- **Severity**: MEDIUM
- **File**: `MuMain/src/source/Core/ErrorReport.h` (line 82), `MuMain/src/source/Core/ErrorReport.cpp` (line 379)
- **Lines**: ErrorReport.h:82, ErrorReport.cpp:379
- **Description**: The free function `void GetSystemInfo(ER_SystemInfo* si)` shares its name with the Win32 API `void WINAPI GetSystemInfo(LPSYSTEM_INFO)` from `<sysinfoapi.h>`. While the different parameter types prevent a direct collision via C++ overloading, `windows.h` can macro-define `GetSystemInfo` to `GetSystemInfoA`/`GetSystemInfoW` on certain MSVC configurations, which would silently rename the function and break callers. Additionally, the function was listed as "removed" in Task 6.3 of the ATDD checklist, yet it still exists as a cross-platform reimplementation.
- **Suggested Fix**: Rename to `MuGetSystemInfo` or `PopulateSystemInfo` to eliminate any naming ambiguity with the Win32 API.

### Finding 6 — LOW: Forward declaration of `mu::GetAudioDeviceNames()` instead of include

- **Severity**: LOW
- **File**: `MuMain/src/source/Core/ErrorReport.cpp`
- **Lines**: 288–291
- **Description**: A forward declaration `namespace mu { std::vector<std::string> GetAudioDeviceNames(); }` is used instead of including `MiniAudioBackend.h`. This is an intentional design choice (keep `miniaudio.h` out of `ErrorReport.cpp`), but it creates a maintenance risk — if the function signature changes in `MiniAudioBackend.h`, the forward declaration silently becomes inconsistent, leading to link errors or ODR violations.
- **Suggested Fix**: No immediate action required. Consider extracting `GetAudioDeviceNames()` declaration into a lightweight header (e.g., `Platform/MiniAudio/AudioDeviceNames.h`) that does not include `miniaudio.h`.

### Finding 7 — LOW: `WriteCurrentTime` retains `#ifdef _WIN32` guard (acknowledged)

- **Severity**: LOW
- **File**: `MuMain/src/source/Core/ErrorReport.cpp`
- **Lines**: 270–274
- **Description**: `WriteCurrentTime()` uses `#ifdef _WIN32` to select between `localtime_s` (MSVC) and `localtime_r` (POSIX). This is explicitly acknowledged in the dev agent completion notes as "platform abstraction, not game logic." AC-STD-1 literally says "zero `#ifdef _WIN32`," but this is a standard POSIX/MSVC portability pattern with no game-logic contamination.
- **Suggested Fix**: Could be unified via `#if defined(_MSC_VER)` (compiler-specific) instead of `_WIN32` (platform-specific) to better express intent, but this is cosmetic.

---

## ATDD Coverage

| AC | ATDD Status | Review Assessment | Notes |
|----|-------------|-------------------|-------|
| AC-1 | `[x]` | Accurate | `check-win32-guards.py` pass verified |
| AC-2 | `[x]` | Accurate | Win32 block deleted; verified by code inspection |
| AC-3 | `[x]` | **Inaccurate** | Test calls wrong function (Finding 1 — BLOCKER). GetSystemInfo() populates struct correctly, but test verifies WriteSystemInfo which only logs. |
| AC-4 | `[x]` | Accurate | WriteOpenGLInfo compiles without `#ifdef _WIN32`; nullptr-safe |
| AC-5 | `[x]` | Accurate | WriteImeInfo takes `SDL_Window*`; nullptr handled |
| AC-6 | `[x]` | Accurate | WriteSoundCardInfo uses `mu::GetAudioDeviceNames()` |
| AC-7 | `[x]` | Accurate | Win32 functions deleted |
| AC-8 | `[x]` | Accurate | `m_lpszGpuBackend` field exists; test compiles |
| AC-9 | `[x]` | Accurate | `#else` stubs removed from ErrorReport.h |
| AC-10 | `[x]` | Accurate | Winmain.cpp passes `nullptr` (SDL_Window*) |
| AC-11 | `[x]` | Accurate | `./ctl check` passes |
| AC-STD-1 | `[x]` | **Partial** | ErrorReport.h is clean; ErrorReport.cpp retains 2 `#ifdef _WIN32` guards (Findings 3, 7) |
| AC-STD-2 | `[x]` | **Inaccurate** | Test exists but has logic error — will fail at runtime (Finding 1) |
| AC-STD-13 | `[x]` | Accurate | Quality gate passes |
| AC-STD-15 | `[x]` | Accurate | No force push or rebase issues |

**ATDD Accuracy**: 12/15 criteria accurately verified. 3 criteria have issues (AC-3 test bug, AC-STD-1 residual guards, AC-STD-2 test bug).

---

## Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 1 |
| HIGH | 1 |
| MEDIUM | 3 |
| LOW | 2 |
| **Total** | **7** |

**BLOCKER** must be resolved before story can proceed to `done`:
- Finding 1: Test `AC-3/AC-STD-2` calls `WriteSystemInfo` instead of `GetSystemInfo` — test will fail at runtime.

**HIGH** should be resolved:
- Finding 2: `m_iMemorySize` integer overflow produces garbage RAM values on all modern machines (>2GB).

**Recommendation**: Fix BLOCKER and HIGH findings. MEDIUM findings (3, 4, 5) are valid concerns but non-blocking for story completion given the `check-win32-guards.py` script passes and the naming collision is theoretical.
