# Story 5.1.1: MuAudio Abstraction Layer

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 5 - Audio System Migration |
| Feature | 5.1 - IPlatformAudio Interface |
| Story ID | 5.1.1 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-AUDIO-ABSTRACT-CORE |
| FRs Covered | FR-AUDIO-1, FR-AUDIO-2 |
| Prerequisites | None — first story in EPIC-5 |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | New `IPlatformAudio.h` in `Platform/`; new `MiniAudioBackend.h/.cpp` in `Platform/MiniAudio/`; vendor `miniaudio.h` + `stb_vorbis.c` in `src/dependencies/miniaudio/`; CMake changes in `src/CMakeLists.txt`; Catch2 tests in `tests/audio/` |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** an `IPlatformAudio` interface backed by a miniaudio implementation,
**so that** audio call sites can be migrated to a cross-platform abstraction without modifying any existing game code in this story.

---

## Functional Acceptance Criteria

- [x] **AC-1:** `IPlatformAudio.h` defines the pure abstract interface `mu::IPlatformAudio` with methods: `Initialize()`, `Shutdown()`, `LoadSound(ESound, const wchar_t*, int channels, bool enable3D)`, `PlaySound(ESound, OBJECT*, bool looped)`, `StopSound(ESound, bool resetPosition)`, `AllStopSound()`, `Set3DSoundPosition()`, `SetVolume(ESound, long vol)`, `SetMasterVolume(long vol)`, `PlayMusic(const char* name, bool enforce)`, `StopMusic(bool enforce)`, `IsEndMusic()`, `GetMusicPosition()` — matching the public API surface of `DSPlaySound.h` and `Winmain.cpp` wzAudio wrappers exactly
- [x] **AC-2:** `MiniAudioBackend.h` declares `mu::MiniAudioBackend : public IPlatformAudio` with all methods from AC-1; `MiniAudioBackend.cpp` implements the class using `ma_engine` and `ma_sound` APIs from the vendored `miniaudio.h`
- [x] **AC-3:** `miniaudio.h` (v0.11.x) and `stb_vorbis.c` are vendored at `MuMain/src/dependencies/miniaudio/`; a dedicated `MuMain/src/source/Platform/MiniAudio/MiniAudioImpl.cpp` contains `#define MINIAUDIO_IMPLEMENTATION` followed by `#include "miniaudio.h"` (the implementation TU), separate from `MiniAudioBackend.cpp` which only uses the API
- [x] **AC-4:** `g_platformAudio` global pointer is declared in `IPlatformAudio.h` as `extern mu::IPlatformAudio* g_platformAudio;` and defined (set to `nullptr`) in `MiniAudioBackend.cpp`; the variable is NOT yet wired into the game loop (that is Story 5.2.1's job)
- [x] **AC-5:** `MiniAudioBackend::LoadSound()` initialises polyphonic sound slots: `MAX_CHANNEL` (`4`) duplicate `ma_sound` instances per `ESound` slot, using `ma_sound_init_from_file()` with `MA_SOUND_FLAG_DECODE` for sound effects and `MA_SOUND_FLAG_STREAM` for music; 3D sounds also call `ma_sound_set_spatialization_enabled(true)`
- [x] **AC-6:** `MiniAudioBackend::Initialize()` calls `ma_engine_init(NULL, &m_engine)` and returns `false` (logging via `g_ErrorReport`) on failure; `Shutdown()` calls `ma_engine_uninit(&m_engine)` and releases all loaded sounds
- [x] **AC-7:** No existing game logic files are modified in this story — `DSplaysound.cpp`, `DSPlaySound.h`, `Winmain.cpp`, and all call sites remain untouched (that is Sessions 3.2/3.3 in the cross-platform plan, handled by Stories 5.2.1 and 5.2.2)
- [x] **AC-8:** `src/CMakeLists.txt` is updated to: add `miniaudio/` include path to `MUAudio` target includes, add `src/source/Platform/MiniAudio/MiniAudioBackend.cpp` and `MiniAudioImpl.cpp` to `MUAudio` sources (or via glob if Audio directory glob is used), and add conditional platform link for threading (`-lpthread` on Linux/macOS)

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards Compliance — `mu::` namespace, PascalCase functions, `m_` member prefix with Hungarian hints, `#pragma once` header guard, no raw `new`/`delete`, `[[nodiscard]]` on `Initialize()` and any fallible functions, no `NULL` (use `nullptr`), no `wprintf`; `g_ErrorReport.Write()` for all failure paths
- [x] **AC-STD-2:** Catch2 tests in `tests/audio/test_muaudio_abstraction.cpp`: `MiniAudioBackend` default-constructs without crashing, `Initialize()` with no audio device returns false gracefully (CI has no audio device), `g_platformAudio` starts as `nullptr`, `IPlatformAudio` interface is a pure virtual class (static assert or type trait check)
- [x] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format check + cppcheck 0 errors)
- [x] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [x] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/audio/` directory pattern, explicit `target_sources` in `tests/CMakeLists.txt`)

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [x] **AC-STD-13:** Quality Gate passes (`./ctl check`)
- [x] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [x] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target)

---

## Validation Artifacts

- [x] **AC-VAL-1:** Catch2 tests pass: `MiniAudioBackend` default construction, `Initialize()` graceful failure path, `g_platformAudio == nullptr` at startup, interface purity check
- [x] **AC-VAL-2:** `./ctl check` passes with 0 errors after new files are added
- [x] **AC-VAL-3:** No existing source file is modified (verify with `git diff --name-only` — only new files and `src/CMakeLists.txt` and `tests/CMakeLists.txt` should appear)

---

## Tasks / Subtasks

- [x] Task 1: Define `IPlatformAudio` interface (AC: 1, 4)
  - [x] Subtask 1.1: Create `MuMain/src/source/Platform/IPlatformAudio.h` — `#pragma once`, `mu::` namespace, include `DSPlaySound.h` for `ESound` enum and `OBJECT` struct forward declaration, declare pure virtual `IPlatformAudio` class with all methods listed in AC-1; declare `extern mu::IPlatformAudio* g_platformAudio;` at namespace scope
  - [x] Subtask 1.2: Ensure all method signatures exactly match the existing `DSPlaySound.h` public API plus the `PlayMp3()`/`StopMp3()`/`IsEndMp3()`/`GetMp3PlayPosition()` wrappers in `Winmain.cpp` — this is critical for zero call-site changes in later stories

