# Test Scenarios: Story 5.4.1 — Volume Controls & Audio State Management

**Generated:** 2026-03-20
**Story:** 5.4.1 Volume Controls & Audio State Management
**Flow Code:** VS1-AUDIO-VOLUME-CONTROLS
**Project:** MuMain-workspace

These scenarios cover validation of Story 5.4.1 acceptance criteria.
Automated tests (Catch2 unit tests in `MuMain/tests/audio/test_volume_controls.cpp`) run on macOS/Linux.
Manual validation scenarios require a Windows or MinGW build with audio hardware.

---

## AC-1: IPlatformAudio Volume Methods

### Scenario 1: IPlatformAudio declares four new volume methods (automated)

- **Prerequisites:** `IPlatformAudio.h` compiled into `MUAudio` target
- **Given:** `mu::IPlatformAudio` class definition
- **When:** `SetBGMVolume(float)`, `SetSFXVolume(float)`, `GetBGMVolume() const`, `GetSFXVolume() const` are called via `mu::MiniAudioBackend`
- **Then:** All compile and resolve via virtual dispatch to MiniAudioBackend overrides
- **Automated:** `TEST_CASE("AC-1 [5-4-1]: IPlatformAudio volume methods exist on MiniAudioBackend")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 2: Volume getters have [[nodiscard]] attribute

- **Prerequisites:** `IPlatformAudio.h` header inspection
- **Given:** `GetBGMVolume()` and `GetSFXVolume()` declarations
- **When:** Inspected for `[[nodiscard]]` attribute
- **Then:** Both getters are annotated `[[nodiscard]]`
- **Automated:** Code review inspection
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-2: SetBGMVolume Implementation

### Scenario 3: Default BGM volume is 1.0f (automated)

- **Prerequisites:** Compiled test binary
- **Given:** A freshly constructed `mu::MiniAudioBackend` (not initialized)
- **When:** `GetBGMVolume()` is called before any Set call
- **Then:** Returns `1.0f` (full volume default)
- **Automated:** `TEST_CASE("AC-2/AC-STD-2 [5-4-1]: MiniAudioBackend default BGM volume is 1.0f")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 4: SetBGMVolume clamps to [0.0, 1.0] (automated)

- **Prerequisites:** Compiled test binary
- **Given:** An uninitialized MiniAudioBackend
- **When:** SetBGMVolume called with -0.5f, 2.0f, 0.5f, 0.0f, 1.0f
- **Then:** GetBGMVolume returns 0.0f, 1.0f, 0.5f, 0.0f, 1.0f respectively (clamped)
- **Automated:** `TEST_CASE("AC-2/AC-STD-2 [5-4-1]: SetBGMVolume clamps to valid range [0.0, 1.0]")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 5: New BGM tracks inherit stored volume (manual)

- **Prerequisites:** Windows build with audio hardware, BGM files in data directory
- **Given:** BGM volume set to 0.3f via `g_platformAudio->SetBGMVolume(0.3f)`
- **When:** `PlayMusic()` starts a new BGM track
- **Then:** The new track plays at 30% volume (not full volume)
- **Automated:** N/A (requires audio hardware)
- **Status:** [x] Not Tested / [ ] Passed / [ ] Failed

---

## AC-3: SetSFXVolume Implementation

### Scenario 6: Default SFX volume is 1.0f (automated)

- **Prerequisites:** Compiled test binary
- **Given:** A freshly constructed `mu::MiniAudioBackend` (not initialized)
- **When:** `GetSFXVolume()` is called before any Set call
- **Then:** Returns `1.0f`
- **Automated:** `TEST_CASE("AC-3/AC-STD-2 [5-4-1]: MiniAudioBackend default SFX volume is 1.0f")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 7: SetSFXVolume clamps to [0.0, 1.0] (automated)

