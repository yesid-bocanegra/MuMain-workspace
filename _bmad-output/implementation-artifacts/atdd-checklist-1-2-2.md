# ATDD Implementation Checklist — Story 1.2.2: Platform Library Backends

**Story Key:** 1-2-2-platform-library-backends
**Story Type:** infrastructure
**Test Framework:** Catch2 v3.7.1 + CMake script-mode tests
**Phase:** GREEN (implementation complete, CMake script tests passing)
**Generated:** 2026-03-04

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Name / Script |
|----|-------------|-----------|-------------------|
| AC-1 | PlatformLibrary.h interface in mu::platform namespace | test_platform_library.cpp | `AC-1: PlatformLibrary.h interface exists in mu::platform namespace` |
| AC-1,AC-6 | Load returns [[nodiscard]] LibraryHandle | test_platform_library.cpp | `AC-1,AC-6: Load returns [[nodiscard]] LibraryHandle` |
| AC-1,AC-6 | GetSymbol returns [[nodiscard]] pointer | test_platform_library.cpp | `AC-1,AC-6: GetSymbol returns [[nodiscard]] pointer for known symbol` |
| AC-2 | win32 backend exists | test_ac_1_2_2_cmake_backend.cmake | `AC-2 PASS: win32/PlatformLibrary.cpp exists` |
| AC-3 | posix backend exists | test_ac_1_2_2_cmake_backend.cmake | `AC-3 PASS: posix/PlatformLibrary.cpp exists` |
| AC-4 | CMake platform-conditional backend selection | test_ac_1_2_2_cmake_backend.cmake | `AC-4:platform-library-cmake-backend` |
| AC-5 | Load failure returns nullptr | test_platform_library.cpp | `AC-5: Load failure returns nullptr for non-existent library` |
| AC-5 | GetSymbol failure returns nullptr | test_platform_library.cpp | `AC-5: GetSymbol failure returns nullptr for invalid symbol name` |
| AC-5 | Unload nullptr is no-op | test_platform_library.cpp | `AC-5: Unload on nullptr handle is a safe no-op` |
| AC-6 | [[nodiscard]] on fallible functions | test_ac_1_2_2_header_neutral.cmake | `AC-6 PASS: [[nodiscard]] present` |
| AC-STD-1 | #pragma once, mu::platform namespace | test_ac_1_2_2_header_neutral.cmake | `AC-STD-1 PASS: conventions` |
| AC-STD-2 | Catch2 load/resolve/unload round-trip | test_platform_library.cpp | `AC-STD-2: Load and resolve symbol round-trip` |
| AC-STD-3 | No #ifdef _WIN32 in PlatformLibrary.h | test_ac_1_2_2_header_neutral.cmake | `AC-STD-3:platform-library-header-neutral` |
| AC-STD-3 | Compile-time verification | test_platform_library.cpp | `AC-STD-3: PlatformLibrary.h has no platform conditionals` |

---

## Implementation Checklist

### Header & Interface (Task 1)
- [x] Create `MuMain/src/source/Platform/PlatformLibrary.h` with `#pragma once`
- [x] Define `namespace mu::platform` with `LibraryHandle` type alias
- [x] Declare `[[nodiscard]] LibraryHandle Load(const char* path)`
- [x] Declare `[[nodiscard]] void* GetSymbol(LibraryHandle handle, const char* name)`
- [x] Declare `void Unload(LibraryHandle handle)`
- [x] Header must NOT include `<windows.h>` or `<dlfcn.h>`

### Win32 Backend (Task 2)
- [x] Create directory `MuMain/src/source/Platform/win32/`
- [x] Create `win32/PlatformLibrary.cpp` with LoadLibraryW/GetProcAddress/FreeLibrary
- [x] Implement error logging with `PLAT:` prefix via `g_ErrorReport.Write()`
- [x] Load failure logs reason and returns nullptr
- [x] GetSymbol failure logs symbol name and returns nullptr
- [x] Unload on nullptr is a no-op

### POSIX Backend (Task 3)
- [x] Create directory `MuMain/src/source/Platform/posix/`
- [x] Create `posix/PlatformLibrary.cpp` with dlopen/dlsym/dlclose
- [x] Implement error logging with `PLAT:` prefix (wide string conversion for dlerror)
- [x] Load failure logs dlerror() and returns nullptr
- [x] GetSymbol failure logs symbol name and returns nullptr
- [x] Unload on nullptr is a no-op

### CMake Integration (Task 4)
- [x] Update `MuMain/src/CMakeLists.txt` with `if(WIN32)` backend selection
- [x] MUPlatform transitions from INTERFACE to STATIC with backend sources
- [x] MUPlatform links MUCore (for g_ErrorReport)
- [x] Precompiled headers applied to MUPlatform

### Test Infrastructure (Task 5)
- [x] `test_platform_library.cpp` added to MuTests in `tests/CMakeLists.txt`
- [x] MUPlatform linked to MuTests target
- [ ] All 8 Catch2 test cases compile and pass
- [x] CMake script tests registered in `tests/platform/CMakeLists.txt`
- [x] CMake script tests pass (header neutral + backend selection)

### Quality Gate (Task 6)
- [x] `./ctl check` passes with 0 violations
- [x] `g++ -fsyntax-only -std=c++20 PlatformLibrary.h` passes
- [x] No cppcheck false positives on posix backend (dlopen/dlsym/dlclose)
- [x] No prohibited libraries used
- [x] All test files use Catch2 REQUIRE macros (not CHECK for critical assertions)
- [x] Error logging uses PLAT: taxonomy prefix
- [x] No #ifdef _WIN32 in PlatformLibrary.h (CMake selection only)

---

## PCC Compliance

| Check | Status |
|-------|--------|
| Prohibited libraries | None used |
| Required test patterns | Catch2 v3.7.1 REQUIRE/CHECK |
| Test profiles | N/A (no database/CI profiles) |
| Coverage target | N/A (growing incrementally from 0) |
| Platform conditionals | CMake only (not in header) |
| Naming conventions | mu::platform, PascalCase |
| Error handling | Return codes, no exceptions |
| Logging | g_ErrorReport.Write() with PLAT: prefix |

---

## Test Files Created (RED Phase)

1. `MuMain/tests/platform/test_platform_library.cpp` — 8 Catch2 test cases
2. `MuMain/tests/platform/test_ac_1_2_2_header_neutral.cmake` — CMake script (AC-STD-3, AC-1, AC-6)
3. `MuMain/tests/platform/test_ac_1_2_2_cmake_backend.cmake` — CMake script (AC-4, AC-2, AC-3)

## Modified Files

4. `MuMain/tests/CMakeLists.txt` — Added test_platform_library.cpp to MuTests, linked MUPlatform
5. `MuMain/tests/platform/CMakeLists.txt` — Registered 2 new CMake script tests
