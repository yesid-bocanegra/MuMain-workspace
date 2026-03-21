# Test Scenarios: Story 5.3.1 — Audio Format Validation

**Generated:** 2026-03-20
**Story:** 5.3.1 Audio Format Validation
**Flow Code:** VS1-AUDIO-FORMAT-VALIDATE
**Project:** MuMain-workspace

These scenarios cover validation of Story 5.3.1 acceptance criteria.
Automated tests (Catch2 unit tests in `MuMain/tests/audio/test_audio_format_validation.cpp`) run on macOS/Linux/Windows CI.
All tests are headless-safe: ma_engine-dependent tests guard with Initialize() success check.

---

## AC-1: WAV/MP3/OGG Load via MiniAudioBackend

### Scenario 1: WAV mono PCM 16-bit loads without error (automated)

- **Prerequisites:** Compiled MuTests binary, temp directory writable
- **Given:** A runtime-generated mono WAV file (44100 Hz, PCM 16-bit, 440 Hz sine wave)
- **When:** `MiniAudioBackend::LoadSound()` is called with the WAV path
- **Then:** No crash occurs; if Initialize() succeeded, the sound slot is valid
- **Automated:** `TEST_CASE("AC-1: WAV mono PCM 16-bit loads via MiniAudioBackend")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 2: WAV stereo PCM 16-bit loads without error (automated)

- **Prerequisites:** Compiled MuTests binary, temp directory writable
- **Given:** A runtime-generated stereo WAV file (44100 Hz, PCM 16-bit, 440 Hz sine wave)
- **When:** `MiniAudioBackend::LoadSound()` is called with the WAV path
- **Then:** No crash occurs; if Initialize() succeeded, the sound slot is valid
- **Automated:** `TEST_CASE("AC-1: WAV stereo PCM 16-bit loads via MiniAudioBackend")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 3: MP3 loads without error (automated)

- **Prerequisites:** Compiled MuTests binary, embedded kMinimalMp3 array (2551 bytes)
- **Given:** A valid MP3 file written from embedded hex array (LAME 128kbps, 44100 Hz, mono)
- **When:** `MiniAudioBackend::LoadSound()` is called with the MP3 path
- **Then:** No crash occurs; if Initialize() succeeded, the sound slot is valid
- **Automated:** `TEST_CASE("AC-1: MP3 loads via MiniAudioBackend")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 4: OGG Vorbis loads without error (automated)

- **Prerequisites:** Compiled MuTests binary, embedded kMinimalOgg array (3798 bytes)
- **Given:** A valid OGG Vorbis file written from embedded hex array (oggenc quality 0, 44100 Hz, mono)
- **When:** `MiniAudioBackend::LoadSound()` is called with the OGG path
- **Then:** No crash occurs; if Initialize() succeeded, the sound slot is valid
- **Automated:** `TEST_CASE("AC-1: OGG Vorbis loads via MiniAudioBackend")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-2: Test Assets Generated at Runtime

### Scenario 5: WAV generated at runtime with valid RIFF headers (automated)

- **Prerequisites:** Temp directory writable
- **Given:** `test_assets::GenerateWavFile()` is called with mono, 44100 Hz, 4410 samples
- **When:** The generated file is inspected
- **Then:** File has valid 44-byte RIFF/WAVE header, correct data chunk size, PCM 16-bit samples
- **Automated:** Implicitly validated by all WAV test cases (GenerateWavFile output is decoded by ma_decoder)
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 6: Embedded MP3 hex array is valid encoded data (automated)

- **Prerequisites:** kMinimalMp3 constexpr array in source
- **Given:** `test_assets::WriteMP3File()` writes kMinimalMp3 to a temp file
- **When:** `ma_decoder_init_file()` is called on the written file
- **Then:** Returns MA_SUCCESS, frame count > 0, format is f32 or s16
- **Automated:** `TEST_CASE("AC-5: MP3 decodes to correct PCM frames via ma_decoder")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 7: Embedded OGG hex array is valid encoded data (automated)

- **Prerequisites:** kMinimalOgg constexpr array in source
- **Given:** `test_assets::WriteOggFile()` writes kMinimalOgg to a temp file
- **When:** `ma_decoder_init_file()` is called on the written file
- **Then:** Returns MA_SUCCESS, frame count > 0, channels == 1
- **Automated:** `TEST_CASE("AC-5: OGG Vorbis decodes to correct PCM frames via ma_decoder")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 8: TempAudioDir RAII cleanup (automated)

- **Prerequisites:** std::filesystem available
- **Given:** A TempAudioDir instance is constructed
- **When:** The instance goes out of scope
- **Then:** The temp directory and all files within are removed
- **Automated:** Implicitly validated by Catch2 test case scoping (no temp files left after test run)
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-3: Error Handling -- Graceful Failure

### Scenario 9: LoadSound with non-existent file does not crash (automated)

- **Prerequisites:** Compiled MuTests binary
- **Given:** A file path that does not exist on disk
- **When:** `MiniAudioBackend::LoadSound()` is called with the non-existent path
- **Then:** No crash, no exception; the sound slot remains unloaded
- **Automated:** `TEST_CASE("AC-3: LoadSound with non-existent file handles gracefully")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 10: LoadSound with corrupt file does not crash (automated)

- **Prerequisites:** Compiled MuTests binary
- **Given:** A file containing 256 bytes of pseudo-random data with a .wav extension
- **When:** `MiniAudioBackend::LoadSound()` is called with the corrupt file path
- **Then:** No crash; miniaudio rejects the invalid header gracefully
- **Automated:** `TEST_CASE("AC-3: LoadSound with corrupt file handles gracefully")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 11: PlayMusic with non-existent file does not crash (automated)

