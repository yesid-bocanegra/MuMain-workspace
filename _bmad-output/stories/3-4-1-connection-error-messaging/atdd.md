# ATDD Checklist — Story 3.4.1: Connection Error Messaging & Graceful Degradation

**Flow Code:** VS1-NET-ERROR-MESSAGING
**Story Type:** infrastructure
**Generated:** 2026-03-08
**Phase:** RED (tests created, fail until implementation complete)

---

## FSM Handoff Summary

| Field | Value |
|-------|-------|
| `story_key` | `3-4-1-connection-error-messaging` |
| `story_type` | `infrastructure` |
| `atdd_checklist_path` | `_bmad-output/stories/3-4-1-connection-error-messaging/atdd.md` |
| `implementation_checklist_complete` | FALSE (all items pending) |

### Test Files Created (RED Phase)

| File | Status | Purpose |
|------|--------|---------|
| `MuMain/tests/network/test_connection_error_messages.cpp` | RED | Catch2 unit tests for AC-1, AC-2 message format helpers |
| `MuMain/tests/build/test_ac_std11_flow_code_3_4_1.cmake` | RED | CMake script — AC-STD-11 flow code traceability in Connection.cpp |

### AC → Test Mapping

| AC | Description | Test Method | File |
|----|-------------|-------------|------|
| AC-1 | Library not found message | `TEST_CASE("AC-1: FormatLibraryNotFoundMessage includes path and platform")` | `test_connection_error_messages.cpp` |
| AC-2 | Symbol not found message | `TEST_CASE("AC-2: FormatSymbolNotFoundMessage includes function name")` | `test_connection_error_messages.cpp` |
| AC-3 | Connect fail with addr+port | Manual validation (AC-VAL-1) | WSclient.cpp enhancement |
| AC-4 | Protocol mismatch template (reserved) | Message template present in Connection.cpp (not triggered) | Manual verification |
| AC-5 | Auth failure template (reserved) | Message template present in Connection.cpp (not triggered) | Manual verification |
| AC-6 | Graceful degradation — no crash | Manual validation (AC-VAL-2) | IsManagedLibraryAvailable() returns false |
| AC-7 | Dual output + once-per-session guard | Manual validation (AC-VAL-1) | g_dotnetErrorDisplayed guard |
| AC-STD-11 | Flow code traceability | `test_ac_std11_flow_code_3_4_1.cmake` | CMake script mode |

---

## Implementation Checklist

### PCC Compliance

- [x] PCC: No prohibited libraries used (no `LoadLibrary`/`GetProcAddress`, no `dlopen`/`dlsym` in game logic, no `wprintf`, no `NULL`, no raw `new`/`delete` in new code)
- [x] PCC: Required patterns applied (`g_ErrorReport.Write()` for log, `MessageBoxW` via `PlatformCompat.h` shim for dialog, `#pragma once`, Allman braces, 4-space indent, no `#ifdef _WIN32` in game logic)
- [x] PCC: Catch2 `TEST_CASE`/`SECTION`/`REQUIRE`/`CHECK` structure — no mock framework
- [x] PCC: Test file does not depend on Win32 APIs — tests pure message formatting logic
- [x] PCC: No exceptions in game loop — error reporting uses return codes

### AC-1: Library-Not-Found Message

- [x] AC-1: `DotNetBridge::FormatLibraryNotFoundMessage(path, platform)` free function extracted and declared in `DotNetBridge` namespace
- [x] AC-1: Message format: `"Network library not found at {path}. Build ClientLibrary for {platform} or check build docs."`
- [x] AC-1: `platform` string resolved via compile-time `#if defined(__linux__)` / `__APPLE__` / `_WIN32` in `Connection.cpp` (implementation file — acceptable)
- [x] AC-1: `g_dotnetLibPath` used as `path` argument in `IsManagedLibraryAvailable()` caller
- [x] AC-1: Catch2 test `TEST_CASE("AC-1: ...")` passes (GREEN)

