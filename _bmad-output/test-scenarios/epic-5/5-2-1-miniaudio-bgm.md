# Test Scenarios — Story 5.2.1: miniaudio BGM Implementation

**Story ID:** 5-2-1-miniaudio-bgm
**Epic:** 5 — Audio System Migration
**Story Type:** infrastructure
**Flow Code:** VS1-AUDIO-MINIAUDIO-BGM
**Generated:** 2026-03-19

---

## Prerequisites

- Story 5.1.1 complete (IPlatformAudio + MiniAudioBackend implemented)
- Windows build (DirectX + Win32 available) for runtime tests
- macOS/Linux for automated Catch2 tests (headless)
- `./ctl check` quality gate: `cd MuMain && ./ctl check`

---

## Automated Tests (Catch2, Headless)

| Scenario | Test | Expected | Environment |
|----------|------|----------|-------------|
| IsEndMusic before play | `AC-STD-2: MiniAudioBackend BGM lifecycle — IsEndMusic before play` | Returns true | macOS/Linux/Windows CI |
| StopMusic on unloaded stream | `AC-STD-2: MiniAudioBackend BGM lifecycle — StopMusic on unloaded stream` | No crash; IsEndMusic true | macOS/Linux/Windows CI |
| PlayMusic nonexistent file | `AC-STD-2: MiniAudioBackend BGM lifecycle — PlayMusic non-existent file returns without crash` | No crash; IsEndMusic true | macOS/Linux/Windows CI |
| GetMusicPosition before play | `AC-STD-2: MiniAudioBackend BGM — GetMusicPosition before play returns 0` | Returns 0 | macOS/Linux/Windows CI |

**Run:** `cd MuMain && cmake --preset macos-arm64 && cmake --build --preset macos-arm64-debug --target MuTests && ctest --preset macos-arm64-debug`

---

## AC-1: g_platformAudio Wired at Startup

**Test Type:** Code inspection + runtime
**Steps:**
1. Open `MuMain/src/source/Main/Winmain.cpp`
2. Locate lines ~1290-1299 (after `g_pNewUISystem->Create()`)
3. Verify `g_platformAudio = new mu::MiniAudioBackend();` is present
4. Verify `if (!g_platformAudio->Initialize()) { g_ErrorReport.Write(...) }` is present
5. (Runtime) Launch game on Windows — verify no crash at startup; audio log shows init result

**Expected:** `g_platformAudio` is non-null after startup; `Initialize()` result logged

---

## AC-2: wzAudio Lifecycle Replaced

**Test Type:** Code inspection
**Steps:**
1. Grep Winmain.cpp for `wzAudioCreate`, `wzAudioOption`, `wzAudioDestroy` — must return 0 matches
2. Grep Winmain.cpp for `#include.*wzAudio`, `#pragma comment.*wzAudio` — must return 0 matches
3. Verify `DestroySound()` contains `g_platformAudio->Shutdown(); delete g_platformAudio;`

**Expected:** No wzAudio API calls in Winmain.cpp

---

## AC-3: BGM Free Functions Delegate to g_platformAudio

**Test Type:** Code inspection
**Steps:**
1. Read `StopMusic()` — must call `g_platformAudio->StopMusic(nullptr, FALSE)`
2. Read `StopMp3(Name, bEnforce)` — must check `m_MusicOnOff`, call `g_platformAudio->StopMusic(Name, bEnforce)`
3. Read `PlayMp3(Name, bEnforce)` — must check `Destroy` and `m_MusicOnOff`, call `g_platformAudio->PlayMusic(Name, bEnforce)`
4. Read `IsEndMp3()` — must return `g_platformAudio->IsEndMusic()` with nullptr guard
5. Read `GetMp3PlayPosition()` — must return `g_platformAudio->GetMusicPosition()` with nullptr guard
6. Grep for `Mp3FileName` global declaration — must return 0 matches

**Expected:** All 5 functions delegate; Mp3FileName removed

---

## AC-4: BGM Plays on All Platforms (Manual Validation)

