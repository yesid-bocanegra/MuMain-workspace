# ATDD Checklist — Story 5.2.1: miniaudio BGM Implementation

**Story ID:** 5-2-1-miniaudio-bgm
**Story Type:** infrastructure
**Date Generated:** 2026-03-19
**Primary Test Level:** Unit (Catch2 3.7.1)
**Test File:** `MuMain/tests/audio/test_miniaudio_bgm.cpp`
**Phase:** GREEN — all tasks implemented, quality gate passed, commit done

---

## AC-to-Test Mapping

| AC | Description | Test Method | Test File | Status |
|----|-------------|-------------|-----------|--------|
| AC-1 | g_platformAudio wired at startup (`new mu::MiniAudioBackend()`) | Manual / code inspection — Winmain.cpp diff | `Winmain.cpp` | `[x]` done |
| AC-2 | wzAudioCreate/Option/Destroy replaced with g_platformAudio lifecycle | Manual / code inspection | `Winmain.cpp` | `[x]` done |
| AC-3 | PlayMp3/StopMp3/StopMusic/IsEndMp3/GetMp3PlayPosition delegate to g_platformAudio | Manual / code inspection | `Winmain.cpp` | `[x]` done |
| AC-4 | BGM plays on macOS, Linux, Windows (miniaudio auto-selects backend) | Code-path inspection — no #ifdef _WIN32, no platform guards; audio device test deferred to QA | AC-VAL-1 | `[x]` code-path verified, runtime audio deferred per skip_checks |
| AC-5 | BGM transitions smooth — same-track guard via m_currentMusicName | Code inspection (MiniAudioBackend::PlayMusic already implemented in 5.1.1) | `MiniAudioBackend.cpp` | `[x]` verified |
| AC-6 | BGM loops — ma_sound_set_looping(MA_TRUE) already set | Code inspection | `MiniAudioBackend.cpp` | `[x]` verified |
| AC-7 | Set3DSoundPosition() stub expanded with loop structure | Code inspection | `MiniAudioBackend.cpp` | `[x]` done |
| AC-8 | wzAudio.lib link removed from CMakeLists.txt | Code inspection / build | `MuMain/src/CMakeLists.txt` | `[x]` done |
| AC-STD-2 (Task 5.3) | `IsEndMusic()` == true before play | `TEST_CASE("AC-STD-2: MiniAudioBackend BGM lifecycle — IsEndMusic before play")` | `tests/audio/test_miniaudio_bgm.cpp` | `[x]` done |
| AC-STD-2 (Task 5.4) | `StopMusic(nullptr, TRUE)` on unloaded stream — no crash; `IsEndMusic()` == true | `TEST_CASE("AC-STD-2: MiniAudioBackend BGM lifecycle — StopMusic on unloaded stream")` | `tests/audio/test_miniaudio_bgm.cpp` | `[x]` done |
| AC-STD-2 (Task 5.5) | `PlayMusic("nonexistent_track.mp3", TRUE)` — no crash; `IsEndMusic()` == true | `TEST_CASE("AC-STD-2: MiniAudioBackend BGM lifecycle — PlayMusic non-existent file returns without crash")` | `tests/audio/test_miniaudio_bgm.cpp` | `[x]` done |
| AC-STD-2 (Task 5.6) | `GetMusicPosition()` returns 0 before play | `TEST_CASE("AC-STD-2: MiniAudioBackend BGM — GetMusicPosition before play returns 0")` | `tests/audio/test_miniaudio_bgm.cpp` | `[x]` done |
| AC-STD-1 | mu:: namespace, PascalCase, m_ prefix, #pragma once, no raw new/delete (documented exception in Winmain.cpp), no NULL, no wprintf | Code review | All modified files | `[x]` verified |
| AC-STD-4 | `./ctl check` passes 0 errors | Quality gate | CI | `[x]` passed |
| AC-STD-5 | Error logging pattern: `g_ErrorReport.Write(L"AUDIO: MiniAudioBackend::Initialize failed...")` | Code inspection | `Winmain.cpp` | `[x]` verified |
| AC-STD-6 | Conventional commit: `feat(audio): implement BGM playback via miniaudio` | Git log | — | `[x]` done |
| AC-STD-13 | `./ctl check` passes (duplicate of AC-STD-4) | Quality gate | CI | `[x]` passed |
| AC-STD-15 | Git Safety: no incomplete rebase, no force push | Git log | — | `[x]` verified |
| AC-STD-16 | Catch2 3.7.1, MuTests target, `tests/audio/` directory, `target_sources` in CMakeLists.txt | Code inspection | `tests/CMakeLists.txt` | `[x]` verified |

---

## Implementation Checklist

### Task 1: Wire g_platformAudio into startup/shutdown (AC-1, AC-2, AC-8)

- [x] Subtask 1.1: Replace `wzAudioCreate(g_hWnd)` + `wzAudioOption()` block in `Winmain.cpp` with `g_platformAudio = new mu::MiniAudioBackend(); if (!g_platformAudio->Initialize()) { g_ErrorReport.Write(...) }`
- [x] Subtask 1.2: Replace `wzAudioDestroy()` in `DestroySound()` with backend shutdown + null-guard delete
- [x] Subtask 1.3: Remove `#pragma comment(lib, "wzAudio.lib")` + `#include <wzAudio.h>`; add `#include "IPlatformAudio.h"` + `#include "MiniAudioBackend.h"` to `Winmain.cpp`
- [x] Subtask 1.4: Remove `wzAudio.lib` link from `MuMain/src/CMakeLists.txt`

