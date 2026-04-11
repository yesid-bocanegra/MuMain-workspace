# Story 7.10.1: Migrate logging infrastructure to spdlog

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.10 - Logging Infrastructure Modernization |
| Story ID | 7.10.1 |
| Story Points | 13 |
| Priority | P1 |
| Story Type | `backend_service` |
| Value Stream | VS-0 (Platform) |
| Flow Code | VS0-CORE-MIGRATE-LOGGING |
| FRs Covered | N/A (Enabler) |
| Prerequisites | 7-6-7 (error-report-cross-platform-diagnostics) done |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Replace CErrorReport, CmuConsoleDebug, LOG_CALL, fprintf(stderr) with spdlog. Touch ~59+ source files. |
| project-docs | documentation | Update project-context.md logging table, development-standards.md logging section |

---

## Story

**[VS-0] [Flow:E]**

**As a** game client developer,
**I want** a unified, leveled, category-tagged logging system backed by spdlog,
**so that** I can filter logs by severity and subsystem, rotate log files reliably, and eliminate the tech debt of four separate ad-hoc logging mechanisms.

---

## Functional Acceptance Criteria

- [x] **AC-1:** spdlog 1.x is integrated via CMake FetchContent and links to all MU targets (MUCore, MUGame, Main). Builds pass on macOS (arm64), Linux (x64), and MinGW (i686) CI.
- [x] **AC-2:** A `MuLogger.h` facade header exists in `Core/` providing per-module named loggers via `mu::log::Get(name)`, with levels: trace, debug, info, warn, error, critical. Macros `MU_LOG_TRACE(logger, ...)` through `MU_LOG_CRITICAL(logger, ...)` wrap spdlog calls.
- [x] **AC-3:** A rotating file sink writes to `MuError.log` (max 512 KB per file, 3 rotated backups). A colored stderr sink outputs warn+ messages at runtime. Both sinks are configured during `MuMain()` initialization, before any logging call.
- [x] **AC-4:** The async-signal-safe crash handler fd (`g_errorReportFd`) is preserved. On POSIX, the crash signal handler writes directly to the file descriptor (not through spdlog), exactly as it does today.
- [x] **AC-5:** All 277 `g_ErrorReport.Write(L"fmt", ...)` call sites are replaced with spdlog calls at appropriate levels (error/warn/info) using the correct per-module logger.
- [x] **AC-6:** All 339 `LOG_CALL(func, arg)` macro expansions are replaced with `SPDLOG_TRACE(logger, "func(arg)")` (compiled out in Release) followed by the direct function call. The `LOG_CALL` macro is deleted from `ErrorReport.h`.
- [x] **AC-7:** All 140 `g_ConsoleDebug->Write(type, ...)` call sites are replaced with spdlog calls: `MCD_ERROR` → `error`, `MCD_SEND`/`MCD_RECEIVE` → `debug`, `MCD_NORMAL` → `info`.
- [x] **AC-8:** All `fprintf(stderr, "[DIAG-*]...")` diagnostic call sites (~29 sites across 5 files) are replaced with `SPDLOG_DEBUG(logger, ...)`.
- [x] **AC-9:** The old classes `CErrorReport` (ErrorReport.h/cpp), `CmuConsoleDebug` (muConsoleDebug.h/cpp), and the `LOG_CALL` macro are deleted. No code references them.
- [x] **AC-10:** Runtime log-level control is available via the existing `$` console command system: `$loglevel <logger> <level>` changes a named logger's level at runtime.
- [x] **AC-11:** A Catch2 test in `tests/core/test_mu_logger.cpp` validates: logger creation, level filtering (disabled level produces no output), and file sink writes.
- [x] **AC-12:** The `MU_ERR_INPUT_UNMAPPED_VK` log spam is eliminated — `GetAsyncKeyState()` shim silently returns 0 for unmapped VK codes (matching Windows behavior) instead of logging per-frame. `MuPlatformLogUnmappedVk()` is deleted.

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards Compliance (naming, logging, error taxonomy)
- [x] **AC-STD-2:** Testing Requirements (Catch2 test for MuLogger, build-time AC tests for deleted symbols)
- [x] **AC-STD-3:** Documentation (project-context.md logging table updated)
- [x] **AC-STD-8:** Error Catalog updated with new error codes (if applicable)
- [x] **AC-STD-10:** Contract Catalogs updated (API, Event)
- [x] **AC-STD-11:** Flow Code Traceability (VS0-CORE-MIGRATE-LOGGING in commit messages)
- [x] **AC-STD-20:** Contract Reachability

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [x] **AC-STD-13:** Quality Gate passes (`./ctl check`)
- [x] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [x] **AC-STD-16:** Correct test infrastructure used (Catch2, CTest)

