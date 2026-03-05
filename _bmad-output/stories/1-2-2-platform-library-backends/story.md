# Story 1.2.2: MUPlatform Library with win32/posix Backends

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 1 - Platform Foundation & Build System |
| Feature | 1.2 - Platform Abstraction |
| Story ID | 1.2.2 |
| Story Points | 5 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Code | VS0-PLAT-LIBRARY-BACKENDS |
| FRs Covered | FR9 (partial — dynamic library loading), FR1, FR2, FR3 (regression guard) |
| Prerequisites | 1.2.1 (Platform Abstraction Headers — DONE) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Add `src/source/Platform/PlatformLibrary.h`, `win32/PlatformLibrary.cpp`, `posix/PlatformLibrary.cpp`; CMake backend selection; Catch2 tests |
| project-docs | documentation | Story file, sprint status update, test scenarios |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer,
**I want** a PlatformLibrary abstraction for dynamic library loading with win32 and posix implementations,
**so that** .NET AOT and any future dynamic libraries can be loaded without platform-specific code in game logic.

---

## Functional Acceptance Criteria

- [x] **AC-1:** `PlatformLibrary.h` exists at `MuMain/src/source/Platform/PlatformLibrary.h` and defines interface: `Load(path) -> handle`, `GetSymbol(handle, name) -> pointer`, `Unload(handle)` — all in the `mu::platform` namespace with `[[nodiscard]]` on fallible functions
- [x] **AC-2:** `MuMain/src/source/Platform/win32/PlatformLibrary.cpp` implements the interface via `LoadLibraryW`/`GetProcAddress`/`FreeLibrary` (Win32 backend)
- [x] **AC-3:** `MuMain/src/source/Platform/posix/PlatformLibrary.cpp` implements the interface via `dlopen`/`dlsym`/`dlclose` (POSIX backend for Linux and macOS)
- [x] **AC-4:** `MuMain/src/CMakeLists.txt` selects the correct backend using CMake platform detection: `if(WIN32)` sources `win32/PlatformLibrary.cpp`, else sources `posix/PlatformLibrary.cpp`; both compile only on their respective platforms
- [x] **AC-5:** Error handling: Load failure logs `PLAT: PlatformLibrary::Load() failed — <reason>` using `g_ErrorReport.Write()` and returns a null handle; `GetSymbol` failure logs `PLAT: PlatformLibrary::GetSymbol(<name>) failed` and returns `nullptr`; `Unload` on null handle is a no-op
- [x] **AC-6:** All fallible functions (`Load`, `GetSymbol`) are annotated with `[[nodiscard]]` and return bool or null-check-able handle types; callers are expected to check return values

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code follows project-context.md standards — `#pragma once` in headers, `mu::platform` namespace, PascalCase function names, `m_` prefix for any members, no new Win32 API calls in the header, no `#ifdef _WIN32` in `PlatformLibrary.h` — only in the backend `.cpp` files and CMake selection
- [x] **AC-STD-2:** Catch2 tests in `MuMain/tests/platform/test_platform_library.cpp` cover: (a) load a known shared library (e.g., the C runtime or a known system library), (b) resolve a known symbol from that library, (c) verify null handle returned on missing library path, (d) verify null returned from `GetSymbol` on invalid symbol name; tests must compile and pass on MinGW (Windows), Linux GCC, and macOS Clang
- [x] **AC-STD-3:** No `#ifdef _WIN32` in `PlatformLibrary.h` — compile-time CMake source selection is the only platform conditional; the header is platform-neutral
- [x] **AC-STD-4:** CI quality gate passes — `make -C MuMain format-check && make -C MuMain lint`
- [x] **AC-STD-5:** Error logging uses `PLAT:` prefix taxonomy (e.g., `PLAT: PlatformLibrary::Load() failed — <GetLastError()/dlerror()>`)
- [x] **AC-STD-6:** Conventional commit: `feat(platform): implement PlatformLibrary with win32/posix backends`
- [x] **AC-STD-11:** Flow Code traceability — commit message references `VS0-PLAT-LIBRARY-BACKENDS`
- [x] **AC-STD-12:** SLI/SLO — N/A for infrastructure story; no latency or availability SLOs apply (build-time artifact, no runtime service introduced)
- [x] **AC-STD-13:** Quality gate passes — `make -C MuMain format-check && make -C MuMain lint`
- [x] **AC-STD-14:** Observability — N/A for infrastructure story; `g_ErrorReport.Write()` provides post-mortem tracing via `PLAT:` prefix taxonomy; no runtime metrics or structured logs required
- [x] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [x] **AC-STD-16:** Error codes — no new error codes registered in error-catalog.md; `PLAT:` prefix is a logging taxonomy prefix only, not a registered error code
- [x] **AC-STD-20:** Contract Reachability — story produces no API/event/flow catalog entries (infrastructure only)

