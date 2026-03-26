# Code Review: Story 7-6-7 — ErrorReport Cross-Platform Crash Diagnostics

**Reviewer**: Adversarial Code Review (PCC Pipeline — code-review step)
**Date**: 2026-03-25
**Story Status at Review**: review

---

## Pipeline Status

| Step | Status | Details |
|------|--------|---------|
| 1. Quality Gate | PASSED | Re-validated 2026-03-25 — all checks green |
| 2. Code Review | IN PROGRESS | This document — adversarial review of current code state |
| 3. Code Review Analysis | Pending | Separate pipeline step |
| 4. Code Review Finalize | Pending | Separate pipeline step |

## Quality Gate

**Status**: PASSED
**Date**: 2026-03-25
**Components**: mumain (backend, cpp-cmake)

### Backend: mumain

| Check | Result | Notes |
|-------|--------|-------|
| lint (`make -C MuMain lint`) | PASS | cppcheck clean |
| build (cmake + ninja macOS arm64) | PASS | Homebrew LLVM clang, all TUs compile |
| coverage | PASS | No threshold configured |
| SonarCloud | SKIPPED | No SONAR_TOKEN configured |

### Frontend

| Check | Result | Notes |
|-------|--------|-------|
| (all) | SKIPPED | No frontend components in this story |

### Non-Deterministic Checks

| Check | Result | Notes |
|-------|--------|-------|
| Schema Alignment | SKIPPED | No frontend — no backend/frontend drift to validate |
| AC Compliance | SKIPPED | Infrastructure story — no Playwright/integration AC tests |
| E2E Test Quality | SKIPPED | Infrastructure story — no E2E tests |
| App Boot Verification | N/A | Game client (Win32 GUI), not a server — build success is the applicable check |

**Iterations**: 0 (all checks passed on first run)

### Quality Gate Summary

| Gate | Status | Iterations | Issues Fixed |
|------|--------|------------|--------------|
| Backend Local (mumain) | PASSED | 0 | 0 |
| Backend SonarCloud | SKIPPED | — | — |
| Frontend Local | SKIPPED | — | — |
| Frontend SonarCloud | SKIPPED | — | — |
| **Overall** | **PASSED** | **0** | **0** |

---

## Findings

### Finding 1 — HIGH: `GetSystemInfo` free function name collides with Win32 API macro

- **Severity**: HIGH
- **File**: `MuMain/src/source/Core/ErrorReport.h:82`, `MuMain/src/source/Core/ErrorReport.cpp:379`
- **Lines**: ErrorReport.h:82, ErrorReport.cpp:379, test_error_report.cpp:264
- **Description**: The free function `void GetSystemInfo(ER_SystemInfo* si)` shares its name with the Win32 API `GetSystemInfo` from `<sysinfoapi.h>`. On Windows builds, `<windows.h>` (included via stdafx.h PCH) defines `GetSystemInfo` as a macro expanding to `GetSystemInfoA` or `GetSystemInfoW`. This causes the preprocessor to silently rename the function, which:
  1. Shadows the real Win32 `GetSystemInfo` — any code in the same TU cannot call the Win32 version.
  2. Creates fragile coupling to `#include` ordering — if `windows.h` is included after `ErrorReport.h` in some TU, the declaration and definition will have different names.
  3. Story Task 6.3 specified this function should be **removed** ("superseded by `WriteSystemInfo` cross-platform implementation"), yet it was kept and reimplemented. The ATDD marks Task 6.3 as `[x]` complete.
- **Suggested Fix**: Rename to `MuGetSystemInfo()` or `PopulateSystemInfo()`, or move into a namespace (e.g., `mu::GetSystemInfo`). Update the test and Winmain.cpp call site.

### Finding 2 — MEDIUM: `cpuLine.substr(pos + 2)` can throw on malformed `/proc/cpuinfo`

- **Severity**: MEDIUM
- **File**: `MuMain/src/source/Core/ErrorReport.cpp`
- **Lines**: 418
- **Description**: In the Linux CPU detection path, `cpuLine.substr(pos + 2)` is called after finding the colon in a `/proc/cpuinfo` "model name" line. If the line is truncated or malformed (e.g., `"model name:"` with nothing after the colon), `pos + 2` could exceed `cpuLine.size()`, throwing `std::out_of_range`. While `/proc/cpuinfo` format is stable in practice, `GetSystemInfo()` is called during crash reporting — an exception here would mask the original crash.
- **Suggested Fix**: Add bounds check: `if (pos + 2 < cpuLine.size()) { ... }` before calling `substr()`.

