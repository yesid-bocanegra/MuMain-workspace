# Story 1.1.1: Create macOS CMake Toolchain & Presets

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 1 - Platform Foundation & Build System |
| Feature | 1.1 - CMake Toolchains |
| Story ID | 1.1.1 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Code | VS0-PLAT-CMAKE-MACOS |
| FRs Covered | FR1, FR3 (regression guard) |
| Prerequisites | None — no dependencies |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Add `cmake/toolchains/macos-arm64.cmake`, update `CMakePresets.json` with macOS presets |
| project-docs | documentation | Story file, test scenarios for epic-1 |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer,
**I want** CMake toolchain files and presets for macOS (arm64 + x64),
**so that** I can build MuMain natively on macOS with a single `cmake --preset` command.

---

## Functional Acceptance Criteria

- [x] **AC-1:** `MuMain/cmake/toolchains/macos-arm64.cmake` exists with Clang compiler configuration, `CMAKE_CXX_STANDARD 20`, extensions OFF, and correct system framework paths (CoreFoundation, IOKit, etc.)
- [x] **AC-2:** `MuMain/CMakePresets.json` includes `macos-arm64` configure preset and associated build presets (`macos-arm64-debug`, `macos-arm64-release`)
- [x] **AC-3:** `cmake --preset macos-arm64` succeeds on macOS arm64 (configure step completes — full compile not expected until SDL3 migration removes Win32 API dependencies)
- [x] **AC-4:** Existing Windows MSVC presets (`windows-x64`, `windows-x64-mueditor`, `windows-x86`, `windows-x86-mueditor`) are unchanged and all their build presets still function on Windows

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code follows project-context.md standards — CMake files use consistent style, `#pragma once` in any new C++ headers, no new Win32 API calls
- [x] **AC-STD-2:** No Catch2 tests required — this is a build system story with no testable logic
- [x] **AC-STD-3:** No banned Win32 APIs introduced in any files touched
- [x] **AC-STD-11:** Flow Code traceability — commit message includes `VS0-PLAT-CMAKE-MACOS` reference
- [x] **AC-STD-13:** Quality gate passes — `make -C MuMain format-check && make -C MuMain lint` (mirrors CI quality job)
- [x] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [x] **AC-STD-20:** Contract Reachability — story produces no API/event/flow catalog entries (build system only)

### NFR Acceptance Criteria

- [x] **AC-STD-4:** CI (MinGW cross-compile) quality gate remains green — the macOS presets must not break or conflict with the existing MinGW CI workflow
- [x] **AC-STD-5:** Conventional commit: `build(platform): add macOS CMake toolchain and presets`

---

## Validation Artifacts

- [x] **AC-VAL-1:** macOS configure log showing successful `cmake --preset macos-arm64` run (paste terminal output as comment or attach as artifact)
- [x] **AC-VAL-2:** Windows build confirmed not regressed — existing presets still valid JSON and unchanged

---

## Tasks / Subtasks

- [x] **Task 1: Create macOS arm64 toolchain file** (AC: AC-1)
  - [x] 1.1 Create `MuMain/cmake/toolchains/macos-arm64.cmake`
  - [x] 1.2 Set `CMAKE_SYSTEM_NAME Darwin`, `CMAKE_SYSTEM_PROCESSOR arm64`
  - [x] 1.3 Configure Clang as C and C++ compiler (`clang` / `clang++`)
  - [x] 1.4 Set `CMAKE_CXX_STANDARD 20`, `CMAKE_CXX_EXTENSIONS OFF`
  - [x] 1.5 Add macOS system framework paths (SDK path via `xcrun --show-sdk-path`)
  - [x] 1.6 Set deployment target: `CMAKE_OSX_DEPLOYMENT_TARGET "12.0"` (or whichever minimum is appropriate — see Dev Notes)
  - [x] 1.7 Add `-arch arm64` to `CMAKE_OSX_ARCHITECTURES`

- [x] **Task 2: Update CMakePresets.json with macOS presets** (AC: AC-2)
  - [x] 2.1 Add `macos-base` hidden configure preset (mirrors `windows-base` pattern)
  - [x] 2.2 Add `macos-arm64` configure preset inheriting `macos-base`, using `cmake/toolchains/macos-arm64.cmake`
  - [x] 2.3 Set `CMAKE_EXPORT_COMPILE_COMMANDS ON` in macOS presets (needed for clang-tidy/clangd)
  - [x] 2.4 Add `macos-arm64-debug` and `macos-arm64-release` build presets
  - [x] 2.5 Ensure the new presets do NOT add a `"condition"` that breaks validation on other host OSes (use `hostSystemName` filter if needed to avoid confusion, but verify CI behavior)

- [x] **Task 3: Validate configure step on macOS** (AC: AC-3)
  - [x] 3.1 Run `cmake --preset macos-arm64` on macOS arm64 hardware
  - [x] 3.2 Confirm CMake configure completes (no fatal errors)
  - [x] 3.3 Note any warnings — they are acceptable at this stage (Win32 headers not yet replaced)
  - [x] 3.4 Paste or attach the configure output as part of this story's completion record

- [x] **Task 4: Regression check — Windows presets** (AC: AC-4)
  - [x] 4.1 On Windows (or verify in CI): `cmake --preset windows-x64` still configures successfully
  - [x] 4.2 `cmake --build --preset windows-x64-debug` still builds successfully
  - [x] 4.3 Confirm MinGW CI workflow in `MuMain/.github/workflows/ci.yml` still passes (no changes to CI file needed)

- [x] **Task 5: Quality gate** (AC: AC-STD-13)
  - [x] 5.1 Run `make -C MuMain format-check` — confirm no format violations in changed files
  - [x] 5.2 Run `make -C MuMain lint` (cppcheck) — confirm no new warnings

---

## Error Codes Introduced

_None — this is a build system story. No error codes are introduced._

---

## Contract Catalog Entries

### API Contracts

_None — build system story. No API endpoints introduced._

### Event Contracts

_None — build system story. No events introduced._

### Navigation Entries

_Not applicable — infrastructure story (not frontend)._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Build validation (manual) | CMake | N/A | `cmake --preset macos-arm64` configure succeeds |
| Regression (manual/CI) | CMake + MinGW CI | N/A | Windows presets and MinGW cross-compile unchanged |

_No Catch2 unit tests are required for this story. The acceptance criteria are validated by observing build system behavior._

---

## Dev Notes

### Overview

This story adds macOS arm64 CMake support as a pure build-system change. The game client **cannot** compile to a runnable binary on macOS yet (it depends on Win32 APIs, DirectX, `windows.h`) — but CMake configure must succeed so that IDE tooling (Xcode, CLion, VS Code with clangd) can index the project and quality gates can run on macOS.

### Pattern: Mirror the Existing MinGW Toolchain

The existing toolchain to study is at `MuMain/cmake/toolchains/mingw-w64-i686.cmake`. The macOS toolchain follows the same structural pattern but for native Clang:

```cmake
# MuMain/cmake/toolchains/macos-arm64.cmake
# Toolchain for native macOS arm64 builds (Apple Silicon)

set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_PROCESSOR arm64)

# Clang ships with Xcode Command Line Tools on macOS
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_EXTENSIONS OFF)

# Target Apple Silicon minimum macOS 12 (Monterey)
set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0")
set(CMAKE_OSX_ARCHITECTURES "arm64")

# Let CMake auto-detect the SDK via xcrun
execute_process(
    COMMAND xcrun --show-sdk-path
    OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
```

**Important:** Do NOT set `CMAKE_FIND_ROOT_PATH_MODE_*` the way MinGW does — that is for cross-compilation. On macOS, CMake finds system headers natively via the SDK sysroot.

### Pattern: CMakePresets.json Structure

Study the existing `CMakePresets.json` (lines 1–130) for the Windows preset structure. The macOS presets follow the same pattern:

```json
{
  "name": "macos-base",
  "hidden": true,
  "generator": "Ninja",
  "binaryDir": "${sourceDir}/out/build/${presetName}",
  "cacheVariables": {
    "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
  },
  "condition": {
    "type": "equals",
    "lhs": "${hostSystemName}",
    "rhs": "Darwin"
  }
},
{
  "name": "macos-arm64",
  "displayName": "macOS arm64 (Apple Silicon)",
  "description": "Native macOS arm64 build — configure only until SDL3 migration",
  "inherits": "macos-base",
  "toolchainFile": "${sourceDir}/cmake/toolchains/macos-arm64.cmake",
  "cacheVariables": {
    "ENABLE_EDITOR": "OFF"
  }
}
```

**Note on Ninja vs Ninja Multi-Config:** Windows presets use `"Ninja Multi-Config"` (which supports multiple build configs in one cmake invocation). macOS can use plain `"Ninja"` for simplicity at this stage, or `"Ninja Multi-Config"` for consistency — choose Ninja Multi-Config to match Windows for forward compatibility.

