# Story 7.9.4: Kill DirectSound — Miniaudio-Only Audio Layer

Status: complete

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.9 - macOS Game Loop & Win32 Render Path Migration |
| Story ID | 7.9.4 |
| Story Points | 8 |
| Priority | P1 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-AUDIO-KILLDSOUND |
| FRs Covered | Zero DirectSound code — all audio through miniaudio via IPlatformAudio, zero `#ifdef _WIN32` in Audio/ |
| Prerequisites | 5-2-1-miniaudio-bgm (done), 5-2-2-miniaudio-sfx (done), 7-9-3-unify-entry-point (done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Delete DirectSound implementations from DSplaysound.cpp/DSwaveIO.cpp/headers; wire all 20 `#ifdef _WIN32` audio call sites through IPlatformAudio/miniaudio; remove DirectSound types |
| project-docs | documentation | Story artifacts, progress tracking |

---

## Background

The audio layer has **20 `#ifdef _WIN32` guards** across 5 files, all protecting DirectSound
code (`IDirectSoundBuffer`, `DSBUFFERDESC`, `waveOutOpen`, `mmioOpen`, etc.). The miniaudio backend
(`MiniAudioBackend` implementing `IPlatformAudio`) already exists and works on all platforms
(stories 5-2-1 and 5-2-2). But the old DirectSound code was left in place behind `#ifdef _WIN32`
instead of being deleted.

| File | Guards | What it protects |
|------|--------|-----------------|
| `Audio/DSplaysound.cpp` | 14 | DirectSound buffer creation, playback, volume, 3D positioning, COM interfaces |
| `Audio/DSwaveIO.cpp` | 2 | WAV file parsing via Win32 `mmioOpen`/`mmioRead` |
| `Audio/DSwaveIO.h` | 2 | `WAVEFORMATEX`, `MMCKINFO` type declarations, include guards |
| `Audio/DSPlaySound.h` | 1 | `IDirectSoundBuffer` type declarations |
| `Audio/DSWavRead.h` | 1 | WAV read type declarations |

The fix: delete every DirectSound code path. All audio goes through `g_platformAudio->PlaySound()`,
`g_platformAudio->PlayMusic()`, etc. On Windows, miniaudio uses WASAPI (not DirectSound) which
is superior anyway.

---

## Story

**[VS-0] [Flow:E]**

**As a** developer maintaining the game client,
**I want** all DirectSound code deleted and all audio routed through miniaudio,
**so that** there are zero `#ifdef _WIN32` in the audio layer and one audio path for all platforms.

---

## Functional Acceptance Criteria

- [x] **AC-1: Delete DirectSound implementations**
  All DirectSound API calls are removed from `DSplaysound.cpp`:
  `DirectSoundCreate`, `CreateSoundBuffer`, `IDirectSoundBuffer::Play/Stop/SetVolume`,
  `IDirectSound3DBuffer`, `IDirectSound3DListener`.
  Each is replaced with the equivalent `IPlatformAudio` / miniaudio call.

- [x] **AC-2: Delete Win32 wave I/O**
  `DSwaveIO.cpp` and `DSwaveIO.h` Win32 implementations (`mmioOpen`, `mmioRead`, `mmioDescend`)
  are deleted. WAV loading goes through miniaudio's built-in decoder (`ma_decoder`).

- [x] **AC-3: Zero `#ifdef _WIN32` in Audio/**
  `grep -rn '#ifdef _WIN32' src/source/Audio/` returns 0.
  No DirectSound types (`IDirectSoundBuffer`, `DSBUFFERDESC`, `WAVEFORMATEX`, `LPDIRECTSOUND`)
  remain in any audio header or source file.

- [x] **AC-4: All audio functions route through IPlatformAudio**
  Every public function in `DSPlaySound.h` that game code calls (PlayBuffer, StopBuffer,
  SetVolume, SetPosition3D, etc.) delegates to `g_platformAudio` methods.
  Game code never touches DirectSound or miniaudio directly.

- [x] **AC-5: Quality gate passes**
  `./ctl check` exits 0. MinGW cross-compile passes. `check-win32-guards.py` exits 0.

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards — clang-format clean; zero `#ifdef _WIN32` in Audio/; PascalCase functions, `m_` prefix members.
- [x] **AC-STD-2:** Testing Requirements — Catch2 test suite passes; no regressions in existing tests.
- [x] **AC-STD-12:** SLI/SLO Targets — Audio playback latency p95 < 50ms (single-threaded miniaudio thread); zero audio dropout under normal load.
- [x] **AC-STD-13:** Quality Gate — `./ctl check` exits 0 (format-check + cppcheck + build).
- [x] **AC-STD-15:** API Contract — IPlatformAudio methods called correctly; all audio paths go through interface; no direct miniaudio calls from game logic.

---

## Validation Artifacts

- [x] **AC-VAL-2:** Verify `grep -rn '#ifdef _WIN32' src/source/Audio/` returns 0
- [x] **AC-VAL-3:** Verify `python3 MuMain/scripts/check-win32-guards.py` exits 0
- [x] **AC-VAL-4:** Verify no DirectSound types remain: `grep -rn 'IDirectSound\|DSBUFFERDESC\|LPDIRECTSOUND\|DirectSoundCreate' src/source/Audio/` returns 0

---

## Tasks / Subtasks

- [x] **Task 1: Audit DirectSound call sites** (AC: 1, 2, 3)
  - [x] 1.1: Map every `#ifdef _WIN32` block in DSplaysound.cpp (14 guards) to its IPlatformAudio equivalent
  - [x] 1.2: Map DSwaveIO.cpp functions (2 guards) to miniaudio decoder equivalents
  - [x] 1.3: Map DSwaveIO.h guards (2 guards) — identify type stubs needed
  - [x] 1.4: Map DSPlaySound.h guard (1) and DSWavRead.h guard (1)
  - [x] 1.5: Identify any DirectSound features NOT yet in IPlatformAudio (3D positioning, etc.)

- [x] **Task 2: Extend IPlatformAudio if needed** (AC: 4)
  - [x] 2.1: Add any missing methods to IPlatformAudio for features used by game code
  - [x] 2.2: Implement in MiniAudioBackend

- [x] **Task 3: Replace DirectSound with IPlatformAudio calls** (AC: 1, 2, 3, 4)
  - [x] 3.1: DSplaysound.cpp — replace all 14 `#ifdef _WIN32` blocks with IPlatformAudio delegates
  - [x] 3.2: DSPlaySound.h — remove DirectSound type declarations and COM interface references
  - [x] 3.3: DSwaveIO.cpp — delete Win32 wave I/O or replace with miniaudio decoder
  - [x] 3.4: DSwaveIO.h — delete DirectSound types (`WAVEFORMATEX`, `MMCKINFO`, etc.)
  - [x] 3.5: DSWavRead.h — remove Win32 guard and DirectSound type dependencies

- [x] **Task 4: Quality gate** (AC: 5)
  - [x] 4.1: `./ctl check` passes (format + lint + build)
  - [x] 4.2: MinGW cross-compile passes
  - [x] 4.3: `grep -rn '#ifdef _WIN32' src/source/Audio/` returns 0
  - [x] 4.4: `python3 MuMain/scripts/check-win32-guards.py` exits 0

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 | Existing tests pass | No regressions in timer, core tests |
| Build | CMake + Ninja | All platforms | macOS native, MinGW cross-compile |
| Grep verification | shell | 0 matches | Zero `#ifdef _WIN32` in Audio/, zero DirectSound types |
| Script verification | check-win32-guards.py | exit 0 | No platform guard violations outside Platform/ |

---

## Dev Notes

### Existing miniaudio infrastructure

- `IPlatformAudio` interface: `Platform/IPlatformAudio.h` — 15+ pure virtual methods
- `MiniAudioBackend` implementation: `Platform/MiniAudio/MiniAudioBackend.h/cpp` — uses `ma_engine`, `ma_sound`
- Global: `g_platformAudio` (allocated in MuMain startup)
- Stories 5-2-1 (BGM) and 5-2-2 (SFX) established the pattern
- `DbToLinear()` helper already converts DirectSound dB values to miniaudio linear scale

### DirectSound → miniaudio mapping

| DirectSound function | IPlatformAudio equivalent |
|---------------------|--------------------------|
| `DirectSoundCreate` | `g_platformAudio->Initialize()` (already called at startup) |
| `CreateSoundBuffer` | Internal to miniaudio decoder |
| `IDirectSoundBuffer::Play` | `g_platformAudio->PlaySound()` |
| `IDirectSoundBuffer::Stop` | `g_platformAudio->StopSound()` |
| `IDirectSoundBuffer::SetVolume` | `g_platformAudio->SetVolume()` / `SetSFXVolume()` |
| `IDirectSound3DBuffer::SetPosition` | `g_platformAudio->Set3DSoundPosition()` |
| `IDirectSound3DListener` | `g_platformAudio->Set3DSoundPosition()` (listener integrated) |
| `mmioOpen/mmioRead` | `ma_decoder_init_file()` (miniaudio built-in WAV decoder) |

### After 7-9-3 + 7-9-4

Combined result: **zero `#ifdef _WIN32` outside Platform/**. The ONLY place platform-specific
code lives is `Platform/PlatformCompat.h`, `Platform/PlatformTypes.h`, `Platform/win32/`,
`Platform/posix/`, and the renderer backends. Game code is 100% platform-agnostic.

### Key risks and mitigations

1. **3D audio positioning** — DirectSound uses `IDirectSound3DBuffer::SetPosition()`. Check that `Set3DSoundPosition()` in MiniAudioBackend handles all call patterns.
2. **Volume scale mismatch** — DirectSound uses dB (DSBVOLUME range -10000 to 0), miniaudio uses linear 0.0-1.0. `DbToLinear()` already exists in MiniAudioBackend for this conversion.
3. **Wave format types** — `WAVEFORMATEX` and `MMCKINFO` are Win32 types. Either delete the code that uses them or add stubs to PlatformCompat.h if any non-Win32 code path still references them.

### PCC Project Constraints

- **Prohibited:** No new `#ifdef _WIN32` in game logic; no raw `new`/`delete`; no `NULL`; no `wprintf`
- **Required:** `std::unique_ptr`, `nullptr`, `std::chrono`, `#pragma once`, forward slashes
- **Quality gate:** `./ctl check` (clang-format 21.1.8 + cppcheck + native build)
- **References:** `_bmad-output/project-context.md`, `docs/development-standards.md`

### References

- [Source: Audio/DSplaysound.cpp] — 14 `#ifdef _WIN32` blocks (860 lines)
- [Source: Audio/DSwaveIO.cpp] — 2 `#ifdef _WIN32` blocks (251 lines)
- [Source: Audio/DSwaveIO.h] — 2 `#ifdef _WIN32` blocks (55 lines)
- [Source: Audio/DSPlaySound.h] — 1 `#ifdef _WIN32` block (1021 lines)
- [Source: Audio/DSWavRead.h] — 1 `#ifdef _WIN32` block (36 lines)
- [Source: Platform/IPlatformAudio.h] — Cross-platform audio interface (15+ methods)
- [Source: Platform/MiniAudio/MiniAudioBackend.h/cpp] — miniaudio implementation
- [Source: Story 5-2-1] — Miniaudio BGM integration (done)
- [Source: Story 5-2-2] — Miniaudio SFX integration (done)
- [Source: Story 7-9-3] — Unified entry point, removed #ifdef _WIN32 outside Audio/ (done)

---

## Dev Agent Record

### Agent Model Used

claude-opus-4-6

### Debug Log References

- SIGSEGV in test: ODR violation — test compiled without `Defined_Global.h`, causing `MAX_BUFFER` mismatch (946 vs 977). Fixed by adding `#include "Defined_Global.h"` to test file.

### Completion Notes List

- Deleted ~860 lines of DirectSound code from `DSplaysound.cpp`, replaced with ~90 lines of IPlatformAudio delegates
- Deleted `DSwaveIO.cpp` (252 lines), `DSwaveIO.h` (55 lines), `DSWavRead.h` (36 lines) — entirely dead code
- Added `ReleaseSound()` to `IPlatformAudio` and `MiniAudioBackend` for `ReleaseBuffer()` call sites
- Removed `dsound` linker dependency from both MSVC and MinGW CMake sections
- Updated 7-9-3 test to remove Audio/ from exemption list
- Fixed test SIGSEGV: ODR violation from `ESound` enum `#ifdef` guards requiring `Defined_Global.h`
- Fixed stack overflow: Changed stack-allocated `MiniAudioBackend` (3.7MB) to heap-allocated `std::make_unique` in AC-4 tests
- Cleaned up debug `fprintf` remnants from `MiniAudioBackend::~MiniAudioBackend()`
- Verified all 13 test cases (260 assertions) pass for story 7-9-4
- `./ctl check` exits 0, `check-win32-guards.py` exits 0, zero grep matches for banned patterns

### File List

| File | Action | Summary |
|------|--------|---------|
| `src/source/Audio/DSplaysound.cpp` | Rewritten | All functions delegate to `g_platformAudio` |
| `src/source/Audio/DSPlaySound.h` | Modified | Removed `#ifdef _WIN32` around `InitDirectSound` |
| `src/source/Audio/DSwaveIO.cpp` | Deleted | Win32 wave I/O (entirely `#ifdef _WIN32`) |
| `src/source/Audio/DSwaveIO.h` | Deleted | Win32 wave types (entirely `#ifdef _WIN32`) |
| `src/source/Audio/DSWavRead.h` | Deleted | Dead code, never included |
| `src/source/Platform/IPlatformAudio.h` | Modified | Added `ReleaseSound()` method |
| `src/source/Platform/MiniAudio/MiniAudioBackend.h` | Modified | Added `ReleaseSound()` override |
| `src/source/Platform/MiniAudio/MiniAudioBackend.cpp` | Modified | Implemented `ReleaseSound()` |
| `src/CMakeLists.txt` | Modified | Removed `dsound` from MSVC and MinGW link libs |
| `tests/audio/test_directsound_removal_7_9_4.cpp` | Modified | Fixed ODR violation, merged duplicate test |
| `tests/platform/test_entry_point_unification_7_9_3.cpp` | Modified | Removed Audio/ from exemption list |