### Finding 3 — MEDIUM: Windows/MinGW builds get useless CPU and RAM diagnostics

- **Severity**: MEDIUM
- **File**: `MuMain/src/source/Core/ErrorReport.cpp`
- **Lines**: 406–456
- **Description**: The `#ifdef __APPLE__` / `#else` structure for CPU and RAM detection sends Windows/MinGW builds into the Linux `#else` path, which reads `/proc/cpuinfo` and `/proc/meminfo`. These files don't exist on Windows, resulting in "Unknown CPU" and `m_iMemorySize = 0` (0 MB RAM reported). The diagnostic is effectively useless on the MinGW cross-compile target, which is the primary build environment per CLAUDE.md. The OS field works because MinGW provides `uname()` via POSIX compatibility.
- **Suggested Fix**: Add `#elif defined(__linux__)` to make the Linux path explicit, and add a Windows fallback that either reports "N/A (MinGW)" or uses MinGW-compatible POSIX APIs. Alternatively, document this as a known limitation if Windows crash diagnostics are not in scope.

### Finding 4 — MEDIUM: `HexWrite` retains `#ifdef _WIN32` guard in method body

- **Severity**: MEDIUM
- **File**: `MuMain/src/source/Core/ErrorReport.cpp`
- **Lines**: 228–232
- **Description**: `HexWrite()` contains an `#ifdef _WIN32` / `#else` guard to handle the `swprintf` signature difference (MSVC omits the buffer size parameter). AC-STD-1 states "zero `#ifdef _WIN32` in ErrorReport.cpp." While `check-win32-guards.py` permits this as a platform abstraction pattern, `mu_swprintf` (defined in stdafx.h and used elsewhere in the same function at lines 235, 240, 243, 247, 251) already abstracts this difference. The guard is unnecessary.
- **Suggested Fix**: Replace lines 228–232 with a single `mu_swprintf` call:
  ```cpp
  offset += mu_swprintf(szLine + offset, L"0x%08X : ", (DWORD)(uintptr_t)pBuffer);
  ```
  This eliminates the guard while using the same pattern as the rest of the function body.

### Finding 5 — LOW: `MAX_DXVERSION` macro name not updated to match renamed field

- **Severity**: LOW
- **File**: `MuMain/src/source/Core/ErrorReport.h`
- **Lines**: 8
- **Description**: The macro `#define MAX_DXVERSION (128)` still uses the old "DxVersion" naming even though the field it sizes was renamed from `m_lpszDxVersion` to `m_lpszGpuBackend` (AC-8). The macro name is misleading — readers may assume it relates to DirectX versioning.
- **Suggested Fix**: Rename to `MAX_GPU_BACKEND_LEN` or similar, and update the test assertion at `test_error_report.cpp:249` which references `MAX_DXVERSION`.

### Finding 6 — LOW: Forward declaration of `mu::GetAudioDeviceNames()` duplicates header

- **Severity**: LOW
- **File**: `MuMain/src/source/Core/ErrorReport.cpp`
- **Lines**: 288–291
- **Description**: A forward declaration `namespace mu { std::vector<std::string> GetAudioDeviceNames(); }` duplicates the declaration in `MiniAudioBackend.h:32`. This is intentional (keep `miniaudio.h` out of `ErrorReport.cpp`), but if the signature changes in the header, the forward declaration silently becomes inconsistent, potentially causing ODR violations or link errors that are difficult to diagnose.
- **Suggested Fix**: No immediate action required. Consider extracting the declaration into a lightweight header (e.g., `Platform/MiniAudio/AudioDeviceNames.h`) that doesn't include `miniaudio.h`, to provide a single source of truth.

### Finding 7 — LOW: `ma_context_get_devices` return value unchecked

- **Severity**: LOW
- **File**: `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp`
- **Lines**: 682
- **Description**: In `GetAudioDeviceNames()`, the return value of `ma_context_get_devices(&ctx, &pPlayback, &playbackCount, nullptr, nullptr)` is not checked. If the call fails, `pPlayback` and `playbackCount` remain at their initialized values (nullptr and 0), so the loop is skipped safely. However, not checking the return value hides potential errors and is inconsistent with the `ma_context_init` call on line 675, which does check its result.
- **Suggested Fix**: Check the return value and return early on failure (matching the pattern on line 675):
  ```cpp
  if (ma_context_get_devices(&ctx, &pPlayback, &playbackCount, nullptr, nullptr) != MA_SUCCESS)
  {
      ma_context_uninit(&ctx);
      return {};
  }
  ```

