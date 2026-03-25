# Story 7.6.1: macOS Native Build — Remaining Compilation Gaps

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.6 - macOS Build Completion |
| Story ID | 7.6.1 |
| Story Points | 5 |
| Priority | P0 - Must Have (blocks 7-3-1 stability session) |
| Story Type | infrastructure |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Code | VS0-QUAL-BUILDCOMP-MACOS |
| FRs Covered | FR1 (Build MuMain from source on macOS) |
| Prerequisites | 7-5-1 (quality gate bypass removed, WinINet + `__stdcall` stubs added) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Fix remaining compilation errors in MURenderFX, MUAudio, MUThirdParty targets |
| mumain | backend | Fix build toolchain config in `.pcc-config.yaml`, `ctl`, and `macos-arm64.cmake` |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer,
**I want** `./ctl build` to compile the native macOS arm64 binary with zero errors using Homebrew Clang,
**so that** macOS is a first-class build platform and the 7-3-1 stability session can proceed.

---

## Context: Why This Story Exists

Story 7-5-1 removed the quality gate bypass and fixed widespread Win32 type errors. However, three CMake targets still fail to compile on macOS because of remaining Win32 API headers being included unconditionally:

| Failing Target | Root Cause |
|----------------|------------|
| `MURenderFX` | `ZzzOpenglUtil.cpp` includes `wglext.h` (WGL — Windows OpenGL extensions) unconditionally |
| `MUAudio` | `DSwaveIO.h` includes `<mmsystem.h>` (Windows Multimedia API) unconditionally |
| `MUThirdParty` | `UIControls.cpp` — missing GDI/timer stubs + 8 code correctness bugs; `xstreambuf.cpp` — invalid `delete void*` |

Additionally, `PosixSignalHandlers.cpp` (from story 7-1-2, done) uses `SA_SIGACTION` which does not exist on macOS — the correct POSIX constant is `SA_SIGINFO`.

Finally, `./ctl build` and `.pcc-config.yaml` use Apple Clang 17 (the macOS system default) instead of Homebrew LLVM 22. This was the root cause of the `-Wnontrivial-memcall` pragma failure in story 7-5-1 — the pragma was written for Homebrew Clang but the build uses Apple Clang.

---

## Pattern: How to Fix Win32 API Compilation Errors on macOS

The project rule is: **no `#ifdef _WIN32` in game logic** — only in platform abstraction headers. This means:

### Approach A — CMake Exclusion (for purely Windows TUs)
When a source file is entirely Windows-specific (e.g., WGL context, DirectX, DirectSound), exclude it from non-Windows builds in `CMakeLists.txt`:
```cmake
if(WIN32)
    target_sources(MURenderFX PRIVATE source/RenderFX/ZzzOpenglUtil.cpp)
endif()
```
The file stays untouched. SDL3 GPU replaces WGL — the file will be deleted in a future story.

### Approach B — Header Include Guard (for headers with Win32 includes)
When a header's `#include <winapi.h>` line is the problem, guard just the include. This is allowed because headers ARE the platform abstraction boundary:
```cpp
// DSwaveIO.h
#ifdef _WIN32
#include <mmsystem.h>
#endif
```
Any types from `mmsystem.h` used in the header's declarations must also be guarded or replaced with stubs (Approach C).

### Approach C — PlatformCompat.h Stubs (for Win32 types needed by shared declarations)
Add stubs to `PlatformCompat.h` in the `#else // !_WIN32` section. This is the established pattern from stories 7-3-0 and 7-5-1. The stubs are no-ops — the code compiles but the Windows-only feature is inactive on macOS.

