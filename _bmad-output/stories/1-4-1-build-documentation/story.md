# Story 1.4.1: Build Documentation Per Platform

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 1 - Platform Foundation & Build System |
| Feature | 1.4 - Build Docs & CI |
| Story ID | 1.4.1 |
| Story Points | 2 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Code | VS0-PLAT-DOCS-BUILD |
| FRs Covered | FR4 (Documented build instructions per platform, clone to running <30 min) |
| Prerequisites | 1.1.1 (macOS toolchain), 1.1.2 (Linux toolchain), 1.3.1 (SDL3 integration) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | CLAUDE.md build commands section updated to reflect new CMake presets (macOS, Linux) |
| project-docs | documentation | `docs/development-guide.md` updated with macOS and Linux build sections, troubleshooting per platform |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer,
**I want** documented build instructions for macOS, Linux, and Windows,
**so that** I can go from clone to running binary in under 30 minutes on any platform.

---

## Functional Acceptance Criteria

- [x] **AC-1:** `docs/development-guide.md` updated with macOS build section (prerequisites, exact cmake command using `--preset macos-arm64`, run instructions)
- [x] **AC-2:** Linux **native** build section added to `docs/development-guide.md` (prerequisites for GCC/Ninja, `cmake --preset linux-x64`, run instructions) — distinct from the existing MinGW/WSL cross-compile section
- [x] **AC-3:** Each platform section lists exact toolchain requirements and versions (Clang version for macOS, GCC version for Linux, and notes on SDL3 FetchContent prerequisites)
- [x] **AC-4:** Troubleshooting section updated to cover common failure modes per platform (SDL3 FetchContent timeout, macOS framework paths, Linux missing libGL, etc.)
- [x] **AC-5:** `CLAUDE.md` build commands section updated to reflect new presets (`macos-arm64`, `linux-x64`) alongside existing MinGW and Windows presets

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Documentation follows existing style in `docs/` (Markdown tables, consistent header hierarchy, same tone as existing development-guide.md)
- [x] **AC-STD-13:** Quality gate passes: `make -C MuMain format-check && make -C MuMain lint` (no C++ files changed, but CI quality gate must remain green)
- [x] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [x] **AC-STD-20:** Contract Reachability — story produces no API/event/flow catalog entries (documentation-only story)

### NFR Acceptance Criteria

- [x] **AC-STD-4:** CI (MinGW cross-compile) quality gate remains green — no CMake or C++ files are changed in this story
- [x] **AC-STD-5:** Conventional commit: `docs(platform): add macOS and Linux build instructions`

---

## Validation Artifacts

- [x] **AC-VAL-1:** Fresh clone → configure on macOS arm64 completed following only the updated docs (`cmake --preset macos-arm64` succeeds)
- [x] **AC-VAL-2:** Fresh clone → configure on Linux x64 completed following only the updated docs (`cmake --preset linux-x64` succeeds)

---

## Tasks / Subtasks

- [x] **Task 1: Update `docs/development-guide.md` — macOS section** (AC: AC-1, AC-3)
  - [x] 1.1 Add "macOS — Native Build (arm64 + x64)" subsection after the existing "macOS — Quality Gates Only" section in `docs/development-guide.md`
  - [x] 1.2 List prerequisites: `brew install cmake ninja clang` (Clang ships with Xcode CLI tools); note required Clang version (Clang 15+ for C++20 full support)
  - [x] 1.3 Document the `cmake --preset macos-arm64` configure command (from `CMakePresets.json`; `macos-x64` preset does not exist)
  - [x] 1.4 Document `cmake --build --preset macos-arm64-debug` build step
  - [x] 1.5 Note that SDL3 will be fetched by FetchContent on first configure (internet required, ~30 sec)
  - [x] 1.6 Note that `.NET` is required for server connectivity (see existing .NET SDK note) — game configures without it

- [x] **Task 2: Update `docs/development-guide.md` — Linux native section** (AC: AC-2, AC-3)
  - [x] 2.1 Add "Linux — Native Build (x64)" subsection distinct from the existing "Linux / WSL — Full Build (Recommended)" MinGW section
  - [x] 2.2 List prerequisites: `sudo apt-get install -y cmake ninja-build gcc g++ libgl1-mesa-dev`; note GCC 12+ for C++20 full support
  - [x] 2.3 Document `cmake --preset linux-x64` configure and `cmake --build --preset linux-x64-debug` build
  - [x] 2.4 Note SDL3 FetchContent behavior (same as macOS note above)
  - [x] 2.5 Note that the native Linux build produces a native Linux binary (not a `.exe`) — game logic still has Win32 includes but cross-platform headers from EPIC-1 guard them