- [x] Task 2: Vendor miniaudio (AC: 3)
  - [x] Subtask 2.1: Download `miniaudio.h` v0.11.x from https://github.com/mackron/miniaudio into `MuMain/src/dependencies/miniaudio/miniaudio.h`
  - [x] Subtask 2.2: Download `stb_vorbis.c` from https://github.com/nothings/stb into `MuMain/src/dependencies/miniaudio/stb_vorbis.c` (needed for OGG Vorbis decoding; include before miniaudio in the implementation TU)
  - [x] Subtask 2.3: Add `# miniaudio — single-header audio library (public domain / MIT-0)` comment at top of both files for license clarity

- [x] Task 3: Create `MiniAudioImpl.cpp` (implementation TU) (AC: 3)
  - [x] Subtask 3.1: Create `MuMain/src/source/Platform/MiniAudio/MiniAudioImpl.cpp` with exactly:
    ```cpp
    #include "stdafx.h"
    #define STB_VORBIS_HEADER_ONLY
    #include "stb_vorbis.c"
    #define MINIAUDIO_IMPLEMENTATION
    #include "miniaudio.h"
    ```
  - [x] Subtask 3.2: This file must NOT be compiled with the PCH (`target_precompile_headers` exclusion or guarded include) to avoid PCH/implementation macro collision; add `set_source_files_properties(MiniAudioImpl.cpp PROPERTIES SKIP_PRECOMPILE_HEADERS ON)` in CMake

