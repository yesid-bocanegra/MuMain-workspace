# ATDD Checklist — Story 7.10.1: spdlog Logging Infrastructure Migration

**Story Key**: 7-10-1  
**Story Type**: backend_service (infrastructure migration)  
**Flow Code**: VS0-CORE-MIGRATE-LOGGING  
**Date**: 2026-04-10  
**Status**: GREEN PHASE — all checklist items complete

---

## PCC Compliance Summary

| Check | Status | Detail |
|-------|--------|--------|
| Prohibited libraries | PASS | No prohibited libraries used — spdlog is a new addition, not banned |
| Required testing patterns | PASS | Catch2 v3.7.1 with TEST_CASE/SECTION, REQUIRE/CHECK macros |
| No mocking framework | PASS | Pure logic tests, no mock framework used |
| No Win32 APIs in tests | PASS | Tests use std::filesystem, std::chrono only |
| Test locations | PASS | `MuMain/tests/core/` matching `src/source/Core/` |
| Coverage threshold | PASS | Threshold=0 (growing incrementally); 6 test cases for MuLogger |
| No Bruno collection | N/A | Not an API story — no REST endpoints |
| No Playwright E2E | N/A | Not a frontend story |

---

## AC-to-Test Mapping

| AC | Description | Test Method | Test File |
|----|-------------|-------------|-----------|
| AC-1 | spdlog FetchContent integration | `AC-1 [7-10-1]: spdlog is integrated via FetchContent and version is 1.x` | `test_logging_migration_7_10_1.cpp` |
| AC-2 | MuLogger.h facade + MU_LOG_* macros | `AC-2 [7-10-1]: mu::log::Get() returns a valid named logger` | `test_mu_logger.cpp` |
| AC-2 | MU_LOG_* macros compile at all levels | `AC-2 [7-10-1]: MU_LOG_* macros compile and execute at all levels` | `test_mu_logger.cpp` |
| AC-3 | Rotating file sink creates MuError.log | `AC-3/AC-11 [7-10-1]: Init() creates MuError.log and file sink writes messages` | `test_mu_logger.cpp` |
| AC-4 | Crash handler fd preserved | Manual verification (async-signal-safe fd, not unit-testable) | — |
| AC-5 | 277 g_ErrorReport.Write sites migrated | grep: `grep -rn "g_ErrorReport" MuMain/src/source --include="*.cpp" --include="*.h"` → 0 results | — |
| AC-6 | 339 LOG_CALL sites migrated | grep: `grep -rn "LOG_CALL" MuMain/src/source --include="*.cpp" --include="*.h"` → 0 results | — |
| AC-7 | 140 g_ConsoleDebug->Write sites migrated | grep: `grep -rn "g_ConsoleDebug" MuMain/src/source --include="*.cpp" --include="*.h"` → 0 results | — |
| AC-8 | ~29 fprintf(stderr) diagnostic sites migrated | grep: `grep -rn 'fprintf(stderr.*DIAG\|fprintf(stderr.*PKT\|fprintf(stderr.*GameConfig\|fprintf(stderr.*PLAT' MuMain/src/source` → 0 results | — |
| AC-9 | Old logging classes deleted | `AC-9 [7-10-1]: ErrorReport.h is deleted` | `test_logging_migration_7_10_1.cpp` |
| AC-9 | muConsoleDebug.h deleted | `AC-9 [7-10-1]: muConsoleDebug.h is deleted` | `test_logging_migration_7_10_1.cpp` |
| AC-9 | MuLogger.h exists | `AC-9/AC-2 [7-10-1]: MuLogger.h exists` | `test_logging_migration_7_10_1.cpp` |
| AC-10 | Runtime $loglevel command | Manual verification in running game | — |
| AC-11 | Logger creation | `AC-2 [7-10-1]: mu::log::Get() returns a valid named logger` | `test_mu_logger.cpp` |
| AC-11 | Level filtering | `AC-11 [7-10-1]: Level filtering suppresses messages below logger threshold` | `test_mu_logger.cpp` |
| AC-11 | File sink writes | `AC-3/AC-11 [7-10-1]: Init() creates MuError.log and file sink writes messages` | `test_mu_logger.cpp` |
| AC-11 | Multi-logger isolation | `AC-11 [7-10-1]: Named loggers are isolated — different instances, independent levels` | `test_mu_logger.cpp` |
| AC-11 | All 11 named loggers retrievable | `AC-11 [7-10-1]: All named loggers (core, network, render, ...) are retrievable` | `test_mu_logger.cpp` |
| AC-12 | VK spam eliminated | Already done — [x] in story.md | COMPLETED |

---

## Implementation Checklist

All items start as `[ ]` (pending). Developer checks each item during implementation.

### Phase 1: spdlog Integration (AC-1)

