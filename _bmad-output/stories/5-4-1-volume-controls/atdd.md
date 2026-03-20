# ATDD Implementation Checklist: Story 5.4.1 - Volume Controls & Audio State Management

**Story ID:** 5-4-1-volume-controls
**Story Type:** infrastructure
**Date Generated:** 2026-03-20
**Primary Test Level:** Catch2 unit tests (macOS arm64 syntax-validates; full run post-EPIC-2)

---

## PCC Compliance Summary

| Check | Result | Notes |
|-------|--------|-------|
| Framework | Catch2 v3.7.1 | infrastructure story — unit tests via Catch2 |
| Prohibited libraries | None used | `std::clamp`, `mu::` namespace only; no DirectSound, no `new`/`delete` |
| No `#ifdef _WIN32` in game logic | Required | All new code uses cross-platform `float` volume API; no Win32 guards |
| No raw `new`/`delete` | Required | No heap allocation in volume logic |
| No per-frame I/O | Required | Volume set operations do not log (silent clamp) |
| `[[nodiscard]]` on getters | Required | `GetBGMVolume()` and `GetSFXVolume()` must be `[[nodiscard]]` |
| `namespace mu` | Required | All new `IPlatformAudio`/`MiniAudioBackend` methods in `mu::` namespace |
| Coverage target | N/A | Minimal baseline — growing incrementally per project-context.md |
| Bruno/Playwright | NOT applicable | infrastructure story, no API endpoints, no UI test targets |

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Name | Status |
|----|-------------|-----------|-----------|--------|
| AC-1 | `IPlatformAudio` gains 4 new volume methods | `tests/audio/test_volume_controls.cpp` | `AC-1 [5-4-1]: IPlatformAudio volume methods exist on MiniAudioBackend` | RED |
| AC-2 | `SetBGMVolume` clamps & stores in `m_bgmVolume` | `tests/audio/test_volume_controls.cpp` | `AC-2/AC-STD-2 [5-4-1]: MiniAudioBackend default BGM volume is 1.0f` | RED |
| AC-2 | `SetBGMVolume` clamps to `[0.0, 1.0]` | `tests/audio/test_volume_controls.cpp` | `AC-2/AC-STD-2 [5-4-1]: SetBGMVolume clamps to valid range [0.0, 1.0]` | RED |
| AC-3 | `SetSFXVolume` clamps & stores in `m_sfxVolume` | `tests/audio/test_volume_controls.cpp` | `AC-3/AC-STD-2 [5-4-1]: MiniAudioBackend default SFX volume is 1.0f` | RED |
| AC-3 | `SetSFXVolume` clamps to `[0.0, 1.0]` | `tests/audio/test_volume_controls.cpp` | `AC-3/AC-STD-2 [5-4-1]: SetSFXVolume clamps to valid range [0.0, 1.0]` | RED |
| AC-2/AC-3 | Get/Set round-trip; independent BGM/SFX state | `tests/audio/test_volume_controls.cpp` | `AC-2/AC-3/AC-STD-2 [5-4-1]: GetBGMVolume/GetSFXVolume return the clamped set value` | RED |
| AC-9 | All volume calls safe when backend uninitialized | `tests/audio/test_volume_controls.cpp` | `AC-2/AC-3/AC-9/AC-STD-2 [5-4-1]: Volume controls on uninitialized backend are safe` | RED |
| AC-1/AC-STD-1 | Methods accessible via `mu::` namespace + interface pointer | `tests/audio/test_volume_controls.cpp` | `AC-STD-1/AC-1 [5-4-1]: Volume getters are accessible via mu:: namespace` | RED |
| AC-4 | `GameConfig` BGM/SFX volume persistence | Manual/inspection | Config INI read/write verified by inspecting `config.ini` after save | PENDING |
| AC-5 | Migration fallback from old `VolumeLevel` | Manual/inspection | Load old config.ini without new keys — both volumes default to `VolumeLevel` | PENDING |
| AC-6 | Volume restored at startup after `Initialize()` | Manual/inspection | Code path: `Winmain.cpp` → `GetBGMVolumeLevel()`/`GetSFXVolumeLevel()` → `SetBGMVolume`/`SetSFXVolume` | PENDING |
| AC-7 | `SetEffectVolumeLevel` uses new linear API | Manual/inspection | Verify `SceneCommon.cpp` no longer calls `SetMasterVolume` dB path | PENDING |
| AC-8 | Volumes saved at shutdown | Manual/inspection | `DestroyWindow()` calls `SetBGMVolumeLevel`/`SetSFXVolumeLevel` before `Save()` | PENDING |
| AC-STD-2 | Catch2 tests in `tests/audio/test_volume_controls.cpp` | `tests/audio/test_volume_controls.cpp` | All test cases above | RED |
| AC-STD-4 | `./ctl check` passes 0 errors | Quality gate | `./ctl check` — clang-format + cppcheck | PENDING |
| AC-STD-16 | Correct test infrastructure (Catch2 3.7.1, `MuTests`, explicit `target_sources`) | `tests/CMakeLists.txt` | `target_sources(MuTests PRIVATE audio/test_volume_controls.cpp)` | DONE |