- **Prerequisites:** Compiled test binary
- **Given:** An uninitialized MiniAudioBackend
- **When:** SetSFXVolume called with -1.5f, 3.7f, 0.75f, 0.0f, 1.0f
- **Then:** GetSFXVolume returns 0.0f, 1.0f, 0.75f, 0.0f, 1.0f respectively
- **Automated:** `TEST_CASE("AC-3/AC-STD-2 [5-4-1]: SetSFXVolume clamps to valid range [0.0, 1.0]")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 8: BGM and SFX volumes are independent (automated)

- **Prerequisites:** Compiled test binary
- **Given:** BGM set to 0.2f, SFX set to 0.9f
- **When:** Both getters are called
- **Then:** BGM returns 0.2f, SFX returns 0.9f (not cross-contaminated)
- **Automated:** `TEST_CASE("AC-2/AC-3/AC-STD-2 [5-4-1]: GetBGMVolume/GetSFXVolume return the clamped set value")` — SECTION "BGM and SFX volumes are independent" — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-4: GameConfig Volume Persistence

### Scenario 9: BGMVolumeLevel and SFXVolumeLevel saved to config.ini (manual)

- **Prerequisites:** Windows build, game runs to completion
- **Given:** Player sets BGM volume to 3 and SFX volume to 7
- **When:** Game exits normally (DestroyWindow → GameConfig::Save)
- **Then:** `config.ini` contains `[Audio]` section with `BGMVolumeLevel=3` and `SFXVolumeLevel=7`
- **Automated:** N/A (requires full game lifecycle)
- **Status:** [x] Not Tested / [ ] Passed / [ ] Failed

---

## AC-5: Migration Fallback

### Scenario 10: Old VolumeLevel migrates to both new keys (manual)

- **Prerequisites:** Windows build, old config.ini with only `VolumeLevel=7` (no BGM/SFX keys)
- **Given:** Player upgrades from pre-5.4.1 version
- **When:** Game loads config for the first time
- **Then:** Both `m_bgmVolumeLevel` and `m_sfxVolumeLevel` default to 7 (old VolumeLevel value)
- **Automated:** N/A (requires INI file manipulation)
- **Status:** [x] Not Tested / [ ] Passed / [ ] Failed

---

## AC-6: Volume Restore at Startup

### Scenario 11: Volumes restored from GameConfig on startup (manual)

- **Prerequisites:** Windows build, config.ini with `BGMVolumeLevel=3`, `SFXVolumeLevel=8`
- **Given:** Game starts up, audio initializes
- **When:** Winmain.cpp reads config and calls SetBGMVolume/SetSFXVolume
- **Then:** BGM plays at 30% volume, SFX at 80% volume
- **Automated:** N/A (requires audio hardware)
- **Status:** [x] Not Tested / [ ] Passed / [ ] Failed

---

## AC-7: SetEffectVolumeLevel Uses New API

### Scenario 12: Volume slider now uses linear 0.0-1.0 API (code inspection)

- **Prerequisites:** `SceneCommon.cpp` source inspection
- **Given:** `SetEffectVolumeLevel(int level)` function body
- **When:** Inspected for DirectSound dB-scale conversion code
- **Then:** No `SetMasterVolume`, no `-2000 * log10(...)` — only `g_platformAudio->SetSFXVolume(float(level) / 10.0f)`
- **Automated:** Code review inspection
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-8: Volume Save at Shutdown

### Scenario 13: BGM and SFX levels persisted via DestroyWindow (code inspection)

- **Prerequisites:** `Winmain.cpp` source inspection
- **Given:** `DestroyWindow()` function
- **When:** Inspected for `SetBGMVolumeLevel`/`SetSFXVolumeLevel` calls before `Save()`
- **Then:** Both calls present, sourcing from `g_pOption->GetBGMVolumeLevel()` and `g_pOption->GetVolumeLevel()`
- **Automated:** Code review inspection
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-9: Null-Safe Volume Calls

### Scenario 14: Volume controls safe on uninitialized backend (automated)

- **Prerequisites:** Compiled test binary
- **Given:** A default-constructed MiniAudioBackend (never Initialize()d)
- **When:** SetBGMVolume(0.5f), SetSFXVolume(0.5f), GetBGMVolume(), GetSFXVolume() are called
- **Then:** No crash. Values are stored correctly. No miniaudio API calls made.
- **Automated:** `TEST_CASE("AC-2/AC-3/AC-9/AC-STD-2 [5-4-1]: Volume controls on uninitialized backend are safe")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-STD-2: Catch2 Tests

### Scenario 15: All 10 test cases exist and are GREEN (automated)

- **Prerequisites:** Compiled test binary (MuTests target, BUILD_TESTING=ON)
- **Given:** `MuMain/tests/audio/test_volume_controls.cpp` with 10 TEST_CASE blocks
- **When:** Tests are compiled and run via CTest
- **Then:** All 10 test cases pass (GREEN)
- **Automated:** All TEST_CASE blocks in `test_volume_controls.cpp`
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-STD-4: Quality Gate

### Scenario 16: ./ctl check passes with 0 errors

- **Prerequisites:** macOS or Linux with clang-format + cppcheck installed
- **Given:** All story files modified
- **When:** `./ctl check` is executed
- **Then:** 711/711 files checked, 0 errors, exit code 0
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed
