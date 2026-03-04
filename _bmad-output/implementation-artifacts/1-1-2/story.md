# Story 1.1.2: Create Linux CMake Toolchain & Presets

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 1 - Platform Foundation & Build System |
| Feature | 1.1 - CMake Toolchains |
| Story ID | 1.1.2 |
| Story Points | 2 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Code | VS0-PLAT-CMAKE-LINUX |
| FRs Covered | FR2, FR3 (regression guard) |
| Prerequisites | None (can run parallel with 1.1.1) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Add `cmake/toolchains/linux-x64.cmake`, update `CMakePresets.json` with Linux presets |
| project-docs | documentation | Story file, sprint status update |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer,
**I want** CMake toolchain files and presets for Linux (x64),
**so that** I can build MuMain natively on Linux with a single `cmake --preset` command.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `MuMain/cmake/toolchains/linux-x64.cmake` exists with GCC compiler configuration, `CMAKE_CXX_STANDARD 20`, `CMAKE_CXX_EXTENSIONS OFF`
- [ ] **AC-2:** `MuMain/CMakePresets.json` includes `linux-x64` configure preset and associated build presets (`linux-x64-debug`, `linux-x64-release`)
- [ ] **AC-3:** `cmake --preset linux-x64` succeeds on Linux x64 (configure step completes — full compile not expected until Win32 API dependencies are removed in later epics)

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards — CMake files use consistent style, `#pragma once` in any new C++ headers, no new Win32 API calls
- [ ] **AC-STD-2:** No Catch2 tests required — this is a build system story with no testable logic
- [ ] **AC-STD-3:** No banned Win32 APIs introduced in any files touched
- [ ] **AC-STD-11:** Flow Code traceability — commit message includes `VS0-PLAT-CMAKE-LINUX` reference
- [ ] **AC-STD-13:** Quality gate passes — `make -C MuMain format-check && make -C MuMain lint` (mirrors CI quality job)
- [ ] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [ ] **AC-STD-20:** Contract Reachability — story produces no API/event/flow catalog entries (build system only)

### NFR Acceptance Criteria

- [ ] **AC-STD-4:** CI (MinGW cross-compile) quality gate remains green — the Linux presets must not break or conflict with the existing MinGW CI workflow
- [ ] **AC-STD-5:** Conventional commit: `build(platform): add Linux CMake toolchain and presets`

---

## Validation Artifacts

- [ ] **AC-VAL-1:** Linux configure log showing successful `cmake --preset linux-x64` run (paste terminal output as comment or attach as artifact)

---

## Tasks / Subtasks

- [ ] **Task 1: Create Linux x64 toolchain file** (AC: AC-1)
  - [ ] 1.1 Create `MuMain/cmake/toolchains/linux-x64.cmake`
  - [ ] 1.2 Set `CMAKE_SYSTEM_NAME Linux`, `CMAKE_SYSTEM_PROCESSOR x86_64`
  - [ ] 1.3 Configure GCC as C and C++ compiler (`gcc` / `g++`)
  - [ ] 1.4 Set `CMAKE_CXX_STANDARD 20`, `CMAKE_CXX_EXTENSIONS OFF`
  - [ ] 1.5 Do NOT add `CMAKE_FIND_ROOT_PATH_MODE_*` overrides (those are for cross-compilation only; this is a native Linux build)
  - [ ] 1.6 Do NOT add static libgcc/libstdc++ flags (those are MinGW-specific; on Linux, shared runtimes are standard)

- [ ] **Task 2: Update CMakePresets.json with Linux presets** (AC: AC-2)
  - [ ] 2.1 Add `linux-base` hidden configure preset (mirrors `windows-base` pattern)
  - [ ] 2.2 Add `linux-x64` configure preset inheriting `linux-base`, using `cmake/toolchains/linux-x64.cmake`
  - [ ] 2.3 Set generator to `"Ninja Multi-Config"` (consistent with Windows presets)
  - [ ] 2.4 Set `CMAKE_EXPORT_COMPILE_COMMANDS ON` in Linux presets (needed for clang-tidy/clangd on Linux)
  - [ ] 2.5 Add `linux-x64-debug` and `linux-x64-release` build presets
  - [ ] 2.6 Add `"condition"` block with `hostSystemName == "Linux"` to avoid preset selection confusion on other host OSes
  - [ ] 2.7 Validate the updated JSON is well-formed: `python3 -m json.tool MuMain/CMakePresets.json`

- [ ] **Task 3: Validate configure step on Linux** (AC: AC-3)
  - [ ] 3.1 Run `cmake --preset linux-x64` on Linux x64
  - [ ] 3.2 Confirm CMake configure completes (no fatal errors)
  - [ ] 3.3 Note any warnings — they are acceptable at this stage (Win32 headers not yet replaced)
  - [ ] 3.4 Paste or attach the configure output as part of this story's completion record