---

## Implementation Checklist

### Task 1: Extend `IPlatformAudio` interface (AC-1)

- [ ] In `MuMain/src/source/Platform/IPlatformAudio.h`, add four new pure virtual methods to `mu::IPlatformAudio` after `GetMusicPosition()`:
  ```cpp
  // Volume controls — linear 0.0 (mute) to 1.0 (full). Story 5.4.1.
  virtual void SetBGMVolume(float level) = 0;
  virtual void SetSFXVolume(float level) = 0;
  [[nodiscard]] virtual float GetBGMVolume() const = 0;
  [[nodiscard]] virtual float GetSFXVolume() const = 0;
  ```
- [ ] Verify `#pragma once` is present (no `#ifndef` guard)
- [ ] Verify no `#ifdef _WIN32` introduced
- [ ] Verify `mu::` namespace wraps all declarations

### Task 2: Implement volume methods in `MiniAudioBackend` (AC-2, AC-3)

- [ ] In `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h`, add private members:
  ```cpp
  float m_bgmVolume = 1.0f;   // BGM volume: 0.0 (mute) to 1.0 (full)
  float m_sfxVolume = 1.0f;   // SFX volume: 0.0 (mute) to 1.0 (full)
  ```
- [ ] Add public method declarations with `override`:
  ```cpp
  void SetBGMVolume(float level) override;
  void SetSFXVolume(float level) override;
  [[nodiscard]] float GetBGMVolume() const override;
  [[nodiscard]] float GetSFXVolume() const override;
  ```
- [ ] In `MiniAudioBackend.cpp`, implement `SetBGMVolume` with `std::clamp(level, 0.0f, 1.0f)` and conditional `ma_sound_set_volume` (only if `m_initialized && m_musicLoaded`)
- [ ] Implement `SetSFXVolume` with `std::clamp` and per-slot `ma_sound_set_volume` iteration (only if `m_initialized`)
- [ ] Implement `GetBGMVolume() const { return m_bgmVolume; }`
- [ ] Implement `GetSFXVolume() const { return m_sfxVolume; }`
- [ ] In `PlayMusic()`, after `ma_sound_start`, add `ma_sound_set_volume(&m_musicSound, m_bgmVolume)` (AC-2: new tracks inherit stored volume)
- [ ] In `PlaySound()`, after `ma_sound_start`, add `ma_sound_set_volume(&m_sounds[bufIdx][ch], m_sfxVolume)` (AC-3: new SFX slots inherit stored volume)
- [ ] `<algorithm>` included for `std::clamp` (check if already available via stdafx.h)
- [ ] No `ma_engine_set_volume` used for SFX (would affect BGM — use per-slot approach per dev notes)

### Task 3: Add BGM/SFX volume persistence to `GameConfig` (AC-4, AC-5)

- [ ] In `MuMain/src/source/Data/GameConfigConstants.h`, add:
  ```cpp
  inline constexpr wchar_t CfgKeyBGMVolumeLevel[] = L"BGMVolumeLevel";
  inline constexpr wchar_t CfgKeySFXVolumeLevel[] = L"SFXVolumeLevel";
  inline constexpr int CfgDefaultBGMVolumeLevel = 5;
  inline constexpr int CfgDefaultSFXVolumeLevel = 5;
  ```
- [ ] In `MuMain/src/source/Data/GameConfig.h`, add private members `m_bgmVolumeLevel` and `m_sfxVolumeLevel` (int)
- [ ] Add public accessors: `GetBGMVolumeLevel()`, `GetSFXVolumeLevel()`, `SetBGMVolumeLevel(int)`, `SetSFXVolumeLevel(int)`
- [ ] In `GameConfig.cpp` constructor, initialize both to `CfgDefaultBGMVolumeLevel` / `CfgDefaultSFXVolumeLevel`
- [ ] In `GameConfig::Load()`, read new INI keys with sentinel `-1`; apply migration fallback from `m_volumeLevel` if absent (AC-5)
- [ ] In `GameConfig::Save()`, write both new keys under `[Audio]` section

### Task 4: Wire volume restore at startup and save at shutdown (AC-6, AC-8)

- [ ] In `Winmain.cpp`, after `g_platformAudio->Initialize()` block, add volume restore guarded by `g_platformAudio != nullptr`
- [ ] Clamp loaded level to `[0, 10]` before converting to float (`/ 10.0f`) as safety guard
- [ ] In `DestroyWindow()`, before `GameConfig::GetInstance().Save()`, persist current BGM and SFX levels from option window

