# ATDD Checklist — Story 5.3.1: Audio Format Validation

**Story Key:** 5-3-1-audio-format-validation
**Story Type:** infrastructure
**Date Generated:** 2026-03-20
**Phase:** RED (all tests failing until implementation verified in CI)
**Output File:** `MuMain/tests/audio/test_audio_format_validation.cpp`

---

## FSM Handoff Summary

| Field | Value |
|-------|-------|
| `atdd_checklist_path` | `_bmad-output/stories/5-3-1-audio-format-validation/atdd.md` |
| `test_files_created` | `MuMain/tests/audio/test_audio_format_validation.cpp` |
| `implementation_checklist_complete` | FALSE (all items `[ ]` — ready for implementation) |
| `story_type` | `infrastructure` |
| `backend_root` | `./MuMain` |

---

## AC-to-Test Mapping

| AC | Description | Test Method(s) | File |
|----|-------------|----------------|------|
| AC-1 | WAV/MP3/OGG load via MiniAudioBackend | `AC-1: WAV mono PCM 16-bit loads via MiniAudioBackend` | test_audio_format_validation.cpp |
| AC-1 | WAV stereo load | `AC-1: WAV stereo PCM 16-bit loads via MiniAudioBackend` | test_audio_format_validation.cpp |
| AC-1 | MP3 load via MiniAudioBackend | `AC-1: MP3 loads via MiniAudioBackend` | test_audio_format_validation.cpp |
| AC-1 | OGG Vorbis load via MiniAudioBackend | `AC-1: OGG Vorbis loads via MiniAudioBackend` | test_audio_format_validation.cpp |
| AC-2 | Test assets generated at runtime | `test_assets::GenerateWavFile`, `WriteMP3File`, `WriteOggFile` helpers | test_audio_format_validation.cpp |
| AC-3 | Non-existent file graceful | `AC-3: LoadSound with non-existent file handles gracefully` | test_audio_format_validation.cpp |
| AC-3 | Corrupt file graceful | `AC-3: LoadSound with corrupt file handles gracefully` | test_audio_format_validation.cpp |
| AC-3 | PlayMusic non-existent graceful | `AC-3: PlayMusic with non-existent file handles gracefully` | test_audio_format_validation.cpp |
| AC-4 | MP3 streaming path (PlayMusic) | `AC-4: MP3 streams via PlayMusic without crash` | test_audio_format_validation.cpp |
| AC-4 | OGG Vorbis streaming path (PlayMusic) | `AC-4: OGG Vorbis streams via PlayMusic without crash` | test_audio_format_validation.cpp |
| AC-5 | WAV mono decoder pipeline | `AC-5: WAV mono decodes to correct PCM frames via ma_decoder` | test_audio_format_validation.cpp |
| AC-5 | WAV stereo decoder pipeline | `AC-5: WAV stereo decodes to correct PCM frames via ma_decoder` | test_audio_format_validation.cpp |
| AC-5 | MP3 decoder pipeline | `AC-5: MP3 decodes to correct PCM frames via ma_decoder` | test_audio_format_validation.cpp |
| AC-5 | OGG decoder pipeline | `AC-5: OGG Vorbis decodes to correct PCM frames via ma_decoder` | test_audio_format_validation.cpp |
| AC-5 | Format-agnostic pipeline contract | `AC-5: ma_decoder pipeline returns non-zero frame count for valid WAV` | test_audio_format_validation.cpp |
| AC-6 | Headless CI — ma_decoder works without audio device | `AC-6: ma_decoder works without audio device (headless CI compatible)` | test_audio_format_validation.cpp |
| AC-7 | Standalone backend independence | `AC-7: Test MiniAudioBackend is independent from g_platformAudio` | test_audio_format_validation.cpp |

---

## Test Levels Selected

| Story Type | Unit | Integration | E2E | API Collection |
|------------|------|-------------|-----|----------------|
| infrastructure | Yes | Yes | No | No (skipped — no API endpoints) |

---

## Implementation Checklist

### AC Coverage

