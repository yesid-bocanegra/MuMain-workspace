# Story 5.3.1: Audio Format Validation

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 5 - Audio System Migration |
| Feature | 5.3 - Audio Format Validation |
| Story ID | 5.3.1 |
| Story Points | 3 |
| Priority | P1 - Should Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-AUDIO-FORMAT-VALIDATE |
| FRs Covered | FR-AUDIO-3 (all audio formats decode correctly on all platforms) |
| Prerequisites | 5.2.1 (BGM wired via miniaudio -- done), 5.2.2 (SFX wired via miniaudio -- done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Add Catch2 tests in `tests/audio/test_audio_format_validation.cpp` that exercise miniaudio decoding of WAV, MP3, and OGG Vorbis files; add a portable test asset generator (`tests/audio/generate_test_assets.cpp`) that creates minimal valid audio files at runtime; no game logic changes |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** automated tests that verify miniaudio correctly decodes all audio formats used by the game (WAV, MP3, OGG Vorbis) on every platform,
**so that** I can confirm the audio migration produces correct output and detect platform-specific decoding failures in CI.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** A Catch2 test file `tests/audio/test_audio_format_validation.cpp` exercises `MiniAudioBackend::LoadSound()` for each audio format used by the game: WAV (PCM 16-bit, mono and stereo), MP3, and OGG Vorbis. Each format loads without error (return code check) and the resulting `ma_sound` is in a valid state (not playing, seekable to frame 0).
- [ ] **AC-2:** Test audio assets are generated at build time by a helper utility (`tests/audio/generate_test_assets.cpp`) that synthesizes minimal valid WAV (PCM 16-bit, 44100 Hz, mono + stereo), MP3, and OGG files in `${CMAKE_BINARY_DIR}/test-assets/audio/`. This avoids committing binary audio files to the repository. For MP3 and OGG, if runtime generation is impractical, embed minimal hex-literal byte arrays (< 4 KB each) directly in the test source file as `constexpr` arrays and write them to temp files before testing.
- [ ] **AC-3:** A Catch2 test verifies that `MiniAudioBackend::LoadSound()` with a non-existent file path logs an error via `g_ErrorReport.Write()` and does NOT crash or leave the backend in an invalid state. A test also verifies that loading a file with an invalid/corrupt header (e.g., random bytes) is handled gracefully (logs error, does not crash).
- [ ] **AC-4:** A Catch2 test verifies that `MiniAudioBackend::PlayMusic()` can load and start (then immediately stop) an OGG Vorbis file and an MP3 file -- confirming that the streaming path (`MA_SOUND_FLAG_STREAM`) works for both BGM formats. The test is headless-safe: `Initialize()` may fail on CI (no audio device), in which case the test gracefully skips the streaming check.
- [ ] **AC-5:** A Catch2 test uses `ma_decoder` directly (not via `MiniAudioBackend`) to decode each test asset file to raw PCM frames, then validates: (a) decoded frame count > 0, (b) decoded sample format is `ma_format_f32` or `ma_format_s16`, (c) decoded channel count matches the expected channel count for that asset. This confirms miniaudio's decoder pipeline works independently of the game's sound slot system.
- [ ] **AC-6:** All tests run headless on macOS, Linux, and Windows CI without an audio device. Tests that require `ma_engine` initialization guard with `Initialize()` success check and use `CHECK` (not `REQUIRE`) on the init result so the test suite completes even when no audio device is available.
- [ ] **AC-7:** The `ESound` enum values used in tests do NOT collide with game sound IDs -- tests use high-numbered buffer indices (`SOUND_EXPAND_END - 1`, `SOUND_EXPAND_END - 2`, etc.) or the tests allocate a standalone `MiniAudioBackend` instance that is independent of the game's `g_platformAudio`.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance -- `mu::` namespace for any new utility code, PascalCase functions, `#pragma once`, no raw `new`/`delete`, no `NULL` (use `nullptr`), no `wprintf`; `g_ErrorReport.Write()` for all failure paths in any non-test code
- [ ] **AC-STD-2:** Catch2 tests in `tests/audio/test_audio_format_validation.cpp`: format decoding, graceful failure on bad files, streaming path for BGM formats, direct decoder validation, headless CI compatibility
- [ ] **AC-STD-4:** CI quality gate passes (`./ctl check` -- clang-format check + cppcheck 0 errors)
- [ ] **AC-STD-6:** Conventional commit: `test(audio): add audio format validation tests for WAV, MP3, and OGG`

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check`)
- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [ ] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/audio/` directory pattern, explicit `target_sources` in `tests/CMakeLists.txt`)

