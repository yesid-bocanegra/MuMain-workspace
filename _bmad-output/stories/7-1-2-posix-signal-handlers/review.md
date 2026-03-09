# Code Review — Story 7.1.2: POSIX Signal Handlers for Crash Diagnostics

**Story Key:** `7-1-2-posix-signal-handlers`
**Reviewer:** claude-opus-4-6 (adversarial code review)
**Date:** 2026-03-08
**Phase:** code-review-finalize

---

## Quality Gate Results

| Check | Result |
|-------|--------|
| clang-format | PASS (0 violations) |
| cppcheck | PASS (0 violations, 699/699 files) |
| Signal code isolation | PASS (`sigaction`/`signal(` only in `Platform/posix/`) |
| Post-fix quality gate | PASS (re-verified after all fixes) |

---

## Review Findings

### Issue 1: CrashHandler chains to old handler with nullptr info/context [HIGH] — FIXED

**File:** `MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp:107`
**Severity:** HIGH — potential crash in chained handler
**AC Impact:** AC-STD-NFR-2 (signal handlers chained)

**Problem:** The `CrashHandler` function received `siginfo_t* info` and `void* context` from the kernel but the parameters were unnamed (`/*info*/`, `/*context*/`). When chaining to the previous handler, `nullptr` was passed instead of forwarding the original values. If the .NET AOT runtime's signal handler dereferences `info->si_addr` or reads `context` for stack unwinding, this would cause a secondary crash.

**Fix Applied:** Named the parameters and forwarded them to the chained handler:
```cpp
static void CrashHandler(int signum, siginfo_t* info, void* context)
// ...
oldact->sa_sigaction(signum, info, context);
```

**Status:** [x] FIXED

---

### Issue 2: Redundant `#include <signal.h>` in test file [LOW] — FIXED

**File:** `MuMain/tests/platform/test_posix_signal_handlers.cpp:16`
**Severity:** LOW — code cleanliness

**Problem:** Both `<csignal>` (C++ header) and `<signal.h>` (C header) were included. The C++ header is sufficient.

**Fix Applied:** Removed `#include <signal.h>`.

**Status:** [x] FIXED

---

### Issue 3: Redundant catch2 include in Windows stub branch [LOW] — FIXED

**File:** `MuMain/tests/platform/test_posix_signal_handlers.cpp:145`
**Severity:** LOW — code cleanliness

**Problem:** `#include <catch2/catch_test_macros.hpp>` appeared twice — once at line 11 (outside `#ifndef _WIN32` guard) and again at line 145 (inside `#else` Windows branch). The second was redundant.

**Fix Applied:** Removed the second `#include <catch2/catch_test_macros.hpp>`.

**Status:** [x] FIXED

---

## Verified Aspects (No Issues Found)

| Aspect | Verdict | Notes |
|--------|---------|-------|
| Async-signal-safety (AC-STD-NFR-1) | PASS | Only `write()`, `backtrace()`, `backtrace_symbols_fd()`, `_exit()` called in handler. No malloc/printf/fwrite/streams. |
| SA_RESETHAND prevents re-entry (AC-3) | PASS | Flag properly set in `InstallSignalHandlers()` |
| `g_errorReportFd` lifecycle | PASS | Correctly opened in `Create()`, closed in `Destroy()` with proper ordering (set -1 before close to prevent signal handler race) |
| Handler chaining (AC-STD-NFR-2) | PASS | Chaining logic correct; `info`/`context` now properly forwarded |
| PLAT: prefix (AC-STD-5) | PASS | Install-time log uses `PLAT: signal handler -- installed for SIGSEGV, SIGABRT, SIGBUS` |
| Cross-platform isolation (AC-5) | PASS | Signal code only in `Platform/posix/`; `#ifndef _WIN32` guard in `MuPlatform.cpp` |
| `#pragma once` in headers | PASS | PosixSignalHandlers.h has `#pragma once` |
| Namespace (mu::platform) | PASS | Both header and implementation use `mu::platform` namespace |
| Flow code traceability (AC-STD-11) | PASS | `[VS0-QUAL-SIGNAL-HANDLERS]` in implementation, header, and CMake comments |
| CMake registration | PASS | Added to `MUPlatform` in `else()` (non-WIN32) block; test registered via `target_sources(MuTests)` |
| `_exit(1)` not `exit()` | PASS | Correct — no atexit deadlock risk |
| backtrace guard | PASS | `MU_HAS_BACKTRACE` correctly guarded with `__APPLE__` or `__GLIBC__` |

---

## Summary

| Severity | Count | Fixed |
|----------|-------|-------|
| CRITICAL | 0 | — |
| HIGH | 1 | 1 |
| MEDIUM | 0 | — |
| LOW | 2 | 2 |

**All 3 issues resolved. Quality gate verified clean after fixes.**

---

*Code review completed 2026-03-08 by claude-opus-4-6*
*Fixes applied and quality gate re-verified*