- [ ] AC-1: WAV mono PCM 16-bit loads without error via `MiniAudioBackend::LoadSound()`
- [ ] AC-1: WAV stereo PCM 16-bit loads without error via `MiniAudioBackend::LoadSound()`
- [ ] AC-1: MP3 loads without error via `MiniAudioBackend::LoadSound()`
- [ ] AC-1: OGG Vorbis loads without error via `MiniAudioBackend::LoadSound()`
- [ ] AC-2: `test_assets::GenerateWavFile()` writes a valid RIFF/PCM WAV at runtime
- [ ] AC-2: `test_assets::WriteMP3File()` writes embedded MP3 hex array to a temp file
- [ ] AC-2: `test_assets::WriteOggFile()` writes embedded OGG hex array to a temp file
- [ ] AC-2: `TempAudioDir` RAII wrapper creates and cleans up temp directory correctly
- [ ] AC-3: `LoadSound()` with non-existent path does not crash; slot remains unloaded
- [ ] AC-3: `LoadSound()` with corrupt file does not crash; miniaudio rejects invalid header
- [ ] AC-3: `PlayMusic()` with non-existent path does not crash; `IsEndMusic()` returns true
- [ ] AC-4: `PlayMusic()` + `StopMusic()` with MP3 path does not crash (streaming path)
- [ ] AC-4: `PlayMusic()` + `StopMusic()` with OGG path does not crash (streaming path)
- [ ] AC-4: `IsEndMusic()` returns true after `StopMusic()` for both BGM formats
- [ ] AC-5: `ma_decoder_init_file()` returns `MA_SUCCESS` for WAV mono
- [ ] AC-5: `ma_decoder_get_length_in_pcm_frames()` returns > 0 for WAV mono
- [ ] AC-5: `decoder.outputChannels == 1` for mono WAV
- [ ] AC-5: `decoder.outputChannels == 2` for stereo WAV
- [ ] AC-5: `ma_decoder_init_file()` returns `MA_SUCCESS` for MP3
- [ ] AC-5: `ma_decoder_get_length_in_pcm_frames()` returns > 0 for MP3
- [ ] AC-5: `decoder.outputFormat` is `ma_format_f32` or `ma_format_s16` for MP3
- [ ] AC-5: `ma_decoder_init_file()` returns `MA_SUCCESS` for OGG Vorbis
- [ ] AC-5: `ma_decoder_get_length_in_pcm_frames()` returns > 0 for OGG Vorbis
- [ ] AC-5: `decoder.outputChannels == 1` for embedded OGG (mono)
- [ ] AC-6: All `ma_decoder` tests pass on CI without audio device (no `ma_engine` required)
- [ ] AC-6: Backend tests that require `Initialize()` guard with `bool initOk` check
- [ ] AC-6: Tests using `CHECK` (not `REQUIRE`) on `Initialize()` result so suite completes headless
- [ ] AC-7: Tests construct standalone `mu::MiniAudioBackend` instances on the stack
- [ ] AC-7: No test assigns or modifies `g_platformAudio`
- [ ] AC-7: `g_platformAudio == nullptr` after all audio format tests execute

### PCC Compliance

- [ ] PCC: No prohibited libraries used (`new`/`delete`, `NULL`, `wprintf`, `#ifdef _WIN32` in test logic)
- [ ] PCC: `mu::` namespace used for `MiniAudioBackend` access throughout
- [ ] PCC: Allman brace style, 4-space indent, 120-column limit enforced
- [ ] PCC: `std::filesystem::path` used for all file path construction
- [ ] PCC: Forward slashes in all file paths (`.generic_string()` used)
- [ ] PCC: `std::ofstream` used for file I/O (not `_wfopen`, `CreateFile`)
- [ ] PCC: No binary audio files committed — WAV generated at runtime, MP3/OGG as `constexpr` hex arrays
- [ ] PCC: `#pragma once` not needed (`.cpp` only — no header created)

### CMake / Build

