# Code Review — Story 7-10-1: spdlog Logging Infrastructure Migration

**Reviewer:** Claude (adversarial code review)
**Date:** 2026-04-11
**Story Type:** backend_service (infrastructure migration)
**Flow Code:** VS0-CORE-MIGRATE-LOGGING

---

## Quality Gate

**Status:** ✅ PASSED — 2026-04-11
**Run by:** code-review-quality-gate workflow

| Gate | Status | Detail |
|------|--------|--------|
| Backend lint | ✅ PASS | `make -C MuMain lint` — cppcheck clean (723 files, 0 errors) |
| Backend build | ✅ PASS | cmake + ninja Debug build (macOS arm64, Homebrew Clang) |
| Backend coverage | ✅ PASS | No coverage threshold configured yet |
| Backend SonarCloud | N/A | No sonar project key configured in .pcc-config.yaml |
| Frontend | N/A | No frontend components in project |
| Schema alignment | N/A | No frontend/backend API contract |
| App startup | N/A | Game client requires display/GPU — build success is equivalent gate |

**AC Tests:** Skipped (infrastructure/migration story — no API endpoints, no Playwright tests)
**E2E Test Quality:** N/A (no frontend)

**Iterations:** 0 (all checks passed on first run)
**Issues fixed:** 0

---

## Findings

### Finding 1 — HIGH: Uncaught exceptions from std::stof in console commands

**File:** `MuMain/src/source/Core/MuConsoleCommands.cpp`
**Lines:** 97, 117

**Description:**
The `$fps` and `$winmsg` commands use `std::stof()` to parse user-provided strings. `std::stof` throws `std::invalid_argument` when the input is not a valid float and `std::out_of_range` when the value exceeds float range. Since these are interactive debug commands triggered by arbitrary user input in the chat box, malformed input like `$fps abc` or `$fps 9999999999999999999999` will throw an uncaught exception.

The project convention (CLAUDE.md) explicitly states: _"Return codes (no exceptions in game loop)"_. An uncaught exception here would propagate up through the game loop and terminate the process.

**Suggested Fix:**
Wrap `std::stof()` calls in try/catch, or use a non-throwing alternative (e.g., `std::from_chars` which returns an error code):

```cpp
// Option A: try/catch
try {
    auto target_fps = std::stof(fps_str);
    SetTargetFps(target_fps);
} catch (const std::exception&) {
    mu::log::Get("core")->warn("Invalid FPS value: {}", std::string(fps_str.begin(), fps_str.end()));
}

// Option B: std::from_chars (preferred — no exceptions)
float target_fps = 0;
std::string narrow(fps_str.begin(), fps_str.end());
auto [ptr, ec] = std::from_chars(narrow.data(), narrow.data() + narrow.size(), target_fps);
if (ec != std::errc{}) {
    mu::log::Get("core")->warn("Invalid FPS value");
    return true;
}
SetTargetFps(target_fps);
```

---

### Finding 2 — MEDIUM: Silent fallback in Get() masks logger name typos

**File:** `MuMain/src/source/Core/MuLogger.cpp`
**Lines:** 89-98

**Description:**
`mu::log::Get(name)` falls back to the default logger ("core") when the requested logger name is not found. This means a typo like `mu::log::Get("nework")` silently succeeds, returning the core logger. The caller has no way to detect the mistake at runtime.

This design choice trades safety for convenience — there are 59+ source files calling `Get()`, and a crash-on-typo policy would be too aggressive. However, the silent fallback means:
1. Logs from typo'd call sites appear under "core" instead of their intended category
2. `$loglevel` commands targeting the intended logger won't affect these misrouted sites
3. The mistake is invisible in log output (no warning about the fallback)

**Suggested Fix:**
Log a one-time warning when falling back, so typos are discoverable:

```cpp
std::shared_ptr<spdlog::logger> Get(const std::string& name)
{
    auto logger = spdlog::get(name);
    if (logger) return logger;
    auto def = spdlog::default_logger();
    SPDLOG_LOGGER_WARN(def, "Logger '{}' not registered — using default", name);
    return def;
}
```

Consider adding a debug-build assertion or a one-shot warning flag to avoid log spam.

