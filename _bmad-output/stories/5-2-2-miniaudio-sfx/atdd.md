# ATDD Checklist — Story 5.2.2: miniaudio SFX Implementation

**Story ID:** 5-2-2-miniaudio-sfx
**Story Type:** infrastructure
**Date Generated:** 2026-03-19
**Phase:** RED — all test items start as `[ ]` (pending implementation)

---

## PCC Compliance Summary

| Check | Status | Notes |
|-------|--------|-------|
| Guidelines loaded | PASS | project-context.md + development-standards.md loaded |
| Existing tests mapped | PASS | No pre-existing tests for 5-2-2 ACs found |
| Prohibited libraries | PASS | No DirectSound, wzAudio, or Win32-only APIs in new test code |
| Required test framework | PASS | Catch2 3.7.1, `MuTests` target, `tests/audio/` directory |
| Playwright | N/A | infrastructure story — no frontend E2E |
| Bruno collections | N/A | infrastructure story — no REST endpoints |
| Coverage target | incremental | Adding 7 TEST_CASEs; no coverage threshold enforced |

---

## Test Level Selection

| Level | Included | Rationale |
|-------|----------|-----------|
| Unit (Catch2) | YES | SFX lifecycle safety, headless, pure C++ logic |
| Integration (manual) | YES | SFX plays on game events — deferred to QA (skip_checks: build,test) |
| E2E (Playwright) | NO | infrastructure story |
| API Collection (Bruno) | NO | no REST endpoints |

---

## AC → Test Method Mapping

| AC | Description | Test Method | File | Status |
|----|-------------|-------------|------|--------|
| AC-1 | LoadWaveFile delegates to g_platformAudio | Code inspection (delegation chain in DSplaysound.cpp) | N/A | `[ ]` |
| AC-2 | PlayBuffer delegates; returns result | `AC-STD-2: MiniAudioBackend SFX — PlaySound before Initialize returns S_FALSE` | `tests/audio/test_miniaudio_sfx.cpp` | `[ ]` |
| AC-3 | StopBuffer delegates when g_platformAudio != nullptr | `AC-STD-2: MiniAudioBackend SFX — StopSound on unloaded slot is safe` | `tests/audio/test_miniaudio_sfx.cpp` | `[ ]` |
| AC-4 | AllStopSound delegates | `AC-STD-2: MiniAudioBackend SFX — AllStopSound on empty backend is safe` | `tests/audio/test_miniaudio_sfx.cpp` | `[ ]` |
| AC-5 | SetMasterVolume delegates | `AC-5/AC-6: MiniAudioBackend SFX — volume control before Initialize is safe` | `tests/audio/test_miniaudio_sfx.cpp` | `[ ]` |
| AC-6 | SetVolume delegates | `AC-5/AC-6: MiniAudioBackend SFX — volume control before Initialize is safe` | `tests/audio/test_miniaudio_sfx.cpp` | `[ ]` |
| AC-7 | InitDirectSound/FreeDirectSound removed from Winmain.cpp | Code inspection (Winmain.cpp diff) | N/A | `[ ]` |
| AC-8 | MiniAudioBackend gains m_soundObjects tracking; Set3DSoundPosition upgraded | `AC-STD-2: MiniAudioBackend SFX — Set3DSoundPosition with no loaded sounds is safe` + `...skips nullptr m_soundObjects` | `tests/audio/test_miniaudio_sfx.cpp` | `[ ]` |
| AC-9 | SFX plays on all platforms; backslash→forward-slash normalization | `AC-STD-2: MiniAudioBackend SFX — LoadSound non-existent file does not crash` | `tests/audio/test_miniaudio_sfx.cpp` | `[ ]` |
| AC-10 | DirectSoundManager dormant (never initialized) | Code inspection (no Manager().Initialize() call path) | N/A | `[ ]` |
| AC-STD-1 | Code standards compliance | `./ctl check` (clang-format + cppcheck) | N/A | `[ ]` |
| AC-STD-2 | Catch2 SFX lifecycle test file exists and covers all 5 scenarios | All 7 TEST_CASEs in `tests/audio/test_miniaudio_sfx.cpp` | `tests/audio/test_miniaudio_sfx.cpp` | `[ ]` |
| AC-STD-4 | CI quality gate passes | `./ctl check` — 0 errors | N/A | `[ ]` |
| AC-STD-13 | Quality gate passes | `./ctl check` | N/A | `[ ]` |
| AC-STD-16 | Correct test infrastructure (Catch2 3.7.1, MuTests, tests/audio/) | CMakeLists.txt `target_sources(MuTests PRIVATE audio/test_miniaudio_sfx.cpp)` | `tests/CMakeLists.txt` | `[ ]` |

---

## Implementation Checklist

### Test Infrastructure (RED Phase)

- [ ] `tests/audio/test_miniaudio_sfx.cpp` created with 7 TEST_CASEs (DONE — file exists in RED phase)
- [ ] `tests/CMakeLists.txt` updated: `target_sources(MuTests PRIVATE audio/test_miniaudio_sfx.cpp)` added
- [ ] All test cases compile without errors
- [ ] All test cases FAIL before implementation (RED phase confirmed)

### Core Implementation

