# ATDD Checklist — Story 7.9.1: macOS Game Loop & Render Path Migration

**Story ID:** 7-9-1
**Story Type:** infrastructure
**Flow Code:** VS0-QUAL-RENDER-GAMELOOP
**Date Generated:** 2026-03-26
**Phase:** RED (all tests failing — implementation pending)

---

## PCC Compliance Summary

| Check | Status | Detail |
|-------|--------|--------|
| Guidelines loaded | ✅ | `_bmad-output/project-context.md` + `docs/development-standards.md` |
| Prohibited libraries | ✅ | No prohibited libraries in test scope (Catch2 v3.7.1 is approved) |
| Test framework | ✅ | CMake script-mode tests (infrastructure story pattern) |
| No mocking framework | ✅ | Pure static-analysis tests, no mock objects |
| No Win32 in tests | ✅ | CMake tests use `file(READ)` + `string(FIND)` — no platform APIs |
| Coverage target | N/A | Infrastructure story — static analysis tests, no coverage metric |

---

## Test Level Selection

Story type `infrastructure` → **Unit (Yes) · Integration (Yes) · E2E (No) · API Collection (No)**

For this story, "unit" and "integration" tests take the form of **CMake script-mode static-analysis tests** — consistent with existing patterns for infrastructure stories in this project (see tests/build/). These tests grep source files for the presence or absence of banned API calls and required init symbols. They run on all platforms without a build (no compilation needed), satisfy the project's `skip_checks: [build, test]` for macOS CI, and fail fast in RED phase.

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Name | Phase |
|----|-------------|-----------|-----------|-------|
| AC-1 | SwapBuffers dead calls removed from SceneManager.cpp and LoadingScene.cpp | `tests/build/test_ac1_swapbuffers_removed_7_9_1.cmake` | `7.9.1-AC-1:swapbuffers-removed` | 🔴 RED |
| AC-2 | OutputDebugStringA replaced with g_ErrorReport.Write() in SceneManager.cpp | `tests/build/test_ac2_outputdebugstringa_removed_7_9_1.cmake` | `7.9.1-AC-2:outputdebugstringa-removed` | 🔴 RED |
| AC-3 | KillGLWindow() replaced with `Destroy = true` in SceneManager.cpp | `tests/build/test_ac3_killglwindow_removed_7_9_1.cmake` | `7.9.1-AC-3:killglwindow-removed` | 🔴 RED |
| AC-4 | Game init sequence ported to MuMain() | `tests/build/test_ac4_muminit_sequence_7_9_1.cmake` | `7.9.1-AC-4:muminit-sequence` | 🔴 RED |
| AC-5 | RenderScene(nullptr) wired into SDL3 game loop | `tests/build/test_ac5_renderscene_wired_7_9_1.cmake` | `7.9.1-AC-5:renderscene-wired` | 🔴 RED |
| AC-6 | Quality gate passes | Manual: `./ctl check` + `python3 MuMain/scripts/check-win32-guards.py` | — | 🔴 RED |
| AC-STD-1 | Code standards (clang-format, no new #ifdef _WIN32 at call sites) | Covered by AC-6 quality gate | — | 🔴 RED |
| AC-STD-2 | Existing Catch2 test suite passes with new code | Manual: `./ctl test` | — | 🔴 RED |
| AC-STD-11 | Flow code traceability VS0-QUAL-RENDER-GAMELOOP | `tests/build/test_ac_std11_flow_code_7_9_1.cmake` | `7.9.1-AC-STD-11:flow-code-traceability` | 🟢 GREEN |
| AC-STD-12 | 60 fps target; first frame non-black | Manual: run game on macOS arm64 | — | 🔴 RED |
| AC-STD-13 | Quality gate `./ctl check` exits 0 | Manual + `7.9.1-AC-6` | — | 🔴 RED |

> **AC-STD-11** is GREEN immediately — the flow code appears in all 5 test files committed in RED phase.

---

## Implementation Checklist

### AC-1: SwapBuffers Removal

- [ ] `7.9.1-AC-1:swapbuffers-removed` test passes (GREEN)
- [ ] `SwapBuffers(hDC)` deleted from `src/source/Scenes/SceneManager.cpp:968`
- [ ] `::SwapBuffers(hDC)` deleted from `src/source/Scenes/LoadingScene.cpp:107`
- [ ] No `#ifdef _WIN32` guard added at either call site (migration, not guarding)
- [ ] `python3 MuMain/scripts/check-win32-guards.py` reports 0 violations after change

### AC-2: OutputDebugStringA Replacement

- [ ] `7.9.1-AC-2:outputdebugstringa-removed` test passes (GREEN)
- [ ] `OutputDebugStringA(errorMsg)` at `SceneManager.cpp:993` replaced with `g_ErrorReport.Write(L"Exception in MainScene: %S\r\n", e.what())`
- [ ] `OutputDebugStringA(errorMsg)` at `SceneManager.cpp:1032` replaced with `g_ErrorReport.Write(L"Exception in RenderScene: %S\r\n", e.what())`
- [ ] `char errorMsg[256]` / `sprintf_s` intermediary buffers removed from both catch blocks
- [ ] `g_ErrorReport.Write` present in SceneManager.cpp cross-platform section

### AC-3: KillGLWindow Replacement

- [ ] `7.9.1-AC-3:killglwindow-removed` test passes (GREEN)
- [ ] `KillGLWindow()` at `SceneManager.cpp:1024` replaced with `Destroy = true`
- [ ] `extern GLvoid KillGLWindow(GLvoid)` declaration in `SceneCore.cpp:125` remains (used by ZzzTexture.cpp under `#ifdef MU_USE_OPENGL_BACKEND`)
- [ ] `Destroy` extern bool resolves to the same variable used by SDL3 event loop exit condition at Winmain.cpp:1502

### AC-4: Game Init Sequence in MuMain()

- [ ] `7.9.1-AC-4:muminit-sequence` test passes (GREEN)
- [ ] `srand((unsigned)time(nullptr))` + RandomTable fill added after SDL3 renderer init
- [ ] `GateAttribute`, `SkillAttribute`, `ItemAttRibuteMemoryDump` / `ItemAttribute`, `CharacterMemoryDump` / `CharactersClient`, `CharacterMachine` allocated and memset
- [ ] `CharacterAttribute = &CharacterMachine->Character`, `CharacterMachine->Init()`, `Hero = &CharactersClient[0]` set
- [ ] `g_pUIManager`, `g_pUIMapName`, `g_BuffSystem`, `g_MapProcess`, `g_petProcess`, `CUIMng::Instance().Create()`, `g_pNewUISystem->Create()` constructed
- [ ] `i18n::Translator` loading (Game domain, `Translations/en/game.json`)
- [ ] `g_platformAudio` (MiniAudioBackend) init + volume restore from `GameConfig`
- [ ] `OpenBasicData(nullptr)` called (verify `InitTextures` path does not dereference `hDC` unconditionally before this is called)
- [ ] Win32-only init skipped: `SetTimer`, `CreateFont`, `CInput::Instance().Create(g_hWnd)`, IME, screensaver

### AC-5: RenderScene Wired into SDL3 Loop

- [ ] `7.9.1-AC-5:renderscene-wired` test passes (GREEN)
- [ ] `// Game loop body will be added...` comment at Winmain.cpp:1516 replaced with `RenderScene(nullptr);`
- [ ] Call is inside `#ifdef MU_ENABLE_SDL3` BeginFrame/EndFrame block
- [ ] `RenderScene(HDC)` signature accepts `nullptr` without crash on macOS SDL3 path (all `hDC` dereferences inside `RenderScene()` are behind `#ifdef MU_USE_OPENGL_BACKEND` after AC-1 removes SwapBuffers calls)

### AC-6: Quality Gate

- [ ] `./ctl check` exits 0 (clang-format + cppcheck + build + tests)
- [ ] `python3 MuMain/scripts/check-win32-guards.py` reports 0 violations
- [ ] All existing Catch2 tests pass (`./ctl test`)
- [ ] Game launches on macOS arm64 and renders non-black first frame (loading screen or splash)

### AC-STD-11: Flow Code Traceability

- [x] `7.9.1-AC-STD-11:flow-code-traceability` test passes (GREEN immediately — flow code in all test files)
- [ ] Flow code `VS0-QUAL-RENDER-GAMELOOP` present in git commit message(s) for this story

### PCC Compliance

- [ ] No prohibited libraries used in test or implementation files
- [ ] All new tests use CMake script-mode pattern (consistent with project infrastructure test style)
- [ ] Catch2 test suite (`./ctl test`) continues to pass — no regressions introduced
- [ ] clang-format applied to all modified `.cpp` and `.h` files
- [ ] No new `#ifdef _WIN32` in game logic (checked by `check-win32-guards.py`)
- [ ] Conventional Commit format used: `feat(render): wire RenderScene into SDL3 game loop [Story-7-9-1]`

---

## Test Files Created (RED Phase)

| File | Size | AC Covered |
|------|------|------------|
| `MuMain/tests/build/test_ac1_swapbuffers_removed_7_9_1.cmake` | ~60 lines | AC-1 |
| `MuMain/tests/build/test_ac2_outputdebugstringa_removed_7_9_1.cmake` | ~65 lines | AC-2 |
| `MuMain/tests/build/test_ac3_killglwindow_removed_7_9_1.cmake` | ~60 lines | AC-3 |
| `MuMain/tests/build/test_ac4_muminit_sequence_7_9_1.cmake` | ~70 lines | AC-4 |
| `MuMain/tests/build/test_ac5_renderscene_wired_7_9_1.cmake` | ~75 lines | AC-5 |
| `MuMain/tests/build/test_ac_std11_flow_code_7_9_1.cmake` | ~50 lines | AC-STD-11 |

**CMakeLists.txt updated:** `MuMain/tests/build/CMakeLists.txt` — 6 `add_test()` entries added for story 7.9.1.

---

## Current RED Phase Status

Running `ctest -R "7.9.1"` against the current (unimplemented) codebase will produce:

| Test | Expected Result | Reason |
|------|-----------------|--------|
| `7.9.1-AC-1:swapbuffers-removed` | ❌ FAIL | `SwapBuffers(` still present in SceneManager.cpp:968 and LoadingScene.cpp:107 |
| `7.9.1-AC-2:outputdebugstringa-removed` | ❌ FAIL | `OutputDebugStringA(` still in SceneManager.cpp cross-platform section; `g_ErrorReport.Write` absent |
| `7.9.1-AC-3:killglwindow-removed` | ❌ FAIL | `KillGLWindow` still present in SceneManager.cpp; `Destroy = true` absent |
| `7.9.1-AC-4:muminit-sequence` | ❌ FAIL | `OpenBasicData`, `CharacterMachine->Init`, `g_pUIManager`, `i18n`, `g_platformAudio` not in MuMain() |
| `7.9.1-AC-5:renderscene-wired` | ❌ FAIL | `RenderScene(nullptr)` absent; placeholder comment still present |
| `7.9.1-AC-STD-11:flow-code-traceability` | ✅ PASS | Flow code in test files — present immediately |

---

## Dev Agent Notes

- **No Bruno API tests** — story type `infrastructure` (no REST endpoints)
- **No Playwright E2E tests** — no frontend UI changes
- **AC-STD-12 is manual** — 60fps / non-black first frame requires running the game on macOS arm64 hardware; no automated equivalent exists at this time
- **AC-4 `OpenBasicData` path risk**: before calling `OpenBasicData(nullptr)`, verify `InitTextures(HDC, ...)` does not unconditionally dereference `hDC` on the SDL3 path. If it does, add a null guard inside `InitTextures`, not at the call site.
- **AC-3 Destroy extern**: verify `Destroy` is accessible from `SceneManager.cpp` (it is declared in Winmain.cpp and used via the `while (!Destroy)` loop — ensure it has external linkage or add an extern declaration to an appropriate header)
