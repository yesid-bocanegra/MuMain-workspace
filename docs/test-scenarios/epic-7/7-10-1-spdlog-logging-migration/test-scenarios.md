# Test Scenarios — Story 7-10-1: spdlog Logging Infrastructure Migration

**Story Key:** 7-10-1
**Flow Code:** VS0-CORE-MIGRATE-LOGGING
**Test Framework:** Catch2 v3.7.1

## Automated Test Files

| File | AC Coverage | Assertions |
|------|------------|------------|
| `tests/core/test_mu_logger.cpp` | AC-2, AC-3, AC-11 | 16 |
| `tests/core/test_logging_migration_7_10_1.cpp` | AC-1, AC-9 | 15 |
| `tests/core/test_error_report.cpp` | AC-9 (rewritten for MuSystemInfo) | 4+ |

## Test Scenarios

### AC-1: spdlog FetchContent Integration
- **Scenario:** spdlog version check — `SPDLOG_VER_MAJOR == 1, SPDLOG_VER_MINOR >= 15`
- **Run:** `./MuTests "[7-10-1]"`

### AC-2: MuLogger Facade
- **Scenario:** `mu::log::Get("core")` returns non-null, identity-stable logger
- **Scenario:** All 6 `MU_LOG_*` macros compile and execute without crash

### AC-3: File Sink
- **Scenario:** `mu::log::Init(dir)` creates `MuError.log`; file sink writes and flushes correctly

### AC-9: Old Infrastructure Deleted
- **Scenario:** `__has_include("ErrorReport.h")` returns false
- **Scenario:** `__has_include("muConsoleDebug.h")` returns false
- **Scenario:** `__has_include("MuLogger.h")` returns true

### AC-11: Logger Behavior
- **Scenario:** Level filtering suppresses messages below threshold
- **Scenario:** Named loggers are isolated (different instances, independent levels)
- **Scenario:** All 11 named loggers (`core`, `network`, `render`, `data`, `gameplay`, `ui`, `audio`, `platform`, `dotnet`, `gameshop`, `scenes`) are retrievable

## Build-Time Regression Tests

| Check | Command | Expected |
|-------|---------|----------|
| No g_ErrorReport refs | `grep -rn "g_ErrorReport" MuMain/src/source` | 0 matches |
| No LOG_CALL refs | `grep -rn "LOG_CALL" MuMain/src/source --include="*.cpp"` | 0 matches |
| No g_ConsoleDebug refs | `grep -rn "g_ConsoleDebug" MuMain/src/source` | 0 matches |
| No fprintf(stderr) refs | `grep -rn "fprintf(stderr" MuMain/src/source` | 0 matches |

## Manual Verification

| AC | Scenario | Verification |
|----|----------|-------------|
| AC-4 | Crash handler fd preserved | `g_errorReportFd` set in Init(), signal handler uses write(fd) |
| AC-10 | `$loglevel render debug` | Interactive command changes logger level at runtime |
| AC-12 | VK spam eliminated | No MU_ERR_INPUT_UNMAPPED_VK messages in log output |