---

## Validation Artifacts

- [ ] **AC-VAL-1:** All Catch2 tests pass on the CI build (MinGW cross-compile with `BUILD_TESTING=ON`)
- [ ] **AC-VAL-2:** `./ctl check` passes with 0 errors after changes
- [ ] **AC-VAL-3:** `git diff --name-only` shows only expected files (test files and CMakeLists.txt -- no game logic changes)

---

## Tasks / Subtasks

- [ ] Task 1: Create test audio asset generation (AC: 2)
  - [ ] Subtask 1.1: In `tests/audio/test_audio_format_validation.cpp`, create a helper namespace `test_assets` with functions to generate minimal valid audio files at test runtime:
    - `GenerateWavFile(const std::string& path, int channels, int sampleRate, int numSamples)` -- writes a valid WAV PCM 16-bit file with a sine wave tone (440 Hz). Use raw byte writes with the standard RIFF/WAVE header (44-byte header + PCM data). This is trivial to generate in code.
    - `WriteMP3File(const std::string& path)` -- writes a minimal valid MP3 file from a `constexpr` hex-literal array embedded in the source. Use a pre-encoded ~2 KB MP3 of 0.1 seconds of silence (encode offline, embed as `constexpr uint8_t kMinimalMp3[]`). Document the encoding parameters in a comment (e.g., "LAME 3.100, 44100 Hz, 128 kbps, mono, 0.1s silence").
    - `WriteOggFile(const std::string& path)` -- same approach as MP3: embed a minimal valid OGG Vorbis file (~3 KB) as `constexpr uint8_t kMinimalOgg[]`. Document encoding parameters.
  - [ ] Subtask 1.2: Use `std::filesystem::create_directories()` and `std::filesystem::temp_directory_path()` to create a temp directory for test assets. Clean up in a Catch2 `SECTION` or via RAII wrapper.
  - [ ] Subtask 1.3: Encode the minimal MP3 and OGG files offline using ffmpeg or LAME. Convert to C++ hex arrays using `xxd -i` or equivalent. Keep each under 4 KB. Document the exact command used in a comment above each array.

- [ ] Task 2: Implement WAV format validation tests (AC: 1, 5)
  - [ ] Subtask 2.1: Write `TEST_CASE("WAV mono PCM 16-bit loads via MiniAudioBackend")`: generate a mono WAV, construct `MiniAudioBackend`, call `Initialize()` (may fail on CI -- guard), call `LoadSound()` with the WAV path. On init success, verify no error logged. On init failure, verify `LoadSound()` does not crash.
  - [ ] Subtask 2.2: Write `TEST_CASE("WAV stereo PCM 16-bit loads via MiniAudioBackend")`: same as 2.1 but with stereo WAV.
  - [ ] Subtask 2.3: Write `TEST_CASE("WAV mono decodes to correct PCM frames via ma_decoder")`: use `ma_decoder_init_file()` directly on the generated WAV. Verify: `ma_decoder_get_length_in_pcm_frames() > 0`, output format is `ma_format_s16` or `ma_format_f32`, channel count == 1. Call `ma_decoder_uninit()`.
  - [ ] Subtask 2.4: Write `TEST_CASE("WAV stereo decodes to correct PCM frames via ma_decoder")`: same as 2.3 with stereo, channel count == 2.

