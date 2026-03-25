# Story 7.6.7: ErrorReport Cross-Platform Crash Diagnostics

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.6 - macOS Native Build Compilation |
| Story ID | 7.6.7 |
| Story Points | 8 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-WIN32CLEAN-ERRDIAG |
| FRs Covered | Cross-platform parity — zero `#ifdef _WIN32` in game logic; crash diagnostics on all platforms |
| Prerequisites | 7-1-1-crossplatform-error-reporting (done), 7-1-2-posix-signal-handlers (done), 7-6-1-macos-native-build-compilation (in-progress) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Replace 522-line Win32 diagnostic block (lines 285–807) in `Core/ErrorReport.cpp` with cross-platform equivalents for system info, OpenGL info, IME info, crash dump, and DirectSound enumeration |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer building the game client on macOS/Linux,
**I want** `Core/ErrorReport.cpp`'s Win32-only diagnostic methods to have cross-platform implementations,
**so that** crash reports include meaningful system information on all platforms, not just on Windows.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `python3 MuMain/scripts/check-win32-guards.py` exits 0 — no violations in `Core/ErrorReport.cpp`.
- [ ] **AC-2:** The `#ifdef _WIN32` block spanning lines 285–807 is replaced with a proper `#ifdef _WIN32 ... #else ... #endif` structure where the `#else` branch contains real cross-platform implementations (not empty stubs).
- [ ] **AC-3:** `CErrorReport::WriteSystemInfo(ER_SystemInfo* si)` — on macOS/Linux, `si` is populated via:
  - OS name: `uname(&u)` → `u.sysname` / `u.release`
  - CPU info: `sysctl hw.model` (macOS) or `/proc/cpuinfo` (Linux)
  - RAM: `sysctl hw.memsize` (macOS) or `/proc/meminfo` (Linux)
  - DirectX version field: set to `L"N/A (SDL3 GPU backend)"` on non-Windows
- [ ] **AC-4:** `CErrorReport::WriteOpenGLInfo()` — already uses OpenGL (`glGetString`), which is cross-platform; the `#ifdef _WIN32` guard around this method is removed; it compiles and runs on all platforms.
- [ ] **AC-5:** `CErrorReport::WriteImeInfo(HWND hWnd)` — on macOS/Linux, writes `L"<IME information>\r\nN/A (SDL3 text input — platform IME not accessible)\r\n"` to the log; `HIMC`, `HKL`, and Win32 IMM32 APIs are not used outside Windows.
- [ ] **AC-6:** The DirectSound device enumeration subsystem (lines ~360–500 in the current Win32 block) is replaced by a macOS/Linux stub that writes `L"<Audio devices>\r\nN/A (miniaudio backend — see audio log)\r\n"` — DirectSound does not exist on non-Windows; miniaudio handles audio device selection.
- [ ] **AC-7:** The crash dump / SEH (`SetUnhandledExceptionFilter`, `MiniDumpWriteDump`) subsystem in the Win32 block — the POSIX equivalent (`SIGSEGV`/`SIGABRT` signal handlers) was implemented in story 7-1-2. Add a call to the POSIX signal handler registration from the `#else` branch of the relevant Init function; do not duplicate the signal handler logic.
- [ ] **AC-8:** `ER_SystemInfo` struct in `ErrorReport.h` — Win32-specific fields (`m_lpszDxVersion`) remain but are documented as "N/A on non-Windows"; no `#ifdef _WIN32` required in the struct definition (fields are always present, just set to "N/A" strings).
- [ ] **AC-9:** `./ctl check` passes — build + format-check + lint all green.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — no `#ifdef _WIN32` wrapping any function body in `ErrorReport.cpp`; POSIX includes (`<sys/utsname.h>`, `<sys/sysctl.h>`) used on non-Windows; clang-format clean.
- [ ] **AC-STD-2:** Tests — Catch2 test in `tests/core/test_error_report.cpp`: `TEST_CASE("WriteSystemInfo populates OS and CPU fields")` — call `WriteSystemInfo` and verify `m_lpszOS` and `m_lpszCPU` are non-empty strings.
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [ ] **Task 1: Audit ErrorReport.cpp Win32 block** (prerequisite)
  - [ ] 1.1: Read lines 285–807 completely; catalogue every Win32 API, type, and constant used
  - [ ] 1.2: Group into: system-info collection, OpenGL info, IME info, DirectSound enumeration, crash dump / SEH, OS version detection
  - [ ] 1.3: Identify which groups have direct POSIX equivalents vs. which require stubs

- [ ] **Task 2: WriteOpenGLInfo — remove guard** (AC-4)
  - [ ] 2.1: `WriteOpenGLInfo` uses only `glGetString` and `glGetIntegerv` — pure OpenGL, fully cross-platform
  - [ ] 2.2: Move it outside the `#ifdef _WIN32` block (or place it in the `#else` branch identical to the Win32 version)
  - [ ] 2.3: Verify it compiles on macOS/Linux (requires `<GL/gl.h>` or `<OpenGL/gl.h>` — already handled by `PlatformCompat.h` / `stdafx.h`)