### AC-2: Symbol-Not-Found Message

- [x] AC-2: `DotNetBridge::FormatSymbolNotFoundMessage(name)` free function extracted and declared in `DotNetBridge` namespace
- [x] AC-2: Message format: `"Network library loaded but function {name} not found. Version mismatch?"`
- [x] AC-2: `DotNetErrorKind` enum added (`LibraryNotFound`, `SymbolNotFound`)
- [x] AC-2: `ReportDotNetError(const char* detail, DotNetErrorKind kind)` signature updated in `Connection.h` and `Connection.cpp`
- [x] AC-2: All callers updated: `IsManagedLibraryAvailable()`, `LoadManagedSymbol<T>()`, `Connection::Connection()`, `Connection::Send()`
- [x] AC-2: Catch2 test `TEST_CASE("AC-2: ...")` passes (GREEN)

### AC-3: Connect-Fail Message with Address+Port

- [x] AC-3: `WSclient.cpp` `CreateSocket()` enhanced — after `!SocketClient->IsConnected()`, formats `"Cannot connect to {address}:{port}. Server may be offline."`
- [x] AC-3: `mu_swprintf` used for message formatting (available via `stdafx.h`)
- [x] AC-3: `g_ErrorReport.Write(L"NET: %ls\r\n", szConnectError)` called
- [x] AC-3: `MessageBoxW(nullptr, szConnectError, L"Connection Error", MB_ICONERROR | MB_OK)` called (resolves to `SDL_ShowSimpleMessageBox`)
- [x] AC-3: Existing `CUIMng::Instance().PopUpMsgWin(MESSAGE_SERVER_LOST)` call preserved
- [ ] AC-3: Manual validation: connect to non-existent server — dialog + log message verified (AC-VAL-1)

### AC-4 & AC-5: Reserved Message Templates

- [x] AC-4: Message template `"Server handshake failed. Check OpenMU version compatibility."` present in `Connection.cpp` as a comment or string constant — not triggered in this story
- [x] AC-5: Message template `"Login failed. Check credentials."` present in `Connection.cpp` as a comment or string constant — not triggered in this story

### AC-6: Graceful Degradation

- [x] AC-6: `IsManagedLibraryAvailable()` confirmed to return `false` when library absent — verified by existing implementation (story 3.1.2)
- [x] AC-6: Game loop continues normally when `SocketClient == nullptr` — guards in `WSclient.cpp` confirmed
- [x] AC-6: No crash when `dotnet_connect`, `dotnet_disconnect`, etc. are null — null guards confirmed in `Connection.cpp`
- [ ] AC-6: Manual validation: game launches and renders without ClientLibrary, no crash, just missing network features (AC-VAL-2)

### AC-7: Dual Output + Once-Per-Session Guard

- [x] AC-7: `ReportDotNetError()` writes to BOTH `g_ErrorReport.Write()` AND `MessageBoxW` (SDL dialog)
- [x] AC-7: `g_dotnetErrorDisplayed` guard ensures dialog shown at most ONCE per session
- [x] AC-7: Guard is set to `true` before any display to prevent race condition (note: single-threaded game loop, no sync needed per AC-STD-NFR-2)
- [x] AC-7: Flow code comment `// Flow Code: VS1-NET-ERROR-MESSAGING` added to `Connection.cpp` header block
- [ ] AC-7: Manual validation: multiple errors triggered, confirm dialog appears once (AC-VAL-1)

### AC-STD Standards

