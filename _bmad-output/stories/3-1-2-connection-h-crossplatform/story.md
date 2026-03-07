# Story 3.1.2: Connection.h Cross-Platform Updates

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 3 - .NET AOT Cross-Platform Networking |
| Feature | 3.1 - Build Integration |
| Story ID | 3.1.2 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-NET-CONNECTION-XPLAT |
| FRs Covered | FR9 — .NET Native AOT library loads on all platforms (.dll/.dylib/.so); Architecture Decision 3 (cross-platform interop) |
| Prerequisites | EPIC-1 done (1.2.2 PlatformLibrary backends complete); 3.1.1 done (MU_DOTNET_LIB_EXT defined by FindDotnetAOT.cmake) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Modify `MuMain/src/source/Dotnet/Connection.h` to use `mu::platform::Load()`/`GetSymbol()` via `PlatformLibrary.h`; remove `#ifdef _WIN32` and `LoadLibrary`/`dlopen`/`GetProcAddress`/`dlsym` direct calls; add `MU_DOTNET_LIB_EXT` path construction; modify `MuMain/src/source/Dotnet/Connection.cpp` to fix `IsManagedLibraryAvailable` reference and error reporting; add Catch2 test file |
| project-docs | documentation | Story file and ATDD CMake test for flow code traceability |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** Connection.h to use PlatformLibrary for loading and platform-independent types,
**so that** the .NET interop code works on macOS and Linux without platform ifdefs.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `Connection.h` uses `mu::platform::Load()` instead of `LoadLibrary()`/`dlopen()` — the `munique_client_library_handle` is initialized via `mu::platform::Load(libPath.c_str())` where `libPath` is `"MUnique.Client.Library" + MU_DOTNET_LIB_EXT`
- [ ] **AC-2:** Library path is constructed as `std::filesystem::path("MUnique.Client.Library") += MU_DOTNET_LIB_EXT` using the CMake-defined `MU_DOTNET_LIB_EXT` macro (e.g., `.dll`, `.dylib`, `.so`); no hardcoded extension
- [ ] **AC-3:** Function pointer binding uses `mu::platform::GetSymbol(munique_client_library_handle, name)` instead of `GetProcAddress`/`dlsym` — the `symLoad` macro and platform-specific includes are removed; `LoadManagedSymbol<T>()` uses `GetSymbol()`
- [ ] **AC-4:** No `#ifdef _WIN32` in `Connection.h` — the `#ifdef _WIN32 / LoadLibrary / #else / dlopen #endif` block and `#ifdef _WIN32 / symLoad GetProcAddress / #else / symLoad dlsym #endif` block are removed; all platform differences are in `PlatformLibrary.h` backends
- [ ] **AC-5:** Existing Windows functionality is unchanged — MinGW CI build passes; the game compiles and the `.NET` library loads correctly at runtime on Windows (regression check)

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards — `#pragma once`, `std::filesystem::path`, no `#ifdef _WIN32` in Connection.h, `g_ErrorReport.Write()` for error logging, no new `SAFE_DELETE`/`NULL`/raw `new`/`delete`
- [ ] **AC-STD-2:** Catch2 test added at `MuMain/tests/platform/test_connection_library_load.cpp` — tests the `mu::platform::Load`/`GetSymbol` path with a mock path (verifying graceful nullptr return for non-existent path); does NOT require an actual `.NET` library at test time
- [ ] **AC-STD-3:** Zero platform ifdefs in `Connection.h` — verified by ATDD CMake script test
- [ ] **AC-STD-4:** CI quality gate passes — `./ctl check` (clang-format + cppcheck) zero violations; MinGW cross-compile passes
- [ ] **AC-STD-5:** Error logging uses `g_ErrorReport.Write(L"NET: Connection — library load failed: %hs\r\n", libPath)` in `Connection.cpp` when `mu::platform::Load()` returns nullptr (replacing the current `MessageBoxW` / `wprintf` for load failure)
- [ ] **AC-STD-6:** Conventional commit: `refactor(network): cross-platform Connection.h via PlatformLibrary`
- [ ] **AC-STD-11:** Flow Code traceability — commit message and Connection.h header comment include `VS1-NET-CONNECTION-XPLAT`
- [ ] **AC-STD-13:** Quality gate passes — `./ctl check` clean (currently 691 files; count should stay at 691 unless test file is new, then 692)
- [ ] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [ ] **AC-STD-20:** Contract Reachability — story produces no new API/event/flow catalog entries (refactor only — library loading is an internal concern)