- [ ] **Task 3: WriteSystemInfo — POSIX implementation** (AC-3)
  - [ ] 3.1: Add `mu_get_system_info(ER_SystemInfo* si)` to `PlatformCompat.h` non-Windows section:
    - `uname(&u)` → `si->m_lpszOS = ... (u.sysname + " " + u.release)`
    - `sysctl / /proc/cpuinfo` → `si->m_lpszCPU`
    - `sysctl hw.memsize / /proc/meminfo MemTotal` → `si->m_iMemorySize`
    - `si->m_lpszDxVersion = L"N/A (SDL3 GPU backend)"`
  - [ ] 3.2: In `WriteSystemInfo` `#else` branch: call `mu_get_system_info(si)` then call `Write(...)` with the populated fields

- [ ] **Task 4: WriteImeInfo — POSIX stub** (AC-5)
  - [ ] 4.1: In `WriteImeInfo` `#else` branch: `Write(L"<IME information>\r\nN/A (SDL3 text input)\r\n")`
  - [ ] 4.2: `HWND hWnd` parameter is unused on non-Windows; mark `[[maybe_unused]]` or cast to void

- [ ] **Task 5: DirectSound enumeration — audio stub** (AC-6)
  - [ ] 5.1: Identify the `DSoundEnumCallback` and `WriteSoundInfo` functions in the Win32 block (~lines 360–500)
  - [ ] 5.2: In the `#else` branch: `Write(L"<Audio devices>\r\nN/A (miniaudio backend)\r\n")`
  - [ ] 5.3: `DSoundEnumCallback` is a Win32 callback type; keep it inside `#ifdef _WIN32` only

- [ ] **Task 6: Crash dump / SEH — delegate to POSIX signal handlers** (AC-7)
  - [ ] 6.1: Identify `SetUnhandledExceptionFilter`, `MiniDumpWriteDump` usage in the Win32 block
  - [ ] 6.2: In the `#else` branch of the Init function (e.g. `CErrorReport::Init()`): call `mu::platform::RegisterCrashHandlers()` — implemented in `Platform/posix/PosixSignalHandlers.cpp` (story 7-1-2)
  - [ ] 6.3: Do NOT duplicate the signal handler logic; just call the registration function

- [ ] **Task 7: Replace #ifdef _WIN32 block with #ifdef / #else / #endif** (AC-2)
  - [ ] 7.1: The current structure is `#ifdef _WIN32 [522 lines] #endif // _WIN32` with no `#else`
  - [ ] 7.2: After implementing all POSIX equivalents, restructure as:
    ```
    #ifdef _WIN32
    [Windows implementations — unchanged]
    #else // !_WIN32
    [POSIX implementations from Tasks 2–6]
    #endif // _WIN32
    ```

- [ ] **Task 8: Unit test** (AC-STD-2)
  - [ ] 8.1: Create `tests/core/test_error_report.cpp` (or extend existing if present)
  - [ ] 8.2: `TEST_CASE("WriteSystemInfo populates fields on non-Windows")` — create an `ER_SystemInfo`, call `mu_get_system_info`, verify `m_lpszOS` is non-empty

- [ ] **Task 9: Validate** (AC-1, AC-9)
  - [ ] 9.1: Run `python3 MuMain/scripts/check-win32-guards.py` — zero violations in `Core/ErrorReport.cpp`
  - [ ] 9.2: Run `./ctl check` — exits 0

---

## Error Codes Introduced

None — infrastructure story.

---

## Contract Catalog Entries

None — no API, event, or navigation contracts.

---

## Dev Notes

### Critical Rule (from project-context.md)

**NO `#ifdef _WIN32` wrapping function bodies.** The 522-line Win32 block must be restructured with a proper `#else` branch containing real POSIX implementations, not empty stubs.

### Platform System Info APIs

| Data | Windows | macOS | Linux |
|---|---|---|---|
| OS name | `GetVersionExW` / `RtlGetVersion` | `uname(&u)` → `u.sysname` | `uname(&u)` → `u.sysname` |
| OS release | same | `u.release` | `u.release` |
| CPU model | `HKEY HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0` | `sysctlbyname("machdep.cpu.brand_string", ...)` | `/proc/cpuinfo` → `model name` |
| RAM bytes | `GlobalMemoryStatusEx` | `sysctlbyname("hw.memsize", ...)` | `/proc/meminfo` → `MemTotal` |

### Headers Required on Non-Windows

```cpp
#include <sys/utsname.h>   // uname
#include <sys/sysctl.h>    // sysctlbyname (macOS)
#include <sys/types.h>
```

### Relationship to Story 7-1-1 and 7-1-2

- **7-1-1** implemented cross-platform file logging (`MuError.log`) — this story uses that foundation
- **7-1-2** implemented POSIX crash signal handlers — this story delegates SEH crash dump to those handlers via `mu::platform::RegisterCrashHandlers()`
- This story completes the diagnostic picture: system info, OpenGL info, audio info on all platforms

### References

- [Source: _bmad-output/project-context.md#Prohibited Code Patterns]
- [Source: MuMain/src/source/Core/ErrorReport.h]
- [Source: MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp]
- [Source: _bmad-output/stories/7-1-2-posix-signal-handlers/story.md]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

### File List
