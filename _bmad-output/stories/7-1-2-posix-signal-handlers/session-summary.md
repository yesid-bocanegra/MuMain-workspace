# Session Summary: Story 7-1-2-posix-signal-handlers

This file aggregates session summaries from multiple consolidation runs.
Each session section represents a consolidation of workflow logs.

---

## Session: 2026-03-09 09:48

**Log files analyzed:** 11

# Consolidated Analysis: Story 7-1-2-posix-signal-handlers Workflow Logs

## Issues Found

### Critical Quality Gap: Two Separate Code Reviews Discovered Different Issues

**First Code Review (2026-03-08 19:35):** 3 issues found
| Severity | Issue | Status |
|----------|-------|--------|
| HIGH | CrashHandler not forwarding `siginfo_t*` and `void* context` to chained handler | Fixed |
| LOW | Redundant `#include <signal.h>` (C++ `<csignal>` sufficient) | Fixed |
| LOW | Redundant `#include <catch2/catch_test_macros.hpp>` in Windows stub | Fixed |

**Second Code Review (2026-03-09 09:20):** 5 different issues discovered
| Severity | Issue | Location | Status |
|----------|-------|----------|--------|
| HIGH | Double-install bug: `InstallSignalHandlers()` called twice causes recursive `CrashHandler` on signal delivery (stack overflow). Header falsely claims "safe to call multiple times" | `PosixSignalHandlers.cpp:128-130` | Fixed |
| MEDIUM | `SA_SIGACTION`/`SA_RESETHAND` fallback `#define`s use Linux-specific numeric values—wrong on macOS | `PosixSignalHandlers.cpp:16-21` | Fixed |
| MEDIUM | `sigemptyset()` not called—POSIX requires explicit `sa_mask` initialization before use | `PosixSignalHandlers.cpp:122` | Fixed |
| MEDIUM | `backtrace()` is not async-signal-safe—accepted risk but undocumented in code | `PosixSignalHandlers.cpp:88-100` | Fixed |
| LOW | `nameLen` computed via runtime loop instead of compile-time `sizeof()` | `PosixSignalHandlers.cpp:58-67` | Fixed |

**Additional Gap:**
| Severity | Issue | Resolution |
|----------|-------|-----------|
| MEDIUM | AC-VAL-1 (manual crash test validation) cannot be automated | Accepted as non-automatable gap with documented rationale—signal handler calls `_exit(1)`, terminating process immediately, making verification impossible within test framework |

## Fixes Attempted

**First Review Fixes (2026-03-08):**
- ✅ Added `siginfo_t*` and `void* context` forwarding in `CrashHandler()` to chained handler
- ✅ Removed redundant C includes, using C++ standard library equivalents
- ✅ Re-ran quality gate, verified no regressions (0 violations, 699 files)
- ✅ Marked story `done`, synchronized sprint status

**Second Review Fixes (2026-03-09):**
- ✅ Added `static bool s_installed = false` guard in `InstallSignalHandlers()` to prevent double-install corruption
- ✅ Removed dead Linux-specific `SA_SIGACTION`/`SA_RESETHAND` `#define` fallbacks (would have silently disabled re-entry prevention on macOS)
- ✅ Added `sigemptyset(&act.sa_mask)` call per POSIX requirement for opaque `sigset_t`
- ✅ Added inline comment documenting `backtrace()`/`backtrace_symbols_fd()` are not strictly async-signal-safe but accepted as trade-off per story dev notes
- ✅ Replaced runtime `while (*p != '\0')` strlen loop with compile-time `sizeof("SIGBUS") - 1` expressions
- ✅ Re-ran quality gate, confirmed 0 violations (699 files checked)
- ✅ Updated story status and sprint-status.yaml, emitted metrics JSONL

**All fixes verified:** Quality gate PASSED after each fix cycle; final state: 0 violations across 699 files.

## Unresolved Blockers

None. All identified issues were fixed and verified.

**Accepted Non-Automatable Gaps:**
- AC-VAL-1 (manual crash test) cannot be automated because signal handler terminates process with `_exit(1)`
- Verified via alternative mechanisms: Catch2 install-verification test (AC-VAL-2) confirms `sigaction()` handlers are correctly installed; static analysis validates async-signal-safety constraints

## Key Decisions Made

1. **Double-install protection:** Added `static bool s_installed` guard to prevent recursive `CrashHandler` invocation on signal delivery
2. **POSIX compliance:** Removed platform-specific fallback `#define`s; now relies on standard headers (`<csignal>`) and explicit `sigemptyset()` initialization
3. **Async-signal-safety trade-off:** Documented in code that `backtrace()` / `backtrace_symbols_fd()` are used despite not being strictly async-signal-safe—accepted as practical compromise per story dev notes
4. **Handler chaining:** Preserve .NET AOT crash handling (R8 mitigation) by forwarding `siginfo_t*` and `void* context` to previous handler instead of `nullptr`
5. **Test automation scope:** Accept manual crash testing as non-automatable gap; document rationale (process termination via `_exit()` prevents verification in test framework)

