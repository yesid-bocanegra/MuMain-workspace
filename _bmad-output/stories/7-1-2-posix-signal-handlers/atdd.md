# ATDD Checklist — Story 7.1.2: POSIX Signal Handlers for Crash Diagnostics

**Story Key:** `7-1-2-posix-signal-handlers`
**Story Type:** `infrastructure`
**Flow Code:** `VS0-QUAL-SIGNAL-HANDLERS`
**Date:** 2026-03-08
**Phase:** RED — all items pending implementation

---

## AC-to-Test Mapping

| AC | Description | Test Method | Test File | Status |
|----|-------------|-------------|-----------|--------|
| AC-1 | SIGSEGV, SIGABRT, SIGBUS handlers installed at startup on macOS/Linux | `InstallSignalHandlers installs SA_SIGACTION for SIGSEGV/SIGABRT/SIGBUS` | `tests/platform/test_posix_signal_handlers.cpp` | [ ] |
| AC-2 | Handler writes signal type + backtrace to MuError.log | Manual validation (AC-VAL-1) — handler body calls `_exit()`, not safely unit-testable | N/A (manual) | [ ] |
| AC-3 | Handler calls `_exit(1)` — no re-entrant crash risk | `SA_RESETHAND flag set` SECTION in install test | `tests/platform/test_posix_signal_handlers.cpp` | [ ] |
| AC-4 | Existing Windows build is unchanged | MinGW CI build passes (AC-VAL-3) | CI build | [ ] |
| AC-5 | Signal handler code lives exclusively in `Platform/posix/` | `InstallSignalHandlers is in mu::platform namespace` test case | `tests/platform/test_posix_signal_handlers.cpp` | [ ] |
| AC-STD-1 | Code follows project-context.md standards | Verified by code review + quality gate | `./ctl check` | [ ] |
| AC-STD-2 | Catch2 test in `tests/platform/test_posix_signal_handlers.cpp` | `InstallSignalHandlers installs SA_SIGACTION for SIGSEGV/SIGABRT/SIGBUS` | `tests/platform/test_posix_signal_handlers.cpp` | [ ] |
| AC-STD-3 | Signal handler code only in `Platform/posix/` — verified by grep | grep audit (in atdd.md Step 3.5 below) | grep command | [ ] |
| AC-STD-4 | CI quality gate passes — `./ctl check` exits 0 | Quality gate run | `./ctl check` | [ ] |
| AC-STD-5 | Error logging uses `PLAT:` prefix | Code review of install-time log message in `InstallSignalHandlers()` | `PosixSignalHandlers.cpp` | [ ] |
| AC-STD-6 | Conventional commit `feat(platform): add POSIX signal handlers...` | Git log verification | git log | [ ] |
| AC-STD-11 | Flow code `VS0-QUAL-SIGNAL-HANDLERS` in implementation and commit | grep `VS0-QUAL-SIGNAL-HANDLERS` in PosixSignalHandlers.cpp | PosixSignalHandlers.cpp | [ ] |
| AC-STD-13 | Quality gate passes (duplicate of AC-STD-4) | `./ctl check` | `./ctl check` | [ ] |
| AC-STD-15 | Git safety — no incomplete rebase, no force push to main | Git status check | git status | [ ] |
| AC-STD-20 | Contract Reachability — no API/event/flow catalog entries | N/A (infrastructure — no API) | N/A | [x] |
| AC-STD-NFR-1 | Signal handler is async-signal-safe only | Code review — no malloc/printf/fwrite in handler body | `PosixSignalHandlers.cpp` | [ ] |
| AC-STD-NFR-2 | Signal handlers chained to previous handler | Code review of chaining logic in `CrashHandler` + idempotency test | `test_posix_signal_handlers.cpp` | [ ] |
| AC-VAL-1 | Intentional null deref → PLAT: message in MuError.log on macOS | Manual test (cannot be automated — `_exit()` path) | Manual | [ ] |
| AC-VAL-2 | `sigaction()` query confirms SA_SIGACTION flag — Catch2 GREEN | `InstallSignalHandlers installs SA_SIGACTION` test case GREEN | `test_posix_signal_handlers.cpp` | [ ] |
| AC-VAL-3 | MinGW CI build continues to pass | CI run (Windows stub test in test file) | CI | [ ] |

---

## Implementation Checklist

### Phase 1: Create Platform Header

- [ ] Create `MuMain/src/source/Platform/posix/PosixSignalHandlers.h`
- [ ] Header has `#pragma once`
- [ ] Entire header wrapped in `#ifndef _WIN32` / `#endif`
- [ ] Declares `namespace mu::platform` with `void InstallSignalHandlers()`
- [ ] Includes only `<csignal>` — no game logic headers

### Phase 2: Implement Signal Handler

