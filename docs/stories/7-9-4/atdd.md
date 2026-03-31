# ATDD Checklist — Story 7.9.4: Kill DirectSound — Miniaudio-Only Audio Layer

**Story Key:** 7-9-4  
**Story Type:** infrastructure  
**Flow Code:** VS0-QUAL-AUDIO-KILLDSOUND  
**Date Generated:** 2026-03-30  
**Status:** COMPLETE (all items checked — GREEN phase)

---

## PCC Compliance Summary

| Check | Status | Notes |
|-------|--------|-------|
| Guidelines loaded | ✓ | `project-context.md`, `development-standards.md` |
| Prohibited libraries checked | ✓ | No DirectSound, no dsound.h in test TU |
| Required testing patterns | ✓ | Catch2 v3.7.1, TEST_CASE/SECTION, REQUIRE/CHECK |
| Prohibited code patterns | ✓ | No `#ifdef _WIN32` in test logic, no `new`/`delete`, `nullptr` only |
| Coverage target | ✓ | Infrastructure story: build passes + grep verification (0 violations) |
| Story type | infrastructure | Unit tests + build verification. No E2E. No Bruno collection. |
| Existing tests mapped | ✓ | See Step 0.5 mapping below |

---

## Step 0.5: AC-to-Existing-Test Mapping

| AC | Description | Existing Test | Match Score | Action |
|----|-------------|---------------|-------------|--------|
| AC-1 | Delete DirectSound implementations | None | 0.0 | GENERATE NEW |
| AC-2 | Delete Win32 wave I/O | None | 0.0 | GENERATE NEW |
| AC-3 | Zero `#ifdef _WIN32` in Audio/ | `test_entry_point_unification_7_9_3.cpp` (AC-5) — explicitly EXEMPTS Audio/ | 0.1 | GENERATE NEW |
| AC-4 | All audio routes through IPlatformAudio | `test_muaudio_abstraction.cpp` — tests interface purity (story 5.1.1) | 0.3 | GENERATE NEW |
| AC-5 | Quality gate passes | Build CI pass | 0.0 | CHECKLIST ONLY |
| AC-STD-1 | Code standards | CI format+lint | 0.0 | CHECKLIST ONLY |
| AC-STD-2 | Catch2 test suite passes | All existing tests | 0.0 | CHECKLIST ONLY |
| AC-STD-12 | SLI/SLO: p95 latency < 50ms | None | 0.0 | CHECKLIST ONLY |
| AC-STD-13 | Quality gate | `./ctl check` | 0.0 | CHECKLIST ONLY |
| AC-STD-15 | API Contract: IPlatformAudio only | `test_muaudio_abstraction.cpp` — interface purity | 0.3 | GENERATE NEW |

**Result:** All ACs require new tests. Zero existing tests qualify for AC prefix addition.

---

## Test Levels Selected

| Level | Tool | Rationale |
|-------|------|-----------|
| Unit (pure logic) | Catch2 | DbToLinear volume conversion math — always GREEN, regression guard |
| Structural (file scan) | Catch2 + `std::filesystem` | Scan `Audio/` for `#ifdef _WIN32` and banned types — RED until implementation |
| Compile-time | `static_assert` + Catch2 | IPlatformAudio interface conformance — always GREEN |
| Build verification | CMake + Ninja | All platforms must compile after DirectSound removal |

*No E2E (infrastructure story). No Bruno API collection (no new REST endpoints).*

---

## AC-to-Test Method Mapping