- [ ] **Task 4: Regression check — existing presets and CI** (AC: AC-STD-4)
  - [ ] 4.1 Confirm MinGW CI workflow in `MuMain/.github/workflows/ci.yml` still passes — CI uses direct CMake flags, not presets, so no changes should be needed
  - [ ] 4.2 Verify JSON syntax is valid after edits (`python3 -m json.tool CMakePresets.json`)
  - [ ] 4.3 On Windows (or verify in CI): `cmake --preset windows-x64` still configures and builds successfully

- [ ] **Task 5: Quality gate** (AC: AC-STD-13)
  - [ ] 5.1 Run `make -C MuMain format-check` — confirm no format violations in changed files
  - [ ] 5.2 Run `make -C MuMain lint` (cppcheck) — confirm no new warnings

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
| Build validation (manual) | CMake | N/A | `cmake --preset linux-x64` configure succeeds |
| Regression (manual/CI) | CMake + MinGW CI | N/A | Windows presets and MinGW cross-compile unchanged |

_No Catch2 unit tests are required for this story. The acceptance criteria are validated by observing build system behavior._

---

## Dev Notes

### Overview

This story adds Linux x64 CMake support as a pure build-system change. It is the counterpart to story 1.1.1 (macOS) and can be implemented in parallel. The game client **cannot** compile to a runnable binary on Linux yet (it depends on Win32 APIs, DirectX, `windows.h`) — but CMake configure must succeed so that IDE tooling (CLion, VS Code with clangd) can index the project and quality gates can run on Linux.

The story is rated 2 points (vs. 3 for macOS) because Linux x64 is a simpler native toolchain — no sysroot manipulation, no framework path detection, and no deployment target concepts.

### Pattern: Mirror the Existing MinGW Toolchain (With Important Differences)

The existing toolchain at `MuMain/cmake/toolchains/mingw-w64-i686.cmake` is a **cross-compilation** toolchain (Linux host → Windows target). The Linux toolchain is a **native** toolchain (Linux host → Linux target). Key differences:

| MinGW cross-compile | Linux native |
|---------------------|-------------|
| `CMAKE_SYSTEM_NAME Windows` | `CMAKE_SYSTEM_NAME Linux` |
| `i686-w64-mingw32-gcc` | `gcc` (system GCC) |
| `CMAKE_FIND_ROOT_PATH` set | Not needed (native paths) |
| `CMAKE_FIND_ROOT_PATH_MODE_*` set to ONLY | Not needed |
| Static libgcc/libstdc++ flags | Not needed |

The Linux toolchain is intentionally simpler:

```cmake
# MuMain/cmake/toolchains/linux-x64.cmake
# Toolchain for native Linux x86_64 builds

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# GCC ships with standard Linux distros
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_EXTENSIONS OFF)
```

**Do NOT** add `CMAKE_FIND_ROOT_PATH_MODE_*` — that is for cross-compilation and would break find_package() on a native Linux build.

**Do NOT** add static libgcc flags — those are MinGW-specific workarounds. On Linux, shared GCC runtimes are standard and always present.

### Pattern: CMakePresets.json Structure

Follow the same pattern as the macOS presets in story 1.1.1. The Linux presets follow the same structure:

```json
{
  "name": "linux-base",
  "hidden": true,
  "generator": "Ninja Multi-Config",
  "binaryDir": "${sourceDir}/out/build/${presetName}",
  "cacheVariables": {
    "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
  },
  "condition": {
    "type": "equals",
    "lhs": "${hostSystemName}",
    "rhs": "Linux"
  }
},
{
  "name": "linux-x64",
  "displayName": "Linux x86_64",
  "description": "Native Linux x64 build — configure only until SDL3 migration removes Win32 API dependencies",
  "inherits": "linux-base",
  "toolchainFile": "${sourceDir}/cmake/toolchains/linux-x64.cmake",
  "cacheVariables": {
    "ENABLE_EDITOR": "OFF"
  }
}
```

Build presets follow the same pattern as Windows:

```json
{
  "name": "linux-x64-debug",
  "displayName": "Linux x64 Debug",
  "configurePreset": "linux-x64",
  "configuration": "Debug"
},
{
  "name": "linux-x64-release",
  "displayName": "Linux x64 Release",
  "configurePreset": "linux-x64",
  "configuration": "Release"
}
```

### Critical: The CI Workflow Is Unaffected

The CI workflow at `MuMain/.github/workflows/ci.yml` uses the MinGW toolchain via direct CMake flags (not via presets). Adding Linux presets to `CMakePresets.json` does not affect the CI workflow at all. However, after editing `CMakePresets.json`, validate JSON syntax:

```bash
python3 -m json.tool MuMain/CMakePresets.json
```

This validates the JSON is well-formed and won't silently break CMake preset parsing.

### GCC Version Requirement

The story requires C++20. Ensure the system GCC is GCC 10+ (released in 2020, ships with Ubuntu 20.04+). On Ubuntu 22.04+ or Fedora 36+, the default GCC supports C++20 fully. If building on an older distro:

