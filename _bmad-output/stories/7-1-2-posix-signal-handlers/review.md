# Code Review — Story 7.1.2: POSIX Signal Handlers for Crash Diagnostics

**Story Key:** `7-1-2-posix-signal-handlers`
**Reviewer:** claude-sonnet-4-6 (adversarial code review)
**Date:** 2026-03-09
**Phase:** code-review-analysis

---

## Pipeline Status

| Step | Workflow | Status | Date |
|------|----------|--------|------|
| Step 1 | code-review-quality-gate | PASSED | 2026-03-08 |
| Step 2 | code-review-analysis | COMPLETE | 2026-03-09 |
| Step 3 | code-review-finalize | pending | — |

---

## Quality Gate Results

| Check | Result |
|-------|--------|
| clang-format | PASS (0 violations) |
| cppcheck | PASS (0 violations, 699/699 files) |
| Signal code isolation | PASS (`sigaction`/`signal(` only in `Platform/posix/`) |
| Post-fix quality gate | PASS (re-verified after all fixes from prior review) |

---

## Step 2: Analysis Results

**Completed:** 2026-03-09
**Status:** COMPLETE — 4 issues found (0 BLOCKER, 0 CRITICAL, 1 HIGH, 3 MEDIUM, 1 LOW)

### Severity Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 0 |
| CRITICAL | 0 |
| HIGH | 1 |
| MEDIUM | 3 |
| LOW | 1 |

---

### ATDD Audit

| Metric | Value |
|--------|-------|
| Total ATDD items | 19 |
| GREEN [x] | 18 |
| RED [ ] | 1 |
| Coverage | 94.7% |

**RED item:** AC-VAL-1 — intentional null-deref manual crash test. Explicitly documented as non-automatable (handler calls `_exit()`). This is an **accepted gap**, not a blocker.

---

### AC Validation Results

**Total ACs:** 18 (5 functional + 8 standard + 2 NFR + 3 validation)
**Implemented:** 17
**Not Implemented:** 0
**Deferred:** 0 (AC-VAL-1 is manual — documented as accepted)
**BLOCKERS:** 0
**Pass Rate:** 100% (automated); AC-VAL-1 marked as accepted manual gap

All functional ACs (AC-1 through AC-5), all standard ACs (AC-STD-1 through AC-STD-20), and both NFR ACs are implemented. AC-VAL-1 is acknowledged as manual-only in the story and ATDD.

---

### Issue 1 [HIGH]: Double-install corrupts `s_old*` chain — recursive CrashHandler on signal delivery

**Index:** H-1
**Category:** CODE-QUALITY
**File:** `MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp:128-130`
**Status:** pending

