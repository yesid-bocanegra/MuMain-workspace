# Story 7.9.1: macOS Game Loop & Render Path Migration

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.9 - macOS Game Loop & Win32 Render Path Migration |
| Story ID | 7.9.1 |
| Story Points | 13 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-RENDER-GAMELOOP |
| FRs Covered | Game client must run and render on macOS arm64 natively — not just build |
| Prerequisites | 7-8-4-dotnet-native-build (done), 7-3-1-macos-stability-session (in-progress) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Port game init to MuMain(); wire RenderScene into SDL3 loop; remove SwapBuffers dead calls; replace KillGLWindow with Destroy flag; replace OutputDebugStringA with g_ErrorReport |
| project-docs | documentation | Story artifacts |

---

## Background

The game **builds** on macOS (`./ctl check` passes) but **renders a black screen**. The SDL3
`MuMain()` entry point (Winmain.cpp:1454) is a skeleton: it initialises the SDL3 window and
SDL_gpu renderer, then loops calling `BeginFrame()`/`EndFrame()` with nothing in between.

The full render path — `RenderScene()` → `WebzenScene()` / `LoadingScene()` / `MainScene()` —
lives only in `MainLoop()` (Winmain.cpp:892), a Windows-only Win32 message loop.

Three additional banned Win32 APIs in the scene render path must be **migrated** (not shimmed
or `#ifdef`-guarded at call sites) before wiring:

| Location | Call | Problem |
|----------|------|---------|
| SceneManager.cpp:968 | `SwapBuffers(hDC)` | Dead no-op via shim; SDL3 `EndFrame()` handles presentation — call must be removed |
| LoadingScene.cpp:107 | `SwapBuffers(hDC)` | Same — dead code |
| SceneManager.cpp:993,1032 | `OutputDebugStringA(errorMsg)` | Silently discards exceptions on macOS; must log via `g_ErrorReport.Write()` |
| SceneManager.cpp:1024 | `KillGLWindow()` | **Not shimmed** — compile/link error on macOS when called from `RenderScene()`; must replace with `Destroy = true` (SDL3 graceful exit) |

Additionally, `MuMain()` is missing the game initialization sequence that `WinMain()` runs before
`MainLoop()`: game data arrays (GateAttribute, SkillAttribute, ItemAttribute, CharacterMachine,
Hero), i18n translations, audio backend, and `OpenBasicData()` which loads textures/resources.
Without this, `RenderScene()` will crash or render nothing even after it is wired in.

> **Rule:** No `#ifdef _WIN32` at call sites. All Win32 fixes go in PlatformCompat.h stubs
> (permanent shim strategy, already exists for SwapBuffers/OutputDebugStringA) or are fully
> migrated to cross-platform equivalents (for KillGLWindow). The `check-win32-guards.py` script
> enforces this at every `./ctl check` run.

---

## Story

**[VS-0] [Flow:E]**

**As a** developer running the game client on macOS arm64,
**I want** the SDL3 game loop to initialise game state and call `RenderScene()` each frame,
**so that** the game renders visible content instead of a black screen on macOS.

---

## Functional Acceptance Criteria

- [ ] **AC-1: Remove `SwapBuffers` dead calls**
  `SwapBuffers(hDC)` at `SceneManager.cpp:968` is removed.
  `SwapBuffers(hDC)` at `LoadingScene.cpp:107` is removed.
  SDL3 `EndFrame()` already handles presentation; the Win32 shim in PlatformCompat.h becomes
  the only remaining reference and stays as a safety net for any other lingering call sites.
  _Rationale: migration, not guarding — remove dead code from call sites._

- [ ] **AC-2: Replace `OutputDebugStringA` with `g_ErrorReport.Write()`**
  `OutputDebugStringA(errorMsg)` at `SceneManager.cpp:993` (MainScene catch block) is replaced
  with `g_ErrorReport.Write(L"Exception in MainScene: %S\r\n", e.what())`.
  `OutputDebugStringA(errorMsg)` at `SceneManager.cpp:1032` (RenderScene catch block) is
  replaced with `g_ErrorReport.Write(L"Exception in RenderScene: %S\r\n", e.what())`.
  _Rationale: exceptions are silently swallowed on macOS with the empty OutputDebugStringA shim._

- [ ] **AC-3: Remove `KillGLWindow()` from `RenderScene()`**
  `KillGLWindow()` at `SceneManager.cpp:1024` (inside `if (g_iNoMouseTime > 31)` guard) is
  replaced with `Destroy = true`.
  This signals the SDL3 event loop to exit gracefully (identical to the window close path in
  `PollEvents()`), rather than tearing down a Win32/OpenGL context that does not exist.
  The `SceneCore.cpp:125` `extern` forward declaration for `KillGLWindow` may remain (it is
  used by `ZzzTexture.cpp:314` which is a Windows-only build path under `#ifdef MU_USE_OPENGL_BACKEND`).