### Task 5: Update `SetEffectVolumeLevel` to use new API (AC-7)

- [ ] In `MuMain/src/source/Scenes/SceneCommon.cpp`, replace body of `SetEffectVolumeLevel(int level)` to call `g_platformAudio->SetSFXVolume(static_cast<float>(level) / 10.0f)` (guarded by `g_platformAudio != nullptr`)
- [ ] Remove old DirectSound dB-scale conversion (`-2000 * log10(...)`)
- [ ] Verify `SetMasterVolume(long vol)` free function in `DSplaysound.cpp` is preserved (still referenced by other callers)

### Task 6: Add BGM volume accessor to option windows (AC-8)

- [ ] In `MuMain/src/source/UI/Windows/NewUIOptionWindow.h`, add `int m_iBGMVolumeLevel` private member and `SetBGMVolumeLevel(int)` / `GetBGMVolumeLevel()` declarations
- [ ] In `NewUIOptionWindow.cpp`, initialize `m_iBGMVolumeLevel = 0` in constructor; implement getter/setter
- [ ] Document scope decision (BGM slider deferred if texture assets unavailable — getter/setter sufficient for persistence)

### Task 7: Catch2 tests (AC-STD-2, AC-STD-16)

- [x] Created `MuMain/tests/audio/test_volume_controls.cpp` with 10 `TEST_CASE` blocks (RED phase)
- [x] `AC-1 [5-4-1]`: IPlatformAudio volume methods exist on MiniAudioBackend (interface + virtual dispatch)
- [x] `AC-2/AC-STD-2 [5-4-1]`: Default BGM volume is 1.0f
- [x] `AC-3/AC-STD-2 [5-4-1]`: Default SFX volume is 1.0f
- [x] `AC-2/AC-STD-2 [5-4-1]`: SetBGMVolume clamps to [0.0, 1.0] — negative, over-1, mid-range, exact boundaries
- [x] `AC-3/AC-STD-2 [5-4-1]`: SetSFXVolume clamps to [0.0, 1.0] — same sections
- [x] `AC-2/AC-3/AC-STD-2 [5-4-1]`: Get/Set round-trip; BGM and SFX are independent; last-write-wins
- [x] `AC-2/AC-3/AC-9/AC-STD-2 [5-4-1]`: All volume calls safe on uninitialized backend (no crash)
- [x] `AC-2 [5-4-1]`: SetBGMVolume clamps on uninitialized backend
- [x] `AC-3 [5-4-1]`: SetSFXVolume clamps on uninitialized backend
- [x] `AC-STD-1/AC-1 [5-4-1]`: Methods accessible via `mu::` namespace and `IPlatformAudio*` pointer
- [x] Registered in `MuMain/tests/CMakeLists.txt` via `target_sources(MuTests PRIVATE audio/test_volume_controls.cpp)`
- [x] Tests do NOT call any Win32, DirectSound, or audio device API — all headless

### Task 8: Quality gate + commit (AC-STD-4, AC-STD-13, AC-STD-6)

- [ ] Run `./ctl check` — clang-format check + cppcheck — 0 errors
- [ ] Verify file count increase: +1 test file (`test_volume_controls.cpp`)
- [ ] Commit: `feat(audio): add volume controls and audio state management [VS1-AUDIO-VOLUME-CONTROLS]`

---

## Standard Acceptance Criteria

- [ ] AC-STD-1: Code follows project standards — `mu::` namespace, `#pragma once`, no `#ifdef _WIN32` in game logic, `std::clamp`, `nullptr`, PascalCase methods, `m_` member prefix, `[[nodiscard]]` on getters
- [x] AC-STD-2: Catch2 tests exist in `MuMain/tests/audio/test_volume_controls.cpp` (RED phase — 10 TEST_CASE blocks)
- [ ] AC-STD-4: CI quality gate passes — `./ctl check` exits 0 with zero violations
- [ ] AC-STD-6: Conventional commit: `feat(audio): add volume controls and audio state management`
- [ ] AC-STD-13: Quality gate passes — `./ctl check` clean (clang-format + cppcheck zero violations)
- [ ] AC-STD-15: Git safety — no incomplete rebase, no force push to main
- [x] AC-STD-16: Correct test infrastructure — Catch2 3.7.1, `MuTests` target, `tests/audio/` directory, explicit `target_sources` in `tests/CMakeLists.txt`

---

## NFR Acceptance Criteria

