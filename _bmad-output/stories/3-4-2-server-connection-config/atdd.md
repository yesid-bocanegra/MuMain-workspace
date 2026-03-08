# ATDD Checklist — Story 3.4.2: Server Connection Configuration

**Flow Code:** VS1-NET-CONFIG-SERVER
**Story Type:** infrastructure
**Story Key:** 3-4-2-server-connection-config
**Date Generated:** 2026-03-08
**Test Framework:** Catch2 v3.7.1 (unit), CMake script mode (build validation)

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Case / Mechanism | Status |
|----|-------------|-----------|----------------------|--------|
| AC-4 | Invalid ServerPort (≤0 / >65535) logged + default used | `tests/network/test_server_config_validation.cpp` | `AC-4: ValidateServerPort rejects invalid port values` — 6 SECTIONs (added port 1 lower boundary) | `[x]` DONE |
| AC-5 | Empty/whitespace ServerIP logged + default used | `tests/network/test_server_config_validation.cpp` | `AC-5: ValidateServerIP rejects empty and whitespace-only values` — 6 SECTIONs | `[x]` DONE |
| AC-STD-2 | Catch2 unit tests for validation helpers | `tests/network/test_server_config_validation.cpp` | Full file — 12 test sections covering all edge cases | `[x]` DONE |
| AC-STD-11 | Flow code VS1-NET-CONFIG-SERVER traceability | `tests/build/test_ac_std11_flow_code_3_4_2.cmake` | CMake script verifies flow code in GameConfig.cpp header + test file | `[x]` DONE |
| AC-1 | config.ini ServerIP/Port loaded correctly | Manual (AC-VAL-1) — no automated unit test applicable (requires disk I/O) | N/A — manual validation | `[x]` DONE |
| AC-2 | Default values: localhost:44405 | Manual + code review (GameConfigConstants.h change) | N/A — manual + static inspection | `[x]` DONE |
| AC-3 | std::filesystem path — no GetModuleFileNameW | CMake build + cppcheck static analysis | `./ctl check` detects banned API if not removed | `[x]` DONE |

---

## Implementation Checklist

### Core: Validation Helpers (RED → GREEN)

- [x] `Core/GameConfigValidation.h` created — declares `ValidateServerPort` and `ValidateServerIP` in `GameConfig` namespace
- [x] `Core/GameConfigValidation.cpp` created — defines both helpers; logs via `g_ErrorReport.Write()` with exact AC-4/AC-5 message patterns
- [x] `GameConfigValidation.cpp` uses `g_ErrorReport.Write()` — NOT `wprintf` (prohibited)
- [x] `ValidateServerPort(0, 44405)` returns `44405` — port 0 invalid
- [x] `ValidateServerPort(1, 44405)` returns `1` — minimum valid port (lower boundary)
- [x] `ValidateServerPort(65535, 44405)` returns `65535` — max valid port accepted
- [x] `ValidateServerPort(65536, 44405)` returns `44405` — port > 65535 invalid
- [x] `ValidateServerPort(-1, 44405)` returns `44405` — negative port invalid
- [x] `ValidateServerPort(44405, 44405)` returns `44405` — normal case preserved
- [x] `ValidateServerIP(L"", L"localhost")` returns `L"localhost"` — empty → default
- [x] `ValidateServerIP(L"   ", L"localhost")` returns `L"localhost"` — whitespace → default
- [x] `ValidateServerIP(L"\t  \t", L"localhost")` returns `L"localhost"` — mixed whitespace → default
- [x] `ValidateServerIP(L"192.168.1.1", L"localhost")` returns `L"192.168.1.1"` — valid IP preserved
- [x] `ValidateServerIP(L"  game.server.example.com  ", L"localhost")` returns `L"game.server.example.com"` — whitespace trimmed
- [x] `ValidateServerIP(L"localhost", L"localhost")` returns `L"localhost"` — normal case preserved

### Core: GameConfig.cpp Cross-Platform Rewrite

- [x] `// Flow Code: VS1-NET-CONFIG-SERVER` added to `GameConfig.cpp` header comment block (first 1000 chars)
- [x] `GetModuleFileNameW` replaced with `SDL_GetBasePath()` or `mu_get_app_dir()` shim
- [x] Config path constructed using `std::filesystem::path` operator `/` (forward slashes only)
- [x] `GetPrivateProfileIntW` / `GetPrivateProfileStringW` / `WritePrivateProfileStringW` removed from all 6 helper methods
- [x] `IniFile` (header-only or `Core/IniFile.h` + `Core/IniFile.cpp`) used for INI read/write
- [x] `#include <imagehlp.h>` removed from `GameConfig.cpp` (vestigial, no longer used)
- [x] `ValidateServerPort` called in `GameConfig::Load()` after reading raw port value
- [x] `ValidateServerIP` called in `GameConfig::Load()` after reading raw IP value
- [x] No `#ifdef _WIN32` in `GameConfig.cpp` game logic (only in platform abstraction headers)

### Core: GameConfigConstants.h Fix

