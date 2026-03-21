# Code Review — Story 5.3.1: Audio Format Validation

**Story Key:** 5-3-1-audio-format-validation
**Reviewer:** Claude Opus 4.6 (adversarial code review)
**Date:** 2026-03-20
**Files Reviewed:**
- `MuMain/tests/audio/test_audio_format_validation.cpp` (1240 lines)
- `MuMain/tests/CMakeLists.txt` (line 183-194, story 5.3.1 section)

---

## Quality Gate

**Status:** Pending -- run by pipeline (`./ctl check`)

---

## Findings

### BLOCKER-1: `SOUND_EXPAND_END` is undefined -- test file will not compile

- **Severity:** BLOCKER
- **File:** `MuMain/tests/audio/test_audio_format_validation.cpp`
- **Lines:** 773, 799, 888, 983, 1082, 1085, 1117
- **Description:** The test uses `static_cast<ESound>(SOUND_EXPAND_END - N)` for slot indices in 7 locations, but `SOUND_EXPAND_END` does not exist anywhere in the codebase. The `ESound` enum in `DSPlaySound.h` defines `SOUND_EXPAND_START` (line 387) but the enum continues with individual sound entries and terminates at `MAX_BUFFER` (line 995). There is no `SOUND_EXPAND_END` sentinel value. This is a compilation error -- the test TU will fail to compile on any platform.
- **Suggested Fix:** Replace all `SOUND_EXPAND_END - N` expressions with `MAX_BUFFER - N` (e.g., `static_cast<ESound>(MAX_BUFFER - 1)`, `static_cast<ESound>(MAX_BUFFER - 2)`, etc.). `MAX_BUFFER` is the sentinel value at the end of the enum and is already used as the array dimension in `MiniAudioBackend.h` (line 68). Using `MAX_BUFFER - N` guarantees valid array indices that do not collide with any game sound IDs. Alternatively, the story suggested `SOUND_EXPAND_END - N` as one option and `MAX_BUFFER - N` as a fallback -- the fallback should be used since the primary does not exist.

### MEDIUM-1: Unsafe `std::wstring` construction from narrow string via iterator range

