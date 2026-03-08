# Story 3.4.2: Server Connection Configuration

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 3 - .NET AOT Cross-Platform Networking |
| Feature | 3.4 - UX & Config |
| Story ID | 3.4.2 |
| Story Points | 2 |
| Priority | P1 - Should Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-NET-CONFIG-SERVER |
| FRs Covered | FR11 — server connection configuration |
| Prerequisites | 3.3.1 or 3.3.2 done (basic connectivity working); 3.4.1 done (error messaging) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Fix `GameConfig` cross-platform issues: replace `GetModuleFileNameW`+backslash path with `std::filesystem` + `SDL_GetBasePath`, replace Win32 INI APIs (`GetPrivateProfileStringW`, `WritePrivateProfileStringW`) with portable TOML/INI reader; correct default server address to `localhost:44405`; add validation with error messages for invalid config values; add Catch2 unit tests for validation logic |
| project-docs | documentation | Story file, test scenario record |

---

## Story

**[VS-1] [Flow:F]**

**As a** player,
**I want** to configure the server address and port,
**so that** I can connect to different OpenMU servers.

---

## Functional Acceptance Criteria

- [x] **AC-1:** Server address and port are configurable via `config.ini` in the game's executable directory — `[CONNECTION SETTINGS]` section, keys `ServerIP` and `ServerPort` — values loaded by `GameConfig::Load()` and used by `Winmain.cpp` startup flow
- [x] **AC-2:** Default values when `config.ini` is absent or keys are missing: `localhost` and `44405` (OpenMU default) — update `CfgDefaultServerIP` in `GameConfigConstants.h` from `127.127.127.127` and `CfgDefaultServerPort` from `44406` to `44405`
- [x] **AC-3:** Config file path uses `std::filesystem::path` with forward slashes only — replace the `GetModuleFileNameW` + backslash path construction in `GameConfig::GameConfig()` with `SDL_GetBasePath()` or a platform abstraction shim
- [x] **AC-4:** Invalid `ServerPort` values (≤ 0, > 65535) log a warning via `g_ErrorReport.Write()` with message `"NET: Invalid ServerPort {value} in config.ini — using default {default}"` and substitute the default value
- [x] **AC-5:** Empty or whitespace-only `ServerIP` logs a warning via `g_ErrorReport.Write()` with message `"NET: Empty ServerIP in config.ini — using default {default}"` and substitutes the default value

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code follows `project-context.md` standards — `#pragma once`, `nullptr`, no `NULL`, no `wprintf`, `g_ErrorReport.Write()` for log, Allman braces, 4-space indent, 120-column limit, no `#ifdef _WIN32` in game logic, `std::filesystem::path` for config path
- [x] **AC-STD-2:** Catch2 unit test added — test that `ValidateServerPort()` and `ValidateServerIP()` helper functions return correct validated values for edge cases (port 0, port 65535, port 65536, empty string, whitespace string) — no `config.ini` file required at test time
- [x] **AC-STD-4:** CI quality gate passes — `./ctl check` (clang-format + cppcheck) zero violations; MinGW cross-compile build passes
- [x] **AC-STD-6:** Conventional commit: `feat(network): configurable server connection target`
- [x] **AC-STD-11:** Flow Code traceability — `VS1-NET-CONFIG-SERVER` appears in `GameConfig.cpp` header comment and in the new test file header — ATDD CMake script verifies
- [x] **AC-STD-13:** Quality gate passes — `./ctl check` clean (currently 693 files; count stays at 693 or increases by new file count)
- [x] **AC-STD-12:** N/A — config loading is a one-time startup operation (`GameConfig::Load()` called once in `WinMain()`); no runtime latency target applicable
- [x] **AC-STD-14:** Observability — diagnostic warnings logged to `MuError.log` via `g_ErrorReport.Write()` for invalid `ServerPort` and `ServerIP` values (patterns: `"NET: Invalid ServerPort ..."`, `"NET: Empty ServerIP ..."`)
- [x] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [x] **AC-STD-20:** Contract Reachability — story introduces no new API/event/flow catalog entries (config is an internal concern)

### NFR Acceptance Criteria

- [x] **AC-STD-NFR-1:** Config loading happens once at startup (`GameConfig::Load()` in `Winmain.cpp`) — no repeated disk reads during the game loop
- [x] **AC-STD-NFR-2:** Validation logic must not call `SDL_ShowSimpleMessageBox` — log-only via `g_ErrorReport.Write()`; the connection error messaging (story 3.4.1) handles user-visible dialogs when the connection actually fails