### NFR Acceptance Criteria

- [ ] **AC-STD-NFR-1:** Library load at game startup: `mu::platform::Load()` overhead is equivalent to `LoadLibrary()`/`dlopen()` — no measurable startup regression (not benchmarked, validated by CI build timing)
- [ ] **AC-STD-NFR-2:** `munique_client_library_handle` initialization happens once at static-initialization time (same as current behavior — `inline const` global)

---

## Validation Artifacts

- [ ] **AC-VAL-1:** MinGW CI build passes (`MU_ENABLE_DOTNET=OFF` for CI) — confirms no new Win32 API calls introduced, cross-compile succeeds
- [ ] **AC-VAL-2:** Windows build confirmed working (regression) — `cmake --preset windows-x64 && cmake --build --preset windows-x64-debug` compiles; `Connection.h` no longer includes `windows.h` directly but PlatformLibrary win32 backend does
- [ ] **AC-VAL-3:** ATDD CMake script: `MuMain/tests/build/test_ac_std11_flow_code_3_1_2.cmake` verifies `VS1-NET-CONNECTION-XPLAT` is present in `Connection.h`
- [ ] **AC-VAL-4:** cppcheck passes on `Connection.h` and `Connection.cpp` with zero violations

---

## Tasks / Subtasks

- [ ] **Task 1: Update `Connection.h` to use PlatformLibrary** (AC: AC-1, AC-2, AC-3, AC-4)
  - [ ] 1.1 Remove `#ifdef _WIN32 / windows.h / GetProcAddress / symLoad / #else / dlfcn.h / dlsym / symLoad #endif` blocks entirely
  - [ ] 1.2 Add `#include "PlatformLibrary.h"` (in `mu::platform` namespace)
  - [ ] 1.3 Add `#include <filesystem>` for `std::filesystem::path`
  - [ ] 1.4 Replace `munique_client_library_handle` declaration:
    ```cpp
    // BEFORE:
    #ifdef _WIN32
    inline const HINSTANCE munique_client_library_handle = LoadLibrary(L"MUnique.Client.Library.dll");
    #else
    inline const void* munique_client_library_handle = dlopen("MUnique.Client.Library.dll", RTLD_LAZY);
    #endif

    // AFTER:
    namespace
    {
    // MU_DOTNET_LIB_EXT is defined by CMake (FindDotnetAOT.cmake) as ".dll", ".dylib", or ".so"
    inline const std::string g_dotnetLibPath =
        (std::filesystem::path("MUnique.Client.Library") += MU_DOTNET_LIB_EXT).string();
    }
    inline const mu::platform::LibraryHandle munique_client_library_handle =
        mu::platform::Load(g_dotnetLibPath.c_str());
    ```
  - [ ] 1.5 Update `LoadManagedSymbol<T>()` to use `mu::platform::GetSymbol()`:
    ```cpp
    template <typename T>
    T LoadManagedSymbol(const char* name)
    {
        if (!IsManagedLibraryAvailable())
        {
            return nullptr;
        }
        const auto symbol = reinterpret_cast<T>(mu::platform::GetSymbol(munique_client_library_handle, name));
        if (!symbol)
        {
            ReportDotNetError(name);
        }
        return symbol;
    }
    ```
  - [ ] 1.6 Remove `#include <cwchar>` if no longer needed (check usages in Connection.h)
  - [ ] 1.7 Add flow code comment header: `// Flow Code: VS1-NET-CONNECTION-XPLAT`
  - [ ] 1.8 Keep `#include <coreclr_delegates.h>` (needed for `CORECLR_DELEGATE_CALLTYPE` in Connection.cpp typedefs)

