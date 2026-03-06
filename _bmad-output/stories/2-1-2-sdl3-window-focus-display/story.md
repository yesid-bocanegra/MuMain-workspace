# Story 2.1.2: SDL3 Window Focus & Display Management

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 2 - SDL3 Windowing & Input Migration |
| Feature | 2.1 - SDL3 Window Management |
| Story ID | 2.1.2 |
| Story Points | 3 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-1 |
| Flow Code | VS1-SDL-WINDOW-FOCUS |
| FRs Covered | EPIC-2 windowing migration (focus, display, fullscreen, cursor confinement) |
| Prerequisites | 2.1.1 done (SDL3 window + event loop + MuPlatform facade established) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | SDLEventLoop: implement focus/minimize/restore handlers; SDLWindow: add fullscreen toggle, display mode query, cursor confinement; MuPlatform: new focus/display facade methods |
| project-docs | documentation | Test scenarios for story 2.1.2 |

---

## Story

**[VS-1] [Flow:F]**

**As a** player,
**I want** proper window focus handling and display resolution detection,
**so that** the game behaves correctly on Alt-Tab, fullscreen toggle, and multi-monitor setups on macOS and Linux.

---

## Functional Acceptance Criteria

- [x] **AC-1:** Focus gain/loss events (SDL `SDL_EVENT_WINDOW_FOCUS_GAINED` / `SDL_EVENT_WINDOW_FOCUS_LOST`) pause and resume game activity correctly — `g_bWndActive` is set `false` on focus-loss and `true` on focus-gain; FPS throttle (`SetTargetFps`) is applied on focus-loss in fullscreen mode and restored on focus-gain, matching the existing `WM_ACTIVATE` behavior.
- [x] **AC-2:** Display mode detection (resolution, refresh rate) via `SDL_GetCurrentDisplayMode()` replaces `EnumDisplaySettings` in the non-Windows path; the detected width/height are made available to game initialization code so `WindowWidth`/`WindowHeight` are set correctly.
- [x] **AC-3:** Fullscreen toggle works on all platforms: `mu::MuPlatform::SetFullscreen(bool)` calls `SDL_SetWindowFullscreen()` on the active SDL_Window; the Win32 backend stub delegates to the existing `ChangeDisplaySettings` path (no behavior change on Windows).
- [x] **AC-4:** Mouse cursor is confined to the window on focus-gain in fullscreen mode (`SDL_SetWindowMouseGrab(true)`) and released on focus-loss (`SDL_SetWindowMouseGrab(false)`); in windowed mode cursor grab is not applied.
- [x] **AC-5:** Minimize / restore events (`SDL_EVENT_WINDOW_MINIMIZED` / `SDL_EVENT_WINDOW_RESTORED`) update `g_bWndActive` and FPS throttle consistently with focus-loss / focus-gain behavior.

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code standards compliance — PascalCase public functions, `m_` Hungarian member prefix, `std::unique_ptr` (no raw `new`/`delete`), `nullptr`, `#pragma once`, Allman braces, 4-space indent, LF line endings, UTF-8 files. No `#ifdef _WIN32` in game logic — only in `Platform/` layer.
- [x] **AC-STD-2:** Testing requirements — Catch2 v3.7.1 unit tests in `MuMain/tests/platform/`; tests cover: `SetFullscreen(true)` does not crash when no window is created (null-guard), display mode query returns positive width/height, mouse grab state transitions.
- [x] **AC-STD-8:** Error catalog — any SDL3 errors during fullscreen set or display query surfaced via `g_ErrorReport.Write()` with `MU_ERR_*` prefix.
- [x] **AC-STD-10:** Contract catalogs — N/A (no HTTP API or event-bus contracts).
- [x] **AC-STD-11:** Flow code `VS1-SDL-WINDOW-FOCUS` appears in log output (`g_ErrorReport.Write`), test names, and story artifacts.
- [x] **AC-STD-12:** SLI/SLO targets — N/A for platform infrastructure story; window operations (focus, fullscreen toggle) must complete without blocking the game loop frame (verified by unit tests being non-blocking).
- [x] **AC-STD-13:** Quality gate passes: `make -C MuMain format-check && make -C MuMain lint`
- [x] **AC-STD-14:** Observability — N/A for infrastructure story; error surfacing handled by AC-STD-8 (`g_ErrorReport.Write()` with `MU_ERR_*` prefix) and AC-STD-11 (flow code `VS1-SDL-WINDOW-FOCUS` in log output).
- [x] **AC-STD-15:** Git safety — clean merge, no force push, no incomplete rebase.
- [x] **AC-STD-16:** Correct test infrastructure — Catch2 v3.7.1 via FetchContent, tests in `MuMain/tests/platform/`, `BUILD_TESTING=ON` opt-in.
- [x] **AC-STD-20:** N/A — no HTTP endpoints, event-bus entries, or nav-catalog screens in this story.

