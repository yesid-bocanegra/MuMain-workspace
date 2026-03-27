# Story 7.9.4: Kill DirectSound — Miniaudio-Only Audio Layer

Status: backlog

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
| Prerequisites | 5-2-1-miniaudio-bgm (done), 5-2-2-miniaudio-sfx (done), 7-9-3-unify-entry-point |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Delete DSplaysound.cpp/DSwaveIO.cpp DirectSound implementations; wire all 18 `#ifdef _WIN32` audio call sites through IPlatformAudio/miniaudio; delete DirectSound headers and types |
| project-docs | documentation | Story artifacts |

---

## Background

The audio layer has 18 `#ifdef _WIN32` guards across 4 files, all protecting DirectSound
code (`IDirectSoundBuffer`, `DSBUFFERDESC`, `waveOutOpen`, etc.). The miniaudio backend
(`MiniAudioBackend` implementing `IPlatformAudio`) already exists and works on all platforms
(stories 5-2-1 and 5-2-2). But the old DirectSound code was left in place behind `#ifdef _WIN32`
instead of being deleted.

| File | Guards | What it protects |
|------|--------|-----------------|
| `Audio/DSplaysound.cpp` | 14 | DirectSound buffer creation, playback, volume, 3D positioning |
| `Audio/DSwaveIO.cpp` | 2 | WAV file parsing via Win32 `mmioOpen`/`mmioRead` |
| `Audio/DSPlaySound.h` | 1 | `IDirectSoundBuffer` type declarations |
| `Audio/DSwaveIO.h` | 1 | `WAVEFORMATEX`, `MMCKINFO` type declarations |

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

- [ ] **AC-1: Delete DirectSound implementations**
  All DirectSound API calls are removed from `DSplaysound.cpp`:
  `DirectSoundCreate`, `CreateSoundBuffer`, `IDirectSoundBuffer::Play/Stop/SetVolume`,
  `IDirectSound3DBuffer`, `IDirectSound3DListener`.
  Each is replaced with the equivalent `IPlatformAudio` / miniaudio call.

- [ ] **AC-2: Delete Win32 wave I/O**
  `DSwaveIO.cpp` and `DSwaveIO.h` Win32 implementations (`mmioOpen`, `mmioRead`, `mmioDescend`)
  are deleted. WAV loading goes through miniaudio's built-in decoder (`ma_decoder`).

- [ ] **AC-3: Zero `#ifdef _WIN32` in Audio/**
  `grep -rn '#ifdef _WIN32' src/source/Audio/` returns 0.
  No DirectSound types (`IDirectSoundBuffer`, `DSBUFFERDESC`, `WAVEFORMATEX`, `LPDIRECTSOUND`)
  remain in any audio header or source file.

- [ ] **AC-4: All audio functions route through IPlatformAudio**
  Every public function in `DSPlaySound.h` that game code calls (PlayBuffer, StopBuffer,
  SetVolume, SetPosition3D, etc.) delegates to `g_platformAudio` methods.
  Game code never touches DirectSound or miniaudio directly.

- [ ] **AC-5: Quality gate passes**
  `./ctl check` exits 0. MinGW cross-compile passes.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — clang-format clean; zero `#ifdef _WIN32` in Audio/.
- [ ] **AC-STD-2:** Testing Requirements — Catch2 test suite passes; no regressions.
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [ ] **Task 1: Audit DirectSound call sites**
  - [ ] 1.1: Map every `#ifdef _WIN32` block in DSplaysound.cpp to its IPlatformAudio equivalent
  - [ ] 1.2: Map DSwaveIO.cpp functions to miniaudio decoder equivalents
  - [ ] 1.3: Identify any DirectSound features NOT yet in IPlatformAudio (3D positioning, etc.)

- [ ] **Task 2: Extend IPlatformAudio if needed**
  - [ ] 2.1: Add any missing methods to IPlatformAudio for features used by game code
  - [ ] 2.2: Implement in MiniAudioBackend

- [ ] **Task 3: Replace DirectSound with IPlatformAudio calls**
  - [ ] 3.1: DSplaysound.cpp — replace all 14 `#ifdef _WIN32` blocks
  - [ ] 3.2: DSPlaySound.h — remove DirectSound type declarations
  - [ ] 3.3: DSwaveIO.cpp — delete or replace with miniaudio decoder
  - [ ] 3.4: DSwaveIO.h — delete DirectSound types

- [ ] **Task 4: Quality gate**
  - [ ] 4.1: `./ctl check` passes
  - [ ] 4.2: MinGW cross-compile passes
  - [ ] 4.3: `grep -rn '#ifdef _WIN32' src/source/Audio/` returns 0

---

## Dev Notes

### Existing miniaudio infrastructure

- `IPlatformAudio` interface: `Audio/IPlatformAudio.h`
- `MiniAudioBackend` implementation: `Audio/MiniAudioBackend.h/cpp`
- Global: `g_platformAudio` (allocated in MuMain/WinMain)
- Stories 5-2-1 (BGM) and 5-2-2 (SFX) established the pattern

### DirectSound → miniaudio mapping

| DirectSound function | IPlatformAudio equivalent |
|---------------------|--------------------------|
| `DirectSoundCreate` | `g_platformAudio->Initialize()` (already called) |
| `CreateSoundBuffer` | Internal to miniaudio decoder |
| `IDirectSoundBuffer::Play` | `g_platformAudio->PlaySound()` |
| `IDirectSoundBuffer::Stop` | `g_platformAudio->StopSound()` |
| `IDirectSoundBuffer::SetVolume` | `g_platformAudio->SetSFXVolume()` |
| `mmioOpen/mmioRead` | `ma_decoder_init_file()` (miniaudio built-in) |

### After 7-9-3 + 7-9-4

Combined result: **zero `#ifdef _WIN32` outside Platform/**. The ONLY place platform-specific
code lives is `Platform/PlatformCompat.h`, `Platform/PlatformTypes.h`, `Platform/win32/`,
`Platform/posix/`, and the renderer backends. Game code is 100% platform-agnostic.

### References

- [Source: Audio/DSplaysound.cpp] — 14 `#ifdef _WIN32` blocks to eliminate
- [Source: Audio/DSwaveIO.cpp] — 2 `#ifdef _WIN32` blocks to eliminate
- [Source: Audio/IPlatformAudio.h] — Cross-platform audio interface
- [Source: Audio/MiniAudioBackend.h/cpp] — miniaudio implementation
- [Source: Story 5-2-1] — Miniaudio BGM integration
- [Source: Story 5-2-2] — Miniaudio SFX integration

---

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