---

### Finding 3 — MEDIUM: Level-filtering test operates on wrong logger

**File:** `MuMain/tests/core/test_mu_logger.cpp`
**Lines:** 176-210

**Description:**
The test case _"AC-11 [7-10-1]: Level filtering suppresses messages below logger threshold"_ calls `mu::log::Get("test_filter")`. Since `"test_filter"` is not one of the 11 registered logger names, `Get()` falls back to the default "core" logger (per Finding 2).

Consequences:
- Line 186: `REQUIRE(logger != nullptr)` is a **vacuous assertion** — it can never fail because `Get()` always returns non-null (it falls back to default)
- Line 189: `logger->set_level(spdlog::level::info)` actually changes the **core** logger's level, not an isolated test logger
- The test still passes because the level-filtering logic works, but it's testing the wrong thing — it should demonstrate that a named logger filters independently

**Suggested Fix:**
Use a registered logger name (e.g., `"audio"` which is unlikely to conflict) or create and register a test-specific logger:

```cpp
auto logger = mu::log::Get("audio"); // Use a real registered logger
// OR: register a test logger before use
auto testLogger = std::make_shared<spdlog::logger>("test_filter", ...);
spdlog::register_logger(testLogger);
```

---

### Finding 4 — MEDIUM: Catch-all enum formatter blocks future specializations

**File:** `MuMain/src/source/Core/MuLogger.h`
**Lines:** 17-25

**Description:**
The generic `fmt::formatter<T>` with `requires std::is_enum_v<T>` is a catch-all formatter that handles ANY enum type by casting to its underlying integer. This is included via `stdafx.h` (PCH), so it applies globally.

While this solves the immediate problem (fmt 11.x removed implicit enum-to-int conversion), it creates a maintenance trap: if a developer later wants to provide a human-readable formatter for a specific enum (e.g., printing `"SCENE_LOGIN"` instead of `3`), the explicit specialization `template<> struct fmt::formatter<SceneType>` will conflict with this constrained partial specialization. The compiler may select the wrong one depending on the overload resolution rules.

**Suggested Fix:**
This is acceptable for now given the 785+ migrated call sites. Document the constraint with a comment:

```cpp
// WARNING: This catch-all formatter applies to ALL enums. To provide a custom
// formatter for a specific enum, you must use a different technique (e.g.,
// a named wrapper type or an ADL-based format_as() function).
```

Alternatively, consider the `format_as()` free-function pattern which has lower priority and doesn't conflict with explicit specializations.

---

### Finding 5 — LOW: Duplicate log messages in MainScene init

**File:** `MuMain/src/source/Scenes/MainScene.cpp`
**Lines:** 134, 136

**Description:**
Two nearly identical messages are logged back-to-back during MainScene initialization:
```
mu::log::Get("scenes")->info("Main Scene init success.");
mu::log::Get("scenes")->info("MainScene Init Success");
```

This appears to be a migration artifact — one line was likely the original `g_ErrorReport.Write` call and the other was added during migration. Both convey the same information with slightly different formatting.

**Suggested Fix:**
Delete one of the two duplicate lines. Keep whichever matches the style of other scene init messages (e.g., `LoginScene.cpp:313` uses `"Login Scene init success."`).

---

### Finding 6 — LOW: string_view::data() assumes null-termination in ListLoggers()

**File:** `MuMain/src/source/Core/MuLogger.cpp`
**Line:** 119

**Description:**
```cpp
result.emplace_back(name, spdlog::level::to_string_view(logger->level()).data());
```

`spdlog::level::to_string_view()` returns a `string_view`. The `.data()` pointer is passed to the `std::string` constructor that takes `const char*`, which reads until a null terminator. While spdlog's internal level strings are static null-terminated arrays (so `.data()` is safe in practice), the C++ standard does not guarantee that `string_view::data()` is null-terminated.

**Suggested Fix:**
Use the explicit `std::string(sv.data(), sv.size())` constructor or convert via `std::string(sv)`:

```cpp
auto sv = spdlog::level::to_string_view(logger->level());
result.emplace_back(name, std::string(sv.data(), sv.size()));
```

---

### Finding 7 — LOW: TOCTOU window in Init() fd close/reopen

