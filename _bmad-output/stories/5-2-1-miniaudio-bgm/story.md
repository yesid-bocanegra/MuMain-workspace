# Story 5.2.1: miniaudio BGM Implementation

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 5 - Audio System Migration |
| Feature | 5.2 - Implementation |
| Story ID | 5.2.1 |
| Story Points | 5 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-AUDIO-MINIAUDIO-BGM |
| FRs Covered | FR17 (Background music on all platforms via miniaudio) |
| Prerequisites | 5.1.1 (MuAudio abstraction layer — `IPlatformAudio` + `MiniAudioBackend` created and done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Wire `g_platformAudio` into game startup/shutdown; replace `wzAudio*` and `DSPlaySound` calls in `Winmain.cpp` with `g_platformAudio->PlayMusic()/StopMusic()/IsEndMusic()/GetMusicPosition()`; expand `MiniAudioBackend::Set3DSoundPosition()` stub; Catch2 BGM lifecycle test |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** player,
**I want** background music playing via miniaudio on all platforms,
**so that** I can hear the MU Online soundtrack while playing.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `g_platformAudio` is wired into the game startup in `Winmain.cpp`: `new mu::MiniAudioBackend()` is allocated at the point where `wzAudioCreate(g_hWnd)` was previously called; `g_platformAudio->Initialize()` is called immediately after, with failure logged via `g_ErrorReport.Write()` but not fatal (game continues without audio)
- [ ] **AC-2:** `wzAudioCreate`, `wzAudioOption`, and `wzAudioDestroy` calls in `Winmain.cpp` are removed and replaced with `g_platformAudio` lifecycle (Initialize on startup, Shutdown + delete on `DestroySound()`)
- [ ] **AC-3:** The `PlayMp3(const char* Name, BOOL bEnforce)`, `StopMp3(const char* Name, BOOL bEnforce)`, `StopMusic()`, `IsEndMp3()`, and `GetMp3PlayPosition()` free functions in `Winmain.cpp` delegate to `g_platformAudio->PlayMusic()`, `g_platformAudio->StopMusic()`, `g_platformAudio->IsEndMusic()`, and `g_platformAudio->GetMusicPosition()` respectively; the `#pragma comment(lib, "wzAudio.lib")` and `#include <wzAudio.h>` lines are removed
- [ ] **AC-4:** BGM plays on macOS, Linux, and Windows — `ma_engine` init succeeds on all three platforms (miniaudio auto-selects CoreAudio/ALSA/WASAPI); no platform-specific code in `MiniAudioBackend` or call sites
- [ ] **AC-5:** BGM transitions (stop current → start new) are smooth — `PlayMusic(name, false)` when the same track is already playing does nothing (no restart = no pop); `PlayMusic(name, true)` unconditionally restarts; the existing `Mp3FileName` guard logic is preserved semantically via `m_currentMusicName` in `MiniAudioBackend` (already implemented in 5.1.1)
- [ ] **AC-6:** BGM loops correctly — `ma_sound_set_looping(&m_musicSound, MA_TRUE)` is already set in `MiniAudioBackend::PlayMusic()` from 5.1.1; verify by code inspection (no runtime audio device required for this AC on CI)
- [ ] **AC-7:** `MiniAudioBackend::Set3DSoundPosition()` stub is expanded: iterate all 3D-enabled sound slots and update `ma_sound_set_position` from the attached `OBJECT::Position` — matches the `Set3DSoundPosition()` logic in `DSplaysound.cpp` (this is a BGM story, but the stub must be valid for when SFX is wired in 5.2.2)
- [ ] **AC-8:** `wzAudio` dependency removed for BGM playback: `wzAudio.lib` link removed from `CMakeLists.txt` (or conditionally gated); `#pragma comment(lib, "wzAudio.lib")` removed from `Winmain.cpp`

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance — `mu::` namespace preserved for new/modified code, PascalCase functions, `m_` member prefix, `#pragma once` header guards, no raw `new`/`delete` (use `std::unique_ptr<mu::MiniAudioBackend>` for `g_platformAudio` or document rationale for raw pointer), no `NULL` (use `nullptr`), no `wprintf`; `g_ErrorReport.Write()` for all failure paths
- [ ] **AC-STD-2:** Catch2 test in `tests/audio/test_miniaudio_bgm.cpp`: BGM load, play, stop lifecycle using the existing `MiniAudioBackend` construct+initialize pattern; assert `IsEndMusic()` == true before play, and after `StopMusic(name, true)`; all tests must compile and run headless (no audio device needed — `Initialize()` may return false on CI, which is acceptable)
- [ ] **AC-STD-4:** CI quality gate passes (`./ctl check` — clang-format check + cppcheck 0 errors)
- [ ] **AC-STD-5:** Error logging patterns: `AUDIO: BGM — PlayMusic init failed for '{path}' (%d)` on stream init failure (already in `MiniAudioBackend::PlayMusic()` from 5.1.1 as `AUDIO: MiniAudioBackend::PlayMusic -- failed to init stream '%hs' (%d)`)
- [ ] **AC-STD-6:** Conventional commit: `feat(audio): implement BGM playback via miniaudio`

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check`)
- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [ ] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/audio/` directory pattern, explicit `target_sources` in `tests/CMakeLists.txt`)