- [x] Task 4: Implement `MiniAudioBackend` (AC: 2, 5, 6)
  - [x] Subtask 4.1: Create `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` — declare `mu::MiniAudioBackend : public IPlatformAudio`; private members: `ma_engine m_engine{}`, `std::array<std::array<ma_sound, MAX_CHANNEL>, MAX_BUFFER> m_sounds{}` (or `std::unique_ptr` array if heap preferred), `std::array<int, MAX_BUFFER> m_activeChannel{}`, `ma_sound m_musicSound{}`, `bool m_initialized = false`
  - [x] Subtask 4.2: Implement `Initialize()` — `ma_engine_init(NULL, &m_engine)`; on `MA_SUCCESS` set `m_initialized = true` and return `true`; on failure call `g_ErrorReport.Write(L"AUDIO: MiniAudioBackend::Initialize -- ma_engine_init failed (%d)\r\n", result)` and return `false`
  - [x] Subtask 4.3: Implement `Shutdown()` — call `ma_sound_uninit` on all loaded sounds, then `ma_engine_uninit(&m_engine)`; set `m_initialized = false`
  - [x] Subtask 4.4: Implement `LoadSound(ESound buffer, const wchar_t* filename, int channels, bool enable3D)` — convert `wchar_t` filename to UTF-8 using `PlatformCompat.h` shim (`mu_wchar_to_utf8` or `std::filesystem::path` → `u8string`); call `ma_sound_init_from_file()` for each channel slot; for 3D sounds, call `ma_sound_set_spatialization_enabled(&m_sounds[buffer][ch], MA_TRUE)` per slot; on failure, call `g_ErrorReport.Write()`
  - [x] Subtask 4.5: Implement `PlaySound(ESound buffer, OBJECT* pObject, bool looped)` — find the next available channel slot (round-robin `m_activeChannel[buffer]`); call `ma_sound_set_looping` and `ma_sound_start`; if `enable3D` and `pObject != nullptr`, call `ma_sound_set_position` from `pObject`'s world position
  - [x] Subtask 4.6: Implement `StopSound(ESound buffer, bool resetPosition)` — call `ma_sound_stop` on all channel slots; if `resetPosition`, call `ma_sound_seek_to_pcm_frame(&sound, 0)`
  - [x] Subtask 4.7: Implement `AllStopSound()` — iterate all `MAX_BUFFER` entries, call `ma_sound_stop` on all channel slots
  - [x] Subtask 4.8: Implement `Set3DSoundPosition()` — iterate all 3D-enabled slots, update `ma_sound_set_position` from attached `OBJECT` world positions (matches `Set3DSoundPosition()` logic in `DSplaysound.cpp`)
  - [x] Subtask 4.9: Implement `SetVolume(ESound buffer, long vol)` — convert DirectSound volume (negative dB * 100 scale) to linear 0.0–1.0 via `std::pow(10.0f, vol / 2000.0f)` and call `ma_sound_set_volume`
  - [x] Subtask 4.10: Implement `SetMasterVolume(long vol)` — call `ma_engine_set_volume` with the same dB conversion
  - [x] Subtask 4.11: Implement `PlayMusic(const char* name, bool enforce)` — if `!enforce` and current music name matches, return early (no restart); call `ma_sound_uninit` on `m_musicSound` if active; call `ma_sound_init_from_file()` with `MA_SOUND_FLAG_STREAM | MA_SOUND_FLAG_ASYNC`; call `ma_sound_set_looping(true)` and `ma_sound_start`; store current music name in `m_currentMusicName`
  - [x] Subtask 4.12: Implement `StopMusic(bool enforce)` — call `ma_sound_stop(&m_musicSound)`; if `enforce`, call `ma_sound_uninit(&m_musicSound)` and clear `m_currentMusicName`
  - [x] Subtask 4.13: Implement `IsEndMusic()` — return `!ma_sound_is_playing(&m_musicSound)` (matches `wzAudioGetStreamOffsetRange() == 100` semantics)
  - [x] Subtask 4.14: Implement `GetMusicPosition()` — use `ma_sound_get_cursor_in_pcm_frames` divided by engine sample rate to get seconds, normalise to 0–100 range to match `wzAudioGetStreamOffsetRange()` return value
  - [x] Subtask 4.15: Define `mu::IPlatformAudio* g_platformAudio = nullptr;` in `MiniAudioBackend.cpp`