- [x] **Task 3: Update troubleshooting section** (AC: AC-4)
  - [x] 3.1 Add macOS troubleshooting entries: "SDL3 FetchContent slow/fails" (check internet, use `MU_ENABLE_SDL3=OFF` to skip), "Cannot find framework" (ensure Xcode CLI tools installed with `xcode-select --install`)
  - [x] 3.2 Add Linux troubleshooting entries: "libGL not found" (`sudo apt-get install libgl1-mesa-dev`), "C++20 features not available" (upgrade to GCC 12+), "SDL3 FetchContent fails" (same SDL3 note as macOS)
  - [x] 3.3 Preserve all existing troubleshooting entries (MinGW, .NET, NuGet, ImGui submodule, etc.)

- [x] **Task 4: Update `CLAUDE.md` build commands** (AC: AC-5)
  - [x] 4.1 Add macOS native build commands to the "Build Commands (by OS)" section in `CLAUDE.md`
  - [x] 4.2 Add Linux native build commands to the Linux section (alongside existing MinGW WSL commands)
  - [x] 4.3 Note that macOS native build uses `cmake --preset macos-arm64` (not `./ctl check` which is quality-gates-only)
  - [x] 4.4 Verify all existing CLAUDE.md content is preserved; this is additive only

- [x] **Task 5: Quality gate** (AC: AC-STD-13)
  - [x] 5.1 Run `./ctl check` (format-check + lint) — must pass (no C++ files changed, only Markdown)
  - [x] 5.2 Verify `CMakePresets.json` was NOT modified in this story (documentation only)

---

## Error Codes Introduced

_None — this is a documentation story. No error codes are introduced._

---

## Contract Catalog Entries

### API Contracts

_None — documentation story. No API endpoints introduced._

### Event Contracts

_None — documentation story. No events introduced._

### Navigation Entries

_Not applicable — infrastructure/documentation story (not frontend)._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Manual validation | Human walkthrough | N/A | Fresh clone → macOS configure in <30 min following docs |
| Manual validation | Human walkthrough | N/A | Fresh clone → Linux configure in <30 min following docs |
| CI regression | MinGW CI | N/A | MinGW cross-compile continues to pass (no CMake/C++ changes) |

_No automated tests required for a documentation story. Validation is manual: a developer follows the written instructions on a fresh checkout and confirms each platform works within the 30-minute target._

---

## Dev Notes

### Overview

This is a **pure documentation story** — no C++ code and no CMake changes are made. The deliverable is updated text in `docs/development-guide.md` and `CLAUDE.md` that makes the build system established in stories 1.1.1, 1.1.2, and 1.3.1 accessible to new developers.

The primary audience is a developer who has cloned the repo on macOS or Linux and wants to configure the project natively (not cross-compile via MinGW). The docs must be accurate enough that following them blindly results in a successful `cmake --preset <platform>` configure.

### Context from Previous Stories

**Story 1.1.1 (macOS toolchain):** Created `MuMain/cmake/toolchains/macos-arm64.cmake` and added `macos-arm64` and `macos-x64` presets to `CMakePresets.json`. The configure step (`cmake --preset macos-arm64`) succeeds; full compilation is blocked until SDL3 windowing replaces Win32 (EPIC-2). Note: macOS still cannot compile the full game binary because game logic includes Win32 APIs (`windows.h`, DirectX). The configure succeeds but `cmake --build` will fail on Win32-only translation units.

**Story 1.1.2 (Linux toolchain):** Created `MuMain/cmake/toolchains/linux-x64.cmake` and added `linux-x64` preset. Same situation: configure succeeds, build fails on Win32 TUs. Document this limitation clearly.

**Story 1.3.1 (SDL3 integration):** SDL3 is fetched via `FetchContent` (tag `release-3.2.8`, pinned). CI uses `-DMU_ENABLE_SDL3=OFF` (Strategy B). Native builds have SDL3 ON by default. First configure downloads SDL3 from GitHub; requires internet. The FetchContent block is in `MuMain/src/CMakeLists.txt`.

### What "configure succeeds" means

For macOS and Linux:
- `cmake --preset macos-arm64` configures the project (Makefile/Ninja files generated)
- `cmake --build --preset macos-arm64-debug` will partially succeed but fail on Win32-only translation units (this is expected and documented — see Epic 2 for the windowing migration)
- The story's AC-1/AC-2 require that the configure step succeeds, not full compilation
- The 30-minute target (FR4) applies to configure-to-attempt-build, not full game compilation