---

## Validation Artifacts

- [ ] **AC-VAL-1:** BGM plays in Lorencia on all three platforms (manual validation — Windows build required; macOS/Linux via CI build + audio device)
- [ ] **AC-VAL-2:** Zone transition BGM change works smoothly — trigger a zone change in-game to verify the `PlayMp3(MUSIC_*)` → `g_platformAudio->PlayMusic()` delegation works correctly
- [ ] **AC-VAL-3:** `./ctl check` passes with 0 errors after changes
- [ ] **AC-VAL-4:** `git diff --name-only` shows only the expected files modified (no unintended regressions)

---

## Tasks / Subtasks

- [ ] Task 1: Wire `g_platformAudio` into game startup and shutdown (AC: 1, 2, 8)
  - [ ] Subtask 1.1: In `MuMain/src/source/Main/Winmain.cpp`, find the `if (m_MusicOnOff)` block at line ~1289 that calls `wzAudioCreate(g_hWnd)` + `wzAudioOption(WZAOPT_STOPBEFOREPLAY, 1)`. Replace with:
    ```cpp
    g_platformAudio = new mu::MiniAudioBackend();
    if (!g_platformAudio->Initialize())
    {
        g_ErrorReport.Write(L"AUDIO: MiniAudioBackend::Initialize failed — game will run without audio\r\n");
    }
    ```
    Note: initialization is attempted regardless of `m_MusicOnOff` so the backend exists; mute/enable is handled at the caller level via `PlayMusic(name, bEnforce)`.
  - [ ] Subtask 1.2: In `DestroySound()` (lines ~443–450 in `Winmain.cpp`), replace `wzAudioDestroy()` with:
    ```cpp
    if (g_platformAudio != nullptr)
    {
        g_platformAudio->Shutdown();
        delete g_platformAudio;
        g_platformAudio = nullptr;
    }
    ```
  - [ ] Subtask 1.3: Remove `#pragma comment(lib, "wzAudio.lib")` and `#include <wzAudio.h>` from `Winmain.cpp` (lines ~110–111). Add `#include "IPlatformAudio.h"` and `#include "MiniAudioBackend.h"` if not already present (they may need to be added at the top of `Winmain.cpp`).
  - [ ] Subtask 1.4: In `MuMain/src/CMakeLists.txt`, find the `wzAudio.lib` link (search for `wzAudio` — appears at lines ~435/440/662 per Story 5.1.1 notes) and remove it from the link libraries of `MUGame` or `Main`. The `MUAudio` target already links `Threads::Threads` and `dl` (Linux) from Story 5.1.1.