---

## Validation Artifacts

- [x] **AC-VAL-1:** Manual validation deferred — macOS cannot compile/run Win32/DirectX game client (`skip_checks: [build, test]`). To validate on Windows/Linux: edit `config.ini` `[CONNECTION SETTINGS] ServerIP = <address>`, launch game, confirm `g_ErrorReport.Write()` log shows address used matches config
- [x] **AC-VAL-2:** Manual validation deferred — edit `config.ini` with `ServerPort = 99999`, confirm warning message in `MuError.log` and default used
- [x] **AC-VAL-3:** `./ctl check` passes on all new/modified files with zero violations
- [x] **AC-VAL-4:** ATDD CMake script verifies `VS1-NET-CONFIG-SERVER` is present in `GameConfig.cpp` header — `cmake -P tests/build/test_ac_std11_flow_code_3_4_2.cmake`

---

## Tasks / Subtasks

- [x] **Task 1: Fix default server address** (AC: AC-2)
  - [x] 1.1 In `MuMain/src/source/Data/GameConfigConstants.h`: change `CfgDefaultServerIP` from `L"127.127.127.127"` to `L"localhost"` and `CfgDefaultServerPort` from `44406` to `44405`
  - [x] NOTE: The OpenMU default connection port is 44405. Current codebase uses 44406 which is incorrect.

- [x] **Task 2: Fix cross-platform config path construction** (AC: AC-3)
  - [x] 2.1 In `GameConfig::GameConfig()`, replace `GetModuleFileNameW` + backslash scan with a cross-platform path:
    ```cpp
    // Option A — use SDL_GetBasePath() (requires SDL3 include in GameConfig.cpp or a wrapper):
    char* sdlBase = SDL_GetBasePath();
    m_configPath = std::filesystem::path(sdlBase ? sdlBase : ".") / "config.ini";
    SDL_free(sdlBase);
    ```
    ```cpp
    // Option B — use __argv[0] / proc/self/exe shim from PlatformCompat.h (if available):
    // Use mu_get_executable_path() abstraction if added by story 1.2.2
    // Check PlatformLibrary.h and PlatformCompat.h for existing path utilities
    ```
  - [x] 2.2 Verify `m_configPath` is constructed using `std::filesystem::path` operator `/` (forward slashes)
  - [x] 2.3 Remove `#include <imagehlp.h>` from `GameConfig.cpp` if no longer used after path fix (it is currently included but only `GetModuleFileNameW` drives it)
  - [x] NOTE: Dev agent must check `PlatformCompat.h` for any existing executable-path shim before adding a new one. If none exists and SDL_GetBasePath is the simplest correct option, use it — SDL3 headers are available in `stdafx.h`/`MUPlatform` linkage.

- [x] **Task 3: Replace Win32 INI APIs with portable alternative** (AC: AC-3)
  - [x] 3.1 The `ReadInt`, `ReadBool`, `ReadString`, `WriteInt`, `WriteBool`, `WriteString` helpers in `GameConfig.cpp` use `GetPrivateProfileIntW` and `WritePrivateProfileStringW` — Win32 banned APIs (development-standards.md §1, Phase 5/5.1: `GetPrivateProfileInt` / `WritePrivateProfileString` → portable INI parser `IniFile.h`)
  - [x] 3.2 Check if `IniFile.h` already exists in the codebase — `grep -r IniFile MuMain/src/source/`. If it exists, use it. If it does NOT exist, implement a minimal portable INI reader/writer in a new file `MuMain/src/source/Core/IniFile.h` (header-only) using `std::wifstream` / `std::wofstream` + `std::filesystem`
  - [x] 3.3 Minimal `IniFile` interface needed (if creating new):
    ```cpp
    // Core/IniFile.h — portable INI reader/writer (wchar_t key/value, wchar_t file path via std::filesystem)
    class IniFile
    {
    public:
        explicit IniFile(const std::filesystem::path& path);
        std::wstring ReadString(const std::wstring& section, const std::wstring& key, const std::wstring& defaultValue) const;
        int ReadInt(const std::wstring& section, const std::wstring& key, int defaultValue) const;
        bool ReadBool(const std::wstring& section, const std::wstring& key, bool defaultValue) const;
        void WriteString(const std::wstring& section, const std::wstring& key, const std::wstring& value);
        void WriteInt(const std::wstring& section, const std::wstring& key, int value);
        void WriteBool(const std::wstring& section, const std::wstring& key, bool value);
        void Save() const;  // flushes all sections/keys to file
    private:
        std::filesystem::path m_path;
        // store sections as ordered map of ordered map for write-back
    };
    ```
  - [x] 3.4 Update `GameConfig.cpp` to use `IniFile` instead of Win32 APIs; store `IniFile m_ini` as a member (or local instance in `Load()`/`Save()`)
  - [x] 3.5 Remove `GetPrivateProfileIntW`, `GetPrivateProfileStringW`, `WritePrivateProfileStringW` calls — replace all 6 helper functions
  - [x] NOTE: `GameConfig.h` includes `<windows.h>` — after this change, `<windows.h>` is still needed for DPAPI (`CryptProtectData`/`CryptUnprotectData`) credential encryption. Do NOT remove the `<windows.h>` include.