- [ ] `MiniAudioBackend.h`: Add `std::array<const OBJECT*, MAX_BUFFER> m_soundObjects{}` private member (AC-8 / Task 1.1)
- [ ] `MiniAudioBackend.cpp` `PlaySound()`: Store `pObject` in `m_soundObjects[bufIdx]` after position set, when `m_sound3DEnabled[bufIdx]` (AC-8 / Task 1.2)
- [ ] `MiniAudioBackend.cpp` `Shutdown()`: Clear `m_soundObjects[buf] = nullptr` in cleanup loop (AC-8 / Task 1.3)
- [ ] `MiniAudioBackend.cpp` `Set3DSoundPosition()`: Upgrade stub to call `ma_sound_set_position()` for active 3D slots using `m_soundObjects[buf]->Position`; nullptr guard present (AC-8 / Task 2.1)
- [ ] `MiniAudioBackend.cpp` `Set3DSoundPosition()`: Comment updated to remove 5.2.2 placeholder (Task 2.2)
- [ ] `MiniAudioBackend.cpp` `LoadSound()`: Add `std::replace(utf8Path.begin(), utf8Path.end(), '\\', '/')` after `mu_wchar_to_utf8()` (AC-9 / Task 5.1)
- [ ] Path normalization is applied before `ma_sound_init_from_file()` call (AC-9 / Task 5.2)

### DSplaysound.cpp Redirections

- [ ] `DSplaysound.cpp`: `#include "IPlatformAudio.h"` added (Task 3.1)
- [ ] `DSplaysound.cpp` `LoadWaveFile()`: Delegates to `g_platformAudio->LoadSound()` when `!= nullptr` (AC-1 / Task 3.2)
- [ ] `DSplaysound.cpp` `PlayBuffer()`: Delegates to `g_platformAudio->PlaySound()` when `!= nullptr` (AC-2 / Task 3.3)
- [ ] `DSplaysound.cpp` `StopBuffer()`: Delegates to `g_platformAudio->StopSound()` when `!= nullptr` (AC-3 / Task 3.4)
- [ ] `DSplaysound.cpp` `AllStopSound()`: Delegates to `g_platformAudio->AllStopSound()` when `!= nullptr` (AC-4 / Task 3.5)
- [ ] `DSplaysound.cpp` `SetMasterVolume()`: Delegates to `g_platformAudio->SetMasterVolume()` when `!= nullptr` (AC-5 / Task 3.6)
- [ ] `DSplaysound.cpp` `SetVolume()`: Delegates to `g_platformAudio->SetVolume(static_cast<ESound>(buffer), vol)` when `!= nullptr` (AC-6 / Task 3.7)
- [ ] `DSplaysound.cpp` `Set3DSoundPosition()`: Delegates to `g_platformAudio->Set3DSoundPosition()` when `!= nullptr` (Task 3.8)
- [ ] Zero call-site changes outside `DSplaysound.cpp` (AC-1 requirement)

### Winmain.cpp Cleanup

- [ ] `Winmain.cpp`: `InitDirectSound(g_hWnd)` call removed from `if (m_SoundOnOff)` block (AC-7 / Task 4.1)
- [ ] `Winmain.cpp` `DestroySound()`: `FreeDirectSound()` call removed (AC-7 / Task 4.2)
- [ ] `Winmain.cpp`: Story 5.2.2 annotation comment added (Task 4.2)
- [ ] `Winmain.cpp`: `#include "DSPlaySound.h"` remains present (Task 4.3)

### Verification

- [ ] Code inspection: no `Manager().Initialize()` call path remains active (AC-10)
- [ ] Code inspection: no `#ifdef _WIN32` added to `MiniAudioBackend.cpp` (AC-9)
- [ ] `g_ErrorReport.Write()` error pattern emitted correctly after path normalization (AC-STD-5)
- [ ] `./ctl check` passes with 0 errors (AC-STD-4 / AC-VAL-3)
- [ ] `git diff --name-only` shows only expected files — no unintended regressions (AC-VAL-4)

### PCC Compliance

- [ ] No prohibited libraries used (no DirectSound, wzAudio, `#include <dsound.h>` in new code)
- [ ] All new/modified code in `Platform/` uses `mu::` namespace
- [ ] `m_` prefix on all new member variables (`m_soundObjects`)
- [ ] `#pragma once` in all new/modified headers
- [ ] No raw `new`/`delete` in new code
- [ ] No `NULL` — `nullptr` only
- [ ] No `wprintf` — `g_ErrorReport.Write()` for all failure paths
- [ ] No `#ifdef _WIN32` in `MiniAudioBackend.cpp`
- [ ] Catch2 3.7.1 used (`MuTests` target, `tests/audio/` directory, explicit `target_sources`)
- [ ] Conventional commit: `feat(audio): implement SFX playback via miniaudio` (AC-STD-6)

---

## Test Files Created (RED Phase)

| File | Status | Notes |
|------|--------|-------|
| `MuMain/tests/audio/test_miniaudio_sfx.cpp` | CREATED | 7 TEST_CASEs covering AC-2, AC-3, AC-4, AC-5, AC-6, AC-8, AC-9 |

## Code Files to Modify (not yet created — pending dev-story)

| File | Change |
|------|--------|
| `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` | Add `m_soundObjects` array member |
| `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` | `PlaySound()`: store `m_soundObjects`; `Set3DSoundPosition()`: upgrade stub; `LoadSound()`: path normalization; `Shutdown()`: clear array |
| `MuMain/src/source/Audio/DSplaysound.cpp` | Add `#include "IPlatformAudio.h"`; redirect 8 free functions |
| `MuMain/src/source/Main/Winmain.cpp` | Remove `InitDirectSound(g_hWnd)` and `FreeDirectSound()` calls |
| `MuMain/tests/CMakeLists.txt` | Add `audio/test_miniaudio_sfx.cpp` to `MuTests` |

---

## Output Summary

- **Story ID:** 5-2-2-miniaudio-sfx
- **Primary test level:** Unit (Catch2, headless)
- **Failing tests created:** 7 TEST_CASEs (RED phase)
- **AC-to-test mapping:** Complete (see table above)
- **Output file:** `_bmad-output/stories/5-2-2-miniaudio-sfx/atdd.md`
- **Test file:** `MuMain/tests/audio/test_miniaudio_sfx.cpp`
