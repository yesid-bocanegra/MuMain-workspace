# ATDD Implementation Checklist
# Story 3.1.2: Connection.h Cross-Platform Updates
# Flow Code: VS1-NET-CONNECTION-XPLAT
# Generated: 2026-03-07 | Agent: claude-sonnet-4-6

---

## AC-to-Test Mapping

| AC | Description | Test Method | Test File | Phase |
|----|-------------|-------------|-----------|-------|
| AC-1 | `Connection.h` uses `mu::platform::Load()` instead of `LoadLibrary()`/`dlopen()` | `3.1.2 AC-1: Load returns nullptr for non-existent library` | `tests/platform/test_connection_library_load.cpp` | RED |
| AC-1 | Same — additional path variant | `3.1.2 AC-1: Load returns nullptr for path with wrong extension` | `tests/platform/test_connection_library_load.cpp` | RED |
| AC-2 | Library path uses `MU_DOTNET_LIB_EXT` macro | `3.1.2 AC-2: MU_DOTNET_LIB_EXT macro is defined and non-empty` | `tests/platform/test_connection_library_load.cpp` | RED |
| AC-2 | Path construction correctness | `3.1.2 AC-2: Path construction produces correct library name` | `tests/platform/test_connection_library_load.cpp` | RED |
| AC-3 | `GetSymbol()` replaces `GetProcAddress`/`dlsym` — null-handle safety | `3.1.2 AC-3: GetSymbol returns nullptr for null handle` | `tests/platform/test_connection_library_load.cpp` | RED |
| AC-3 | Same — disconnect symbol variant | `3.1.2 AC-3: GetSymbol returns nullptr for null handle — disconnect symbol` | `tests/platform/test_connection_library_load.cpp` | RED |
| AC-4 / AC-STD-3 | No `#ifdef _WIN32` in `Connection.h` | CMake check 4 in `test_ac_std11_flow_code_3_1_2.cmake` | `tests/build/test_ac_std11_flow_code_3_1_2.cmake` | RED |
| AC-5 | Windows functionality unchanged | MinGW CI build pass (automated) | CI pipeline | RED |
| AC-STD-2 | Catch2 test for graceful failure path | `3.1.2 AC-STD-2: Load and GetSymbol compose safely for missing library` | `tests/platform/test_connection_library_load.cpp` | RED |
| AC-STD-3 | PlatformLibrary.h compile-time check | `3.1.2 AC-STD-3: PlatformLibrary.h compiles without platform conditionals` | `tests/platform/test_connection_library_load.cpp` | GREEN |
| AC-STD-11 | Flow code `VS1-NET-CONNECTION-XPLAT` in `Connection.h` | CMake check 2-3 in `test_ac_std11_flow_code_3_1_2.cmake` | `tests/build/test_ac_std11_flow_code_3_1_2.cmake` | RED |
| AC-VAL-3 | ATDD CMake script verifies flow code + no ifdefs | `3.1.2-AC-STD-11:flow-code-traceability` CTest entry | `tests/build/CMakeLists.txt` | RED |

---

## Implementation Checklist

### Functional ACs

- [ ] AC-1: `Connection.h` uses `mu::platform::Load()` — `munique_client_library_handle` initialized via `mu::platform::Load(g_dotnetLibPath.c_str())`
- [ ] AC-2: Library path constructed as `(std::filesystem::path("MUnique.Client.Library") += MU_DOTNET_LIB_EXT).string()` — no hardcoded extension
- [ ] AC-3: `LoadManagedSymbol<T>()` uses `mu::platform::GetSymbol(munique_client_library_handle, name)` — `symLoad` macro removed
- [ ] AC-4: No `#ifdef _WIN32` in `Connection.h` — all platform blocks removed
- [ ] AC-5: MinGW CI build passes (regression check — no new Win32 API calls)

### Standard ACs

- [ ] AC-STD-1: Code follows project-context.md standards — `#pragma once`, `std::filesystem::path`, `g_ErrorReport.Write()` for errors, no `SAFE_DELETE`/`NULL`/raw `new`/`delete`
- [ ] AC-STD-2: Catch2 test at `MuMain/tests/platform/test_connection_library_load.cpp` compiles and covers graceful failure paths
- [ ] AC-STD-3: Zero platform ifdefs in `Connection.h` — confirmed by CMake script `test_ac_std11_flow_code_3_1_2.cmake` PASS
- [ ] AC-STD-4: `./ctl check` passes — 0 clang-format violations, 0 cppcheck violations
- [ ] AC-STD-5: Error logging uses `g_ErrorReport.Write(L"NET: Connection — library load failed: %hs\r\n", detail)` in `Connection.cpp`
- [ ] AC-STD-6: Conventional commit message: `refactor(network): cross-platform Connection.h via PlatformLibrary`
- [ ] AC-STD-11: `// Flow Code: VS1-NET-CONNECTION-XPLAT` present in `Connection.h` header
- [ ] AC-STD-13: Quality gate clean — file count 691 (source) + 692 (after adding test file)
- [ ] AC-STD-15: Git safety — no incomplete rebase, no force push to main
- [ ] AC-STD-20: No new API/event/flow catalog entries (refactor only)