---

## Validation Artifacts

- [x] **AC-VAL-2:** Test scenarios documented in `docs/test-scenarios/epic-7/`

---

## Tasks / Subtasks

- [x] Task 1: Integrate spdlog via FetchContent (AC: 1)
  - [x] 1.1 Add spdlog FetchContent block to `src/CMakeLists.txt` (alongside SDL3, Catch2, SDL_ttf)
  - [x] 1.2 Link spdlog::spdlog to MUCore target (propagates to all dependents via PUBLIC)
  - [x] 1.3 Verify macOS, Linux, and MinGW builds pass with spdlog linked
- [x] Task 2: Create MuLogger facade (AC: 2, 3)
  - [x] 2.1 Create `src/source/Core/MuLogger.h` with `mu::log::Init()`, `mu::log::Get(name)`, and `MU_LOG_*` macros
  - [x] 2.2 Create `src/source/Core/MuLogger.cpp` — `Init()` sets up rotating file sink (512KB x 3) + colored stderr sink (warn+), creates default loggers
  - [x] 2.3 Define named loggers: `core`, `network`, `render`, `data`, `gameplay`, `ui`, `audio`, `platform`, `dotnet`, `gameshop`, `scenes`
  - [x] 2.4 Call `mu::log::Init()` in `MuMain()` before any existing logging calls
  - [x] 2.5 Preserve `g_errorReportFd` — open the same file path with O_WRONLY|O_APPEND for crash handler use
- [x] Task 3: Migrate `g_ErrorReport.Write` — 277 call sites (AC: 5)
  - [x] 3.1 Migrate `Core/` files (~20 sites) — use `core` logger
  - [x] 3.2 Migrate `Data/` files (~30 sites) — use `data` logger
  - [x] 3.3 Migrate `World/` files (~40 sites) — use `gameplay` logger
  - [x] 3.4 Migrate `Gameplay/` files (~50 sites) — use `gameplay` logger
  - [x] 3.5 Migrate `UI/` files (~30 sites) — use `ui` logger
  - [x] 3.6 Migrate `Network/` + `Dotnet/` files (~40 sites) — use `network`/`dotnet` logger
  - [x] 3.7 Migrate `RenderFX/` files (~20 sites) — use `render` logger
  - [x] 3.8 Migrate `Scenes/`, `Audio/`, `GameShop/`, `Platform/`, `ThirdParty/` files (~47 sites) — use appropriate loggers
  - [x] 3.9 Convert `wchar_t` format strings to UTF-8 `char` format strings (spdlog uses `{fmt}` syntax)
- [x] Task 4: Migrate `LOG_CALL` macro — 339 sites (AC: 6)
  - [x] 4.1 Replace all `LOG_CALL(func, arg)` with `SPDLOG_TRACE(logger, "func(arg)"); func(arg);` in World/Maps/ files (~175 sites)
  - [x] 4.2 Replace in Gameplay/Characters/ files (~164 sites)
  - [x] 4.3 Delete `LOG_CALL`, `MU_WIDEN`, `MU_STRINGIFY` macros from `ErrorReport.h`
- [x] Task 5: Migrate `g_ConsoleDebug->Write` — 140 sites (AC: 7)
  - [x] 5.1 Map `MCD_ERROR` → `spdlog::error`, `MCD_SEND`/`MCD_RECEIVE` → `spdlog::debug`, `MCD_NORMAL` → `spdlog::info`
  - [x] 5.2 Replace all 140 call sites with spdlog equivalents
  - [x] 5.3 Preserve the `$` command parsing logic from `CmuConsoleDebug::CheckCommand` — move to a new `MuConsoleCommands.cpp` or integrate into existing command handling