**Note on `condition`:** The `"condition"` block restricting to `"Darwin"` is recommended to avoid CMake preset selection confusion when developers switch machines, but it is **not** required for CI. The MinGW toolchain does not use a condition. Use your judgment — if in doubt, add the condition.

### Critical: Do Not Break the MinGW CI

The CI workflow at `MuMain/.github/workflows/ci.yml` uses the MinGW toolchain directly via cmake command-line flags (not via presets). Adding macOS presets to `CMakePresets.json` does not affect this workflow at all. However, verify that the JSON remains valid after your edits (use `python3 -m json.tool CMakePresets.json` to validate).

### macOS arm64 Framework Paths

When CMake configure runs, it will attempt to find system frameworks. These are in the Xcode SDK which `xcrun --show-sdk-path` resolves automatically. The `CMAKE_OSX_SYSROOT` approach in the toolchain file handles this. You do NOT need to manually set `CMAKE_FRAMEWORK_PATH`.

### Current Win32 Dependencies (Expected Configure Warnings)

The game client source has extensive Win32 dependencies. At configure time, CMake does not compile sources — so configure should succeed even though compiling the full binary would fail on macOS. The purpose of AC-3 is to confirm the **configure** step works, which enables IDE tooling support.

Known Win32 headers the compiler would encounter if a full build were attempted:
- `windows.h` — ~2,089 occurrences of `wchar_t`, DirectX headers, WinAPI
- `d3d9.h` / `OpenGL/gl.h` — rendering
- `mmsystem.h` / `dsound.h` — audio

These are acceptable at this story stage. They will be addressed in EPIC-2, EPIC-4, EPIC-5.

### Risk Item R2 (from Sprint Status)

The sprint status notes: _"macOS arm64 toolchain may need special handling for framework paths."_ The `xcrun --show-sdk-path` approach resolves this. If `xcrun` is unavailable (CI context), fall back to:

```cmake
# Fallback if xcrun unavailable:
# set(CMAKE_OSX_SYSROOT "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk")
```

Add a comment explaining the fallback so the next developer knows.

### PCC Project Constraints

**Tech Stack:** C++20 game client — CMake 3.25+, Ninja generator, Clang on macOS, MinGW CI

**Required Patterns (from project-context.md):**
- `CMAKE_CXX_STANDARD 20`, `CMAKE_CXX_EXTENSIONS OFF` — mandatory in toolchain
- `cmake --preset` workflow — must work with new presets
- `Ninja` or `Ninja Multi-Config` generator — consistent with existing presets

**Prohibited Patterns (from project-context.md):**
- No `#ifdef _WIN32` in game logic (not applicable here — CMake file only)
- No new Win32 API calls (not applicable here — CMake file only)
- No raw `new`/`delete` in C++ (not applicable here — CMake file only)
- Do NOT modify generated files in `src/source/Dotnet/`

**Quality Gate Command:** `make -C MuMain format-check && make -C MuMain lint`

**Commit Format:** `build(platform): add macOS CMake toolchain and presets`

### References

- [Source: MuMain/cmake/toolchains/mingw-w64-i686.cmake] — existing toolchain to mirror
- [Source: MuMain/CMakePresets.json] — existing presets to extend
- [Source: docs/development-standards.md §7 Build System] — build conventions
- [Source: _bmad-output/project-context.md §Technology Stack] — CMake 3.25+ requirement
- [Source: _bmad-output/planning-artifacts/epics.md §Story 1.1.1] — original acceptance criteria
- [Source: _bmad-output/implementation-artifacts/sprint-status.yaml §risk_items R2] — macOS framework path risk

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
- Story type: infrastructure (build system only — no Catch2 tests required)
- Schema alignment: N/A (no API schemas affected)
- Previous story: None (this is the first story in Epic 1, Feature 1)
- Git context: Main branch, last 5 commits are docs-only (planning artifacts, epic breakdown, sprint status, PRD/architecture/runbook, test design)

### File List

_Files to be created/modified by the dev agent implementing this story:_

- [CREATE] `MuMain/cmake/toolchains/macos-arm64.cmake`
- [MODIFY] `MuMain/CMakePresets.json` — add `macos-base`, `macos-arm64` configure presets and `macos-arm64-debug`, `macos-arm64-release` build presets