### NFR ACs

- [ ] AC-STD-NFR-1: `mu::platform::Load()` overhead equivalent to `LoadLibrary()`/`dlopen()` — no measurable startup regression
- [ ] AC-STD-NFR-2: `munique_client_library_handle` initialization happens once at static-init time

### Validation ACs

- [ ] AC-VAL-1: MinGW CI build passes (`MU_ENABLE_DOTNET=OFF`)
- [ ] AC-VAL-2: Windows build confirmed working — MSVC compiles; `Connection.h` no longer includes `windows.h` directly
- [ ] AC-VAL-3: CMake script `test_ac_std11_flow_code_3_1_2.cmake` runs and PASSES via CTest
- [ ] AC-VAL-4: cppcheck passes on `Connection.h` and `Connection.cpp` — zero violations

### PCC Compliance

- [ ] PCC-1: No prohibited libraries — no `LoadLibrary`/`GetProcAddress`/`dlopen`/`dlsym` in game logic headers
- [ ] PCC-2: Required patterns — `std::filesystem::path`, `#pragma once`, `[[nodiscard]]` on `mu::platform` functions (already in PlatformLibrary.h)
- [ ] PCC-3: No `wprintf` in new/modified code — `ReportDotNetError()` and `OnPacketReceived()` cleaned up
- [ ] PCC-4: No `MessageBoxW` in updated `ReportDotNetError()` — replaced with `g_ErrorReport.Write()`
- [ ] PCC-5: No hardcoded `.dll`/`.dylib`/`.so` literals in new C++ code — `MU_DOTNET_LIB_EXT` macro used
- [ ] PCC-6: Generated files untouched — `PacketBindings_*.h`, `PacketFunctions_*.h/.cpp` not modified

### Tasks

- [ ] Task 1: Update `Connection.h` to use PlatformLibrary (AC-1, AC-2, AC-3, AC-4)
  - [ ] 1.1 Remove `#ifdef _WIN32 / windows.h / GetProcAddress / symLoad / #else / dlfcn.h / dlsym / symLoad #endif` blocks
  - [ ] 1.2 Add `#include "PlatformLibrary.h"`
  - [ ] 1.3 Add `#include <filesystem>`
  - [ ] 1.4 Replace `munique_client_library_handle` with anonymous-namespace `g_dotnetLibPath` + `mu::platform::Load()`
  - [ ] 1.5 Update `LoadManagedSymbol<T>()` to use `mu::platform::GetSymbol()`
  - [ ] 1.6 Remove `#include <cwchar>` if unused
  - [ ] 1.7 Add `// Flow Code: VS1-NET-CONNECTION-XPLAT` header comment
  - [ ] 1.8 Keep `#include <coreclr_delegates.h>`
- [ ] Task 2: Update `Connection.cpp` (AC-5, AC-STD-5)
  - [ ] 2.1 Update `IsManagedLibraryAvailable()` error string to use `MU_DOTNET_LIB_EXT`
  - [ ] 2.2 Replace `ReportDotNetError()` body with `g_ErrorReport.Write()` only (remove `#ifdef _WIN32 / MessageBoxW / wprintf`)
  - [ ] 2.3 Remove `wprintf` debug line from `OnPacketReceived()`
- [ ] Task 3: Catch2 test file created at `MuMain/tests/platform/test_connection_library_load.cpp` (AC-STD-2)
- [ ] Task 4: ATDD CMake script created at `MuMain/tests/build/test_ac_std11_flow_code_3_1_2.cmake` (AC-VAL-3)
- [ ] Task 5: CMake test registered in `MuMain/tests/build/CMakeLists.txt`
- [ ] Task 6: `./ctl check` passes — 0 violations (AC-STD-4, AC-STD-13)

---

## Test Files Created (RED Phase)

| File | Status | ACs Covered |
|------|--------|-------------|
| `MuMain/tests/platform/test_connection_library_load.cpp` | CREATED | AC-1, AC-2, AC-3, AC-STD-2, AC-STD-3 |
| `MuMain/tests/build/test_ac_std11_flow_code_3_1_2.cmake` | CREATED | AC-4, AC-STD-3, AC-STD-11, AC-VAL-3 |
| `MuMain/tests/build/CMakeLists.txt` (modified) | UPDATED | AC-VAL-3 (CTest registration) |

**Note:** Tests for AC-1 through AC-4 are in RED phase — they FAIL until `Connection.h` is refactored. AC-STD-3 (PlatformLibrary.h compile check) passes immediately since PlatformLibrary.h is already implemented.

---

## PCC Compliance Summary

| Check | Status |
|-------|--------|
| Guidelines loaded (project-context.md, development-standards.md) | PASS |
| No prohibited libraries in test files | PASS — test uses PlatformLibrary.h only |
| Required test pattern: Catch2 TEST_CASE / REQUIRE | PASS |
| AC-N: prefix in test names | PASS — all test names include AC number |
| No platform conditionals in test logic | PASS — platform ifdefs are in test files (acceptable per project-context.md) |
| ATDD checklist has AC-to-test mapping | PASS |
| All items REQUIRED (no DEFERRED) | PASS |