- [x] Task 6: Migrate `fprintf(stderr)` diagnostics — ~29 sites (AC: 8)
  - [x] 6.1 Replace `[DIAG-CHARSEL]` sites in CharacterScene.cpp with `SPDLOG_DEBUG(gameplay, ...)`
  - [x] 6.2 Replace `[DIAG-SELOBJ]` sites in ZzzInterface.cpp
  - [x] 6.3 Replace `[PKT #N]` sites in WSclient.cpp
  - [x] 6.4 Replace `[GameConfig]` sites in PlatformCrypto.cpp
  - [x] 6.5 Replace `PLAT:` site in ErrorReport.cpp (file deleted — Init() error handling uses spdlog)
- [x] Task 7: Delete old logging infrastructure (AC: 9)
  - [x] 7.1 Delete `ErrorReport.h` and `ErrorReport.cpp`
  - [x] 7.2 Delete `muConsoleDebug.h` and `muConsoleDebug.cpp`
  - [x] 7.3 Remove `extern CErrorReport g_ErrorReport;` and `extern volatile int g_errorReportFd;` declarations (fd moves to MuLogger)
  - [x] 7.4 Remove `#include "ErrorReport.h"` from all files — replace with `#include "MuLogger.h"`
  - [x] 7.5 Remove `#include "muConsoleDebug.h"` from all files
  - [x] 7.6 Verify build: no references to deleted symbols remain
- [x] Task 8: Add runtime log-level control (AC: 10)
  - [x] 8.1 Add `$loglevel <logger> <level>` command handler
  - [x] 8.2 Add `$loggers` command to list all active loggers and their current levels
- [x] Task 9: Tests (AC: 11)
  - [x] 9.1 Create `tests/core/test_mu_logger.cpp` with Catch2 TEST_CASEs
  - [x] 9.2 Grep verification: `g_ErrorReport`, `g_ConsoleDebug`, `LOG_CALL` — 0 active references in source
- [x] Task 10: Documentation and cleanup (AC: STD-1, STD-3)
  - [x] 10.1 Update `CLAUDE.md` logging convention to reference spdlog and MuLogger
  - [x] 10.2 Update `development-standards.md` §2 (Error Handling & Logging) with new logging patterns
  - [x] 10.3 No CI workflow changes needed — spdlog auto-discovered via FetchContent

---

## Error Codes Introduced

_No new error codes — this is an infrastructure migration._

---

## Contract Catalog Entries

### API Contracts

_None — no API changes._

### Event Contracts

_None — no event changes._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 | MuLogger facade | Logger creation, level filtering, file output, multi-logger isolation |
| Build | CMake CTest | 0 references to old APIs | Grep-based regression test: no `g_ErrorReport`, `g_ConsoleDebug`, `LOG_CALL` |
| Integration | Manual | Log output correctness | Launch game, verify MuError.log rotates, stderr shows warn+, `$loglevel` works |

---

## Dev Notes

### Migration Strategy — All-at-Once

The user explicitly requires **all logging mechanisms migrated in a single story** — no incremental phases. This means:
1. spdlog integration + MuLogger facade
2. All 785+ call sites migrated (277 ErrorReport + 339 LOG_CALL + 140 ConsoleDebug + 29 fprintf)
3. Old infrastructure deleted
4. All in one commit chain on a single branch

### spdlog Integration Details

**FetchContent block (add after SDL3_ttf in src/CMakeLists.txt):**
```cmake
FetchContent_Declare(
    spdlog
    GIT_REPOSITORY https://github.com/gabime/spdlog.git
    GIT_TAG        v1.15.3
    GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(spdlog)
```

Link to MUCore as PUBLIC so all downstream targets inherit:
```cmake
target_link_libraries(MUCore PUBLIC spdlog::spdlog)
```

### MuLogger.h Facade Design

```cpp
#pragma once
#include <spdlog/spdlog.h>

namespace mu::log {
    void Init(const std::filesystem::path& logDir);
    void Shutdown();
    std::shared_ptr<spdlog::logger> Get(const std::string& name);
}

// Convenience macros — compile to nothing at SPDLOG_ACTIVE_LEVEL > level
#define MU_LOG_TRACE(logger, ...) SPDLOG_LOGGER_TRACE(logger, __VA_ARGS__)
#define MU_LOG_DEBUG(logger, ...) SPDLOG_LOGGER_DEBUG(logger, __VA_ARGS__)
#define MU_LOG_INFO(logger, ...)  SPDLOG_LOGGER_INFO(logger, __VA_ARGS__)
#define MU_LOG_WARN(logger, ...)  SPDLOG_LOGGER_WARN(logger, __VA_ARGS__)
#define MU_LOG_ERROR(logger, ...) SPDLOG_LOGGER_ERROR(logger, __VA_ARGS__)
```