---

## Validation Artifacts

- [x] **AC-VAL-1:** Catch2 test passes on MinGW CI (Windows cross-compile — test must use a library available in MinGW environment)
- [x] **AC-VAL-2:** Manual dlopen smoke test on macOS: load a known .dylib (e.g., `libSystem.B.dylib`) and resolve a known symbol; log output shows no errors
- [x] **AC-VAL-3:** `g++ -fsyntax-only -std=c++20 PlatformLibrary.h` passes on Linux or macOS (compile check without linking)
- [x] **AC-VAL-4:** CMake configure log shows correct backend selected per platform (`win32/PlatformLibrary.cpp` on Windows, `posix/PlatformLibrary.cpp` on Linux/macOS)

---

## Tasks / Subtasks

- [x] **Task1: Create `PlatformLibrary.h` interface header** (AC: AC-1, AC-3, AC-6)
  - [x]1.1 Create `MuMain/src/source/Platform/PlatformLibrary.h` with `#pragma once`
  - [x]1.2 Define `namespace mu::platform` (C++17 nested namespace, C++20 compatible)
  - [x]1.3 Define opaque handle type: `using LibraryHandle = void*;`
  - [x]1.4 Declare `[[nodiscard]] LibraryHandle Load(const char* path)` — returns `nullptr` on failure
  - [x]1.5 Declare `[[nodiscard]] void* GetSymbol(LibraryHandle handle, const char* name)` — returns `nullptr` on failure
  - [x]1.6 Declare `void Unload(LibraryHandle handle)` — no-op on null
  - [x]1.7 Header must NOT include `<windows.h>` or `<dlfcn.h>` — backend implementations include those
  - [x]1.8 Verify `#include "PlatformLibrary.h"` resolves from any game source (Platform/ is on MUCommon include path — line 171 in CMakeLists.txt)

- [x] **Task2: Create win32 backend** (AC: AC-2, AC-5)
  - [x]2.1 Create directory `MuMain/src/source/Platform/win32/`
  - [x]2.2 Create `MuMain/src/source/Platform/win32/PlatformLibrary.cpp`
  - [x]2.3 Include `<windows.h>` and `"PlatformLibrary.h"` and `"ErrorReport.h"`
  - [x]2.4 Implement `mu::platform::Load(const char* path)`:
    - Convert `path` to wide string for `LoadLibraryW` using `MultiByteToWideChar` or a simple loop
    - On failure: call `g_ErrorReport.Write(L"PLAT: PlatformLibrary::Load() failed — %lu\r\n", GetLastError())` then return `nullptr`
    - On success: return `HMODULE` cast to `void*`
  - [x]2.5 Implement `mu::platform::GetSymbol(LibraryHandle handle, const char* name)`:
    - Cast handle to `HMODULE`, call `GetProcAddress`
    - On failure: `g_ErrorReport.Write(L"PLAT: PlatformLibrary::GetSymbol(%hs) failed\r\n", name)` return `nullptr`
  - [x]2.6 Implement `mu::platform::Unload(LibraryHandle handle)`:
    - If `handle == nullptr`: return immediately (no-op)
    - Cast to `HMODULE`, call `FreeLibrary`