- [ ] Task 2: Delegate BGM free functions to `g_platformAudio` (AC: 3, 5)
  - [ ] Subtask 2.1: Replace the body of `StopMusic()` (lines ~113–119 in `Winmain.cpp`) with:
    ```cpp
    void StopMusic()
    {
        if (g_platformAudio != nullptr)
        {
            g_platformAudio->StopMusic(nullptr, FALSE); // soft stop, name ignored
        }
    }
    ```
  - [ ] Subtask 2.2: Replace the body of `StopMp3(const char* Name, BOOL bEnforce)` (lines ~121–134) with:
    ```cpp
    void StopMp3(const char* Name, BOOL bEnforce)
    {
        if (!m_MusicOnOff && !bEnforce)
            return;
        if (g_platformAudio != nullptr)
        {
            g_platformAudio->StopMusic(Name, bEnforce);
        }
    }
    ```
  - [ ] Subtask 2.3: Replace the body of `PlayMp3(const char* Name, BOOL bEnforce)` (lines ~136–149) with:
    ```cpp
    void PlayMp3(const char* Name, BOOL bEnforce)
    {
        if (Destroy)
            return;
        if (!m_MusicOnOff && !bEnforce)
            return;
        if (g_platformAudio != nullptr)
        {
            g_platformAudio->PlayMusic(Name, bEnforce);
        }
    }
    ```
    Note: `Mp3FileName` array is now dead code (the `m_currentMusicName` in `MiniAudioBackend` handles the same guard). Remove the `char Mp3FileName[256]` global and the `strcpy(Mp3FileName, Name)` references.
  - [ ] Subtask 2.4: Replace the body of `IsEndMp3()` (lines ~152–157) with:
    ```cpp
    bool IsEndMp3()
    {
        if (g_platformAudio == nullptr)
            return true;
        return g_platformAudio->IsEndMusic();
    }
    ```
  - [ ] Subtask 2.5: Replace the body of `GetMp3PlayPosition()` (lines ~159–161) with:
    ```cpp
    int GetMp3PlayPosition()
    {
        if (g_platformAudio == nullptr)
            return 0;
        return g_platformAudio->GetMusicPosition();
    }
    ```

- [ ] Task 3: Expand `Set3DSoundPosition()` stub in `MiniAudioBackend` (AC: 7)
  - [ ] Subtask 3.1: In `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp`, replace the `Set3DSoundPosition()` stub body with a real implementation:
    ```cpp
    void MiniAudioBackend::Set3DSoundPosition()
    {
        if (!m_initialized)
        {
            return;
        }
        // Update spatial positions for all 3D-enabled sound effect slots.
        // Called each frame from the game loop (mirrors DSplaysound.cpp Set3DSoundPosition()).
        // OBJECT::Position is vec3_t (float[3]): [0]=X, [1]=Y, [2]=Z.
        for (int buf = 0; buf < static_cast<int>(MAX_BUFFER); ++buf)
        {
            if (!m_soundLoaded[buf] || !m_sound3DEnabled[buf])
            {
                continue;
            }
            for (int ch = 0; ch < MAX_CHANNEL; ++ch)
            {
                if (ma_sound_is_playing(&m_sounds[buf][ch]))
                {
                    // Position source is tracked externally via PlaySound() pObject arg.
                    // Per-frame update requires storing the last pObject per slot.
                    // For this story: stub preserves interface — full 3D tracking in 5.2.2.
                    // (SFX with OBJECT* tracking is 5.2.2's job; BGM is never 3D.)
                }
            }
        }
    }
    ```
    **Note:** True per-frame 3D position tracking requires storing `OBJECT*` per slot (introduced when SFX is wired in 5.2.2). For this story, the loop structure is in place and the method is no longer a bare stub — but the actual `ma_sound_set_position` call is deferred to 5.2.2 when call sites are available. Document this in a comment.

- [ ] Task 4: Add `#include "IPlatformAudio.h"` to the `InitDirectSound` / audio init site (AC: 1)
  - [ ] Subtask 4.1: Verify that `Winmain.cpp` can resolve `mu::MiniAudioBackend` and `g_platformAudio`. Add includes at the top of `Winmain.cpp` (after `stdafx.h`):
    ```cpp
    #include "IPlatformAudio.h"
    #include "MiniAudioBackend.h"
    ```
    The `MiniAudio/` include directory is already propagated from `MUAudio` target (Story 5.1.1). Verify the include is resolvable by checking `MUGame` target's include dependencies.