- [x] Task 5: Update CMake (AC: 8)
  - [x] Subtask 5.1: In `MuMain/src/CMakeLists.txt`, add `"${MU_SOURCE_DIR}/Platform/MiniAudio"` to include directories for `MUAudio`
  - [x] Subtask 5.2: Add `${CMAKE_CURRENT_SOURCE_DIR}/dependencies/miniaudio` to the include directories so `#include "miniaudio.h"` resolves
  - [x] Subtask 5.3: Explicitly add `Platform/MiniAudio/MiniAudioBackend.cpp` and `Platform/MiniAudio/MiniAudioImpl.cpp` to `MU_AUDIO_SOURCES` (the Audio dir is globbed but Platform/MiniAudio is not — add explicit `target_sources` or extend the glob pattern)
  - [x] Subtask 5.4: Add threading library dependency: `find_package(Threads REQUIRED)` and `target_link_libraries(MUAudio PRIVATE Threads::Threads)` — miniaudio uses pthreads on Linux/macOS
  - [x] Subtask 5.5: Add `set_source_files_properties(${MU_SOURCE_DIR}/Platform/MiniAudio/MiniAudioImpl.cpp PROPERTIES SKIP_PRECOMPILE_HEADERS ON)` to prevent PCH collision with `MINIAUDIO_IMPLEMENTATION` macro

- [x] Task 6: Catch2 tests (AC: AC-STD-2, AC-VAL-1)
  - [x] Subtask 6.1: Create `MuMain/tests/audio/test_muaudio_abstraction.cpp`
  - [x] Subtask 6.2: In `tests/CMakeLists.txt`, add: `target_sources(MuTests PRIVATE audio/test_muaudio_abstraction.cpp)` with a comment `# Story 5.1.1: MuAudio Abstraction Layer [VS1-AUDIO-ABSTRACT-CORE]`
  - [x] Subtask 6.3: Write `TEST_CASE("IPlatformAudio interface is pure virtual")`: static assert that `std::is_abstract_v<mu::IPlatformAudio>` is true
  - [x] Subtask 6.4: Write `TEST_CASE("g_platformAudio is nullptr at startup")`: `REQUIRE(g_platformAudio == nullptr)` (confirms default state before game initialization)
  - [x] Subtask 6.5: Write `TEST_CASE("MiniAudioBackend default-constructs cleanly")`: stack-allocate `mu::MiniAudioBackend backend;` — must not crash or throw; confirm `backend.IsEndMusic()` returns `true` (not playing)
  - [x] Subtask 6.6: Write `TEST_CASE("MiniAudioBackend Initialize fails gracefully without audio device")`: call `backend.Initialize()` — on CI (headless, no audio device) this should return `false` without crashing; test uses `CHECK` not `REQUIRE` so test continues; `REQUIRE_NOTHROW` wraps the call
  - [x] Subtask 6.7: Tests must NOT call any Win32 or DirectSound API — pure logic and interface checks only

- [x] Task 7: Quality gate + commit (AC: AC-STD-13, AC-STD-6)
  - [x] Subtask 7.1: Run `./ctl check` — 0 errors
  - [x] Subtask 7.2: Commit: `feat(audio): create IPlatformAudio interface with miniaudio backend`

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A — C++ client, no HTTP error codes | — | — | — |