### Approach D — Fix Real Code Bugs
Some errors are genuine C++ bugs that happen to be ignored on MSVC but caught by Clang:
- `delete void*` — invalid C++, use typed pointer
- `NULL` compared to `wchar_t` — use `L'\0'`
- Sign comparison — use explicit casts
- Tautological comparisons — remove dead conditions

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `cmake --build build` with Homebrew Clang 22 produces zero errors (all targets build)
- [ ] **AC-2:** `./ctl build` uses Homebrew Clang from `/opt/homebrew/opt/llvm/bin/` (not Apple Clang `/usr/bin/c++`)
- [ ] **AC-3:** `.pcc-config.yaml` `build` command specifies Homebrew LLVM and removes the stale "Will fail on macOS" comment
- [ ] **AC-4:** `quality_gate` in `.pcc-config.yaml` includes `&& cmake --build build` since the build now passes
- [ ] **AC-5:** `ZzzOpenglUtil.cpp` excluded from macOS CMake build (WGL is Windows-only, replaced by SDL3 GPU)
- [ ] **AC-6:** `DSwaveIO.h` `#include <mmsystem.h>` guarded with `#ifdef _WIN32`; any `MMRESULT`/`WAVEFORMATEX` uses in the header also guarded
- [ ] **AC-7:** `UIControls.cpp` missing stubs (`RGB`, `SetBkColor`, `SetTextColor`, `TextOut`, `WM_PAINT`, `WM_ERASEBKGND`, `SB_VERT`, `GCS_COMPSTR`, `SetTimer`) added to `PlatformCompat.h`; code bugs fixed in same file
- [ ] **AC-8:** `xstreambuf.cpp` `delete void*` fixed (3 occurrences)
- [ ] **AC-9:** `PosixSignalHandlers.cpp` `SA_SIGACTION` replaced with `SA_SIGINFO` (correct POSIX flag; `SA_SIGACTION` does not exist on macOS)
- [ ] **AC-10:** `ZzzOpenData.cpp` pragma uses `__has_warning("-Wnontrivial-memcall")` guard (version-safe across Apple Clang 17 and Homebrew Clang 22)
- [ ] **AC-11:** MinGW CI build continues to pass (no regression)

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code standards — no new `#ifdef _WIN32` in game logic; stubs go in `PlatformCompat.h`; CMake exclusions in `CMakeLists.txt`
- [ ] **AC-STD-2:** Testing — `./ctl build` succeeds; `./ctl check` (format + lint) continues to pass
- [ ] **AC-STD-11:** Flow code `VS0-QUAL-BUILDCOMP-MACOS` in commit messages
- [ ] **AC-STD-13:** Quality gate passes (`./ctl check && ./ctl build`)
- [ ] **AC-STD-15:** Git safety — conventional commits

---

## Validation Artifacts

- [ ] **AC-VAL-1:** `cmake --build build 2>&1 | grep "^FAILED:"` returns empty
- [ ] **AC-VAL-2:** `cmake --build build 2>&1 | grep "Build complete"` shows success
- [ ] **AC-VAL-3:** `./ctl check` passes (format + lint — no regression)
- [ ] **AC-VAL-CONFIG:** `.pcc-config.yaml` `build` command contains `/opt/homebrew/opt/llvm/bin/clang++`

---

## Tasks / Subtasks

- [ ] **Task 1: Fix build toolchain config** (AC-2, AC-3, AC-4)
  - [ ] 1.1: Update `.pcc-config.yaml` `build` command: add `-DCMAKE_C_COMPILER=/opt/homebrew/opt/llvm/bin/clang -DCMAKE_CXX_COMPILER=/opt/homebrew/opt/llvm/bin/clang++`; remove stale macOS comment; add build to `quality_gate`
  - [ ] 1.2: Update `ctl` `cmd_build` to match `.pcc-config.yaml`
  - [ ] 1.3: Update `MuMain/cmake/toolchains/macos-arm64.cmake` to prefer Homebrew LLVM: use `find_program` to locate `/opt/homebrew/opt/llvm/bin/clang`
  - [ ] 1.4: Delete stale `build/` cache: `rm -rf build/` before rebuilding

- [ ] **Task 2: Fix MURenderFX — WGL exclusion** (AC-1, AC-5)
  - [ ] 2.1: In `MuMain/src/CMakeLists.txt`, wrap `ZzzOpenglUtil.cpp` in `if(WIN32)` block for `MURenderFX` target
  - [ ] 2.2: Verify `MURenderFX` builds without error on macOS after exclusion

- [ ] **Task 3: Fix MUAudio — mmsystem.h guard** (AC-1, AC-6)
  - [ ] 3.1: In `src/source/Audio/DSwaveIO.h`, wrap `#include <mmsystem.h>` with `#ifdef _WIN32 / #endif`
  - [ ] 3.2: Wrap any `MMRESULT`, `WAVEFORMATEX`, `HWAVEOUT` types in `DSwaveIO.h` declarations with `#ifdef _WIN32`
  - [ ] 3.3: Verify `MUAudio` builds without error on macOS