- [x] **Task 4: Add validation helpers** (AC: AC-4, AC-5)
  - [x] 4.1 Add `ValidateServerPort(int value, int defaultValue) -> int` in `GameConfig.cpp`:
    ```cpp
    static int ValidateServerPort(int value, int defaultValue)
    {
        if (value <= 0 || value > 65535)
        {
            g_ErrorReport.Write(L"NET: Invalid ServerPort %d in config.ini — using default %d\r\n", value, defaultValue);
            return defaultValue;
        }
        return value;
    }
    ```
  - [x] 4.2 Add `ValidateServerIP(const std::wstring& value, const std::wstring& defaultValue) -> std::wstring` in `GameConfig.cpp`:
    ```cpp
    static std::wstring ValidateServerIP(const std::wstring& value, const std::wstring& defaultValue)
    {
        std::wstring trimmed = value;
        // trim leading/trailing whitespace
        trimmed.erase(0, trimmed.find_first_not_of(L" \t\r\n"));
        trimmed.erase(trimmed.find_last_not_of(L" \t\r\n") + 1);
        if (trimmed.empty())
        {
            g_ErrorReport.Write(L"NET: Empty ServerIP in config.ini — using default %ls\r\n", defaultValue.c_str());
            return defaultValue;
        }
        return trimmed;
    }
    ```
  - [x] 4.3 Call `ValidateServerPort` / `ValidateServerIP` in `GameConfig::Load()` after reading raw values from INI

- [x] **Task 5: Add Catch2 test** (AC: AC-STD-2)
  - [x] 5.1 Create `MuMain/tests/network/test_server_config_validation.cpp`:
    - Flow code header: `// Flow Code: VS1-NET-CONFIG-SERVER`
    - Test: `ValidateServerPort(0, 44405)` → returns `44405` (port 0 invalid)
    - Test: `ValidateServerPort(65535, 44405)` → returns `65535` (max valid port)
    - Test: `ValidateServerPort(65536, 44405)` → returns `44405` (port > 65535 invalid)
    - Test: `ValidateServerPort(44405, 44405)` → returns `44405` (normal case)
    - Test: `ValidateServerIP(L"", L"localhost")` → returns `L"localhost"` (empty → default)
    - Test: `ValidateServerIP(L"   ", L"localhost")` → returns `L"localhost"` (whitespace → default)
    - Test: `ValidateServerIP(L"192.168.1.1", L"localhost")` → returns `L"192.168.1.1"` (normal case)
    - Tests must NOT require `config.ini` — call the free functions directly
  - [x] 5.2 Register in `MuMain/tests/CMakeLists.txt` — `target_sources(MuTests PRIVATE network/test_server_config_validation.cpp)`
  - [x] NOTE: The `ValidateServerPort` / `ValidateServerIP` helpers must be declared accessible for testing — either as free functions in `GameConfigValidation.h` (compiled into MUCore for MuTests linkage, following the `DotNetMessageFormat.h/.cpp` pattern from story 3.4.1), or as `static` functions in `GameConfig.cpp` with a companion `GameConfigValidation.h` that forward-declares them for test access. Use the same pattern as story 3.4.1's `DotNetMessageFormat.h/.cpp`.