- [x] **Task3: Create posix backend** (AC: AC-3, AC-5)
  - [x]3.1 Create directory `MuMain/src/source/Platform/posix/`
  - [x]3.2 Create `MuMain/src/source/Platform/posix/PlatformLibrary.cpp`
  - [x]3.3 Include `<dlfcn.h>` and `"PlatformLibrary.h"` and `"ErrorReport.h"`
  - [x]3.4 Implement `mu::platform::Load(const char* path)`:
    - Call `dlopen(path, RTLD_LAZY | RTLD_LOCAL)`
    - On failure: `g_ErrorReport.Write(L"PLAT: PlatformLibrary::Load() failed — %hs\r\n", dlerror())` then return `nullptr`
    - On success: return the handle directly (already `void*`)
  - [x]3.5 Implement `mu::platform::GetSymbol(LibraryHandle handle, const char* name)`:
    - Call `dlsym(handle, name)`
    - On failure (nullptr): `g_ErrorReport.Write(L"PLAT: PlatformLibrary::GetSymbol(%hs) failed\r\n", name)` return `nullptr`
    - Note: `dlsym` returns `nullptr` for both missing symbols AND symbols with value 0; this is acceptable for function pointers
  - [x]3.6 Implement `mu::platform::Unload(LibraryHandle handle)`:
    - If `handle == nullptr`: return (no-op)
    - Call `dlclose(handle)`

- [x] **Task4: Update CMakeLists.txt for platform-selected backend** (AC: AC-4)
  - [x]4.1 Read `MuMain/src/CMakeLists.txt` lines 268-277 — current `file(GLOB MU_PLATFORM_SOURCES)` pattern
  - [x]4.2 Replace or augment the MUPlatform `file(GLOB)` with explicit platform-conditional source selection:
    ```cmake
    # Platform-selected backend sources
    if(WIN32)
        set(MU_PLATFORM_BACKEND_SOURCES
            "${MU_SOURCE_DIR}/Platform/win32/PlatformLibrary.cpp"
        )
    else()
        set(MU_PLATFORM_BACKEND_SOURCES
            "${MU_SOURCE_DIR}/Platform/posix/PlatformLibrary.cpp"
        )
    endif()
    file(GLOB MU_PLATFORM_SOURCES CONFIGURE_DEPENDS "${MU_SOURCE_DIR}/Platform/*.cpp")
    list(APPEND MU_PLATFORM_SOURCES ${MU_PLATFORM_BACKEND_SOURCES})
    ```
  - [x]4.3 Verify MUPlatform target now has sources and builds as `STATIC` (not INTERFACE)
  - [x]4.4 Verify MUPlatform still links `MUCore` (for `g_ErrorReport`)
  - [x]4.5 Verify `precompile_headers(REUSE_FROM MUCore)` is applied to MUPlatform when it has sources
  - [x]4.6 If MUPlatform transitions from INTERFACE to STATIC, verify MUGame still links correctly (it already has `MUPlatform` in `target_link_libraries`)