- [ ] Task 3: Implement MP3 format validation tests (AC: 1, 4, 5)
  - [ ] Subtask 3.1: Write `TEST_CASE("MP3 loads via MiniAudioBackend")`: write embedded MP3 to temp file, construct backend, LoadSound. Same guard pattern as WAV tests.
  - [ ] Subtask 3.2: Write `TEST_CASE("MP3 streams via PlayMusic")`: construct backend, Initialize (guard), call `PlayMusic(mp3Path, TRUE)`, immediately call `StopMusic(nullptr, TRUE)`. Must not crash. If init succeeded, verify `IsEndMusic() == true` after stop.
  - [ ] Subtask 3.3: Write `TEST_CASE("MP3 decodes to correct PCM frames via ma_decoder")`: use `ma_decoder_init_file()` on the MP3 file. Verify frame count > 0, format is f32/s16.

- [ ] Task 4: Implement OGG Vorbis format validation tests (AC: 1, 4, 5)
  - [ ] Subtask 4.1: Write `TEST_CASE("OGG Vorbis loads via MiniAudioBackend")`: same pattern as MP3. The game uses OGG for 3 crywolf BGM tracks.
  - [ ] Subtask 4.2: Write `TEST_CASE("OGG Vorbis streams via PlayMusic")`: same pattern as MP3 streaming test.
  - [ ] Subtask 4.3: Write `TEST_CASE("OGG Vorbis decodes to correct PCM frames via ma_decoder")`: same pattern as MP3 decoder test.

- [ ] Task 5: Implement error handling tests (AC: 3)
  - [ ] Subtask 5.1: Write `TEST_CASE("LoadSound with non-existent file handles gracefully")`: call `LoadSound()` with a path that does not exist. Verify no crash. The slot should remain unloaded (`PlaySound` on that slot should be a no-op).
  - [ ] Subtask 5.2: Write `TEST_CASE("LoadSound with corrupt file handles gracefully")`: write random bytes to a `.wav` file, attempt `LoadSound()`. Verify no crash.
  - [ ] Subtask 5.3: Write `TEST_CASE("PlayMusic with non-existent file handles gracefully")`: call `PlayMusic("nonexistent.mp3", TRUE)`. Verify no crash. `IsEndMusic()` should return `true`.

- [ ] Task 6: Update CMake and quality gate (AC: AC-STD-4, AC-STD-6, AC-STD-16)
  - [ ] Subtask 6.1: In `MuMain/tests/CMakeLists.txt`, add:
    ```cmake
    # Story 5.3.1: Audio Format Validation [VS1-AUDIO-FORMAT-VALIDATE]
    target_sources(MuTests PRIVATE audio/test_audio_format_validation.cpp)
    ```
  - [ ] Subtask 6.2: Run `./ctl check` -- 0 errors
  - [ ] Subtask 6.3: Commit: `test(audio): add audio format validation tests for WAV, MP3, and OGG`

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A -- C++ client, no HTTP error codes | -- | -- | -- |

No new logging patterns introduced (test-only story). Existing `g_ErrorReport.Write()` patterns from `MiniAudioBackend` are exercised by the tests.

---

## Contract Catalog Entries

### API Contracts

Not applicable -- no network endpoints introduced.

### Event Contracts

Not applicable -- no events introduced.

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 3.7.1 | Format decoding correctness | WAV mono/stereo load, MP3 load, OGG load, MP3 stream, OGG stream, direct decoder validation, corrupt file handling, missing file handling |
| Integration (manual) | Windows build + live game | All ~950 SFX + ~48 BGM tracks play | Verify no silent sounds, no decode errors in MuError.log, no audio pops/clicks |

---

## Dev Notes

### Context: Why This Story Exists

This is the **final validation story for EPIC-5 (Audio System Migration)**. Stories 5.1.1, 5.2.1, 5.2.2, and 5.4.1 created the `IPlatformAudio` abstraction, wired BGM and SFX via miniaudio, and added volume controls. This story closes the epic by verifying that ALL audio formats used by the game decode correctly through the miniaudio pipeline on all platforms.