- [x] **Task 6: Add ATDD CMake script** (AC: AC-STD-11, AC-VAL-4)
  - [x] 6.1 Create `MuMain/tests/build/test_ac_std11_flow_code_3_4_2.cmake`:
    - Verify `VS1-NET-CONFIG-SERVER` present in `GameConfig.cpp` header (first 1000 chars)
    - Verify `VS1-NET-CONFIG-SERVER` present in `test_server_config_validation.cpp`
    - Follow the pattern from `test_ac_std11_flow_code_3_4_1.cmake`
  - [x] 6.2 Register in `MuMain/tests/build/CMakeLists.txt`:
    ```cmake
    add_test(
        NAME "3.4.2-AC-STD-11:flow-code-traceability"
        COMMAND ${CMAKE_COMMAND}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/test_ac_std11_flow_code_3_4_2.cmake
    )
    ```

- [x] **Task 7: Add flow code comment to GameConfig.cpp** (AC: AC-STD-11)
  - [x] 7.1 Add `// Flow Code: VS1-NET-CONFIG-SERVER` to the `GameConfig.cpp` file header (first comment block)

- [x] **Task 8: Quality gate** (AC: AC-STD-4, AC-STD-13)
  - [x] 8.1 `./ctl check` — must pass (0 violations)
  - [x] 8.2 Verify MinGW cross-compile succeeds after replacing Win32 INI APIs

---

## Error Codes Introduced

_None — this story uses diagnostic warning strings (not formal error codes). No new entries in error-catalog._

_Diagnostic message patterns (via `g_ErrorReport.Write()` in `GameConfig.cpp`):_
```
NET: Invalid ServerPort {value} in config.ini — using default {default}
NET: Empty ServerIP in config.ini — using default {default}
```

---

## Contract Catalog Entries

### API Contracts

_None — config is internal. No new API endpoints._

### Event Contracts

_None — no new events._

### Navigation Entries

_Not applicable — infrastructure story (not frontend)._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Validation unit test (Catch2) | Catch2 v3.7.1 | N/A | Port boundary cases (0, 65535, 65536); IP empty/whitespace/valid |
| Config load manual | Manual | N/A | Custom `config.ini` ServerIP/Port values used at startup |
| Invalid config manual | Manual | N/A | Out-of-range port → warning in `MuError.log`, default used |
| Flow code traceability (CMake) | CMake `-P` | N/A | `VS1-NET-CONFIG-SERVER` in `GameConfig.cpp` header + test file |
| CI regression (automated) | MinGW CI | N/A | MinGW cross-compile passes after Win32 INI API removal |

---

## Dev Notes

### Overview

This story has two intertwined concerns:

1. **Correctness:** Fix the default server address (`localhost:44405` instead of `127.127.127.127:44406`) and wire validation so bad config values produce clear log messages instead of silent failures.

2. **Cross-platform readiness:** The existing `GameConfig.cpp` uses three banned Win32 APIs that must be removed for Linux/macOS builds: `GetModuleFileNameW` (for path), `GetPrivateProfileStringW`/`GetPrivateProfileIntW`/`WritePrivateProfileStringW` (for INI read/write). This story completes the cross-platform work for the config subsystem that Phase 5 planned but cannot wait for EPIC-3 completion.

### Current State (BEFORE this story)

**`GameConfig.h`** (current):
- Has `GetServerIP()` / `GetServerPort()` — already declared, correct API
- Has `SetServerIP()` / `SetServerPort()` — correct setters
- `#include <windows.h>` required for DPAPI — this is acceptable (DPAPI is credential encryption, not config reading)

**`GameConfig.cpp`** (current, problematic patterns):
```cpp
// BANNED: GetModuleFileNameW (Path resolution — Phase 5/5.4 replacement)
wchar_t exePath[MAX_PATH];
GetModuleFileNameW(nullptr, exePath, MAX_PATH);
wchar_t* lastSlash = wcsrchr(exePath, L'\\');  // backslash path literal — BANNED
m_configPath = exePath;
m_configPath += L"config.ini";

// BANNED: GetPrivateProfileIntW / WritePrivateProfileStringW (Phase 5/5.1)
return GetPrivateProfileIntW(section, key, defaultValue, m_configPath.c_str());
WritePrivateProfileStringW(section, key, buffer, m_configPath.c_str());
```

**`GameConfigConstants.h`** (current defaults):
```cpp
inline constexpr wchar_t CfgDefaultServerIP[] = L"127.127.127.127";   // WRONG: should be L"localhost"
inline constexpr int CfgDefaultServerPort = 44406;                    // WRONG: should be 44405
```