- [ ] **Task 4: Fix MUThirdParty — UIControls stubs and code bugs** (AC-1, AC-7)
  - [ ] 4.1: Add missing GDI/timer stubs to `PlatformCompat.h` (non-Windows section):
    - `RGB(r,g,b)` macro → `((r) | ((g) << 8) | ((b) << 16))`
    - `SetBkColor(hdc, color)` → no-op inline returning 0
    - `SetTextColor(hdc, color)` → no-op inline returning 0
    - `TextOut(hdc, x, y, str, len)` → no-op inline returning FALSE
    - `WM_PAINT` → `#define WM_PAINT 0x000F`
    - `WM_ERASEBKGND` → `#define WM_ERASEBKGND 0x0014`
    - `SB_VERT` → `#define SB_VERT 1`
    - `GCS_COMPSTR` → `#define GCS_COMPSTR 0x0008`
    - `SetTimer(hwnd, id, ms, fn)` → no-op inline returning 0
  - [ ] 4.2: Fix code bugs in `UIControls.cpp` (Clang errors, not MSVC warnings):
    - Line ~4073: `NULL` compared to `wchar_t` → use `L'\0'`
    - Line ~4092: `GCS_COMPSTR` (now stubbed — verify fix)
    - Line ~4410: Sign comparison `int` vs `size_t` → cast to `int`
    - Line ~5089, ~5461, ~5633: `NULL` assigned to `wchar_t` → use `L'\0'`
    - Line ~5292: `NOCOM (-1)` vs `BYTE` tautological comparison → use `static_cast<int>(val) == NOCOM` or guard with `#if`
    - Line ~6427, ~6574: Array compared to null pointer (always true) → remove null check or use `[0] == L'\0'`