- [ ] **AC-4: Port minimum game init to `MuMain()`**
  The following initialisation steps from `WinMain()` are reproduced in `MuMain()` **after**
  the SDL3 window and renderer are created and **before** the game loop:
  - `srand((unsigned)time(nullptr))` + `RandomTable` fill
  - `GateAttribute`, `SkillAttribute`, `ItemAttRibuteMemoryDump` / `ItemAttribute`, `CharacterMemoryDump` / `CharactersClient`, `CharacterMachine` allocation and memset
  - `CharacterAttribute = &CharacterMachine->Character`, `CharacterMachine->Init()`, `Hero = &CharactersClient[0]`
  - `g_pUIManager`, `g_pUIMapName`, `g_BuffSystem`, `g_MapProcess`, `g_petProcess`, `CUIMng::Instance().Create()`, `g_pNewUISystem->Create()` construction
  - `i18n::Translator` translation loading (Game domain, `Translations/en/game.json`)
  - `g_platformAudio` (MiniAudioBackend) init if `m_MusicOnOff || m_SoundOnOff`; volume restore from `GameConfig`
  - `OpenBasicData(nullptr)` — loads textures, item data, gate scripts, mix recipes etc.
  Win32-only init steps (`CreateFont`, `SetTimer`, `g_hWnd`-dependent calls, IME, screensaver)
  are **skipped** for the SDL3 path and are not ported.

- [ ] **AC-5: Wire `RenderScene()` into SDL3 game loop**
  `MuMain()` at Winmain.cpp:1516 (the `// Game loop body will be added...` comment) is replaced
  with a call to `RenderScene(nullptr)`.
  The call is placed between `BeginFrame()` and `EndFrame()`.
  On macOS, `hDC` is `nullptr`; all `hDC` dereferences in the scene hierarchy are either
  already guarded by `#ifdef MU_USE_OPENGL_BACKEND` or are the now-removed `SwapBuffers` calls.

- [ ] **AC-6: Quality gate passes**
  `./ctl check` exits 0 (format-check + cppcheck lint + build + tests).
  `python3 MuMain/scripts/check-win32-guards.py` reports 0 violations.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — clang-format clean; no new `#ifdef _WIN32` at call sites.
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [ ] **Task 1: Remove `SwapBuffers` dead calls** (AC-1)
  - [ ] 1.1: Delete `SwapBuffers(hDC);` at `SceneManager.cpp:968`
  - [ ] 1.2: Delete `::SwapBuffers(hDC);` at `LoadingScene.cpp:107`

- [ ] **Task 2: Replace `OutputDebugStringA` with `g_ErrorReport.Write()`** (AC-2)
  - [ ] 2.1: Replace `SceneManager.cpp:993` — `g_ErrorReport.Write(L"Exception in MainScene: %S\r\n", e.what())`
  - [ ] 2.2: Replace `SceneManager.cpp:1032` — `g_ErrorReport.Write(L"Exception in RenderScene: %S\r\n", e.what())`
  - [ ] 2.3: Remove the `char errorMsg[256]` / `sprintf_s` intermediary buffers in both catch blocks

- [ ] **Task 3: Replace `KillGLWindow()` in `RenderScene()`** (AC-3)
  - [ ] 3.1: Replace `KillGLWindow();` at `SceneManager.cpp:1024` with `Destroy = true;`
  - [ ] 3.2: Verify `Destroy` is the correct external-linkage bool used by the SDL3 event loop exit condition at Winmain.cpp:1502

- [ ] **Task 4: Port minimum game init to `MuMain()`** (AC-4)
  - [ ] 4.1: Add srand + RandomTable fill after renderer init
  - [ ] 4.2: Add GateAttribute, SkillAttribute, ItemAttribute, CharacterMachine, CharactersClient allocation + memset
  - [ ] 4.3: Set CharacterAttribute, call CharacterMachine->Init(), set Hero
  - [ ] 4.4: Construct g_pUIManager, g_pUIMapName, g_BuffSystem, g_MapProcess, g_petProcess, CUIMng, g_pNewUISystem
  - [ ] 4.5: Load i18n translations (Game domain)
  - [ ] 4.6: Init MiniAudioBackend + restore volume levels from GameConfig
  - [ ] 4.7: Call `OpenBasicData(nullptr)` (pass nullptr HDC — texture loading via SDL_gpu does not use HDC)

- [ ] **Task 5: Wire `RenderScene()` into SDL3 game loop** (AC-5)
  - [ ] 5.1: Replace the `// Game loop body will be added...` comment with `RenderScene(nullptr);`
  - [ ] 5.2: Verify the call is inside the `#ifdef MU_ENABLE_SDL3` BeginFrame/EndFrame block
  - [ ] 5.3: Confirm `RenderScene(HDC)` signature accepts nullptr without crash on the macOS path (all hDC dereferences are behind MU_USE_OPENGL_BACKEND guards)