### Format String Migration

All existing `wchar_t` format strings using `%ls`, `%d`, `%02X` etc. must be converted to `{fmt}` syntax:
- `Write(L"OS \t\t\t: %ls\r\n", si->m_lpszOS)` → `logger->info("OS: {}", WideToUtf8(si->m_lpszOS))`
- `Write(L"RAM \t\t\t: %lldMB\r\n", val)` → `logger->info("RAM: {}MB", val)`
- Hex dumps: use spdlog's `spdlog::to_hex()` or a custom formatter

### wchar_t Conversion

Many existing log call sites pass `wchar_t*` strings. The `WideToUtf8()` helper from ErrorReport.cpp should be moved to a utility header (e.g., `Core/StringUtils.h`) and reused in migrated call sites where wide strings must be logged.

### Crash Handler Preservation (CRITICAL)

The POSIX signal handler in `PosixSignalHandlers.cpp` uses `write(g_errorReportFd, ...)` which is async-signal-safe. spdlog is NOT async-signal-safe. The raw fd approach MUST be preserved:
- `mu::log::Init()` opens the same log file path with `open(path, O_WRONLY|O_APPEND)` and stores the fd
- Signal handlers continue to use `write(fd, ...)` directly
- This is the same pattern as today, just the fd ownership moves from CErrorReport to MuLogger

### Console Command Migration

The `$` commands from `CmuConsoleDebug::CheckCommand` (`$fpscounter`, `$details`, `$vsync`, etc.) are NOT logging commands — they are game debug commands. These must be preserved in a separate command handler, not deleted with the logging class. Move command parsing to the existing game command infrastructure or a new `MuConsoleCommands.cpp`.

### Files Affected (Summary)

| Directory | Files | Primary Logger |
|-----------|-------|---------------|
| Core/ | ErrorReport.h/cpp (DELETE), muConsoleDebug.h/cpp (DELETE), MuLogger.h/cpp (NEW) | `core` |
| Data/ | ~8 files | `data` |
| World/Maps/ | ~15 files | `gameplay` |
| Gameplay/ | ~12 files | `gameplay` |
| UI/ | ~8 files | `ui` |
| Network/ + Dotnet/ | ~10 files | `network`, `dotnet` |
| RenderFX/ | ~5 files | `render` |
| Scenes/ | ~3 files | `scenes` |
| GameShop/ | ~5 files | `gameshop` |
| Audio/ | ~2 files | `audio` |
| Platform/ | ~3 files | `platform` |
| Main/ | MuMain.cpp (init call) | `core` |
| ThirdParty/ | UIControls.cpp | `ui` |

### PCC Project Constraints

- **Prohibited:** No `wprintf` logging (replaced by spdlog), no raw `new`/`delete`, no `NULL`
- **Required:** `std::unique_ptr`, `#pragma once`, `std::filesystem::path`, `[[nodiscard]]` on new fallible functions
- **Coverage:** Catch2 test for MuLogger, build-time regression test for old API deletion
- **References:** docs/project-context.md, docs/development-standards.md

### References

- [Source: src/source/Core/ErrorReport.h — LOG_CALL macro, CErrorReport class]
- [Source: src/source/Core/ErrorReport.cpp — Write(), CutHead(), WideToUtf8(), g_errorReportFd]
- [Source: src/source/Core/muConsoleDebug.h — CmuConsoleDebug, MCD_* types, $ commands]
- [Source: src/source/Core/muConsoleDebug.cpp — CheckCommand(), Write(), color support]
- [Source: src/source/Core/WindowsConsole.h/cpp — leaf:: ANSI abstraction (keep)]
- [Source: src/source/Platform/posix/PosixSignalHandlers.cpp — write(g_errorReportFd)]
- [Source: docs/project-context.md#Logging — current logging table]
- [Source: docs/development-standards.md §2 — Error Handling & Logging]

---

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