```bash
# Ubuntu 20.04 — install GCC 12
sudo apt-get install -y gcc-12 g++-12
```

The toolchain file uses unversioned `gcc`/`g++` to pick up the system default. If a specific version is needed, the developer can override at configure time with `-DCMAKE_C_COMPILER=gcc-12 -DCMAKE_CXX_COMPILER=g++-12`.

### Current Win32 Dependencies (Expected Configure Warnings)

At configure time CMake does not compile sources — configure should succeed even though a full build would fail on Linux (Win32 headers are missing). The purpose of AC-3 is to confirm the **configure** step succeeds, which enables IDE tooling support and verifies the preset infrastructure is correct.

Known Win32 headers the compiler would encounter on a full build attempt:
- `windows.h` — ~2,089 occurrences of `wchar_t`, DirectX headers, WinAPI
- `d3d9.h` / `OpenGL/gl.h` — rendering
- `mmsystem.h` / `dsound.h` — audio

These are acceptable at this story stage. They will be addressed in EPIC-2, EPIC-4, EPIC-5.

### Relationship to Story 1.1.1 (macOS)

Stories 1.1.1 and 1.1.2 are deliberately independent (no dependencies listed in sprint-status.yaml or the epic dependency graph) and can be implemented in parallel. If 1.1.1 was implemented first, `CMakePresets.json` will already have `macos-base` and `macos-arm64` entries. This story adds `linux-base`, `linux-x64`, `linux-x64-debug`, and `linux-x64-release` alongside them.

The story 1.1.1 Dev Notes established the structural pattern for the macOS `condition` block. The Linux story mirrors this exactly but with `"rhs": "Linux"` instead of `"rhs": "Darwin"`.

### Git Context (as of story creation)

Last 5 commits are docs-only (planning artifacts, epic breakdown, sprint status, PRD/architecture/runbook, test design). No toolchain files have been created yet. The first implementation commits will come from stories 1.1.1 and 1.1.2.

### PCC Project Constraints

**Tech Stack:** C++20 game client — CMake 3.25+, Ninja Multi-Config generator, GCC on Linux, MinGW CI

**Required Patterns (from project-context.md):**
- `CMAKE_CXX_STANDARD 20`, `CMAKE_CXX_EXTENSIONS OFF` — mandatory in toolchain
- `cmake --preset` workflow — must work with new presets
- `"Ninja Multi-Config"` generator — consistent with existing Windows presets
- `CMAKE_EXPORT_COMPILE_COMMANDS ON` — required for clang-tidy/clangd tooling

**Prohibited Patterns (from project-context.md):**
- No `#ifdef _WIN32` in game logic (not applicable here — CMake file only)
- No new Win32 API calls (not applicable here — CMake file only)
- No raw `new`/`delete` in C++ (not applicable here — CMake file only)
- Do NOT modify generated files in `src/source/Dotnet/`
- Do NOT add `CMAKE_FIND_ROOT_PATH_MODE_*` — that pattern is for cross-compilation (MinGW), not native Linux

**Quality Gate Command:** `make -C MuMain format-check && make -C MuMain lint`

**Commit Format:** `build(platform): add Linux CMake toolchain and presets`

### Schema Alignment

Not applicable — C++20 game client with no schema validation tooling (noted in sprint-status.yaml).

### References

- [Source: MuMain/cmake/toolchains/mingw-w64-i686.cmake] — existing cross-compile toolchain (note: do NOT replicate its FIND_ROOT_PATH settings for a native build)
- [Source: MuMain/CMakePresets.json] — existing presets to extend
- [Source: docs/development-standards.md §7 Build System] — build conventions
- [Source: _bmad-output/project-context.md §Technology Stack] — CMake 3.25+ requirement
- [Source: _bmad-output/planning-artifacts/epics.md §Story 1.1.2] — original acceptance criteria
- [Source: _bmad-output/implementation-artifacts/1-1-1/story.md §Dev Notes] — macOS toolchain pattern (structural reference)

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
- Schema alignment: N/A (no API schemas affected — C++20 game client)
- Previous story context: Story 1.1.1 (macOS) reviewed — established CMakePresets.json `condition` block pattern and `macos-base` hidden preset convention
- Git context: Main branch, last 5 commits are docs-only (planning artifacts, epic breakdown, sprint status, PRD/architecture/runbook, test design)
- Key difference from 1.1.1: Linux is a native (not cross-compiled) build — no `CMAKE_FIND_ROOT_PATH_MODE_*` settings
- design-screen (2026-03-04): NOT APPLICABLE — story type is `infrastructure` (CMake build system). No Visual Design Specification, no UI components, no frontend. .pen screen creation skipped. design_status = N/A

### File List

_Files to be created/modified by the dev agent implementing this story:_

- [CREATE] `MuMain/cmake/toolchains/linux-x64.cmake`
- [MODIFY] `MuMain/CMakePresets.json` — add `linux-base`, `linux-x64` configure presets and `linux-x64-debug`, `linux-x64-release` build presets