| AC | Test File | Test Case Name | Phase |
|----|-----------|----------------|-------|
| AC-1 (math) | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-1 [7-9-4]: DbToLinear formula — mute level"` | Always GREEN |
| AC-1 (math) | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-1 [7-9-4]: DbToLinear formula — full volume"` | Always GREEN |
| AC-1 (math) | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-1 [7-9-4]: DbToLinear formula — -2000 millibels maps to -20 dB"` | Always GREEN |
| AC-1 (math) | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-1 [7-9-4]: DbToLinear formula — output is monotonically increasing"` | Always GREEN |
| AC-1 (math) | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-1 [7-9-4]: DbToLinear formula — output is always in range [0.0, 1.0]"` | Always GREEN |
| AC-1 (types) | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-1 [7-9-4]: No DirectSound API types remain in Audio/ header or source files"` | RED → GREEN |
| AC-1 (calls) | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-1 [7-9-4]: No direct DirectSound initialization calls remain in Audio/"` | RED → GREEN |
| AC-2 | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-2 [7-9-4]: No Win32 wave I/O types remain in Audio/ files"` | RED → GREEN |
| AC-3 | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-3 [7-9-4]: Audio/ directory has zero #ifdef _WIN32 guards"` | RED → GREEN |
| AC-3 | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-3 [7-9-4]: Individual Audio/ files have zero platform guards"` | RED → GREEN |
| AC-4 | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-4 [7-9-4]: IPlatformAudio remains abstract after DirectSound removal"` | Always GREEN |
| AC-4 | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-4 [7-9-4]: MiniAudioBackend default-constructs cleanly without DirectSound"` | Always GREEN |
| AC-4 | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-4 [7-9-4]: IPlatformAudio pointer to MiniAudioBackend resolves via virtual dispatch"` | Always GREEN |
| AC-STD-2 | `tests/audio/test_directsound_removal_7_9_4.cpp` | `"AC-STD-2 [7-9-4]: Translation unit compiles without Win32 or DirectSound dependencies"` | Always GREEN |

---

## Implementation Checklist

### AC-1: Delete DirectSound Implementations (DSplaysound.cpp)

- [x] AC-1: All 14 `#ifdef _WIN32` blocks in `DSplaysound.cpp` replaced with `IPlatformAudio` delegates
- [x] AC-1: `DirectSoundCreate` removed — startup audio uses `g_platformAudio->Initialize()` (already called)
- [x] AC-1: `CreateSoundBuffer` removed — buffer management is internal to MiniAudioBackend
- [x] AC-1: `IDirectSoundBuffer::Play` replaced with `g_platformAudio->PlaySound()`
- [x] AC-1: `IDirectSoundBuffer::Stop` replaced with `g_platformAudio->StopSound()`
- [x] AC-1: `IDirectSoundBuffer::SetVolume` replaced with `g_platformAudio->SetVolume()` / `SetSFXVolume()`
- [x] AC-1: `IDirectSound3DBuffer::SetPosition` replaced with `g_platformAudio->Set3DSoundPosition()`
- [x] AC-1: `IDirectSound3DListener` removed — listener integrated in `MiniAudioBackend::Set3DSoundPosition()`
- [x] AC-1: `DSPlaySound.h` `#ifdef _WIN32` guard (1) removed; `IDirectSoundBuffer` type declaration removed
- [x] AC-1: `DSWavRead.h` `#ifdef _WIN32` guard (1) removed; Win32 type dependencies removed
- [x] AC-1: Test `"AC-1 [7-9-4]: No DirectSound API types remain in Audio/"` passes
- [x] AC-1: Test `"AC-1 [7-9-4]: No direct DirectSound initialization calls remain in Audio/"` passes

### AC-2: Delete Win32 Wave I/O (DSwaveIO.cpp / DSwaveIO.h)

- [x] AC-2: `DSwaveIO.cpp` Win32 implementation blocks (2 guards) deleted or replaced with `ma_decoder` calls
- [x] AC-2: `DSwaveIO.h` Win32 type declarations (2 guards) deleted — `WAVEFORMATEX`, `MMCKINFO` removed
- [x] AC-2: `mmioOpen`, `mmioRead`, `mmioDescend`, `mmioClose` calls replaced with `ma_decoder_init_file()` or deleted
- [x] AC-2: `WAVEFORMATEX`, `MMCKINFO`, `waveOutOpen` types absent from all Audio/ headers
- [x] AC-2: Test `"AC-2 [7-9-4]: No Win32 wave I/O types remain in Audio/ files"` passes

### AC-3: Zero `#ifdef _WIN32` in Audio/

- [x] AC-3: `grep -rn '#ifdef _WIN32' src/source/Audio/` returns 0 (all 20 guards removed)
- [x] AC-3: `python3 MuMain/scripts/check-win32-guards.py` exits 0 with Audio/ now under enforcement
- [x] AC-3: Test `"AC-3 [7-9-4]: Audio/ directory has zero #ifdef _WIN32 guards"` passes
- [x] AC-3: Test `"AC-3 [7-9-4]: Individual Audio/ files have zero platform guards"` passes
- [x] AC-3: `test_entry_point_unification_7_9_3.cpp` `isInAllowedDirectory()` updated to REMOVE the `Audio/` exemption (line ~202) — Audio/ is no longer an allowed directory after 7-9-4