- [x] spdlog FetchContent block added to `MuMain/src/CMakeLists.txt` (GIT_TAG v1.15.3)
- [x] `target_link_libraries(MUCore PUBLIC spdlog::spdlog)` added
- [x] macOS arm64 build passes with spdlog linked (`./ctl build`)
- [x] Linux x64 build passes with spdlog linked
- [x] MinGW i686 CI build passes with spdlog linked
- [x] `AC-1 [7-10-1]` test passes: `ctest -R mu_logger`

### Phase 2: MuLogger Facade (AC-2, AC-3)

- [x] `MuMain/src/source/Core/MuLogger.h` created with `mu::log::Init()`, `mu::log::Get()`, `mu::log::Shutdown()`
- [x] `MuMain/src/source/Core/MuLogger.cpp` created — Init() configures rotating file sink (512KB × 3) + colored stderr sink (warn+)
- [x] All 11 named loggers created in Init(): `core`, `network`, `render`, `data`, `gameplay`, `ui`, `audio`, `platform`, `dotnet`, `gameshop`, `scenes`
- [x] `MU_LOG_TRACE` through `MU_LOG_CRITICAL` macros defined (wrap `SPDLOG_LOGGER_*`)
- [x] `mu::log::Init()` called in `MuMain()` before first logging call
- [x] `g_errorReportFd` raw fd preserved — `mu::log::Init()` opens same path with `O_WRONLY|O_APPEND`
- [x] `AC-2 [7-10-1]` tests pass (all 2 test cases in test_mu_logger.cpp for AC-2)
- [x] `AC-3/AC-11 [7-10-1]` file sink test passes
- [x] `AC-9/AC-2 [7-10-1]` MuLogger.h existence test passes

### Phase 3: Migrate g_ErrorReport.Write — 277 Sites (AC-5)

- [x] Core/ files migrated (~20 sites) — `core` logger
- [x] Data/ files migrated (~30 sites) — `data` logger
- [x] World/ files migrated (~40 sites) — `gameplay` logger
- [x] Gameplay/ files migrated (~50 sites) — `gameplay` logger
- [x] UI/ files migrated (~30 sites) — `ui` logger
- [x] Network/ + Dotnet/ files migrated (~40 sites) — `network`/`dotnet` logger
- [x] RenderFX/ files migrated (~20 sites) — `render` logger
- [x] Scenes/, Audio/, GameShop/, Platform/, ThirdParty/ files migrated (~47 sites) — appropriate loggers
- [x] wchar_t format strings converted to UTF-8 `{fmt}` syntax
- [x] Generic `fmt::formatter<T>` for all enum types added in MuLogger.h (replaces WideToUtf8 need)
- [x] grep check: `grep -rn "g_ErrorReport" MuMain/src/source --include="*.cpp" --include="*.h"` → **0 results**

### Phase 4: Migrate LOG_CALL — 339 Sites (AC-6)

- [x] World/Maps/ files migrated (~175 sites) — `SPDLOG_TRACE(logger, "func(arg)"); func(arg);`
- [x] Gameplay/Characters/ files migrated (~164 sites)
- [x] `LOG_CALL`, `MU_WIDEN`, `MU_STRINGIFY` macros deleted with `ErrorReport.h`
- [x] grep check: `grep -rn "LOG_CALL" MuMain/src/source --include="*.cpp" --include="*.h"` → **0 results** (1 comment in MuLogger.h)

### Phase 5: Migrate g_ConsoleDebug->Write — 140 Sites (AC-7)

- [x] `MCD_ERROR` → `spdlog::error` at all sites
- [x] `MCD_SEND`/`MCD_RECEIVE` → `spdlog::debug` at all sites
- [x] `MCD_NORMAL` → `spdlog::info` at all sites
- [x] `$` game debug commands from `CmuConsoleDebug::CheckCommand` preserved in `MuConsoleCommands.cpp`
- [x] grep check: `grep -rn "g_ConsoleDebug" MuMain/src/source --include="*.cpp" --include="*.h"` → **0 results**

### Phase 6: Migrate fprintf(stderr) Diagnostics — ~29 Sites (AC-8)

- [x] `[DIAG-CHARSEL]` sites in CharacterScene.cpp → `mu::log::Get("gameplay")->debug(...)`
- [x] `[DIAG-SELOBJ]` sites in ZzzInterface.cpp → `mu::log::Get("gameplay")->debug(...)`
- [x] `[PKT #N]` sites in WSclient.cpp → `mu::log::Get("network")->debug(...)`
- [x] `[GameConfig]` sites in PlatformCrypto.cpp → `mu::log::Get("core")->debug(...)`
- [x] `PLAT:` site in ErrorReport.cpp — file deleted, Init() uses spdlog
- [x] grep check: `grep -rn 'fprintf(stderr' MuMain/src/source --include="*.cpp"` → **0 results** (1 comment in MuLogger.h)

### Phase 7: Delete Old Infrastructure (AC-9)