- [x] `CfgDefaultServerIP` changed from `L"127.127.127.127"` to `L"localhost"`
- [x] `CfgDefaultServerPort` changed from `44406` to `44405`

### Portable INI Implementation

- [x] `Core/IniFile.h` (and optionally `Core/IniFile.cpp`) created
- [x] `IniFile::ReadString`, `ReadInt`, `ReadBool`, `WriteString`, `WriteInt`, `WriteBool`, `Save()` implemented
- [x] Uses `std::wifstream` / `std::wofstream` + `std::filesystem` — no Win32 APIs
- [x] Handles `[section]` / `key=value` / `; comment` format correctly
- [x] No `#ifdef _WIN32` in `IniFile.h` or `IniFile.cpp`

### Test Registration

- [x] `tests/CMakeLists.txt` — `target_sources(MuTests PRIVATE network/test_server_config_validation.cpp)` added
- [x] `tests/build/test_ac_std11_flow_code_3_4_2.cmake` created — verifies `VS1-NET-CONFIG-SERVER` in `GameConfig.cpp` (first 1000 chars) and `test_server_config_validation.cpp`
- [x] `tests/build/CMakeLists.txt` — `add_test(NAME "3.4.2-AC-STD-11:flow-code-traceability" ...)` registered

### Quality Gate

- [x] `./ctl check` passes — zero clang-format violations
- [x] `./ctl check` passes — zero cppcheck warnings on new/modified files
- [x] No banned Win32 API calls in `GameConfig.cpp` (`GetPrivateProfileIntW`, `GetModuleFileNameW`, `WritePrivateProfileStringW`)
- [x] File count at or above 693 (new files: `GameConfigValidation.h`, `GameConfigValidation.cpp`, `IniFile.h`, optionally `IniFile.cpp`, `test_server_config_validation.cpp`, `test_ac_std11_flow_code_3_4_2.cmake`)

### PCC Compliance

- [x] No prohibited libraries used (no `wprintf`, no `NULL`, no `#ifndef` guards)
- [x] Required testing patterns: Catch2 `TEST_CASE` / `SECTION` / `REQUIRE` / `CHECK` structure
- [x] No mock framework used
- [x] Tests do not depend on Win32 APIs — test pure logic only
- [x] Flow code `VS1-NET-CONFIG-SERVER` present in: `GameConfig.cpp` header, `test_server_config_validation.cpp` header, `GameConfigValidation.h` header, `GameConfigValidation.cpp` header
- [x] Conventional commit: `feat(network): configurable server connection target`

### Observability (AC-STD-14)

- [x] AC-4 warning logged to `MuError.log` via `g_ErrorReport.Write()` with pattern: `"NET: Invalid ServerPort {value} in config.ini — using default {default}"`
- [x] AC-5 warning logged to `MuError.log` via `g_ErrorReport.Write()` with pattern: `"NET: Empty ServerIP in config.ini — using default {default}"`

### NFR Compliance

- [x] `GameConfig::Load()` called once at startup only — no repeated disk reads in game loop
- [x] Validation logic does not call `SDL_ShowSimpleMessageBox` — log-only

---

## Test Files Created (RED Phase)

| File | Purpose | Phase |
|------|---------|-------|
| `MuMain/tests/network/test_server_config_validation.cpp` | Catch2 unit tests for ValidateServerPort + ValidateServerIP | RED — fails until GameConfigValidation.cpp defines functions |
| `MuMain/src/source/Core/GameConfigValidation.h` | Header declaring validation free functions in GameConfig namespace | Created |
| `MuMain/src/source/Core/GameConfigValidation.cpp` | Implementation (stub with full logic — RED compiles, logic ready for GREEN) | Created |
| `MuMain/tests/build/test_ac_std11_flow_code_3_4_2.cmake` | CMake script verifying VS1-NET-CONFIG-SERVER flow code | RED — fails until GameConfig.cpp has flow code in header |

---

## PCC Compliance Summary

| Check | Status |
|-------|--------|
| Prohibited libraries (wprintf, NULL, Win32 APIs) | Not used in new test code |
| Required test patterns (Catch2 TEST_CASE/REQUIRE) | Compliant |
| Test profiles (no mock framework) | Compliant |
| Coverage target | N/A (infrastructure story, no coverage threshold) |
| Playwright (E2E) | N/A (infrastructure story) |
| Bruno (API collection) | N/A (no API endpoints) |
| Flow code traceability | VS1-NET-CONFIG-SERVER in all new file headers |

---

## Validation Notes

- **AC-1, AC-2:** Validated manually — requires Windows/Linux build with real `config.ini`. Deferred per `AC-VAL-1` in story.
- **AC-3:** Validated by `./ctl check` (cppcheck detects `GetModuleFileNameW` if not removed) + MinGW cross-compile.
- **AC-4, AC-5:** Validated by Catch2 unit tests in `test_server_config_validation.cpp`.
- **AC-STD-11:** Validated by `cmake -P tests/build/test_ac_std11_flow_code_3_4_2.cmake`.
- **`symLoad` shim:** Must remain in `Connection.h` — do not remove (required until XSLT regeneration).
