# ATDD Checklist: Story 7.6.7 — ErrorReport Cross-Platform Crash Diagnostics

**Story Key**: `7-6-7-error-report-cross-platform-diagnostics`
**Story Type**: infrastructure
**Flow Code**: VS0-QUAL-WIN32CLEAN-ERRDIAG
**Status**: RED (implementation pending)
**Generated**: 2026-03-25

---

## AC-to-Test Mapping

| AC | Description | Test / Verification Method | File | Status |
|----|-------------|---------------------------|------|--------|
| AC-1 | Python script exits 0 — no violations in ErrorReport.cpp | `python3 MuMain/scripts/check-win32-guards.py` | N/A — script | `[ ]` |
| AC-2 | Win32 block (lines 285–807) deleted | Build + grep: no `#ifdef _WIN32` in method bodies | N/A — code review | `[ ]` |
| AC-3 | WriteSystemInfo populates OS/CPU/RAM/GPU fields | `AC-3/AC-STD-2 [7-6-7]: WriteSystemInfo populates OS, CPU, and RAM fields` | `tests/core/test_error_report.cpp` | `[ ]` |
| AC-4 | WriteOpenGLInfo callable without `#ifdef _WIN32` guard | `AC-4 [7-6-7]: WriteOpenGLInfo callable on all platforms without crash` | `tests/core/test_error_report.cpp` | `[ ]` |
| AC-5 | WriteImeInfo signature changed to `WriteImeInfo(SDL_Window*)` | `AC-5 [7-6-7]: WriteImeInfo accepts SDL_Window* and does not crash` | `tests/core/test_error_report.cpp` | `[ ]` |
| AC-6 | WriteSoundCardInfo uses miniaudio — no DirectSound | `AC-6 [7-6-7]: WriteSoundCardInfo uses miniaudio and does not crash` | `tests/core/test_error_report.cpp` | `[ ]` |
| AC-7 | Win32-only functions deleted (`GetDXVersion`, `DSoundEnumCallback`, etc.) | Linker: no undefined symbols; grep: functions absent | N/A — build | `[ ]` |
| AC-8 | `m_lpszDxVersion` renamed to `m_lpszGpuBackend` in `ER_SystemInfo` | `AC-8 [7-6-7]: ER_SystemInfo has m_lpszGpuBackend field` (compile check) | `tests/core/test_error_report.cpp` | `[ ]` |
| AC-9 | `#else` empty stubs removed from ErrorReport.h | Compile on non-Windows with real method bodies | N/A — build | `[ ]` |
| AC-10 | All callers of WriteImeInfo updated to `SDL_Window*` | grep + build: no `HWND` passed to `WriteImeInfo` | N/A — code review + build | `[ ]` |
| AC-11 | `./ctl check` passes | `./ctl check` | N/A — quality gate | `[ ]` |
| AC-STD-1 | Zero `#ifdef _WIN32` in `ErrorReport.cpp` and `ErrorReport.h` | `python3 scripts/check-win32-guards.py` | N/A — script | `[ ]` |
| AC-STD-2 | Catch2 WriteSystemInfo test exists and passes | `AC-3/AC-STD-2 [7-6-7]: WriteSystemInfo populates OS, CPU, and RAM fields` | `tests/core/test_error_report.cpp` | `[ ]` |
| AC-STD-13 | Quality gate passes | `./ctl check` exits 0 | N/A — quality gate | `[ ]` |
| AC-STD-15 | Git safety | No force push, no incomplete rebase | N/A — git workflow | `[ ]` |

---

## RED Phase Failure Reasons