**Test Type:** Runtime validation — Windows + macOS/Linux
**Prerequisites:** Windows build; macOS/Linux build with audio device
**Steps:**
1. Build on Windows: `cmake --preset windows-x64 && cmake --build --preset windows-x64-debug`
2. Launch game, reach Lorencia — verify BGM plays (Mutheme.mp3)
3. (macOS/Linux CI) Verify no platform-specific `#ifdef _WIN32` in `MiniAudioBackend.cpp`
4. (macOS/Linux CI) Verify `./ctl check` passes (no forbidden Win32 calls added)

**Expected:** BGM plays on Windows; no platform-specific code in backend

---

## AC-5: BGM Transitions (Code Inspection)

**Test Type:** Code inspection
**Steps:**
1. Read `MiniAudioBackend::PlayMusic()` — verify `!enforce && m_currentMusicName == normalizedName` guard returns early
2. Verify `enforce=true` path always stops + uninits current track before loading new one
3. Verify `Mp3FileName` array is removed (AC-3 covers this)

**Expected:** Same-track guard implemented via `m_currentMusicName`

---

## AC-6: BGM Loops (Code Inspection)

**Test Type:** Code inspection
**Steps:**
1. Read `MiniAudioBackend::PlayMusic()` — verify `ma_sound_set_looping(&m_musicSound, MA_TRUE)` is called before `ma_sound_start()`

**Expected:** `MA_TRUE` looping set on every PlayMusic call

---

## AC-7: Set3DSoundPosition() Loop Structure (Code Inspection)

**Test Type:** Code inspection
**Steps:**
1. Read `MiniAudioBackend::Set3DSoundPosition()` — verify loop iterates `MAX_BUFFER` slots
2. Verify `m_soundLoaded[buf] && m_sound3DEnabled[buf]` guard present
3. Verify inner loop over `MAX_CHANNEL` with `ma_sound_is_playing()` check
4. Verify comment documenting 5.2.2 deferral for per-slot OBJECT* tracking

**Expected:** Loop structure in place; body intentionally empty with deferral comment

---

## AC-8: wzAudio.lib Removed (Code Inspection + Build)

**Test Type:** Code inspection + build
**Steps:**
1. Grep `MuMain/src/CMakeLists.txt` for `wzAudio` — must return only comments (lines with `#`)
2. (Windows build) Verify `wzAudio.dll` is not required at runtime

**Expected:** wzAudio.lib removed from link libraries; only comment references remain

---

## AC-VAL-1: BGM Plays in Lorencia (Manual Runtime — Windows)

**Test Type:** Manual runtime — Windows only
**Prerequisites:** Windows build, game connects to server, Lorencia map loads
**Steps:**
1. Launch game on Windows
2. Log in and spawn in Lorencia
3. Verify Mutheme.mp3 or pub.mp3 plays (zone-specific BGM per SceneManager.cpp)
4. Check no audio error in `error.log`

**Expected:** BGM plays in Lorencia; no `AUDIO: MiniAudioBackend::PlayMusic -- failed` in error log

---

## AC-VAL-2: Zone Transition BGM (Manual Runtime — Windows)

**Test Type:** Manual runtime — Windows only
**Prerequisites:** AC-VAL-1 passing
**Steps:**
1. From Lorencia, move to Noria (zone with different BGM)
2. Verify Lorencia BGM stops cleanly (no pop/click)
3. Verify Noria BGM starts (different track)
4. Move back to Lorencia — verify correct BGM resumes

**Expected:** BGM changes cleanly on zone transition; no audio artifacts

---

## AC-VAL-3: Quality Gate (Automated)

**Test Type:** Automated
**Command:** `./ctl check` (from workspace root)
**Expected:** 0 errors, 711 files checked

---

## AC-VAL-4: File Diff Verification (Automated)

**Test Type:** Code inspection
**Command:** `cd MuMain && git diff --name-only HEAD~1`
**Expected modified files:**
- `src/CMakeLists.txt`
- `src/source/Main/Winmain.cpp`
- `src/source/Platform/MiniAudio/MiniAudioBackend.cpp`
- `tests/audio/test_miniaudio_bgm.cpp` (committed in ATDD phase)
- `tests/CMakeLists.txt` (committed in ATDD phase)

---

*Test scenarios generated by PCC dev-story workflow*
