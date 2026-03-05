# Story 1.2.1: Platform Abstraction Headers

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 1 - Platform Foundation & Build System |
| Feature | 1.2 - Platform Abstraction |
| Story ID | 1.2.1 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Code | VS0-PLAT-ABSTRACT-HEADERS |
| FRs Covered | FR1, FR2, FR3 (regression guard) |
| Prerequisites | None — no dependencies (can run parallel with 1.1.x stories) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Add `src/source/Platform/PlatformTypes.h`, `PlatformKeys.h`, `PlatformCompat.h`; include in MUPlatform CMake target; add Catch2 type-size tests |
| project-docs | documentation | Story file, sprint status update, test scenarios |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer,
**I want** cross-platform type aliases and function declarations in shared headers,
**so that** game logic code can use platform-independent types and functions without `#ifdef _WIN32` scattered across game logic files.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `PlatformCompat.h` exists at `MuMain/src/source/Platform/PlatformCompat.h` and declares cross-platform function shims: timing (`timeGetTime()`, `GetTickCount()`), message box (`MessageBoxW`), file I/O (`_wfopen`, `_wfopen_s`), and zero-memory (`RtlSecureZeroMemory`)
- [ ] **AC-2:** `PlatformTypes.h` exists at `MuMain/src/source/Platform/PlatformTypes.h` and defines platform type aliases (`DWORD` → `uint32_t`, `BOOL` → `int`, `BYTE` → `uint8_t`, `WORD` → `uint16_t`, `HANDLE`, `HWND`, `HDC`, `HINSTANCE`, `HFONT`, `HGLRC`, `LPARAM`, `WPARAM`, `LRESULT`, `HRESULT`, `MAX_PATH`, `TRUE`/`FALSE`, `LOWORD`/`HIWORD`, `ZeroMemory`) on non-Windows (`#ifndef _WIN32`). On Windows, the header is a no-op.
- [ ] **AC-3:** Both `PlatformCompat.h` and `PlatformTypes.h` use `#pragma once`, and both are reachable via the MUPlatform CMake target's include path (the `Platform/` directory is on the include path so game code can `#include "PlatformCompat.h"`)
- [ ] **AC-4:** Both headers compile without errors on macOS (Clang), Linux (GCC), and Windows (MSVC/MinGW) — validated by `g++ -fsyntax-only -std=c++20` on Linux/macOS and by the CI MinGW build on Windows
- [ ] **AC-5:** No existing game logic files need modification to compile with these headers — the headers wrap/alias existing types and functions so call sites remain unchanged

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards — `#pragma once` in headers, PascalCase for any functions, no new Win32 API calls introduced into game logic, no `#ifdef _WIN32` scattered outside the Platform headers
- [ ] **AC-STD-2:** Catch2 test in `MuMain/tests/platform/test_platform_types.cpp` validates type size assertions: `sizeof(DWORD) == 4`, `sizeof(BOOL) == sizeof(int)`, `sizeof(BYTE) == 1`, `sizeof(WORD) == 2`; test must pass on MinGW (Windows), Linux GCC, and macOS Clang
- [ ] **AC-STD-3:** Zero `#ifdef _WIN32` leaked into game logic — all platform conditionals are contained within the Platform headers themselves
- [ ] **AC-STD-4:** CI (MinGW cross-compile) quality gate remains green — `make -C MuMain format-check && make -C MuMain lint`
- [ ] **AC-STD-5:** Conventional commit: `refactor(platform): add cross-platform type aliases and compat headers`
- [ ] **AC-STD-11:** Flow Code traceability — commit message references `VS0-PLAT-ABSTRACT-HEADERS`
- [ ] **AC-STD-13:** Quality gate passes — `make -C MuMain format-check && make -C MuMain lint`
- [ ] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [ ] **AC-STD-20:** Contract Reachability — story produces no API/event/flow catalog entries (infrastructure only)

---

## Validation Artifacts

- [ ] **AC-VAL-1:** MinGW CI build passes with new headers (CI log or confirmation)
- [ ] **AC-VAL-2:** Clang compile on macOS (quality check) passes — `./ctl check` output shows no errors
- [ ] **AC-VAL-3:** `g++ -fsyntax-only -std=c++20 PlatformTypes.h` passes on Linux or macOS (compile check without output)
- [ ] **AC-VAL-4:** Catch2 type-size test passes on MinGW CI

---