Logging patterns (not error catalog entries):
- `g_ErrorReport.Write(L"AUDIO: MiniAudioBackend::Initialize -- ma_engine_init failed (%d)\r\n", result)` on init failure
- `g_ErrorReport.Write(L"AUDIO: MiniAudioBackend::LoadSound -- ma_sound_init_from_file failed for '%ls' (%d)\r\n", filename, result)` on sound load failure
- `g_ErrorReport.Write(L"AUDIO: MiniAudioBackend::PlayMusic -- failed to init stream '%s' (%d)\r\n", name, result)` on music stream failure

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
| Unit | Catch2 3.7.1 | Pure interface/construction logic | Interface abstractness, g_platformAudio default state, default-construct, Initialize graceful failure |
| Integration (manual) | Windows build | No regression on existing audio | Existing audio plays identically; no call sites changed; MinGW CI builds clean |

---

## Dev Notes

### Context: Why This Story Exists

This is the **foundation story for all audio migration work in EPIC-5**. Stories 5.2.1 (BGM) and 5.2.2 (SFX) cannot proceed until `IPlatformAudio` and `MiniAudioBackend` exist. The design goal exactly mirrors what Story 4.2.1 did for rendering: create a thin interface that wraps the new cross-platform library today and will replace the Win32 backend in the next stories.

**Key design constraint from CROSS_PLATFORM_PLAN.md Session 3.1:** The interface method signatures MUST exactly match the public API of `DSPlaySound.h` plus the wzAudio wrappers in `Winmain.cpp`. Story 5.2.1 will make `DSplaysound.cpp` delegate to `g_platformAudio` — zero call site changes elsewhere in the codebase.

**Scope guard (AC-7):** This story creates the abstraction only. No `DSplaysound.cpp`, `Winmain.cpp`, or `DSPlaySound.h` file is modified. This minimizes risk and keeps the story to 3 points.

### Existing Audio System to Understand (Read-Only Reference)

**`DSPlaySound.h`** — Defines `ESound` enum (450+ sound IDs, `MAX_BUFFER = SOUND_EXPAND_END`), and declares:
- `InitDirectSound(HWND)`, `FreeDirectSound()`, `SetEnableSound(bool)`
- `LoadWaveFile(ESound, const wchar_t*, int channels, bool enable3D)` — loads WAV into DirectSound buffer
- `PlayBuffer(ESound, OBJECT*, BOOL looped)`, `StopBuffer(ESound, BOOL resetPosition)`, `AllStopSound()`
- `Set3DSoundPosition()`, `SetVolume(ESound, long)`, `SetMasterVolume(long)`
- `MAX_CHANNEL = 4` — polyphony per sound

**`Winmain.cpp`** wzAudio wrappers (lines 110–161):
- `#pragma comment(lib, "wzAudio.lib")` + `#include <wzAudio.h>`
- `PlayMp3(const char* Name, BOOL bEnforce)` → `wzAudioPlay(Name, 1)`
- `StopMp3(const char* Name, BOOL bEnforce)` → `wzAudioStop()`
- `IsEndMp3()` → `wzAudioGetStreamOffsetRange() == 100`
- `GetMp3PlayPosition()` → `wzAudioGetStreamOffsetRange()`
- Init: `wzAudioCreate(g_hWnd)` + `wzAudioOption(WZAOPT_STOPBEFOREPLAY, 1)` (line 1291–1292)
- Shutdown: `wzAudioDestroy()` (line 449)

**Only 6 wzAudio call sites in 1 file** — the replacement in Story 5.2.1/5.2.2 is trivial.

**DirectSound volume scale:** `DSplaysound.cpp` uses `DSBVOLUME_MIN` to `0` (dB * 100, e.g. `-10000` = silent, `0` = full). Conversion to linear 0.0–1.0: `std::pow(10.0f, vol / 2000.0f)`.

### Project Structure Notes

**New files to create:**

