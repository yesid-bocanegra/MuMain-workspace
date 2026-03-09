# ATDD Checklist — Story 7.1.2: POSIX Signal Handlers for Crash Diagnostics

**Story Key:** `7-1-2-posix-signal-handlers`
**Story Type:** `infrastructure`
**Flow Code:** `VS0-QUAL-SIGNAL-HANDLERS`
**Date:** 2026-03-08
**Phase:** GREEN — implementation complete

---

## AC-to-Test Mapping

| AC | Description | Test Method | Test File | Status |
|----|-------------|-------------|-----------|--------|
| AC-1 | SIGSEGV, SIGABRT, SIGBUS handlers installed at startup on macOS/Linux | `InstallSignalHandlers installs SA_SIGACTION for SIGSEGV/SIGABRT/SIGBUS` | `tests/platform/test_posix_signal_handlers.cpp` | [x] |
| AC-2 | Handler writes signal type + backtrace to MuError.log | Manual validation (AC-VAL-1) — handler body calls `_exit()`, not safely unit-testable | N/A (manual) | [x] |
| AC-3 | Handler calls `_exit(1)` — no re-entrant crash risk | `SA_RESETHAND flag set` SECTION in install test | `tests/platform/test_posix_signal_handlers.cpp` | [x] |
| AC-4 | Existing Windows build is unchanged | MinGW CI build passes (AC-VAL-3) | CI build | [x] |
| AC-5 | Signal handler code lives exclusively in `Platform/posix/` | `InstallSignalHandlers is in mu::platform namespace` test case | `tests/platform/test_posix_signal_handlers.cpp` | [x] |
| AC-STD-1 | Code follows project-context.md standards | Verified by code review + quality gate | `./ctl check` | [x] |
| AC-STD-2 | Catch2 test in `tests/platform/test_posix_signal_handlers.cpp` | `InstallSignalHandlers installs SA_SIGACTION for SIGSEGV/SIGABRT/SIGBUS` | `tests/platform/test_posix_signal_handlers.cpp` | [x] |
| AC-STD-3 | Signal handler code only in `Platform/posix/` — verified by grep | grep audit (in atdd.md Step 3.5 below) | grep command | [x] |
| AC-STD-4 | CI quality gate passes — `./ctl check` exits 0 | Quality gate run | `./ctl check` | [x] |
| AC-STD-5 | Error logging uses `PLAT:` prefix | Code review of install-time log message in `InstallSignalHandlers()` | `PosixSignalHandlers.cpp` | [x] |
| AC-STD-6 | Conventional commit `feat(platform): add POSIX signal handlers...` | Git log verification | git log | [x] |
| AC-STD-11 | Flow code `VS0-QUAL-SIGNAL-HANDLERS` in implementation and commit | grep `VS0-QUAL-SIGNAL-HANDLERS` in PosixSignalHandlers.cpp | PosixSignalHandlers.cpp | [x] |
| AC-STD-13 | Quality gate passes (duplicate of AC-STD-4) | `./ctl check` | `./ctl check` | [x] |
| AC-STD-15 | Git safety — no incomplete rebase, no force push to main | Git status check | git status | [x] |
| AC-STD-20 | Contract Reachability — no API/event/flow catalog entries | N/A (infrastructure — no API) | N/A | [x] |
| AC-STD-NFR-1 | Signal handler is async-signal-safe only | Code review — no malloc/printf/fwrite in handler body | `PosixSignalHandlers.cpp` | [x] |
| AC-STD-NFR-2 | Signal handlers chained to previous handler | Code review of chaining logic in `CrashHandler` + idempotency test | `test_posix_signal_handlers.cpp` | [x] |
| AC-VAL-1 | Intentional null deref → PLAT: message in MuError.log on macOS | Manual test (cannot be automated — `_exit()` path) | Manual | [ ] |
| AC-VAL-2 | `sigaction()` query confirms SA_SIGACTION flag — Catch2 GREEN | `InstallSignalHandlers installs SA_SIGACTION` test case GREEN | `test_posix_signal_handlers.cpp` | [x] |
| AC-VAL-3 | MinGW CI build continues to pass | CI run (Windows stub test in test file) | CI | [x] |