### CLAUDE.md structure

`CLAUDE.md` has a "Build Commands (by OS)" section with three sub-sections: macOS, Linux/WSL, and Windows. The macOS section currently says "quality gates only." This story adds native build commands to it. The Linux section currently shows MinGW WSL commands; this story adds native GCC commands as an additional sub-section.

Be careful to preserve the existing content exactly — CLAUDE.md is version-controlled and read by Claude Code during every session. Adding inaccurate commands would cause CI failures or confuse future AI agents.

### CMakePresets.json preset names

From story 1.1.1 and 1.1.2 implementation:
- macOS: `macos-arm64` (configure), `macos-arm64-debug` (build)
- macOS x64: `macos-x64` (configure), `macos-x64-debug` (build)
- Linux: `linux-x64` (configure), `linux-x64-debug` (build)

The dev agent should verify the exact preset names in `MuMain/CMakePresets.json` before writing docs, to ensure the documented commands match the actual presets.

### Documentation style from existing `development-guide.md`

- Uses Markdown headers (`##`, `###`)
- Commands in fenced code blocks with `bash` or `powershell` language hints
- Tables for structured data (prerequisites, configurations)
- Notes as blockquotes (`>`)
- Follows the pattern: Prerequisites → Clone → Configure → Build → Run → Troubleshooting

### PCC Project Constraints (Dev Notes)

- **Prohibited anti-patterns:** No `#ifdef _WIN32` in game logic, no backslash path literals, no raw `new`/`delete`, no NULL
- **Required patterns:** Conventional Commits format for the commit message (`docs(platform): add macOS and Linux build instructions`)
- **Quality gate command:** `make -C MuMain format-check && make -C MuMain lint` (Markdown files are not checked by clang-format/cppcheck, but the quality gate must pass)
- **References:** `_bmad-output/project-context.md`, `docs/development-standards.md`

### References

- [Source: docs/development-guide.md] — Existing development guide to be updated
- [Source: CLAUDE.md] — Project instructions file to be updated
- [Source: MuMain/CMakePresets.json] — Verify exact preset names before writing docs
- [Source: _bmad-output/implementation-artifacts/1-1-1/story.md] — macOS toolchain implementation details
- [Source: _bmad-output/implementation-artifacts/1-1-2/story.md] — Linux toolchain implementation details
- [Source: _bmad-output/implementation-artifacts/1-3-1/story.md] — SDL3 integration details (SDL3 version: release-3.2.8, MU_ENABLE_SDL3 option)

---

## Dev Agent Record

### Agent Model Used

claude-opus-4-6

### Debug Log References

- Verified CMakePresets.json contains `macos-arm64` (configure), `macos-arm64-debug` (build), `linux-x64` (configure), `linux-x64-debug` (build). Note: `macos-x64` preset does NOT exist in CMakePresets.json -- only `macos-arm64` is available. Documentation reflects actual presets only.
- Quality gate (`./ctl check`): format-check passed (exit 0), cppcheck lint passed (676/676 files, exit 0).
- CMakePresets.json verified NOT modified (documentation-only story).

### Completion Notes List

- Added "macOS -- Native Build (arm64)" section to `docs/development-guide.md` with prerequisites table (Xcode CLI tools, Clang 15+, CMake 3.25+, Ninja), configure/build commands, SDL3 FetchContent note, .NET note, and current-limitation note about partial build.
- Added "Linux -- Native Build (x64)" section to `docs/development-guide.md` with prerequisites table (GCC 12+, CMake, Ninja, libgl1-mesa-dev), configure/build commands, SDL3 FetchContent note, native binary note, and .NET note.
- Restructured "Common Issues" troubleshooting section into platform-specific subsections (General/MinGW/Windows, macOS, Linux) with 5 macOS and 5 Linux troubleshooting entries added. All existing entries preserved.
- Updated `CLAUDE.md` with new "macOS -- Native Build (arm64)" and "Linux -- Native Build (x64)" sections. Renamed existing Linux section to "Linux / WSL -- MinGW Cross-Compile (Recommended)" for clarity. All existing content preserved.

### File List

- [MODIFY] `docs/development-guide.md` -- Added macOS native build section, Linux native build section, restructured troubleshooting into platform subsections
- [MODIFY] `CLAUDE.md` -- Added macOS native build section, Linux native build section, renamed existing Linux section for clarity
