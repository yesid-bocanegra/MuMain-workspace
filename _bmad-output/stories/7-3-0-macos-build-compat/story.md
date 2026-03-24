# Story 7.3.0: macOS Native Build Compatibility Fixes

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.3 - Stability Sessions |
| Story ID | 7.3.0 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Code | VS0-QUAL-BUILDCOMPAT-MACOS |
| FRs Covered | FR1 (Build MuMain from source on macOS using CMake), FR37 (60+ minute session on macOS without crashes — requires build to succeed first) |
| Prerequisites | EPIC-2–6 done (SDL3 migration code correct; only build wiring missing) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | CMakeLists.txt: propagate MU_ENABLE_SDL3 to all targets; PlatformTypes.h: add CONST/CP_UTF8; PlatformCompat.h: add 5 Win32 compat stubs; GlobalBitmap.cpp: fix deprecated wstring_convert + GL constants; LoadData.cpp: remove shlwapi.h; GameConfig.cpp: guard DPAPI with #ifdef _WIN32 |
| project-docs | documentation | Story file, sprint status update |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer,
**I want** `cmake --build --preset macos-arm64-debug` to complete without errors,
**so that** the macOS stability session (7-3-1) can proceed and EPIC-7 can close.

---

## Discovery Context

This story was created from a scope discovery artifact.

**Source artifact:** `_bmad-output/stories/7-3-1-macos-stability-session/build-rca.md`
**Discovered during:** 7-3-1-macos-stability-session (first actual macOS arm64 build attempt)
**Discovery type:** compat-gap
**Root causes:** 5 root causes — see source artifact for detail

See `_bmad-output/stories/7-3-1-macos-stability-session/build-rca.md` for the complete RCA and implementation plan.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `cmake --build --preset macos-arm64-debug` exits 0 with 0 compilation errors — verified on macOS arm64
- [ ] **AC-2:** `add_compile_definitions(MU_ENABLE_SDL3)` is emitted at project scope in `MuMain/src/CMakeLists.txt` — all targets (MUCore, MUData, MURenderFX, MUGame, MUProtocol, MUAudio) receive the flag
- [ ] **AC-3:** `PlatformTypes.h` defines `CONST` and `CP_UTF8` in the non-Win32 `#else` block — `KeyGenerater.h` and all encoding files compile without "undeclared identifier" errors
- [ ] **AC-4:** `PlatformCompat.h` provides `_wcsicmp`/`wcsicmp`, `_TRUNCATE`, and no-op `OutputDebugString` stubs in the non-Win32 path — `GlobalBitmap.cpp` and `GameConfig.cpp` compile without missing identifier errors
- [ ] **AC-5:** `GlobalBitmap.cpp`'s `NarrowPath()` uses `mu_wchar_to_utf8()` on non-Windows (no `std::wstring_convert` / `std::codecvt_utf8_utf16` deprecation warning or error)
- [ ] **AC-6:** `GlobalBitmap.cpp` lines 651–652 use `0x812Fu` / `0x2901u` literals instead of `GL_CLAMP_TO_EDGE` / `GL_REPEAT` — compiles without OpenGL headers on macOS SDL3 path
- [ ] **AC-7:** `LoadData.cpp` has no `#include <shlwapi.h>` — Windows-only path manipulation header removed
- [ ] **AC-8:** `GameConfig.cpp` `DATA_BLOB`, `CryptProtectData`, `CryptUnprotectData` are guarded by `#ifdef _WIN32`; non-Windows stubs return input unchanged (no credential encryption on macOS — acceptable for dev build)
- [ ] **AC-9:** Windows MinGW CI build remains green — no regression on existing Windows/MinGW compilation path

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards — no new `#ifdef _WIN32` in game logic (only in Platform headers), `nullptr`, `std::filesystem::path` for any new path code
- [ ] **AC-STD-2:** No new tests required — this is a build-system wiring fix; existing Catch2 suite must continue to pass
- [ ] **AC-STD-11:** Flow Code traceability — commit message references `VS0-QUAL-BUILDCOMPAT-MACOS`
- [ ] **AC-STD-13:** Quality gate passes — `./ctl check` exits 0 (clang-format clean + 0 cppcheck errors)
- [ ] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [ ] **AC-STD-20:** Contract Reachability — story produces no API/event/flow catalog entries (infrastructure only)

---

## Tasks / Subtasks

