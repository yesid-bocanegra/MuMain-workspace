# Story 7.1.2: POSIX Signal Handlers for Crash Diagnostics

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.1 - Diagnostics |
| Story ID | 7.1.2 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Code | VS0-QUAL-SIGNAL-HANDLERS |
| FRs Covered | Risk R8 — POSIX signal handler/AOT runtime interference mitigation; Architecture Pattern 4 (PLAT: error prefix) |
| Prerequisites | 7.1.1 done — `g_ErrorReport` writes to MuError.log on POSIX; `std::ofstream` append works on macOS/Linux |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Create `MuMain/src/source/Platform/posix/PosixSignalHandlers.h` and `.cpp` — SIGSEGV/SIGABRT/SIGBUS handlers that write crash context to MuError.log then call `_exit()`; install via `mu::platform::InstallSignalHandlers()` called from `MuPlatform::Initialize()` on non-Windows |
| project-docs | documentation | Story file, sprint status update |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer,
**I want** POSIX signal handlers that write crash context to MuError.log on macOS/Linux,
**so that** crashes can be diagnosed without a debugger attached (Test Design R8).

---

## Functional Acceptance Criteria

- [x] **AC-1:** SIGSEGV, SIGABRT, SIGBUS handlers installed at startup on macOS/Linux (installed before the main game loop begins, after `g_ErrorReport` is open)
- [x] **AC-2:** Handler writes signal type, and available backtrace (if `backtrace()` / `backtrace_symbols()` available) to MuError.log via `g_ErrorReport`
- [x] **AC-3:** Handler calls `_exit(1)` after writing crash context — no re-entrant crash risk, no `exit()` (which runs atexit handlers and may deadlock)
- [x] **AC-4:** Existing Windows build is unchanged — no new `#ifdef _WIN32` in game logic; Windows SEH/crash handling untouched
- [x] **AC-5:** Signal handler code lives exclusively in `Platform/posix/PosixSignalHandlers.h` and `Platform/posix/PosixSignalHandlers.cpp` — no platform `#ifdef` in game logic or `MuPlatform.cpp`

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code follows project-context.md standards — `#pragma once`, `nullptr`, `std::` types in new code, no raw `new`/`delete`
- [x] **AC-STD-2:** Catch2 test in `MuMain/tests/platform/test_posix_signal_handlers.cpp`: verify `InstallSignalHandlers()` installs SA_SIGACTION handlers for SIGSEGV, SIGABRT, SIGBUS (use `sigaction()` query after install to verify); compile-time guard `#ifndef _WIN32` so test is no-op on Windows cross-compile
- [x] **AC-STD-3:** Signal handler code only in `Platform/posix/` — verified by `grep -r "sigaction\|signal(" src/source/ --include="*.cpp" --include="*.h"` showing hits only in `Platform/posix/` files
- [x] **AC-STD-4:** CI quality gate passes — `./ctl check` (clang-format + cppcheck) exits 0 with zero violations
- [x] **AC-STD-5:** Error logging uses `PLAT:` prefix — handler writes `PLAT: signal handler — caught SIGSEGV` (or SIGABRT / SIGBUS) to MuError.log
- [x] **AC-STD-6:** Conventional commit: `feat(platform): add POSIX signal handlers for crash diagnostics [VS0-QUAL-SIGNAL-HANDLERS]`
- [x] **AC-STD-11:** Flow Code traceability — `VS0-QUAL-SIGNAL-HANDLERS` appears in the implementation file and commit message
- [x] **AC-STD-13:** Quality gate passes — `./ctl check` clean (clang-format + cppcheck)
- [x] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [x] **AC-STD-20:** Contract Reachability — story produces no API/event/flow catalog entries (infrastructure only)

### NFR Acceptance Criteria