**File:** `MuMain/src/source/Core/MuLogger.cpp`
**Lines:** 67-72

**Description:**
During `Init()`, the old file descriptor is closed before the new one is opened:
```cpp
int oldFd = g_errorReportFd;
if (oldFd >= 0) close(oldFd);
g_errorReportFd = open(logPath.string().c_str(), ...);
```

There is a window between `close(oldFd)` and the `open()` call where `g_errorReportFd` still holds the old (now closed) fd value. If a signal fires during this window, the crash handler would `write()` to a closed descriptor.

In practice this is benign because `Init()` runs once at startup before signal handlers are installed (`InstallSignalHandlers()` is called after `Init()`). But if `Init()` is ever called for re-initialization, this becomes a real race.

**Suggested Fix:**
Set `g_errorReportFd = -1` before closing the old fd:
```cpp
int oldFd = g_errorReportFd;
g_errorReportFd = -1;  // Disable crash-handler writes during transition
if (oldFd >= 0) close(oldFd);
g_errorReportFd = open(...);
```

---

## ATDD Coverage

### Coverage Matrix

| AC | ATDD Claim | Actual Coverage | Verdict |
|----|-----------|-----------------|---------|
| AC-1 | test: spdlog version check | `test_logging_migration_7_10_1.cpp:39` — checks `SPDLOG_VER_MAJOR == 1` | ACCURATE |
| AC-2 | test: Get() + macros | `test_mu_logger.cpp:72,104` — 2 test cases | ACCURATE |
| AC-3 | test: file sink writes | `test_mu_logger.cpp:139` — checks MuError.log exists + content | ACCURATE |
| AC-4 | manual: crash handler fd | Appropriate — async-signal-safe behavior can't be unit tested | ACCURATE |
| AC-5 | grep: 0 g_ErrorReport refs | Verification command, not a test file — acceptable for migration | ACCURATE |
| AC-6 | grep: 0 LOG_CALL refs | Verification command, not a test file — acceptable for migration | ACCURATE |
| AC-7 | grep: 0 g_ConsoleDebug refs | Verification command, not a test file — acceptable for migration | ACCURATE |
| AC-8 | grep: 0 fprintf(stderr) refs | Verification command, not a test file — acceptable for migration | ACCURATE |
| AC-9 | test: headers deleted | `test_logging_migration_7_10_1.cpp:64,85,104` — `__has_include` checks | ACCURATE |
| AC-10 | manual: $loglevel command | Appropriate — interactive command requires manual testing | ACCURATE |
| AC-11 | test: level filtering | `test_mu_logger.cpp:176` — **INACCURATE** (see Finding 3: tests fallback logger, not a registered one) | INACCURATE |
| AC-11 | test: multi-logger isolation | `test_mu_logger.cpp:220` — tests core vs network isolation | ACCURATE |
| AC-11 | test: all 11 loggers | `test_mu_logger.cpp:257` — iterates all names | ACCURATE |
| AC-12 | already done | Pre-existing fix, no test needed | ACCURATE |

### ATDD Metadata Discrepancy

The ATDD checklist Phase 9 item 1 states:
> `tests/core/test_mu_logger.cpp — all test cases PASS (31 assertions in 10 test cases with [7-10-1] tag)`

Actual count in `test_mu_logger.cpp`: **6 test cases** (not 10). The total of 10 test cases is correct when counting across **both** test files (6 + 4), but the description incorrectly attributes all 10 to `test_mu_logger.cpp`. This is a minor documentation inaccuracy.

---

## Summary

| Severity | Count | Key Concern |
|----------|-------|-------------|
| BLOCKER | 0 | — |
| HIGH | 1 | Exception safety in user-facing console commands |
| MEDIUM | 3 | Silent fallback masking, test validity, formatter design |
| LOW | 3 | Duplicate logs, fragile string_view usage, fd race window |

**Overall Assessment:** The migration is thorough and well-executed — 785+ call sites replaced with correct logger categories, old infrastructure cleanly deleted, and the spdlog facade design is solid. The HIGH finding (std::stof exceptions) should be addressed before merge. The MEDIUM findings are worth addressing but don't block the migration.