## Tasks / Subtasks

- [ ] **Task 1: Create `PlatformTypes.h`** (AC: AC-2, AC-3, AC-4)
  - [ ] 1.1 Create `MuMain/src/source/Platform/PlatformTypes.h` with `#pragma once`
  - [ ] 1.2 Wrap all content in `#ifndef _WIN32` / `#endif` so on Windows the file is a no-op
  - [ ] 1.3 Add `typedef uint32_t DWORD;`, `typedef int BOOL;`, `typedef uint8_t BYTE;`, `typedef uint16_t WORD;`
  - [ ] 1.4 Add `typedef void* HANDLE;`, `typedef void* HWND;`, `typedef void* HDC;`, `typedef void* HGLRC;`, `typedef void* HINSTANCE;`, `typedef void* HFONT;`
  - [ ] 1.5 Add `typedef intptr_t LPARAM;`, `typedef uintptr_t WPARAM;`, `typedef intptr_t LRESULT;`, `typedef long HRESULT;`
  - [ ] 1.6 Add `#define MAX_PATH 260`
  - [ ] 1.7 Add `#define TRUE 1`, `#define FALSE 0`
  - [ ] 1.8 Add `#define LOWORD(l) ((WORD)(((DWORD_PTR)(l)) & 0xffff))`, `#define HIWORD(l) ((WORD)((((DWORD_PTR)(l)) >> 16) & 0xffff))`
  - [ ] 1.9 Add `#define ZeroMemory(Destination, Length) memset((Destination), 0, (Length))` (requires `<cstring>` include in the `#else` branch)
  - [ ] 1.10 Add required standard includes in the `#else` branch: `<cstdint>`, `<cstring>`, `<climits>`

- [ ] **Task 2: Create `PlatformKeys.h`** (AC: AC-4 — bonus file per CROSS_PLATFORM_PLAN Session 0.2)
  - [ ] 2.1 Create `MuMain/src/source/Platform/PlatformKeys.h` with `#pragma once`
  - [ ] 2.2 Wrap all content in `#ifndef _WIN32` / `#endif`
  - [ ] 2.3 Define all ~40 VK_* constants used in the codebase using Windows numeric values: `VK_LBUTTON` (0x01), `VK_RBUTTON` (0x02), `VK_MBUTTON` (0x04), `VK_ESCAPE` (0x1B), `VK_RETURN` (0x0D), `VK_SPACE` (0x20), `VK_PRIOR` (0x21), `VK_NEXT` (0x22), `VK_END` (0x23), `VK_HOME` (0x24), `VK_LEFT` (0x25), `VK_UP` (0x26), `VK_RIGHT` (0x27), `VK_DOWN` (0x28), `VK_INSERT` (0x2D), `VK_DELETE` (0x2E), `VK_F1`–`VK_F12` (0x70–0x7B), `VK_CONTROL` (0x11), `VK_SHIFT` (0x10), `VK_MENU` (0x12), `VK_TAB` (0x09), `VK_BACK` (0x08), `VK_NUMPAD0`–`VK_NUMPAD9` (0x60–0x69)