---

## ATDD Coverage

### Step 3: Cross-reference ATDD checklist against test implementations

| AC | ATDD Status | Review Assessment | Notes |
|----|-------------|-------------------|-------|
| AC-1 | `[x]` | **Accurate** | `check-win32-guards.py` passes (verified by completeness gate) |
| AC-2 | `[x]` | **Accurate** | Win32 block deleted — no `#ifdef _WIN32 … #else … #endif` in method bodies |
| AC-3 | `[x]` | **Accurate** | Test calls `GetSystemInfo(&si)` then `WriteSystemInfo(&si)`; asserts OS, CPU, RAM fields populated |
| AC-4 | `[x]` | **Accurate** | `WriteOpenGLInfo()` compiles without guard; nullptr-safe on `glGetString` returns |
| AC-5 | `[x]` | **Accurate** | Signature changed to `SDL_Window*`; test passes `nullptr` safely |
| AC-6 | `[x]` | **Accurate** | `WriteSoundCardInfo` uses `mu::GetAudioDeviceNames()`; no DirectSound |
| AC-7 | `[x]` | **Accurate** | `GetDXVersion`, `GetOSVersion`, `GetCPUInfo` (Win32), `DSoundEnumCallback` all deleted |
| AC-8 | `[x]` | **Accurate** | `m_lpszGpuBackend` field exists; test verifies size at compile time |
| AC-9 | `[x]` | **Accurate** | `#else` empty stubs removed from ErrorReport.h |
| AC-10 | `[x]` | **Accurate** | Winmain.cpp:1268 passes `nullptr` (SDL_Window*) instead of `HWND` |
| AC-11 | `[x]` | **Accurate** | Pre-run quality gate PASS confirms `./ctl check` green |
| AC-STD-1 | `[x]` | **Partial** | ErrorReport.h is clean. ErrorReport.cpp retains 5 platform guards (#ifndef _WIN32 for POSIX includes/fd, #ifdef _WIN32 in HexWrite and WriteCurrentTime). Script passes — guards are platform abstraction, not game logic. But literal wording says "zero." |
| AC-STD-2 | `[x]` | **Accurate** | Catch2 test exists with correct logic (GetSystemInfo + WriteSystemInfo + assertions). Note: tests cannot execute on macOS (cpp-cmake skip_checks: [build, test]). |
| AC-STD-13 | `[x]` | **Accurate** | Pre-run quality gate PASS |
| AC-STD-15 | `[x]` | **Accurate** | No force push, no incomplete rebase |

**ATDD Accuracy**: 14/15 criteria fully accurate. AC-STD-1 is partially accurate — script-validated but retains platform abstraction guards that the literal AC wording prohibits.

**Checklist items marked complete without real test coverage**:
- AC-4, AC-6: Tests exist but only verify "does not crash" (REQUIRE_NOTHROW). They do not verify functional output (e.g., that WriteSoundCardInfo actually enumerates devices). This is acceptable for infrastructure story tests in headless CI environments where audio/GL contexts are unavailable.
- AC-7, AC-9, AC-10: Verified by code inspection and build, not by dedicated tests. Appropriate for deletion/removal criteria.

---

## Summary

| Severity | Count | Status |
|----------|-------|--------|
| BLOCKER | 0 | — |
| HIGH | 1 | Noted (Finding 1: GetSystemInfo name collision) |
| MEDIUM | 3 | Noted (Findings 2-4) |
| LOW | 3 | Noted (Findings 5-7) |
| **Total** | **7** | **0 blockers, 7 noted** |

**No BLOCKER findings.** The 2 prior BLOCKERs (test logic error, integer overflow) have been verified as fixed in the current code.

**HIGH finding** (1): `GetSystemInfo` Win32 API name collision — real risk on Windows builds, should be renamed before merge.

**MEDIUM findings** (2-4): `substr` bounds safety, MinGW diagnostic gaps, unnecessary `#ifdef _WIN32` in HexWrite.

**LOW findings** (5-7): Cosmetic naming, forward declaration duplication, unchecked return value.

**Quality Gate**: PASSED — story is clear to proceed to code-review-analysis.