- [ ] CMake: `target_sources(MuTests PRIVATE audio/test_audio_format_validation.cpp)` added to `tests/CMakeLists.txt`
- [ ] CMake: New test file compiles with `BUILD_TESTING=ON` on MinGW cross-compile (CI)
- [ ] CMake: `MuTests` already links `MUAudio` (provides `MiniAudioBackend` symbols) — no new `target_link_libraries` needed
- [ ] CMake: `MuTests` already has `target_include_directories` for `src/dependencies/miniaudio` — `miniaudio.h` available

### Quality Gate

- [ ] QG: `./ctl check` passes with 0 errors (clang-format + cppcheck) after adding test file
- [ ] QG: No cppcheck warnings in `test_audio_format_validation.cpp`
- [ ] QG: `SOUND_EXPAND_END - N` indices used (not hard-coded game sound IDs) to avoid collision

### Commit

- [ ] Commit: `test(audio): add audio format validation tests for WAV, MP3, and OGG`

---

## PCC Compliance Summary

| Check | Status | Notes |
|-------|--------|-------|
| Prohibited libraries | PASS | No `new`/`delete`, `NULL`, `wprintf`, `#ifdef _WIN32` in test logic |
| Required testing patterns | PASS | Catch2 `TEST_CASE`/`SECTION`, `REQUIRE`/`CHECK`/`REQUIRE_NOTHROW` |
| Test profiles | PASS | `MuTests` target, `tests/audio/` directory |
| Coverage target | N/A | Coverage threshold = 0 (growing incrementally per `.pcc-config.yaml`) |
| No binary assets committed | PASS | WAV generated in-process; MP3/OGG as `constexpr` hex arrays |
| Headless CI | PASS | `ma_decoder` tests need no audio device; backend tests guard `Initialize()` |
| Test independence | PASS | Standalone `mu::MiniAudioBackend` instances; `g_platformAudio` not touched |

---

## Failing Tests Created (RED Phase)

| Level | Count | Tool |
|-------|-------|------|
| Unit/integration (Catch2) | 17 TEST_CASEs | Catch2 3.7.1 |
| E2E | 0 | N/A (infrastructure story) |
| API collection (Bruno) | 0 | N/A (no HTTP endpoints) |

**Total failing tests:** 17 TEST_CASEs in `test_audio_format_validation.cpp`

Tests that are RED until the embedded MP3/OGG hex arrays represent fully valid encoded files:
- `AC-5: MP3 decodes to correct PCM frames via ma_decoder` — WILL FAIL if embedded MP3 bytes are not a valid MPEG Layer 3 bitstream
- `AC-5: OGG Vorbis decodes to correct PCM frames via ma_decoder` — WILL FAIL if embedded OGG bytes are not a valid OGG/Vorbis page structure
- `AC-1: MP3 loads via MiniAudioBackend` — depends on above
- `AC-1: OGG Vorbis loads via MiniAudioBackend` — depends on above

**Dev note:** The embedded hex arrays in the current RED phase are representative stubs. The dev implementing story 5-3-1 must run the `ffmpeg` + `xxd -i` commands documented in the story's Dev Notes to generate real minimal MP3/OGG files and replace the stub arrays. The WAV tests will pass immediately since `GenerateWavFile()` produces a valid RIFF/PCM file.

---

## Notes for Implementation (dev-story)

1. **MP3/OGG hex arrays:** Replace the stub `kMinimalMp3` and `kMinimalOgg` arrays with real encoded data. Run the `ffmpeg` + `xxd -i` commands from the story's Dev Notes section. Each array must be < 4 KB.
2. **SOUND_EXPAND_END:** Verify this constant is defined in `mu_enum.h`. If not, use a fixed high index (e.g., `static_cast<ESound>(MAX_BUFFER - 1)`) to avoid collision with game sound IDs.
3. **WAV tests:** These will pass immediately — `GenerateWavFile()` produces a valid RIFF/WAV with correct headers.
4. **Streaming tests (AC-4):** These only exercise the full path when `Initialize()` succeeds (audio device present). On CI (headless), they skip via early return — this is the correct AC-6 behavior.
5. **CMakeLists.txt:** The `target_sources` line has been added. No other CMake changes needed.