---

## Validation Artifacts

- [x] **AC-VAL-1:** N/A — no HTTP endpoints.
- [x] **AC-VAL-2:** Test scenarios documented in `_bmad-output/test-scenarios/epic-2/2-1-2-window-focus-display.md`
- [x] **AC-VAL-3:** N/A — no seed data.
- [x] **AC-VAL-4:** N/A — no API catalog entries.
- [x] **AC-VAL-5:** N/A — no event-bus events.
- [x] **AC-VAL-6:** Flow catalog entry `VS1-SDL-WINDOW-FOCUS` confirmed in story artifacts.
**Manual validation (deferred to integration testing after EPIC-2 completes):**
- AC-VAL-1 (manual): Alt-Tab focus behavior on macOS/Linux — requires full game compilation (blocked until EPIC-4 rendering migration).
- AC-VAL-2 (manual): Fullscreen toggle on macOS/Linux — requires full game compilation (blocked until EPIC-4 rendering migration).

---

## Tasks / Subtasks

- [x] **Task 1 — Extend IPlatformWindow interface** (AC: 3, 4)
  - [x] 1.1 Add `SetFullscreen(bool fullscreen)` pure virtual method to `IPlatformWindow.h`.
  - [x] 1.2 Add `SetMouseGrab(bool grab)` pure virtual method to `IPlatformWindow.h`.
  - [x] 1.3 Add `[[nodiscard]] bool GetDisplaySize(int& outWidth, int& outHeight) const` pure virtual method to `IPlatformWindow.h` (returns current display resolution for this window's display).

- [x] **Task 2 — Implement SDL3 backend methods** (AC: 1, 2, 3, 4, 5)
  - [x] 2.1 In `SDLWindow.h` / `SDLWindow.cpp`: implement `SetFullscreen(bool)` using `SDL_SetWindowFullscreen(m_pWindow, fullscreen ? SDL_WINDOW_FULLSCREEN : 0)`. Log failure via `g_ErrorReport.Write(L"MU_ERR_FULLSCREEN_FAILED [VS1-SDL-WINDOW-FOCUS]: %hs\r\n", SDL_GetError())`.
  - [x] 2.2 In `SDLWindow.h` / `SDLWindow.cpp`: implement `SetMouseGrab(bool)` using `SDL_SetWindowMouseGrab(m_pWindow, grab)`.
  - [x] 2.3 In `SDLWindow.h` / `SDLWindow.cpp`: implement `GetDisplaySize(int&, int&)` using `SDL_GetCurrentDisplayMode(SDL_GetDisplayForWindow(m_pWindow), &mode)`. Log failure via `g_ErrorReport.Write`. Return `false` on SDL error.

- [x] **Task 3 — Implement Win32 backend stubs** (AC: 3, 4 — Windows no-behavior-change)
  - [x] 3.1 In `Win32Window.h` / `Win32Window.cpp`: implement `SetFullscreen(bool)` as a no-op stub (existing Win32 fullscreen is handled by `ChangeDisplaySettings` in `Winmain.cpp` before window creation — no runtime toggle needed at this stage). Document the stub with a comment referencing the existing code path.
  - [x] 3.2 In `Win32Window.h` / `Win32Window.cpp`: implement `SetMouseGrab(bool)` as a no-op stub (Win32 uses `SetCapture`/`ReleaseCapture` in game logic; this interface method is SDL3-specific behavior).
  - [x] 3.3 In `Win32Window.h` / `Win32Window.cpp`: implement `GetDisplaySize(int&, int&)` using `GetSystemMetrics(SM_CXSCREEN)` / `GetSystemMetrics(SM_CYSCREEN)`. This keeps the existing behavior on Windows.

- [x] **Task 4 — Extend MuPlatform facade** (AC: 2, 3, 4)
  - [x] 4.1 Add `static void SetFullscreen(bool fullscreen)` to `MuPlatform.h` / `MuPlatform.cpp` — delegates to `s_pWindow->SetFullscreen(fullscreen)` if window exists.
  - [x] 4.2 Add `static void SetMouseGrab(bool grab)` to `MuPlatform.h` / `MuPlatform.cpp` — delegates to `s_pWindow->SetMouseGrab(grab)`.
  - [x] 4.3 Add `[[nodiscard]] static bool GetDisplaySize(int& outWidth, int& outHeight)` to `MuPlatform.h` / `MuPlatform.cpp` — delegates to `s_pWindow->GetDisplaySize(...)`. Returns `false` if no window.

- [x] **Task 5 — Implement focus/minimize/restore handlers in SDLEventLoop** (AC: 1, 4, 5)
  - [x] 5.1 In `SDLEventLoop.cpp`, replace the `// No-op — will be mapped in story 2.1.2` comments with real handler code for all five events. Import necessary externs (`g_bWndActive`, `g_bUseWindowMode`, `g_HasInactiveFpsOverride`, `g_TargetFpsBeforeInactive`, `SetTargetFps`, `GetTargetFps`, `REFERENCE_FPS`). Use the same logic as the Win32 `WM_ACTIVATE` handler in `Winmain.cpp` (lines ~488–526).
  - [x] 5.2 `SDL_EVENT_WINDOW_FOCUS_GAINED`: Set `g_bWndActive = true`. If `g_HasInactiveFpsOverride`, restore `SetTargetFps(g_TargetFpsBeforeInactive)` and clear the flag. If fullscreen, call `mu::MuPlatform::SetMouseGrab(true)`.
  - [x] 5.3 `SDL_EVENT_WINDOW_FOCUS_LOST`: Set `g_bWndActive = false`. If fullscreen (`!g_bUseWindowMode`) and `!g_HasInactiveFpsOverride`, save FPS and throttle to `REFERENCE_FPS`. Clear mouse state (MouseLButton, MouseRButton, etc.) in windowed mode. Call `mu::MuPlatform::SetMouseGrab(false)`.
  - [x] 5.4 `SDL_EVENT_WINDOW_MINIMIZED`: Apply same focus-loss logic as 5.3 (minimized implies inactive).
  - [x] 5.5 `SDL_EVENT_WINDOW_RESTORED`: Apply same focus-gain logic as 5.2 (restored implies re-active).

- [x] **Task 6 — Replace EnumDisplaySettings in non-Windows path** (AC: 2)
  - [x] 6.1 In `Winmain.cpp`, the `EnumDisplaySettings` / `ChangeDisplaySettings` block is already inside `#ifdef _WIN32` context (Win32-only game logic). Confirm via code inspection that the SDL3 path (`#ifndef _WIN32` or `#ifdef MU_ENABLE_SDL3`) calls `mu::MuPlatform::GetDisplaySize(WindowWidth, WindowHeight)` during initialization instead of `EnumDisplaySettings`. Add the SDL3 display query call in the `MuMain()` function non-Windows initialization path.
  - [x] 6.2 Log the result: `g_ErrorReport.Write(L"[VS1-SDL-WINDOW-FOCUS] Display size: %dx%d\r\n", WindowWidth, WindowHeight)`.

- [x] **Task 7 — Tests** (AC-STD-2)
  - [x] 7.1 In `MuMain/tests/platform/test_platform_window.cpp`, add test cases (guarded `#ifdef MU_ENABLE_SDL3`):
    - `TEST_CASE("SDLWindow::SetFullscreen does not crash when window is null")` — construct SDLWindow without calling Create(), call SetFullscreen(true), verify no crash (null-guard test).
    - `TEST_CASE("SDLWindow::SetMouseGrab does not crash when window is null")` — same null-guard pattern.
    - `TEST_CASE("MuPlatform::GetDisplaySize returns false when no window created")` — call `MuPlatform::GetDisplaySize` with no active window, verify returns `false`.
  - [x] 7.2 Add CMake script-mode test `test_ac_std11_flow_code_2_1_2.cmake` that verifies `VS1-SDL-WINDOW-FOCUS` string appears in `SDLEventLoop.cpp`.

- [x] **Task 8 — Quality Gate Verification** (AC-STD-13)
  - [x] 8.1 Run `make -C MuMain format-check` — fix any formatting issues.
  - [x] 8.2 Run `make -C MuMain lint` (cppcheck) — resolve all warnings to zero.
  - [x] 8.3 Verify `./ctl check` passes locally on macOS.

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| MU_ERR_FULLSCREEN_FAILED | Platform | N/A | SDL3 fullscreen set failed: {sdl_error} |
| MU_ERR_DISPLAY_QUERY_FAILED | Platform | N/A | SDL3 display mode query failed: {sdl_error} |

**Note:** Add new codes to `docs/error-catalog.md`. Surface via `g_ErrorReport.Write()`.

---

## Contract Catalog Entries

### API Contracts

N/A — platform infrastructure story with no HTTP endpoints.

### Event Contracts

N/A — no event-bus events produced or consumed.

### Navigation Entries

N/A — infrastructure story, no screen navigation.

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 v3.7.1 | Platform module (null-guard paths) | SetFullscreen null-guard, SetMouseGrab null-guard, GetDisplaySize returns false with no window |
| CMake script | CMake -P mode | AC-STD-11 flow code | VS1-SDL-WINDOW-FOCUS present in SDLEventLoop.cpp |
| Manual | Platform-specific | Critical paths | Alt-Tab behavior on macOS arm64 and Linux x64; fullscreen toggle; cursor confinement |

---

## Dev Notes

### Architecture Context

This story implements the focus/display subsection of CROSS_PLATFORM_PLAN.md Phase 1 (Session 1.3 — focus, fullscreen, display). It builds directly on Story 2.1.1's `SDLEventLoop::PollEvents()`, which left five window events as no-ops with TODO comments pointing to this story.

**Key observation from 2.1.1 code:** `SDLEventLoop.cpp` already has the correct `switch` cases with `// No-op — will be mapped in story 2.1.2` comments for all five events. Task 5 replaces these stubs with real handler logic.

**Existing focus behavior in Win32 WndProc (Winmain.cpp ~L488–526):**

```
WM_ACTIVATE → WA_INACTIVE:
  g_bWndActive = false
  if fullscreen && !g_HasInactiveFpsOverride:
    save GetTargetFps() → g_TargetFpsBeforeInactive
    SetTargetFps(REFERENCE_FPS)
    g_HasInactiveFpsOverride = true
  if windowed mode:
    clear all mouse button state

WM_ACTIVATE → WA_ACTIVE:
  g_bWndActive = true
  if g_HasInactiveFpsOverride:
    restore SetTargetFps(g_TargetFpsBeforeInactive)
    g_HasInactiveFpsOverride = false
```

This exact logic must be replicated in `SDLEventLoop.cpp` for `SDL_EVENT_WINDOW_FOCUS_LOST` and `SDL_EVENT_WINDOW_FOCUS_GAINED`. The `ACTIVE_FOCUS_OUT` preprocessor guard in Win32 (which conditionally applies `g_bWndActive = false` only in fullscreen) should be handled by checking `!g_bUseWindowMode` in the SDL3 path.

**Platform interface hierarchy (established in 2.1.1, extended here):**

```
mu::MuPlatform (static facade — MuPlatform.h/cpp)
└── IPlatformWindow (abstract — Platform/IPlatformWindow.h)
    ├── SDLWindow   (Platform/sdl3/SDLWindow.h)    ← MU_ENABLE_SDL3=ON
    │   + SetFullscreen(), SetMouseGrab(), GetDisplaySize()  [NEW in this story]
    └── Win32Window (Platform/win32/Win32Window.h) ← Windows / MU_ENABLE_SDL3=OFF
        + SetFullscreen() stub, SetMouseGrab() stub, GetDisplaySize() via GetSystemMetrics()  [NEW]
```

### SDL3 API Notes (release-3.2.8)

**Fullscreen:**
- `SDL_SetWindowFullscreen(SDL_Window* window, bool fullscreen)` — pass `true` for fullscreen, `false` for windowed. Returns `true` on success in SDL3 (note: return type is `bool` in SDL3, not `int` like SDL2).
- Do NOT use `SDL_SetWindowDisplayMode` (SDL2 approach) — SDL3 unified API is `SDL_SetWindowFullscreen`.
- Check return value and log SDL_GetError() on failure.

**Display query:**
- `SDL_GetDisplayForWindow(SDL_Window*)` → `SDL_DisplayID` — gets the display the window is on (handles multi-monitor correctly).
- `SDL_GetCurrentDisplayMode(SDL_DisplayID, SDL_DisplayMode*)` → `bool` — fills the mode struct. Returns `false` on failure.
- `SDL_DisplayMode` fields: `w` (int, pixels), `h` (int, pixels), `refresh_rate` (float, Hz).
- This correctly detects multi-monitor display sizes, unlike `GetSystemMetrics(SM_CXSCREEN)` which returns the primary monitor.

**Mouse grab:**
- `SDL_SetWindowMouseGrab(SDL_Window*, bool)` — confines the mouse to the window area. On Wayland/macOS this may be a no-op if the compositor does not support it; do not assert on it.
- Do NOT use `SDL_CaptureMouse` (that is for capturing events outside the window, not confinement).

**Minimize/restore:**
- `SDL_EVENT_WINDOW_MINIMIZED` — window is minimized (iconified).
- `SDL_EVENT_WINDOW_RESTORED` — window is restored from minimized.
- These are distinct from focus events. A window can be focused but minimized (e.g. on some desktops). Map both minimized → inactive and restored → active for simplicity, matching the existing Win32 behavior.

### Key Externs Required in SDLEventLoop.cpp

These external variables must be `extern`-declared in `SDLEventLoop.cpp` for the focus handler to compile:

```cpp
// Existing externs (already present for Destroy):
extern bool Destroy;

// New externs needed for focus/FPS handling:
extern bool g_bWndActive;
extern bool g_bUseWindowMode;          // BOOL — false = fullscreen
extern bool g_HasInactiveFpsOverride;
extern double g_TargetFpsBeforeInactive;

// Function declarations (defined in Winmain.cpp):
double GetTargetFps();
void SetTargetFps(double fps);

// Constant (defined in Winmain.cpp or header):
// REFERENCE_FPS — the throttled FPS value when inactive

// Mouse state (cleared on focus-loss in windowed mode):
extern bool MouseLButton;
extern bool MouseLButtonPop;
extern bool MouseRButton;
extern bool MouseRButtonPop;
extern bool MouseRButtonPush;
extern bool MouseLButtonDBClick;
extern bool MouseMButton;
extern bool MouseMButtonPop;
extern bool MouseMButtonPush;
extern int MouseWheel;
```

Before adding these externs, verify each variable's exact name and type by checking `Winmain.cpp` declarations. Use `grep` to confirm. Do NOT guess — the game uses a mix of `BOOL`, `bool`, `int` for historically-named globals.

### CMake Guard Pattern (established in 2.1.1 — do NOT change)

```cmake
if(MU_ENABLE_SDL3)
    # SDL3 sources already in MUPlatform from 2.1.1 — just add new .cpp files if any
    # SDLWindow.cpp and SDLEventLoop.cpp are already included
endif()
```

This story adds NO new CMake source files — it modifies existing `SDLWindow.cpp`, `SDLEventLoop.cpp`, `Win32Window.cpp`, and `MuPlatform.cpp`. No CMake changes needed unless new `.cpp` files are introduced.

### WinMain.cpp Modification Boundary

Winmain.cpp must be touched in Task 6 to add the SDL3 display query in the `MuMain()` non-Windows initialization path. The existing `EnumDisplaySettings` block is inside the Win32-only code path (inside `#ifdef _WIN32` or only reached when `g_bUseWindowMode == FALSE && g_bUseFullscreenMode == TRUE`).

**Exact location to add SDL3 display query:** In the `MuMain()` function, after `mu::MuPlatform::CreateWindow(...)` (not before, because `SDL_GetDisplayForWindow` requires an existing window), add:

```cpp
#ifdef MU_ENABLE_SDL3
    {
        int nDisplayW = WindowWidth;
        int nDisplayH = WindowHeight;
        if (mu::MuPlatform::GetDisplaySize(nDisplayW, nDisplayH))
        {
            g_ErrorReport.Write(L"[VS1-SDL-WINDOW-FOCUS] Display size: %dx%d\r\n", nDisplayW, nDisplayH);
            // Only override window dimensions in fullscreen mode
            if (!g_bUseWindowMode)
            {
                WindowWidth = nDisplayW;
                WindowHeight = nDisplayH;
            }
        }
    }
#endif
```

### Mouse State Variables — Verification Required

Before writing the focus-loss mouse-clear code, verify all mouse globals exist with these exact names in `Winmain.cpp`:

```cpp
extern bool MouseLButton;       // check Winmain.cpp for exact type
extern bool MouseLButtonPop;
extern bool MouseRButton;
extern bool MouseRButtonPop;
extern bool MouseRButtonPush;
extern bool MouseLButtonDBClick;
extern bool MouseMButton;
extern bool MouseMButtonPop;
extern bool MouseMButtonPush;
extern int  MouseWheel;
```

These are set to false/0 in the Win32 `WM_ACTIVATE → WA_INACTIVE` handler (windowed mode only). Replicate that same conditional reset in `SDL_EVENT_WINDOW_FOCUS_LOST`.

### PCC Project Constraints

**Prohibited (never use in new code):**
- Raw `new` / `delete` — use `std::unique_ptr<T>`
- `NULL` — use `nullptr`
- `#ifdef _WIN32` in game logic files — only permitted in `Platform/` abstraction layer
- Win32 display APIs (`EnumDisplaySettings`, `ChangeDisplaySettings`, `GetSystemMetrics`) in SDL3 code paths — replace with SDL3 equivalents
- `GetAsyncKeyState` — deferred to story 2.2.1

**Required patterns:**
- `[[nodiscard]]` on all functions that return error codes or handles
- `std::unique_ptr` for owned objects
- `g_ErrorReport.Write()` for post-mortem errors with `MU_ERR_*` prefix
- `g_ConsoleDebug->Write()` for live debug diagnostics
- `MU_ENABLE_SDL3` compile-time guard for all SDL3 code
- Catch2 v3.7.1 for tests (FetchContent, `BUILD_TESTING=ON`)
- `VS1-SDL-WINDOW-FOCUS` flow code in log messages and test names

**Quality gate command:** `make -C MuMain format-check && make -C MuMain lint`

### Project Structure Notes

Files to modify (NO new files needed unless adding test helpers):

```
MuMain/src/source/Platform/
├── IPlatformWindow.h          [MODIFY] — add SetFullscreen(), SetMouseGrab(), GetDisplaySize()
├── MuPlatform.h               [MODIFY] — add facade declarations
├── MuPlatform.cpp             [MODIFY] — add facade implementations
├── sdl3/
│   ├── SDLWindow.h            [MODIFY] — add method declarations
│   ├── SDLWindow.cpp          [MODIFY] — implement SetFullscreen, SetMouseGrab, GetDisplaySize
│   └── SDLEventLoop.cpp       [MODIFY] — replace 5 no-op cases with real focus/minimize handlers
└── win32/
    ├── Win32Window.h          [MODIFY] — add method declarations
    └── Win32Window.cpp        [MODIFY] — implement stubs / GetSystemMetrics path

MuMain/src/source/Main/
└── Winmain.cpp                [MODIFY] — add SDL3 display query in MuMain() init path (Task 6)

MuMain/tests/platform/
├── test_platform_window.cpp   [MODIFY] — add 3 new null-guard test cases
└── test_ac_std11_flow_code_2_1_2.cmake  [NEW] — CMake script test for flow code
```

### Scope Boundary

This story covers: focus events, minimize/restore events, fullscreen toggle, display mode query, mouse cursor confinement on focus change.

This story does NOT cover:
- SDL3 keyboard input (`GetAsyncKeyState` replacement) → story 2.2.1
- SDL3 mouse click/scroll event handling → story 2.2.2
- SDL3 text input / IME → story 2.2.3
- SwapBuffers / OpenGL context migration → EPIC-4
- Multi-monitor window placement → deferred (out of scope for S5.2→6 migration)

### Previous Story Intelligence (from 2.1.1)

Key learnings from story 2.1.1 that MUST be carried forward:

1. **SDLEventLoop already has stubs** — the `// No-op — will be mapped in story 2.1.2` comments are in the correct switch cases. Task 5 fills them in.
2. **SDL3 pinned to `release-3.2.8`** via FetchContent — do NOT change the version.
3. **`SDL3::SDL3-static`** is the correct CMake target.
4. **CI Strategy B** is established: `-DMU_ENABLE_SDL3=OFF` in MinGW — do not break this. New SDL3 code must be inside `#ifdef MU_ENABLE_SDL3` guards.
5. **No new CMake source files** in this story — only modifying existing files.
6. **`g_ErrorReport.Write()`** (not `wprintf`) for all error logging. Use `%hs` for `const char*` SDL error strings in wide-char format strings.
7. **Catch2 null-guard pattern** — test methods on an uninitialized SDL object (SDL not initialized, window pointer is null). The window methods must null-check `m_pWindow` before calling SDL APIs. SDLWindow already does this in `SetTitle`/`SetSize` — follow the same pattern for new methods.
8. **`extern bool Destroy`** is the existing coupling mechanism between SDL event loop and game state — the new externs follow the same pattern.

### References

- [Source: _bmad-output/project-context.md]
- [Source: docs/development-standards.md — Banned Win32 API table §1, C++ Conventions §2, Error Handling §2]
- [Source: _bmad-output/stories/2-1-1-sdl3-window-event-loop/story.md — Platform hierarchy, SDL3 API notes, CMake guard pattern, previous story learnings]
- [Source: MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp — 5 stub cases to fill in]
- [Source: MuMain/src/source/Platform/sdl3/SDLWindow.cpp — null-guard pattern for SetTitle/SetSize]
- [Source: MuMain/src/source/Main/Winmain.cpp L488–526 — WM_ACTIVATE handler to replicate]
- [Source: MuMain/src/source/Platform/IPlatformWindow.h — interface to extend]

---

## Dev Agent Record

### Agent Model Used

claude-opus-4-6 (dev-story workflow)

### Debug Log References

- Made `g_TargetFpsBeforeInactive` and `g_HasInactiveFpsOverride` non-static in Winmain.cpp so SDLEventLoop.cpp can extern them
- Used `INACTIVE_REFERENCE_FPS` local constant (25.0) in SDLEventLoop.cpp instead of including ZzzAI.h to avoid coupling Platform layer to Gameplay headers
- SDL3 `SDL_GetCurrentDisplayMode` returns `const SDL_DisplayMode*` (not bool+out-param) — adapted from story spec which assumed SDL2-style API

### Completion Notes List

- Story created by create-story workflow on 2026-03-06
- PCC compliant: SAFe metadata, AC-STD sections, prohibited/required patterns documented
- Infrastructure story type — Visual Design Specification section not applicable (removed)
- Schema alignment: N/A (C++20 game client, no HTTP API schemas)
- Previous story intelligence from 2.1.1 incorporated (SDLEventLoop stubs, extern pattern, SDL3 API notes)
- Git intelligence: recent commits show 2.1.1 code-review finalized — clean base for 2.1.2
- Story 2.1.1 dev-agent record shows SDLEventLoop.cpp has 5 explicit stubs pointing to this story
- Implementation complete 2026-03-06: All 8 tasks done, quality gate passed (688/688 files clean)
- ATDD checklist: 33/33 items checked (100%)
- Error catalog created with MU_ERR_FULLSCREEN_FAILED and MU_ERR_DISPLAY_QUERY_FAILED
- Test scenarios documented in _bmad-output/test-scenarios/epic-2/2-1-2-window-focus-display.md

### Change Log

- 2026-03-06: Implementation complete — all tasks 1-8 done in single session
- 2026-03-06: Code review finalize — 7 issues fixed (1 HIGH, 5 MEDIUM, 1 LOW), quality gate passed, story marked done
- 2026-03-06: BMM code review — 3 MEDIUM, 2 LOW found. Fixed: stale RED PHASE header in CMake test, corrected File List statuses (EXISTING→MODIFIED/NEW), standardized g_bUseWindowMode comparison style in Winmain.cpp SDL3 block

### File List

| File | Status | Notes |
|------|--------|-------|
| `MuMain/src/source/Platform/IPlatformWindow.h` | MODIFIED | Added SetFullscreen(), SetMouseGrab(), GetDisplaySize() pure virtuals |
| `MuMain/src/source/Platform/MuPlatform.h` | MODIFIED | Added SetFullscreen(), SetMouseGrab(), GetDisplaySize() facade declarations |
| `MuMain/src/source/Platform/MuPlatform.cpp` | MODIFIED | Added facade implementations delegating to s_pWindow |
| `MuMain/src/source/Platform/sdl3/SDLWindow.h` | MODIFIED | Added method declarations |
| `MuMain/src/source/Platform/sdl3/SDLWindow.cpp` | MODIFIED | Implemented SetFullscreen (SDL_SetWindowFullscreen), SetMouseGrab (SDL_SetWindowMouseGrab), GetDisplaySize (SDL_GetCurrentDisplayMode) |
| `MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp` | MODIFIED | Replaced 5 no-op stubs with HandleFocusGain/HandleFocusLoss handlers; added externs for game state |
| `MuMain/src/source/Platform/win32/Win32Window.h` | MODIFIED | Added method declarations |
| `MuMain/src/source/Platform/win32/Win32Window.cpp` | MODIFIED | Added SetFullscreen/SetMouseGrab no-op stubs, GetDisplaySize via GetSystemMetrics |
| `MuMain/src/source/Main/Winmain.cpp` | MODIFIED | Made g_TargetFpsBeforeInactive/g_HasInactiveFpsOverride non-static; added SDL3 display query in MuMain() init |
| `MuMain/tests/platform/test_platform_window.cpp` | MODIFIED | Added 6 test cases for story 2.1.2 (null-guard + active-window tests) |
| `MuMain/tests/platform/test_ac_std11_flow_code_2_1_2.cmake` | NEW | CMake script test verifying VS1-SDL-WINDOW-FOCUS flow code in SDLEventLoop.cpp |
| `docs/error-catalog.md` | NEW | Error catalog with MU_ERR_FULLSCREEN_FAILED and MU_ERR_DISPLAY_QUERY_FAILED |
| `_bmad-output/test-scenarios/epic-2/2-1-2-window-focus-display.md` | NEW | Test scenarios for AC validation |
