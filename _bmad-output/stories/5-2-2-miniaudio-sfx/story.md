# Story 5.2.2: miniaudio SFX Implementation

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 5 - Audio System Migration |
| Feature | 5.2 - Implementation |
| Story ID | 5.2.2 |
| Story Points | 5 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-AUDIO-MINIAUDIO-SFX |
| FRs Covered | FR18 (Sound effects on all platforms via miniaudio) |
| Prerequisites | 5.1.1 (IPlatformAudio + MiniAudioBackend created — done), 5.2.1 (BGM wired, wzAudio removed — done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Redirect `LoadWaveFile`, `PlayBuffer`, `StopBuffer`, `AllStopSound`, `Set3DSoundPosition`, `SetVolume`, `SetMasterVolume` free functions in `DSplaysound.cpp` to delegate to `g_platformAudio`; remove `InitDirectSound`/`FreeDirectSound` from `Winmain.cpp` startup/shutdown; add per-slot `OBJECT*` tracking to `MiniAudioBackend` for per-frame 3D position updates; Catch2 SFX lifecycle tests |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** player,
**I want** sound effects playing via miniaudio on all platforms,
**so that** I can hear game audio feedback (combat, UI, ambient) without DirectSound.

---

## Functional Acceptance Criteria

- [x] **AC-1:** `LoadWaveFile(ESound, const wchar_t*, int, bool)` free function in `DSplaysound.cpp` delegates to `g_platformAudio->LoadSound(buffer, filename, channels, enable3D)` when `g_platformAudio != nullptr`; falls through to the legacy `Manager().LoadWaveFile()` path only as a dead-code fallback (or is fully replaced — see Dev Notes). All existing call sites in `ZzzOpenData.cpp`, `Scenes/`, `World/Maps/`, `Gameplay/`, `RenderFX/` remain unchanged (zero call-site changes outside `DSplaysound.cpp`).
- [x] **AC-2:** `PlayBuffer(ESound, OBJECT*, BOOL)` free function delegates to `g_platformAudio->PlaySound(buffer, object, looped)` and returns its result when `g_platformAudio != nullptr`. The `OBJECT*` parameter (world-position source for 3D SFX) is passed directly to `PlaySound()` — `MiniAudioBackend::PlaySound()` already handles the 3D position set-before-start pattern (from Story 5.2.1 HIGH-1 fix).
- [x] **AC-3:** `StopBuffer(ESound, BOOL)` free function delegates to `g_platformAudio->StopSound(buffer, resetPosition)` when `g_platformAudio != nullptr`.
- [x] **AC-4:** `AllStopSound()` free function delegates to `g_platformAudio->AllStopSound()` when `g_platformAudio != nullptr`.
- [x] **AC-5:** `SetMasterVolume(long)` free function delegates to `g_platformAudio->SetMasterVolume(vol)` when `g_platformAudio != nullptr`. `SetEffectVolumeLevel()` in `SceneCommon.cpp` calls `SetMasterVolume()` — this delegation chain requires no change at the `SetEffectVolumeLevel` call site.
- [x] **AC-6:** `SetVolume(int buffer, long vol)` free function delegates to `g_platformAudio->SetVolume(static_cast<ESound>(buffer), vol)` when `g_platformAudio != nullptr`. Existing callers cast `int buffer` to `ESound` already — the cast in the delegation is safe for values in `[0, MAX_BUFFER)`.
- [x] **AC-7:** `InitDirectSound(g_hWnd)` call in `Winmain.cpp` (line ~1312) is removed from the `if (m_SoundOnOff)` block; `FreeDirectSound()` call in `DestroySound()` (line ~446) is removed. The `g_platformAudio` backend (already initialized in Story 5.2.1) handles all audio. The `SetEnableSound(bool)` call and `ReleaseBuffer(i)` loop in `DestroySound()` can also be removed — or left as no-ops if the legacy path is kept for safety (see Dev Notes).
- [x] **AC-8:** `MiniAudioBackend` gains per-slot `OBJECT*` tracking: add `std::array<const OBJECT*, MAX_BUFFER> m_soundObjects{}` (nullptr-initialized) to `MiniAudioBackend.h`. `PlaySound(ESound, OBJECT*, BOOL)` stores `pObject` in `m_soundObjects[bufIdx]` after the 3D position set (existing before-start position logic from 5.2.1 already correct; the per-slot pointer enables per-frame update). `Set3DSoundPosition()` is upgraded from the loop-structure stub (5.2.1) to call `ma_sound_set_position()` for active 3D-enabled slots using the stored `m_soundObjects[bufIdx]->Position`.
- [x] **AC-9:** SFX plays on macOS, Linux, and Windows — `MiniAudioBackend::LoadSound()` uses `ma_sound_init_from_file` with `MA_SOUND_FLAG_DECODE` (pre-decode, already implemented in 5.1.1); no `#ifdef _WIN32` in `MiniAudioBackend.cpp`. Path normalization: `LoadSound()` receives `wchar_t*` filenames; `mu_wchar_to_utf8()` converts them (already implemented in 5.1.1 `LoadSound`). Backslash-to-forward-slash normalization in the UTF-8 result is needed for Linux/macOS — apply `std::replace` after conversion (same pattern as `PlayMusic()` from 5.2.1).
- [x] **AC-10:** `DirectSoundManager` singleton in `DSplaysound.cpp` is made dormant (never initialized): `InitDirectSound` is no longer called, so `Manager().Initialize()` is never called, so all legacy DS paths are inactive. The legacy code is retained as-is in `DSplaysound.cpp` (not deleted) — removal is EPIC-5 final cleanup. Verify by code inspection: no `Manager().Initialize()` call path remains active.

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards Compliance — `mu::` namespace for all new/modified code in `Platform/`, `m_` member prefix, `#pragma once`, no raw `new`/`delete`, no `NULL` (use `nullptr`), no `wprintf`; `g_ErrorReport.Write()` for all failure paths; no `#ifdef _WIN32` in `MiniAudioBackend.cpp`
- [x] **AC-STD-2:** Catch2 test in `tests/audio/test_miniaudio_sfx.cpp`: SFX load (non-existent file graceful), PlaySound before Initialize does not crash, StopSound on unloaded slot is safe, AllStopSound on empty backend is safe, Set3DSoundPosition with nullptr object does not crash; all tests headless (no audio device required)
- [x] **AC-STD-4:** CI quality gate passes (`./ctl check` — clang-format check + cppcheck 0 errors)
- [x] **AC-STD-5:** Error logging: `AUDIO: MiniAudioBackend::LoadSound -- ma_sound_init_from_file failed for '%ls' channel %d (%d)` already implemented from 5.1.1; verify the pattern is emitted correctly after path normalization
- [x] **AC-STD-6:** Conventional commit: `feat(audio): implement SFX playback via miniaudio`

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [x] **AC-STD-13:** Quality Gate passes (`./ctl check`)
- [x] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [x] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/audio/` directory pattern, explicit `target_sources` in `tests/CMakeLists.txt`)

---

## Validation Artifacts

- [x] **AC-VAL-1:** SFX plays on game events (UI click, combat hit) — code path verified by inspection: `PlayBuffer(SOUND_CLICK01)` → `g_platformAudio->PlaySound()` → `ma_sound_start()`. Full runtime validation deferred to QA — skip_checks: [build, test] per .pcc-config.yaml
- [x] **AC-VAL-2:** `Set3DSoundPosition()` per-frame update exercises the stored `m_soundObjects` pointers — code verified by inspection (loop body calls `ma_sound_set_position` for active 3D slots with non-null `m_soundObjects[buf]`)
- [x] **AC-VAL-3:** `./ctl check` passes with 0 errors after changes
- [x] **AC-VAL-4:** `git diff --name-only` shows only expected files (no unintended regressions to non-audio systems)

---

## Tasks / Subtasks

- [x] Task 1: Add per-slot `OBJECT*` tracking to `MiniAudioBackend` (AC: 8)
  - [x] Subtask 1.1: In `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h`, add to the private section:
    ```cpp
    // Per-slot OBJECT* for per-frame 3D position updates (Story 5.2.2)
    // Stores the most recent pObject passed to PlaySound() for each 3D-enabled buffer slot.
    // nullptr means no object is attached to this slot (safe to check before deref).
    std::array<const OBJECT*, MAX_BUFFER> m_soundObjects{};
    ```
    Note: `OBJECT` is forward-declared via `DSPlaySound.h` include chain. `const OBJECT*` is safe since we only read `Position` fields.
  - [x] Subtask 1.2: In `MiniAudioBackend.cpp`, in `PlaySound()`, after the `ma_sound_set_position()` call (lines ~224–227), add:
    ```cpp
    // Store the object pointer for per-frame updates in Set3DSoundPosition().
    // Only update per-slot tracking if this is a 3D-enabled sound with an object.
    if (m_sound3DEnabled[bufIdx])
    {
        m_soundObjects[bufIdx] = pObject; // may be nullptr — checked in Set3DSoundPosition
    }
    ```
  - [x] Subtask 1.3: In `MiniAudioBackend.cpp`, in `Shutdown()`, reset the object tracking array: after clearing `m_soundLoaded[buf]` in the loop, add `m_soundObjects[buf] = nullptr;` (or use `m_soundObjects.fill(nullptr)` after the loop). This prevents dangling pointers if the backend is restarted.

- [x] Task 2: Upgrade `Set3DSoundPosition()` stub to full implementation (AC: 8)
  - [x] Subtask 2.1: In `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp`, replace the inner body of the `Set3DSoundPosition()` loop (currently an empty comment-only block, lines ~327–332) with:
    ```cpp
    // Update 3D position for this slot from the stored OBJECT*.
    // m_soundObjects[buf] is set in PlaySound() for 3D-enabled buffers.
    // It may be nullptr if PlaySound was called with pObject=nullptr.
    if (m_soundObjects[buf] == nullptr)
    {
        continue;
    }
    ma_sound_set_position(&m_sounds[buf][ch],
                          m_soundObjects[buf]->Position[0],
                          m_soundObjects[buf]->Position[1],
                          m_soundObjects[buf]->Position[2]);
    ```
    The `OBJECT::Position` field is `vec3_t` (float[3]): [0]=X, [1]=Y, [2]=Z — matches `ma_sound_set_position(ma_sound*, float x, float y, float z)` exactly.
  - [x] Subtask 2.2: Update the comment block above `Set3DSoundPosition()` to remove the "Story 5.2.2: Add per-slot OBJECT* storage" placeholder and document the full implementation.

- [x] Task 3: Redirect SFX free functions in `DSplaysound.cpp` to `g_platformAudio` (AC: 1, 2, 3, 4, 5, 6, 10)
  - [x] Subtask 3.1: In `MuMain/src/source/Audio/DSplaysound.cpp`, add at the top (after existing includes, before the free function definitions at lines ~736+):
    ```cpp
    #include "IPlatformAudio.h"
    ```
    This gives access to `g_platformAudio` and the `mu::IPlatformAudio` interface.
  - [x] Subtask 3.2: Replace the body of `LoadWaveFile(ESound bufferId, const wchar_t* filename, int maxChannel, bool enable3D)` (line ~736–739) with:
    ```cpp
    void LoadWaveFile(ESound bufferId, const wchar_t* filename, int maxChannel, bool enable3D)
    {
        if (g_platformAudio != nullptr)
        {
            g_platformAudio->LoadSound(bufferId, filename, maxChannel, enable3D);
            return;
        }
        // Fallback: legacy DirectSound path (dormant — InitDirectSound no longer called)
        Manager().LoadWaveFile(bufferId, filename, maxChannel, enable3D);
    }
    ```
    Note: The fallback to `Manager()` is dead code since `InitDirectSound` is no longer called (AC-10), but retaining it avoids a crash if somehow called before `g_platformAudio` init.
  - [x] Subtask 3.3: Replace the body of `PlayBuffer(ESound bufferId, OBJECT* object, BOOL looped)` (line ~751–754) with:
    ```cpp
    HRESULT PlayBuffer(ESound bufferId, OBJECT* object, BOOL looped)
    {
        if (g_platformAudio != nullptr)
        {
            return g_platformAudio->PlaySound(bufferId, object, looped);
        }
        return Manager().PlayBuffer(bufferId, object, looped != FALSE);
    }
    ```
  - [x] Subtask 3.4: Replace the body of `StopBuffer(ESound bufferId, BOOL resetPosition)` (line ~756–759) with:
    ```cpp
    VOID StopBuffer(ESound bufferId, BOOL resetPosition)
    {
        if (g_platformAudio != nullptr)
        {
            g_platformAudio->StopSound(bufferId, resetPosition);
            return;
        }
        Manager().StopBuffer(bufferId, resetPosition != FALSE);
    }
    ```
  - [x] Subtask 3.5: Replace the body of `AllStopSound()` (line ~761–768) with:
    ```cpp
    void AllStopSound()
    {
        if (g_platformAudio != nullptr)
        {
            g_platformAudio->AllStopSound();
            return;
        }
        Manager().StopAll();
    }
    ```
  - [x] Subtask 3.6: Replace the body of `SetMasterVolume(long volume)` (line ~771–774) with:
    ```cpp
    void SetMasterVolume(long volume)
    {
        if (g_platformAudio != nullptr)
        {
            g_platformAudio->SetMasterVolume(volume);
            return;
        }
        Manager().SetMasterVolume(volume);
    }
    ```
  - [x] Subtask 3.7: Replace the body of `SetVolume(int buffer, long vol)` (search for `void SetVolume` in DSplaysound.cpp) with:
    ```cpp
    void SetVolume(int buffer, long vol)
    {
        if (g_platformAudio != nullptr)
        {
            g_platformAudio->SetVolume(static_cast<ESound>(buffer), vol);
            return;
        }
        Manager().SetVolumeInternal(static_cast<ESound>(buffer), vol); // or Manager().SetVolume(...)
    }
    ```
    Note: Check the exact private method name in `DirectSoundManager` — it may be `SetVolume(ESound, long)`. Search for the public `SetVolume` wrapper in the Manager and use it.
  - [x] Subtask 3.8: Replace the body of `Set3DSoundPosition()` (line ~776–779) with:
    ```cpp
    void Set3DSoundPosition()
    {
        if (g_platformAudio != nullptr)
        {
            g_platformAudio->Set3DSoundPosition();
            return;
        }
        Manager().Update3DPositions();
    }
    ```

- [x] Task 4: Remove `InitDirectSound` / `FreeDirectSound` from `Winmain.cpp` (AC: 7)
  - [x] Subtask 4.1: In `MuMain/src/source/Main/Winmain.cpp`, find the `if (m_SoundOnOff)` block (lines ~1310–1321). Remove the `InitDirectSound(g_hWnd)` call. The volume level setup (`g_pOption->SetVolumeLevel(value)` + `SetEffectVolumeLevel()`) can remain — it calls `SetMasterVolume()` which now routes to `g_platformAudio`. The resulting block after edit:
    ```cpp
    if (m_SoundOnOff)
    {
        // Load volume level from config.ini
        int value = GameConfig::GetInstance().GetVolumeLevel();
        if (value < 0 || value >= 10)
            value = 5;

        g_pOption->SetVolumeLevel(value);
        SetEffectVolumeLevel(g_pOption->GetVolumeLevel());
    }
    ```
  - [x] Subtask 4.2: In `DestroySound()` (around lines ~443–446), remove the `FreeDirectSound()` call. The `for (int i = 0; i < MAX_BUFFER; i++) ReleaseBuffer(i);` loop calls `ReleaseBuffer()` which calls `Manager().ReleaseBuffer()` on the uninitialized DirectSoundManager — this is a no-op since the Manager was never initialized, but remove it too for cleanliness if easy; otherwise leave it (it will be a safe no-op). Add a story annotation comment:
    ```cpp
    // Story 5.2.2: InitDirectSound / FreeDirectSound removed — g_platformAudio (MiniAudioBackend)
    // handles all audio lifecycle. DirectSoundManager is dormant (never initialized).
    ```
  - [x] Subtask 4.3: Verify that `#include "DSPlaySound.h"` remains in `Winmain.cpp` — the file still declares the `PlayBuffer`, `LoadWaveFile` etc. free functions used by the codebase. Do NOT remove the include. The `#include <dsound.h>` in `DSplaysound.cpp` is untouched — it's inside the cpp, not in the header.

- [x] Task 5: Path normalization in `MiniAudioBackend::LoadSound()` (AC: 9)
  - [x] Subtask 5.1: In `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp`, in `LoadSound()`, after `std::string utf8Path = mu_wchar_to_utf8(filename);` (line ~131), add backslash normalization:
    ```cpp
    // Normalize path separators for Linux/macOS — sound file paths use Windows backslashes
    // (e.g., L"Data\\Sound\\nBlackSmith.wav"). mu_wchar_to_utf8 preserves them.
    std::replace(utf8Path.begin(), utf8Path.end(), '\\', '/');
    ```
    This mirrors the `PlayMusic()` pattern from Story 5.2.1. On Windows, forward slashes work the same as backslashes for file paths.
  - [x] Subtask 5.2: Verify the normalization is applied before the `ma_sound_init_from_file()` call in the channel loop (line ~139). The `utf8Path.c_str()` argument to `ma_sound_init_from_file()` will already be normalized.

- [x] Task 6: Catch2 SFX lifecycle tests (AC: AC-STD-2)
  - [x] Subtask 6.1: Create `MuMain/tests/audio/test_miniaudio_sfx.cpp`
  - [x] Subtask 6.2: In `MuMain/tests/CMakeLists.txt`, add:
    ```cmake
    # Story 5.2.2: miniaudio SFX Implementation [VS1-AUDIO-MINIAUDIO-SFX]
    target_sources(MuTests PRIVATE audio/test_miniaudio_sfx.cpp)
    ```
  - [x] Subtask 6.3: Write `TEST_CASE("MiniAudioBackend SFX — LoadSound non-existent file does not crash")`: construct `mu::MiniAudioBackend`, do NOT call `Initialize()`, call `LoadSound(SOUND_CLICK01, L"nonexistent.wav", 1, false)` — must not crash (early-return guard on `!m_initialized`). Assert `g_platformAudio == nullptr` (not the test instance).
  - [x] Subtask 6.4: Write `TEST_CASE("MiniAudioBackend SFX — PlaySound before Initialize returns S_FALSE")`: construct, do NOT initialize, call `PlaySound(SOUND_CLICK01, nullptr, FALSE)` — must return `S_FALSE` without crashing (existing guard from 5.2.1).
  - [x] Subtask 6.5: Write `TEST_CASE("MiniAudioBackend SFX — StopSound on unloaded slot is safe")`: construct, optionally initialize (REQUIRE_NOTHROW), call `StopSound(SOUND_CLICK01, FALSE)` — must not crash (guard: `!m_soundLoaded[bufIdx]`).
  - [x] Subtask 6.6: Write `TEST_CASE("MiniAudioBackend SFX — AllStopSound on empty backend is safe")`: construct, call `Initialize()` (may return false on CI), call `AllStopSound()` — must not crash.
  - [x] Subtask 6.7: Write `TEST_CASE("MiniAudioBackend SFX — Set3DSoundPosition with no loaded sounds is safe")`: construct, call `Initialize()` (may fail), call `Set3DSoundPosition()` — must not crash (all slots have `m_soundLoaded[buf] == false`, loop skips them).
  - [x] Subtask 6.8: Write `TEST_CASE("MiniAudioBackend SFX — Set3DSoundPosition skips nullptr m_soundObjects")`: construct, simulate a 3D-enabled loaded slot by calling `LoadSound()` with a non-existent file (will fail gracefully, `m_soundLoaded[buf]` remains false) — confirm no crash. Alternatively: test the guard logic directly by verifying the method does not dereference nullptr when `m_soundObjects[buf] == nullptr`.
  - [x] Subtask 6.9: All tests must NOT call any Win32 or DirectSound API — pure interface and safety checks only. `REQUIRE_NOTHROW` wraps calls that may log errors; `Initialize()` may fail on CI (no audio device) — use `CHECK` not `REQUIRE`.

- [x] Task 7: Quality gate + commit (AC: AC-STD-4, AC-STD-6)
  - [x] Subtask 7.1: Run `./ctl check` — 0 errors. File count will increase by 1 (test file). The `DSplaysound.cpp` edits are within the checked files — verify no new cppcheck warnings.
  - [x] Subtask 7.2: Commit: `feat(audio): implement SFX playback via miniaudio`

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A — C++ client, no HTTP error codes | — | — | — |

Logging patterns (not error catalog entries):
- `g_ErrorReport.Write(L"AUDIO: MiniAudioBackend::LoadSound -- ma_sound_init_from_file failed for '%ls' channel %d (%d)\r\n", filename, ch, result)` — already in `MiniAudioBackend.cpp` from 5.1.1; triggered when SFX files are loaded

---

## Contract Catalog Entries

### API Contracts

Not applicable — no network endpoints introduced.

### Event Contracts

Not applicable — no events introduced.

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 3.7.1 | SFX lifecycle safety (no audio device needed) | LoadSound non-existent graceful, PlaySound before init, StopSound on unloaded, AllStopSound empty, Set3DSoundPosition with nullptr objects |
| Integration (manual) | Windows build | SFX plays on game events | UI click sounds; combat hit sounds; 3D ambient sounds track object position |

---

## Dev Notes

### Context: Why This Story Exists

Story 5.2.1 removed the `wzAudio` BGM dependency and wired `g_platformAudio` into the game startup. However, the **DirectSound SFX system (`DSplaysound.cpp`)** was left intact — `InitDirectSound(g_hWnd)` is still called, and all `LoadWaveFile`/`PlayBuffer`/`StopBuffer` calls still route to the `DirectSoundManager` singleton.

This story completes the audio migration by:
1. **Redirecting all SFX free functions** in `DSplaysound.cpp` to delegate to `g_platformAudio` (with `!= nullptr` guard)
2. **Removing `InitDirectSound`/`FreeDirectSound`** from `Winmain.cpp` — the `MiniAudioBackend` (already initialized) handles everything
3. **Upgrading `Set3DSoundPosition()`** in `MiniAudioBackend` from the 5.2.1 loop-structure stub to a full per-frame position update using stored `OBJECT*` pointers

The design goal is **zero call-site changes** outside `DSplaysound.cpp` and `Winmain.cpp`. The 127+ files that call `PlayBuffer()`, `LoadWaveFile()`, `StopBuffer()`, etc. do NOT need modification — they call the free functions declared in `DSPlaySound.h`, which now delegate to `g_platformAudio`.

### Existing SFX Free Functions (Read-Only Reference — to be Redirected)

**`DSplaysound.cpp` free functions (lines ~717–779):**
- `InitDirectSound(HWND)` → `Manager().Initialize()` — REMOVE call from Winmain.cpp
- `FreeDirectSound()` → `Manager().Shutdown()` — REMOVE call from Winmain.cpp
- `LoadWaveFile(ESound, wchar_t*, int, bool)` → `Manager().LoadWaveFile()` — REDIRECT to `g_platformAudio->LoadSound()`
- `PlayBuffer(ESound, OBJECT*, BOOL)` → `Manager().PlayBuffer()` — REDIRECT to `g_platformAudio->PlaySound()`
- `StopBuffer(ESound, BOOL)` → `Manager().StopBuffer()` — REDIRECT to `g_platformAudio->StopSound()`
- `AllStopSound()` → `Manager().StopAll()` — REDIRECT to `g_platformAudio->AllStopSound()`
- `Set3DSoundPosition()` → `Manager().Update3DPositions()` — REDIRECT to `g_platformAudio->Set3DSoundPosition()`
- `SetMasterVolume(long)` → `Manager().SetMasterVolume()` — REDIRECT to `g_platformAudio->SetMasterVolume()`
- `SetVolume(int buffer, long vol)` → `Manager().SetVolumeInternal()` — REDIRECT to `g_platformAudio->SetVolume()`

**`Winmain.cpp` calls to remove:**
- `InitDirectSound(g_hWnd)` at line ~1312 (inside `if (m_SoundOnOff)` block)
- `FreeDirectSound()` at line ~446 (in `DestroySound()`)
- `for (int i = 0; i < MAX_BUFFER; i++) ReleaseBuffer(i);` at lines ~443–444 — `ReleaseBuffer()` calls `Manager().ReleaseBuffer()` which is safe to remove since Manager is uninitialized

### `SetEffectVolumeLevel` → `SetMasterVolume` Chain

`SetEffectVolumeLevel(int level)` in `SceneCommon.cpp` converts a 0–9 slider level to a dB value and calls `SetMasterVolume(long vol)`. This chain does **not** need to change — `SetMasterVolume()` will delegate to `g_platformAudio->SetMasterVolume()` after this story. The volume formula in `SetEffectVolumeLevel()` (`-2000 * log10(10.f / float(level))`) produces values in the DirectSound dB*100 scale. `MiniAudioBackend::SetMasterVolume()` already converts via `DbToLinear()` (`std::pow(10.0f, vol / 2000.0f)`). The math is correct end-to-end.

### Per-Slot `OBJECT*` Storage for 3D Sound Position Updates

The 3D position update flow:
1. Game calls `PlayBuffer(SOUND_AMBIENT_FIRE, pFlameObject, FALSE)` from `ZzzEffect.cpp`
2. `PlayBuffer` → `g_platformAudio->PlaySound(SOUND_AMBIENT_FIRE, pFlameObject, FALSE)`
3. `MiniAudioBackend::PlaySound()`: sets position from `pObject->Position` BEFORE `ma_sound_start()` (HIGH-1 fix from 5.2.1 — correct), then stores `m_soundObjects[bufIdx] = pObject`
4. Every frame: game calls `Set3DSoundPosition()` → `g_platformAudio->Set3DSoundPosition()`
5. `MiniAudioBackend::Set3DSoundPosition()`: for each active 3D slot, reads `m_soundObjects[buf]->Position` and calls `ma_sound_set_position()`

**CRITICAL:** `m_soundObjects[buf]` is a raw `const OBJECT*` — it can dangle if the object is deleted while the sound is still "playing". This matches the existing `DirectSoundManager::attachedObjects` pattern in `DSplaysound.cpp` (line ~55: `std::array<OBJECT*, MAX_CHANNEL> attachedObjects{}`), which has the same lifetime concern. The game engine design ensures objects outlive the sounds attached to them during normal play. Do NOT add lifetime management here — it would require an engine-wide refactor. Add a comment acknowledging the assumption.

### Sound File Path Normalization

**Existing call patterns** (from `ZzzOpenData.cpp`):
```cpp
LoadWaveFile(SOUND_NPC_BLACK_SMITH, L"Data\\Sound\\nBlackSmith.wav", 1);
LoadWaveFile(SOUND_CLICK01, L"Data\\Sound\\click01.wav");
LoadWaveFile(SOUND_XMAS_SNOWMAN_WALK_1, L"Data\\Sound\\xmas\\SnowMan_Walk01.wav");
```

These use Windows-style backslash paths (`wchar_t*`). `MiniAudioBackend::LoadSound()` already converts `wchar_t*` to UTF-8 via `mu_wchar_to_utf8()` (from 5.1.1). Add `std::replace(utf8Path.begin(), utf8Path.end(), '\\', '/')` after the conversion (Task 5 of this story) to handle Linux/macOS. On Windows, forward slashes work identically.

**Audio file formats supported by miniaudio:** WAV (native), MP3 (native), OGG/Vorbis (via stb_vorbis — vendored in 5.1.1). All MU Online SFX are WAV files → no format concern.

### `DirectSoundManager` Dormancy

After this story, `InitDirectSound` is no longer called → `Manager().Initialize()` is never invoked → `DirectSoundManager::m_initialized` remains `false` → all legacy DS code paths are dead. The `DirectSoundManager` singleton object still exists in memory (static in anonymous namespace in `DSplaysound.cpp`) but is inert.

The legacy `DSplaysound.cpp` code is **NOT deleted** in this story — that is deferred to a future cleanup story (post-EPIC-5). Keeping it in place:
1. Preserves the fallback path in the free functions (safety net)
2. Avoids large-scale file deletion that could introduce regressions
3. Maintains a reference implementation for any future debugging needs

### Project Structure Notes

**Files to modify:**

| File | Change |
|------|--------|
| `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` | Add `m_soundObjects` array member |
| `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` | `PlaySound()`: store `m_soundObjects[bufIdx]`; `Set3DSoundPosition()`: upgrade stub; `LoadSound()`: add path normalization; `Shutdown()`: clear `m_soundObjects` |
| `MuMain/src/source/Audio/DSplaysound.cpp` | Add `#include "IPlatformAudio.h"`; redirect 8 free functions to `g_platformAudio` |
| `MuMain/src/source/Main/Winmain.cpp` | Remove `InitDirectSound(g_hWnd)` and `FreeDirectSound()` calls |
| `MuMain/tests/CMakeLists.txt` | Add `audio/test_miniaudio_sfx.cpp` to `MuTests` |

**New files to create:**

| File | CMake Target | Notes |
|------|-------------|-------|
| `MuMain/tests/audio/test_miniaudio_sfx.cpp` | `MuTests` (explicit add) | Catch2 SFX lifecycle tests |

**Include guard for `IPlatformAudio.h` in `DSplaysound.cpp`:** The `#include "IPlatformAudio.h"` in `DSplaysound.cpp` will pull in `DSPlaySound.h` (already included), `miniaudio.h` (via `MiniAudioBackend.h` include chain — not directly). Wait — `IPlatformAudio.h` does NOT include `MiniAudioBackend.h`. Check the actual `IPlatformAudio.h` include chain: it includes `DSPlaySound.h` for `ESound` and `OBJECT`. Since `DSplaysound.cpp` already includes `DSPlaySound.h`, this is a duplicate include — harmless with `#pragma once`. The `miniaudio.h` include is only in `MiniAudioBackend.h`, not `IPlatformAudio.h`. So adding `#include "IPlatformAudio.h"` to `DSplaysound.cpp` is clean.

**cppcheck note:** The added `#include "IPlatformAudio.h"` in `DSplaysound.cpp` may trigger cppcheck warnings if the include introduces new symbols not used locally. If so, add an inline suppression or verify cppcheck only runs on changed lines.

### Technical Implementation

#### `MiniAudioBackend.h` — New Private Member

```cpp
// Per-slot OBJECT* for per-frame 3D position updates (Story 5.2.2).
// Stores the most recent pObject from PlaySound() for each 3D-enabled buffer.
// Lifetime: game engine guarantees object outlives the sound (same as DirectSound pattern).
// nullptr = no object attached (safe — Set3DSoundPosition checks before deref).
std::array<const OBJECT*, MAX_BUFFER> m_soundObjects{};
```

#### `MiniAudioBackend::Set3DSoundPosition()` — Full Implementation

```cpp
void MiniAudioBackend::Set3DSoundPosition()
{
    if (!m_initialized)
    {
        return;
    }

    for (int buf = 0; buf < static_cast<int>(MAX_BUFFER); ++buf)
    {
        if (!m_soundLoaded[buf] || !m_sound3DEnabled[buf] || m_soundObjects[buf] == nullptr)
        {
            continue;
        }

        for (int ch = 0; ch < MAX_CHANNEL; ++ch)
        {
            if (!ma_sound_is_playing(&m_sounds[buf][ch]))
            {
                continue;
            }

            // OBJECT::Position is vec3_t (float[3]): [0]=X, [1]=Y, [2]=Z
            ma_sound_set_position(&m_sounds[buf][ch],
                                  m_soundObjects[buf]->Position[0],
                                  m_soundObjects[buf]->Position[1],
                                  m_soundObjects[buf]->Position[2]);
        }
    }
}
```

#### `LoadWaveFile` Delegation Pattern

```cpp
void LoadWaveFile(ESound bufferId, const wchar_t* filename, int maxChannel, bool enable3D)
{
    if (g_platformAudio != nullptr)
    {
        g_platformAudio->LoadSound(bufferId, filename, maxChannel, enable3D);
        return;
    }
    // Fallback: legacy DirectSound (dormant — InitDirectSound not called after 5.2.2)
    Manager().LoadWaveFile(bufferId, filename, maxChannel, enable3D);
}
```

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, Catch2 3.7.1, miniaudio 0.11.x (vendored single-header), `MUAudio` CMake target

**Prohibited (per project-context.md):**
- `NULL` — use `nullptr`
- `wprintf`, `__TraceF()`, `DebugAngel` — use `g_ErrorReport.Write()`
- `#ifndef` header guards — use `#pragma once`
- `#ifdef _WIN32` in `MiniAudioBackend.cpp` — miniaudio abstracts the platform
- New Win32 audio APIs — this story replaces DirectSound; do NOT introduce new DS calls

**Required patterns (per project-context.md):**
- `g_ErrorReport.Write()` for all failure paths
- `mu::` namespace for all new code in `Platform/`
- Allman brace style, 4-space indent, 120-column limit
- `#pragma once` header guards
- `nullptr` guards before `g_platformAudio` dereference
- Conventional Commit: `feat(audio): implement SFX playback via miniaudio`

**Quality gate:** `./ctl check` — must pass 0 errors. File count increases by 1 (test file). `DSplaysound.cpp` is large and may have pre-existing cppcheck suppressions — verify the new delegation lines pass.

**skip_checks:** `[build, test]` per `.pcc-config.yaml` — macOS cannot compile Win32/DirectX. Build and runtime audio verification is CI-only (MinGW on Linux) and manual QA.

### References

- [Source: `_bmad-output/stories/5-1-1-muaudio-abstraction-layer/story.md` — interface contract, MiniAudioBackend structure, CMake patterns]
- [Source: `_bmad-output/stories/5-2-1-miniaudio-bgm/story.md` — BGM delegation patterns, HIGH-1 fix (position before start), path normalization, g_platformAudio lifecycle]
- [Source: `_bmad-output/project-context.md` — C++ Language Rules, CMake Module Targets, Testing Rules]
- [Source: `docs/development-standards.md` — §1 Banned Win32 API table (Audio row), §1 Platform Abstraction Interfaces]
- [Source: `MuMain/src/source/Audio/DSplaysound.cpp` lines ~717–779 — free function definitions to redirect]
- [Source: `MuMain/src/source/Audio/DSPlaySound.h` — ESound enum, MAX_BUFFER, MAX_CHANNEL, free function declarations]
- [Source: `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` — current class definition (add m_soundObjects)]
- [Source: `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` lines 184–232 (PlaySound), 300–334 (Set3DSoundPosition stub), 101–165 (LoadSound) — methods to modify]
- [Source: `MuMain/src/source/Main/Winmain.cpp` lines ~1310–1321 (InitDirectSound block), ~443–454 (DestroySound) — lines to edit]
- [Source: `MuMain/src/source/Scenes/SceneCommon.cpp` lines ~220–236 — SetEffectVolumeLevel → SetMasterVolume chain]
- [Source: `MuMain/tests/CMakeLists.txt` — test registration pattern, MUAudio link]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

(none — implementation was already complete from prior session; this session verified, checked ATDD, ran quality gate, and updated all artifacts)

### Completion Notes List

- All 7 tasks fully implemented prior to this session (verified by reading source files)
- Task 1 (m_soundObjects tracking): `MiniAudioBackend.h` already has `std::array<const OBJECT*, MAX_BUFFER> m_soundObjects{}` private member; `PlaySound()` stores pointer; `Shutdown()` clears array
- Task 2 (Set3DSoundPosition upgrade): Full loop implementation with `ma_sound_set_position()` + nullptr guard already in `MiniAudioBackend.cpp`
- Task 3 (DSplaysound.cpp redirections): All 8 free functions (`LoadWaveFile`, `PlayBuffer`, `StopBuffer`, `AllStopSound`, `SetMasterVolume`, `SetVolume`, `Set3DSoundPosition`) delegate to `g_platformAudio` when non-null; `#include "IPlatformAudio.h"` added
- Task 4 (Winmain.cpp cleanup): `InitDirectSound(g_hWnd)` and `FreeDirectSound()` calls removed; story annotation comments present; `#include "DSPlaySound.h"` retained
- Task 5 (path normalization): `std::replace(utf8Path.begin(), utf8Path.end(), '\\\\', '/')` added in `LoadSound()` after `mu_wchar_to_utf8()`, before `ma_sound_init_from_file()`
- Task 6 (Catch2 tests): `MuMain/tests/audio/test_miniaudio_sfx.cpp` exists with 7 TEST_CASEs; registered in `tests/CMakeLists.txt`
- Task 7 (quality gate): `./ctl check` passed with 0 errors on 711 files
- ATDD checklist: Implementation Checklist 39/39 checked [x]; AC-to-test mapping 15/15 checked [x]
- Code inspection ACs satisfied: no `Manager().Initialize()` call path active (AC-10); no `#ifdef _WIN32` in `MiniAudioBackend.cpp` (AC-9); `git diff --name-only` shows only 6 expected files (AC-VAL-4)

### File List

**Modified:**
- `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` — added `m_soundObjects` array member (Task 1.1)
- `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` — `PlaySound()` stores object pointer (Task 1.2); `Shutdown()` clears array (Task 1.3); `Set3DSoundPosition()` full implementation (Task 2.1/2.2); `LoadSound()` path normalization (Task 5.1/5.2)
- `MuMain/src/source/Audio/DSplaysound.cpp` — added `#include "IPlatformAudio.h"`; redirected 8 SFX free functions to `g_platformAudio` (Task 3.1–3.8)
- `MuMain/src/source/Main/Winmain.cpp` — removed `InitDirectSound(g_hWnd)` and `FreeDirectSound()` calls; added story annotation comments (Task 4.1–4.3)
- `MuMain/tests/CMakeLists.txt` — added `target_sources(MuTests PRIVATE audio/test_miniaudio_sfx.cpp)` (Task 6.2)

**Created:**
- `MuMain/tests/audio/test_miniaudio_sfx.cpp` — 7 Catch2 TEST_CASEs for SFX lifecycle safety (Task 6.1–6.9)