- [ ] **Task 1 — CMakeLists.txt** (AC: 2)
  - [ ] Add `add_compile_definitions(MU_ENABLE_SDL3)` inside the `if(MU_ENABLE_SDL3)` block in `MuMain/src/CMakeLists.txt`
  - [ ] Verify this is placed BEFORE `target_compile_definitions(MUPlatform PRIVATE MU_ENABLE_SDL3)` (can coexist)
- [ ] **Task 2 — PlatformTypes.h** (AC: 3)
  - [ ] Add `#define CONST const` to the non-Win32 `#else` section
  - [ ] Add `#define CP_UTF8 65001` to the non-Win32 `#else` section
- [ ] **Task 3 — PlatformCompat.h** (AC: 4)
  - [ ] Add `#define _wcsicmp wcscasecmp` and `#define wcsicmp wcscasecmp` to the non-Win32 section
  - [ ] Add `#define _TRUNCATE ((size_t)-1)` to the non-Win32 section
  - [ ] Add `inline void OutputDebugString(const wchar_t* /*msg*/) {}` to the non-Win32 section
  - [ ] Add portable `MultiByteToWideChar` and `WideCharToMultiByte` stubs using `mu_utf8_to_wchar` / `mu_wchar_to_utf8`
- [ ] **Task 4 — GlobalBitmap.cpp** (AC: 5, 6)
  - [ ] Replace `NarrowPath()` body: use `mu_wchar_to_utf8()` on `#ifndef _WIN32`, `WideCharToMultiByte` on Windows
  - [ ] Replace `GL_CLAMP_TO_EDGE` with `0x812Fu` at line ~651
  - [ ] Replace `GL_REPEAT` with `0x2901u` at line ~652
- [ ] **Task 5 — LoadData.cpp** (AC: 7)
  - [ ] Remove `#include <shlwapi.h>` (unused Windows-only header)
- [ ] **Task 6 — GameConfig.cpp** (AC: 8)
  - [ ] Wrap `DATA_BLOB`, `CryptProtectData`, `CryptUnprotectData` usage in `#ifdef _WIN32`
  - [ ] Add `#else` stub: `DecryptSetting` and `EncryptSetting` return input as-is on non-Windows
- [ ] **Task 7 — Verify** (AC: 1, 9)
  - [ ] Run `cmake --build --preset macos-arm64-debug` — confirm exits 0
  - [ ] Run `./ctl check` — confirm exits 0

---

## Dev Notes

### Implementation Plan

Derived directly from `_bmad-output/stories/7-3-1-macos-stability-session/build-rca.md`. Execute Tasks 1–6 in order — each reduces the failing translation unit count before the next. Task 1 alone (CMake flag propagation) will unblock the majority of failures.

### Key Constraints

- **Do NOT** put `#ifdef _WIN32` in game logic files. All Win32 stubs belong in `PlatformCompat.h` or `PlatformTypes.h` only.
- **Do NOT** add OpenGL headers to the SDL3 build path — use numeric literals for GL constants.
- **MultiByteToWideChar / WideCharToMultiByte stubs:** These are called throughout `Data/` and `Core/`. Use the existing `mu_utf8_to_wchar()` and `mu_wchar_to_utf8()` functions from `PlatformCompat.h` as the underlying implementation. The stub signatures must match the Win32 API exactly (same parameters, same return type `int`).
- **GameConfig.cpp DPAPI:** On non-Windows, credentials are stored unencrypted. This is acceptable for developer builds — not a security issue for local dev sessions.

### Files to Touch (6 total, ~60 lines)

| File | Change |
|------|--------|
| `MuMain/src/CMakeLists.txt` | Add `add_compile_definitions` |
| `MuMain/src/source/Platform/PlatformTypes.h` | Add CONST, CP_UTF8 |
| `MuMain/src/source/Platform/PlatformCompat.h` | Add 5 stubs |
| `MuMain/src/source/Data/GlobalBitmap.cpp` | NarrowPath + GL literals |
| `MuMain/src/source/Data/LoadData.cpp` | Remove shlwapi.h |
| `MuMain/src/source/Data/GameConfig.cpp` | Guard DPAPI |

### References

- [Source: `_bmad-output/stories/7-3-1-macos-stability-session/build-rca.md`] — Complete RCA with evidence per file
- [Source: `MuMain/src/source/Platform/PlatformCompat.h`] — Existing compat stubs pattern to follow
- [Source: `MuMain/src/source/Platform/PlatformTypes.h`] — Existing type alias pattern to follow
- [Source: `MuMain/src/CMakeLists.txt` line 364] — Current `target_compile_definitions(MUPlatform PRIVATE MU_ENABLE_SDL3)` to augment

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
