# Story 1.1.1: Create macOS CMake Toolchain & Presets

Status: ready-for-dev

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
| FRs Covered | FR1, FR9 (partial) |
| Prerequisites | None — this is an entry-point story |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Add `cmake/toolchains/macos-arm64.cmake`, add macOS presets to `CMakePresets.json` |
| project-docs | documentation | No catalog entries needed (build system only) |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer,
**I want** CMake toolchain files and presets for macOS (arm64 + x64),
**so that** I can build MuMain natively on macOS with a single cmake command.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `MuMain/cmake/toolchains/macos-arm64.cmake` exists with Clang configuration, C++20 standard, and correct system framework paths
- [ ] **AC-2:** `MuMain/CMakePresets.json` includes `macos-arm64` configure and build presets (Debug + Release) with `hostSystemName == "Darwin"` condition
- [ ] **AC-3:** `cmake --preset macos-arm64` succeeds on macOS (configure step only — full compile blocked by Win32/DirectX APIs until SDL3 migration is complete)
- [ ] **AC-4:** Windows MSVC presets (`windows-x86`, `windows-x86-mueditor`, `windows-x64`, `windows-x64-mueditor`) are unchanged and all existing build presets remain valid

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance — CMake files use forward slashes, no hardcoded absolute paths, toolchain file follows conventions established in `mingw-w64-i686.cmake` and `linux-x64.cmake`
- [ ] **AC-STD-2:** No Catch2 tests required — build system only; CI is the validation mechanism
- [ ] **AC-STD-3:** No banned Win32 APIs introduced
- [ ] **AC-STD-4:** CI quality gate passes (`make -C MuMain format-check && make -C MuMain lint`) — build/test skipped on macOS per `.pcc-config.yaml` `skip_checks: [build, test]`
- [ ] **AC-STD-5:** Conventional commit: `build(platform): add macOS CMake toolchain and presets`

### NFR Acceptance Criteria (Infrastructure)

- [ ] **AC-STD-13:** Quality Gate passes: `make -C MuMain format-check && make -C MuMain lint`
- [ ] **AC-STD-15:** Git safety: no incomplete rebase, no force push, no `--no-verify` hooks

---

## Validation Artifacts

- [ ] **AC-VAL-1:** macOS configure log showing successful `cmake --preset macos-arm64` run (exit code 0)
- [ ] **AC-VAL-2:** Windows build confirmed not regressed — existing presets (`windows-x64`, `windows-x64-mueditor`) still valid JSON and unchanged

---

## Tasks / Subtasks

- [ ] Task 1: Create `MuMain/cmake/toolchains/macos-arm64.cmake` toolchain file (AC: 1)
  - [ ] 1.1: Set `CMAKE_SYSTEM_NAME Darwin` and `CMAKE_SYSTEM_PROCESSOR arm64`
  - [ ] 1.2: Set `CMAKE_C_COMPILER clang` and `CMAKE_CXX_COMPILER clang++`
  - [ ] 1.3: Set `CMAKE_CXX_STANDARD 20`, `CMAKE_CXX_STANDARD_REQUIRED ON`, `CMAKE_CXX_EXTENSIONS OFF`
  - [ ] 1.4: Add `-isysroot` with `$(xcrun --sdk macosx --show-sdk-path)` or detect via CMake's `CMAKE_OSX_SYSROOT`
  - [ ] 1.5: Set `CMAKE_OSX_ARCHITECTURES arm64`
  - [ ] 1.6: Add comment block explaining configure-only status (full compile blocked until SDL3 migration)
- [ ] Task 2: Add macOS presets to `MuMain/CMakePresets.json` (AC: 2, 4)
  - [ ] 2.1: Add `macos-base` hidden configure preset with `hostSystemName == "Darwin"` condition, Ninja Multi-Config generator
  - [ ] 2.2: Add `macos-arm64` configure preset inheriting `macos-base`, pointing to `cmake/toolchains/macos-arm64.cmake`
  - [ ] 2.3: Add `macos-arm64-debug` build preset
  - [ ] 2.4: Add `macos-arm64-release` build preset
  - [ ] 2.5: Validate existing Windows presets are structurally unchanged (JSON diff review)
