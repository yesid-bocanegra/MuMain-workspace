# Test Scenarios: Story 3.4.1 — Connection Error Messaging & Graceful Degradation

**Generated:** 2026-03-08
**Story:** 3.4.1 Connection Error Messaging & Graceful Degradation
**Flow Code:** VS1-NET-ERROR-MESSAGING
**Project:** MuMain-workspace

These scenarios cover validation of Story 3.4.1 acceptance criteria.
Automated tests (Catch2 unit tests, CMake ATDD script) are in `MuMain/tests/`.
Manual validation scenarios (AC-VAL-1, AC-VAL-2) require a target platform build
with the game running.

---

## AC-1: Library-Not-Found Message

### Scenario 1: Dialog appears when ClientLibrary is absent (AC-VAL-1)

- **Prerequisites:** Game built with `-DMU_ENABLE_DOTNET=ON`; `ClientLibrary.dll/.so` removed from expected path
- **Given:** Game binary present but no ClientLibrary at `g_dotnetLibPath`
- **When:** Game starts and `IsManagedLibraryAvailable()` runs
- **Then:**
  - `MuError.log` contains `NET: Network library not found at <path>. Build ClientLibrary for <platform> or check build docs.`
  - Dialog box titled "Network Error" appears with the same message text
  - Dialog appears ONLY ONCE per session (not repeatedly)
- **Automated:** `TEST_CASE("AC-1: FormatLibraryNotFoundMessage includes path and platform")` — GREEN
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 2: Platform string resolves correctly per OS

- **Given:** Game built on Linux, macOS, or Windows
- **When:** `ReportDotNetError` formats the library-not-found message
- **Then:** `platform` string is "Linux", "macOS", or "Windows" respectively
- **Automated:** Unit test checks path and platform substitution; compile-time `#if defined(__linux__)` logic verified structurally
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-2: Symbol-Not-Found Message

### Scenario 3: Dialog appears when function symbol is missing (AC-VAL-1)

- **Prerequisites:** ClientLibrary present but built from a mismatched version (missing `ConnectionManager_Connect`)
- **Given:** `mu::platform::Load` succeeds but `mu::platform::GetSymbol("ConnectionManager_Connect")` returns null
- **When:** `LoadManagedSymbol<>()` runs in `Connection::Connection()`
- **Then:**
  - `MuError.log` contains `NET: Network library loaded but function ConnectionManager_Connect not found. Version mismatch?`
  - Dialog box titled "Network Error" appears with the same message text
  - Dialog appears ONLY ONCE per session
- **Automated:** `TEST_CASE("AC-2: FormatSymbolNotFoundMessage includes function name")` — GREEN
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-3: Connect-Fail Message with Address and Port

### Scenario 4: Connect-fail dialog shows address and port (AC-VAL-1)

- **Prerequisites:** Game built and running; a non-existent server address configured (e.g., `127.0.0.1:55901`)
- **Given:** `WSclient.cpp::CreateSocket()` runs with a non-reachable server
- **When:** `SocketClient->IsConnected()` returns false
- **Then:**
  - `MuError.log` contains `NET: Cannot connect to <address>:<port>. Server may be offline.`
  - Dialog box titled "Connection Error" appears with the same message text
  - Existing `CUIMng::Instance().PopUpMsgWin(MESSAGE_SERVER_LOST)` popup still appears
  - Game remains stable (no crash)
- **Edge Case:** Port 0 or unusual addresses (IPv6) should not crash
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-4 & AC-5: Reserved Message Templates (Structural Validation Only)

### Scenario 5: Protocol mismatch template exists in Connection.cpp

- **Given:** `Connection.cpp` source file
- **When:** Reviewed manually or by grep
- **Then:** String `"Server handshake failed. Check OpenMU version compatibility."` is present as comment or string constant
- **Note:** Not triggered in this story; this is a forward-compatibility template
- **Status:** [ ] Not Verified / [ ] Verified