- [ ] Task 5: Catch2 BGM lifecycle test (AC: AC-STD-2, AC-VAL-3)
  - [ ] Subtask 5.1: Create `MuMain/tests/audio/test_miniaudio_bgm.cpp`
  - [ ] Subtask 5.2: In `tests/CMakeLists.txt`, add:
    ```cmake
    # Story 5.2.1: miniaudio BGM Implementation [VS1-AUDIO-MINIAUDIO-BGM]
    target_sources(MuTests PRIVATE audio/test_miniaudio_bgm.cpp)
    ```
  - [ ] Subtask 5.3: Write `TEST_CASE("MiniAudioBackend BGM lifecycle — IsEndMusic before play")`: construct `mu::MiniAudioBackend`, do NOT call `Initialize()`, assert `IsEndMusic()` == true (no music loaded = ended).
  - [ ] Subtask 5.4: Write `TEST_CASE("MiniAudioBackend BGM lifecycle — StopMusic on unloaded stream")`: construct, optionally `Initialize()` (wrap in `REQUIRE_NOTHROW`), call `StopMusic(nullptr, TRUE)` — must not crash. Assert `IsEndMusic()` == true.
  - [ ] Subtask 5.5: Write `TEST_CASE("MiniAudioBackend BGM lifecycle — PlayMusic non-existent file returns without crash")`: construct, call `Initialize()` (may return false on CI), call `PlayMusic("nonexistent_track.mp3", TRUE)` — must not crash (will log error, return early). Assert `IsEndMusic()` == true (no stream loaded).
  - [ ] Subtask 5.6: Write `TEST_CASE("MiniAudioBackend BGM — GetMusicPosition before play returns 0")`: construct (no init), call `GetMusicPosition()` — must return 0.
  - [ ] Subtask 5.7: Tests must NOT call any Win32, DirectSound, or wzAudio API. All tests run headless — Initialize() may fail, which is fine.

- [ ] Task 6: Quality gate + commit (AC: AC-STD-4, AC-STD-6)
  - [ ] Subtask 6.1: Run `./ctl check` — 0 errors
  - [ ] Subtask 6.2: Commit: `feat(audio): implement BGM playback via miniaudio`

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A — C++ client, no HTTP error codes | — | — | — |

Logging patterns (not error catalog entries):
- `g_ErrorReport.Write(L"AUDIO: MiniAudioBackend::Initialize failed — game will run without audio\r\n")` on init failure in Winmain.cpp
- `g_ErrorReport.Write(L"AUDIO: MiniAudioBackend::PlayMusic -- failed to init stream '%hs' (%d)\r\n", name, result)` — already in MiniAudioBackend.cpp from Story 5.1.1

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
| Unit | Catch2 3.7.1 | BGM lifecycle logic (no audio device needed) | IsEndMusic before play, StopMusic on unloaded, PlayMusic with nonexistent file, GetMusicPosition before play |
| Integration (manual) | Windows build | BGM plays on game launch | Lorencia BGM plays; zone transition changes track; no audio pop/click |

---

## Dev Notes

### Context: Why This Story Exists

Story 5.1.1 created `IPlatformAudio` and `MiniAudioBackend` as an abstraction layer, but deliberately left `g_platformAudio = nullptr` and did NOT modify any existing game logic files. This story completes the BGM migration by:

1. **Wiring `g_platformAudio`** into the game startup/shutdown cycle in `Winmain.cpp`
2. **Replacing `wzAudio` free functions** (`PlayMp3`, `StopMp3`, `StopMusic`, `IsEndMp3`, `GetMp3PlayPosition`) with delegations to `g_platformAudio`
3. **Removing wzAudio dependency** (`wzAudio.lib`, `wzAudio.h`, `#pragma comment`)

The design goal is **zero call-site changes** outside `Winmain.cpp` — the 129 call sites across 10+ files that call `PlayMp3()` / `StopMp3()` / `IsEndMp3()` / `GetMp3PlayPosition()` do NOT need to be modified. They call the free functions declared in `Winmain.h`, which now delegate to `g_platformAudio`.