- [ ] Create `MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp`
- [ ] First include is `#include "stdafx.h"` (PCH)
- [ ] Includes `#include "PosixSignalHandlers.h"`
- [ ] Includes POSIX headers: `<csignal>`, `<cstdlib>`, `<unistd.h>`
- [ ] `<execinfo.h>` conditionally included with `#if defined(__APPLE__) || defined(__GLIBC__)` guard + `#define MU_HAS_BACKTRACE 1`
- [ ] Declares `static struct sigaction s_oldSIGSEGV, s_oldSIGABRT, s_oldSIGBUS`
- [ ] `CrashHandler` function uses ONLY async-signal-safe operations: `write()`, `backtrace()`, `backtrace_symbols_fd()`, `_exit()`
- [ ] `CrashHandler` writes signal name to `STDERR_FILENO` via `write()` (fixed strings, no malloc)
- [ ] `CrashHandler` conditionally writes backtrace via `backtrace_symbols_fd()` when `MU_HAS_BACKTRACE` defined
- [ ] `CrashHandler` chains to old handler (checks `sa_sigaction != nullptr` or handler != `SIG_DFL`/`SIG_IGN`)
- [ ] `CrashHandler` calls `_exit(1)` — NOT `exit(1)`
- [ ] `InstallSignalHandlers()` sets `act.sa_sigaction = CrashHandler`
- [ ] `InstallSignalHandlers()` sets `act.sa_flags = SA_SIGACTION | SA_RESETHAND`
- [ ] `InstallSignalHandlers()` calls `sigaction()` for SIGSEGV, SIGABRT, SIGBUS, saving old handlers
- [ ] `InstallSignalHandlers()` logs via `g_ErrorReport.Write()` at install time: `PLAT: signal handler — installed for SIGSEGV, SIGABRT, SIGBUS\r\n`
- [ ] Flow code comment `// [VS0-QUAL-SIGNAL-HANDLERS]` present in file

### Phase 3: Integrate into MuPlatform

- [ ] `MuMain/src/source/Platform/MuPlatform.cpp` includes `PosixSignalHandlers.h` inside `#ifndef _WIN32` guard
- [ ] `MuPlatform::Initialize()` calls `mu::platform::InstallSignalHandlers()` inside `#ifndef _WIN32` guard after SDL_Init (or directly if no SDL_Init in non-SDL path)
- [ ] Verified: no `#ifdef _WIN32` added to game logic (guard is only in platform abstraction layer `MuPlatform.cpp`)

### Phase 4: CMake Registration

- [ ] `MuMain/src/CMakeLists.txt` adds `PosixSignalHandlers.cpp` to `MUPlatform` target inside `if(NOT WIN32)` block
- [ ] Verified: MinGW build excludes `Platform/posix/PosixSignalHandlers.cpp` (Windows cross-compile `_WIN32` defined)

### Phase 5: Test Registration

- [ ] `MuMain/tests/platform/test_posix_signal_handlers.cpp` exists (RED PHASE — created by ATDD)
- [ ] `MuMain/tests/CMakeLists.txt` adds `target_sources(MuTests PRIVATE platform/test_posix_signal_handlers.cpp)`

### Phase 6: Quality Gate and Validation

- [ ] `./ctl check` passes — clang-format check: zero violations
- [ ] `./ctl check` passes — cppcheck: zero violations (add `// cppcheck-suppress` with rationale if async-signal-safe functions flagged)
- [ ] `grep -r "sigaction\|signal(" MuMain/src/source/ --include="*.cpp" --include="*.h"` shows hits ONLY in `Platform/posix/` files
- [ ] `grep -r "VS0-QUAL-SIGNAL-HANDLERS" MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp` returns a match
- [ ] Conventional commit: `feat(platform): add POSIX signal handlers for crash diagnostics [VS0-QUAL-SIGNAL-HANDLERS]`

### PCC Compliance

- [ ] No prohibited libraries used (project-context.md §Prohibited Patterns)
- [ ] No `malloc`/`printf`/C++ streams inside the signal handler body (async-signal-unsafe)
- [ ] No `#ifdef _WIN32` in game logic (`MuPlatform.cpp` is platform abstraction layer — guard there is accepted)
- [ ] `#pragma once` in all new headers
- [ ] `nullptr` used, not `NULL`
- [ ] `mu::platform` namespace for all new platform code
- [ ] `_exit(1)` called in handler, not `exit()` (no atexit deadlock risk)
- [ ] `SA_RESETHAND` flag set (prevents handler re-entry)
- [ ] Chaining to `.NET AOT` previous handler implemented (Risk R8 mitigation)
- [ ] `PLAT:` prefix used in install-time log message (Architecture Pattern 4)
- [ ] No new `SAFE_DELETE` / `SAFE_DELETE_ARRAY` — not applicable (stack-only storage)
- [ ] No generated files edited (`src/source/Dotnet/`)

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