- [x] `ErrorReport.h` deleted (`git rm`)
- [x] `ErrorReport.cpp` deleted (`git rm`)
- [x] `muConsoleDebug.h` deleted (`git rm`)
- [x] `muConsoleDebug.cpp` deleted (`git rm`)
- [x] All `#include "ErrorReport.h"` replaced — PCH includes `MuLogger.h`
- [x] All `#include "muConsoleDebug.h"` removed
- [x] `extern CErrorReport g_ErrorReport;` declarations removed
- [x] `g_errorReportFd` moved to `mu::log::` namespace in MuLogger
- [x] Build passes with 0 errors after deletions
- [x] `AC-9 [7-10-1]: ErrorReport.h is deleted` test PASSES
- [x] `AC-9 [7-10-1]: muConsoleDebug.h is deleted` test PASSES

### Phase 8: Runtime Log-Level Control (AC-10)

- [x] `$loglevel <logger> <level>` command handler added in `MuConsoleCommands.cpp`
- [x] `$loggers` command lists all active loggers and current levels
- [x] `mu::log::SetLevel()` and `mu::log::ListLoggers()` API added to MuLogger

### Phase 9: Tests (AC-11)

- [x] `tests/core/test_mu_logger.cpp` — all test cases PASS (31 assertions in 10 test cases with [7-10-1] tag)
- [x] `tests/core/test_logging_migration_7_10_1.cpp` — all test cases PASS
- [x] `tests/core/test_error_report.cpp` — rewritten for MuSystemInfo (2 test cases, 4 assertions PASS)
- [x] `AC-11 [7-10-1]: Level filtering` test passes
- [x] `AC-11 [7-10-1]: Named loggers are isolated` test passes
- [x] `AC-11 [7-10-1]: All named loggers are retrievable` test passes

### Phase 10: Documentation (AC-STD-3)

- [x] `CLAUDE.md` logging convention updated — references spdlog/MuLogger
- [x] `docs/development-standards.md` §2 (Error Handling & Logging) rewritten with spdlog patterns, level guide, runtime control

---

## Standard AC Verification

- [x] **AC-STD-1**: Code standards: `#pragma once`, `nullptr`, `std::unique_ptr`, no `new`/`delete`, `std::filesystem::path` for log dir, `[[nodiscard]]` on `mu::log::Get()`
- [x] **AC-STD-2**: Catch2 tests exist and pass: `test_mu_logger.cpp` + `test_logging_migration_7_10_1.cpp` + `test_error_report.cpp`
- [x] **AC-STD-3**: Documentation: CLAUDE.md + development-standards.md §2 updated
- [x] **AC-STD-11**: Flow code `VS0-CORE-MIGRATE-LOGGING` in MuLogger.h/cpp headers
- [x] **AC-STD-13**: Quality gate passes: `./ctl check` (format-check + build) → 0 errors
- [x] **AC-STD-15**: No incomplete rebase, no force-push
- [x] **AC-STD-16**: Correct test infrastructure: Catch2 + CTest (no mocking, no Win32 in tests)
- [x] **AC-VAL-2**: Test files cover AC-1 through AC-11
- [x] **AC-VAL-6**: Flow code `VS0-CORE-MIGRATE-LOGGING` in source headers

---

## Verification Commands

Run these after implementation to confirm all migration counts are zero:

```bash
# AC-5: No g_ErrorReport references (expect 0 matches)
grep -rn "g_ErrorReport" MuMain/src/source --include="*.cpp" --include="*.h" | wc -l

# AC-6: No LOG_CALL macro uses (expect 0 matches)
grep -rn "LOG_CALL\b" MuMain/src/source --include="*.cpp" --include="*.h" | wc -l

# AC-7: No g_ConsoleDebug references (expect 0 matches)
grep -rn "g_ConsoleDebug" MuMain/src/source --include="*.cpp" --include="*.h" | wc -l

# AC-8: No fprintf(stderr) calls (expect 0 matches)
grep -rn 'fprintf(stderr' MuMain/src/source --include="*.cpp" | wc -l

# AC-9: No ErrorReport.h include (expect 0 matches)
grep -rn '"ErrorReport.h"' MuMain/src/source --include="*.cpp" --include="*.h" | wc -l

# AC-9: No muConsoleDebug.h include (expect 0 matches)
grep -rn '"muConsoleDebug.h"' MuMain/src/source --include="*.cpp" --include="*.h" | wc -l

# Run all mu_logger tests
ctest --test-dir MuMain/build -R mu_logger -V

# Full quality gate
./ctl check
```

---

## Test Files (GREEN Phase)

| File | AC Coverage | State |
|------|-------------|-------|
| `MuMain/tests/core/test_mu_logger.cpp` | AC-2, AC-3, AC-11 | ALL PASS |
| `MuMain/tests/core/test_logging_migration_7_10_1.cpp` | AC-1, AC-9 | ALL PASS |
| `MuMain/tests/core/test_error_report.cpp` | AC-8 (MuSystemInfo) | ALL PASS |

**Implementation Checklist Complete**: All items `[x]` (done).