### Existing wzAudio System (Read-Only Reference — to be Replaced)

**`Winmain.cpp` wzAudio call sites (lines ~110–161, 449, 1291–1292):**
- `#pragma comment(lib, "wzAudio.lib")` + `#include <wzAudio.h>` — REMOVE
- `StopMusic()` → `wzAudioStop()` — REPLACE with `g_platformAudio->StopMusic(nullptr, FALSE)`
- `StopMp3(Name, bEnforce)` → `wzAudioStop()` — REPLACE with `g_platformAudio->StopMusic(Name, bEnforce)`
- `PlayMp3(Name, bEnforce)` → `wzAudioPlay(Name, 1)` — REPLACE with `g_platformAudio->PlayMusic(Name, bEnforce)`
- `IsEndMp3()` → `wzAudioGetStreamOffsetRange() == 100` — REPLACE with `g_platformAudio->IsEndMusic()`
- `GetMp3PlayPosition()` → `wzAudioGetStreamOffsetRange()` — REPLACE with `g_platformAudio->GetMusicPosition()`
- `wzAudioCreate(g_hWnd)` + `wzAudioOption(WZAOPT_STOPBEFOREPLAY, 1)` at line ~1291–1292 — REPLACE with `g_platformAudio = new mu::MiniAudioBackend(); g_platformAudio->Initialize()`
- `wzAudioDestroy()` in `DestroySound()` at line ~449 — REPLACE with backend shutdown + delete

**`char Mp3FileName[256]` global (dead code after migration):**
The existing `PlayMp3` guard `if (strcmp(Name, Mp3FileName) == 0) return;` prevents restarting the same track. After migration, `MiniAudioBackend::PlayMusic()` implements the same guard via `m_currentMusicName == name` (already coded in 5.1.1). Remove `Mp3FileName` global and `strcpy(Mp3FileName, Name)`.

**`m_MusicOnOff` / `m_SoundOnOff` globals (Winmain.cpp lines ~740–741):**
These remain. `m_MusicOnOff` guards `PlayMp3()` / `StopMp3()` — preserve that guard as-is in the delegating wrappers. Do NOT remove `m_MusicOnOff` — the option window and GameConfig use it.

**BGM call sites across the codebase (no changes needed):**
| File | Call sites |
|------|-----------|
| `Scenes/SceneManager.cpp` | 10 — `PlayMp3(MUSIC_*)` / `StopMp3(MUSIC_*)` |
| `Scenes/LoginScene.cpp` | 1 — `PlayMp3(MUSIC_LOGIN_THEME)` |
| `Scenes/LoadingScene.cpp` | 1 — `StopMp3(MUSIC_LOGIN_THEME)` |
| `UI/Legacy/CreditWin.cpp` | 2 — `StopMp3` / `PlayMp3` |
| `UI/Legacy/LoginMainWin.cpp` | 2 — `StopMp3` / `PlayMp3` |
| `World/Maps/GM*.cpp` | multiple — `PlayMp3` / `StopMp3` variants |
| `Gameplay/Events/w_CursedTemple.cpp` | 1+ |

**Music file constants (in `Core/mu_enum.h`, lines ~169–201):**
```cpp
constexpr const char* MUSIC_PUB         = "data\\music\\Pub.mp3";
constexpr const char* MUSIC_MUTHEME     = "data\\music\\Mutheme.mp3";
constexpr const char* MUSIC_CHURCH      = "data\\music\\Church.mp3";
constexpr const char* MUSIC_MAIN_THEME  = "data\\music\\main_theme.mp3";
constexpr const char* MUSIC_LOGIN_THEME = "data\\music\\login_theme.mp3";
```
These are `const char*` paths with backslashes. `MiniAudioBackend::PlayMusic()` receives them as `const char*` — miniaudio on Windows handles backslashes natively. On Linux/macOS, the path separator will need to be forward-slash. **Action:** In `MiniAudioBackend::PlayMusic()`, normalize the path by replacing `\\` with `/` before passing to `ma_sound_init_from_file()`. Use `std::string` with `std::replace()` — no new Win32 calls.