- [ ] **Task 2: Update `Connection.cpp`** (AC: AC-5, AC-STD-5)
  - [ ] 2.1 Update `IsManagedLibraryAvailable()`: change error message string from `"MUnique.Client.Library.dll missing"` to `"MUnique.Client.Library" MU_DOTNET_LIB_EXT " missing"` (platform-accurate)
  - [ ] 2.2 Update `ReportDotNetError()`: replace the `#ifdef _WIN32 / MessageBoxW / #else / wprintf #endif` block with `g_ErrorReport.Write()` only (consistent cross-platform logging):
    ```cpp
    void ReportDotNetError(const char* detail)
    {
        if (g_dotnetErrorDisplayed)
        {
            return;
        }
        g_dotnetErrorDisplayed = true;
        g_ErrorReport.Write(L"NET: Connection — library load failed: %hs\r\n", detail ? detail : "unknown error");
    }
    ```
  - [ ] 2.3 Update `IsManagedLibraryAvailable()` error string to use `MU_DOTNET_LIB_EXT`:
    ```cpp
    const std::string libName = std::string("MUnique.Client.Library") + MU_DOTNET_LIB_EXT + " missing";
    ReportDotNetError(libName.c_str());
    ```
  - [ ] 2.4 Remove `#include "windows.h"` guard check — `Connection.cpp` includes `Connection.h` which no longer pulls in `windows.h` directly; verify no other Windows-only symbols are used in `Connection.cpp` game logic
  - [ ] 2.5 `wprintf(L"Received packet, size %d", size)` in `OnPacketReceived` — this is dead debug code; replace with `g_ErrorReport.Write` or remove (per project-context.md: no `wprintf` in new code)

- [ ] **Task 3: Add Catch2 test** (AC: AC-STD-2)
  - [ ] 3.1 Create `MuMain/tests/platform/test_connection_library_load.cpp`:
    - Test: `mu::platform::Load("NonExistentLibrary.xyz")` returns `nullptr` (graceful failure)
    - Test: `mu::platform::GetSymbol(nullptr, "any")` returns `nullptr` (null-handle safety)
    - Note: These tests use PlatformLibrary directly — they do NOT test Connection class (which requires the full .NET library)
    - No mock of `munique_client_library_handle` needed — test the underlying platform primitives that Connection.h uses

- [ ] **Task 4: Add ATDD CMake test** (AC: AC-VAL-3)
  - [ ] 4.1 Create `MuMain/tests/build/test_ac_std11_flow_code_3_1_2.cmake`:
    - Read `Connection.h` content
    - Check that `VS1-NET-CONNECTION-XPLAT` appears in the file
    - Check that `#ifdef _WIN32` does NOT appear in the file
    - Check that `LoadLibrary` does NOT appear in the file
    - Check that `dlopen` does NOT appear in the file
  - [ ] 4.2 Register test in `MuMain/tests/build/CMakeLists.txt`

- [ ] **Task 5: Quality gate** (AC: AC-STD-4, AC-STD-13)
  - [ ] 5.1 `./ctl check` — must pass (0 violations)
  - [ ] 5.2 Verify `cmake --preset macos-arm64` configures cleanly (Connection.h no longer has dlfcn.h / windows.h)
  - [ ] 5.3 Verify MinGW cross-compile (`-DMU_ENABLE_DOTNET=OFF`) continues to work

---

## Error Codes Introduced

_None — this is a refactor story. No new C++ error codes introduced._

_Diagnostic message format (via `g_ErrorReport.Write()` in Connection.cpp):_
```
NET: Connection — library load failed: <detail>
```
_This replaces the previous `MessageBoxW` (Win32-only) and `wprintf` (non-persistent) calls._

---

## Contract Catalog Entries

### API Contracts

_None — internal refactor. No new API endpoints._

### Event Contracts

_None — no new events._

### Navigation Entries