- [ ] **Task 3: Create `PlatformCompat.h`** (AC: AC-1, AC-4, AC-5)
  - [ ] 3.1 Create `MuMain/src/source/Platform/PlatformCompat.h` with `#pragma once`
  - [ ] 3.2 Wrap all content in `#ifndef _WIN32` / `#endif`
  - [ ] 3.3 Add timing shims (in the `#else` branch):
    ```cpp
    #include <chrono>
    inline uint32_t timeGetTime() {
        using namespace std::chrono;
        return static_cast<uint32_t>(
            duration_cast<milliseconds>(steady_clock::now().time_since_epoch()).count()
        );
    }
    inline uint32_t GetTickCount() { return timeGetTime(); }
    ```
  - [ ] 3.4 Add `MessageBoxW` shim — requires SDL3 headers (defer full implementation to story 1.3.1 when SDL3 is available; for now declare as stub returning 0 with `IDOK`):
    ```cpp
    // MB_ flag constants
    #define MB_OK        0x00
    #define MB_YESNO     0x04
    #define MB_OKCANCEL  0x01
    #define MB_ICONERROR 0x10
    #define MB_ICONWARNING  0x30
    #define MB_ICONSTOP  0x10
    #define MB_ICONINFORMATION 0x40
    // Return values
    #define IDOK     1
    #define IDCANCEL 2
    #define IDYES    6
    #define IDNO     7
    // Stub (full SDL3 impl added in 1.3.1 when SDL3 available)
    inline int MessageBoxW(void*, const wchar_t*, const wchar_t*, unsigned int) { return IDOK; }
    #define MessageBox MessageBoxW
    ```
  - [ ] 3.5 Add `_wfopen` / `_wfopen_s` shims — convert wchar_t path to UTF-8 and call POSIX `fopen`:
    ```cpp
    #include <cstdio>
    #include <string>
    #include <locale>
    #include <codecvt>
    // Convert wchar_t path (UTF-32 on Linux/macOS) to UTF-8, normalize backslashes
    inline FILE* mu_wfopen(const wchar_t* path, const wchar_t* mode) {
        // Convert to std::string (UTF-8) via wstring_convert
        std::wstring_convert<std::codecvt_utf8<wchar_t>> conv;
        std::string u8path = conv.to_bytes(path);
        std::string u8mode = conv.to_bytes(mode);
        // Normalize backslashes to forward slashes
        for (auto& c : u8path) { if (c == '\\') c = '/'; }
        return fopen(u8path.c_str(), u8mode.c_str());
    }
    inline errno_t _wfopen_s(FILE** pFile, const wchar_t* path, const wchar_t* mode) {
        *pFile = mu_wfopen(path, mode);
        return (*pFile) ? 0 : errno;
    }
    #define _wfopen mu_wfopen
    ```
    **NOTE:** `std::wstring_convert` is deprecated in C++17 but available in C++20. The CROSS_PLATFORM_PLAN specifies this approach. The replacement (manually iterating wchar_t and converting) is more complex — use wstring_convert for now with a suppressed deprecation warning.
  - [ ] 3.6 Add `RtlSecureZeroMemory` shim:
    ```cpp
    inline void* mu_SecureZeroMemory(void* ptr, size_t cnt) {
        volatile char* vptr = static_cast<volatile char*>(ptr);
        while (cnt--) *vptr++ = 0;
        return ptr;
    }
    #define RtlSecureZeroMemory mu_SecureZeroMemory
    ```
  - [ ] 3.7 Add `#include "PlatformTypes.h"` at the top of `PlatformCompat.h` so all shims have the type aliases available

- [ ] **Task 4: Verify MUPlatform CMake target includes the Platform/ directory** (AC: AC-3)
  - [ ] 4.1 Read `MuMain/src/CMakeLists.txt` lines 268-277 — MUPlatform currently uses `file(GLOB)` on `Platform/*.cpp`
  - [ ] 4.2 Since headers-only stories produce no `.cpp` files, MUPlatform may remain INTERFACE — verify include path is propagated
  - [ ] 4.3 Confirm `${MU_SOURCE_DIR}/Platform` is in MUCommon or MUPlatform's include directories so `#include "PlatformTypes.h"` resolves from game code
  - [ ] 4.4 If the include path is NOT already set: add `target_include_directories(MUPlatform INTERFACE "${MU_SOURCE_DIR}/Platform")` — but verify first that `${MU_SOURCE_DIR}` already covers `Platform/` via the existing directory structure
  - [ ] 4.5 Check: `MuMain/src/CMakeLists.txt` near line 165-175 shows `target_include_directories` with `"${MU_SOURCE_DIR}/Platform"` — confirm this covers the new headers

- [ ] **Task 5: Create Catch2 type-size test** (AC: AC-STD-2)
  - [ ] 5.1 Create `MuMain/tests/platform/` directory if it doesn't exist
  - [ ] 5.2 Create `MuMain/tests/platform/test_platform_types.cpp`:
    ```cpp
    #include "PlatformTypes.h"
    #include <catch2/catch_test_macros.hpp>
    #include <cstdint>

    TEST_CASE("PlatformTypes size assertions", "[platform][types]")
    {
        SECTION("DWORD is 4 bytes")
        {
            REQUIRE(sizeof(DWORD) == 4);
        }
        SECTION("BOOL is same size as int")
        {
            REQUIRE(sizeof(BOOL) == sizeof(int));
        }
        SECTION("BYTE is 1 byte")
        {
            REQUIRE(sizeof(BYTE) == 1);
        }
        SECTION("WORD is 2 bytes")
        {
            REQUIRE(sizeof(WORD) == 2);
        }
        SECTION("TRUE and FALSE are defined")
        {
            REQUIRE(TRUE == 1);
            REQUIRE(FALSE == 0);
        }
    }
    ```
  - [ ] 5.3 Register the test in `MuMain/tests/CMakeLists.txt` or a new `MuMain/tests/platform/CMakeLists.txt`
  - [ ] 5.4 Confirm the test builds and passes with `-DBUILD_TESTING=ON` on MinGW CI