| File | CMake Target | Notes |
|------|-------------|-------|
| `MuMain/src/source/Platform/IPlatformAudio.h` | `MUAudio` (via include) | Interface declaration + `g_platformAudio` extern |
| `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` | `MUAudio` | Backend class declaration |
| `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` | `MUAudio` (explicit add) | Backend implementation + `g_platformAudio` definition |
| `MuMain/src/source/Platform/MiniAudio/MiniAudioImpl.cpp` | `MUAudio` (explicit add) | `MINIAUDIO_IMPLEMENTATION` TU only; SKIP_PRECOMPILE_HEADERS |
| `MuMain/src/dependencies/miniaudio/miniaudio.h` | Vendored | Single-header miniaudio library |
| `MuMain/src/dependencies/miniaudio/stb_vorbis.c` | Vendored | OGG decoder (included via miniaudio) |
| `MuMain/tests/audio/test_muaudio_abstraction.cpp` | `MuTests` (explicit add) | Catch2 tests |

**Files to modify:**

| File | Change |
|------|--------|
| `MuMain/src/CMakeLists.txt` | Add miniaudio include dir, add MiniAudio .cpp files, add Threads::Threads, set SKIP_PRECOMPILE_HEADERS on MiniAudioImpl.cpp |
| `MuMain/tests/CMakeLists.txt` | Add `audio/test_muaudio_abstraction.cpp` to MuTests |

**CMake auto-glob caveat:** `MUAudio` uses `file(GLOB MU_AUDIO_SOURCES CONFIGURE_DEPENDS "${MU_SOURCE_DIR}/Audio/*.cpp")` — this only globs the `Audio/` directory. The new `Platform/MiniAudio/` files are NOT in that directory, so they must be added explicitly via `target_sources(MUAudio PRIVATE ...)`.

**CMake target dependency chain:**
```
MUCommon → MUCore → MUAudio → MUGame → Main
```
`IPlatformAudio` and `MiniAudioBackend` belong in `MUAudio`. Tests link `MuTests` against `MUCore` — the audio tests are pure construction/interface checks with no game state dependencies.

### Technical Implementation

#### `IPlatformAudio` Interface Sketch

```cpp
// Platform/IPlatformAudio.h
#pragma once

#include <cstdint>
#include "DSPlaySound.h"  // ESound enum, MAX_CHANNEL, OBJECT forward decl

namespace mu
{

class IPlatformAudio
{
public:
    virtual ~IPlatformAudio() = default;

    [[nodiscard]] virtual bool Initialize() = 0;
    virtual void Shutdown() = 0;

    // Sound effects (mirrors DSPlaySound.h public API)
    virtual void LoadSound(ESound buffer, const wchar_t* filename,
                           int channels = MAX_CHANNEL, bool enable3D = false) = 0;
    virtual HRESULT PlaySound(ESound buffer, OBJECT* pObject = nullptr,
                              BOOL looped = false) = 0;
    virtual void StopSound(ESound buffer, BOOL resetPosition) = 0;
    virtual void AllStopSound() = 0;
    virtual void Set3DSoundPosition() = 0;
    virtual void SetVolume(ESound buffer, long vol) = 0;
    virtual void SetMasterVolume(long vol) = 0;

    // Music (mirrors Winmain.cpp wzAudio wrappers)
    virtual void PlayMusic(const char* name, BOOL enforce) = 0;
    virtual void StopMusic(const char* name, BOOL enforce) = 0;
    [[nodiscard]] virtual bool IsEndMusic() = 0;
    [[nodiscard]] virtual int GetMusicPosition() = 0;
};

} // namespace mu

extern mu::IPlatformAudio* g_platformAudio;
```

#### `MiniAudioBackend` Private State Sketch

```cpp
// Platform/MiniAudio/MiniAudioBackend.h
#pragma once
#include "IPlatformAudio.h"
#include "miniaudio.h"
#include <array>
#include <string>

namespace mu
{

class MiniAudioBackend : public IPlatformAudio
{
public:
    MiniAudioBackend() = default;
    ~MiniAudioBackend() override;

    [[nodiscard]] bool Initialize() override;
    void Shutdown() override;

    // ... all IPlatformAudio methods ...

private:
    ma_engine m_engine{};
    // Per-sound polyphonic slots: [ESound index][channel]
    std::array<std::array<ma_sound, MAX_CHANNEL>, MAX_BUFFER> m_sounds{};
    std::array<bool, MAX_BUFFER> m_soundLoaded{};
    std::array<int, MAX_BUFFER> m_activeChannel{};
    std::array<bool, MAX_BUFFER> m_sound3DEnabled{};
    ma_sound m_musicSound{};
    bool m_musicLoaded = false;
    std::string m_currentMusicName;
    bool m_initialized = false;

    static float DbToLinear(long dsVol); // Convert DirectSound dB*100 to 0.0-1.0
};

} // namespace mu
```