| Test | Why it fails in RED phase |
|------|--------------------------|
| AC-8 field check | **Compile error**: `m_lpszGpuBackend` does not exist — field still named `m_lpszDxVersion` |
| AC-3/AC-STD-2 WriteSystemInfo | **FAIL**: empty stub returns without populating any fields; all three REQUIRE assertions fail |
| AC-5 WriteImeInfo signature | **Compile error on Windows**: `HWND` and `SDL_Window*` are incompatible types; `static_cast<SDL_Window*>(nullptr)` rejected |
| AC-4 WriteOpenGLInfo | PASS (stub doesn't throw) — intent documented; real verification via `./ctl check` |
| AC-6 WriteSoundCardInfo | PASS (stub doesn't throw) — intent documented; real verification via `./ctl check` |

---

## Implementation Checklist

### Task Group 1: Delete Win32-only block and functions (AC-2, AC-7)

- [ ] 1.1: Delete `GetDXVersion()`, `GetOSVersion()` (Win32 variant), `GetCPUInfo()` (Win32 variant), `DSoundEnumCallback`, `ER_SOUNDDEVICEINFO`, `ER_SOUNDDEVICEENUMINFO` from `Core/ErrorReport.cpp`
- [ ] 1.2: Delete Win32-only includes: `<ddraw.h>`, `<dinput.h>`, `<dmusicc.h>`, `<eh.h>`, `<imagehlp.h>` and their `#ifdef _WIN32` guards
- [ ] 1.3: Remove the outer `#ifdef _WIN32 … #endif` block entirely (lines 285–807)

### Task Group 2: WriteOpenGLInfo — remove Win32 guard (AC-4)

- [ ] 2.1: Move `WriteOpenGLInfo()` body outside any `#ifdef _WIN32` block — implementation body unchanged; `glGetString`/`glGetIntegerv` are pure OpenGL

### Task Group 3: WriteSystemInfo — cross-platform implementation (AC-3, AC-8)

- [ ] 3.1: Rename `ER_SystemInfo.m_lpszDxVersion` → `m_lpszGpuBackend` in `Core/ErrorReport.h`; update all callers
- [ ] 3.2: Implement OS detection using `uname(&u)` → `swprintf(si->m_lpszOS, L"%hs %hs", u.sysname, u.release)`
- [ ] 3.3: Implement CPU detection: `sysctlbyname("machdep.cpu.brand_string", …)` on macOS / `/proc/cpuinfo` `model name` on Linux
- [ ] 3.4: Implement RAM detection: `sysctlbyname("hw.memsize", …)` on macOS / `/proc/meminfo` `MemTotal` on Linux
- [ ] 3.5: Populate `si->m_lpszGpuBackend` via `MuRenderer::GetGPUDriverName()` (exposes `SDL_GetGPUDeviceDriver(s_device)` from `MuRendererSDLGpu.cpp`)
- [ ] 3.6: Add unconditional includes to `ErrorReport.cpp`: `<sys/utsname.h>`, `<sys/sysctl.h>` (with `#ifdef __APPLE__` inline guard — not a `_WIN32` guard), `<fstream>` for `/proc` reads

### Task Group 4: WriteImeInfo — SDL3 implementation (AC-5, AC-10)

- [ ] 4.1: Change signature in `Core/ErrorReport.h`: `void WriteImeInfo(SDL_Window* pWindow)`
- [ ] 4.2: Change implementation in `Core/ErrorReport.cpp`: `void CErrorReport::WriteImeInfo(SDL_Window* pWindow)`
- [ ] 4.3: Implement using `SDL_TextInputActive(pWindow)` — write active/inactive state and SDL version string to the log
- [ ] 4.4: Update all call sites to pass `SDL_Window*` instead of `HWND`

### Task Group 5: WriteSoundCardInfo — miniaudio implementation (AC-6)

- [ ] 5.1: Declare `std::vector<std::string> GetAudioDeviceNames()` in `Platform/MiniAudio/MiniAudioBackend.h` under `namespace mu`
- [ ] 5.2: Define `mu::GetAudioDeviceNames()` in `Platform/MiniAudio/MiniAudioBackend.cpp` using `ma_context_init` + `ma_context_get_devices` + `ma_context_uninit`
- [ ] 5.3: Implement `WriteSoundCardInfo()` in `ErrorReport.cpp` using `mu::GetAudioDeviceNames()` — no `#include "miniaudio.h"` in `ErrorReport.cpp`

### Task Group 6: Clean up ErrorReport.h stubs (AC-9)

- [ ] 6.1: Remove `#ifdef _WIN32` / `#else` / `#endif` guard around the four method declarations
- [ ] 6.2: Remove the four empty `#else` stub implementations
- [ ] 6.3: Remove the Win32-only `GetSystemInfo(ER_SystemInfo*)` free function declaration (lines 88–95 of current header); superseded by `WriteSystemInfo` cross-platform implementation

### Task Group 7: Unit tests — ATDD RED phase (AC-STD-2)

- [x] 7.1: Add 7-6-7 test block to `MuMain/tests/core/test_error_report.cpp`
- [ ] 7.2: Verify `AC-3/AC-STD-2 [7-6-7]: WriteSystemInfo populates OS, CPU, and RAM fields` passes in GREEN phase
- [ ] 7.3: Verify `AC-8 [7-6-7]: ER_SystemInfo has m_lpszGpuBackend field` compiles and passes in GREEN phase
- [ ] 7.4: Verify `AC-5 [7-6-7]: WriteImeInfo accepts SDL_Window* and does not crash` compiles and passes in GREEN phase

### Task Group 8: Validate (AC-1, AC-11)

- [ ] 8.1: Run `python3 MuMain/scripts/check-win32-guards.py` — zero violations in `Core/ErrorReport.cpp`
- [ ] 8.2: Run `./ctl check` — format-check + cppcheck exits 0

---

## PCC Compliance

| Check | Status | Notes |
|-------|--------|-------|
| No prohibited libraries | `[x]` | Catch2 only — no gtest, no Boost.Test |
| Required testing patterns | `[x]` | `TEST_CASE`/`REQUIRE`/`CHECK`/`REQUIRE_NOTHROW` — Catch2 macros |
| No `#ifdef _WIN32` in test code | `[x]` | Tests use portable APIs (`SDL_Window*`, `ER_SystemInfo`) |
| AC-N: prefix on all test names | `[x]` | All tests tagged `[7-6-7]` with AC reference in name |
| Tests target pure logic (no Win32 dependency) | `[ ]` | Pending GREEN phase — tests call cross-platform APIs only |
| Quality gate `./ctl check` | `[ ]` | Passes after implementation complete |
| `implementation_checklist_complete` | `false` | 31 items remain unchecked |

---

## Test Files

| File | Phase | ACs Covered | New / Modified |
|------|-------|-------------|----------------|
| `MuMain/tests/core/test_error_report.cpp` | RED | AC-3, AC-4, AC-5, AC-6, AC-8, AC-STD-2 | Modified (appended 7-6-7 block) |

---

## Output Summary

- **Story ID**: `7-6-7-error-report-cross-platform-diagnostics`
- **Primary Test Level**: Unit (infrastructure story — no E2E, no Bruno)
- **Failing tests created**: 5 unit tests (RED phase — 3 compile errors, 2 behavioral)
- **Test file**: `MuMain/tests/core/test_error_report.cpp` (additions appended)
- **ATDD checklist**: `_bmad-output/stories/7-6-7-error-report-cross-platform-diagnostics/atdd.md`
- **`implementation_checklist_complete`**: `false` — all `[ ]` items ready for dev-story

## AC-to-Test Map (for downstream `dev-story` workflow)

```json
{
  "AC-3":     "AC-3/AC-STD-2 [7-6-7]: WriteSystemInfo populates OS, CPU, and RAM fields",
  "AC-STD-2": "AC-3/AC-STD-2 [7-6-7]: WriteSystemInfo populates OS, CPU, and RAM fields",
  "AC-4":     "AC-4 [7-6-7]: WriteOpenGLInfo callable on all platforms without crash",
  "AC-5":     "AC-5 [7-6-7]: WriteImeInfo accepts SDL_Window* and does not crash",
  "AC-6":     "AC-6 [7-6-7]: WriteSoundCardInfo uses miniaudio and does not crash",
  "AC-8":     "AC-8 [7-6-7]: ER_SystemInfo has m_lpszGpuBackend field"
}
```