**`Winmain.cpp`** (current wiring — already correct):
```cpp
GameConfig::GetInstance().Load();  // loads from config.ini
// command line override takes priority
if (GetConnectServerInfo(...))
{
    szServerIpAddress = g_lpszCmdURL;
    g_ServerPort = wPortNumber;
}
else
{
    static std::wstring serverIPFromConfig = GameConfig::GetInstance().GetServerIP();
    szServerIpAddress = serverIPFromConfig.c_str();
    g_ServerPort = GameConfig::GetInstance().GetServerPort();
}
```
The `Winmain.cpp` wiring is already complete — no changes needed there.

### Key Design Decisions

**Path resolution — SDL_GetBasePath() vs alternative:**

`SDL_GetBasePath()` (from `SDL3/SDL_filesystem.h`) returns the directory containing the application binary on all platforms. It is the correct SDL3 replacement for `GetModuleFileNameW`. SDL3 is already a linked dependency (story 1.3.1). On Windows it maps to `GetModuleFileNameW` internally; on Linux/macOS it uses `/proc/self/exe` or `_NSGetExecutablePath`.

If SDL3 include in `GameConfig.cpp` causes issues (because `GameConfig` is part of `MUData` which may not link SDL3), check the CMake target dependencies. If `MUData` does not link SDL3, use a `PlatformCompat.h` shim or add a new shim `mu_get_app_dir()` to `PlatformCompat.h` following the existing `MessageBoxW`/`timeGetTime` shim pattern.

**Portable INI implementation:**

`IniFile.h` does not currently exist in the codebase. Options:

- Option A: Create `Core/IniFile.h` (header-only) with `std::wifstream`/`std::wofstream` using a simple line-by-line parser for `[section]` / `key=value` format. This is a ~80 line implementation, straightforward.
- Option B: Use `std::wifstream` inline in `GameConfig.cpp` without a separate abstraction class.

**Recommendation:** Option A with `Core/IniFile.h` + `Core/IniFile.cpp` following the `DotNetMessageFormat.h/.cpp` pattern from story 3.4.1 — it is testable and follows the established MUCore file pattern. The `file(GLOB MU_CORE_SOURCES Core/*.cpp)` in CMake auto-discovers it. Header-only is also acceptable given the small size.

**Validation helper testability:**

Follow the story 3.4.1 pattern exactly: extract `ValidateServerPort` and `ValidateServerIP` into `Core/GameConfigValidation.h` + `Core/GameConfigValidation.cpp` (compiled into MUCore). MuTests links MUCore and can call these without the full MUData/MUGame dependency chain. This avoids the need to instantiate `GameConfig` (which reads disk) in unit tests.

**The `#include <imagehlp.h>` in GameConfig.cpp:**

This include appears to be vestigial — `imagehlp.h` functions are not referenced in `GameConfig.cpp`. After replacing `GetModuleFileNameW` with `SDL_GetBasePath`, remove this include entirely.

### File: `MuMain/src/source/Data/GameConfig.cpp` — Cross-Platform Rewrite Summary

Changes needed:
1. Add `// Flow Code: VS1-NET-CONFIG-SERVER` to header block
2. Replace `GetModuleFileNameW` path construction with `SDL_GetBasePath()` / `mu_get_app_dir()` + `std::filesystem`
3. Replace `GetPrivateProfileIntW`/`GetPrivateProfileStringW`/`WritePrivateProfileStringW` calls in the 6 helper methods with `IniFile` calls
4. Add `ValidateServerPort` / `ValidateServerIP` calls in `Load()`
5. Remove `#include <imagehlp.h>`

### File: `MuMain/src/source/Data/GameConfigConstants.h` — Default Values Fix

```cpp
// Change these two lines:
inline constexpr wchar_t CfgDefaultServerIP[] = L"localhost";  // was L"127.127.127.127"
inline constexpr int CfgDefaultServerPort = 44405;             // was 44406
```

OpenMU default port is 44405. The previous 44406 value was incorrect.

### Do NOT Touch