## Lessons Learned

### What Went Wrong
- **Inadequate first code review:** Initial adversarial review (2026-03-08) found only shallow issues (include cleanup, parameter forwarding) and missed critical correctness bugs (double-install, platform-specific constants, POSIX compliance)
- **H-1 bug was real:** Double-install corrupts handler chain—not a theoretical issue but a genuine stack-overflow vulnerability if function called twice
- **Platform differences matter:** Linux-specific `SA_RESETHAND` value (0x80000000) differs on macOS; fallback `#define` would silently disable re-entry prevention on some platforms
- **POSIX compliance gaps:** Missing `sigemptyset()` call violates POSIX requirement for opaque `sigset_t` initialization

### What Worked Well
- **ATDD 100% coverage:** All 45 implementation checklist items were checked; comprehensive task structure caught most implementation details
- **Completeness gate rigor:** Verified 8/8 files exist with real code (no stubs/placeholders); caught phantom tasks early (0 phantoms found)
- **Quality gate infrastructure:** `./ctl check` consistently passed format and lint checks; provided reliable gate for code quality
- **Second review catch:** More thorough adversarial analysis on 2026-03-09 successfully identified deep correctness issues
- **Documented trade-offs:** When design constraints exist (backtrace not async-safe, AC-VAL-1 not automatable), documenting rationale prevents future confusion

## Recommendations for Reimplementation

### For This Story's Implementation
1. **Signal handler code requires dual-pass review:** First pass catches surface-level issues; second adversarial pass (focused on async-signal-safety, platform differences) is mandatory for correctness
2. **Platform-specific constants:** Always validate constants like `SA_SIGACTION` / `SA_RESETHAND` across Linux and macOS before use; don't rely on fallback `#define`s
3. **POSIX compliance checklist:** For signal handling, explicitly verify:
   - `sigemptyset()` called for all signal masks
   - Only async-signal-safe functions in handler (write, backtrace_symbols_fd, _exit—not malloc, printf, etc.)
   - Handler chaining preserves previous handler context (siginfo_t, void*)
   - Static guards prevent re-entry if function can be called multiple times
4. **Documenting trade-offs:** When accepting non-standard patterns (e.g., `backtrace()` not async-safe), document in code comment with rationale—prevents later developers from "fixing" intentional decisions

### Architecture & Design Patterns
1. **Use compile-time evaluation:** Replace runtime `strlen()` loops with `sizeof(string) - 1` for signal handler code (performance + clarity)
2. **Double-install protection pattern:** For one-time initialization functions used in signal handlers or early startup, use `static bool` guard:
   ```cpp
   static bool s_installed = false;
   if (s_installed) return;
   s_installed = true;
   ```
3. **Handler chaining:** Always forward `siginfo_t*` and `void* context` to previous handler to preserve signal context for higher-level handlers (.NET AOT, other interceptors)

### Code Review Process
1. **Adversarial review must include domain experts:** Signal handler code needs reviewer familiar with async-signal-safety constraints, platform differences, and POSIX requirements
2. **Create signal handler review checklist:** Before marking code-review complete, verify:
   - [ ] All functions in handler are in POSIX async-signal-safe list
   - [ ] Platform-specific constants validated on all target platforms (Linux, macOS)
   - [ ] `sigemptyset()` / `sigfillset()` used correctly for signal masks
   - [ ] Handler re-entry prevented if applicable
   - [ ] Previous handler context forwarded (siginfo_t, void*)
   - [ ] All design trade-offs documented in code comments
3. **Schedule second review if first review is shallow:** If initial adversarial review finds only cosmetic issues (includes, formatting), schedule additional focused review on domain-specific concerns

### Files Requiring Attention
- `MuMain/src/source/Platform/posix/PosixSignalHandlers.{h,cpp}` — high correctness sensitivity; async-signal-safety is non-trivial
- `MuMain/src/source/Core/ErrorReport.{h,cpp}` — manages `g_errorReportFd` lifecycle; ensure FD cleanup on shutdown
- `MuMain/tests/platform/test_posix_signal_handlers.cpp` — Catch2 test structure is sound; AC-VAL-1 (manual crash test) remains manually verified

### Patterns to Follow
- Use `#ifndef _WIN32` guards for POSIX-only code (signal handling, async I/O)
- Prefer C++ standard library (`<csignal>`) over C headers (`<signal.h>`)
- For infrastructure code: accept that some validations (crash diagnostics) cannot be fully automated; document gaps with clear rationale

### Patterns to Avoid
- ❌ Platform-specific fallback `#define`s for standard constants (rely on headers)
- ❌ Skipping `sigemptyset()` initialization (POSIX requires explicit initialization of opaque types)
- ❌ Using non-async-signal-safe functions without documenting the trade-off
- ❌ Calling one-time initialization functions without re-entry guards in multithreaded contexts
- ❌ Silent handler behavior—always document signal handling strategy and design decisions

*Generated by paw_runner consolidate using Haiku*