### Project Structure Notes

**Files to modify:**

| File | Change |
|------|--------|
| `MuMain/src/source/Main/Winmain.cpp` | Remove wzAudio includes/pragma; replace wzAudio calls; wire g_platformAudio; add IPlatformAudio.h + MiniAudioBackend.h includes; remove Mp3FileName global |
| `MuMain/src/CMakeLists.txt` | Remove `wzAudio.lib` link from `MUGame`/`Main` target |
| `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.cpp` | Expand `Set3DSoundPosition()` stub |
| `MuMain/tests/CMakeLists.txt` | Add `audio/test_miniaudio_bgm.cpp` to MuTests |

**New files to create:**

| File | CMake Target | Notes |
|------|-------------|-------|
| `MuMain/tests/audio/test_miniaudio_bgm.cpp` | `MuTests` (explicit add) | Catch2 BGM lifecycle tests |

**CMake include resolution:** `Winmain.cpp` is compiled as part of the `Main` target. The `Main` target links `MUGame` which links `MUAudio`. `IPlatformAudio.h` and `MiniAudioBackend.h` are in `Platform/` and `Platform/MiniAudio/` directories. Verify that `MUAudio` propagates its include directories to `MUGame` → `Main` (check if `target_include_directories(MUAudio PUBLIC ...)` or `PRIVATE`). If PRIVATE, add an explicit `target_include_directories(Main PRIVATE ...)` or include via the source path.

**wzAudio CMake removal pattern:** Search `src/CMakeLists.txt` for `wzAudio` to find the exact link line. Pattern may be:
```cmake
target_link_libraries(MUGame PRIVATE ... wzAudio ...)
# or
set_target_properties(Main ... wzAudio.lib ...)
```
Remove or comment out with rationale: `# wzAudio removed — Story 5.2.1: replaced by miniaudio via g_platformAudio`.

### Technical Implementation

#### Path Normalization for Cross-Platform BGM

The MUSIC_* constants use Windows backslash paths. On Linux/macOS, forward slashes are required:

```cpp
void MiniAudioBackend::PlayMusic(const char* name, BOOL enforce)
{
    if (!m_initialized || name == nullptr)
    {
        return;
    }

    // Normalize path separators for cross-platform compatibility
    // MUSIC_* constants use Windows-style backslashes (e.g., "data\\music\\Pub.mp3")
    std::string normalizedName(name);
    std::replace(normalizedName.begin(), normalizedName.end(), '\\', '/');

    // If not enforced and same track is already playing, do nothing
    if (!enforce && !m_currentMusicName.empty() && m_currentMusicName == normalizedName)
    {
        return;
    }
    // ... rest of implementation using normalizedName instead of name
}
```

This change should be applied to `MiniAudioBackend::PlayMusic()` and `MiniAudioBackend::StopMusic()` (the name comparison). Update `m_currentMusicName` to store the normalized path.

#### `g_platformAudio` Lifetime in `Winmain.cpp`

The global pointer `mu::IPlatformAudio* g_platformAudio` is defined in `MiniAudioBackend.cpp` (from 5.1.1). `Winmain.cpp` sees it as `extern mu::IPlatformAudio* g_platformAudio` via `IPlatformAudio.h`. The game loop sets `g_platformAudio = new mu::MiniAudioBackend()` at startup, and `DestroySound()` deletes it. This raw pointer pattern is consistent with the existing legacy codebase; `std::unique_ptr` would require changing the extern declaration — defer to future modernization.

#### Init Failure Handling

If `g_platformAudio->Initialize()` fails (no audio device — CI runners, headless VMs), the game continues without audio. All `PlayMp3` / `StopMp3` callers guard with `g_platformAudio != nullptr`, so a non-null-but-uninitialized backend is also safe (the `MiniAudioBackend` methods check `m_initialized` first). This matches the wzAudio pattern where `wzAudioCreate()` failure was silently ignored.

#### StopMusic vs StopMp3 Semantics