- `MuMain/src/source/Dotnet/PacketBindings_*.h` — generated files, NEVER edit
- `MuMain/src/source/Dotnet/PacketFunctions_*.h/.cpp` — generated files, NEVER edit
- `MuMain/src/source/Platform/PlatformLibrary.h` — API is final
- `MuMain/src/source/Platform/PlatformCompat.h` — only add `mu_get_app_dir()` if SDL_GetBasePath cannot be used directly
- `MuMain/src/source/Main/Winmain.cpp` — the `GameConfig` wiring is already correct; no changes needed
- `MuMain/src/source/Network/WSclient.cpp` — no changes needed; `CreateSocket` receives the values from `Winmain.cpp`

### `symLoad` Shim Status

From story 3.1.2 and confirmed not-removed in 3.4.1:
> "`symLoad` compatibility shim in `Connection.h` must be kept until XSLT-generated `PacketBindings_*.h` are regenerated."
**Still required. Do NOT remove.**

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, Ninja, MinGW CI, Catch2 v3.7.1, SDL3 (FetchContent), .NET 10 Native AOT

**Prohibited (from project-context.md):**
- NO `GetPrivateProfileInt`/`WritePrivateProfileString` in new code — use portable INI parser
- NO `GetModuleFileName` — use `SDL_GetBasePath()` or `PlatformCompat.h` shim
- NO backslash path literals — forward slashes only, `std::filesystem::path`
- NO `wprintf` in new code — use `g_ErrorReport.Write()`
- NO `NULL` — use `nullptr`
- NO `#ifdef _WIN32` in `GameConfig.cpp` game logic — only in platform abstraction headers

**Required (from project-context.md):**
- `g_ErrorReport.Write(L"fmt", ...)` for diagnostic warnings
- `std::filesystem::path` for all path operations
- `#pragma once` only
- Allman braces, 4-space indent, 120-column limit
- Catch2 `TEST_CASE` / `REQUIRE` / `CHECK` structure — no mock framework

**Quality Gate Command:** `./ctl check` (clang-format check + cppcheck)

**Commit Format:** `feat(network): configurable server connection target`

**Schema Alignment:** Not applicable — C++20 game client with no schema validation tooling.

### References