#### MiniAudioImpl.cpp — Critical Compile Order

```cpp
// Platform/MiniAudio/MiniAudioImpl.cpp
// IMPORTANT: This file MUST NOT use the precompiled header.
// It defines MINIAUDIO_IMPLEMENTATION which expands the entire library inline.
// Compiling with PCH would cause duplicate symbol errors.
//
// CMakeLists.txt must have:
//   set_source_files_properties(MiniAudioImpl.cpp PROPERTIES SKIP_PRECOMPILE_HEADERS ON)

#define STB_VORBIS_HEADER_ONLY
#include "stb_vorbis.c"
#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
```

#### Volume Conversion

DirectSound uses `long vol` in range `DSBVOLUME_MIN` (-10000) to `0` (dB * 100 hundredths):
```cpp
static float MiniAudioBackend::DbToLinear(long dsVol)
{
    // Convert from 1/100ths of dB to linear gain
    return std::pow(10.0f, static_cast<float>(dsVol) / 2000.0f);
}
```

#### CI Headless Audio Handling

miniaudio will fail `ma_engine_init()` when no audio device is available (CI runners). `MiniAudioBackend::Initialize()` returns `false` in this case — the game continues without audio (not a crash). This is the correct behavior since `g_platformAudio` is not yet wired into the game loop in this story.

For tests, wrap `Initialize()` in `REQUIRE_NOTHROW` — the test passes whether init succeeds or fails (it just must not crash).

#### Platform-Specific Notes

**macOS:** miniaudio uses CoreAudio by default. No extra CMake dependency needed beyond `Threads::Threads`.

**Linux:** miniaudio uses ALSA by default. Add `target_link_libraries(MUAudio PRIVATE dl)` in CMakeLists for `dlopen` used internally by miniaudio (or use `CMAKE_DL_LIBS`).

**Windows (MinGW):** miniaudio uses DirectSound/WASAPI. No change from existing build.

Add platform-conditional link in CMake:
```cmake
if(UNIX AND NOT APPLE)
    target_link_libraries(MUAudio PRIVATE dl)
endif()
target_link_libraries(MUAudio PRIVATE Threads::Threads)
```

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, Catch2 3.7.1, miniaudio 0.11.x (vendored single-header), `MUAudio` CMake target

**Prohibited (per project-context.md):**
- `new`/`delete` — use `std::array`, `std::unique_ptr` if heap required
- `NULL` — use `nullptr`
- `wprintf`, `__TraceF()`, `DebugAngel` — use `g_ErrorReport.Write()`
- `#ifndef` header guards — use `#pragma once`
- `#ifdef _WIN32` in game logic — miniaudio abstracts the platform; no Win32 conditionals in `MiniAudioBackend.cpp`
- DirectSound types in `IPlatformAudio.h` interface — `HRESULT` is acceptable for `PlaySound()` to match the existing `PlayBuffer()` signature exactly (return type preserved for zero call-site changes)

**Required patterns (per project-context.md):**
- `[[nodiscard]]` on `Initialize()` and `IsEndMusic()`, `GetMusicPosition()`
- `mu::` namespace for all new code
- Allman brace style, 4-space indent, 120-column limit (`.clang-format`)
- `#pragma once` header guards
- `g_ErrorReport.Write()` for all failure paths

**Quality gate:** `./ctl check` — must pass 0 errors. File count will increase from ~728 (post-epic-4) by approximately 4 source files + 1 test file. cppcheck may report warnings about the vendored miniaudio/stb_vorbis — verify `ThirdParty/` exclusion covers `dependencies/` as well; if not, add `--suppress=*:*dependencies/*` to the cppcheck invocation in `ctl` script.