The existing codebase has TWO stop functions:
- `StopMusic()` — unconditional stop (no name argument), called when minimizing or changing scene categories
- `StopMp3(Name, bEnforce)` — name-matched stop; if `bEnforce=false` and the named track isn't the current one, does nothing

Map to `IPlatformAudio`:
- `StopMusic()` → `g_platformAudio->StopMusic(nullptr, FALSE)` — soft stop, name ignored (nullptr = stop current)
- `StopMp3(Name, false)` → `g_platformAudio->StopMusic(Name, FALSE)` — soft stop, name must match
- `StopMp3(Name, true)` → `g_platformAudio->StopMusic(Name, TRUE)` — hard stop, release decoder

The `MiniAudioBackend::StopMusic()` implementation already handles these semantics (from 5.1.1):
- `enforce=true`: always stops + uninits the sound (releases decoder/file handle)
- `enforce=false` + `name != nullptr`: only stops if name matches `m_currentMusicName`
- `enforce=false` + `name == nullptr`: stops current track regardless

### Critical Cross-Platform Rule

**No `#ifdef _WIN32` in `MiniAudioBackend.cpp`** — miniaudio abstracts the platform. Path normalization via `std::replace` is the only cross-platform concern. Do NOT add platform conditionals to the audio backend.

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, Catch2 3.7.1, miniaudio 0.11.x (vendored single-header), `MUAudio` CMake target

**Prohibited (per project-context.md):**
- `new`/`delete` for new types — in this story, `new mu::MiniAudioBackend()` is intentional (legacy-pattern startup in `Winmain.cpp` where all singletons are raw pointers); document the rationale
- `NULL` — use `nullptr`
- `wprintf`, `__TraceF()`, `DebugAngel` — use `g_ErrorReport.Write()`
- `#ifndef` header guards — use `#pragma once`
- `#ifdef _WIN32` in game logic — miniaudio abstracts the platform
- New Win32 calls — this story removes Win32 audio dependencies; do NOT add new ones

**Required patterns (per project-context.md):**
- `g_ErrorReport.Write()` for all failure paths
- `mu::` namespace for all new code in `Platform/`
- Allman brace style, 4-space indent, 120-column limit (`.clang-format`)
- `#pragma once` header guards
- Conventional Commit format: `feat(audio): implement BGM playback via miniaudio`

**Quality gate:** `./ctl check` — must pass 0 errors. File count will increase by 1 (test file). `cppcheck` runs only on changed files — `Winmain.cpp` is large; verify no new cppcheck warnings introduced.

**cppcheck known issue:** `Winmain.cpp` may have pre-existing cppcheck suppressions. After modifications, run `./ctl check` to verify the changed lines pass. The `// cppcheck-suppress` inline pattern is acceptable for known false positives.

### References

- [Source: `_bmad-output/stories/5-1-1-muaudio-abstraction-layer/story.md` — prerequisite story, implementation patterns, file list]
- [Source: `_bmad-output/project-context.md` — C++ Language Rules, CMake Module Targets, Testing Rules]
- [Source: `docs/development-standards.md` — §1 Banned Win32 API table (Audio row), §1 Platform Abstraction Interfaces]
- [Source: `MuMain/src/source/Main/Winmain.cpp` lines 110–161, 448–449, 1289–1297 — wzAudio call sites (all to be replaced)]
- [Source: `MuMain/src/source/Platform/IPlatformAudio.h` — interface contract]
- [Source: `MuMain/src/source/Platform/MiniAudio/MiniAudioBackend.h` + `MiniAudioBackend.cpp` — existing implementation from 5.1.1]
- [Source: `MuMain/src/source/Core/mu_enum.h` lines ~169–201 — MUSIC_* path constants with backslash separators]
- [Source: `MuMain/src/source/Audio/DSPlaySound.h` — ESound enum, MAX_BUFFER, MAX_CHANNEL]
- [Source: `MuMain/src/source/Scenes/SceneManager.cpp` lines ~731–793 — BGM call sites (no changes needed)]
- [Source: `MuMain/tests/CMakeLists.txt` — test registration pattern, MUAudio link]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