**Description:**
`InstallSignalHandlers()` has no guard against being called twice. On the first call, `sigaction(SIGSEGV, &act, &s_oldSIGSEGV)` correctly captures the previous handler (e.g., .NET AOT's) into `s_oldSIGSEGV`. On a second call, `sigaction(SIGSEGV, &act, &s_oldSIGSEGV)` overwrites `s_oldSIGSEGV` with the entry that was current at that moment — which is `CrashHandler` itself (installed by the first call).

When a signal fires after double-install, `CrashHandler` executes the chain:
```cpp
if ((oldact->sa_flags & SA_SIGACTION) != 0 && oldact->sa_sigaction != nullptr)
    oldact->sa_sigaction(signum, info, context);  // calls CrashHandler again
```
`s_oldSIGSEGV.sa_sigaction` now points to `CrashHandler`, so this is a recursive call. SA_RESETHAND has reset the signal to SIG_DFL before the handler runs, but the static `s_old*` still holds the CrashHandler pointer — the recursion continues until stack overflow.

`MuPlatform::Initialize()` only calls `InstallSignalHandlers()` once, so this is not triggered in production. However, the idempotency test (`AC-STD-NFR-2`) calls it twice, creating a latent bug that any future caller could hit.

**Fix:** Guard against double-install by checking whether current handlers already point to `CrashHandler`, OR add a `static bool s_installed = false` guard:
```cpp
void InstallSignalHandlers()
{
    static bool s_installed = false;
    if (s_installed) return;
    s_installed = true;
    // ... existing code
}
```
Alternatively, note in the header comment that double-install is unsafe and remove the idempotency claim from the header comment (line 19: "Safe to call multiple times").

---

### Issue 2 [MEDIUM]: `SA_SIGACTION`/`SA_RESETHAND` fallback defines use Linux-specific values

**Index:** M-1
**Category:** CODE-QUALITY / CROSS-PLATFORM
**File:** `MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp:16-21`
**Status:** pending

**Description:**
```cpp
#ifndef SA_SIGACTION
#define SA_SIGACTION 0x0040
#endif
#ifndef SA_RESETHAND
#define SA_RESETHAND 0x0004
#endif
```
These fallback defines are dead code on any conforming POSIX system (`<csignal>` / `<signal.h>` always defines them). However, if they were ever triggered (e.g., on a minimal embedded POSIX target), the values are Linux-specific. On macOS, `SA_RESETHAND` is `0x80000000` (not `0x0004`). Using the wrong value would silently fail to set SA_RESETHAND, meaning the handler would NOT reset to SIG_DFL after first invocation — violating AC-3's re-entrant crash prevention.

**Fix:** Remove the fallback defines entirely (they are dead code on all supported targets — macOS and Linux glibc both define these). If keeping them for documentation purposes, add a `static_assert` that the hardcoded value matches the system value:
```cpp
// Remove these lines — SA_SIGACTION and SA_RESETHAND are defined by <csignal> on all POSIX targets
```

---

### Issue 3 [MEDIUM]: `sigemptyset()` not called — POSIX requires explicit `sa_mask` initialization

**Index:** M-2
**Category:** CODE-QUALITY
**File:** `MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp:122`
**Status:** pending

**Description:**
```cpp
struct sigaction act = {};
```
Value-initialization (`= {}`) sets `act.sa_mask` to all-bits-zero. POSIX specifies `sigset_t` as an opaque type — it is not guaranteed that all-zeros represents an empty signal set. The correct POSIX idiom is:
```cpp
struct sigaction act = {};
sigemptyset(&act.sa_mask);
```
On Linux (where `sigset_t` is `unsigned long[16]` or similar) and macOS (where it is a 32-bit unsigned int), all-zeros happens to be the empty set. But this is implementation-defined, and the code implicitly depends on it. POSIX compliance requires the explicit `sigemptyset()` call.

**Fix:** Add `sigemptyset(&act.sa_mask);` after `struct sigaction act = {};`.

---

### Issue 4 [MEDIUM]: `backtrace()` is not POSIX async-signal-safe — acknowledged risk not documented as a code comment

**Index:** M-3
**Category:** CODE-QUALITY / NFR
**File:** `MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp:88-100`
**Status:** pending

**Description:**
AC-STD-NFR-1 and the header comment claim only async-signal-safe functions are used. `backtrace()` and `backtrace_symbols_fd()` are NOT in the POSIX list of async-signal-safe functions (POSIX.1-2008 §2.4.3). On macOS, `backtrace()` internally acquires a lock via `_dyld_find_unwind_sections()`. If the crash signal interrupts code holding that lock, `backtrace()` in the signal handler will deadlock instead of producing a backtrace.

This is an accepted platform-specific pragmatism (glibc documents `backtrace()` as signal-safe; macOS's behavior varies by OS version). The story Dev Notes explicitly acknowledge this. However, there is no inline code comment explaining why this known-unsafe call is acceptable here, creating confusion for future maintainers reading the "only async-signal-safe functions" comment at the top.

**Fix:** Add an inline comment above the `#ifdef MU_HAS_BACKTRACE` block:
```cpp
// NOTE: backtrace()/backtrace_symbols_fd() are not strictly POSIX async-signal-safe,
// but are documented as signal-safe by glibc and work in practice on macOS.
// Risk: may deadlock on macOS if crash occurs inside dyld lock. Accepted trade-off
// for diagnostic value. (Story 7.1.2 Dev Notes §Async-Signal-Safety)
```

---

### Issue 5 [LOW]: `nameLen` computed via runtime loop — contradicts story dev notes recommendation

**Index:** L-1
**Category:** CODE-QUALITY
**File:** `MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp:58-67`
**Status:** pending

**Description:**
The code computes signal name length via a runtime `while (*p != '\0')` loop. The story's own Dev Notes (§Signal Handler Implementation Pattern) explicitly recommends using `sizeof("SIGSEGV") - 1` to compute lengths as compile-time constants, avoiding any potential ambiguity. While `strlen()` is async-signal-safe per POSIX 2008, a runtime loop in a signal handler is unnecessary overhead and less readable than compile-time constants.

**Fix:** Replace the name-length loop with a helper or direct `sizeof`:
```cpp
int nameLen = (signum == SIGABRT) ? 6 : 7;  // "SIGABRT"=6, "SIGSEGV"/"SIGBUS "=7/6
// Or use a lookup table with precomputed lengths
```

---

## Verified Aspects (No Issues Found)

| Aspect | Verdict | Notes |
|--------|---------|-------|
| Async-signal-safety core path (AC-STD-NFR-1) | PASS | `write()`, `_exit()` are strictly safe; `backtrace()` is accepted risk (M-3 flagged) |
| SA_RESETHAND prevents re-entry (AC-3) | PASS | Flag properly set (when system defines it correctly — M-1 flagged) |
| `g_errorReportFd` lifecycle | PASS | Correctly opened in `Create()` via `open(O_WRONLY|O_APPEND)`, closed in `Destroy()` with proper ordering (set -1 before close) |
| Handler chaining (AC-STD-NFR-2 R8 mitigation) | PASS | Chaining logic correct for single-install scenario |
| PLAT: prefix (AC-STD-5) | PASS | Install-time log uses correct prefix |
| Cross-platform isolation (AC-5) | PASS | Signal code only in `Platform/posix/`; `#ifndef _WIN32` guard in `MuPlatform.cpp` |
| `#pragma once` in headers | PASS | PosixSignalHandlers.h has `#pragma once` |
| Namespace (mu::platform) | PASS | Both header and implementation use `mu::platform` namespace |
| Flow code traceability (AC-STD-11) | PASS | `[VS0-QUAL-SIGNAL-HANDLERS]` in implementation, header, and MuPlatform.cpp |
| CMake registration | PASS | Added to `MUPlatform` in `if(NOT WIN32)` block (src/CMakeLists.txt:311); test registered via `target_sources(MuTests)` (tests/CMakeLists.txt:67) |
| `_exit(1)` not `exit()` | PASS | Correct — no atexit deadlock risk |
| backtrace guard | PASS | `MU_HAS_BACKTRACE` correctly guarded with `__APPLE__` or `__GLIBC__` |
| ErrorReport.h `g_errorReportFd` declaration | PASS | `extern volatile int g_errorReportFd` at line 64 |
| ErrorReport.cpp definition | PASS | Defined as `volatile int g_errorReportFd = -1` at line 37 |
| Test compile guard | PASS | `#ifndef _WIN32` wraps all test logic; Windows stub trivially passes |
| Test cleanup / handler restore | PASS | Old handlers saved before install, restored after test |

---

## Summary

| Severity | Count | Fixed |
|----------|-------|-------|
| BLOCKER | 0 | — |
| CRITICAL | 0 | — |
| HIGH | 1 | 0 |
| MEDIUM | 3 | 0 |
| LOW | 1 | 0 |

**No ACs are violated. Story can proceed to code-review-finalize after fixing H-1 (double-install chain-loop) and optionally addressing M-1 through M-3.**

---

**Next step:** `/bmad:pcc:workflows:code-review-finalize 7-1-2-posix-signal-handlers`

---

*Code review analysis completed 2026-03-09 by claude-sonnet-4-6*


---

## Code Review Analysis (Step 2)

**Date:** 2026-03-09 09:24
**Reviewer:** Claude (Adversarial Analysis)

💬 ## Code Review Analysis Complete — Story 7-1-2-posix-signal-handlers

**Quality Gate:** PASSED  
**ATDD:** 94.7% (18/19) — above the 80% threshold, 1 non-automatable manual test deferred

### Issues Found (5 total)

| # | Severity | Description | Location |
|---|----------|-------------|----------|
| **H-1** | HIGH | Double-install corrupts `s_old*` chain — `InstallSignalHandlers()` called twice causes recursive `CrashHandler` on signal delivery (stack overflow). Header comment falsely claims "safe to call multiple times" | `PosixSignalHandlers.cpp:128-130` |
| **M-1** | MEDIUM | `SA_SIGACTION`/`SA_RESETHAND` fallback `#define`s use Linux-specific numeric values — wrong on macOS | `PosixSignalHandlers.cpp:16-21` |
| **M-2** | MEDIUM | `sigemptyset()` not called — POSIX requires explicit `sa_mask` initialization before use | `PosixSignalHandlers.cpp:122` |
| **M-3** | MEDIUM | `backtrace()` is not async-signal-safe — accepted risk but undocumented in code | `PosixSignalHandlers.cpp:88-100` |
| **L-1** | LOW | `nameLen` computed via runtime loop instead of compile-time `sizeof()` | `PosixSignalHandlers.cpp:58-67` |

**Key finding (H-1):** The double-install bug is a real correctness issue — the idempotency guard is missing despite the header claiming otherwise. Fix: add a `static bool s_installed` guard.

**Review artifacts saved to:** `_bmad-output/stories/7-1-2-posix-signal-handlers/review.md`

**Next step:** Run `/bmad:pcc:workflows:code-review-finalize 7-1-2-posix-signal-handlers` to fix the issues and close the story.

📋 Result:
## Code Review Analysis Complete — Story 7-1-2-posix-signal-handlers

**Quality Gate:** PASSED  
**ATDD:** 94.7% (18/19) — above the 80% threshold, 1 non-automatable manual test deferred

### Issues Found (5 total)

| # | Severity | Description | Location |
|---|----------|-------------|----------|
| **H-1** | HIGH | Double-install corrupts `s_old*` chain — `InstallSignalHandlers()` called twice causes recursive `CrashHandler` on signal delivery (stack overflow). Header comment falsely claims "safe to call multiple times" | `PosixSignalHandlers.cpp:128-130` |
| **M-1** | MEDIUM | `SA_SIGACTION`/`SA_RESETHAND` fallback `#define`s use Linux-specific numeric values — wrong on macOS | `PosixSignalHandlers.cpp:16-21` |
| **M-2** | MEDIUM | `sigemptyset()` not called — POSIX requires explicit `sa_mask` initialization before use | `PosixSignalHandlers.cpp:122` |
| **M-3** | MEDIUM | `backtrace()` is not async-signal-safe — accepted risk but undocumented in code | `PosixSignalHandlers.cpp:88-100` |
| **L-1** | LOW | `nameLen` computed via runtime loop instead of compile-time `sizeof()` | `PosixSignalHandlers.cpp:58-67` |

**Key finding (H-1):** The double-install bug is a real correctness issue — the idempotency guard is missing despite the header claiming otherwise. Fix: add a `static bool s_installed` guard.

**Review artifacts saved to:** `_bmad-output/stories/7-1-2-posix-signal-handlers/review.md`

**Next step:** Run `/bmad:pcc:workflows:code-review-finalize 7-1-2-posix-signal-handlers` to fix the issues and close the story.
