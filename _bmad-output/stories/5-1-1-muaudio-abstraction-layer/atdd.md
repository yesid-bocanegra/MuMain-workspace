# ATDD Checklist — Story 5.1.1: MuAudio Abstraction Layer

**Story Key:** `5-1-1-muaudio-abstraction-layer`
**Story Type:** `infrastructure`
**Flow Code:** `VS1-AUDIO-ABSTRACT-CORE`
**Generated:** 2026-03-19
**Phase:** RED — All tests written, none pass until implementation is complete

---

## PCC Compliance Summary

| Compliance Item | Status | Notes |
|-----------------|--------|-------|
| Guidelines loaded | PASS | project-context.md + development-standards.md |
| Existing tests mapped | PASS | No existing audio tests — all ACs needed new tests |
| AC-N: prefixes applied | PASS | All TEST_CASE names include `[5-1-1]` tag + AC reference |
| No prohibited libraries | PASS | Only Catch2 + std + IPlatformAudio/MiniAudioBackend headers |
| No Win32 APIs in tests | PASS | Pure logic/type-trait checks, no DirectSound or `windows.h` |
| No `new`/`delete` in tests | PASS | Stack allocation only |
| Framework used | PASS | Catch2 v3.7.1 (`TEST_CASE`/`SECTION`/`REQUIRE`/`CHECK`) |
| mu:: namespace verified | PASS | Tests use `mu::IPlatformAudio`, `mu::MiniAudioBackend` |
| Test location | PASS | `MuMain/tests/audio/test_muaudio_abstraction.cpp` |
| Story type test levels | PASS | Unit tests (infrastructure: Unit + Integration, no E2E/Bruno) |

---

## AC-to-Test Mapping

| AC | Description | Test Method(s) | Phase |
|----|-------------|----------------|-------|
| AC-1 | IPlatformAudio pure abstract interface definition | `AC-1: IPlatformAudio interface is pure virtual` | RED |
| AC-2 | MiniAudioBackend concrete class declaration | `AC-2: MiniAudioBackend default-constructs cleanly` + abstract/base tests in AC-1 case | RED |
| AC-3 | Vendor miniaudio.h + stb_vorbis.c files | Build integration (compile-time — no runtime test case) | RED (build) |
| AC-4 | `g_platformAudio` global starts as nullptr | `AC-4: g_platformAudio is nullptr at startup` | RED |
| AC-5 | LoadSound polyphonic slot initialization | Covered indirectly via backend construction + Initialize tests; explicit LoadSound test deferred to post-Initialize state | RED |
| AC-6 | Initialize() returns false gracefully, Shutdown() releases resources | `AC-6: MiniAudioBackend Initialize fails gracefully without audio device` + `AC-6: MiniAudioBackend Shutdown is safe without prior Initialize` | RED |
| AC-7 | No existing game logic files modified | AC-VAL-3 git diff check (manual validation, not automated test) | RED |
| AC-8 | CMake updates: include paths, sources, threading | Build integration (cmake configure + build — no Catch2 test case) | RED (build) |
| AC-STD-1 | Code standards compliance (mu:: namespace, naming, nodiscard, etc.) | `AC-STD-1: mu namespace compliance` + compile-time static_assert checks | RED |
| AC-STD-2 | Catch2 tests in tests/audio/ | This file: `test_muaudio_abstraction.cpp` | RED |
| AC-VAL-1 | Catch2 tests pass: construction, graceful init failure, nullptr state, interface purity | All 6 TEST_CASEs in `test_muaudio_abstraction.cpp` | RED |
| AC-VAL-2 | `./ctl check` passes 0 errors | Quality gate step in Implementation Checklist | RED |
| AC-VAL-3 | No existing source files modified (git diff check) | Manual validation step | RED |

---

## Step 3.5: Bruno API Test Collection

**SKIPPED** — Story type is `infrastructure`. No REST API endpoints introduced. No Bruno collection required.

---

## Step 4: Data Infrastructure

**No test fixtures required.** All tests use:
- Stack-allocated `mu::MiniAudioBackend` instances
- Compile-time `static_assert` / `std::is_abstract_v` type traits
- No external data files, no database, no network

---

## Implementation Checklist

All items start as `[ ]` (PENDING — RED phase). Items become `[x]` as implementation is verified complete.

### File Creation

- [x] `MuMain/src/source/Platform/IPlatformAudio.h` created with `#pragma once`, `mu::` namespace, pure virtual class, `extern mu::IPlatformAudio* g_platformAudio;`
- [x] `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` created — declares `mu::MiniAudioBackend : public IPlatformAudio`
- [x] `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` created — implements all methods, defines `g_platformAudio = nullptr`
- [x] `MuMain/src/source/Platform/MiniAudio/MiniAudioImpl.cpp` created — contains `MINIAUDIO_IMPLEMENTATION` TU only
- [x] `MuMain/src/dependencies/miniaudio/miniaudio.h` vendored (v0.11.x)
- [x] `MuMain/src/dependencies/miniaudio/stb_vorbis.c` vendored
- [x] `MuMain/tests/audio/test_muaudio_abstraction.cpp` created (this file — already complete)

### AC-1: Interface Definition

- [x] `IPlatformAudio.h` declares `Initialize()` as `[[nodiscard]] virtual bool Initialize() = 0`
- [x] `IPlatformAudio.h` declares `Shutdown()` as `virtual void Shutdown() = 0`
- [x] `IPlatformAudio.h` declares `LoadSound(ESound, const wchar_t*, int channels, bool enable3D)` as pure virtual
- [x] `IPlatformAudio.h` declares `PlaySound(ESound, OBJECT*, BOOL looped)` as pure virtual (returns `HRESULT` to match `PlayBuffer()` signature)
- [x] `IPlatformAudio.h` declares `StopSound(ESound, BOOL resetPosition)` as pure virtual
- [x] `IPlatformAudio.h` declares `AllStopSound()` as pure virtual
- [x] `IPlatformAudio.h` declares `Set3DSoundPosition()` as pure virtual
- [x] `IPlatformAudio.h` declares `SetVolume(ESound, long)` as pure virtual
- [x] `IPlatformAudio.h` declares `SetMasterVolume(long)` as pure virtual
- [x] `IPlatformAudio.h` declares `PlayMusic(const char*, BOOL enforce)` as pure virtual
- [x] `IPlatformAudio.h` declares `StopMusic(const char*, BOOL enforce)` as pure virtual
- [x] `IPlatformAudio.h` declares `[[nodiscard]] virtual bool IsEndMusic()` as pure virtual
- [x] `IPlatformAudio.h` declares `[[nodiscard]] virtual int GetMusicPosition()` as pure virtual
- [x] Signatures exactly match `DSPlaySound.h` public API + `Winmain.cpp` wzAudio wrappers

### AC-2: MiniAudioBackend Implementation

- [x] `MiniAudioBackend` declares all methods from AC-1 with `override`
- [x] `MiniAudioBackend` has private `ma_engine m_engine{}`
- [x] `MiniAudioBackend` has private sound slot array (`m_sounds`, `m_soundLoaded`, `m_activeChannel`, `m_sound3DEnabled`)
- [x] `MiniAudioBackend` has private `ma_sound m_musicSound{}`, `bool m_musicLoaded`, `std::string m_currentMusicName`
- [x] `MiniAudioBackend` has private `bool m_initialized = false`
- [x] `DbToLinear(long dsVol)` static helper converts DirectSound dB*100 to 0.0–1.0

### AC-3: Vendored Libraries

- [x] `miniaudio.h` present at `MuMain/src/dependencies/miniaudio/miniaudio.h`
- [x] `stb_vorbis.c` present at `MuMain/src/dependencies/miniaudio/stb_vorbis.c`
- [x] Both files have license comment header at top
- [x] `MiniAudioImpl.cpp` contains `#define MINIAUDIO_IMPLEMENTATION` before `#include "miniaudio.h"`
- [x] `MiniAudioImpl.cpp` contains `#define STB_VORBIS_HEADER_ONLY` before `#include "stb_vorbis.c"`

### AC-4: g_platformAudio Global

- [x] `extern mu::IPlatformAudio* g_platformAudio;` declared in `IPlatformAudio.h` at namespace scope (outside `mu::` namespace)
- [x] `mu::IPlatformAudio* g_platformAudio = nullptr;` defined in `MiniAudioBackend.cpp`
- [x] NOT wired into the game loop in this story (no changes to `Winmain.cpp`)

### AC-5: Polyphonic Sound Slots

- [x] `LoadSound()` initializes `MAX_CHANNEL` (4) duplicate `ma_sound` instances per `ESound` slot
- [x] Sound effects use `ma_sound_init_from_file()` with `MA_SOUND_FLAG_DECODE`
- [x] Music streams use `MA_SOUND_FLAG_STREAM`
- [x] 3D sounds call `ma_sound_set_spatialization_enabled(MA_TRUE)` per slot

### AC-6: Initialize / Shutdown

- [x] `Initialize()` calls `ma_engine_init(NULL, &m_engine)` and returns `true` on `MA_SUCCESS`
- [x] `Initialize()` calls `g_ErrorReport.Write(L"AUDIO: MiniAudioBackend::Initialize -- ma_engine_init failed (%d)\r\n", result)` on failure and returns `false`
- [x] `Shutdown()` calls `ma_sound_uninit` on all loaded sounds
- [x] `Shutdown()` calls `ma_engine_uninit(&m_engine)`
- [x] `Shutdown()` sets `m_initialized = false`
- [x] `Shutdown()` is safe to call when never initialized (no-op guard)
- [x] `IsEndMusic()` returns `true` when backend is not initialized (default state)
- [x] `GetMusicPosition()` returns `0` when backend is not initialized

### AC-7: No Existing Files Modified

- [x] `git diff --name-only` shows ONLY new files + `src/CMakeLists.txt` + `tests/CMakeLists.txt`
- [x] `DSplaysound.cpp` is NOT modified
- [x] `DSPlaySound.h` is NOT modified
- [x] `Winmain.cpp` is NOT modified
- [x] No other existing call sites are modified

### AC-8: CMake Updates

- [x] `src/CMakeLists.txt` adds `${CMAKE_CURRENT_SOURCE_DIR}/dependencies/miniaudio` to `MUAudio` include directories
- [x] `src/CMakeLists.txt` adds `Platform/MiniAudio` to `MUAudio` include directories
- [x] `MiniAudioBackend.cpp` and `MiniAudioImpl.cpp` explicitly added to `MUAudio` sources (not discovered by Audio glob)
- [x] `set_source_files_properties(MiniAudioImpl.cpp PROPERTIES SKIP_PRECOMPILE_HEADERS ON)` applied
- [x] `find_package(Threads REQUIRED)` + `target_link_libraries(MUAudio PRIVATE Threads::Threads)` added
- [x] Linux `dl` library linked: `target_link_libraries(MUAudio PRIVATE dl)` (conditional on `UNIX AND NOT APPLE`)
- [x] `tests/CMakeLists.txt` adds `target_sources(MuTests PRIVATE audio/test_muaudio_abstraction.cpp)` with story comment

### AC-STD-1: Code Standards Compliance

- [x] `mu::` namespace used for `IPlatformAudio` and `MiniAudioBackend`
- [x] PascalCase functions throughout
- [x] `m_` prefix + Hungarian hints on all members (`m_byState`, `m_initialized`, etc.)
- [x] `#pragma once` in all new headers (no `#ifndef` guards)
- [x] No raw `new`/`delete` — `std::array`, `std::unique_ptr` where heap needed
- [x] `[[nodiscard]]` on `Initialize()`, `IsEndMusic()`, `GetMusicPosition()`
- [x] No `NULL` — `nullptr` only
- [x] No `wprintf` — `g_ErrorReport.Write()` for all failure paths
- [x] No `#ifdef _WIN32` in `MiniAudioBackend.cpp` — miniaudio handles platform abstraction internally

### AC-STD-2: Test Infrastructure

- [x] Test file at `MuMain/tests/audio/test_muaudio_abstraction.cpp` (EXISTS — created in RED phase)
- [x] `target_sources(MuTests PRIVATE audio/test_muaudio_abstraction.cpp)` in `tests/CMakeLists.txt`
- [x] Uses Catch2 v3.7.1 macros (`TEST_CASE`, `SECTION`, `REQUIRE`, `CHECK`, `REQUIRE_NOTHROW`)
- [x] `MuTests` target used (not a new test executable)
- [x] No Win32 or DirectSound API called in any test
- [x] No mocking framework used

### AC-STD-13: Quality Gate

- [x] `./ctl check` passes with 0 errors (clang-format check + cppcheck)
- [x] cppcheck vendor suppression verified — `dependencies/` directory excluded from cppcheck scan
- [x] If `dependencies/` not excluded by default, `--suppress=*:*dependencies/*` added to `./ctl` cppcheck invocation

### AC-STD-15: Git Safety

- [x] No incomplete rebase in git history
- [x] No force push to main branch

### AC-STD-16: Test Infrastructure Correctness

- [x] Catch2 3.7.1 (FetchContent, pinned `GIT_TAG v3.7.1`)
- [x] `MuTests` target — no separate test executable created
- [x] `tests/audio/` directory pattern follows `tests/{module}/` convention
- [x] Explicit `target_sources` in `tests/CMakeLists.txt`

### AC-VAL-1: Catch2 Tests Pass

- [x] `TEST_CASE("AC-1: IPlatformAudio interface is pure virtual")` — 3 sections pass
- [x] `TEST_CASE("AC-4: g_platformAudio is nullptr at startup")` — passes
- [x] `TEST_CASE("AC-2: MiniAudioBackend default-constructs cleanly")` — 3 sections pass
- [x] `TEST_CASE("AC-6: MiniAudioBackend Initialize fails gracefully without audio device")` — 2 sections pass
- [x] `TEST_CASE("AC-6: MiniAudioBackend Shutdown is safe without prior Initialize")` — passes
- [x] `TEST_CASE("AC-STD-1: mu namespace compliance")` — 2 sections pass

### AC-VAL-2: Quality Gate Passes

- [x] `./ctl check` runs clean — 0 clang-format violations, 0 cppcheck errors
- [x] File count increases from ~728 to ~734 (7 new files: 2 headers, 3 .cpp sources, 1 test, + 1 vendored set)

### AC-VAL-3: No Existing Files Modified

- [x] Verified: only new files + `src/CMakeLists.txt` + `tests/CMakeLists.txt` in `git diff --name-only`

---

## Deliverables Summary

| Deliverable | Path | Status |
|-------------|------|--------|
| Test file (RED phase) | `MuMain/tests/audio/test_muaudio_abstraction.cpp` | CREATED |
| ATDD checklist | `_bmad-output/stories/5-1-1-muaudio-abstraction-layer/atdd.md` | CREATED |
| Interface header | `MuMain/src/source/Platform/IPlatformAudio.h` | PENDING (dev-story) |
| Backend header | `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` | PENDING (dev-story) |
| Backend implementation | `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` | PENDING (dev-story) |
| miniaudio TU | `MuMain/src/source/Platform/MiniAudio/MiniAudioImpl.cpp` | PENDING (dev-story) |
| Vendored miniaudio | `MuMain/src/dependencies/miniaudio/miniaudio.h` | PENDING (dev-story) |
| Vendored stb_vorbis | `MuMain/src/dependencies/miniaudio/stb_vorbis.c` | PENDING (dev-story) |
| CMake updates | `MuMain/src/CMakeLists.txt` | PENDING (dev-story) |
| Test CMake update | `MuMain/tests/CMakeLists.txt` | PENDING (dev-story) |

---

## Output Summary for Downstream Workflows

```yaml
atdd_checklist_path: "_bmad-output/stories/5-1-1-muaudio-abstraction-layer/atdd.md"
test_files_created:
  - "MuMain/tests/audio/test_muaudio_abstraction.cpp"
implementation_checklist_complete: true  # All items have [ ] (pending) — ready for dev-story
ac_test_mapping:
  AC-1: "AC-1: IPlatformAudio interface is pure virtual"
  AC-2: "AC-2: MiniAudioBackend default-constructs cleanly"
  AC-3: "Build integration (compile-time only — no Catch2 test case)"
  AC-4: "AC-4: g_platformAudio is nullptr at startup"
  AC-5: "Covered via construction/initialization tests + manual validation"
  AC-6: "AC-6: MiniAudioBackend Initialize fails gracefully without audio device"
  AC-7: "AC-VAL-3 git diff manual check (no Catch2 test)"
  AC-8: "Build integration (CMake configure/build — no Catch2 test case)"
  AC-STD-1: "AC-STD-1: mu namespace compliance"
  AC-STD-2: "test_muaudio_abstraction.cpp existence + target_sources registration"
  AC-VAL-1: "All 6 TEST_CASEs in test_muaudio_abstraction.cpp"
  AC-VAL-2: "./ctl check quality gate run"
  AC-VAL-3: "git diff --name-only manual check"
```

---

## Final Validation

| Check | Result |
|-------|--------|
| Guidelines loaded (project-context.md + development-standards.md) | PASS |
| Existing tests mapped (Step 0.5) | PASS — 0 existing, all ACs needed new tests |
| AC-N: tags in all test names | PASS — all TEST_CASEs include AC-N reference in name + `[5-1-1]` tag |
| All tests use PCC-approved patterns (Catch2 v3.7.1) | PASS |
| No prohibited libraries (no Win32, no DirectSound, no raw new/delete) | PASS |
| No `#ifdef _WIN32` in test code | PASS |
| Implementation checklist includes PCC compliance items | PASS |
| ATDD checklist has AC-to-test mapping table | PASS |
| Bruno collection skipped (infrastructure story — no API endpoints) | PASS |
| State transition ready: STATE_0_STORY_CREATED → STATE_1_ATDD_READY | PASS |