- [ ] **Task 6: Quality gate and validation** (AC: AC-STD-4, AC-VAL-1, AC-VAL-2)
  - [ ] 6.1 Run `make -C MuMain format-check` — confirm no format violations in changed files
  - [ ] 6.2 Run `make -C MuMain lint` (cppcheck) — confirm no new warnings
  - [ ] 6.3 On macOS: `./ctl check` confirms headers are parseable by Clang (syntax check)
  - [ ] 6.4 Validate `g++ -fsyntax-only -std=c++20 MuMain/src/source/Platform/PlatformTypes.h` (on Linux/macOS)

---

## Error Codes Introduced

_None — this is a build system / infrastructure story. No error codes are introduced._

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
| Type size assertions | Catch2 v3.7.1 | N/A | `sizeof(DWORD)==4`, `sizeof(BYTE)==1`, `sizeof(WORD)==2`, `sizeof(BOOL)==sizeof(int)`, `TRUE==1`, `FALSE==0` |
| Syntax compile check | GCC/Clang `-fsyntax-only` | N/A | `PlatformTypes.h`, `PlatformCompat.h`, `PlatformKeys.h` each compile standalone |
| Build regression | CMake + MinGW CI | N/A | Windows MinGW cross-compile continues to pass |

_No Catch2 integration or E2E tests are required. The primary test vehicle is Catch2 type-size assertions + standalone compile checks._

---

## Dev Notes

### Overview

This story creates the **platform abstraction headers** that will eventually allow game logic code to compile on Linux and macOS without `#ifdef _WIN32` scattered at every call site. The approach is:

1. Headers are **additive only** — no existing files are modified (per CROSS_PLATFORM_PLAN Session 0.1-0.3 rules: "Additive sessions before substitutive sessions")
2. All platform conditionals are **contained in the Platform headers** — game logic remains unchanged
3. On Windows, the headers are **no-ops** (wrapped in `#ifndef _WIN32`) — the Windows build is completely unaffected

The CMake build already has an MUPlatform target that uses `file(GLOB)` on `Platform/*.cpp`. Since this story creates headers only (no `.cpp` files), MUPlatform will remain an INTERFACE target. The include path for `Platform/` must be verified to be on the include path reachable by game code.

### Critical Architecture from CROSS_PLATFORM_PLAN

Per `docs/CROSS_PLATFORM_PLAN.md` Sessions 0.1-0.3, the headers cover these areas:

**`PlatformTypes.h` (Session 0.1):**
- Windows type aliases as typedefs: `DWORD`, `BOOL`, `BYTE`, `WORD`, `HANDLE`, `HWND`, `HDC`, `HGLRC`, `HFONT`, `HINSTANCE`, `LPARAM`, `WPARAM`, `LRESULT`, `HRESULT`
- `MAX_PATH` constant (= 260)
- `TRUE`/`FALSE` macros
- `LOWORD`/`HIWORD` macros
- `ZeroMemory` macro (maps to `memset`)
- Requires `<cstdint>`, `<cstring>`, `<climits>` in the `#else` branch

**`PlatformKeys.h` (Session 0.2):**
- All ~40 `VK_*` key code constants used in the codebase
- Uses the same Windows numeric values so no game code needs changing
- Only active on `#ifndef _WIN32`

**`PlatformCompat.h` (Session 0.3):**
- `timeGetTime()` / `GetTickCount()` → `std::chrono::steady_clock` shims (105+ call sites)
- `MessageBoxW` stub (181 call sites — full SDL3 implementation added in story 1.3.1)
- `_wfopen` / `_wfopen_s` → UTF-8 + path normalization shims (60 call sites)
- `RtlSecureZeroMemory` → `volatile memset` shim
- MB_* and IDOK/IDCANCEL/IDYES/IDNO constants

### Important: MessageBoxW Stub Strategy

The full `MessageBoxW` shim requires SDL3 (`SDL_ShowSimpleMessageBox`) which is added in story 1.3.1. For this story, a **stub returning IDOK** is acceptable per the story scope — it keeps headers compiling without SDL3. The stub MUST be clearly commented as a temporary placeholder:

```cpp
// TEMPORARY STUB: Full SDL3 implementation added in story 1.3.1
// Returns IDOK for all cases until SDL3 is available
inline int MessageBoxW(void* /*hwnd*/, const wchar_t* /*text*/, const wchar_t* /*caption*/, unsigned int /*type*/) {
    return IDOK;
}
```

### Platform/ Include Path — Current CMake State

From `MuMain/src/CMakeLists.txt` lines 165-175, `target_include_directories` for `MUCommon` includes `"${MU_SOURCE_DIR}/Platform"`. Since `MUCommon` is an INTERFACE target propagated to all other targets, this means `Platform/` is already on the include path for all game code. The new headers are immediately findable as `#include "PlatformTypes.h"` from any game source file.

**Verify this before Task 4** — read the actual target_include_directories in CMakeLists.txt to confirm. If `Platform/` is NOT listed, add it to MUPlatform's INTERFACE include directories.

### wstring_convert Deprecation Warning

`std::wstring_convert` is deprecated in C++17 (C++26 will likely remove it). The CROSS_PLATFORM_PLAN specifies it for the `_wfopen` shim as the pragmatic solution given the scale (60 call sites). Suppress the deprecation warning per-header:

```cpp
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
// ... wstring_convert usage ...
#pragma GCC diagnostic pop
```

For MSVC, wrap in `#ifdef __GNUC__`. This is acceptable technical debt documented in the header. The CROSS_PLATFORM_PLAN does not specify the deprecation suppression explicitly but it is needed for `-Werror` builds.

Alternatively, implement the UTF-8 conversion manually using a simple loop if the deprecation suppression adds complexity. The manual approach is ~15 lines and avoids the deprecated API entirely.

### Catch2 Test Registration

The existing test infrastructure (from story 1.1.2) shows `MuMain/tests/build/CMakeLists.txt` is the pattern. For platform tests:

1. Create `MuMain/tests/platform/CMakeLists.txt` with `add_test(...)` registration
2. Add `add_subdirectory(platform)` to `MuMain/tests/CMakeLists.txt`
3. The `MuTests` target already links Catch2 and uses CTest

Check `MuMain/tests/CMakeLists.txt` for the existing pattern before creating new CMake files.

### Lessons from Previous Stories (1.1.1, 1.1.2)

From the story 1.1.2 Dev Agent Record (code review findings):
- **CRITICAL pattern:** Do NOT commit build artifacts (`build-test/`, CMake output dirs) — they are already gitignored
- **JSON validation:** When editing `CMakePresets.json`, always validate with `python3 -m json.tool`
- **Test SKIP on wrong OS:** Use host OS checks in shell scripts (AC-3 for 1.1.2 correctly SKIPs on macOS)
- **cmake `-B` override:** Do NOT override preset's `binaryDir` in test scripts — let the preset use its own `binaryDir`
- For this story, the Catch2 test must compile and pass on MinGW (Windows) since the types on Windows come from `<windows.h>` — the test is cross-platform

### `DWORD_PTR` Note

`LOWORD`/`HIWORD` macros in PlatformTypes.h reference `DWORD_PTR` (pointer-sized unsigned integer). On 64-bit Linux/macOS, this should be `typedef uintptr_t DWORD_PTR;`. Add this typedef before the `LOWORD`/`HIWORD` macros.

### Cross-Platform Rules (Critical — Cannot Be Skipped)

Per `docs/development-standards.md` §1 Cross-Platform Readiness:
- `#ifdef _WIN32` ONLY in Platform header files — NEVER in game logic (MUCore, MUGame, etc.)
- `#pragma once` in all headers (no `#ifndef` guards)
- No backslash path literals — the `_wfopen` shim normalizes existing ones
- No `NULL` — use `nullptr` in any C++ code added
- CI (MinGW) build must remain green

Per the CROSS_PLATFORM_PLAN Iteration Safety Rules:
- **Additive only** — create new files, do NOT modify any existing game logic files
- Windows x64 build must still compile after this story
- Git branch before implementation (the branch is the rollback boundary)

### PCC Project Constraints

**Tech Stack:** C++20 game client — CMake 3.25+, Ninja generator, Clang/GCC/MSVC/MinGW, Catch2 v3.7.1