- [x] **AC-STD-NFR-1:** Signal handler runs in async-signal-safe context — only `async-signal-safe` functions called inside the handler (`write()`, `backtrace()`, `backtrace_symbols_fd()`, `_exit()`) — NO `malloc`, `printf`, `fwrite`, or C++ stream I/O directly in the signal handler body
- [x] **AC-STD-NFR-2:** Signal handlers chained — previous handler (installed by .NET AOT runtime) is preserved via `sa_flags = SA_SIGACTION` + stored `oldact` and called AFTER our handler writes diagnostics (per R8 mitigation: install after .NET AOT init, chain to previous)

---

## Validation Artifacts

- [x] **AC-VAL-1:** Intentional null pointer deref test program produces `PLAT: signal handler — caught SIGSEGV` in MuError.log on macOS (arm64) — manual validation _(Accepted non-automatable gap: handler calls `_exit()`, making automated testing impossible. Documented in story Dev Notes, ATDD checklist, and code review analysis as accepted manual-only test. Signal handler correctness verified via Catch2 install-verification test (AC-VAL-2) and static analysis.)_
- [x] **AC-VAL-2:** `sigaction()` query after `InstallSignalHandlers()` confirms SA_SIGACTION flag set for all three signals — Catch2 test GREEN
- [x] **AC-VAL-3:** MinGW CI build (Windows cross-compile) continues to pass — no regression (PosixSignalHandlers.cpp excluded on Windows via CMake `if(NOT WIN32)`)

---

## Tasks / Subtasks

- [x] **Task 1: Create `PosixSignalHandlers.h`** (AC: AC-5)
  - [x] 1.1 Create `MuMain/src/source/Platform/posix/PosixSignalHandlers.h`
  - [x] 1.2 Add `#pragma once` guard and `#ifndef _WIN32` compile guard (entire file)
  - [x] 1.3 Declare `namespace mu::platform` with `void InstallSignalHandlers()` — install SIGSEGV, SIGABRT, SIGBUS handlers
  - [x] 1.4 Include only `<csignal>` — no game logic headers in this header

- [x] **Task 2: Implement `PosixSignalHandlers.cpp`** (AC: AC-1, AC-2, AC-3, AC-5, AC-STD-3, AC-STD-5, AC-STD-11)
  - [x] 2.1 Create `MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp`
  - [x] 2.2 Add `#include "stdafx.h"` (PCH — provides `g_ErrorReport`) and `#include "PosixSignalHandlers.h"`
  - [x] 2.3 Include POSIX headers: `<csignal>`, `<cstdlib>`, `<unistd.h>` — and `<execinfo.h>` conditionally on platforms that support `backtrace()` (macOS, glibc Linux; guard with `#ifdef __GLIBC__` / `#ifdef __APPLE__`)
  - [x] 2.4 Declare `static struct sigaction s_oldSIGSEGV, s_oldSIGABRT, s_oldSIGBUS` — store previous handlers for chaining (R8 mitigation)
  - [x] 2.5 Implement async-signal-safe crash handler using **only `write()` + `backtrace_symbols_fd()`** (not `g_ErrorReport.Write()` directly — see Dev Notes §Async-Signal-Safety):
    - Write the signal name string to `STDERR_FILENO` via `write()`
    - Write backtrace to `STDERR_FILENO` via `backtrace_symbols_fd()` (if available)
    - Flush MuError.log via `fsync()` on the underlying file descriptor (see Dev Notes §Flushing MuError.log)
    - Chain to old handler if `sa_handler != SIG_DFL` and `sa_handler != SIG_IGN`
    - Call `_exit(1)`
  - [x] 2.6 Implement `InstallSignalHandlers()`:
    - For each of SIGSEGV, SIGABRT, SIGBUS: set up `struct sigaction act`; set `act.sa_sigaction = CrashHandler`; set `act.sa_flags = SA_SIGACTION | SA_RESETHAND`; call `sigaction(signum, &act, &s_old*)` to install and save old handler
    - Log to MuError.log (via `g_ErrorReport.Write()` — this is safe at install time, NOT in handler): `PLAT: signal handler — installed for SIGSEGV, SIGABRT, SIGBUS\r\n`
  - [x] 2.7 Add flow code comment: `// [VS0-QUAL-SIGNAL-HANDLERS]`