_Not applicable — infrastructure story (not frontend)._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Load failure (Catch2) | Catch2 v3.7.1 | N/A | `mu::platform::Load()` returns nullptr for non-existent library; `GetSymbol(nullptr, ...)` returns nullptr |
| No-ifdef check (CMake script) | CMake `-P` | N/A | Connection.h contains no `#ifdef _WIN32`, no `LoadLibrary`, no `dlopen` |
| Flow code traceability (CMake script) | CMake `-P` | N/A | `VS1-NET-CONNECTION-XPLAT` present in Connection.h |
| CI regression (automated) | MinGW CI | N/A | MinGW cross-compile build passes (`-DMU_ENABLE_DOTNET=OFF`) |
| Windows regression | Manual | N/A | Windows MSVC build compiles; library loads at runtime |

_Note: Full Connection class integration test (connecting to a real .NET library) is deferred to story 3.3.1/3.3.2 (platform validation). Story 3.1.2 only establishes the cross-platform library loading mechanism._

---

## Dev Notes

### Overview

This story refactors `MuMain/src/source/Dotnet/Connection.h` (and companion `Connection.cpp`) to remove all `#ifdef _WIN32` platform conditionals and replace direct Win32 (`LoadLibrary`/`GetProcAddress`) and POSIX (`dlopen`/`dlsym`) calls with the platform-agnostic `mu::platform` API provided by `PlatformLibrary.h`.

**What this story does NOT do:**
- Does NOT change the `wchar_t` parameter in `Connection::Connection(const wchar_t* host, ...)` — that is deferred to story 3.2.1 (`char16_t` encoding)
- Does NOT change function pointer signatures (CORECLR types, `Connect`/`Disconnect`/etc.) — those are deferred to 3.2.1
- Does NOT validate actual server connectivity — that is story 3.3.1/3.3.2
- Does NOT modify any generated files (`PacketBindings_*.h`, `PacketFunctions_*.h/.cpp`) — NEVER edit generated files

### Current State of Connection.h (BEFORE this story)

```cpp
// CURRENT - has platform ifdefs (violation of cross-platform rules)
#ifdef _WIN32
#include "windows.h"
#define symLoad GetProcAddress
#else
#include "dlfcn.h"
#define symLoad dlsym
#endif

#ifdef _WIN32
inline const HINSTANCE munique_client_library_handle = LoadLibrary(L"MUnique.Client.Library.dll");
#else
inline const void* munique_client_library_handle = dlopen("MUnique.Client.Library.dll", RTLD_LAZY);
#endif
```

**Key Problems:**
1. `dlopen("MUnique.Client.Library.dll", RTLD_LAZY)` — hardcodes `.dll` extension even on non-Windows (wrong extension for macOS/Linux)
2. `HINSTANCE` type is Win32-only
3. `LoadLibrary`/`GetProcAddress` are Win32-only
4. Two `#ifdef _WIN32` blocks in a header that should be platform-neutral

### Target State of Connection.h (AFTER this story)

```cpp
#pragma once

#include "stdafx.h"
// Flow Code: VS1-NET-CONNECTION-XPLAT

#include <coreclr_delegates.h>
#include <filesystem>

#include "PlatformLibrary.h"
#include "PacketFunctions_ChatServer.h"
#include "PacketFunctions_ConnectServer.h"
#include "PacketFunctions_ClientToServer.h"

namespace
{
// MU_DOTNET_LIB_EXT is defined by CMake (FindDotnetAOT.cmake): ".dll" | ".dylib" | ".so"
inline const std::string g_dotnetLibPath =
    (std::filesystem::path("MUnique.Client.Library") += MU_DOTNET_LIB_EXT).string();
}

inline const mu::platform::LibraryHandle munique_client_library_handle =
    mu::platform::Load(g_dotnetLibPath.c_str());

namespace DotNetBridge
{
void ReportDotNetError(const char* detail);
bool IsManagedLibraryAvailable();

template <typename T>
T LoadManagedSymbol(const char* name)
{
    if (!IsManagedLibraryAvailable())
    {
        return nullptr;
    }
    const auto symbol = reinterpret_cast<T>(mu::platform::GetSymbol(munique_client_library_handle, name));
    if (!symbol)
    {
        ReportDotNetError(name);
    }
    return symbol;
}
} // namespace DotNetBridge

using DotNetBridge::LoadManagedSymbol;

// ... Connection class unchanged except wchar_t (deferred to 3.2.1)
```