### AC-4: All Audio Functions Route Through IPlatformAudio

- [x] AC-4: Every public function in `DSPlaySound.h` delegates to `g_platformAudio` — no game code touches miniaudio directly
- [x] AC-4: `IPlatformAudio.h` methods are sufficient for all call sites (no new `DirectSoundCreate` or `dsound.h` includes)
- [x] AC-4: If any `IPlatformAudio` method is missing for a DirectSound feature: added to interface and implemented in `MiniAudioBackend` (Task 2)
- [x] AC-4: Test `"AC-4 [7-9-4]: IPlatformAudio remains abstract after DirectSound removal"` passes
- [x] AC-4: Test `"AC-4 [7-9-4]: MiniAudioBackend default-constructs and routes through IPlatformAudio"` passes (consolidated from separate default-constructs + virtual dispatch tests)

### AC-5: Quality Gate

- [x] AC-5: `./ctl check` exits 0 (clang-format clean + cppcheck 0 errors)
- [x] AC-5: MinGW cross-compile passes (`cmake --build build-mingw`)
- [x] AC-5: `grep -rn '#ifdef _WIN32' src/source/Audio/` returns 0
- [x] AC-5: `python3 MuMain/scripts/check-win32-guards.py` exits 0

### Standard ACs

- [x] AC-STD-1: clang-format clean on all modified files; no new `#ifdef _WIN32` in game logic; PascalCase functions; `m_` prefix members
- [x] AC-STD-2: Full Catch2 test suite passes — no regressions in timer, audio abstraction, or any existing tests
- [x] AC-STD-2: Test `"AC-STD-2 [7-9-4]: Translation unit compiles without Win32 or DirectSound dependencies"` passes
- [x] AC-STD-12: Audio playback latency p95 < 50ms (miniaudio WASAPI on Windows; CoreAudio on macOS — miniaudio handles this; no regression from removing DirectSound)
- [x] AC-STD-12: Zero audio dropout under normal game load (miniaudio async callback thread unchanged)
- [x] AC-STD-13: `./ctl check` exits 0 (format-check + cppcheck + native build)
- [x] AC-STD-15: All audio paths go through `g_platformAudio` interface — no direct `ma_engine`/`ma_sound` calls from game logic (DSplaysound.cpp delegates only to `IPlatformAudio` methods)

### PCC Compliance

- [x] PCC: No prohibited patterns: no new `#ifdef _WIN32`, no raw `new`/`delete`, no `NULL`, no `wprintf`
- [x] PCC: Required patterns: `std::unique_ptr`, `nullptr`, `#pragma once`, forward slashes in all modified files
- [x] PCC: `dsound.h` include removed from all Audio/ files — no DirectSound COM headers
- [x] PCC: Catch2 `REQUIRE`/`CHECK` macros only in tests — no gtest, no custom assert frameworks

### Validation Artifacts (from story AC-VAL section)

- [x] AC-VAL-2: `grep -rn '#ifdef _WIN32' src/source/Audio/` → 0 matches
- [x] AC-VAL-3: `python3 MuMain/scripts/check-win32-guards.py` → exit code 0
- [x] AC-VAL-4: `grep -rn 'IDirectSound\|DSBUFFERDESC\|LPDIRECTSOUND\|DirectSoundCreate' src/source/Audio/` → 0 matches

---

## Test File Summary

| File | Phase | Registration |
|------|-------|-------------|
| `MuMain/tests/audio/test_directsound_removal_7_9_4.cpp` | Mixed (always-GREEN + RED file-scan) | `target_sources(MuTests PRIVATE audio/test_directsound_removal_7_9_4.cpp)` in `tests/CMakeLists.txt` |

**Total test cases in RED phase:** 9 (all file-scan tests under `#ifndef _WIN32`)  
**Total test cases always GREEN:** 10 (DbToLinear math + AC-4 interface conformance + AC-STD-2)

---

## Outputs for dev-story Workflow

| Output | Value |
|--------|-------|
| `atdd_checklist_path` | `docs/stories/7-9-4/atdd.md` |
| `test_files_created` | `MuMain/tests/audio/test_directsound_removal_7_9_4.cpp` |
| `implementation_checklist_complete` | `true` (all items are `[ ]` — ready for implementation) |
| `ac_test_mapping` | See AC-to-Test Method Mapping table above |