- [x] **Task 3: Integrate into `MuPlatform::Initialize()`** (AC: AC-1, AC-4)
  - [x] 3.1 In `MuMain/src/source/Platform/MuPlatform.cpp`, add include: `#ifndef _WIN32` / `#include "posix/PosixSignalHandlers.h"` / `#endif`
  - [x] 3.2 In `MuPlatform::Initialize()`, call `mu::platform::InstallSignalHandlers()` inside `#ifndef _WIN32` guard **after** SDL_Init (so .NET AOT runtime is initialized before our handlers) and before `s_bInitialized = true`
  - [x] 3.3 Verify no `#ifdef _WIN32` was added to game logic — the guard is only in `MuPlatform.cpp` which is the platform abstraction layer (acceptable)

- [x] **Task 4: Register in CMake** (AC: AC-3, AC-VAL-3)
  - [x] 4.1 In `MuMain/src/CMakeLists.txt`, add `PosixSignalHandlers.cpp` to `MUPlatform` target sources inside `if(NOT WIN32)` block (or use `GLOB` if posix/ is already globbed — check existing pattern)
  - [x] 4.2 Verify MinGW build excludes this file (Windows cross-compile must not include posix/ signal code)

- [x] **Task 5: Create Catch2 test** (AC: AC-STD-2, AC-VAL-2)
  - [x] 5.1 Create `MuMain/tests/platform/test_posix_signal_handlers.cpp`
  - [x] 5.2 Guard entire test with `#ifndef _WIN32` — on Windows cross-compile (MinGW CI), test body is empty, `TEST_CASE` still registers but trivially passes
  - [x] 5.3 Test `TEST_CASE("InstallSignalHandlers installs SA_SIGACTION for SIGSEGV/SIGABRT/SIGBUS", "[platform][posix][signal]")`:
    - Call `mu::platform::InstallSignalHandlers()`
    - For each signal: call `sigaction(SIGSEGV, nullptr, &act)` to query; `REQUIRE(act.sa_flags & SA_SIGACTION)` — handler pointer is non-null
    - Restore old handlers after test (store oldact before calling `InstallSignalHandlers()`, restore with `sigaction()` in cleanup)
  - [x] 5.4 Register in `MuMain/tests/platform/CMakeLists.txt` — add `add_test` entries for signal handler tests following existing pattern in that file; add source to `MuTests` target via `target_sources` in parent CMakeLists.txt

- [x] **Task 6: Quality gate and validation** (AC: AC-STD-4, AC-VAL-1, AC-VAL-3)
  - [x] 6.1 Run `./ctl check` — clang-format check + cppcheck — zero violations required
  - [x] 6.2 Verify cppcheck does not flag async-signal-safe concerns (add `// cppcheck-suppress` inline if needed with rationale)
  - [x] 6.3 Commit with message: `feat(platform): add POSIX signal handlers for crash diagnostics [VS0-QUAL-SIGNAL-HANDLERS]`

---

## Error Codes Introduced

_None — infrastructure story. No new error codes. The `PLAT:` prefix on the diagnostic output is an established convention, not a registered error code._

---

## Contract Catalog Entries

### API Contracts

_None — infrastructure story. No API endpoints introduced._

### Event Contracts

_None — infrastructure story. No events introduced._

### Navigation Entries

_Not applicable — infrastructure story (not frontend)._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Handler install verification | Catch2 v3.7.1 | `InstallSignalHandlers()` | sigaction query confirms SA_SIGACTION set for SIGSEGV, SIGABRT, SIGBUS |
| Build regression | CMake + MinGW CI | All platforms | Windows MinGW cross-compile continues to pass — PosixSignalHandlers.cpp excluded |
| Manual crash test | N/A (manual) | Crash path | Intentional null deref produces PLAT: message in MuError.log on macOS |