- [ ] **Task 6: Quality gate** (AC-6)
  - [ ] 6.1: Run `./ctl check` — fix any format or lint issues
  - [ ] 6.2: Run `python3 MuMain/scripts/check-win32-guards.py` — confirm 0 violations
  - [ ] 6.3: Run game on macOS and confirm non-black first frame (loading screen or splash renders)

---

## Dev Notes

### Key File Locations

| File | Relevant Lines | Change |
|------|---------------|--------|
| `src/source/Scenes/SceneManager.cpp` | 968 | Remove `SwapBuffers(hDC)` |
| `src/source/Scenes/SceneManager.cpp` | 993, 1032 | Replace `OutputDebugStringA` with `g_ErrorReport.Write()` |
| `src/source/Scenes/SceneManager.cpp` | 1024 | Replace `KillGLWindow()` with `Destroy = true` |
| `src/source/Scenes/LoadingScene.cpp` | 107 | Remove `::SwapBuffers(hDC)` |
| `src/source/Main/Winmain.cpp` | 1454–1530 | `MuMain()` — add init + `RenderScene(nullptr)` |
| `src/source/Main/Winmain.cpp` | 1280–1430 | `WinMain` init sequence to replicate (Win32-free parts) |

### `RenderScene(HDC)` is safe with `nullptr` on the SDL3 path

`hDC` is only used in two places inside `RenderScene()`:
1. Passed to `WebzenScene(hDC)`, `LoadingScene(hDC)`, `MainScene(hDC)` — which in turn pass
   it to `SwapBuffers(hDC)` (being removed in AC-1) and to OpenGL-specific calls that are
   wrapped in `#ifdef MU_USE_OPENGL_BACKEND`.
2. `SwapBuffers(hDC)` at SceneManager.cpp:968 — removed by AC-1.

After AC-1 is applied, no call site dereferences `hDC` on the SDL3 path.

### `KillGLWindow` — why `Destroy = true` not `SDL_DestroyWindow`

`KillGLWindow()` (Winmain.cpp:198) tears down a Win32/OpenGL context (wglDeleteContext,
ReleaseDC, DestroyWindow). On SDL3, there is no such context to destroy. Setting
`Destroy = true` signals the `while (!Destroy)` loop at Winmain.cpp:1502 to exit, which then
hits `mu::ShutdownSDLGpuRenderer()` and `mu::MuPlatform::Shutdown()` in the normal teardown
path. This is the correct SDL3 equivalent of a forced exit.

`Destroy` is declared `extern` in the broader codebase (set by `WM_DESTROY` on Windows, by
`SDL_EVENT_QUIT` on SDL3 via PollEvents). It is safe to set from any thread holding the game
lock, or from the main game loop itself.

### Init items to SKIP in `MuMain()` (Win32-only)

- `SetTimer(g_hWnd, ...)` — Windows message-queue timers, no SDL3 equivalent needed
- `CreateFont(...)` — GDI font handles; font rendering is not yet implemented in SDL3 path
- `CInput::Instance().Create(g_hWnd, ...)` — Win32 raw input; SDL3 input already wired
- `g_pMercenaryInputBox->Init(g_hWnd, ...)` — HWND-dependent UI; skip for SDL3 path
- IME init (`ImmGetContext` etc.) — Win32-only; SDL3 uses SDL_StartTextInput
- Screensaver suppression (`SystemParametersInfo`) — Windows-only

### OpenBasicData signature

`OpenBasicData(HDC hDC)` in `ZzzOpenData.cpp` — the `hDC` parameter is passed to
`InitTextures(hDC, ...)` which on the SDL3 path (no `MU_USE_OPENGL_BACKEND`) should be
a no-op or use the SDL_gpu texture loader. Verify the texture init path before calling with
`nullptr`; if `InitTextures` dereferences `hDC` unconditionally, add a guard there rather
than at the call site.

### References

- [Source: Winmain.cpp:1454–1530] — `MuMain()` SDL3 skeleton
- [Source: Winmain.cpp:892–960] — `MainLoop()` Windows render loop
- [Source: Winmain.cpp:1280–1430] — WinMain init sequence
- [Source: SceneManager.cpp:997–1034] — `RenderScene(HDC)` implementation
- [Source: Platform/PlatformCompat.h:1634–1638] — `SwapBuffers` shim (no-op)
- [Source: Platform/PlatformCompat.h:1631–1632] — `OutputDebugStringA` shim (empty)
- [Source: Platform/PlatformCompat.h:1268] — `GetAsyncKeyState` shim (already correct)

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Session: 36258f40-6830-487d-924e-a0a0da50ddce (metal entrypoint fix, diagnostic counters, black screen root cause analysis)

### Completion Notes List

### File List