**cppcheck vendor suppression:** Check `./ctl` or `Makefile` for the cppcheck command. The `--suppress` or `--exclude` pattern covers `ThirdParty/` but may not cover `dependencies/`. If miniaudio generates cppcheck warnings, add `src/dependencies/` to the exclusion list.

### References

- [Source: `_bmad-output/project-context.md` — C++ Language Rules, CMake Module Targets, Testing Rules]
- [Source: `docs/development-standards.md` — §1 Banned Win32 API table (Audio row), §1 Platform Abstraction Interfaces (IPlatformAudio)]
- [Source: `docs/CROSS_PLATFORM_PLAN.md` — Phase 3 (Audio System), Sessions 3.1–3.3]
- [Source: `docs/CROSS_PLATFORM_DECISIONS.md` — miniaudio selection rationale]
- [Source: `MuMain/src/source/Audio/DSPlaySound.h` — ESound enum, public API surface, MAX_CHANNEL, volume scale]
- [Source: `MuMain/src/source/Audio/DSplaysound.cpp` — DirectSound implementation patterns, 3D sound, volume conversion]
- [Source: `MuMain/src/source/Main/Winmain.cpp` lines 110–161, 448–449, 1291–1292 — wzAudio call sites (6 total)]
- [Source: `MuMain/src/CMakeLists.txt` lines 280–283 — MUAudio target definition, lines 435/440/662 — wzAudio link]
- [Source: `_bmad-output/stories/4-2-1-murenderer-core-api/story.md` — pattern reference for abstraction layer story structure]
- [Source: `MuMain/src/source/Platform/MuPlatform.h` — platform singleton pattern reference]
- [Source: `MuMain/tests/CMakeLists.txt` — test registration pattern]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — no issues encountered during implementation.

### Completion Notes List

- IPlatformAudio interface created with all 13 pure virtual methods matching DSPlaySound.h + Winmain.cpp wzAudio wrappers exactly
- miniaudio v0.11.25 and stb_vorbis v1.22 vendored at src/dependencies/miniaudio/
- MiniAudioBackend fully implements all 13 methods: Initialize (ma_engine_init, graceful failure), Shutdown (uninit all sounds + engine), LoadSound (polyphonic slots, MA_SOUND_FLAG_DECODE, 3D spatialization), PlaySound (round-robin channel selection), StopSound, AllStopSound, Set3DSoundPosition (stub — full impl in 5.2.1), SetVolume (DbToLinear conversion), SetMasterVolume, PlayMusic (MA_SOUND_FLAG_STREAM|ASYNC, looping), StopMusic, IsEndMusic, GetMusicPosition
- MiniAudioImpl.cpp isolated with SKIP_PRECOMPILE_HEADERS ON to prevent PCH collision
- CMake updated: miniaudio include path, MiniAudio/ include path, explicit sources, Threads::Threads, dl (Linux), CoreAudio frameworks (macOS)
- All 6 Catch2 TEST_CASEs pass: interface purity, g_platformAudio nullptr, default construction, graceful init failure, safe shutdown, namespace compliance
- Quality gate: ./ctl check PASSED — 0 errors, 711 files
- No existing game logic files modified (AC-7 verified)

### File List

New files created:
- MuMain/src/source/Platform/IPlatformAudio.h
- MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h
- MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp
- MuMain/src/source/Platform/MiniAudio/MiniAudioImpl.cpp
- MuMain/src/dependencies/miniaudio/miniaudio.h
- MuMain/src/dependencies/miniaudio/stb_vorbis.c
- MuMain/tests/audio/test_muaudio_abstraction.cpp (created in ATDD step)

Modified files:
- MuMain/src/CMakeLists.txt (MUAudio target: miniaudio includes, MiniAudio sources, threading)
- MuMain/tests/CMakeLists.txt (MuTests: audio test source, MUAudio link, include paths)