**Risk R19 from sprint-status.yaml:** "Audio format validation PCM hash comparison may fail due to floating-point decode differences across platforms." **Mitigation applied:** This story does NOT compare PCM hashes across platforms. Instead, it validates: (1) files load without error, (2) decoded frame counts are non-zero, (3) channel counts match expected values, (4) streaming paths work for BGM formats. This tolerance-based approach avoids floating-point comparison issues.

**EPIC-5 completion gate criteria addressed:**
- `all_audio_formats_decode_correctly` -- this story directly validates WAV, MP3, and OGG decoding
- `no_audio_latency_degradation` -- the `MA_SOUND_FLAG_DECODE` (pre-decode) strategy for SFX already mitigates latency; tests confirm the decode path works

### Audio Formats Used by the Game

| Format | Usage | Count | miniaudio Decoder | Notes |
|--------|-------|-------|-------------------|-------|
| WAV (PCM 16-bit) | Sound effects (SFX) | ~950 files loaded via `LoadWaveFile()` across `ZzzOpenData.cpp` (606), `MapManager.cpp` (330), `Event.cpp` (9) | Built-in WAV decoder | All in `Data\Sound\` directory tree; mono and stereo; loaded with `MA_SOUND_FLAG_DECODE` (pre-decode to memory) |
| MP3 | Background music (BGM) | ~45 tracks defined in `Core/mu_enum.h` (MUSIC_* constants) | Built-in MP3 decoder (dr_mp3) | Streamed via `MA_SOUND_FLAG_STREAM`; paths use backslash separators, normalized in `PlayMusic()` |
| OGG Vorbis | Background music (BGM) | 3 tracks: `crywolf_ready-02.ogg`, `crywolf_before-01.ogg`, `crywolf_back-03.ogg` | stb_vorbis (vendored at `src/dependencies/miniaudio/stb_vorbis.c`) | Streamed same as MP3; stb_vorbis included in `MiniAudioImpl.cpp` via `STB_VORBIS_HEADER_ONLY` pattern |

### Project Structure Notes

**New files to create:**

| File | CMake Target | Notes |
|------|-------------|-------|
| `MuMain/tests/audio/test_audio_format_validation.cpp` | `MuTests` (explicit add) | Catch2 test file with embedded MP3/OGG hex assets and WAV generator |

**Files to modify:**

| File | Change |
|------|--------|
| `MuMain/tests/CMakeLists.txt` | Add `audio/test_audio_format_validation.cpp` to MuTests |

**No game logic files are modified in this story.** This is a pure test-addition story.

### Technical Implementation

#### WAV File Generation (In-Test)

WAV files can be trivially generated in code by writing the 44-byte RIFF header followed by PCM samples:

```cpp
namespace test_assets
{

void GenerateWavFile(const std::string& path, int channels, int sampleRate, int numSamples)
{
    // 16-bit PCM WAV: 44-byte header + (numSamples * channels * 2) bytes data
    const int dataSize = numSamples * channels * 2;  // 16-bit = 2 bytes per sample per channel
    const int fileSize = 44 + dataSize;

    std::ofstream file(path, std::ios::binary);
    // RIFF header
    file.write("RIFF", 4);
    int32_t chunkSize = fileSize - 8;
    file.write(reinterpret_cast<const char*>(&chunkSize), 4);
    file.write("WAVE", 4);
    // fmt subchunk
    file.write("fmt ", 4);
    int32_t subchunk1Size = 16;
    file.write(reinterpret_cast<const char*>(&subchunk1Size), 4);
    int16_t audioFormat = 1;  // PCM
    file.write(reinterpret_cast<const char*>(&audioFormat), 2);
    int16_t numCh = static_cast<int16_t>(channels);
    file.write(reinterpret_cast<const char*>(&numCh), 2);
    file.write(reinterpret_cast<const char*>(&sampleRate), 4);
    int32_t byteRate = sampleRate * channels * 2;
    file.write(reinterpret_cast<const char*>(&byteRate), 4);
    int16_t blockAlign = static_cast<int16_t>(channels * 2);
    file.write(reinterpret_cast<const char*>(&blockAlign), 2);
    int16_t bitsPerSample = 16;
    file.write(reinterpret_cast<const char*>(&bitsPerSample), 2);
    // data subchunk
    file.write("data", 4);
    file.write(reinterpret_cast<const char*>(&dataSize), 4);
    // Generate sine wave samples (440 Hz)
    for (int i = 0; i < numSamples; ++i)
    {
        int16_t sample = static_cast<int16_t>(
            16384.0 * std::sin(2.0 * 3.14159265358979 * 440.0 * i / sampleRate));
        for (int ch = 0; ch < channels; ++ch)
        {
            file.write(reinterpret_cast<const char*>(&sample), 2);
        }
    }
}

} // namespace test_assets
```

#### Embedded MP3 and OGG Assets

Pre-encode minimal audio files offline and embed as hex arrays:

```bash
# Generate 0.1s silence as MP3 (mono, 44100 Hz, 128 kbps)
ffmpeg -f lavfi -i "anullsrc=r=44100:cl=mono" -t 0.1 -c:a libmp3lame -b:a 128k minimal.mp3
xxd -i minimal.mp3 > minimal_mp3_hex.h

