# Story 7.8.1: Audio Interface Win32 Type Cleanup

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.8 - Remaining Build Blockers |
| Story ID | 7.8.1 |
| Story Points | 5 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-BUILD-AUDIO |
| FRs Covered | Cross-platform parity — audio interface must compile on macOS and Linux without Win32 types |
| Prerequisites | 7-6-1-macos-native-build-compilation (done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Replace Win32 types (`HRESULT`, `BOOL`, `HWND`, `OBJECT*`) in `Audio/DSPlaySound.h`, `Platform/IPlatformAudio.h`, and `Platform/MiniAudio/MiniAudioBackend.h` with portable equivalents |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer building the game client on macOS/Linux,
**I want** the audio interface headers to use only portable C++ types,
**so that** `IPlatformAudio.h`, `MiniAudioBackend.h`, and `DSPlaySound.h` compile on all platforms without Win32 type dependencies.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `Audio/DSPlaySound.h` function declarations that use `HRESULT`, `HWND`, or `OBJECT*` are either wrapped in `#ifdef _WIN32` guards (if DirectSound-only) or removed from the cross-platform header.
- [ ] **AC-2:** `Platform/IPlatformAudio.h` pure virtual interface uses only portable types:
  - `HRESULT` → `bool` (return true on success)
  - `BOOL` → `bool`
  - `OBJECT*` → removed or replaced with a forward-declared portable handle type
- [ ] **AC-3:** `Platform/MiniAudio/MiniAudioBackend.h` override declarations match the updated `IPlatformAudio.h` interface exactly — no Win32 types remain.
- [ ] **AC-4:** All call sites of the changed virtual methods compile with the new signatures — no implicit conversion from `BOOL` to `bool` warnings.
- [ ] **AC-5:** `python3 MuMain/scripts/check-win32-guards.py` exits 0 — no bare Win32 type usage in `Platform/IPlatformAudio.h` or `Platform/MiniAudio/MiniAudioBackend.h`.
- [ ] **AC-6:** `./ctl check` passes — build + tests + format-check + lint all green.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — no `HRESULT`, `BOOL`, or `HWND` in `IPlatformAudio.h` or `MiniAudioBackend.h` outside `#ifdef _WIN32` guards; clang-format clean.
- [ ] **AC-STD-2:** Testing Requirements — All modified audio interface headers are verified to compile across all platforms (macOS arm64, Linux x64, Windows x64); existing audio functional tests continue to pass (if any).
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [ ] **Task 1: Audit Win32 types in audio headers** (AC-1, AC-2, AC-3)
  - [ ] 1.1: Read `Audio/DSPlaySound.h` — identify every declaration using `HRESULT`, `HWND`, `BOOL`, `OBJECT*`
  - [ ] 1.2: Read `Platform/IPlatformAudio.h` — map virtual method signatures to Win32 types
  - [ ] 1.3: Read `Platform/MiniAudio/MiniAudioBackend.h` — confirm override signatures match

- [ ] **Task 2: Fix `Platform/IPlatformAudio.h`** (AC-2)
  - [ ] 2.1: Replace `HRESULT` return types with `bool`
  - [ ] 2.2: Replace `BOOL` parameters with `bool`
  - [ ] 2.3: Replace or remove `OBJECT*` parameters — use `void*` or remove if unused by MiniAudio backend

- [ ] **Task 3: Fix `Platform/MiniAudio/MiniAudioBackend.h`** (AC-3)
  - [ ] 3.1: Update override declarations to match updated interface

- [ ] **Task 4: Fix `Audio/DSPlaySound.h`** (AC-1)
  - [ ] 4.1: Wrap DirectSound-specific declarations in `#ifdef _WIN32` guard
  - [ ] 4.2: Remove or guard any bare `HRESULT`/`HWND` in the header's cross-platform scope

- [ ] **Task 5: Fix all call sites** (AC-4)
  - [ ] 5.1: Grep for callers of changed virtual methods; update argument types as needed
  - [ ] 5.2: Update `MiniAudioBackend.cpp` implementations to match new signatures

- [ ] **Task 6: Verify quality gate** (AC-5, AC-6)
  - [ ] 6.1: Run `python3 MuMain/scripts/check-win32-guards.py`
  - [ ] 6.2: Run `./ctl check`

---

## Dev Notes

### Background

This story addresses one of the core cross-platform compilation blockers identified in the Sprint 7 scope discovery phase. The audio interface headers (`IPlatformAudio.h`, `MiniAudioBackend.h`, `DSPlaySound.h`) contain Win32-specific types (`HRESULT`, `BOOL`, `HWND`, `OBJECT*`) that prevent compilation on macOS and Linux.

### Implementation Approach

**Phase 1: Audit & Analysis (Tasks 1-3)**
- Read existing headers to understand current type usage
- Map each Win32 type to portable equivalents:
  - `HRESULT` (Win32 LONG status codes) → `bool` (simple success/failure)
  - `BOOL` (Win32 typedef'd int) → `bool` (standard C++ boolean)
  - `HWND` (Win32 window handle) → Not used by miniaudio backend; wrap in `#ifdef _WIN32` if kept
  - `OBJECT*` (COM interface) → Remove if unused; use `void*` if necessary for DSPlaySound.h

**Phase 2: Implementation (Tasks 4-5)**
- Focus on interface definitions first (`IPlatformAudio.h` is the contract)
- Update implementations to match (`MiniAudioBackend.h`)
- Guard DirectSound-only declarations in `DSPlaySound.h` with `#ifdef _WIN32`
- Update all call sites via grep to ensure no implicit conversions

**Phase 3: Verification (Task 6)**
- Run `check-win32-guards.py` to detect any remaining bare Win32 types
- Run `./ctl check` to verify format, lint, build, and test pass

### Key Files Affected

1. `MuMain/src/source/Platform/IPlatformAudio.h` — pure virtual interface, macOS/Linux consumers depend on this
2. `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` — miniaudio backend implementation
3. `MuMain/src/source/Audio/DSPlaySound.h` — DirectSound wrapper (Windows-only features)

### Reference Documentation

- **Cross-Platform Standards:** `docs/development-standards.md` §1 (Cross-Platform Readiness)
- **Audio Architecture:** See audio subsystem documentation in `docs/` (if available)
- **Quality Gate Requirements:** `docs/development-standards.md` §7 (Build System)
- **Project Architecture:** Reference `_bmad-output/project-context.md` for platform abstraction rules

### Testing Strategy

- Compilation on all three platforms (Windows MSVC, macOS Clang, Linux GCC)
- No runtime tests needed — this is a compilation/interface fix
- Existing audio tests (if any) must continue to pass
- Verification via `./ctl check` build target

### Common Pitfalls to Avoid

1. **Do NOT** wrap call sites in `#ifdef _WIN32` — fix the type definitions instead
2. **Do NOT** introduce new bare `HRESULT` or `HWND` in cross-platform code — stub them in `PlatformCompat.h` if absolutely necessary
3. **Do NOT** change function semantics when switching return types (e.g., `HRESULT` with FAILED/SUCCEEDED macros → `bool` with simple true/false)
4. **Do NOT** commit without running `./ctl check` — format and lint violations block the quality gate