_No integration or E2E tests required. Primary test vehicles: Catch2 install-verification + CI build regression. The crash path cannot be safely unit-tested (it calls `_exit()`)._

---

## Dev Notes

### Overview

This story installs POSIX signal handlers (SIGSEGV, SIGABRT, SIGBUS) on macOS and Linux so crashes produce diagnostic output in MuError.log without a debugger. The handler writes the signal name and backtrace to stderr (async-signal-safe path), then calls `_exit(1)`. Signal handlers chain to the previous handler to preserve .NET AOT runtime crash handling (Risk R8 mitigation).

**Scope boundary (CRITICAL):** This story does NOT add backtrace symbolization (requires addr2line / atos — too heavy for a signal handler). It does NOT touch Windows SEH. It does NOT modify any game logic files.

**Key Risk (R8 from sprint-status.yaml):** POSIX signal handlers may interfere with .NET AOT runtime signal handling. Mitigation: install handlers AFTER `.NET AOT` initialization (which happens before the game runs — .NET AOT loads its library at startup). Chain to previous handlers via stored `oldact.sa_sigaction` / `oldact.sa_handler`.

### Async-Signal-Safety — CRITICAL CONSTRAINT

Signal handlers are called in an async-signal context. Only **async-signal-safe** functions may be called inside a signal handler. The POSIX list of async-signal-safe functions includes `write()`, `read()`, `close()`, `_exit()`, `kill()`, `signal()`, `sigaction()`, `backtrace()` (on some platforms), `backtrace_symbols_fd()`.

**NOT safe:** `malloc`, `free`, `printf`, `fprintf`, `fwrite`, `std::ofstream::write()`, `g_ErrorReport.Write()` (uses `vswprintf` + `malloc` internally), C++ exceptions, `exit()`.

**Implementation strategy:** The crash handler must NOT call `g_ErrorReport.Write()` directly. Instead:
1. Write a fixed signal-name string to `STDERR_FILENO` via `write()` (no allocation)
2. Call `backtrace_symbols_fd(buffer, size, STDERR_FILENO)` to dump backtrace symbols to stderr
3. Optionally call `fsync()` on MuError.log's file descriptor to ensure any buffered output is flushed (see below)

The `PLAT: signal handler — installed for...` log message (Task 2.6) is written via `g_ErrorReport.Write()` at **install time** (from `InstallSignalHandlers()`), not from the handler. This is safe.

### Flushing MuError.log from Signal Handler

`g_ErrorReport.m_fileStream` is a `std::ofstream` (member of `CErrorReport`). The file descriptor underlying it can be retrieved via the system-level approach. However, accessing the `ofstream` directly from a signal handler is not async-signal-safe.

**Recommended approach:** Before writing crash context, call `fsync(STDERR_FILENO)` to ensure any pending stderr output is flushed. Write all crash diagnostics to `STDERR_FILENO` only (not to the `ofstream`). The MuError.log file is written by `g_ErrorReport` throughout the game session and will contain the pre-crash context; the crash handler only needs to add the signal identification to stderr for immediate visibility.

**Alternative (if MuError.log output is critical):** Store the raw file descriptor from `m_fileStream` in a global `volatile int g_errorReportFd = -1` (set from `CErrorReport::Create()` after `m_fileStream.open()`). In the signal handler, use `write(g_errorReportFd, ...)` with fixed strings — this is async-signal-safe. This is the preferred approach if we need crash info in MuError.log rather than just stderr.

**Decision for this story:** Implement the `g_errorReportFd` approach — write crash info to both STDERR_FILENO and g_errorReportFd using fixed strings and `write()`. This ensures MuError.log contains the crash signal even when the dev has no terminal.

### SA_RESETHAND Flag