- [ ] Task 3: Validate configure on macOS (AC: 3)
  - [ ] 3.1: Run `cmake --preset macos-arm64` in the `MuMain/` directory
  - [ ] 3.2: Capture configure output as validation artifact (or document expected errors from Win32 headers)
  - [ ] 3.3: Confirm exit code 0 (configure success) or document any expected errors with rationale
- [ ] Task 4: Run quality gate (AC: STD-4)
  - [ ] 4.1: Run `./ctl check` from workspace root
  - [ ] 4.2: Confirm format-check and lint pass (670/670 files pattern from story 1.1.2)

---

## Error Codes Introduced

None — build system story, no runtime error codes.

---

## Contract Catalog Entries

### API Contracts

None — build system story, no API endpoints.

### Event Contracts

None — build system story, no events.

### Navigation Entries

Not applicable — infrastructure story.

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Build Integration | CMake + CI | 100% (configure step) | `cmake --preset macos-arm64` succeeds; Windows presets unaffected |
| Quality Gate | clang-format + cppcheck | 100% (format-check + lint pass) | All C++ source files pass format and lint checks |

No Catch2 tests required for build system story.

---

## Dev Notes

### Project Structure Notes

**Critical paths for this story:**
- Toolchain file: `MuMain/cmake/toolchains/macos-arm64.cmake`
- Presets file: `MuMain/CMakePresets.json`
- Existing toolchain reference: `MuMain/cmake/toolchains/linux-x64.cmake` (pattern to follow)
- Existing toolchain reference: `MuMain/cmake/toolchains/mingw-w64-i686.cmake` (pattern to follow)

**Existing preset structure** (from `CMakePresets.json` as of story creation):
- `windows-base` (hidden, condition: `hostSystemName == "Windows"`)
  - `windows-x86`, `windows-x86-mueditor`, `windows-x64`, `windows-x64-mueditor`
- `linux-base` (hidden, condition: `hostSystemName == "Linux"`)
  - `linux-x64`
- Build presets: `windows-*-debug/release`, `linux-x64-debug/release`

The macOS base preset must follow the same hidden/inherit pattern.

### Technical Implementation

**Toolchain file pattern** (follow `linux-x64.cmake` style):

```cmake
# Toolchain for native macOS arm64 builds
#
# Configure-only until SDL3 migration removes Win32/DirectX API dependencies.
# Full compile will be possible after Phase 1-2 of the cross-platform plan.

set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_PROCESSOR arm64)
set(CMAKE_OSX_ARCHITECTURES arm64)

# Clang is the native macOS compiler
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

# Detect macOS SDK path at configure time
execute_process(
    COMMAND xcrun --sdk macosx --show-sdk-path
    OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
```

**CMakePresets.json addition pattern** (follow `linux-base`/`linux-x64` pattern):

```json
{
  "name": "macos-base",
  "hidden": true,
  "description": "Base configuration for native macOS builds",
  "generator": "Ninja Multi-Config",
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
  "displayName": "macOS arm64",
  "description": "Native macOS Apple Silicon build -- configure only until SDL3 migration removes Win32 API dependencies",
  "inherits": "macos-base",
  "toolchainFile": "${sourceDir}/cmake/toolchains/macos-arm64.cmake",
  "cacheVariables": {
    "ENABLE_EDITOR": "OFF"
  }
}
```

Build presets to add:
```json
{
  "name": "macos-arm64-debug",
  "displayName": "macOS arm64 Debug",
  "configurePreset": "macos-arm64",
  "configuration": "Debug"
},
{
  "name": "macos-arm64-release",
  "displayName": "macOS arm64 Release",
  "configurePreset": "macos-arm64",
  "configuration": "Release"
}
```

**xcrun SDK detection alternative** — if `execute_process` is too early in toolchain evaluation, use CMake's built-in:
```cmake
# Alternative: let CMake find the SDK automatically
# set(CMAKE_OSX_SYSROOT "" CACHE PATH "" FORCE)
# CMake auto-detects on macOS when not set
```

### macOS Build Context