### Scenario 6: Auth failure template exists in Connection.cpp

- **Given:** `Connection.cpp` source file
- **When:** Reviewed manually or by grep
- **Then:** String `"Login failed. Check credentials."` is present as comment or string constant
- **Note:** Not triggered in this story; this is a forward-compatibility template
- **Status:** [ ] Not Verified / [ ] Verified

---

## AC-6: Graceful Degradation — No Crash

### Scenario 7: Game launches without ClientLibrary (AC-VAL-2)

- **Prerequisites:** Game built with `-DMU_ENABLE_DOTNET=ON`; `ClientLibrary.dll/.so` absent
- **Given:** Game starts with no ClientLibrary
- **When:** Main game loop runs (rendering, input, UI)
- **Then:**
  - Game renders the main window without crashing
  - Network features are simply absent (cannot connect to server)
  - `SocketClient == nullptr` guard in `WSclient.cpp` prevents null-deref
  - `dotnet_connect` etc. are null; null guards in `Connection.cpp` prevent UB
  - Error dialog appears once (from `IsManagedLibraryAvailable()`)
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-7: Dual Output + Once-Per-Session Guard

### Scenario 8: Multiple errors trigger only one dialog (AC-VAL-1)

- **Prerequisites:** Game configured to trigger multiple `ReportDotNetError` calls
- **Given:** Both `IsManagedLibraryAvailable()` and `LoadManagedSymbol<>()` fail
- **When:** `g_dotnetErrorDisplayed` guard activates on first call
- **Then:**
  - First call: both `MuError.log` entry AND dialog appear
  - Subsequent calls: only `MuError.log` entry, no additional dialog
  - `g_dotnetErrorDisplayed` stays `true` for entire session
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-STD-11: Flow Code Traceability

### Scenario 9: VS1-NET-ERROR-MESSAGING present in required files (Automated)

- **Given:** `Connection.cpp` and `test_connection_error_messages.cpp`
- **When:** `cmake -P MuMain/tests/build/test_ac_std11_flow_code_3_4_1.cmake` runs
- **Then:** Exit code 0, both files contain `VS1-NET-ERROR-MESSAGING` in their first 1000 characters
- **Automated:** CMake script `test_ac_std11_flow_code_3_4_1.cmake` — PASSED
- **Status:** [x] Passed

---

## Edge Cases and Error Scenarios

| Scenario | Input | Expected Behavior |
|----------|-------|-------------------|
| Null library path | `g_dotnetLibPath` is empty string | Message shows empty path; no crash |
| Null function name | `LoadManagedSymbol<T>(nullptr)` | `FormatSymbolNotFoundMessage(nullptr)` returns "unknown" placeholder |
| Null platform const | `platformName` is nullptr | `FormatLibraryNotFoundMessage(path, nullptr)` returns "Unknown" placeholder |
| Rapid reconnect attempts | Multiple `CreateSocket()` calls in quick succession | AC-3 dialog shown on first failure; subsequent failures log-only if guard fires |
| Very long library path | Path > 200 chars | String concat succeeds; dialog truncates at OS level if needed |

---

## Prerequisites Summary

| Prerequisite | Required For | Notes |
|-------------|-------------|-------|
| Target platform build (Win/Linux/macOS) | All manual AC-VAL scenarios | macOS blocked until EPIC-2 |
| Game binary with `-DMU_ENABLE_DOTNET=ON` | AC-1, AC-2, AC-6, AC-7 | Default for full builds |
| Non-existent server address configured | AC-3 | Edit game config or use `127.0.0.1:55901` |
| Mismatched ClientLibrary version | AC-2 | Rename an export to simulate symbol miss |
| Catch2 MuTests binary built | Automated AC-1, AC-2 | `cmake --build ... --target MuTests` |

---

_Test scenarios generated by dev-story workflow — 2026-03-08_
