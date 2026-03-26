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