Per `CLAUDE.md` and `project-context.md`:
- macOS **cannot** compile the game client (requires `windows.h`, Win32 APIs, DirectX)
- macOS role: **code quality checks only** (`./ctl check`)
- `./ctl check` runs: `clang-format` format-check + `cppcheck` lint (mirrors CI)
- CI runs the actual MinGW cross-compile build on Linux (Ubuntu)

AC-3 note: "cmake --preset macos-arm64" configure step should succeed even though a full compile will fail. The Ninja generator writes build.ninja, CMake generates build system files, but actual compilation is not performed in AC-3 scope. If configure itself fails due to compiler detection issues, document the error and resolution.

### Sibling Story Context (1.1.2 - Linux CMake Toolchain)

Story 1.1.2 is already **done** (see session-summary.md). Key learnings from that story:
1. Linux toolchain (`linux-x64.cmake`) was created successfully — use it as the primary structural reference
2. Setting `CMAKE_SYSTEM_NAME` causes `CMAKE_CROSSCOMPILING=TRUE` even for native builds — this is acceptable and documented in the toolchain comment
3. The `cmake --preset linux-x64` pattern established the test validation approach for AC-3
4. 670/670 files passed quality gate (format-check + cppcheck) in story 1.1.2 — this story must maintain that

Story 1.1.2 key decisions with applicability:
- **Skip design-screen task** — correctly skipped for infrastructure/build-system stories (no UI, no .pen screen needed)
- **Platform-specific AC deferral** — AC-3 for macOS configure is analogous to Linux configure in 1.1.2; document any platform-specific behavior

### PCC Project Constraints

**Tech Stack (from project-context.md):**
- C++20, CMake 3.25+, Ninja generator
- MinGW-w64 i686 (CI cross-compile), MSVC (Windows), Clang (macOS quality gates)
- macOS: quality gates only — `./ctl check`

**Prohibited Libraries / Anti-Patterns:**
- No Win32 APIs in new code (banned API table in `development-standards.md` §1)
- No `#ifdef _WIN32` in game logic — only in platform abstraction headers
- No backslash path literals — forward slashes only
- No new `SAFE_DELETE`/`SAFE_DELETE_ARRAY` — use smart pointers

**Required Patterns:**
- C++20 standard: `std::filesystem`, `std::chrono`, `[[nodiscard]]`
- `#pragma once` (no `#ifndef` header guards)
- `std::unique_ptr` (no raw `new`/`delete`)
- Conventional commits: `build(platform): add macOS CMake toolchain and presets`

**Quality Gate Command:** `make -C MuMain format-check && make -C MuMain lint`

**References:**
- [Source: _bmad-output/project-context.md]
- [Source: docs/development-standards.md §1 Cross-Platform Readiness]
- [Source: docs/development-standards.md §7 Build System]
- [Source: MuMain/cmake/toolchains/linux-x64.cmake — pattern reference]
- [Source: MuMain/CMakePresets.json — existing preset structure]
- [Source: CLAUDE.md — macOS build commands section]
- [Source: _bmad-output/planning-artifacts/epics.md — Epic 1, Story 1.1.1 spec]

### Risk Register (from sprint-status.yaml)

**R2:** macOS arm64 toolchain may need special handling for framework paths
- **Affected story:** 1-1-1-macos-cmake-toolchain
- **Mitigation:** AC-1 requires correct system framework paths; use `xcrun --sdk macosx --show-sdk-path` to detect at configure time; fallback to CMake auto-detection if xcrun unavailable

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Story created by create-story workflow on 2026-03-04
- PCC guidelines loaded: project-context.md + development-standards.md
- Corpus: specification-index.yaml not found — corpus recommendations skipped
- Sibling story 1.1.2 session summary loaded for intelligence; key patterns applied
- Story type: `infrastructure` (build system only — no frontend design screen needed)
- Schema alignment: N/A for build system story (no API schemas affected)
- Sprint status: story was `ready-for-dev` in sprint-status.yaml at create time (pre-existing state)

### File List

- `MuMain/cmake/toolchains/macos-arm64.cmake` [CREATE]
- `MuMain/CMakePresets.json` [MODIFY] — add macos-base, macos-arm64 configure presets + build presets