### PlatformLibrary.h API (already implemented in story 1.2.2)

`PlatformLibrary.h` is at `MuMain/src/source/Platform/PlatformLibrary.h`:

```cpp
namespace mu::platform
{
    using LibraryHandle = void*;  // Opaque handle (HMODULE on Win32, void* on POSIX)
    [[nodiscard]] LibraryHandle Load(const char* path);    // UTF-8 path
    [[nodiscard]] void* GetSymbol(LibraryHandle handle, const char* name);
    void Unload(LibraryHandle handle);
}
```

**Include path:** `#include "PlatformLibrary.h"` (flat include, per project convention — `SortIncludes: Never`)
**Available in:** `MUGame` target (includes `Platform/` in include path via `MUCommon` INTERFACE)

**Backend implementations:**
- Win32: `Platform/win32/PlatformLibrary.cpp` — uses `LoadLibraryW` (converts UTF-8 path with `MultiByteToWideChar`)
- POSIX: `Platform/posix/PlatformLibrary.cpp` — uses `dlopen(path, RTLD_LAZY | RTLD_LOCAL)`

**Error logging:** Both backends log to `g_ErrorReport.Write()` on failure and return `nullptr`. The caller (Connection.h) does NOT need to log again on nullptr — `PlatformLibrary` already handles it.

### MU_DOTNET_LIB_EXT — How It Gets to Connection.h

Set by `FindDotnetAOT.cmake` (story 3.1.1) and passed to the C++ compiler via:
```cmake
add_compile_definitions(MU_DOTNET_LIB_EXT="${MU_DOTNET_LIB_EXT}")
```
This is called even when `DOTNETAOT_FOUND=FALSE` (CI/rendering builds) with a fallback of `.dll`.

When `MU_ENABLE_DOTNET=OFF` (MinGW CI):
```cmake
add_compile_definitions(MU_DOTNET_LIB_EXT=".dll")
```

The macro expands to a string literal at compile time. Usage: `std::filesystem::path("MUnique.Client.Library") += MU_DOTNET_LIB_EXT` produces `"MUnique.Client.Library.dll"`, `"MUnique.Client.Library.dylib"`, or `"MUnique.Client.Library.so"` depending on platform.

### Important: `munique_client_library_handle` Is a Static Global

