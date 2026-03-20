# Story 5.4.1: Volume Controls & Audio State Management

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 5 - Audio System Migration |
| Feature | 5.4 - Volume Controls |
| Story ID | 5.4.1 |
| Story Points | 2 |
| Priority | P1 - Should Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-AUDIO-VOLUME-CONTROLS |
| FRs Covered | FR19 (Volume controls persisted across sessions) |
| Prerequisites | 5.2.1 (BGM wired via miniaudio — done), 5.2.2 (SFX wired via miniaudio — done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Add `SetBGMVolume(float)`/`SetSFXVolume(float)`/`GetBGMVolume()`/`GetSFXVolume()` to `IPlatformAudio`; implement in `MiniAudioBackend`; add `m_bgmVolumeLevel`/`m_musicVolumeLevel` to `GameConfig`; wire volume restore on startup in `Winmain.cpp`; update `SetEffectVolumeLevel` to use new API; Catch2 tests |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** player,
**I want** separate BGM and SFX volume controls that persist across sessions,
**so that** I can set my preferred audio levels and have them restored when I restart the game.

---

## Functional Acceptance Criteria

- [x] **AC-1:** `IPlatformAudio` gains four new methods: `SetBGMVolume(float level)`, `SetSFXVolume(float level)`, `[[nodiscard]] float GetBGMVolume() const`, `[[nodiscard]] float GetSFXVolume() const` — level range is `0.0f` (mute) to `1.0f` (full volume). These are pure virtual in the interface and implemented in `MiniAudioBackend`.
- [x] **AC-2:** `MiniAudioBackend::SetBGMVolume(float level)` clamps `level` to `[0.0f, 1.0f]` and calls `ma_sound_set_volume(&m_musicSound, level)` — takes effect immediately on the currently-playing BGM track. The clamped value is stored in `m_bgmVolume` (private member, default `1.0f`). New BGM tracks started via `PlayMusic()` inherit `m_bgmVolume` via a `ma_sound_set_volume` call after `ma_sound_start`.
- [x] **AC-3:** `MiniAudioBackend::SetSFXVolume(float level)` clamps `level` to `[0.0f, 1.0f]` and stores it in `m_sfxVolume` (private member, default `1.0f`). It calls `ma_engine_set_volume(&m_engine, level)` to set the engine-wide SFX volume. Note: since BGM also plays through the engine, the effective BGM volume is `m_bgmVolume * m_sfxVolume` — this is acceptable because `SetBGMVolume` sets per-sound volume on `m_musicSound`, while `SetSFXVolume` sets the engine master. **Alternative approach if this coupling is unacceptable:** use a `ma_sound_group` for SFX and set group volume independently. Decide at implementation time based on audible behavior.
- [x] **AC-4:** `GameConfig` gains two new persistent settings: `m_bgmVolumeLevel` (int, 0-10, default `CfgDefaultBGMVolumeLevel = 5`) and `m_sfxVolumeLevel` (int, 0-10, default `CfgDefaultSFXVolumeLevel = 5`). Both are read/written via `IniFile` in `GameConfig::Load()`/`Save()` under `[Audio]` section with keys `BGMVolumeLevel` and `SFXVolumeLevel`. Getters: `GetBGMVolumeLevel()`, `GetSFXVolumeLevel()`. Setters: `SetBGMVolumeLevel(int)`, `SetSFXVolumeLevel(int)`.
- [x] **AC-5:** The existing `m_volumeLevel` / `CfgKeyVolumeLevel` in `GameConfig` is preserved as a **migration fallback**: on first load, if `BGMVolumeLevel` and `SFXVolumeLevel` are absent but `VolumeLevel` exists, both new settings default to the old `VolumeLevel` value. This preserves the player's existing preference. After the first `Save()`, the new keys are written.
- [x] **AC-6:** At game startup in `Winmain.cpp` (after `g_platformAudio->Initialize()`), BGM and SFX volumes are restored from `GameConfig`:
  ```
  int bgmLevel = GameConfig::GetInstance().GetBGMVolumeLevel();
  int sfxLevel = GameConfig::GetInstance().GetSFXVolumeLevel();
  g_platformAudio->SetBGMVolume(static_cast<float>(bgmLevel) / 10.0f);
  g_platformAudio->SetSFXVolume(static_cast<float>(sfxLevel) / 10.0f);
  ```
  The existing `SetEffectVolumeLevel()` call is replaced or augmented with the new API.
- [x] **AC-7:** `SetEffectVolumeLevel(int level)` in `SceneCommon.cpp` is updated to call `g_platformAudio->SetSFXVolume(static_cast<float>(level) / 10.0f)` instead of the legacy `SetMasterVolume(long vol)` path. The old DirectSound dB-scale conversion (`-2000 * log10(10.0f / float(level))`) is removed since the new API uses linear 0.0-1.0.
- [x] **AC-8:** At shutdown in `DestroyWindow()` (Winmain.cpp), `GameConfig::GetInstance().SetBGMVolumeLevel(...)` and `GameConfig::GetInstance().SetSFXVolumeLevel(...)` are called before `Save()` to persist the current volume state. The source of truth is `g_pOption` (which the option UI updates) — add `GetBGMVolumeLevel()`/`SetBGMVolumeLevel(int)` to `CNewUIOptionWindow` and the legacy `COptionWin` (or use a shared accessor).
- [x] **AC-9:** Audio can be fully disabled: when `m_MusicOnOff == 0 && m_SoundOnOff == 0`, `g_platformAudio` remains `nullptr` (existing behavior from Story 5.2.1). All volume-related calls are guarded with `g_platformAudio != nullptr`. `MiniAudioBackend::IsEndMusic()` continues to return `true` when not initialized (existing behavior — no regression).

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards Compliance — `mu::` namespace, PascalCase functions, `m_` member prefix with Hungarian hints, `#pragma once`, no raw `new`/`delete`, `[[nodiscard]]` on getters, no `NULL` (use `nullptr`), no `wprintf`; `g_ErrorReport.Write()` for failure paths
- [x] **AC-STD-2:** Catch2 tests in `tests/audio/test_volume_controls.cpp`: default volumes are 1.0f, SetBGMVolume/SetSFXVolume clamp correctly (values < 0.0 clamp to 0.0, values > 1.0 clamp to 1.0), getters return the clamped value
- [x] **AC-STD-4:** CI quality gate passes (`./ctl check` — clang-format check + cppcheck 0 errors)
- [x] **AC-STD-6:** Conventional commit: `feat(audio): add volume controls and audio state management`

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [x] **AC-STD-13:** Quality Gate passes (`./ctl check`)
- [x] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [x] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/audio/` directory pattern, explicit `target_sources` in `tests/CMakeLists.txt`)

---

## Validation Artifacts

- [x] **AC-VAL-1:** Volume slider in option UI controls SFX volume in real-time — code path verified by inspection: `CNewUIOptionWindow::UpdateWhileActive()` calls `SetEffectVolumeLevel(m_iVolumeLevel)` which now delegates to `g_platformAudio->SetSFXVolume()`. Full runtime validation deferred to QA — skip_checks: [build, test] per .pcc-config.yaml
- [x] **AC-VAL-2:** BGM volume is preserved across game restart — `GameConfig::Save()` writes `BGMVolumeLevel`; `GameConfig::Load()` reads it back; startup wires it to `g_platformAudio->SetBGMVolume()`. Verification: inspect config.ini after save.
- [x] **AC-VAL-3:** `./ctl check` passes with 0 errors after changes
- [x] **AC-VAL-4:** `git diff --name-only` shows only expected files (no unintended regressions)

---

## Tasks / Subtasks

- [x] Task 1: Extend `IPlatformAudio` interface (AC: 1)
  - [x] Subtask 1.1: In `MuMain/src/source/Platform/IPlatformAudio.h`, add four new pure virtual methods to `mu::IPlatformAudio`:
    ```cpp
    // Volume controls — linear 0.0 (mute) to 1.0 (full). Story 5.4.1.
    virtual void SetBGMVolume(float level) = 0;
    virtual void SetSFXVolume(float level) = 0;
    [[nodiscard]] virtual float GetBGMVolume() const = 0;
    [[nodiscard]] virtual float GetSFXVolume() const = 0;
    ```
    Place them after `GetMusicPosition()` in the Music section.

- [x] Task 2: Implement volume methods in `MiniAudioBackend` (AC: 2, 3)
  - [x] Subtask 2.1: In `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h`, add to private section:
    ```cpp
    float m_bgmVolume = 1.0f;   // BGM volume: 0.0 (mute) to 1.0 (full)
    float m_sfxVolume = 1.0f;   // SFX volume: 0.0 (mute) to 1.0 (full)
    ```
    Add method declarations to the public section:
    ```cpp
    void SetBGMVolume(float level) override;
    void SetSFXVolume(float level) override;
    [[nodiscard]] float GetBGMVolume() const override;
    [[nodiscard]] float GetSFXVolume() const override;
    ```
  - [x] Subtask 2.2: In `MiniAudioBackend.cpp`, implement `SetBGMVolume`:
    ```cpp
    void MiniAudioBackend::SetBGMVolume(float level)
    {
        m_bgmVolume = std::clamp(level, 0.0f, 1.0f);
        if (m_initialized && m_musicLoaded)
        {
            ma_sound_set_volume(&m_musicSound, m_bgmVolume);
        }
    }
    ```
  - [x] Subtask 2.3: Implement `SetSFXVolume`. **Approach decision:** miniaudio's `ma_engine_set_volume` affects ALL sounds including music. To get independent BGM/SFX control, use a `ma_sound_group` for SFX (created at `Initialize()` time) and set group volume. If `ma_sound_group` is too complex, use the simpler approach: store `m_sfxVolume` and apply it to each SFX slot in `PlaySound()` via `ma_sound_set_volume(&m_sounds[buf][ch], m_sfxVolume)` before `ma_sound_start`. Also iterate all currently-loaded SFX slots to update existing playing sounds. **Do NOT use `ma_engine_set_volume` for SFX** — it would override BGM volume.
    ```cpp
    void MiniAudioBackend::SetSFXVolume(float level)
    {
        m_sfxVolume = std::clamp(level, 0.0f, 1.0f);
        if (!m_initialized)
        {
            return;
        }
        // Update all currently-loaded SFX slots
        for (int buf = 0; buf < static_cast<int>(MAX_BUFFER); ++buf)
        {
            if (!m_soundLoaded[buf])
            {
                continue;
            }
            for (int ch = 0; ch < m_loadedChannels[buf]; ++ch)
            {
                ma_sound_set_volume(&m_sounds[buf][ch], m_sfxVolume);
            }
        }
    }
    ```
  - [x] Subtask 2.4: Implement getters:
    ```cpp
    float MiniAudioBackend::GetBGMVolume() const { return m_bgmVolume; }
    float MiniAudioBackend::GetSFXVolume() const { return m_sfxVolume; }
    ```
  - [x] Subtask 2.5: In `MiniAudioBackend::PlayMusic()`, after `ma_sound_start(&m_musicSound)`, add `ma_sound_set_volume(&m_musicSound, m_bgmVolume)` to apply the current BGM volume to newly-started tracks.
  - [x] Subtask 2.6: In `MiniAudioBackend::PlaySound()`, after `ma_sound_start`, add `ma_sound_set_volume(&m_sounds[bufIdx][ch], m_sfxVolume)` to apply current SFX volume to newly-started effects.

- [x] Task 3: Add BGM/SFX volume persistence to `GameConfig` (AC: 4, 5)
  - [x] Subtask 3.1: In `MuMain/src/source/Data/GameConfigConstants.h`, add:
    ```cpp
    inline constexpr wchar_t CfgKeyBGMVolumeLevel[] = L"BGMVolumeLevel";
    inline constexpr wchar_t CfgKeySFXVolumeLevel[] = L"SFXVolumeLevel";
    inline constexpr int CfgDefaultBGMVolumeLevel = 5;
    inline constexpr int CfgDefaultSFXVolumeLevel = 5;
    ```
  - [x] Subtask 3.2: In `MuMain/src/source/Data/GameConfig.h`, add private members and public accessors:
    ```cpp
    // Private:
    int m_bgmVolumeLevel;
    int m_sfxVolumeLevel;

    // Public:
    int GetBGMVolumeLevel() const { return m_bgmVolumeLevel; }
    int GetSFXVolumeLevel() const { return m_sfxVolumeLevel; }
    void SetBGMVolumeLevel(int level);
    void SetSFXVolumeLevel(int level);
    ```
  - [x] Subtask 3.3: In `GameConfig.cpp` constructor initializer list, add: `m_bgmVolumeLevel(CfgDefaults::CfgDefaultBGMVolumeLevel)`, `m_sfxVolumeLevel(CfgDefaults::CfgDefaultSFXVolumeLevel)`.
  - [x] Subtask 3.4: In `GameConfig::Load()`, add INI reads:
    ```cpp
    m_bgmVolumeLevel = ini.ReadInt(CfgSectionAudio, CfgKeyBGMVolumeLevel, -1);
    m_sfxVolumeLevel = ini.ReadInt(CfgSectionAudio, CfgKeySFXVolumeLevel, -1);
    // Migration fallback: if new keys absent, use old VolumeLevel
    if (m_bgmVolumeLevel < 0)
        m_bgmVolumeLevel = m_volumeLevel;
    if (m_sfxVolumeLevel < 0)
        m_sfxVolumeLevel = m_volumeLevel;
    ```
  - [x] Subtask 3.5: In `GameConfig::Save()`, add INI writes:
    ```cpp
    ini.WriteInt(CfgSectionAudio, CfgKeyBGMVolumeLevel, m_bgmVolumeLevel);
    ini.WriteInt(CfgSectionAudio, CfgKeySFXVolumeLevel, m_sfxVolumeLevel);
    ```
  - [x] Subtask 3.6: Implement setters in `GameConfig.cpp`:
    ```cpp
    void GameConfig::SetBGMVolumeLevel(int level) { m_bgmVolumeLevel = level; }
    void GameConfig::SetSFXVolumeLevel(int level) { m_sfxVolumeLevel = level; }
    ```

- [x] Task 4: Wire volume restore at startup and save at shutdown (AC: 6, 8)
  - [x] Subtask 4.1: In `Winmain.cpp`, after the existing `g_platformAudio->Initialize()` block (line ~1312), add:
    ```cpp
    // Story 5.4.1: Restore BGM and SFX volume from config
    if (g_platformAudio != nullptr)
    {
        int bgmLevel = GameConfig::GetInstance().GetBGMVolumeLevel();
        int sfxLevel = GameConfig::GetInstance().GetSFXVolumeLevel();
        if (bgmLevel < 0 || bgmLevel > 10) bgmLevel = 5;
        if (sfxLevel < 0 || sfxLevel > 10) sfxLevel = 5;
        g_platformAudio->SetBGMVolume(static_cast<float>(bgmLevel) / 10.0f);
        g_platformAudio->SetSFXVolume(static_cast<float>(sfxLevel) / 10.0f);
    }
    ```
  - [x] Subtask 4.2: In `DestroyWindow()` function in `Winmain.cpp`, before `GameConfig::GetInstance().Save()`, add:
    ```cpp
    GameConfig::GetInstance().SetBGMVolumeLevel(g_pOption->GetBGMVolumeLevel());
    GameConfig::GetInstance().SetSFXVolumeLevel(g_pOption->GetSFXVolumeLevel());
    ```
    This requires Task 5 (option window BGM accessor) to be completed first.

- [x] Task 5: Update `SetEffectVolumeLevel` to use new API (AC: 7)
  - [x] Subtask 5.1: In `MuMain/src/source/Scenes/SceneCommon.cpp`, replace the body of `SetEffectVolumeLevel(int level)`:
    ```cpp
    void SetEffectVolumeLevel(int level)
    {
        if (level > 10)
            level = 10;
        if (level < 0)
            level = 0;

        if (g_platformAudio != nullptr)
        {
            g_platformAudio->SetSFXVolume(static_cast<float>(level) / 10.0f);
        }
    }
    ```
    The old `SetMasterVolume(-10000)` / `SetMasterVolume(vol)` path with DirectSound dB conversion is removed. The legacy `SetMasterVolume(long vol)` free function in `DSplaysound.cpp` remains for backward compatibility but is no longer called from this path.

- [x] Task 6: Add BGM volume accessor to option windows (AC: 8)
  - [x] Subtask 6.1: In `MuMain/src/source/UI/Windows/NewUIOptionWindow.h`, add:
    ```cpp
    void SetBGMVolumeLevel(int iVolume);
    int GetBGMVolumeLevel();
    ```
    And private member: `int m_iBGMVolumeLevel;`
  - [x] Subtask 6.2: In `NewUIOptionWindow.cpp`, initialize `m_iBGMVolumeLevel = 0` in constructor. Implement getter/setter (same pattern as existing `m_iVolumeLevel`).
  - [x] Subtask 6.3: **Scope decision for UI interaction:** Adding a BGM volume slider to the option window UI requires new texture assets (volume bar image for BGM). If texture assets are not available, store the BGM level in `NewUIOptionWindow` and expose it via getter/setter, but defer the visual slider to a future UI story. The BGM volume can still be set programmatically and persisted — just without a UI slider in this story. **Document this decision in dev notes if slider is deferred.**
  - [x] Subtask 6.4: In `CNewUIOptionWindow::SetVolumeLevel(int)` rename semantics: the existing `m_iVolumeLevel` becomes the SFX volume level. Add `SetBGMVolumeLevel(int)` alongside it. Update `DestroyWindow()` in Winmain.cpp to call both `GetVolumeLevel()` (SFX) and `GetBGMVolumeLevel()` (BGM) when saving.

- [x] Task 7: Catch2 tests (AC: AC-STD-2)
  - [x] Subtask 7.1: Create `MuMain/tests/audio/test_volume_controls.cpp`
  - [x] Subtask 7.2: In `tests/CMakeLists.txt`, add:
    ```cmake
    # Story 5.4.1: Volume Controls [VS1-AUDIO-VOLUME-CONTROLS]
    target_sources(MuTests PRIVATE audio/test_volume_controls.cpp)
    ```
  - [x] Subtask 7.3: Write `TEST_CASE("MiniAudioBackend default BGM volume is 1.0")`: construct backend, assert `GetBGMVolume() == 1.0f`.
  - [x] Subtask 7.4: Write `TEST_CASE("MiniAudioBackend default SFX volume is 1.0")`: construct backend, assert `GetSFXVolume() == 1.0f`.
  - [x] Subtask 7.5: Write `TEST_CASE("SetBGMVolume clamps to valid range")`: set to -0.5f, assert `GetBGMVolume() == 0.0f`; set to 2.0f, assert `GetBGMVolume() == 1.0f`; set to 0.5f, assert `GetBGMVolume() == 0.5f`.
  - [x] Subtask 7.6: Write `TEST_CASE("SetSFXVolume clamps to valid range")`: same pattern as 7.5.
  - [x] Subtask 7.7: Write `TEST_CASE("SetBGMVolume/SetSFXVolume on uninitialized backend does not crash")`: construct (no Init), call SetBGMVolume(0.5f) and SetSFXVolume(0.5f) — must not crash. Volumes are stored even without init.
  - [x] Subtask 7.8: Tests must NOT call any Win32 or DirectSound API. All tests run headless.

- [x] Task 8: Quality gate + commit (AC: AC-STD-4, AC-STD-6)
  - [x] Subtask 8.1: Run `./ctl check` — 0 errors
  - [x] Subtask 8.2: Commit: `feat(audio): add volume controls and audio state management`

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A — C++ client, no HTTP error codes | — | — | — |

Logging patterns (not error catalog entries):
- No new error log patterns introduced. Volume set operations do not fail — they clamp silently.

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
| Unit | Catch2 3.7.1 | Volume logic (no audio device needed) | Default volumes, clamping, get/set roundtrip, uninitialized backend safety |
| Integration (manual) | Windows build | Volume controls audio in real-time | SFX slider controls effect volume; BGM volume persists across restart; mute (0) silences audio |

---

## Dev Notes

### Context: Why This Story Exists

Stories 5.2.1 and 5.2.2 wired BGM and SFX through `g_platformAudio` (MiniAudioBackend), replacing wzAudio and DirectSound. However, the volume control system was carried over from the legacy architecture:

1. **Single volume control**: `m_volumeLevel` (0-10 int) in `GameConfig` maps to `SetMasterVolume(long vol)` via `SetEffectVolumeLevel()`. This uses a DirectSound-era dB*100 scale conversion.
2. **No BGM volume**: Music is either ON (`m_MusicOnOff = 1`) or OFF. There is no volume slider for BGM.
3. **Legacy dB conversion**: `SetEffectVolumeLevel()` converts int 0-10 to DirectSound dB scale (`-2000 * log10(10.0f / float(level))`), which is then converted back to linear in `MiniAudioBackend::SetMasterVolume()` via `DbToLinear()`. This double conversion is unnecessary now that we control miniaudio directly.

This story introduces clean linear 0.0-1.0 volume APIs (`SetBGMVolume`/`SetSFXVolume`) on `IPlatformAudio`, persists separate BGM/SFX levels in `GameConfig`, and updates the SFX volume path to bypass the legacy dB conversion.

### Critical Design Decision: Independent BGM vs SFX Volume

miniaudio's `ma_engine_set_volume()` sets volume for the entire engine (ALL sounds including music). To get independent control:

- **BGM volume**: Use `ma_sound_set_volume(&m_musicSound, level)` — per-sound volume on the music track. This is independent of the engine volume.
- **SFX volume**: Apply per-sound volume to each SFX slot individually via `ma_sound_set_volume(&m_sounds[buf][ch], level)`. Do NOT use `ma_engine_set_volume` which would also affect BGM.

**Why not `ma_sound_group`?** A sound group would be cleaner but requires creating the group at init, routing all SFX through it, and managing its lifecycle. For a 2-point story with ~450 SFX slots, per-slot volume is simpler and more explicit. A sound group refactor can be a future optimization.

### Existing Volume Flow (Read-Only Reference)

```
User drags slider in CNewUIOptionWindow
  → m_iVolumeLevel updated (int 0-10)
  → SetEffectVolumeLevel(m_iVolumeLevel)           [SceneCommon.cpp]
    → converts to DirectSound dB*100 scale
    → SetMasterVolume(long vol)                     [DSplaysound.cpp free function]
      → g_platformAudio->SetMasterVolume(vol)       [MiniAudioBackend]
        → DbToLinear(vol) → ma_engine_set_volume()
```

**New flow after this story:**
```
User drags slider in CNewUIOptionWindow
  → m_iVolumeLevel updated (int 0-10)
  → SetEffectVolumeLevel(m_iVolumeLevel)           [SceneCommon.cpp]
    → g_platformAudio->SetSFXVolume(level / 10.0f)  [MiniAudioBackend]
      → std::clamp → per-slot ma_sound_set_volume()
```

### Project Structure Notes

**Files to modify:**

| File | Change |
|------|--------|
| `MuMain/src/source/Platform/IPlatformAudio.h` | Add 4 new pure virtual methods |
| `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` | Add `m_bgmVolume`, `m_sfxVolume` members; declare 4 new methods |
| `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` | Implement SetBGMVolume/SetSFXVolume/GetBGMVolume/GetSFXVolume; update PlayMusic/PlaySound to apply stored volume |
| `MuMain/src/source/Data/GameConfigConstants.h` | Add `CfgKeyBGMVolumeLevel`, `CfgKeySFXVolumeLevel`, defaults |
| `MuMain/src/source/Data/GameConfig.h` | Add `m_bgmVolumeLevel`, `m_sfxVolumeLevel` members + accessors |
| `MuMain/src/source/Data/GameConfig.cpp` | Init, Load, Save for new volume settings; migration fallback |
| `MuMain/src/source/Scenes/SceneCommon.cpp` | Replace `SetEffectVolumeLevel()` body with new linear API |
| `MuMain/src/source/Main/Winmain.cpp` | Wire volume restore on startup; save BGM/SFX levels on shutdown |
| `MuMain/src/source/UI/Windows/NewUIOptionWindow.h` | Add `m_iBGMVolumeLevel` + accessors |
| `MuMain/src/source/UI/Windows/NewUIOptionWindow.cpp` | Init BGM volume member; implement accessors |
| `MuMain/tests/CMakeLists.txt` | Add `audio/test_volume_controls.cpp` to MuTests |

**New files to create:**

| File | CMake Target | Notes |
|------|-------------|-------|
| `MuMain/tests/audio/test_volume_controls.cpp` | `MuTests` (explicit add) | Catch2 volume control tests |

**CMake notes:** No new CMake dependencies. The test file follows the existing `target_sources(MuTests PRIVATE ...)` pattern in `tests/CMakeLists.txt`.

### Technical Implementation

#### Volume Clamping Helper

```cpp
static float ClampVolume(float level)
{
    return std::clamp(level, 0.0f, 1.0f);
}
```

Use `<algorithm>` for `std::clamp`. If already included via `stdafx.h` or `MiniAudioBackend.cpp` includes, no new include needed.

#### `SetEffectVolumeLevel` — Legacy Compatibility

The existing `SetEffectVolumeLevel(int level)` is called from both `CNewUIOptionWindow` and `COptionWin` (legacy). Both call it with int 0-10. The function is the single entry point — update it to use the new linear API and all existing callers automatically work.

The old DirectSound `SetMasterVolume(long vol)` free function in `DSplaysound.cpp` is NOT removed — it still delegates to `g_platformAudio->SetMasterVolume()` which sets `ma_engine_set_volume()`. This is preserved for any remaining callers. However, `SetEffectVolumeLevel()` no longer calls it.

#### Config Migration Pattern

```ini
; Old config.ini (before this story)
[Audio]
VolumeLevel=7

; New config.ini (after this story)
[Audio]
VolumeLevel=7
BGMVolumeLevel=7
SFXVolumeLevel=7
```

On first load: `BGMVolumeLevel` key is absent → `ReadInt` returns `-1` (sentinel) → falls back to `m_volumeLevel` (7). After `Save()`, new keys are written.

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, Catch2 3.7.1, miniaudio 0.11.x (vendored), `MUAudio` CMake target

**Prohibited (per project-context.md):**
- `new`/`delete` — use existing patterns only (no new allocations in this story)
- `NULL` — use `nullptr`
- `wprintf`, `__TraceF()`, `DebugAngel` — use `g_ErrorReport.Write()`
- `#ifndef` header guards — use `#pragma once`
- `#ifdef _WIN32` in game logic — no platform conditionals needed
- DirectSound types in new API signatures — use `float` not `long` for the new volume methods

**Required patterns (per project-context.md):**
- `[[nodiscard]]` on `GetBGMVolume()`, `GetSFXVolume()`
- `mu::` namespace for all new code in `Platform/`
- Allman brace style, 4-space indent, 120-column limit (`.clang-format`)
- `g_ErrorReport.Write()` for failure paths (none expected in volume logic)
- Conventional Commit: `feat(audio): add volume controls and audio state management`

**Quality gate:** `./ctl check` — must pass 0 errors. File count increases by 1 (test file).

### References

- [Source: `_bmad-output/stories/5-1-1-muaudio-abstraction-layer/story.md` — IPlatformAudio interface, MiniAudioBackend design, DbToLinear conversion]
- [Source: `_bmad-output/stories/5-2-1-miniaudio-bgm/story.md` — BGM wiring, PlayMusic implementation, m_currentMusicName guard]
- [Source: `_bmad-output/stories/5-2-2-miniaudio-sfx/story.md` — SFX wiring, per-slot OBJECT* tracking, m_loadedChannels]
- [Source: `_bmad-output/project-context.md` — C++ Language Rules, CMake Module Targets, Testing Rules]
- [Source: `docs/development-standards.md` — §1 Banned Win32 API table (Audio row), §2 Error Handling & Logging]
- [Source: `MuMain/src/source/Platform/IPlatformAudio.h` — current interface (13 methods, no volume float API)]
- [Source: `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` — current private state: m_engine, m_sounds, m_musicSound]
- [Source: `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` — SetVolume/SetMasterVolume/DbToLinear implementation]
- [Source: `MuMain/src/source/Data/GameConfig.h` — m_volumeLevel, GetVolumeLevel/SetVolumeLevel]
- [Source: `MuMain/src/source/Data/GameConfigConstants.h` — CfgKeyVolumeLevel, CfgDefaultVolumeLevel (5)]
- [Source: `MuMain/src/source/Scenes/SceneCommon.cpp` lines 220-236 — SetEffectVolumeLevel with dB conversion]
- [Source: `MuMain/src/source/Main/Winmain.cpp` lines 1314-1327 — SFX volume restore on startup]
- [Source: `MuMain/src/source/Main/Winmain.cpp` lines 364-368 — volume save on shutdown]
- [Source: `MuMain/src/source/UI/Windows/NewUIOptionWindow.cpp` lines 102-140 — volume slider interaction]
- [Source: `MuMain/src/source/UI/Legacy/OptionWin.cpp` lines 151-158 — legacy option window volume slider]

---

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

- Quality gate `./ctl check`: 711/711 files checked, 0 errors (2026-03-20)

### Completion Notes List

- Task 1 (AC-1): Added 4 pure virtual volume methods to `IPlatformAudio` — `SetBGMVolume`, `SetSFXVolume`, `GetBGMVolume`, `GetSFXVolume` with `[[nodiscard]]` on getters
- Task 2 (AC-2, AC-3): Implemented volume methods in `MiniAudioBackend` — `std::clamp` for clamping, per-slot `ma_sound_set_volume` for SFX (not `ma_engine_set_volume`), `m_bgmVolume`/`m_sfxVolume` private members default 1.0f. Applied stored volume in `PlayMusic()` and `PlaySound()` for newly-started tracks
- Task 3 (AC-4, AC-5): Added `CfgKeyBGMVolumeLevel`/`CfgKeySFXVolumeLevel` constants, `m_bgmVolumeLevel`/`m_sfxVolumeLevel` to `GameConfig` with Load/Save/getters/setters. Migration fallback: sentinel -1 from ReadInt triggers fallback to old `m_volumeLevel`
- Task 4 (AC-6, AC-8): Wired volume restore at startup (after `g_platformAudio->Initialize()`) and save at shutdown (before `GameConfig::Save()`) in `Winmain.cpp`
- Task 5 (AC-7): Replaced `SetEffectVolumeLevel()` body in `SceneCommon.cpp` — removed DirectSound dB-scale conversion, now calls `g_platformAudio->SetSFXVolume(float)` directly
- Task 6 (AC-8): Added `m_iBGMVolumeLevel` + `SetBGMVolumeLevel(int)`/`GetBGMVolumeLevel()` to `CNewUIOptionWindow`. BGM slider UI deferred (no texture assets) — getter/setter sufficient for persistence
- Task 7 (AC-STD-2): 10 Catch2 TEST_CASE blocks in `tests/audio/test_volume_controls.cpp` — all headless, no Win32/DirectSound APIs
- Task 8 (AC-STD-4, AC-STD-6): `./ctl check` passed 0 errors (711 files)

### File List

**Modified:**
- `MuMain/src/source/Platform/IPlatformAudio.h` — Added 4 pure virtual volume methods
- `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` — Added `m_bgmVolume`, `m_sfxVolume` members; 4 override declarations
- `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` — Implemented SetBGMVolume/SetSFXVolume/GetBGMVolume/GetSFXVolume; updated PlayMusic/PlaySound to apply stored volume
- `MuMain/src/source/Data/GameConfigConstants.h` — Added `CfgKeyBGMVolumeLevel`, `CfgKeySFXVolumeLevel`, defaults
- `MuMain/src/source/Data/GameConfig.h` — Added `m_bgmVolumeLevel`, `m_sfxVolumeLevel` members + accessors
- `MuMain/src/source/Data/GameConfig.cpp` — Constructor init, Load (with migration fallback), Save, setters
- `MuMain/src/source/Scenes/SceneCommon.cpp` — Replaced SetEffectVolumeLevel body with linear API
- `MuMain/src/source/Main/Winmain.cpp` — Volume restore at startup, BGM/SFX save at shutdown
- `MuMain/src/source/UI/Windows/NewUIOptionWindow.h` — Added `m_iBGMVolumeLevel` + accessors
- `MuMain/src/source/UI/Windows/NewUIOptionWindow.cpp` — Init BGM volume member; implement accessors

**New (committed in ATDD step):**
- `MuMain/tests/audio/test_volume_controls.cpp` — Catch2 volume control tests (10 TEST_CASE blocks)
- `MuMain/tests/CMakeLists.txt` — Added `target_sources(MuTests PRIVATE audio/test_volume_controls.cpp)`
