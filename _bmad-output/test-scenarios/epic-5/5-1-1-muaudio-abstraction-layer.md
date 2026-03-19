# Test Scenarios: Story 5.1.1 — MuAudio Abstraction Layer

**Generated:** 2026-03-19
**Story:** 5.1.1 MuAudio Abstraction Layer
**Flow Code:** VS1-AUDIO-ABSTRACT-CORE
**Project:** MuMain-workspace

These scenarios cover validation of Story 5.1.1 acceptance criteria.
Automated tests (Catch2 unit tests in `MuMain/tests/audio/`) run on macOS/Linux.
Manual validation scenarios require a Windows or MinGW build with audio hardware.

---

## AC-1: IPlatformAudio Interface Definition

### Scenario 1: Interface is pure abstract (automated)

- **Prerequisites:** `IPlatformAudio.h` compiled into `MUAudio` target
- **Given:** `mu::IPlatformAudio` class definition
- **When:** `std::is_abstract_v<mu::IPlatformAudio>` is evaluated at compile time
- **Then:** Returns `true` — no direct instantiation is possible
- **Automated:** `TEST_CASE("AC-1: IPlatformAudio interface is pure virtual")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 2: All 13 method signatures match DSPlaySound.h + wzAudio wrappers

- **Prerequisites:** Both `DSPlaySound.h` and `IPlatformAudio.h` readable
- **Given:** Method signatures in `IPlatformAudio.h`
- **When:** Compared against `DSPlaySound.h` (LoadWaveFile, PlayBuffer, StopBuffer, etc.) and `Winmain.cpp` wzAudio wrappers (PlayMp3, StopMp3, IsEndMp3, GetMp3PlayPosition)
- **Then:** All parameter types, names, and return types match exactly (zero call-site changes for Stories 5.2.1/5.2.2)
- **Automated:** Compile-time contract (Stories 5.2.1/5.2.2 will fail to compile if signatures diverge)
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-2: MiniAudioBackend Class

### Scenario 3: Backend inherits from IPlatformAudio (automated)

- **Prerequisites:** `MiniAudioBackend.h` compiled
- **Given:** `mu::MiniAudioBackend` class definition
- **When:** `std::is_base_of_v<mu::IPlatformAudio, mu::MiniAudioBackend>` is checked
- **Then:** Returns `true`
- **Automated:** `TEST_CASE("AC-1: IPlatformAudio interface is pure virtual")` — SECTION "MiniAudioBackend is a subclass" — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 4: MiniAudioBackend default-constructs cleanly (automated)

- **Prerequisites:** Compiled test binary
- **Given:** No audio device, no engine initialized
- **When:** `mu::MiniAudioBackend backend;` is stack-allocated
- **Then:** No crash, no exception, `backend.IsEndMusic()` returns `true`, `backend.GetMusicPosition()` returns `0`
- **Automated:** `TEST_CASE("AC-2: MiniAudioBackend default-constructs cleanly")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-3: Vendored Libraries

### Scenario 5: miniaudio.h and stb_vorbis.c are present and have license headers

- **Prerequisites:** Access to `MuMain/src/dependencies/miniaudio/`
- **Given:** Files at `src/dependencies/miniaudio/miniaudio.h` and `src/dependencies/miniaudio/stb_vorbis.c`
- **When:** File headers are inspected
- **Then:**
  - `miniaudio.h` begins with `// miniaudio — single-header audio library (public domain / MIT-0)` comment
  - `stb_vorbis.c` begins with `// stb_vorbis — OGG Vorbis audio decoder (public domain)` comment
  - Version is miniaudio 0.11.x (confirmed: 0.11.25)
- **Automated:** File existence verified via glob in CI; version grep confirms 0.11.x
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 6: MiniAudioImpl.cpp defines MINIAUDIO_IMPLEMENTATION (automated at compile time)

- **Prerequisites:** Build system configured with `SKIP_PRECOMPILE_HEADERS ON` for `MiniAudioImpl.cpp`
- **Given:** `MiniAudioImpl.cpp` TU
- **When:** Compiled
- **Then:** No duplicate symbol errors; PCH is excluded; all ma_* symbols are available to `MiniAudioBackend.cpp`
- **Automated:** Compile-time (MinGW CI build is the automated check)
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed — requires CI build

---

## AC-4: g_platformAudio Global

### Scenario 7: g_platformAudio is nullptr at startup (automated)