# Generate 0.1s silence as OGG (mono, 44100 Hz)
ffmpeg -f lavfi -i "anullsrc=r=44100:cl=mono" -t 0.1 -c:a libvorbis minimal.ogg
xxd -i minimal.ogg > minimal_ogg_hex.h
```

The resulting `constexpr uint8_t` arrays should be < 4 KB each.

#### Direct Decoder Validation Pattern

```cpp
TEST_CASE("WAV mono decodes to correct PCM frames via ma_decoder")
{
    // Generate test WAV
    auto tempDir = std::filesystem::temp_directory_path() / "mu_audio_test";
    std::filesystem::create_directories(tempDir);
    auto wavPath = (tempDir / "test_mono.wav").string();
    test_assets::GenerateWavFile(wavPath, 1, 44100, 4410);  // 0.1s mono

    ma_decoder decoder;
    ma_decoder_config config = ma_decoder_config_init(ma_format_f32, 0, 0);
    ma_result result = ma_decoder_init_file(wavPath.c_str(), &config, &decoder);
    REQUIRE(result == MA_SUCCESS);

    ma_uint64 frameCount = 0;
    result = ma_decoder_get_length_in_pcm_frames(&decoder, &frameCount);
    CHECK(result == MA_SUCCESS);
    CHECK(frameCount > 0);

    // Verify channel count
    CHECK(decoder.outputChannels == 1);

    ma_decoder_uninit(&decoder);
    std::filesystem::remove_all(tempDir);
}
```

#### Headless CI Guard Pattern

All tests that need `ma_engine` (via `MiniAudioBackend`) use this guard:

```cpp
mu::MiniAudioBackend backend;
bool initOk = backend.Initialize();
// CI may not have audio device -- guard engine-dependent tests
if (!initOk)
{
    WARN("MiniAudioBackend::Initialize() failed (no audio device?) -- skipping engine test");
    return;  // or SKIP() in Catch2 3.x
}
// ... test logic that requires initialized engine ...
backend.Shutdown();
```

Tests that use `ma_decoder` directly do NOT need `ma_engine` and should always work on all platforms (no audio device needed).

#### Test Independence from Game State

Tests construct their own `MiniAudioBackend` instances on the stack -- they do NOT touch `g_platformAudio`. This avoids collisions with game sound IDs and ensures tests are independent of game initialization order.

### Sibling Story Context (EPIC-5)

- **5.1.1 (done):** Created `IPlatformAudio` + `MiniAudioBackend` + vendored miniaudio + stb_vorbis
- **5.2.1 (done):** Wired BGM via `g_platformAudio`, removed wzAudio dependency, added path normalization
- **5.2.2 (done):** Wired SFX via `g_platformAudio`, added per-slot OBJECT* tracking, removed DirectSound init
- **5.4.1 (done):** Added SetBGMVolume/SetSFXVolume to IPlatformAudio, GameConfig persistence

Key learnings from sibling stories:
- **5.2.2 session-summary:** CRITICAL issue found with uninitialized `ma_sound` slots in polyphonic playback -- fixed via `m_loadedChannels` array. Tests should verify this doesn't regress.
- **5.2.2 session-summary:** Dangling pointer risk with `m_soundObjects` during `LoadSound()` reload -- tests should exercise the reload path.
- Path normalization (`\\` to `/`) is applied in both `LoadSound()` and `PlayMusic()` -- test file paths should use forward slashes.

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, Catch2 3.7.1, miniaudio 0.11.x (vendored), `MuTests` CMake target

**Prohibited (per project-context.md):**
- `new`/`delete` -- use `std::array`, `std::unique_ptr`, stack allocation
- `NULL` -- use `nullptr`
- `wprintf`, `__TraceF()`, `DebugAngel` -- use `g_ErrorReport.Write()`
- `#ifndef` header guards -- use `#pragma once`
- `#ifdef _WIN32` in test logic -- tests must be platform-agnostic
- No binary audio files committed to the repository -- generate WAV at runtime, embed MP3/OGG as hex arrays