- [x] **Task5: Create Catch2 tests** (AC: AC-STD-2, AC-VAL-1)
  - [x]5.1 Create `MuMain/tests/platform/test_platform_library.cpp`
  - [x]5.2 Include `<catch2/catch_test_macros.hpp>` and `"PlatformLibrary.h"`
  - [x]5.3 Add test: Load a system library that exists on all platforms:
    - On Windows (MinGW): load `"kernel32.dll"` — always present
    - On Linux: load `"libm.so.6"` (or `"libdl.so.2"`) — available in MinGW test environment? (use conditional compile)
    - On macOS: load `"libSystem.B.dylib"`
    - Use `#ifdef _WIN32` / `#else` in the test file ONLY (test platform selection is acceptable — it's not game logic)
  - [x]5.4 Add test: Resolve a known symbol from the loaded library (e.g., `GetTickCount` from `kernel32.dll`, `sin` from `libm`)
  - [x]5.5 Add test: Load a non-existent library path returns `nullptr` (e.g., `"definitely_does_not_exist_12345.so"`)
  - [x]5.6 Add test: `GetSymbol` with invalid name on valid handle returns `nullptr`
  - [x]5.7 Add test: `Unload(nullptr)` does not crash (no-op safety)
  - [x]5.8 Add `test_platform_library.cpp` to `MuTests` in `MuMain/tests/CMakeLists.txt`
  - [x]5.9 Verify all tests compile with `-DBUILD_TESTING=ON` and pass on macOS Clang
  - [x]5.10 Add `target_link_libraries(MuTests PRIVATE ... MUPlatform)` if not already linked (tests need the implementation)

- [x] **Task6: Quality gate and validation** (AC: AC-STD-4, AC-VAL-2, AC-VAL-3)
  - [x]6.1 Run `./ctl check` (format-check + cppcheck lint) — must pass with 0 violations
  - [x]6.2 Run `g++ -fsyntax-only -std=c++20 MuMain/src/source/Platform/PlatformLibrary.h` on macOS — must pass
  - [x]6.3 Manually verify dlopen smoke test on macOS (if available)
  - [x]6.4 Verify `win32/` and `posix/` subdirectories are not caught by `cppcheck` ThirdParty exclusion (they are inside `Platform/`, not `ThirdParty/`)

---

## Error Codes Introduced

_None — this is a build system / infrastructure story. No game-level error codes are introduced. The `PLAT:` prefix is a logging taxonomy prefix, not a registered error code._

---

## Contract Catalog Entries

### API Contracts

_None — infrastructure story. No API endpoints introduced._

### Event Contracts

_None — infrastructure story. No events introduced._

### Navigation Entries

_Not applicable — infrastructure story (not frontend)._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit — Load success | Catch2 v3.7.1 | N/A | Load known system library, returns non-null handle |
| Unit — Symbol resolution | Catch2 v3.7.1 | N/A | `GetSymbol` on valid handle + known symbol returns non-null |
| Unit — Load failure | Catch2 v3.7.1 | N/A | Load non-existent path returns `nullptr` |
| Unit — Symbol failure | Catch2 v3.7.1 | N/A | `GetSymbol` with invalid name returns `nullptr` |
| Unit — Unload null safety | Catch2 v3.7.1 | N/A | `Unload(nullptr)` does not crash |
| Syntax compile check | GCC/Clang `-fsyntax-only` | N/A | `PlatformLibrary.h` compiles standalone |
| Build regression | CMake + MinGW CI | N/A | Windows MinGW cross-compile continues to pass |
| CMake backend selection | Manual log inspection | N/A | Correct `.cpp` selected per platform |

_No integration or E2E tests required. The primary test vehicle is Catch2 unit tests + standalone compile check + CMake configure verification._

---

## Dev Notes

### Overview

This story creates the **PlatformLibrary abstraction** for dynamic library loading. The goal is to allow the `.NET AOT` bridge (`Dotnet/Connection.h`) and future platform libraries to be loaded without `#ifdef _WIN32` in game logic. The approach follows the same additive pattern as Story 1.2.1:

1. **Header is platform-neutral** — `PlatformLibrary.h` has no platform conditionals
2. **Backend selection is at the CMake level** — `win32/PlatformLibrary.cpp` vs `posix/PlatformLibrary.cpp`
3. **This story is additive** — only new files are created; no existing game logic files are modified
4. **MUPlatform transitions from INTERFACE to STATIC** — this is the first story that adds `.cpp` files to the Platform/ directory

### Critical Architecture from CROSS_PLATFORM_PLAN

Per `docs/CROSS_PLATFORM_PLAN.md` Phase 0 / Phase 8 (Session 8.2), the future use of PlatformLibrary is:

```cpp
// Future Connection.h usage (Phase 8 / Story 3.1.2):
#ifdef __linux__
    mu::platform::Load("libMUnique.Client.Library.so");
#elif __APPLE__
    mu::platform::Load("libMUnique.Client.Library.dylib");
#endif
```

However, **this story does NOT modify Connection.h**. It only creates the abstraction layer that Story 3.1.2 (`3-1-2-connection-h-crossplatform`) will use. Scope is strictly limited to creating the PlatformLibrary interface and backends.

### MUPlatform CMake Transition: INTERFACE → STATIC

Currently (from `MuMain/src/CMakeLists.txt` lines 268-277), MUPlatform is:

```cmake
file(GLOB MU_PLATFORM_SOURCES CONFIGURE_DEPENDS "${MU_SOURCE_DIR}/Platform/*.cpp")
if(MU_PLATFORM_SOURCES)
  add_library(MUPlatform STATIC ${MU_PLATFORM_SOURCES})
  target_link_libraries(MUPlatform PRIVATE MUCore)
  target_precompile_headers(MUPlatform REUSE_FROM MUCore)
else()
  # Empty directory — create INTERFACE placeholder until Phase 0 adds files
  add_library(MUPlatform INTERFACE)
endif()
```

After this story adds `win32/PlatformLibrary.cpp` or `posix/PlatformLibrary.cpp`, the `file(GLOB)` will NOT pick them up automatically because they are in subdirectories. The CMake change in Task 4 must explicitly add the backend sources. The condition `if(MU_PLATFORM_SOURCES)` should then become true (because of the backend source list), and MUPlatform becomes STATIC.

**Key risk:** If only subdirectory sources exist and `file(GLOB)` only matches `Platform/*.cpp` (not `Platform/**/*.cpp`), the glob will remain empty. The solution is to use an explicit `set()` for the backend source rather than relying on glob. See Task 4.2 for the approach.

**Another risk:** When MUPlatform transitions from INTERFACE to STATIC, it gains `target_precompile_headers(REUSE_FROM MUCore)`. This requires MUCore's PCH to be compatible with the `win32/` and `posix/` source files. The PCH includes `<windows.h>` on Windows — this is fine for `win32/PlatformLibrary.cpp`. On POSIX builds via CI (Linux), `<windows.h>` is not included in the PCH — the posix backend should work cleanly.

### Interface Design: `PlatformLibrary.h`

```cpp
#pragma once

#include <cstddef>  // for nullptr_t if needed

namespace mu::platform
{

using LibraryHandle = void*;

[[nodiscard]] LibraryHandle Load(const char* path);
[[nodiscard]] void* GetSymbol(LibraryHandle handle, const char* name);
void Unload(LibraryHandle handle);

}  // namespace mu::platform
```

Key decisions:
- `const char*` over `std::string` — avoids dependency on `<string>` in a header that may be included everywhere
- `void*` for handle — opaque, no Windows types leak into header
- `using` alias over `typedef` — per `modernize-use-using` (clang-tidy enforcement)
- `namespace mu::platform` — C++17 nested namespace syntax, valid in C++20

### Win32 Backend: `win32/PlatformLibrary.cpp`

Error formatting note: `GetLastError()` returns `DWORD` (uint32_t). Use `%lu` format specifier:
```cpp
g_ErrorReport.Write(L"PLAT: PlatformLibrary::Load() failed — %lu\r\n", GetLastError());
```

Path conversion for `LoadLibraryW`: `Connection.h` will pass UTF-8 paths. A simple ASCII-to-wide conversion is sufficient for library names (system paths are ASCII). If full UTF-8 support is needed, use `MultiByteToWideChar(CP_UTF8, 0, path, -1, wbuf, MAX_PATH)`.

### POSIX Backend: `posix/PlatformLibrary.cpp`

`dlerror()` resets after each call. Call it immediately after `dlopen` failure:
```cpp
void* handle = dlopen(path, RTLD_LAZY | RTLD_LOCAL);
if (!handle)
{
    const char* err = dlerror();
    g_ErrorReport.Write(L"PLAT: PlatformLibrary::Load() failed — %hs\r\n", err ? err : "(unknown)");
    return nullptr;
}
```

`%hs` in `g_ErrorReport.Write()` — this is MSVC-specific format specifier for narrow strings in wide format strings. On GCC/Clang with `wprintf`-compatible format, `%s` in `L"..."` expects `wchar_t*`. Use a local `wchar_t` buffer with `mbstowcs` or format the error into a wide string:
```cpp
// Safe approach for POSIX backend:
wchar_t wErr[256] = {};
mbstowcs(wErr, err ? err : "(unknown)", sizeof(wErr) / sizeof(wchar_t) - 1);
g_ErrorReport.Write(L"PLAT: PlatformLibrary::Load() failed — %ls\r\n", wErr);
```

### Test Library Selection for Cross-Platform Catch2 Tests

The test must use a library available on all CI platforms:

| Platform | Test Library | Known Symbol |
|----------|-------------|--------------|
| MinGW/Windows | `"kernel32.dll"` | `"GetTickCount"` |
| Linux (GCC) | `"libm.so.6"` | `"sin"` |
| macOS (Clang) | `"libSystem.B.dylib"` | `"strlen"` |

Use `#ifdef _WIN32` / `#elif __APPLE__` / `#else` in the test file to select the library path. This is acceptable in test files (tests are not game logic).

**MinGW CI consideration:** The MinGW cross-compile CI builds a Windows `.exe`. In CI, there is no `kernel32.dll` available for `dlopen` during cross-compilation test runs. The Catch2 test runs on the host (Linux in CI), not the target. Verify whether `MuTests` is run in CI after cross-compilation or only on native builds. If CI does not run tests (only builds), mark AC-VAL-1 as validated when the build succeeds.

Check the CI pipeline in `MuMain/.github/workflows/ci.yml` to understand if `ctest` is run. If tests are only built (not run) in CI, the test compilation passing is sufficient for AC-VAL-1.

### Lessons from Story 1.2.1 (Predecessor Intelligence)

From `_bmad-output/implementation-artifacts/1-2-1/story.md` Dev Agent Record:

1. **Reserved identifiers:** Do NOT name internal functions with underscore prefixes. Use `mu_` or similar. For PlatformLibrary, all functions are in `mu::platform` namespace — no reserved identifier issues.
2. **Surrogate codepoint filtering in UTF-8 conversion:** Not applicable here (we're passing `char*` paths directly to OS APIs, not doing our own UTF-8 conversion).
3. **Test enforcement vs. silent pass:** Tests must actively fail when their assertion fails. Ensure Catch2 `REQUIRE` is used (not `CHECK`) for critical assertions where test continuation on failure is not desired.
4. **`./ctl check` before submitting:** Run the quality gate before code review. It catches clang-format violations and cppcheck warnings.
5. **JSON validation for CMakePresets.json:** If CMakePresets.json is edited, validate with `python3 -m json.tool`. This story does NOT edit CMakePresets.json (only src/CMakeLists.txt).
6. **Additive only:** No existing game logic files should be modified. CMakeLists.txt is the only existing file that needs a change (to add the backend source to MUPlatform).

### Lessons from Stories 1.1.1 and 1.1.2 (Earlier Stories)

From code review findings:
- Do NOT commit build artifacts (`build-test/`, CMake output dirs) — gitignored
- When adding new CMake targets or modifying existing ones, verify the change works on macOS quality check (`./ctl check`) even though macOS cannot build the full game

### cppcheck Considerations

- `win32/PlatformLibrary.cpp` is inside `source/Platform/win32/` — cppcheck by default runs on `source/.*`. Verify the cppcheck Makefile excludes `ThirdParty/` but includes `Platform/win32/`.
- From project-context.md: cppcheck skips `ThirdParty/` entirely but Platform/ is in scope.
- The win32 backend uses `LoadLibraryW`, `GetProcAddress`, `FreeLibrary` — these are not in cppcheck's win32W platform model as issues.
- The posix backend uses `dlopen`/`dlsym`/`dlclose` — on `win32W` platform model (used in CI), these will be unknown symbols. Verify that cppcheck does not produce false positives for these unknown symbols. If it does, add per-file suppression: `// cppcheck-suppress unknownFunction` or update cppcheck suppressions.

### cppcheck Platform Model Note

CI runs cppcheck with `--platform=win32W`. The `posix/PlatformLibrary.cpp` file uses `dlopen` which is not in the Win32 platform model. Options:
1. Add `posix/` to the cppcheck exclusion list (clean, but maintains exclusion list)
2. Add `// cppcheck-suppress` directives for `unknownFunction` in the posix backend
3. Configure cppcheck to use different platform models per file (complex)

Option 2 is recommended: add targeted suppressions in `posix/PlatformLibrary.cpp` for any cppcheck warnings about `dlopen`/`dlsym`/`dlclose`. Check what cppcheck actually reports before deciding which suppressions are needed.

### File Includes in Backend `.cpp` Files

Both backend files must include `"ErrorReport.h"` for `g_ErrorReport`. Since `stdafx.h` is the PCH and `g_ErrorReport` is declared in `ErrorReport.h`, verify:
- `stdafx.h` includes `ErrorReport.h` (check `MuMain/src/source/Main/stdafx.h`)
- If `ErrorReport.h` is in the PCH, then `win32/PlatformLibrary.cpp` and `posix/PlatformLibrary.cpp` get it via the PCH (REUSE_FROM MUCore)
- If not in PCH, explicitly include `"ErrorReport.h"` in each backend file

From `MuMain/src/source/Main/stdafx.h` — verify the include. If it is not present, add the explicit include.

### g_ErrorReport.Write() Format Strings

The `g_ErrorReport` uses wide-format printf. Confirmed format specifiers:
- `%lu` — `DWORD` (uint32_t) from `GetLastError()` — Windows only
- `%ls` — `wchar_t*` — wide string
- `%hs` — narrow `char*` — MSVC-specific extension; NOT standard on GCC/Clang

On POSIX backends (GCC/Clang), use `%s` is invalid in wide-format (`L"..."`) strings. Convert the narrow error message to wide before passing to `g_ErrorReport.Write()`. See the `mbstowcs` approach in the POSIX Backend section above.

### Cross-Platform Rules (Critical)

Per `docs/development-standards.md` §1:
- `#ifdef _WIN32` ONLY in Platform backend source files (`win32/` directory) — NOT in `PlatformLibrary.h`
- CMake `if(WIN32)` is the platform selection mechanism — clean, no C++ preprocessor in headers
- `#pragma once` in header (no `#ifndef` guards)
- No backslash path literals in new code
- No `NULL` — use `nullptr`
- CI (MinGW) build must remain green

Per CROSS_PLATFORM_PLAN Iteration Safety Rules:
- **Additive only** — create new files, modify only `MuMain/src/CMakeLists.txt`
- Windows x64 build must still compile after this story (invariant)
- Git branch before implementation (the branch is the rollback boundary)

### SAFe Context

This story unblocks **EPIC-3** (`3-1-2-connection-h-crossplatform` has `1.2.2` as a prerequisite per sprint-status.yaml). Completing this story on time is critical to the Epic 3 start date.

### PCC Project Constraints

**Tech Stack:** C++20 game client — CMake 3.25+, Ninja generator, Clang/GCC/MSVC/MinGW, Catch2 v3.7.1

**Required Patterns (from project-context.md):**
- `#pragma once` — no `#ifndef` guards
- `std::chrono::steady_clock` for timing — not applicable here
- `std::unique_ptr`, `nullptr` in any new C++ code — handle is `void*` (opaque), no smart pointer needed here
- Return codes (`bool`/`void*`/null-check-able) — no exceptions
- `[[nodiscard]]` on new fallible functions — applied to `Load` and `GetSymbol`
- `mu::` namespace for new code — using `mu::platform` nested namespace

**Prohibited Patterns (from project-context.md):**
- No `#ifdef _WIN32` in `PlatformLibrary.h` — only in backend `.cpp` files
- No new `wprintf` logging — use `g_ErrorReport`
- No raw `new`/`delete` — not applicable (no heap allocations in this story)
- No backslash path literals
- Do NOT modify generated files in `src/source/Dotnet/`
- No `NULL` — use `nullptr`

**Quality Gate Command:** `make -C MuMain format-check && make -C MuMain lint`

**Commit Format:** `feat(platform): implement PlatformLibrary with win32/posix backends`

### Schema Alignment

Not applicable — C++20 game client with no schema validation tooling (noted in sprint-status.yaml). Schema alignment section omitted.

### References

- [Source: docs/CROSS_PLATFORM_PLAN.md §Phase 0 Session 0.4+, Phase 8 Session 8.2] — PlatformLibrary as dynamic loading abstraction, future Connection.h usage
- [Source: docs/development-standards.md §1 Cross-Platform Readiness] — banned APIs, platform abstraction rules
- [Source: _bmad-output/project-context.md §Critical Implementation Rules] — C++ language rules, prohibited patterns, CMake module targets
- [Source: MuMain/src/CMakeLists.txt lines 268-277] — current MUPlatform CMake target definition (INTERFACE placeholder)
- [Source: MuMain/src/CMakeLists.txt line 171] — Platform/ on include path via MUCommon INTERFACE target
- [Source: _bmad-output/implementation-artifacts/1-2-1/story.md §Dev Notes + Dev Agent Record] — lessons from previous story (reserved identifiers, UTF-8 conversion, test patterns)
- [Source: _bmad-output/planning-artifacts/epics.md §Story 1.2.2] — original acceptance criteria
- [Source: _bmad-output/implementation-artifacts/sprint-status.yaml] — sprint context, critical path (1.2.2 unblocks EPIC-3)
- [Source: MuMain/tests/CMakeLists.txt] — existing test infrastructure pattern (Catch2 FetchContent, MuTests executable)
- [Source: MuMain/tests/platform/CMakeLists.txt] — platform test registration pattern from Story 1.2.1

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (story creation)

### Debug Log References

### Completion Notes List

- Story created 2026-03-04 via create-story workflow (agent: claude-sonnet-4-6)
- No specification corpus available (specification-index.yaml not found)
- No story partials found in docs/story-partials/
- Story type: `infrastructure` (C++ platform abstraction — no frontend, no API)
- Schema alignment: N/A (no API schemas affected — C++20 game client)
- Prerequisite story 1.2.1 (Platform Abstraction Headers) is DONE — all three headers (PlatformTypes.h, PlatformKeys.h, PlatformCompat.h) created and quality gate passed
- Platform/ directory currently contains only headers — MUPlatform is INTERFACE target; this story transitions it to STATIC
- Key architectural insight: CMake `if(WIN32)` used for backend selection (NOT `#ifdef _WIN32` in headers)
- Critical dependency: this story unblocks EPIC-3 (story 3-1-2-connection-h-crossplatform)
- Git context: Main branch, last 5 commits are story 1-2-1 pipeline artifacts
- Story is additive-only except for CMakeLists.txt update — lowest-risk modification pattern

### Design Screen Status

design_status: SKIPPED
reason: Infrastructure story — no Visual Design Specification section. Story type is `infrastructure` (C++ platform abstraction, no UI). Pencil design system also not initialized (pencil.style_guide.initialized: false). Design screen step not applicable for backend-only stories. Matches precedent from story 1.2.1 which also skipped design-screen.
skipped_at: 2026-03-04

### File List

- [CREATE] `MuMain/src/source/Platform/PlatformLibrary.h` — Platform-neutral interface for dynamic library loading (mu::platform namespace)
- [CREATE] `MuMain/src/source/Platform/win32/PlatformLibrary.cpp` — Win32 backend via LoadLibraryW/GetProcAddress/FreeLibrary
- [CREATE] `MuMain/src/source/Platform/posix/PlatformLibrary.cpp` — POSIX backend via dlopen/dlsym/dlclose
- [CREATE] `MuMain/tests/platform/test_platform_library.cpp` — Catch2 unit tests for Load, GetSymbol, Unload
- [MODIFY] `MuMain/src/CMakeLists.txt` — Add platform-conditional backend source to MUPlatform target
- [MODIFY] `MuMain/tests/CMakeLists.txt` — Add test_platform_library.cpp to MuTests + link MUPlatform
- [CREATE] `MuMain/tests/platform/CMakeLists.txt` — Register CMake script tests for platform validation
- [CREATE] `MuMain/tests/platform/test_ac_1_2_2_header_neutral.cmake` — CMake script test for header neutrality (AC-STD-3, AC-1, AC-6)
- [CREATE] `MuMain/tests/platform/test_ac_1_2_2_cmake_backend.cmake` — CMake script test for backend selection (AC-4, AC-2, AC-3)