- [ ] **Task 5: Fix MUThirdParty — xstreambuf.cpp** (AC-1, AC-8)
  - [ ] 5.1: In `xstreambuf.cpp`, lines 33, 73, 113: replace `delete void*` with correct typed delete (inspect what type the pointer actually is and cast before delete, or use `free()` if it's `malloc`-allocated)

- [ ] **Task 6: Fix PosixSignalHandlers.cpp** (AC-9)
  - [ ] 6.1: Replace `SA_SIGACTION` with `SA_SIGINFO` in `PosixSignalHandlers.cpp` (macOS and Linux both define `SA_SIGINFO`; `SA_SIGACTION` is non-standard and absent on macOS)

- [ ] **Task 7: Fix ZzzOpenData.cpp pragma** (AC-10)
  - [ ] 7.1: Wrap the `-Wnontrivial-memcall` pragma with `__has_warning`:
    ```cpp
    #if defined(__has_warning) && __has_warning("-Wnontrivial-memcall")
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wnontrivial-memcall"
    #endif
        ZeroMemory(Models, MAX_MODELS * sizeof(BMD));
    #if defined(__has_warning) && __has_warning("-Wnontrivial-memcall")
    #pragma clang diagnostic pop
    #endif
    ```

- [ ] **Task 8: Verify full build passes** (AC-1, AC-VAL-1, AC-VAL-2)
  - [ ] 8.1: `rm -rf build && ./ctl build` — must succeed with zero errors
  - [ ] 8.2: `./ctl check` — must pass (no format or lint regressions)

---

## Error Codes Introduced

None — infrastructure story.

---

## Contract Catalog Entries

None — no API, event, or navigation contracts.

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Build verification | CMake + Ninja | All targets compile | `cmake --build build` exits 0 |
| Quality gate | clang-format + cppcheck | All files | `./ctl check` exits 0 |
| Regression | MinGW CI | Windows build unchanged | CI pipeline green |

---

## Dev Notes

### Critical: Which Compiler Wins

`./ctl build` currently resolves to `/usr/bin/c++` = Apple Clang 17. Homebrew LLVM 22 lives at `/opt/homebrew/opt/llvm/bin/clang++`. The build MUST explicitly pass the compiler path to CMake — do not rely on PATH ordering.

After changing the compiler, **delete the `build/` cache first** (`rm -rf build/`). CMake caches the compiler and will silently use the stale Apple Clang if the cache dir exists.

Verify after configure:
```bash
grep "CMAKE_CXX_COMPILER:FILEPATH" build/CMakeCache.txt
# Must show: /opt/homebrew/opt/llvm/bin/clang++
```

### ZzzOpenglUtil.cpp — WGL Context

This file implements WGL (Windows OpenGL extensions) context creation. On macOS the rendering pipeline uses SDL3 GPU / Metal (from EPIC-4). The file is completely dead on macOS — there is no OpenGL WGL on macOS. Correct fix: CMake exclusion, not stubbing. The file will be deleted in a later EPIC-4 cleanup story.

`wglext.h` is a vendored header in `src/dependencies/include/`. It uses `DECLARE_HANDLE` which is a Windows macro from `<windows.h>`. Adding stubs for `DECLARE_HANDLE` would trigger a cascade of other WGL type failures — CMake exclusion is the only clean path.

### DSwaveIO.h — DirectSound/WinMM

This header is part of the legacy DirectSound audio path, replaced by miniaudio in EPIC-5. The `#include <mmsystem.h>` guard with `#ifdef _WIN32` is the minimal fix. The entire file will be deleted in a future EPIC-5 cleanup story.

Inspect what types from `mmsystem.h` are used in `DSwaveIO.h` declarations — `MMRESULT`, `HWAVEOUT`, `WAVEFORMATEX` are common. These need `#ifdef _WIN32` guards around their usage in the header, or the file needs to be excluded via CMake (same as Approach A).

### UIControls.cpp — GDI Stubs

`UIControls.cpp` is a ThirdParty file (no lint/format enforcement per project rules). The missing stubs (`RGB`, `SetBkColor`, `SetTextColor`, `TextOut`, `WM_PAINT`, `WM_ERASEBKGND`, `SB_VERT`, `GCS_COMPSTR`, `SetTimer`) are all from Windows GDI + Win32 APIs. On macOS these should be no-ops — the legacy Win32 rendering path is dead (replaced by SDL3 GPU). Add all stubs to `PlatformCompat.h` in the non-Windows section.

The 8 code bugs are genuine C++ correctness issues that MSVC historically accepted as warnings or silently ignored. Clang is stricter. These are not false positives — fix them.

### xstreambuf.cpp — delete void*

`delete void*` is undefined behavior in C++ — the compiler doesn't know which destructor to call. Inspect what the `void*` actually points to:
- If it's a `char` buffer from `new char[]`: use `delete[] static_cast<char*>(ptr)`
- If it's from `malloc`: use `free(ptr)`

### PosixSignalHandlers.cpp — SA_SIGACTION vs SA_SIGINFO

`SA_SIGACTION` is not a POSIX constant. The correct flag to use the 3-argument signal handler form (`void handler(int, siginfo_t*, void*)`) is `SA_SIGINFO`. Both macOS and Linux define `SA_SIGINFO`. This is a bug in story 7-1-2 that wasn't caught because the macOS build was bypassed at the time.

### `.pcc-config.yaml` Build Comment

The comment "Will fail on macOS (Win32 APIs)" is stale after this story. Update it to reflect the current state: native macOS arm64 build enabled with Homebrew LLVM.

### References

- Platform abstraction pattern: `src/source/Platform/PlatformCompat.h` (established in 7-3-0, extended in 7-5-1)
- CMake target structure: `MuMain/src/CMakeLists.txt`
- macOS toolchain: `MuMain/cmake/toolchains/macos-arm64.cmake`
- Build config: `.pcc-config.yaml` + `ctl`
- WGL header: `MuMain/src/dependencies/include/wglext.h`
- [Source: _bmad-output/project-context.md — "No `#ifdef _WIN32` in game logic"]
- [Source: CLAUDE.md — "macOS — Native Build (arm64)"]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

Build error log (2026-03-24): `cmake --build build -j$(nproc) 2>&1 | grep -E "^FAILED:|error:"` revealed:
- `MURenderFX`: wglext.h `DECLARE_HANDLE` cascade
- `MUAudio`: `mmsystem.h` not found
- `MUThirdParty/UIControls.cpp`: RGB, GDI stubs + code bugs
- `MUThirdParty/xstreambuf.cpp`: delete void*
- `Platform/posix/PosixSignalHandlers.cpp`: SA_SIGACTION undefined

### Completion Notes List

### File List