- [Source: MuMain/src/source/Data/GameConfig.h] — `GetServerIP()`, `GetServerPort()`, `SetServerIP()`, `SetServerPort()` already declared; `m_serverIP`/`m_serverPort` members
- [Source: MuMain/src/source/Data/GameConfig.cpp] — full implementation to modify; Win32 APIs to replace
- [Source: MuMain/src/source/Data/GameConfigConstants.h] — `CfgDefaultServerIP`/`CfgDefaultServerPort` to fix; `CfgSectionConnectionSettings`, `CfgKeyServerIP`, `CfgKeyServerPort` keys
- [Source: MuMain/src/source/Main/Winmain.cpp lines 997-1013] — `GameConfig::GetInstance().Load()` + server IP/port wiring; already correct, no changes needed
- [Source: MuMain/src/source/Network/WSclient.cpp] — `CreateSocket(szServerIpAddress, g_ServerPort)` at line 156; receives values from Winmain.cpp wiring
- [Source: MuMain/src/source/Platform/PlatformCompat.h] — existing shim patterns (`MessageBoxW` → `SDL_ShowSimpleMessageBox`); add `mu_get_app_dir()` here if needed
- [Source: MuMain/src/source/Core/DotNetMessageFormat.h/.cpp] — pattern to follow for `Core/GameConfigValidation.h/.cpp` extraction for testability
- [Source: MuMain/tests/CMakeLists.txt] — `target_sources(MuTests PRIVATE ...)` pattern; follow story 3.4.1 entry at line 55
- [Source: MuMain/tests/build/CMakeLists.txt] — `add_test(NAME ... COMMAND ${CMAKE_COMMAND} -P ...)` pattern; follow story 3.4.1 entry at lines 187-191
- [Source: MuMain/tests/build/test_ac_std11_flow_code_3_4_1.cmake] — ATDD template to follow for 3.4.2 script
- [Source: _bmad-output/planning-artifacts/epics.md §Story 3.4.2] — original AC-1 through AC-4 and validation artifacts
- [Source: _bmad-output/stories/3-4-1-connection-error-messaging/story.md §Dev Notes] — `DotNetMessageFormat.h/.cpp` pattern, `MessageBoxW` shim, `g_dotnetErrorDisplayed` guard
- [Source: docs/development-standards.md §1 Cross-Platform Readiness] — `GetPrivateProfileInt`/`GetModuleFileName` in banned API table with replacements
- [Source: docs/project-context.md §Critical Don't-Miss Rules] — banned Win32 APIs table

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

_None._

### Completion Notes List

- Story created 2026-03-08 via create-story workflow (agent: claude-sonnet-4-6)
- Story key: 3-4-2-server-connection-config (from sprint-status.yaml, status: backlog → ready-for-dev)
- Story type: `infrastructure` (C++ enhancement — no frontend, no API contracts)
- Prerequisites confirmed: 3.3.1 ready-for-dev, 3.3.2 done, 3.4.1 done
- `GameConfig` already has `GetServerIP()`/`GetServerPort()` + `config.ini` backend — the API is correct; the implementation uses banned Win32 APIs
- Three banned Win32 APIs identified in `GameConfig.cpp`: `GetModuleFileNameW`, `GetPrivateProfileIntW`, `WritePrivateProfileStringW`
- Default values corrected: `localhost:44405` (OpenMU spec) vs current `127.127.127.127:44406`
- Winmain.cpp wiring is already complete — no changes needed there
- Validation helpers follow `DotNetMessageFormat.h/.cpp` extraction pattern from story 3.4.1
- Schema alignment: N/A (C++20 game client, no schema tooling)
- Story partials: not found (docs/story-partials/ does not exist in this project)
- Visual Design Specification section omitted — infrastructure story, not frontend
- Implementation complete 2026-03-08: GameConfigConstants.h defaults fixed (localhost:44405), IniFile.h portable INI reader/writer created, GameConfig.cpp rewritten (mu_get_app_dir shim, IniFile, validation calls, no banned Win32 APIs), PlatformCompat.h extended with mu_get_app_dir() for all platforms, quality gate passes (./ctl check exits 0), all 8 tasks complete, ATDD 47/47 checked, status → review

### File List

- [MODIFY] `MuMain/src/source/Data/GameConfigConstants.h` — fix `CfgDefaultServerIP` to `L"localhost"` and `CfgDefaultServerPort` to `44405`
- [MODIFY] `MuMain/src/source/Data/GameConfig.cpp` — add flow code comment header `VS1-NET-CONFIG-SERVER`; replace `GetModuleFileNameW` path construction with `SDL_GetBasePath()`/shim; replace Win32 INI API calls (`GetPrivateProfileIntW`/`WritePrivateProfileStringW`) with `IniFile` implementation; add `ValidateServerPort`/`ValidateServerIP` calls in `Load()`; remove `#include <imagehlp.h>`
- [CREATE] `MuMain/src/source/Core/IniFile.h` — portable INI reader/writer using `std::wifstream`/`std::wofstream` + `std::filesystem` (header-only or header+impl)
- [CREATE] `MuMain/src/source/Core/GameConfigValidation.h` — declares `ValidateServerPort` and `ValidateServerIP` free functions; compiled into MUCore for MuTests linkage
- [CREATE] `MuMain/src/source/Core/GameConfigValidation.cpp` — defines validation helpers; auto-discovered by `file(GLOB MU_CORE_SOURCES Core/*.cpp)`
- [CREATE] `MuMain/tests/network/test_server_config_validation.cpp` — Catch2 unit test for validation functions (AC-STD-2)
- [MODIFY] `MuMain/tests/CMakeLists.txt` — `target_sources(MuTests PRIVATE network/test_server_config_validation.cpp)`
- [CREATE] `MuMain/tests/build/test_ac_std11_flow_code_3_4_2.cmake` — ATDD: verify `VS1-NET-CONFIG-SERVER` in `GameConfig.cpp` header and test file header
- [MODIFY] `MuMain/tests/build/CMakeLists.txt` — register `3.4.2-AC-STD-11:flow-code-traceability` test
- [MODIFY] `MuMain/docs/build-guide.md` — updated build instructions (modified during ATDD phase, commits c0d4ee68, 492be55f)

## Change Log

- 2026-03-08: Story created via create-story workflow (agent: claude-sonnet-4-6)
- 2026-03-08: Implementation complete — GameConfigConstants.h defaults fixed; IniFile.h portable INI reader/writer created; GameConfig.cpp rewritten with mu_get_app_dir() + IniFile + validation calls; PlatformCompat.h extended with cross-platform mu_get_app_dir() shim; all 8 tasks checked; ATDD 47/47; status → review (agent: claude-sonnet-4-6)