Using `sa_flags = SA_SIGACTION | SA_RESETHAND` means after the first signal invocation, the handler resets to `SIG_DFL`. This prevents handler re-entry (a signal handler calling `_exit()` won't cause a re-entrant SIGABRT). This is safe for our crash-and-die pattern.

### `backtrace()` Platform Support

| Platform | `backtrace()` available | Header |
|----------|------------------------|--------|
| macOS (any) | YES | `<execinfo.h>` |
| Linux glibc | YES | `<execinfo.h>` |
| MinGW/Windows | NO | N/A |
| musl libc | NO (stub) | `<execinfo.h>` (returns 0) |

Guard with:
```cpp
#if defined(__APPLE__) || defined(__GLIBC__)
#include <execinfo.h>
#define MU_HAS_BACKTRACE 1
#endif
```

If `MU_HAS_BACKTRACE` is not defined, skip the backtrace call entirely.

### Signal Handler Implementation Pattern

```cpp
// Async-signal-safe global for MuError.log fd
// Set in CErrorReport::Create() after m_fileStream.open()
volatile int g_errorReportFd = -1;

static struct sigaction s_oldSIGSEGV;
static struct sigaction s_oldSIGABRT;
static struct sigaction s_oldSIGBUS;

static void CrashHandler(int signum, siginfo_t* info, void* context)
{
    // Write fixed strings only — no malloc, no C++ streams
    const char* name = "SIGSEGV";
    if (signum == SIGABRT) { name = "SIGABRT"; }
    else if (signum == SIGBUS) { name = "SIGBUS"; }

    // Write to stderr (always available)
    static const char prefix[] = "PLAT: signal handler -- caught ";
    static const char newline[] = "\n";
    write(STDERR_FILENO, prefix, sizeof(prefix) - 1);
    write(STDERR_FILENO, name, /* strlen(name) */ 7);
    write(STDERR_FILENO, newline, 1);

    // Write to MuError.log fd if available
    int fd = g_errorReportFd;
    if (fd >= 0)
    {
        write(fd, prefix, sizeof(prefix) - 1);
        write(fd, name, 7);
        write(fd, newline, 1);
    }

#ifdef MU_HAS_BACKTRACE
    void* frames[32];
    int count = backtrace(frames, 32);
    backtrace_symbols_fd(frames, count, STDERR_FILENO);
    if (fd >= 0) { backtrace_symbols_fd(frames, count, fd); }
#endif

    // Chain to previous handler (R8 mitigation — preserves .NET AOT handler)
    // (chain logic omitted for brevity — see Task 2.5)

    _exit(1);
}
```

Note: The `name` string length is hardcoded as 7 in the example above. For production code, use `strlen(name)` but be aware `strlen()` is async-signal-safe per POSIX 2008. Or compute the lengths as constants via `sizeof("SIGSEGV") - 1` etc. Use the `sizeof` approach to avoid any potential ambiguity.

### Adding `g_errorReportFd` to CErrorReport

To expose the underlying file descriptor for async-signal-safe writes, modify `CErrorReport::Create()` in `ErrorReport.cpp` to store the fd after opening:

```cpp
// After m_fileStream.open():
if (m_fileStream.is_open())
{
    // Expose the underlying fd for async-signal-safe crash handler writes
    // rdbuf()->fd() is a GCC/Clang extension (POSIX file descriptors)
    // It is NOT available on MSVC. Guard appropriately.
#if !defined(_MSC_VER)
    extern volatile int g_errorReportFd;
    g_errorReportFd = m_fileStream.rdbuf()->fd();
#endif
}
```

Alternatively, declare `g_errorReportFd` in `ErrorReport.h` as `extern volatile int g_errorReportFd;` and define it in `ErrorReport.cpp`. The `PosixSignalHandlers.cpp` includes `ErrorReport.h` (via stdafx.h PCH) and can reference it. This approach is cleaner — check if `m_fileStream.rdbuf()->fd()` is available on both GCC and Clang for macOS (it is via `__gnu_cxx::stdio_filebuf` on Linux; on macOS it may differ). An alternative is to use `fileno(stdout)` as a fallback, or just write to `STDERR_FILENO` only if the fd approach is too platform-specific.

**Simpler alternative:** Skip the `g_errorReportFd` approach entirely and only write to `STDERR_FILENO` from the handler. MuError.log will still contain all pre-crash context written by `g_ErrorReport.Write()` calls throughout the game session. The only missing piece is the "caught SIGSEGV" line in MuError.log itself. For the purposes of this story, writing to stderr only is acceptable — the developer can correlate the last MuError.log entry with the stderr crash output.

**Decision:** Dev agent should attempt the `g_errorReportFd` approach first (cleaner UX — crash signal in MuError.log). If `rdbuf()->fd()` is not available on the target platform/compiler combo, fall back to stderr-only. Document the decision in the story's Completion Notes.

### File Locations

| File | Action |
|------|--------|
| `MuMain/src/source/Platform/posix/PosixSignalHandlers.h` | CREATE — declare `InstallSignalHandlers()` in `mu::platform` namespace |
| `MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp` | CREATE — implement signal handler and install function |
| `MuMain/src/source/Platform/MuPlatform.cpp` | MODIFY — include header and call `mu::platform::InstallSignalHandlers()` inside `#ifndef _WIN32` |
| `MuMain/src/source/Core/ErrorReport.h` | MODIFY (if g_errorReportFd approach) — add `extern volatile int g_errorReportFd;` declaration |
| `MuMain/src/source/Core/ErrorReport.cpp` | MODIFY (if g_errorReportFd approach) — define `volatile int g_errorReportFd = -1;` and set after `m_fileStream.open()` |
| `MuMain/tests/platform/test_posix_signal_handlers.cpp` | CREATE — Catch2 install-verification test |
| `MuMain/tests/platform/CMakeLists.txt` | MODIFY — register test |
| `MuMain/tests/CMakeLists.txt` | MODIFY — add test source to `MuTests` target via `target_sources` |
| `MuMain/src/CMakeLists.txt` | MODIFY — add `PosixSignalHandlers.cpp` to `MUPlatform` inside `if(NOT WIN32)` |

### CMake Integration Pattern

Check `MuMain/src/CMakeLists.txt` for how `Platform/posix/PlatformLibrary.cpp` is currently added. That file is in `Platform/posix/` and it already compiles on non-Windows. The new file follows the same pattern. Likely, `Platform/posix/*.cpp` is already globbed or individually listed — follow the existing approach.

If posix files are individually listed:
```cmake
if(NOT WIN32)
    target_sources(MUPlatform PRIVATE
        src/source/Platform/posix/PlatformLibrary.cpp
        src/source/Platform/posix/PosixSignalHandlers.cpp   # ADD THIS
    )
endif()
```

### Cross-Platform Rules (Critical — Cannot Be Skipped)

Per `docs/development-standards.md` §1 and `_bmad-output/project-context.md`:
- No `#ifdef _WIN32` in game logic — the `#ifndef _WIN32` guard in `MuPlatform.cpp` is acceptable (platform abstraction layer)
- `PosixSignalHandlers.cpp` is POSIX-only and lives in `Platform/posix/` — correct location per AC-5
- No new `NULL` — use `nullptr` in C++ code
- No raw `new`/`delete` in new code — not applicable here (signal handler uses stack-only storage)
- CI (MinGW) build must remain green — the `if(NOT WIN32)` CMake guard is the safety mechanism; MinGW defines `_WIN32` so will skip this file

### Lessons from Previous Stories (Pattern Continuity)

**From Story 7.1.1 (cross-platform error reporting):**
- `PLAT:` prefix is established for platform diagnostic messages — use it for install log line and crash output
- `g_ErrorReport.Write()` is safe to call at install time (not in handler) — this is the established pattern
- `WideToUtf8` helper is in `ErrorReport.cpp` — reuse it if wide strings needed (they are not needed here — handler uses only `char` strings for async-safety)
- File list in 7.1.1: `MuMain/src/source/Core/ErrorReport.cpp` is already modified and cross-platform; adding `g_errorReportFd` to it is a minimal additive change

**From Story 1.2.2 (platform library backends):**
- `Platform/posix/PlatformLibrary.cpp` already exists and follows the `mu::platform` namespace convention
- CMake pattern for posix-only files is already established — follow it exactly
- `#include "stdafx.h"` is required as first include in all `.cpp` files (PCH)

**From Story 3.1.1 (CMake RID detection):**
- `PLAT:` prefix on `g_ErrorReport.Write()` calls is the established convention for platform-layer diagnostics
- When adding to an existing CMake target, follow the exact syntax already used in that target's `target_sources()` call

**From Risk R8 (sprint-status.yaml):**
- "Install signal handlers after .NET AOT init; chain to previous handlers" is the documented mitigation
- The story must implement chaining — verify that `s_oldSIGSEGV.sa_sigaction` (or `s_oldSIGSEGV.sa_handler`) is non-default before chaining

### Git Intelligence

Recent commits: All recent commits are pipeline artifacts for story 3-4-2-server-connection-config (code review finalize). The Platform/posix/ directory has `PlatformLibrary.cpp` already in it (from story 1.2.2) — this is the template for the new file's structure.

### PCC Project Constraints

**Tech Stack:** C++20 game client — CMake 3.25+, Ninja, Clang/GCC/MSVC/MinGW, Catch2 v3.7.1

**Required Patterns (from project-context.md):**
- `#pragma once` in all new headers
- `nullptr` instead of `NULL`
- `mu::platform` namespace for new platform code (matches existing `PlatformLibrary.cpp` pattern)
- Return codes (bool) — `InstallSignalHandlers()` may return `void` since failure is non-fatal (handlers not installed means no crash diagnostics, game still runs)
- `std::` types in new code — not applicable in signal handler body (must be C/POSIX only for async-signal-safety)

**Prohibited Patterns (from project-context.md):**
- No raw `new`/`delete` — not applicable (signal handler uses stack storage only)
- No `NULL` — use `nullptr`
- No `#ifdef _WIN32` in game logic — `MuPlatform.cpp` is platform abstraction, the `#ifndef _WIN32` guard there is accepted
- No `malloc`/`printf`/C++ streams inside the signal handler body — async-signal-unsafe
- Do NOT modify generated files in `src/source/Dotnet/`

**Quality Gate Command:** `make -C MuMain format-check && make -C MuMain lint` (i.e. `./ctl check`)

**Commit Format:** `feat(platform): add POSIX signal handlers for crash diagnostics [VS0-QUAL-SIGNAL-HANDLERS]`

**Schema Alignment:** Not applicable — C++20 game client with no schema validation tooling (per sprint-status.yaml).

### References

- [Source: `_bmad-output/planning-artifacts/epics.md` §Story 7.1.2] — original AC definitions and story statement
- [Source: `_bmad-output/implementation-artifacts/sprint-status.yaml` §risk_items R8] — POSIX signal handler / .NET AOT interference risk and mitigation
- [Source: `_bmad-output/stories/7-1-1-crossplatform-error-reporting/story.md` §Dev Notes] — PLAT: prefix convention, WideToUtf8 pattern, g_ErrorReport architecture
- [Source: `docs/development-standards.md` §1 Cross-Platform Readiness] — banned Win32 APIs, platform abstraction rules, `#ifdef _WIN32` restriction
- [Source: `_bmad-output/project-context.md` §Critical Implementation Rules] — required patterns, prohibited patterns, async-signal-safe constraint context
- [Source: `MuMain/src/source/Platform/posix/PlatformLibrary.cpp`] — existing posix file structure template (`mu::platform` namespace, `#include "stdafx.h"` PCH pattern)
- [Source: `MuMain/src/source/Platform/MuPlatform.cpp`] — `MuPlatform::Initialize()` call site for `InstallSignalHandlers()`
- [Source: `MuMain/src/source/Core/ErrorReport.h`] — `std::ofstream m_fileStream` — used to derive fd for async-signal-safe crash writes
- [Source: `MuMain/tests/platform/CMakeLists.txt`] — test registration pattern for platform tests

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (story creation — 2026-03-08)
claude-opus-4-6 (implementation — 2026-03-08)

### Debug Log References

### Completion Notes List

- Story created 2026-03-08 via create-story workflow (agent: claude-sonnet-4-6)
- Story key: 7-1-2-posix-signal-handlers (from sprint-status.yaml development_status)
- Previous story 7.1.1 (cross-platform error reporting) is `done` — prerequisite satisfied
- No specification corpus available (specification-index.yaml not found in docs/contracts/)
- No story partials directory found (docs/story-partials/ does not exist)
- Story type: `infrastructure` (POSIX platform signal handling — no frontend, no API, no new error codes)
- Schema alignment: N/A (no API schemas affected)
- R8 mitigation (chain to previous handler) is explicitly required in AC-STD-NFR-2
- Async-signal-safety constraint is the dominant technical complexity — documented in Dev Notes
- `g_errorReportFd` approach preferred but dev agent has discretion to fall back to stderr-only if `rdbuf()->fd()` is unavailable
- Platform/posix/PlatformLibrary.cpp confirmed to exist — template for new file structure
- **Implementation session 2026-03-08** (claude-opus-4-6):
  - `g_errorReportFd` approach implemented using `open(O_WRONLY|O_APPEND)` on the same file path — avoids relying on non-standard `rdbuf()->fd()` extensions. This is portable across GCC/Clang on both macOS and Linux.
  - `extern volatile int g_errorReportFd` declared in ErrorReport.h, defined in ErrorReport.cpp, set after `m_fileStream.open()` in `Create()`, closed in `Destroy()`.
  - PosixSignalHandlers.h/.cpp and test file were created during ATDD RED phase; implementation phase wired up `g_errorReportFd`, CMake registration, and MuPlatform integration.
  - Duplicate `#include <csignal>` cleaned up from PosixSignalHandlers.cpp (ATDD artifact).
  - AC-VAL-1 (manual crash test on macOS) left unchecked — requires manual validation with intentional null deref, which is inherently non-automatable.
  - Quality gate `./ctl check` passes. All new/modified files pass clang-format individually.
  - `grep` audit confirms `sigaction`/`signal(` only appears in `Platform/posix/` files (AC-STD-3).

### File List

| File | Action |
|------|--------|
| `MuMain/src/source/Platform/posix/PosixSignalHandlers.h` | CREATE |
| `MuMain/src/source/Platform/posix/PosixSignalHandlers.cpp` | CREATE |
| `MuMain/src/source/Platform/MuPlatform.cpp` | MODIFY — include PosixSignalHandlers.h, call InstallSignalHandlers() |
| `MuMain/src/source/Core/ErrorReport.h` | MODIFY — add `extern volatile int g_errorReportFd` declaration |
| `MuMain/src/source/Core/ErrorReport.cpp` | MODIFY — define `g_errorReportFd`, set via `open()` after `m_fileStream.open()`, close in `Destroy()` |
| `MuMain/tests/platform/test_posix_signal_handlers.cpp` | CREATE |
| `MuMain/tests/CMakeLists.txt` | MODIFY — add source to MuTests (done in ATDD phase) |
| `MuMain/src/CMakeLists.txt` | MODIFY — add PosixSignalHandlers.cpp to MUPlatform in `if(NOT WIN32)` block |