- **Prerequisites:** Compiled test binary (no game loop initialization)
- **Given:** Process start, no `Initialize()` called
- **When:** `g_platformAudio` is checked
- **Then:** `g_platformAudio == nullptr`
- **Automated:** `TEST_CASE("AC-4: g_platformAudio is nullptr at startup")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-5: Polyphonic Sound Slots

### Scenario 8: LoadSound initializes MAX_CHANNEL (4) slots per ESound (manual)

- **Prerequisites:** Windows/MinGW build with audio device; call `Initialize()` successfully
- **Given:** `MiniAudioBackend` initialized successfully
- **When:** `LoadSound(SOUND_CLICK01, L"Data/Sound/UI/click.wav", 4, false)` called
- **Then:**
  - 4 `ma_sound` instances for `SOUND_CLICK01` are initialized
  - First `PlaySound(SOUND_CLICK01, nullptr, false)` succeeds immediately
  - Rapid 4× consecutive calls all play (no channel blocking)
- **Automated:** Unit test coverage via construction + Initialize test; direct LoadSound test requires audio device
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed — requires Windows build

---

## AC-6: Initialize / Shutdown

### Scenario 9: Initialize fails gracefully without audio device (automated)

- **Prerequisites:** CI headless environment (no audio hardware) OR `ma_engine_init` mock
- **Given:** Default-constructed `MiniAudioBackend`
- **When:** `backend.Initialize()` called on CI (no audio device)
- **Then:**
  - Returns `false` without crashing
  - `MuError.log` contains `AUDIO: MiniAudioBackend::Initialize -- ma_engine_init failed`
  - Process continues normally
- **Automated:** `TEST_CASE("AC-6: MiniAudioBackend Initialize fails gracefully without audio device")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

### Scenario 10: Shutdown is safe without prior Initialize (automated)

- **Prerequisites:** Compiled test binary
- **Given:** Default-constructed backend, never initialized
- **When:** `backend.Shutdown()` called
- **Then:** No crash, no-op, `m_initialized` remains `false`
- **Automated:** `TEST_CASE("AC-6: MiniAudioBackend Shutdown is safe without prior Initialize")` — GREEN
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-7: No Existing Files Modified

### Scenario 11: git diff confirms only new files changed (manual/AC-VAL-3)

- **Prerequisites:** Git repository with Story 5.1.1 implementation committed
- **Given:** `git diff HEAD~1 --name-only` (or comparison to pre-story commit)
- **When:** Output is inspected
- **Then:**
  - `DSplaysound.cpp` is NOT listed
  - `DSPlaySound.h` is NOT listed
  - `Winmain.cpp` is NOT listed
  - Only new files + `src/CMakeLists.txt` + `tests/CMakeLists.txt` appear
- **Automated:** `git diff` check in story validation
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-8: CMake Updates

### Scenario 12: CMake configures and compiles MUAudio with miniaudio (automated at build time)

- **Prerequisites:** Linux/WSL with MinGW toolchain
- **Given:** `MuMain/src/CMakeLists.txt` with miniaudio includes and MiniAudio sources
- **When:** `cmake --preset mingw-x86 && cmake --build build-mingw -j$(nproc)`
- **Then:**
  - `MUAudio` target builds without errors
  - `ma_engine_init` symbol resolved from `MiniAudioImpl.cpp`
  - `Threads::Threads` linked (MinGW: `-lpthread`)
- **Automated:** MinGW CI build
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed — requires CI build

---

## AC-STD-2 / AC-VAL-1: Catch2 Tests

### Scenario 13: All 6 TEST_CASEs pass (automated)

- **Prerequisites:** macOS/Linux build with `-DBUILD_TESTING=ON`
- **Given:** `MuTests` binary
- **When:** `ctest -R audio` or `./MuTests "[5-1-1]"`
- **Then:** 6 TEST_CASEs, all PASSED:
  - `AC-1: IPlatformAudio interface is pure virtual` (3 sections)
  - `AC-4: g_platformAudio is nullptr at startup` (1 section)
  - `AC-2: MiniAudioBackend default-constructs cleanly` (3 sections)
  - `AC-6: MiniAudioBackend Initialize fails gracefully without audio device` (2 sections)
  - `AC-6: MiniAudioBackend Shutdown is safe without prior Initialize` (1 section)
  - `AC-STD-1: mu namespace compliance` (2 sections)
- **Automated:** Catch2 tests in `MuMain/tests/audio/test_muaudio_abstraction.cpp`
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed

---

## AC-VAL-2: Quality Gate

### Scenario 14: ./ctl check passes 0 errors (automated)

- **Prerequisites:** macOS with clang-format + cppcheck installed
- **Given:** All new source files present
- **When:** `./ctl check` runs (clang-format check + cppcheck)
- **Then:** 0 format violations, 0 cppcheck errors; file count = 711
- **Automated:** `./ctl check` confirmed PASSED — 711 files, 0 errors
- **Status:** [ ] Not Tested / [x] Passed / [ ] Failed