The current `munique_client_library_handle` is initialized at static-initialization time (C++ `inline const` globals initialize before `main()`). This is fine for `mu::platform::Load()` which is a pure function. The handle will be:
- Non-null: library loaded successfully (game can use .NET bridge)
- Null: library not found (`g_dotnetLibPath` doesn't exist at runtime — graceful path via `IsManagedLibraryAvailable()`)

**IMPORTANT:** The anonymous namespace for `g_dotnetLibPath` prevents multiple-definition linker errors across translation units that include `Connection.h`. The `inline const` on `munique_client_library_handle` works across translation units (C++17 inline variables).

### Connection.cpp Changes

**`ReportDotNetError()` — current code (has `#ifdef _WIN32` in `.cpp`):**
```cpp
void ReportDotNetError(const char* detail)
{
    // ...
    wchar_t buffer[512];
    std::swprintf(buffer, std::size(buffer), L"...", detail ? detail : "unknown error");
#ifdef _WIN32
    MessageBoxW(nullptr, buffer, L"MuMainClient", MB_ICONERROR | MB_OK);
#else
    wprintf(L"%ls\n", buffer);
#endif
}
```

**Target (use g_ErrorReport only):**
```cpp
void ReportDotNetError(const char* detail)
{
    if (g_dotnetErrorDisplayed)
    {
        return;
    }
    g_dotnetErrorDisplayed = true;
    g_ErrorReport.Write(L"NET: Connection — library load failed: %hs\r\n",
                        detail ? detail : "unknown error");
}
```

**Note on `#ifdef _WIN32` in Connection.cpp:** The spec (AC-STD-3) says "Zero platform ifdefs in Connection.h". The `#ifdef _WIN32` in `Connection.cpp` should also be removed to follow the spirit of the story (AC-4 says "No `#ifdef _WIN32` in Connection.h"). Connection.cpp is technically not Connection.h, but the dev agent should remove the `#ifdef _WIN32` in `ReportDotNetError()` and replace with `g_ErrorReport.Write()` (the cross-platform logging mechanism already available from story 7.1.1).

**`OnPacketReceived()` wprintf cleanup:**
```cpp
// CURRENT (dead debug code, banned per project-context.md):
void Connection::OnPacketReceived(const BYTE* data, const int32_t size)
{
    wprintf(L"Received packet, size %d", size);  // <-- REMOVE THIS
    this->_packetHandler(this->_handle, data, size);
}

// TARGET:
void Connection::OnPacketReceived(const BYTE* data, const int32_t size)
{
    this->_packetHandler(this->_handle, data, size);
}
```

### Static Initialization Order Concern

`munique_client_library_handle` and `g_dotnetLibPath` are namespace-scope `inline const` variables initialized before `main()`. They depend on `MU_DOTNET_LIB_EXT` which is a compile-time macro — no runtime dependency. `mu::platform::Load()` only uses the system dynamic loader (`LoadLibraryW`/`dlopen`) which is safe to call during static initialization.

`dotnet_connect`, `dotnet_disconnect`, `dotnet_beginreceive`, `dotnet_send` (in Connection.cpp) are also namespace-scope globals initialized by calling `LoadManagedSymbol<T>()` at static-init time. They depend on `munique_client_library_handle`. Since all these are in the same translation unit (`Connection.cpp`), the initialization order within the translation unit is deterministic (top to bottom) — `munique_client_library_handle` in `Connection.h` is initialized first (it's an `inline const` — initialized before the TU's globals), then the function pointer globals. This is safe.

### ATDD CMake Test Pattern (from story 3.1.1)

Follow the existing pattern in `MuMain/tests/build/`:

```cmake
# test_ac_std11_flow_code_3_1_2.cmake
# Validates: Connection.h contains VS1-NET-CONNECTION-XPLAT and has no platform ifdefs

cmake_minimum_required(VERSION 3.25)

set(CONNECTION_H "${CMAKE_CURRENT_LIST_DIR}/../../src/source/Dotnet/Connection.h")
if(NOT EXISTS "${CONNECTION_H}")
    message(FATAL_ERROR "FAIL: Connection.h not found at ${CONNECTION_H}")
endif()

file(READ "${CONNECTION_H}" CONNECTION_H_CONTENT)

# Check flow code present
if(NOT CONNECTION_H_CONTENT MATCHES "VS1-NET-CONNECTION-XPLAT")
    message(FATAL_ERROR "FAIL: VS1-NET-CONNECTION-XPLAT not found in Connection.h")
endif()

# Check no platform ifdefs
if(CONNECTION_H_CONTENT MATCHES "#ifdef _WIN32")
    message(FATAL_ERROR "FAIL: #ifdef _WIN32 found in Connection.h — remove platform ifdefs")
endif()

# Check no LoadLibrary
if(CONNECTION_H_CONTENT MATCHES "LoadLibrary")
    message(FATAL_ERROR "FAIL: LoadLibrary found in Connection.h — use mu::platform::Load()")
endif()

# Check no dlopen
if(CONNECTION_H_CONTENT MATCHES "dlopen")
    message(FATAL_ERROR "FAIL: dlopen found in Connection.h — use mu::platform::Load()")
endif()

message(STATUS "PASS: Connection.h is cross-platform (no Win32 ifdefs, uses PlatformLibrary)")
```

### Catch2 Test Pattern (from existing tests)

```cpp
// MuMain/tests/platform/test_connection_library_load.cpp
// Story 3.1.2: Connection.h Cross-Platform Updates
// Tests the mu::platform primitives that Connection.h uses
// Does NOT require an actual .NET library at test time

#include <catch2/catch_test_macros.hpp>
#include "PlatformLibrary.h"

TEST_CASE("3.1.2 AC-1: Load returns nullptr for non-existent library", "[network][dotnet]")
{
    // Validates the graceful-failure path that IsManagedLibraryAvailable() relies on
    mu::platform::LibraryHandle handle = mu::platform::Load("NonExistent.Client.Library.xyz");
    REQUIRE(handle == nullptr);
}

TEST_CASE("3.1.2 AC-3: GetSymbol returns nullptr for null handle", "[network][dotnet]")
{
    // Validates null-handle safety — IsManagedLibraryAvailable() guards against this
    void* symbol = mu::platform::GetSymbol(nullptr, "ConnectionManager_Connect");
    REQUIRE(symbol == nullptr);
}
```

### Files to Modify

| File | Action | Notes |
|------|--------|-------|
| `MuMain/src/source/Dotnet/Connection.h` | MODIFY | Remove `#ifdef _WIN32` blocks; add `PlatformLibrary.h` + `<filesystem>`; replace library loading with `mu::platform::Load()`; replace `symLoad` macro with `mu::platform::GetSymbol()` |
| `MuMain/src/source/Dotnet/Connection.cpp` | MODIFY | Remove `#ifdef _WIN32` in `ReportDotNetError()`; replace with `g_ErrorReport.Write()`; update error message string; remove `wprintf` debug line in `OnPacketReceived()` |
| `MuMain/tests/platform/test_connection_library_load.cpp` | CREATE | Catch2 tests for platform load primitives |
| `MuMain/tests/build/test_ac_std11_flow_code_3_1_2.cmake` | CREATE | ATDD: verify flow code + no platform ifdefs |
| `MuMain/tests/build/CMakeLists.txt` | MODIFY | Register new ATDD test |

### Do NOT Touch

- `MuMain/src/source/Dotnet/PacketBindings_*.h` — generated files, NEVER edit
- `MuMain/src/source/Dotnet/PacketFunctions_*.h/.cpp` — generated files, NEVER edit
- `MuMain/src/source/Dotnet/Connection.h` function signatures (`wchar_t`, `CORECLR_DELEGATE_CALLTYPE`) — deferred to story 3.2.1
- `MuMain/ClientLibrary/` — .NET source, not in scope

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, Ninja, MinGW CI, Catch2 v3.7.1, clang-format 21.1.8

**Required Patterns (from project-context.md):**
- `std::filesystem::path` for path construction (used for `g_dotnetLibPath`)
- `#pragma once` only (no `#ifndef` guards)
- `[[nodiscard]]` on `mu::platform::Load()` and `GetSymbol()` (already in PlatformLibrary.h)
- `g_ErrorReport.Write(L"fmt", ...)` for error logging (not `wprintf`, not `MessageBoxW`)
- No `#ifdef _WIN32` in game logic (platform abstraction via `PlatformLibrary.h` backends)
- Catch2 `TEST_CASE` / `REQUIRE` / `SECTION` structure

**Prohibited Patterns (from project-context.md):**
- NO `LoadLibrary`/`GetProcAddress` in Connection.h (Win32-only)
- NO `dlopen`/`dlsym` in Connection.h (POSIX-only)
- NO `#ifdef _WIN32` in Connection.h or Connection.cpp
- NO `wprintf` in new/modified code
- NO raw `new`/`delete` (Connection.cpp uses `SAFE_DELETE` for legacy pointers — do not change those)
- NO modification of generated files in `src/source/Dotnet/`
- NO `MessageBoxW` in updated `ReportDotNetError()`
- NO hardcoded `.dll`/`.dylib`/`.so` string literals in new C++ code — use `MU_DOTNET_LIB_EXT`

**Quality Gate Command:** `./ctl check` (clang-format check + cppcheck)

**Commit Format:** `refactor(network): cross-platform Connection.h via PlatformLibrary`

### Schema Alignment

Not applicable — C++20 game client with no schema validation tooling.

### References

- [Source: MuMain/src/source/Dotnet/Connection.h] — file to refactor; current state has two `#ifdef _WIN32` blocks
- [Source: MuMain/src/source/Dotnet/Connection.cpp] — companion implementation; `ReportDotNetError()` has `#ifdef _WIN32 / MessageBoxW / wprintf` that needs removal
- [Source: MuMain/src/source/Platform/PlatformLibrary.h] — the target API (`mu::platform::Load`, `GetSymbol`, `Unload`)
- [Source: MuMain/src/source/Platform/win32/PlatformLibrary.cpp] — Win32 backend (uses `LoadLibraryW` + `GetProcAddress`)
- [Source: MuMain/src/source/Platform/posix/PlatformLibrary.cpp] — POSIX backend (uses `dlopen` + `dlsym`)
- [Source: MuMain/src/dependencies/netcore/includes/coreclr_delegates.h] — provides `CORECLR_DELEGATE_CALLTYPE` macro (keep this include)
- [Source: MuMain/cmake/FindDotnetAOT.cmake] — defines `MU_DOTNET_LIB_EXT` and `add_compile_definitions(MU_DOTNET_LIB_EXT=...)` (story 3.1.1 output)
- [Source: MuMain/CMakeLists.txt] — `add_compile_definitions(MU_DOTNET_LIB_EXT=...)` is called even when `DOTNETAOT_FOUND=FALSE`
- [Source: MuMain/tests/platform/test_platform_library.cpp] — existing PlatformLibrary test file; follow same structure for new test
- [Source: MuMain/tests/build/test_ac1_dotnet_rid_detection.cmake] — ATDD test pattern from story 3.1.1
- [Source: MuMain/tests/build/CMakeLists.txt] — register new ATDD test here
- [Source: _bmad-output/planning-artifacts/epics.md §Story 3.1.2] — original acceptance criteria
- [Source: _bmad-output/stories/3-1-1-cmake-rid-detection/story.md §Dev Notes] — MU_DOTNET_LIB_EXT setup, CMake module patterns
- [Source: _bmad-output/stories/1-2-2-platform-library-backends/story.md] — PlatformLibrary.h API design and usage patterns

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Story created 2026-03-07 via create-story workflow (agent: claude-sonnet-4-6)
- Story key: 3-1-2-connection-h-crossplatform (from sprint-status.yaml)
- Story type: infrastructure (C++ refactor — no frontend, no API contracts)
- Prerequisites confirmed done: 1.2.2 (PlatformLibrary backends), 3.1.1 (FindDotnetAOT.cmake, MU_DOTNET_LIB_EXT)
- Specification corpus: specification-index.yaml not available
- Story partials: not found (docs/story-partials/ does not exist)
- Schema alignment: N/A (C++20 game client, no schema tooling)
- Visual Design Specification section omitted — infrastructure story, not frontend
- This story unblocks 3-2-1-char16t-encoding and 3-4-1-connection-error-messaging
- Static initialization analysis: g_dotnetLibPath (anonymous namespace) + munique_client_library_handle (inline const) are safe at static-init time
- coreclr_delegates.h is at MuMain/src/dependencies/netcore/includes/ — keep the include in Connection.h

### File List

- [MODIFY] `MuMain/src/source/Dotnet/Connection.h` — remove Win32/POSIX ifdefs; add PlatformLibrary.h + filesystem; use mu::platform::Load()/GetSymbol()
- [MODIFY] `MuMain/src/source/Dotnet/Connection.cpp` — remove #ifdef _WIN32 in ReportDotNetError(); use g_ErrorReport; remove wprintf debug line
- [CREATE] `MuMain/tests/platform/test_connection_library_load.cpp` — Catch2 tests for PlatformLibrary graceful failure paths used by Connection.h
- [CREATE] `MuMain/tests/build/test_ac_std11_flow_code_3_1_2.cmake` — ATDD: verify VS1-NET-CONNECTION-XPLAT + no platform ifdefs in Connection.h
- [MODIFY] `MuMain/tests/build/CMakeLists.txt` — register new ATDD test