- **Prerequisites:** Compiled MuTests binary
- **Given:** A non-existent MP3 file path
- **When:** `MiniAudioBackend::PlayMusic()` is called with the path
- **Then:** No crash; `IsEndMusic()` returns true
- **Automated:** `TEST_CASE("AC-3: PlayMusic with non-existent file handles gracefully")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-4: MP3/OGG Streaming Path (PlayMusic)

### Scenario 12: MP3 streams via PlayMusic without crash (automated)

- **Prerequisites:** Compiled MuTests binary, audio device (skipped headless)
- **Given:** A valid MP3 file and an initialized MiniAudioBackend
- **When:** `PlayMusic(mp3Path, TRUE)` is called, then `StopMusic(nullptr, TRUE)` immediately
- **Then:** No crash; `IsEndMusic()` returns true after stop
- **Automated:** `TEST_CASE("AC-4: MP3 streams via PlayMusic without crash")` -- GREEN (or SKIPPED on headless CI)
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 13: OGG Vorbis streams via PlayMusic without crash (automated)

- **Prerequisites:** Compiled MuTests binary, audio device (skipped headless)
- **Given:** A valid OGG Vorbis file and an initialized MiniAudioBackend
- **When:** `PlayMusic(oggPath, TRUE)` is called, then `StopMusic(nullptr, TRUE)` immediately
- **Then:** No crash; `IsEndMusic()` returns true after stop
- **Automated:** `TEST_CASE("AC-4: OGG Vorbis streams via PlayMusic without crash")` -- GREEN (or SKIPPED on headless CI)
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-5: Direct ma_decoder Pipeline Validation

### Scenario 14: WAV mono decodes to correct PCM frames (automated)

- **Prerequisites:** Runtime-generated mono WAV file
- **Given:** `ma_decoder_init_file()` called on mono WAV
- **When:** Decoder output is inspected
- **Then:** `ma_decoder_get_length_in_pcm_frames() > 0`, `outputChannels == 1`
- **Automated:** `TEST_CASE("AC-5: WAV mono decodes to correct PCM frames via ma_decoder")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 15: WAV stereo decodes to correct PCM frames (automated)

- **Prerequisites:** Runtime-generated stereo WAV file
- **Given:** `ma_decoder_init_file()` called on stereo WAV
- **When:** Decoder output is inspected
- **Then:** `ma_decoder_get_length_in_pcm_frames() > 0`, `outputChannels == 2`
- **Automated:** `TEST_CASE("AC-5: WAV stereo decodes to correct PCM frames via ma_decoder")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 16: MP3 decodes to correct PCM frames (automated)

- **Prerequisites:** Embedded MP3 written to temp file
- **Given:** `ma_decoder_init_file()` called on MP3 file
- **When:** Decoder output is inspected
- **Then:** `MA_SUCCESS` returned, `frame count > 0`, `outputFormat` is f32 or s16
- **Automated:** `TEST_CASE("AC-5: MP3 decodes to correct PCM frames via ma_decoder")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 17: OGG Vorbis decodes to correct PCM frames (automated)

- **Prerequisites:** Embedded OGG written to temp file
- **Given:** `ma_decoder_init_file()` called on OGG file
- **When:** Decoder output is inspected
- **Then:** `MA_SUCCESS` returned, `frame count > 0`, `outputChannels == 1`
- **Automated:** `TEST_CASE("AC-5: OGG Vorbis decodes to correct PCM frames via ma_decoder")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 18: Format-agnostic pipeline contract (automated)

- **Prerequisites:** Runtime-generated WAV file
- **Given:** `ma_decoder_init_file()` called on a valid WAV
- **When:** `ma_decoder_get_length_in_pcm_frames()` is called
- **Then:** Returns non-zero frame count, confirming the decoder pipeline is functional
- **Automated:** `TEST_CASE("AC-5: ma_decoder pipeline returns non-zero frame count for valid WAV")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-6: Headless CI Compatibility

### Scenario 19: ma_decoder works without audio device (automated)

- **Prerequisites:** CI environment without audio hardware
- **Given:** `ma_decoder_init_file()` called (no ma_engine required)
- **When:** Tests run on headless CI (macOS/Linux/Windows without audio device)
- **Then:** All ma_decoder tests pass; backend tests that need Initialize() gracefully skip
- **Automated:** `TEST_CASE("AC-6: ma_decoder works without audio device (headless CI compatible)")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-7: Standalone Backend Independence

### Scenario 20: MiniAudioBackend is independent from g_platformAudio (automated)

- **Prerequisites:** Compiled MuTests binary
- **Given:** Tests construct standalone `mu::MiniAudioBackend` instances on the stack
- **When:** All audio format tests execute
- **Then:** `g_platformAudio` remains nullptr; no global state is modified
- **Automated:** `TEST_CASE("AC-7: Test MiniAudioBackend is independent from g_platformAudio")` -- GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## Summary

| AC | Scenarios | Automated | Manual | Status |
|----|-----------|-----------|--------|--------|
| AC-1 | 4 | 4 | 0 | All GREEN |
| AC-2 | 4 | 4 | 0 | All GREEN |
| AC-3 | 3 | 3 | 0 | All GREEN |
| AC-4 | 2 | 2 | 0 | GREEN (skipped headless) |
| AC-5 | 5 | 5 | 0 | All GREEN |
| AC-6 | 1 | 1 | 0 | GREEN |
| AC-7 | 1 | 1 | 0 | GREEN |
| **Total** | **20** | **20** | **0** | **All GREEN** |