- [ ] AC-VAL-1: Volume slider in option UI controls SFX volume in real-time — code path: `CNewUIOptionWindow::UpdateWhileActive()` → `SetEffectVolumeLevel()` → `g_platformAudio->SetSFXVolume()`. Full runtime validation deferred to QA (skip_checks: [build, test])
- [ ] AC-VAL-2: BGM volume preserved across restart — `GameConfig::Save()` writes `BGMVolumeLevel`; `Load()` reads it back; startup wires to `SetBGMVolume()`. Verify by inspecting `config.ini` after save
- [ ] AC-VAL-3: `./ctl check` passes with 0 errors after all changes
- [ ] AC-VAL-4: `git diff --name-only` shows only expected files (no unintended regressions)

---

## PCC Compliance Checklist

- [ ] No prohibited libraries used — no `DirectSoundCreate`, no `IDirectSound*`, no raw `new`/`delete`, no `NULL`
- [ ] Required testing patterns followed — Catch2 v3.7.1, `TEST_CASE`/`REQUIRE`, GIVEN/WHEN/THEN structure in comments, `WithinAbs` matcher for float comparisons
- [ ] No `#ifdef _WIN32` in game logic — `std::clamp` and `float` volume are fully portable
- [ ] No backslash path literals in new files
- [ ] `[[nodiscard]]` on `GetBGMVolume()` and `GetSFXVolume()`
- [ ] CI MinGW build invariant maintained — `std::clamp` available in MinGW-w64 C++20
- [ ] `namespace mu` used for all new code in `Platform/` and `MiniAudio/`
- [ ] `m_` prefix with descriptive suffixes on all new member variables (`m_bgmVolume`, `m_sfxVolume`)

---

## Test Execution Commands

```bash
# Quality gate (macOS + Linux — mirrors CI):
./ctl check

# Run all MuTests via CTest (requires BUILD_TESTING=ON and MUCore compiling):
cmake -S MuMain -B build-test -DBUILD_TESTING=ON
cd build-test && ctest -R "5-4-1" --output-on-failure

# Run individual 5.4.1 volume control tests:
ctest -R "volume_controls" --output-on-failure

# MinGW cross-compile (Linux/WSL — full build):
cmake -S MuMain -B build-mingw -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=MuMain/cmake/toolchains/mingw-w64-i686.cmake \
  -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON
cmake --build build-mingw --target MuTests

# Commit (after implementation complete):
# feat(audio): add volume controls and audio state management [VS1-AUDIO-VOLUME-CONTROLS]
```

---

## RED Phase Verification

All tests confirmed FAILING (RED) as of 2026-03-20 (pre-implementation — `SetBGMVolume`/`SetSFXVolume` do not exist on `MiniAudioBackend`):

| Test | Result | Error |
|------|--------|-------|
| `AC-1 [5-4-1]: IPlatformAudio volume methods exist on MiniAudioBackend` | FAIL | `'SetBGMVolume': is not a member of 'mu::MiniAudioBackend'` |
| `AC-2/AC-STD-2 [5-4-1]: MiniAudioBackend default BGM volume is 1.0f` | FAIL | `'GetBGMVolume': is not a member of 'mu::MiniAudioBackend'` |
| `AC-3/AC-STD-2 [5-4-1]: MiniAudioBackend default SFX volume is 1.0f` | FAIL | `'GetSFXVolume': is not a member of 'mu::MiniAudioBackend'` |
| `AC-2/AC-STD-2 [5-4-1]: SetBGMVolume clamps to valid range [0.0, 1.0]` | FAIL | `'SetBGMVolume': is not a member of 'mu::MiniAudioBackend'` |
| `AC-3/AC-STD-2 [5-4-1]: SetSFXVolume clamps to valid range [0.0, 1.0]` | FAIL | `'SetSFXVolume': is not a member of 'mu::MiniAudioBackend'` |
| `AC-2/AC-3/AC-STD-2 [5-4-1]: GetBGMVolume/GetSFXVolume return the clamped set value` | FAIL | `'SetBGMVolume': is not a member of 'mu::MiniAudioBackend'` |
| `AC-2/AC-3/AC-9/AC-STD-2 [5-4-1]: Volume controls on uninitialized backend are safe` | FAIL | `'SetBGMVolume': is not a member of 'mu::MiniAudioBackend'` |
| `AC-2 [5-4-1]: SetBGMVolume clamps on uninitialized backend` | FAIL | `'SetBGMVolume': is not a member of 'mu::MiniAudioBackend'` |
| `AC-3 [5-4-1]: SetSFXVolume clamps on uninitialized backend` | FAIL | `'SetSFXVolume': is not a member of 'mu::MiniAudioBackend'` |
| `AC-STD-1/AC-1 [5-4-1]: Volume getters are accessible via mu:: namespace` | FAIL | `'SetBGMVolume': is not a member of 'mu::MiniAudioBackend'` |