### Task 2: Delegate BGM free functions (AC-3, AC-5)

- [x] Subtask 2.1: Replace `StopMusic()` body to delegate to `g_platformAudio->StopMusic(nullptr, FALSE)`
- [x] Subtask 2.2: Replace `StopMp3(Name, bEnforce)` body to delegate to `g_platformAudio->StopMusic(Name, bEnforce)` (preserving `m_MusicOnOff` guard)
- [x] Subtask 2.3: Replace `PlayMp3(Name, bEnforce)` body to delegate to `g_platformAudio->PlayMusic(Name, bEnforce)` (preserving `Destroy` + `m_MusicOnOff` guards); remove dead `Mp3FileName` global
- [x] Subtask 2.4: Replace `IsEndMp3()` body to delegate to `g_platformAudio->IsEndMusic()` (nullptr guard)
- [x] Subtask 2.5: Replace `GetMp3PlayPosition()` body to delegate to `g_platformAudio->GetMusicPosition()` (nullptr guard)

### Task 3: Expand Set3DSoundPosition() stub (AC-7)

- [x] Subtask 3.1: Replace bare stub in `MiniAudioBackend.cpp` with loop structure iterating 3D-enabled slots (full per-frame position update deferred to 5.2.2 per story notes)

### Task 4: Include resolution check (AC-1)

- [x] Subtask 4.1: Verify `Winmain.cpp` can resolve `mu::MiniAudioBackend` and `g_platformAudio`; add includes if needed

### Task 5: Catch2 BGM lifecycle tests (AC-STD-2, AC-VAL-3)

- [x] Subtask 5.1: Create `MuMain/tests/audio/test_miniaudio_bgm.cpp` — DONE (RED phase)
- [x] Subtask 5.2: Add `target_sources(MuTests PRIVATE audio/test_miniaudio_bgm.cpp)` to `tests/CMakeLists.txt` — DONE
- [x] Subtask 5.3: Write `TEST_CASE` for `IsEndMusic before play` — DONE (RED phase)
- [x] Subtask 5.4: Write `TEST_CASE` for `StopMusic on unloaded stream` — DONE (RED phase)
- [x] Subtask 5.5: Write `TEST_CASE` for `PlayMusic non-existent file returns without crash` — DONE (RED phase)
- [x] Subtask 5.6: Write `TEST_CASE` for `GetMusicPosition before play returns 0` — DONE (RED phase)
- [x] Subtask 5.7: No Win32/DirectSound/wzAudio APIs in test file — VERIFIED

### Task 6: Quality gate + commit (AC-STD-4, AC-STD-6)

- [x] Subtask 6.1: Run `./ctl check` — 0 errors
- [x] Subtask 6.2: Commit: `feat(audio): implement BGM playback via miniaudio`

---

## PCC Compliance Verification

| Item | Status |
|------|--------|
| No prohibited libraries (NULL, wprintf, Win32 APIs) in test file | `[x]` Verified |
| Required test patterns used (Catch2 REQUIRE/CHECK, TEST_CASE/SECTION) | `[x]` Verified — test file uses REQUIRE, CHECK, TEST_CASE |
| Correct test profiles (no test profiles needed — pure logic tests) | `[x]` N/A |
| No Playwright (infrastructure story, no frontend E2E) | `[x]` N/A |
| No Bruno collection (no REST endpoints) | `[x]` N/A |
| Coverage target per project-context.md (0% threshold, growing incrementally) | `[x]` N/A — threshold is 0 |
| Implementation checklist includes PCC compliance items | `[x]` This checklist |
| AC-N: prefixes in test names | `[x]` All 4 tests carry `AC-STD-2:` prefix in display name |
| Tests compile without Win32/audio device | `[x]` Uses only MiniAudioBackend.h (miniaudio single-header) |

---

## PCC Compliance Summary

| Category | Status |
|----------|--------|
| Prohibited libraries | None detected — test file uses only Catch2 + MiniAudioBackend.h |
| Required testing patterns | Catch2 REQUIRE/CHECK macros, TEST_CASE structure with GIVEN/WHEN/THEN comments |
| Test profiles | N/A — infrastructure/unit tests, no server profile needed |
| E2E (Playwright) | N/A — infrastructure story, no frontend |
| API collection (Bruno) | N/A — no REST endpoints |
| Coverage requirement | 0 threshold per project-context.md, incrementally growing |

---

## Failing Tests Created (RED Phase)

| Type | Count | Files |
|------|-------|-------|
| Unit (Catch2) | 4 | `MuMain/tests/audio/test_miniaudio_bgm.cpp` |
| Integration | 0 | (manual runtime validation per AC-VAL-1/2) |
| E2E | 0 | N/A |
| Bruno API | 0 | N/A |

**Total failing tests created:** 4

---

## Output File Path

`_bmad-output/stories/5-2-1-miniaudio-bgm/atdd.md`