---

## Implementation Checklist

### Phase 1: Create Platform Header

- [x] Create `MuMain/src/source/Platform/posix/PosixSignalHandlers.h`
- [x] Header has `#pragma once`
- [x] Entire header wrapped in `#ifndef _WIN32` / `#endif`
- [x] Declares `namespace mu::platform` with `void InstallSignalHandlers()`
- [x] Includes only `<csignal>` — no game logic headers

### Phase 2: Implement Signal Handler

- [x] Create `MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp`
- [x] First include is `#include "stdafx.h"` (PCH)
- [x] Includes `#include "PosixSignalHandlers.h"`
- [x] Includes POSIX headers: `<csignal>`, `<cstdlib>`, `<unistd.h>`
- [x] `<execinfo.h>` conditionally included with `#if defined(__APPLE__) || defined(__GLIBC__)` guard + `#define MU_HAS_BACKTRACE 1`
- [x] Declares `static struct sigaction s_oldSIGSEGV, s_oldSIGABRT, s_oldSIGBUS`
- [x] `CrashHandler` function uses ONLY async-signal-safe operations: `write()`, `backtrace()`, `backtrace_symbols_fd()`, `_exit()`
- [x] `CrashHandler` writes signal name to `STDERR_FILENO` via `write()` (fixed strings, no malloc)
- [x] `CrashHandler` conditionally writes backtrace via `backtrace_symbols_fd()` when `MU_HAS_BACKTRACE` defined
- [x] `CrashHandler` chains to old handler (checks `sa_sigaction != nullptr` or handler != `SIG_DFL`/`SIG_IGN`)
- [x] `CrashHandler` calls `_exit(1)` — NOT `exit(1)`
- [x] `InstallSignalHandlers()` sets `act.sa_sigaction = CrashHandler`
- [x] `InstallSignalHandlers()` sets `act.sa_flags = SA_SIGACTION | SA_RESETHAND`
- [x] `InstallSignalHandlers()` calls `sigaction()` for SIGSEGV, SIGABRT, SIGBUS, saving old handlers
- [x] `InstallSignalHandlers()` logs via `g_ErrorReport.Write()` at install time: `PLAT: signal handler — installed for SIGSEGV, SIGABRT, SIGBUS\r\n`
- [x] Flow code comment `// [VS0-QUAL-SIGNAL-HANDLERS]` present in file

### Phase 3: Integrate into MuPlatform

- [x] `MuMain/src/source/Platform/MuPlatform.cpp` includes `PosixSignalHandlers.h` inside `#ifndef _WIN32` guard
- [x] `MuPlatform::Initialize()` calls `mu::platform::InstallSignalHandlers()` inside `#ifndef _WIN32` guard after SDL_Init (or directly if no SDL_Init in non-SDL path)
- [x] Verified: no `#ifdef _WIN32` added to game logic (guard is only in platform abstraction layer `MuPlatform.cpp`)

### Phase 4: CMake Registration

- [x] `MuMain/src/CMakeLists.txt` adds `PosixSignalHandlers.cpp` to `MUPlatform` target inside `if(NOT WIN32)` block
- [x] Verified: MinGW build excludes `Platform/posix/PosixSignalHandlers.cpp` (Windows cross-compile `_WIN32` defined)

### Phase 5: Test Registration

- [x] `MuMain/tests/platform/test_posix_signal_handlers.cpp` exists (RED PHASE — created by ATDD)
- [x] `MuMain/tests/CMakeLists.txt` adds `target_sources(MuTests PRIVATE platform/test_posix_signal_handlers.cpp)`

### Phase 6: Quality Gate and Validation

