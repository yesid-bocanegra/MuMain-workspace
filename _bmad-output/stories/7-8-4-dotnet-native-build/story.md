# Story 7.8.4: .NET Client Library Native Build

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.8 - Remaining Build Blockers |
| Story ID | 7.8.4 |
| Story Points | 3 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-BUILD-DOTNET |
| FRs Covered | All platforms are first-class build targets — .NET Client Library must build natively on macOS and Linux |
| Prerequisites | 7-6-1-macos-native-build-compilation (done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Fix `src/CMakeLists.txt` DOTNET_RID to detect host platform; fix hardcoded `.dll` extension in copy command; guard `#include "resource.h"` in `Winmain.cpp`; set `MU_ENABLE_DOTNET=ON` (or equivalent) in macOS/Linux presets |
| project-docs | documentation | Story artifacts |

---

## Background

The C++ side is already done:
- `Dotnet/Connection.cpp:22-27` uses `MU_DOTNET_LIB_EXT` (cmake-defined: `.dll`/`.dylib`/`.so`) — no change needed
- `Platform/posix/PlatformLibrary.cpp` uses `dlopen`/`dlsym` — no change needed
- `Platform/win32/PlatformLibrary.cpp` uses `LoadLibrary`/`GetProcAddress` — no change needed

Only the cmake build logic is broken.

---

## Story

**[VS-0] [Flow:E]**

**As a** developer building the game client on macOS/Linux,
**I want** the .NET Client Library to build for the native host platform,
**so that** `MUnique.Client.Library` compiles on macOS (`osx-arm64`) and Linux (`linux-x64`) without attempting cross-OS Native AOT compilation.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `src/CMakeLists.txt` lines 691-699 — replace the hardcoded `win-x64`/`win-x86` RID with host-platform detection:
  - macOS arm64 → `osx-arm64`, platform `arm64`
  - macOS x64 → `osx-x64`, platform `x64`
  - Linux x64 → `linux-x64`, platform `x64`
  - Linux arm64 → `linux-arm64`, platform `arm64`
  - Windows x64 → `win-x64`, platform `x64` (existing behavior, unchanged)
  - Windows x86 → `win-x86`, platform `x86` (existing behavior, unchanged)

- [ ] **AC-2:** `src/CMakeLists.txt:712` — the `copy_if_different` command hardcodes `.dll` as the output filename (`MUnique.Client.Library.dll`). Replace with the platform-correct extension matching what `dotnet publish` actually produces:
  - macOS: `MUnique.Client.Library.dylib`
  - Linux: `MUnique.Client.Library.so`
  - Windows: `MUnique.Client.Library.dll`
  - Use the cmake variable `MU_DOTNET_LIB_EXT` (already defined elsewhere and used in `Connection.h`) for the extension.

- [ ] **AC-3:** `CMakePresets.json` — remove `MU_ENABLE_DOTNET: OFF` from `macos-base` and `linux-base` (or change the legacy build path guard so it works correctly for all platforms). The .NET library must now build on all platforms, not be skipped.

- [ ] **AC-4:** `src/source/Main/Winmain.cpp` — wrap `#include "resource.h"` in `#ifdef _WIN32` / `#endif`. This is a Windows RC-compiler artifact with no cross-platform compat stub; it causes "file not found" on macOS/Linux.

- [ ] **AC-5:** `cmake --build --preset macos-arm64-debug` succeeds — the `.NET` target builds an `osx-arm64` native library without the "Cross-OS native compilation is not supported" error.

- [ ] **AC-6:** `./ctl check` passes — build + tests + format-check + lint all green.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — cmake changes follow existing style; clang-format clean on any C++ changes.
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [ ] **Task 1: Fix DOTNET_RID platform detection** (AC-1)
  - [ ] 1.1: Replace `if(CMAKE_SIZEOF_VOID_P EQUAL 8) set(DOTNET_RID "win-x64")` block with nested platform+arch detection
  - [ ] 1.2: Add `CMAKE_SYSTEM_NAME` check for Darwin, Linux, Windows to select correct RID family
  - [ ] 1.3: Within each OS, check `CMAKE_SYSTEM_PROCESSOR` or `CMAKE_SIZEOF_VOID_P` for architecture

- [ ] **Task 2: Fix hardcoded .dll extension in cmake copy command** (AC-2)
  - [ ] 2.1: Determine the platform-correct output filename produced by `dotnet publish`
  - [ ] 2.2: Replace the hardcoded `MUnique.Client.Library.dll` path in the `copy_if_different` command

- [ ] **Task 3: Fix MU_ENABLE_DOTNET in cmake presets** (AC-3)
  - [ ] 3.1: Read what the `MU_ENABLE_DOTNET` flag actually controls in the build logic
  - [ ] 3.2: Either remove `MU_ENABLE_DOTNET: OFF` from macos-base/linux-base, or fix the condition so the build runs on all platforms

- [ ] **Task 4: Guard resource.h** (AC-4)
  - [ ] 4.1: Wrap `#include "resource.h"` in `Winmain.cpp` with `#ifdef _WIN32` / `#endif`

- [ ] **Task 5: Verify** (AC-5, AC-6)
  - [ ] 5.1: Run `cmake --build --preset macos-arm64-debug` — confirm .NET library builds for `osx-arm64`
  - [ ] 5.2: Run `./ctl check`

---

## Standard Acceptance Criteria (Optional)

- [ ] **AC-STD-2:** Testing Requirements — Infrastructure change; no new unit tests required (cmake configuration update)
- [ ] **AC-STD-12:** SLI/SLO Targets — Not applicable (build-time change, no runtime SLOs)

---

## Dev Notes

### Implementation Strategy

**RID Detection Logic:**
- CMake platform detection: `CMAKE_SYSTEM_NAME` (Darwin, Linux, Windows) and `CMAKE_SYSTEM_PROCESSOR` (arm64, x86_64, x86)
- Map to RID family: `osx`, `linux`, `win`
- Combine with architecture: e.g., `osx-arm64`, `linux-x64`, `win-x86`

**Extension Handling:**
- Use `MU_DOTNET_LIB_EXT` variable (already used in `Connection.h`)
- Set in CMakeLists.txt: `.dll` (Windows), `.dylib` (macOS), `.so` (Linux)
- Reference in `copy_if_different` command for generated library path

**Platform Presets:**
- macOS (`macos-arm64`, `macos-x86-64`): Remove or flip `MU_ENABLE_DOTNET: OFF` condition
- Linux (`linux-base`): Remove or flip `MU_ENABLE_DOTNET: OFF` condition
- Windows (unchanged): Keep existing behavior

**Resource Header Guard:**
- `resource.h` is generated by Windows RC compiler (MSVC)
- Wrapped in `#ifdef _WIN32` prevents "file not found" on macOS/Linux

### Cross-Platform Considerations

- `.NET 10 Native AOT` supports `osx-arm64`, `osx-x64`, `linux-x64`, `linux-arm64` as RIDs
- WSL interop: `dotnet.exe` via `/mnt/c/Program Files/dotnet/dotnet.exe` still used on Linux/WSL
- No code changes required on C++ side; cmake logic is the blocker

### Verification

After fixes:
1. macOS arm64 build: `cmake --build --preset macos-arm64-debug` → `osx-arm64` native library generated
2. Linux x64 build: `cmake --build --preset linux-base` → `linux-x64` native library generated
3. Quality gate: `./ctl check` passes format-check + lint