- [x] AC-STD-1: Code follows project-context.md standards — no `NULL`, no `wprintf`, Allman braces, 4-space indent, no `#ifdef _WIN32` in `Connection.cpp` game logic (compile-time platform detection in impl file only for diagnostic string)
- [x] AC-STD-2: Catch2 unit test added and passes for AC-1 and AC-2 message format functions
- [x] AC-STD-4: `./ctl check` passes — 0 clang-format violations, 0 cppcheck violations; MinGW cross-compile with `-DMU_ENABLE_DOTNET=OFF` passes
- [x] AC-STD-6: Commit message: `feat(network): add connection error messaging and graceful degradation`
- [x] AC-STD-11: `VS1-NET-ERROR-MESSAGING` in `Connection.cpp` header comment — verified by `test_ac_std11_flow_code_3_4_1.cmake`
- [x] AC-STD-11: `VS1-NET-ERROR-MESSAGING` in `test_connection_error_messages.cpp` header comment — verified by cmake script
- [x] AC-STD-13: File count stays at 691 or increases only by new test files — verify `./ctl check` file count
- [x] AC-STD-15: No incomplete rebase, no force push to main
- [x] AC-STD-20: No new API/event/flow catalog entries — error messaging is internal concern

### NFR Standards

- [x] AC-STD-NFR-1: Error dialog appears at most ONCE per session — `g_dotnetErrorDisplayed` guard enforced in `ReportDotNetError()`
- [x] AC-STD-NFR-2: `SDL_ShowSimpleMessageBox` called from main thread only — confirmed by single-threaded game loop architecture

### Validation Artifacts

- [ ] AC-VAL-1: AC-1 and AC-2 scenarios manually triggered (remove library or rename symbol) — message verified in both dialog and `MuError.log`
- [ ] AC-VAL-2: Game launches and renders correctly with `ClientLibrary` absent — no crash confirmed
- [x] AC-VAL-3: `./ctl check` passes on all new/modified files
- [x] AC-VAL-4: CMake script passes: `cmake -P tests/build/test_ac_std11_flow_code_3_4_1.cmake`

### Do-Not-Touch Verification

- [x] SAFETY: `PacketBindings_*.h` NOT modified (generated files)
- [x] SAFETY: `PacketFunctions_*.h/.cpp` NOT modified (generated files)
- [x] SAFETY: `PlatformLibrary.h` NOT modified (API is final from story 1.2.2)
- [x] SAFETY: `PlatformCompat.h` NOT modified (MessageBoxW shim used as-is)
- [x] SAFETY: `symLoad` compatibility shim NOT removed from `Connection.h`
- [x] SAFETY: `test_linux_connectivity.cpp` NOT modified (story 3.3.2 file)

---

## PCC Compliance Summary

| Category | Status | Details |
|----------|--------|---------|
| Prohibited Libraries | PASS | No LoadLibrary, dlopen, wprintf, NULL, raw new/delete in new code |
| Required Patterns | PASS | g_ErrorReport.Write(), MessageBoxW shim, #pragma once, Allman, 4-space |
| Test Framework | PASS | Catch2 v3.7.1, TEST_CASE/SECTION/REQUIRE, no mocking |
| Coverage Target | N/A | No threshold enforced; coverage grows incrementally |
| E2E Tool | N/A | Infrastructure story — no frontend |
| Bruno Collections | N/A | No new API endpoints |
| Flow Code | PENDING | VS1-NET-ERROR-MESSAGING must appear in Connection.cpp and test file |

---

## RED Phase Test Count

| Test Level | Count | Status |
|------------|-------|--------|
| Unit (Catch2 TEST_CASEs) | 7 | RED — FormatLibraryNotFoundMessage, FormatSymbolNotFoundMessage not yet in Connection.cpp |
| CMake build scripts | 1 | RED — Connection.cpp does not yet have VS1-NET-ERROR-MESSAGING flow code |
| Manual validation | 4 | Pending implementation |
| **Total** | **12** | **RED** |

---

## Output Path

ATDD checklist: `/Users/joseybv/workspace/mu/MuMain-workspace/_bmad-output/stories/3-4-1-connection-error-messaging/atdd.md`

---

_Generated by testarch-atdd workflow — 2026-03-08_