- **Severity:** MEDIUM
- **File:** `MuMain/tests/audio/test_audio_format_validation.cpp`
- **Lines:** 772, 798, 887, 982, 1081, 1116
- **Description:** The test converts narrow `std::string` to `std::wstring` via `std::wstring wPath(path.begin(), path.end())`. This works only for ASCII paths because it widens each `char` to `wchar_t` by zero-extension. If the system temp directory contains non-ASCII characters (e.g., a user's home directory with accented or CJK characters on a localized system), this conversion produces incorrect `wchar_t` values. On macOS, `std::filesystem::temp_directory_path()` returns `/tmp/` which is always ASCII, so this is safe in practice. On Windows with localized usernames, `%TEMP%` may contain non-ASCII characters, which would cause `LoadSound()` to pass garbage to `mu_wchar_to_utf8()`.
- **Suggested Fix:** Use the project's `mu_utf8_to_wchar()` function (if available) or `std::filesystem::path::wstring()` for a correct UTF-8-to-wide conversion: `auto wPath = std::filesystem::path(narrowPath).wstring();`. This handles multi-byte UTF-8 correctly on all platforms. Since test paths are always under `/tmp/` or a controlled location with ASCII-only names, this is MEDIUM rather than HIGH.

### MEDIUM-2: Fixed temp directory name creates parallel test execution conflict

- **Severity:** MEDIUM
- **File:** `MuMain/tests/audio/test_audio_format_validation.cpp`
- **Line:** 717
- **Description:** `TempAudioDir` uses the hardcoded path `mu_audio_test_5_3_1` under the system temp directory. If two CI jobs or two test runs execute in parallel on the same machine, they will share the same temp directory. The RAII destructor calls `std::filesystem::remove_all()` on it, which can delete files that a parallel test is actively reading (race condition). This can cause intermittent `ma_decoder_init_file()` failures or `GenerateWavFile()` failures on CI.
- **Suggested Fix:** Append a unique suffix to the directory name, such as the process ID: `std::filesystem::temp_directory_path() / ("mu_audio_test_5_3_1_" + std::to_string(getpid()))`. Alternatively, use `std::tmpnam()` or a UUID. This is MEDIUM because parallel execution of the same test binary is uncommon in practice, but the fix is trivial.

### MEDIUM-3: Comment mismatch between OGG encoding command and "silence" description

- **Severity:** LOW
- **File:** `MuMain/tests/audio/test_audio_format_validation.cpp`
- **Lines:** 363-367 vs 373-374
- **Description:** The `WriteOggFile` header comment (line 363) documents the encoding command as `ffmpeg -f lavfi -i "sine=frequency=440:sample_rate=44100:duration=0.1"` (a 440 Hz tone), while the `Parameters:` line (367) says "~0.1s silence" and the inner comment (line 374) says `anullsrc=r=44100:cl=mono` (null/silence source). The actual embedded bytes contain real Vorbis-encoded data, so the header command appears to be the correct one (440 Hz sine, not silence). The inner comment and "silence" label are stale from an earlier iteration. This does not affect functionality but is misleading for future maintainers.
- **Suggested Fix:** Update line 367 to say `~0.1s 440 Hz tone (3798 bytes)` and update line 374 to match the header encoding command (`sine=frequency=440`).

### LOW-1: Redundant AC-5 pipeline test duplicates WAV mono decoder test

- **Severity:** LOW
- **File:** `MuMain/tests/audio/test_audio_format_validation.cpp`
- **Lines:** 1150-1182 vs 813-839
- **Description:** `TEST_CASE("AC-5: ma_decoder pipeline returns non-zero frame count for valid WAV")` (line 1150) exercises the exact same ma_decoder path as `TEST_CASE("AC-5: WAV mono decodes to correct PCM frames via ma_decoder")` (line 813) with nearly identical assertions: `MA_SUCCESS`, `frameCount > 0`, `outputChannels == 1`. The only addition is reading PCM frames into a buffer (line 1175-1179). While this extra read is marginally valuable, the test is ~80% duplicated.
- **Suggested Fix:** Either merge the `ma_decoder_read_pcm_frames` assertion into the existing WAV mono decoder test (line 813), or document why the duplication is intentional (e.g., "this test focuses on the read path, the other focuses on metadata"). Not a functional issue.

### LOW-2: AC-6 headless CI test only verifies WAV, not MP3/OGG

- **Severity:** LOW
- **File:** `MuMain/tests/audio/test_audio_format_validation.cpp`
- **Lines:** 1193-1211
- **Description:** `TEST_CASE("AC-6: ma_decoder works without audio device")` only creates a WAV file and verifies it decodes successfully without `ma_engine`. AC-6 states "All tests run headless on macOS/Linux/Windows CI without audio device." The test does not verify that the MP3 and OGG decoder paths also work headless. In practice, the AC-5 MP3/OGG decoder tests already exercise this implicitly (they use `ma_decoder` without `ma_engine`), so AC-6 is covered in aggregate. However, the dedicated AC-6 test only proves headless WAV decoding.
- **Suggested Fix:** Add MP3 and OGG sections to the AC-6 test for completeness, or add a comment noting that AC-6 is also implicitly covered by the AC-5 MP3/OGG decoder tests. This is cosmetic.

### LOW-3: `Shutdown()` called without guarding `initOk` in error-handling tests

- **Severity:** LOW
- **File:** `MuMain/tests/audio/test_audio_format_validation.cpp`
- **Lines:** 1087, 1119, 1139
- **Description:** In the AC-3 error handling tests, `backend.Shutdown()` is always called regardless of whether `Initialize()` succeeded. The `MiniAudioBackend::Shutdown()` implementation does check `m_initialized` before doing work, so calling `Shutdown()` on an uninitialized backend is safe and does not crash. However, the pattern is inconsistent with AC-1 tests which also call `Shutdown()` unconditionally but document the guard reason. This is not a bug -- just a documentation gap.
- **Suggested Fix:** No code change needed. Optionally add a brief comment: `// Shutdown() is safe even if Initialize() failed (m_initialized guard)`.

---

## ATDD Coverage

| ATDD Item | Status | Notes |
|-----------|--------|-------|
| AC-1: WAV mono loads | Covered | TEST_CASE at line 758 |
| AC-1: WAV stereo loads | Covered | TEST_CASE at line 787 |
| AC-1: MP3 loads | Covered | TEST_CASE at line 876 |
| AC-1: OGG Vorbis loads | Covered | TEST_CASE at line 971 |
| AC-2: WAV generated at runtime | Covered | `GenerateWavFile()` at line 63 |
| AC-2: MP3 embedded hex array | Covered | `WriteMP3File()` at line 127 (2551 bytes) |
| AC-2: OGG embedded hex array | Covered | `WriteOggFile()` at line 371 (3798 bytes) |
| AC-2: TempAudioDir RAII | Covered | Class at line 714 |
| AC-3: Non-existent file LoadSound | Covered | TEST_CASE at line 1070 |
| AC-3: Corrupt file LoadSound | Covered | TEST_CASE at line 1094 |
| AC-3: Non-existent file PlayMusic | Covered | TEST_CASE at line 1126 |
| AC-4: MP3 streaming PlayMusic | Covered | TEST_CASE at line 902 |
| AC-4: OGG streaming PlayMusic | Covered | TEST_CASE at line 998 |
| AC-5: WAV mono decoder | Covered | TEST_CASE at line 813 |
| AC-5: WAV stereo decoder | Covered | TEST_CASE at line 844 |
| AC-5: MP3 decoder | Covered | TEST_CASE at line 936 |
| AC-5: OGG decoder | Covered | TEST_CASE at line 1032 |
| AC-5: Pipeline contract | Covered | TEST_CASE at line 1150 |
| AC-6: Headless CI | Covered | TEST_CASE at line 1193 + all ma_decoder tests |
| AC-7: g_platformAudio independence | Covered | TEST_CASE at line 1221 |
| CMake: compiles on MinGW CI | **Not yet verified** | `[ ]` in ATDD -- requires CI build |

**ATDD Gap:** None. All checklist items marked `[x]` have corresponding test implementations. The one `[ ]` item (MinGW CI compilation) is expected -- it can only be verified by running the CI build, which is outside the scope of code review.

**ATDD Accuracy Warning:** The ATDD marks `SOUND_EXPAND_END - N indices used` as PASS, but `SOUND_EXPAND_END` does not exist in the codebase (see BLOCKER-1). This checklist item is inaccurate.

---

## Summary

| Severity | Count |
|----------|-------|
| BLOCKER | 1 |
| MEDIUM | 2 |
| LOW | 4 |
| **Total** | **7** |

The implementation is well-structured, thorough in AC coverage, and follows project conventions. The single blocker (undefined `SOUND_EXPAND_END`) is a straightforward fix (replace with `MAX_BUFFER`). The two MEDIUM issues (narrow-to-wide string conversion, fixed temp dir name) are low-risk in practice but should be addressed for robustness.