**Required patterns (per project-context.md):**
- `mu::` namespace for any helper code
- Allman brace style, 4-space indent, 120-column limit (`.clang-format`)
- `#pragma once` if any header is created
- Catch2 `TEST_CASE` / `SECTION` structure
- `REQUIRE_NOTHROW` for crash-safety tests
- Forward slashes in all file paths

**Quality gate:** `./ctl check` -- must pass 0 errors. File count increases by 1 (test file). cppcheck runs on changed files only; the test file should pass cppcheck with no warnings.

### References

- [Source: `_bmad-output/stories/5-1-1-muaudio-abstraction-layer/story.md` -- IPlatformAudio interface, MiniAudioBackend implementation, miniaudio vendoring, stb_vorbis]
- [Source: `_bmad-output/stories/5-2-1-miniaudio-bgm/story.md` -- BGM wiring, wzAudio removal, path normalization, PlayMusic/StopMusic delegation]
- [Source: `_bmad-output/stories/5-2-2-miniaudio-sfx/story.md` -- SFX wiring, per-slot OBJECT* tracking, m_loadedChannels fix, LoadSound delegation]
- [Source: `_bmad-output/stories/5-2-2-miniaudio-sfx/session-summary.md` -- CRITICAL: uninitialized ma_sound slots, dangling pointer fixes]
- [Source: `_bmad-output/stories/5-4-1-volume-controls/story.md` -- Volume API additions to IPlatformAudio]
- [Source: `_bmad-output/project-context.md` -- C++ Language Rules, Testing Rules, Prohibited Libraries]
- [Source: `docs/development-standards.md` -- S1 Banned Win32 API table (Audio row), S2 Error Handling]
- [Source: `MuMain/src/source/Core/mu_enum.h` lines 169-216 -- MUSIC_* constants (45 MP3, 3 OGG)]
- [Source: `MuMain/src/source/Data/ZzzOpenData.cpp` -- 606 LoadWaveFile() calls for SFX WAVs]
- [Source: `MuMain/src/source/World/MapManager.cpp` -- 330 LoadWaveFile() calls for map SFX]
- [Source: `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` -- LoadSound() with path normalization, ma_sound_init_from_file]
- [Source: `MuMain/src/dependencies/miniaudio/miniaudio.h` -- miniaudio v0.11.25 single-header library]
- [Source: `MuMain/src/dependencies/miniaudio/stb_vorbis.c` -- OGG Vorbis decoder]
- [Source: `MuMain/tests/CMakeLists.txt` -- test registration pattern]
- [Source: `_bmad-output/implementation-artifacts/sprint-status.yaml` -- R19 risk item: floating-point decode differences]

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