**Required Patterns (from project-context.md):**
- `#pragma once` — no `#ifndef` guards
- `std::chrono::steady_clock` for timing shims (not `timeGetTime` in new code — but the shim wraps the old API)
- `std::unique_ptr`, `nullptr` in any new C++ code
- Return codes (`bool`/`int`) — no exceptions
- `[[nodiscard]]` on new fallible functions (none in this story — these are header-only shims)

**Prohibited Patterns (from project-context.md):**
- No `#ifdef _WIN32` in game logic — only in Platform headers
- No new `wprintf` logging — not applicable here (header shims only)
- No raw `new`/`delete` — not applicable (no allocations in these headers)
- No backslash path literals
- Do NOT modify generated files in `src/source/Dotnet/`

**Quality Gate Command:** `make -C MuMain format-check && make -C MuMain lint`

**Commit Format:** `refactor(platform): add cross-platform type aliases and compat headers`

### Schema Alignment

Not applicable — C++20 game client with no schema validation tooling (noted in sprint-status.yaml).

### References

- [Source: docs/CROSS_PLATFORM_PLAN.md §Phase 0 Sessions 0.1–0.3] — exact specification of what each header must contain
- [Source: docs/development-standards.md §1 Cross-Platform Readiness] — banned APIs, platform abstraction rules
- [Source: _bmad-output/project-context.md §Critical Implementation Rules] — C++ language rules, prohibited patterns
- [Source: MuMain/src/CMakeLists.txt lines 268-277] — MUPlatform CMake target definition (currently INTERFACE)
- [Source: MuMain/src/CMakeLists.txt lines 165-175] — include directory setup (confirm Platform/ is included)
- [Source: _bmad-output/implementation-artifacts/1-1-1/story.md §Dev Notes] — CMakePresets.json JSON validation pattern
- [Source: _bmad-output/implementation-artifacts/1-1-2/story.md §Dev Agent Record] — lessons from code review (build artifacts, test SKIP patterns)
- [Source: _bmad-output/planning-artifacts/epics.md §Story 1.2.1] — original acceptance criteria

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

_None — story creation only._

### Completion Notes List

- Story created 2026-03-04 via create-story workflow (agent: claude-sonnet-4-6)
- No specification corpus available (specification-index.yaml not found)
- No story partials found in docs/story-partials/
- Story type: `infrastructure` (platform headers only — no frontend, no API)
- Schema alignment: N/A (no API schemas affected — C++20 game client, noted in sprint-status.yaml)
- Previous sibling stories: 1.1.1 (macOS CMake) and 1.1.2 (Linux CMake) reviewed for patterns and lessons
- Git context: Main branch, last 8 commits are story pipeline artifacts for 1-1-1-macos and docs-only for planning
- Platform/ directory currently empty — MUPlatform is INTERFACE target in CMakeLists.txt
- Story is additive-only (no existing file modifications) — lowest-risk story in Epic 1
- MessageBoxW: stub returning IDOK chosen for this story (full SDL3 impl deferred to 1.3.1 per scope)
- `std::wstring_convert` used for `_wfopen` shim — deprecated in C++17, consider manual UTF-8 loop if `-Wdeprecated` causes CI issues
- `PlatformKeys.h` included in scope per CROSS_PLATFORM_PLAN Session 0.2 (not explicitly in epics.md ACs, but needed for cross-platform compilation completeness and unblocks future stories)

### File List

_Files to be created/modified by the dev agent implementing this story:_

- [CREATE] `MuMain/src/source/Platform/PlatformTypes.h` — Windows type aliases (no-op on Windows)
- [CREATE] `MuMain/src/source/Platform/PlatformKeys.h` — VK_* key constants (no-op on Windows)
- [CREATE] `MuMain/src/source/Platform/PlatformCompat.h` — Function shims: timing, MessageBoxW stub, _wfopen, RtlSecureZeroMemory (no-op on Windows)
- [CREATE] `MuMain/tests/platform/CMakeLists.txt` — CTest registration for platform type tests
- [CREATE] `MuMain/tests/platform/test_platform_types.cpp` — Catch2 type-size assertions
- [MODIFY] `MuMain/tests/CMakeLists.txt` — Add `add_subdirectory(platform)` (if not already present)
- [VERIFY/POSSIBLY MODIFY] `MuMain/src/CMakeLists.txt` — Confirm `Platform/` is on include path; add `target_include_directories` if needed (read first before modifying)