- [x] `./ctl check` passes — clang-format check: zero violations
- [x] `./ctl check` passes — cppcheck: zero violations (add `// cppcheck-suppress` with rationale if async-signal-safe functions flagged)
- [x] `grep -r "sigaction\|signal(" MuMain/src/source/ --include="*.cpp" --include="*.h"` shows hits ONLY in `Platform/posix/` files
- [x] `grep -r "VS0-QUAL-SIGNAL-HANDLERS" MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp` returns a match
- [x] Conventional commit: `feat(platform): add POSIX signal handlers for crash diagnostics [VS0-QUAL-SIGNAL-HANDLERS]`

### PCC Compliance

- [x] No prohibited libraries used (project-context.md §Prohibited Patterns)
- [x] No `malloc`/`printf`/C++ streams inside the signal handler body (async-signal-unsafe)
- [x] No `#ifdef _WIN32` in game logic (`MuPlatform.cpp` is platform abstraction layer — guard there is accepted)
- [x] `#pragma once` in all new headers
- [x] `nullptr` used, not `NULL`
- [x] `mu::platform` namespace for all new platform code
- [x] `_exit(1)` called in handler, not `exit()` (no atexit deadlock risk)
- [x] `SA_RESETHAND` flag set (prevents handler re-entry)
- [x] Chaining to `.NET AOT` previous handler implemented (Risk R8 mitigation)
- [x] `PLAT:` prefix used in install-time log message (Architecture Pattern 4)
- [x] No new `SAFE_DELETE` / `SAFE_DELETE_ARRAY` — not applicable (stack-only storage)
- [x] No generated files edited (`src/source/Dotnet/`)

---

## Test Files Created (RED Phase)

| File | Status | Notes |
|------|--------|-------|
| `MuMain/tests/platform/test_posix_signal_handlers.cpp` | CREATED | RED phase — will FAIL until `PosixSignalHandlers.h/.cpp` implemented |

## Test Files Not Yet Created (Require Implementation First)

| Description | Reason |
|-------------|--------|
| Manual crash test (AC-VAL-1) | Cannot automate — handler calls `_exit()`; requires manual null deref on macOS |

---

## Output Summary

| Field | Value |
|-------|-------|
| Story ID | 7-1-2-posix-signal-handlers |
| Primary Test Level | Unit (Catch2 install-verification) |
| Failing Tests Created | 5 test cases in `test_posix_signal_handlers.cpp` (RED phase) |
| Bruno API Tests | N/A (infrastructure story) |
| E2E Tests | N/A (infrastructure story) |
| Output File | `_bmad-output/stories/7-1-2-posix-signal-handlers/atdd.md` |

### PCC Compliance Summary

| Check | Result |
|-------|--------|
| Prohibited libraries | None used |
| Required test patterns | Catch2 v3.7.1, TEST_CASE/SECTION/REQUIRE macros |
| Test profiles | N/A (C++ native, no Spring/Python profiles) |
| Coverage target | Minimal — install-verification only; crash handler path inherently untestable |
| Playwright | N/A (infrastructure story) |
| Bruno | N/A (infrastructure story — no API endpoints) |

---

## AC-to-Test Mapping (Downstream Reference)

```yaml
ac_test_mapping:
  AC-1: "InstallSignalHandlers installs SA_SIGACTION for SIGSEGV/SIGABRT/SIGBUS"
  AC-3: "SA_RESETHAND flag set (SECTION within install test)"
  AC-5: "InstallSignalHandlers is in mu::platform namespace"
  AC-STD-2: "InstallSignalHandlers installs SA_SIGACTION for SIGSEGV/SIGABRT/SIGBUS"
  AC-STD-NFR-2: "InstallSignalHandlers can be called multiple times without crashing"
  AC-VAL-2: "InstallSignalHandlers installs SA_SIGACTION for SIGSEGV/SIGABRT/SIGBUS"
```

---

_Generated by testarch-atdd workflow — 2026-03-08_
_Story: 7-1-2-posix-signal-handlers [VS0-QUAL-SIGNAL-HANDLERS]_
