# Story 2.2.2: SDL3 Mouse Input Migration

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 2 - SDL3 Windowing & Input Migration |
| Feature | 2.2 - Input |
| Story ID | 2.2.2 |
| Story Points | 3 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-1 |
| Flow Code | VS1-SDL-INPUT-MOUSE |
| FRs Covered | FR21 — Mouse interaction on all platforms via SDL3 |
| Prerequisites | 2.1.1 done (SDL3 window + event loop established); 2.1.2 done (focus/display management); 2.2.1 done (keyboard input) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | SDLEventLoop: add SDL mouse event handlers feeding global mouse state vars; PlatformCompat.h: add ShowCursor, SetCursorPos, GetDoubleClickTime shims; PlatformTypes.h: add POINT struct shim |
| project-docs | documentation | Test scenarios for story 2.2.2 |

---

## Story

**[VS-1] [Flow:F]**

**As a** player,
**I want** mouse input handled by SDL3,
**so that** I can click UI elements, select targets, and navigate on macOS and Linux.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** Mouse position (`MouseX`, `MouseY`) is updated from SDL3 `SDL_EVENT_MOUSE_MOTION` events — coordinates normalized to the game's 640x480 virtual coordinate space using `g_fScreenRate_x` / `g_fScreenRate_y` — identical to the existing `WM_MOUSEMOVE` handler in `WndProc`.
- [ ] **AC-2:** Left, right, and middle mouse button press/release events (`SDL_EVENT_MOUSE_BUTTON_DOWN` / `SDL_EVENT_MOUSE_BUTTON_UP`) correctly update all six button state globals (`MouseLButton`, `MouseLButtonPush`, `MouseLButtonPop`, `MouseRButton`, `MouseRButtonPush`, `MouseRButtonPop`, `MouseMButton`, `MouseMButtonPush`, `MouseMButtonPop`) — including the double-click flag (`MouseLButtonDBClick`) — matching the semantics of the `WM_LBUTTONDOWN` / `WM_RBUTTONDOWN` / `WM_MBUTTONDOWN` handlers.
- [ ] **AC-3:** Mouse wheel scroll events (`SDL_EVENT_MOUSE_WHEEL`) update `MouseWheel` with the correct sign and delta matching the Win32 `WM_MOUSEWHEEL` / `WHEEL_DELTA` behavior (positive = scroll up, negative = scroll down).
- [ ] **AC-4:** Mouse cursor visibility is controllable: `ShowCursor(FALSE)` hides the cursor via `SDL_HideCursor()`, `ShowCursor(TRUE)` shows it via `SDL_ShowCursor()` — existing call sites in `Winmain.cpp` work without modification.
- [ ] **AC-5:** `SetCursorPos(x, y)` is shimmed on non-Windows to `SDL_WarpMouseInWindow()` mapping the Win32 screen-space coordinates to SDL window coordinates — three call sites (`ZzzInterface.cpp:4089`, `WSclient.cpp:6170`, `NewUITrade.cpp:600`) work without modification.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code standards compliance — PascalCase public functions, `m_` Hungarian member prefix, `std::unique_ptr` (no raw `new`/`delete`), `nullptr`, `#pragma once`, Allman braces, 4-space indent, LF line endings, UTF-8 files. No `#ifdef _WIN32` in game logic — only in `Platform/` layer and `PlatformCompat.h`.
- [ ] **AC-STD-2:** Testing requirements — Catch2 v3.7.1 unit tests in `MuMain/tests/platform/`; tests cover: mouse button state transitions (down→pop, held→push), MouseWheel delta sign, coordinate normalization math, ShowCursor shim callable (compiled successfully under `#ifdef MU_ENABLE_SDL3`).
- [ ] **AC-STD-3:** No Win32 mouse WM_* handling remains required on SDL3 path — all mouse state is fed from SDL events in `SDLEventLoop::PollEvents()`; `WndProc` mouse handlers remain intact for the Win32 path (zero regression).
- [ ] **AC-STD-8:** Error catalog — SDL mouse init failures (if any) log via `g_ErrorReport.Write()` with `MU_ERR_*` prefix and flow code `VS1-SDL-INPUT-MOUSE`.
- [ ] **AC-STD-10:** Contract catalogs — N/A (no HTTP API or event-bus contracts).
- [ ] **AC-STD-11:** Flow code `VS1-SDL-INPUT-MOUSE` appears in log output (`g_ErrorReport.Write`), test names, and story artifacts.
- [ ] **AC-STD-12:** SLI/SLO targets — N/A for platform infrastructure story; mouse event handler in `PollEvents()` must complete in < 1 microsecond per event (table dispatch — verified by design).
- [ ] **AC-STD-13:** Quality gate passes: `make -C MuMain format-check && make -C MuMain lint`
- [ ] **AC-STD-14:** Observability — SDL mouse init errors (if any) logged via `g_ErrorReport.Write()` with `MU_ERR_MOUSE_*` prefix and flow code `VS1-SDL-INPUT-MOUSE`.
- [ ] **AC-STD-15:** Git safety — clean merge, no force push, no incomplete rebase.
- [ ] **AC-STD-16:** Correct test infrastructure — Catch2 v3.7.1 via FetchContent, tests in `MuMain/tests/platform/`, `BUILD_TESTING=ON` opt-in.
- [ ] **AC-STD-20:** N/A — no HTTP endpoints, event-bus entries, or nav-catalog screens in this story.

---

## Validation Artifacts

- [ ] **AC-VAL-1:** N/A — no HTTP endpoints.
- [ ] **AC-VAL-2:** Test scenarios documented in `_bmad-output/test-scenarios/epic-2/2-2-2-sdl3-mouse-input.md`
- [ ] **AC-VAL-3:** N/A — no seed data.
- [ ] **AC-VAL-4:** N/A — no API catalog entries.
- [ ] **AC-VAL-5:** N/A — no event-bus events.
- [ ] **AC-VAL-6:** Flow catalog entry `VS1-SDL-INPUT-MOUSE` confirmed in story artifacts.
**Manual validation (deferred to integration testing after EPIC-2 completes):**
- AC-VAL-1 (manual): Click-to-move, inventory drag-and-drop, UI button clicks on macOS arm64 and Linux x64 — requires full game compilation (blocked until EPIC-4 rendering migration).
- AC-VAL-2 (manual): Cursor visibility toggle (hidden during gameplay, visible in menus) on all platforms.
- AC-VAL-3 (manual): Mouse wheel scrolling in chat log and UI list windows.

---

## Tasks / Subtasks

- [ ] **Task 1 — Add POINT struct shim to PlatformTypes.h** (AC: 5)
  - [ ]1.1 In `PlatformTypes.h` (inside `#else // !_WIN32` block), add `struct POINT { long x; long y; };` — required by `CInput::Create()` and `CInput::Update()` which store `m_ptCursor` and `m_ptFormerCursor` as `POINT`.
  - [ ]1.2 Add `inline bool PtInRect(const RECT* prc, POINT pt)` shim — used by `Win.cpp`, `WinEx.cpp`, `Slider.cpp` for cursor hit-testing. Check if `RECT` is already defined in `PlatformTypes.h`; add it if not (`struct RECT { long left, top, right, bottom; };`).
  - [ ]1.3 Verify `SIZE` struct is defined in `PlatformTypes.h` — used by legacy UI code. Add `struct SIZE { long cx; long cy; };` if missing.

- [ ] **Task 2 — Add mouse Win32 API shims to PlatformCompat.h** (AC: 4, 5)
  - [ ]2.1 Add `ShowCursor(bool show)` shim inside `#ifdef MU_ENABLE_SDL3` (inside `#else // !_WIN32` block):
    ```cpp
    inline void ShowCursor(bool show)
    {
        if (show)
            SDL_ShowCursor();
        else
            SDL_HideCursor();
    }
    ```
    Guard existing call sites in `Winmain.cpp:222` (`ShowCursor(TRUE)`), `Winmain.cpp:603` (`ShowCursor(false)`), `Winmain.cpp:1057` (`ShowCursor(FALSE)`) — these must compile unchanged.
  - [ ]2.2 Add `SetCursorPos(int x, int y)` shim inside `#ifdef MU_ENABLE_SDL3` (inside `#else // !_WIN32` block):
    ```cpp
    inline void SetCursorPos(int x, int y)
    {
        // Map Win32 screen coordinates to SDL window coordinates.
        // Win32 call sites pass window-relative coordinates (WindowWidth/Height scale).
        // SDL_WarpMouseInWindow with nullptr targets the focused window.
        SDL_WarpMouseInWindow(nullptr, static_cast<float>(x), static_cast<float>(y));
    }
    ```
    Three call sites: `ZzzInterface.cpp:4089`, `WSclient.cpp:6170`, `NewUITrade.cpp:600` — all pass window-relative coordinates already scaled to `WindowWidth/Height`.
  - [ ]2.3 Add `GetDoubleClickTime()` shim inside `#else // !_WIN32` block (no SDL3 guard needed — pure portable):
    ```cpp
    inline DWORD GetDoubleClickTime()
    {
        // 500ms is the standard double-click interval on Windows.
        // SDL3 does not expose a platform double-click time API.
        return 500u;
    }
    ```
    Used by `CInput::Create()` at `Input.cpp:40`.
  - [ ]2.4 Add `ScreenToClient(HWND /*hwnd*/, POINT* /*ppt*/)` stub inside `#else // !_WIN32` block:
    ```cpp
    inline void ScreenToClient(HWND /*hwnd*/, POINT* /*ppt*/)
    {
        // No-op on SDL3 path: mouse coordinates from SDL_EVENT_MOUSE_MOTION
        // are already window-relative. CInput::Update() calls ScreenToClient()
        // but on the SDL3 path cursor position is fed directly via SDL events
        // into MouseX/MouseY — the CInput position is not used for gameplay.
    }
    ```
    Used by `Input.cpp:35` and `Input.cpp:67`.
  - [ ]2.5 Add `GetCursorPos(POINT* ppt)` stub inside `#else // !_WIN32` block:
    ```cpp
    inline void GetCursorPos(POINT* ppt)
    {
        // On SDL3 path, mouse position is maintained in MouseX/MouseY globals
        // via SDL_EVENT_MOUSE_MOTION. CInput::Update() calls GetCursorPos()
        // but the CInput cursor position system is superseded by the global
        // mouse state populated by SDLEventLoop.
        if (ppt != nullptr)
        {
            ppt->x = 0;
            ppt->y = 0;
        }
    }
    ```
    Used by `Input.cpp:34` and `Input.cpp:66`. The `CInput` system polls `VK_LBUTTON` / `VK_RBUTTON` / `VK_MBUTTON` via `SEASON3B::IsPress()` which routes through `ScanAsyncKeyState()` — on the SDL3 path, button state must also be shimmed (see Task 3 notes in Dev Notes).
  - [ ]2.6 Add `GetActiveWindow()` stub returning `(HWND)1` (non-null = window active) inside `#else // !_WIN32` block — used by `Input.cpp:202` to suppress input when the window is inactive. On the SDL3 path, focus management is handled by `HandleFocusGain`/`HandleFocusLoss` in `SDLEventLoop.cpp`.
    ```cpp
    inline HWND GetActiveWindow()
    {
        // On SDL3 path, focus state is managed by SDLEventLoop via g_bWndActive.
        // Return non-null so CInput::Update() does not zero out cursor state.
        return reinterpret_cast<HWND>(1);
    }
    ```

- [ ] **Task 3 — Feed mouse state from SDLEventLoop** (AC: 1, 2, 3)
  - [ ]3.1 In `SDLEventLoop.cpp`, add extern declarations for mouse state globals (defined in `ZzzOpenglUtil.cpp`):
    ```cpp
    extern float MouseX;
    extern float MouseY;
    extern int MouseWheel;
    extern bool MouseLButtonDBClick;
    extern int g_iNoMouseTime;
    extern float g_fScreenRate_x;
    extern float g_fScreenRate_y;
    extern int g_iMousePopPosition_x;
    extern int g_iMousePopPosition_y;
    ```
    Note: `MouseLButton`, `MouseLButtonPop`, `MouseRButton`, etc. are already declared as externs at the top of `SDLEventLoop.cpp` (added for focus-loss mouse clear in story 2.1.2). Verify and reuse them.
  - [ ]3.2 Add `SDL_EVENT_MOUSE_MOTION` handler in `SDLEventLoop::PollEvents()`:
    ```cpp
    case SDL_EVENT_MOUSE_MOTION:
        MouseX = event.motion.x / g_fScreenRate_x;
        MouseY = event.motion.y / g_fScreenRate_y;
        if (MouseX < 0.0f) MouseX = 0.0f;
        if (MouseX > 640.0f) MouseX = 640.0f;
        if (MouseY < 0.0f) MouseY = 0.0f;
        if (MouseY > 480.0f) MouseY = 480.0f;
        break;
    ```
    **IMPORTANT:** `event.motion.x` and `event.motion.y` are `float` in SDL3 (not `int` as in SDL2). Cast directly — no LOWORD/HIWORD extraction needed.
  - [ ]3.3 Add `SDL_EVENT_MOUSE_BUTTON_DOWN` handler (mirrors `WM_LBUTTONDOWN` / `WM_RBUTTONDOWN` / `WM_MBUTTONDOWN` logic from `WndProc`):
    ```cpp
    case SDL_EVENT_MOUSE_BUTTON_DOWN:
        g_iNoMouseTime = 0;
        switch (event.button.button)
        {
        case SDL_BUTTON_LEFT:
            MouseLButtonPop = false;
            if (!MouseLButton)
                MouseLButtonPush = true;
            MouseLButton = true;
            // SDL_CaptureMouse replaces SetCapture — ensures events received outside window
            SDL_CaptureMouse(true);
            break;
        case SDL_BUTTON_RIGHT:
            MouseRButtonPop = false;
            if (!MouseRButton)
                MouseRButtonPush = true;
            MouseRButton = true;
            SDL_CaptureMouse(true);
            break;
        case SDL_BUTTON_MIDDLE:
            MouseMButtonPop = false;
            if (!MouseMButton)
                MouseMButtonPush = true;
            MouseMButton = true;
            SDL_CaptureMouse(true);
            break;
        }
        break;
    ```
  - [ ]3.4 Add `SDL_EVENT_MOUSE_BUTTON_UP` handler (mirrors `WM_LBUTTONUP` / `WM_RBUTTONUP` / `WM_MBUTTONUP` logic):
    ```cpp
    case SDL_EVENT_MOUSE_BUTTON_UP:
        g_iNoMouseTime = 0;
        switch (event.button.button)
        {
        case SDL_BUTTON_LEFT:
            MouseLButtonPush = false;
            if (MouseLButton)
                MouseLButtonPop = true;
            MouseLButton = false;
            g_iMousePopPosition_x = static_cast<int>(MouseX);
            g_iMousePopPosition_y = static_cast<int>(MouseY);
            SDL_CaptureMouse(false);
            break;
        case SDL_BUTTON_RIGHT:
            MouseRButtonPush = false;
            if (MouseRButton)
                MouseRButtonPop = true;
            MouseRButton = false;
            SDL_CaptureMouse(false);
            break;
        case SDL_BUTTON_MIDDLE:
            MouseMButtonPush = false;
            if (MouseMButton)
                MouseMButtonPop = true;
            MouseMButton = false;
            SDL_CaptureMouse(false);
            break;
        }
        break;
    ```
  - [ ]3.5 Add `SDL_EVENT_MOUSE_WHEEL` handler (mirrors `WM_MOUSEWHEEL` logic):
    ```cpp
    case SDL_EVENT_MOUSE_WHEEL:
        // SDL3: event.wheel.y is positive = scroll up (away from user) — same sign as Win32 WHEEL_DELTA
        // Win32: HIWORD(wParam) / WHEEL_DELTA → positive = scroll up
        MouseWheel = static_cast<int>(event.wheel.y);
        break;
    ```
  - [ ]3.6 Add double-click detection for left button using SDL3's `event.button.clicks` field:
    ```cpp
    // Inside SDL_EVENT_MOUSE_BUTTON_DOWN, SDL_BUTTON_LEFT case:
    if (event.button.clicks == 2)
        MouseLButtonDBClick = true;
    ```
    SDL3 reports `clicks == 2` on the second click of a double-click sequence. This replaces `WM_LBUTTONDBLCLK`.
  - [ ]3.7 Clear `MouseLButtonDBClick = false` at the START of each `PollEvents()` call (before the `while(SDL_PollEvent)` loop) — mirrors `Winmain.cpp:611` which does this at the start of `WndProc` processing:
    ```cpp
    bool SDLEventLoop::PollEvents()
    {
        MouseLButtonDBClick = false; // Reset each frame before processing events
        // ... rest of existing code
    ```
  - [ ]3.8 Also reset `MouseWheel = 0` at the start of each `PollEvents()` call — `MouseWheel` is a per-frame accumulated value that must be cleared each frame (matches Win32 behavior where `WM_MOUSEWHEEL` only fires when scrolling occurs).

- [ ] **Task 4 — Handle VK_LBUTTON / VK_RBUTTON / VK_MBUTTON in GetAsyncKeyState shim** (AC: 2)
  - [ ]4.1 The `CInput::Update()` function calls `SEASON3B::IsPress(VK_LBUTTON)` / `IsPress(VK_RBUTTON)` / `IsPress(VK_MBUTTON)` — which routes through `ScanAsyncKeyState()` → `GetAsyncKeyState(VK_LBUTTON)`. On the SDL3 path the keyboard shim returns 0 for these VK codes (VK_LBUTTON=0x01, VK_RBUTTON=0x02, VK_MBUTTON=0x04) since they are not in the keyboard mapping table.
  - [ ]4.2 Add mouse button VK mappings to `MuVkToSdlScancode()` in `PlatformCompat.h` OR add a separate path: extend `GetAsyncKeyState()` shim to check the global mouse button state for mouse-button VK codes before consulting the scancode table:
    ```cpp
    // In GetAsyncKeyState() shim (PlatformCompat.h), add before the scancode lookup:
    // Mouse button VK codes — backed by global mouse state (populated by SDLEventLoop)
    extern bool MouseLButton;
    extern bool MouseRButton;
    extern bool MouseMButton;
    switch (vk)
    {
    case 0x01: return MouseLButton ? static_cast<uint16_t>(0x8000) : 0; // VK_LBUTTON
    case 0x02: return MouseRButton ? static_cast<uint16_t>(0x8000) : 0; // VK_RBUTTON
    case 0x04: return MouseMButton ? static_cast<uint16_t>(0x8000) : 0; // VK_MBUTTON
    }
    ```
    **IMPORTANT:** This ensures `CInput::Update()` correctly tracks double-click timing and button state transitions on the SDL3 path.
  - [ ]4.3 Add `VK_LBUTTON (0x01)`, `VK_RBUTTON (0x02)`, `VK_MBUTTON (0x04)` defines to `PlatformKeys.h` if not already present — check first.

- [ ] **Task 5 — Tests** (AC-STD-2)
  - [ ]5.1 Add `MuMain/tests/platform/test_platform_mouse.cpp` (new file, guarded `#ifdef MU_ENABLE_SDL3`):
    - `TEST_CASE("Mouse button state: LButton down sets MouseLButton=true and MouseLButtonPush=true")` — simulate SDL_EVENT_MOUSE_BUTTON_DOWN for SDL_BUTTON_LEFT, verify state transitions.
    - `TEST_CASE("Mouse button state: LButton up sets MouseLButtonPop=true and MouseLButton=false")` — simulate button up, verify pop flag set.
    - `TEST_CASE("MouseWheel: positive y maps to positive MouseWheel")` — verify sign convention.
    - `TEST_CASE("MouseWheel: negative y maps to negative MouseWheel")` — verify sign convention.
    - `TEST_CASE("Mouse coordinate: normalization clamps to 0-640 x range")` — test boundary clamping.
    - `TEST_CASE("GetDoubleClickTime shim: returns 500ms")` — `REQUIRE(GetDoubleClickTime() == 500u)`.
    - `TEST_CASE("GetAsyncKeyState: VK_LBUTTON returns 0x8000 when MouseLButton is true")` — set global, verify return value.
    - `TEST_CASE("GetAsyncKeyState: VK_LBUTTON returns 0 when MouseLButton is false")` — verify not held.
  - [ ]5.2 Add CMake script-mode test `test_ac_std11_flow_code_2_2_2.cmake` that verifies `VS1-SDL-INPUT-MOUSE` string appears in `SDLEventLoop.cpp`.
  - [ ]5.3 Add CMake script-mode test `test_ac_std3_no_raw_win32_mouse.cmake` that greps all non-Platform/ source files for `WM_MOUSEMOVE`, `WM_LBUTTONDOWN`, `WM_RBUTTONDOWN`, `SetCapture`, `ReleaseCapture` — reports occurrences (expected only in `Winmain.cpp` WndProc, fails if found in new files).
  - [ ]5.4 Register `test_platform_mouse.cpp` in `MuMain/tests/platform/CMakeLists.txt` — add to `MuTests` target under `BUILD_TESTING` guard.

- [ ] **Task 6 — Quality Gate Verification** (AC-STD-13)
  - [ ]6.1 Run `make -C MuMain format-check` — fix any formatting issues.
  - [ ]6.2 Run `make -C MuMain lint` (cppcheck) — resolve all warnings to zero.
  - [ ]6.3 Verify `./ctl check` passes locally on macOS.
  - [ ]6.4 Verify MinGW CI build is not broken — all new SDL3 code must be inside `#ifdef MU_ENABLE_SDL3` guards.

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| MU_ERR_MOUSE_WARP_FAILED | Platform | N/A | `MOUSE: cursor warp failed [VS1-SDL-INPUT-MOUSE]: {SDL_GetError()}` |

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
| Unit | Catch2 v3.7.1 | Platform module (mouse state logic) | Button state transitions, wheel sign convention, coordinate clamping, GetDoubleClickTime, VK_LBUTTON/RBUTTON/MBUTTON shim |
| CMake script | CMake -P mode | AC-STD-11 flow code | VS1-SDL-INPUT-MOUSE present in SDLEventLoop.cpp |
| CMake script | CMake -P mode | AC-STD-3 no new Win32 mouse | No WM_MOUSEMOVE / SetCapture outside WndProc / Platform/ |
| Manual | Platform-specific | Critical paths | Click-to-move, inventory drag-and-drop, UI buttons, cursor hide/show, mouse wheel in chat log on macOS arm64 and Linux x64 |

---

## Dev Notes

### Architecture Context

This story implements mouse input migration for CROSS_PLATFORM_PLAN.md Phase 1 (Session 1.3: `SetCapture`/`ReleaseCapture` → `SDL_CaptureMouse()`; Session 1.6: cursor APIs → SDL3). The approach mirrors story 2.2.1 (keyboard): a **global-state population approach** rather than replacing individual call sites.

**Two-tier mouse architecture in the codebase:**

**Tier 1 — Global mouse state (primary gameplay input):**
The game's primary mouse handling uses global variables defined in `ZzzOpenglUtil.cpp`:
```cpp
int MouseX, MouseY;           // position in 640x480 virtual space
bool MouseLButton;            // currently held
bool MouseLButtonPush;        // just pressed this frame
bool MouseLButtonPop;         // just released this frame
bool MouseLButtonDBClick;     // double-click this frame
bool MouseRButton, MouseRButtonPush, MouseRButtonPop;
bool MouseMButton, MouseMButtonPush, MouseMButtonPop;
int MouseWheel;               // scroll delta this frame
int g_iNoMouseTime;           // idle timer reset on any mouse event
int g_iMousePopPosition_x/y;  // position at last left-button-up
```
On Win32, these are populated by `WndProc` handling `WM_MOUSEMOVE`, `WM_LBUTTONDOWN`, etc. On SDL3, `SDLEventLoop::PollEvents()` will populate them from SDL events — **zero call-site changes** in game logic.

**Tier 2 — CInput singleton (legacy UI input):**
`CInput::Update()` (called from `SceneManager::UpdateSceneState()`) polls `VK_LBUTTON`/`VK_RBUTTON`/`VK_MBUTTON` via `SEASON3B::IsPress()` → `GetAsyncKeyState()`. It also calls `::GetCursorPos()` + `::ScreenToClient()` to update `m_ptCursor`. On SDL3:
- `GetCursorPos()` / `ScreenToClient()` are shimmed as no-ops (position is already in `MouseX`/`MouseY`).
- `VK_LBUTTON` / `VK_RBUTTON` / `VK_MBUTTON` are handled by extending `GetAsyncKeyState()` shim to check the global mouse state (Task 4).
- `GetDoubleClickTime()` is shimmed to return 500ms constant.
- `GetActiveWindow()` is shimmed to return non-null.

This makes `CInput` compile and function correctly without modifying `Input.cpp`.

**Key architectural constraint from story 2.1.1:** CI Strategy B is `MU_ENABLE_SDL3=OFF` in MinGW — all SDL3 code must stay behind `#ifdef MU_ENABLE_SDL3`. The new shims in `PlatformCompat.h` follow the existing pattern (`#else // !_WIN32` → `#ifdef MU_ENABLE_SDL3`).

**Platform interface hierarchy (from 2.1.1/2.1.2):**
```
mu::MuPlatform (static facade — MuPlatform.h/cpp)
└── IPlatformWindow (abstract — Platform/IPlatformWindow.h)
    ├── SDLWindow   (Platform/sdl3/SDLWindow.h)    [MU_ENABLE_SDL3=ON]
    └── Win32Window (Platform/win32/Win32Window.h) [Windows / MU_ENABLE_SDL3=OFF]

SDLEventLoop (Platform/sdl3/SDLEventLoop.cpp)
  [feeds MouseX/Y, MouseLButton*, MouseRButton*, MouseMButton*, MouseWheel]

PlatformCompat.h
  [ShowCursor, SetCursorPos, GetDoubleClickTime, GetCursorPos, ScreenToClient,
   GetActiveWindow shims — non-Windows only]

PlatformTypes.h
  [POINT, RECT, SIZE struct shims — non-Windows only]
```

### SDL3 API Notes (release-3.2.8 — pinned from story 2.1.1)

**Mouse motion:**
- `SDL_EVENT_MOUSE_MOTION` carries `event.motion.x`, `event.motion.y` as `float` (SDL3 changed from SDL2's `int`).
- These are window-relative pixel coordinates. Divide by `g_fScreenRate_x` / `g_fScreenRate_y` to get 640x480 virtual space.

**Mouse buttons:**
- `SDL_EVENT_MOUSE_BUTTON_DOWN` / `SDL_EVENT_MOUSE_BUTTON_UP` carry `event.button.button` (SDL_BUTTON_LEFT=1, SDL_BUTTON_RIGHT=3, SDL_BUTTON_MIDDLE=2).
- `event.button.clicks` is `1` for single click, `2` for double-click — use this instead of `WM_LBUTTONDBLCLK`.
- `SDL_CaptureMouse(true)` replaces `SetCapture()` — ensures mouse events continue to be received when button is held and cursor moves outside the window.
- `SDL_CaptureMouse(false)` replaces `ReleaseCapture()`.

**Mouse wheel:**
- `SDL_EVENT_MOUSE_WHEEL` carries `event.wheel.y` as `float`. Positive = scroll up (away from user), negative = scroll down — same sign convention as Win32 `WHEEL_DELTA`.
- Cast to `int` for `MouseWheel`. Note: SDL3 can produce sub-integer scroll deltas (trackpad); truncating to `int` is acceptable and matches the existing int type of `MouseWheel`.

**Cursor visibility:**
- `SDL_ShowCursor()` — shows the cursor (SDL3 changed API from SDL2's `SDL_ShowCursor(SDL_ENABLE)`).
- `SDL_HideCursor()` — hides the cursor.
- These are global (not per-window). The Win32 `ShowCursor()` function has a reference-count mechanism; the SDL3 shim does not need to replicate the reference count since the codebase uses it in a balanced show/hide pattern.

**Cursor warp:**
- `SDL_WarpMouseInWindow(SDL_Window* window, float x, float y)` — warps cursor. Pass `nullptr` for the focused window.
- Call sites pass Win32 screen-relative coordinates scaled to `WindowWidth/Height`. Since the SDL window IS the game window (full screen or windowed), these are already window-relative.

**`GetActiveWindow()` equivalent:**
- SDL3 does not have a direct equivalent. Use `g_bWndActive` (already maintained by `SDLEventLoop`) for focus-aware logic. The `GetActiveWindow()` shim returns non-null to prevent `CInput::Update()` from zeroing cursor state; actual focus management is handled by the SDL event loop.

### Mouse Reset on Frame Boundary

`MouseLButtonDBClick` and `MouseWheel` must be reset to `false`/`0` each frame BEFORE processing new events — identical to the Win32 path in `WndProc`:
- Win32: `MouseLButtonDBClick = false;` at `Winmain.cpp:611`, `MouseWheel` implied cleared between frames.
- SDL3: Clear at the START of `SDLEventLoop::PollEvents()`.

`MouseLButtonPop`, `MouseRButtonPop`, `MouseMButtonPop` are NOT cleared here — they are cleared in `WndProc`-equivalent logic at the start of the next button-down event. The existing `Winmain.cpp:612` pattern:
```cpp
if (MouseLButtonPop == true && (g_iMousePopPosition_x != MouseX || g_iMousePopPosition_y != MouseY))
    MouseLButtonPop = false;
```
...remains in `Winmain.cpp` and applies to the Win32 path. On the SDL3 path, `SDLEventLoop` mimics this by clearing `MouseLButtonPop` at the start of each `SDL_EVENT_MOUSE_BUTTON_DOWN/LEFT` event.

### VK_LBUTTON/RBUTTON/MBUTTON Shim — Implementation Detail

The `GetAsyncKeyState()` shim in `PlatformCompat.h` currently handles keyboard VK codes only. Extending it for mouse buttons requires access to the global `MouseLButton` / `MouseRButton` / `MouseMButton` booleans defined in `ZzzOpenglUtil.cpp`.

**Important ODR concern:** `MouseLButton` et al. are already declared as `extern` at the top of `SDLEventLoop.cpp` (story 2.1.2 added them for focus-loss clearing). To extend `GetAsyncKeyState()` in `PlatformCompat.h`, add:
```cpp
// In PlatformCompat.h, inside #ifdef MU_ENABLE_SDL3 block:
// Mouse button state — populated by SDLEventLoop, used by GetAsyncKeyState shim
extern bool MouseLButton;
extern bool MouseRButton;
extern bool MouseMButton;
```
These `extern` declarations in a header are safe — they are declarations (not definitions). The definitions remain in `ZzzOpenglUtil.cpp`.

### Files to Modify

```
MuMain/src/source/Platform/
├── PlatformTypes.h            [MODIFY] — add POINT, RECT, SIZE structs; PtInRect inline
├── PlatformCompat.h           [MODIFY] — add ShowCursor, SetCursorPos, GetDoubleClickTime,
│                                         GetCursorPos, ScreenToClient, GetActiveWindow shims;
│                                         extend GetAsyncKeyState for VK_LBUTTON/RBUTTON/MBUTTON;
│                                         add extern MouseLButton/R/M
└── sdl3/
    └── SDLEventLoop.cpp       [MODIFY] — add SDL_EVENT_MOUSE_MOTION, SDL_EVENT_MOUSE_BUTTON_DOWN,
                                          SDL_EVENT_MOUSE_BUTTON_UP, SDL_EVENT_MOUSE_WHEEL handlers;
                                          add MouseX/Y/Wheel/NoMouseTime externs;
                                          reset MouseLButtonDBClick and MouseWheel at frame start

MuMain/src/source/Platform/
└── PlatformKeys.h             [MODIFY if needed] — add VK_LBUTTON (0x01), VK_RBUTTON (0x02),
                                                      VK_MBUTTON (0x04) if not already present

MuMain/tests/platform/
├── test_platform_mouse.cpp    [NEW] — Catch2 tests for mouse state transitions and shims
├── test_ac_std11_flow_code_2_2_2.cmake [NEW] — flow code CMake test
└── test_ac_std3_no_raw_win32_mouse.cmake [NEW] — regression: no raw Win32 mouse APIs in new files
```

**Files explicitly NOT to modify:**
- `ZzzOpenglUtil.cpp` — global mouse variables are already defined there; no changes needed.
- `Winmain.cpp` — WndProc mouse handlers remain intact for Win32 path; `ShowCursor`/`SetCursorPos` calls compile unchanged via shim.
- `Core/Input.cpp` — `GetCursorPos`, `ScreenToClient`, `GetDoubleClickTime`, `GetActiveWindow`, `VK_LBUTTON` calls all compile via shims; no source changes.
- `ZzzInterface.cpp`, `WSclient.cpp`, `NewUITrade.cpp` — `SetCursorPos` calls compile unchanged via shim.
- Any game logic files — zero call-site modifications needed.

### Previous Story Intelligence (from 2.1.1, 2.1.2, 2.2.1)

Key learnings that MUST be carried forward:

1. **SDL3 pinned to `release-3.2.8`** via FetchContent — do NOT change the version.
2. **`SDL3::SDL3-static`** is the correct CMake target.
3. **CI Strategy B** is established: `-DMU_ENABLE_SDL3=OFF` in MinGW — all new SDL3 code must be inside `#ifdef MU_ENABLE_SDL3` guards.
4. **`g_ErrorReport.Write()`** (not `wprintf`) for all error logging. Use `%hs` for `const char*` SDL error strings in wide-char format strings.
5. **Catch2 null-guard pattern from 2.1.2** — test shim behavior in isolation, not requiring a live SDL window.
6. **`extern bool Destroy`** coupling pattern from 2.1.1 — new externs in `SDLEventLoop.cpp` follow the same style.
7. **Mouse state externs already declared in SDLEventLoop.cpp** (story 2.1.2 added `MouseLButton`, `MouseLButtonPop`, `MouseRButton`, `MouseRButtonPop`, `MouseRButtonPush`, `MouseLButtonDBClick`, `MouseMButton`, `MouseMButtonPop`, `MouseMButtonPush`, `MouseWheel` for focus-loss clearing) — verify list and reuse; do NOT re-declare.
8. **SDL3 API note** — `SDL_CaptureMouse` takes `bool` in SDL3, not `int` like SDL2's `SDL_CaptureMouse(SDL_TRUE)`. Verify against SDL3 `release-3.2.8` headers.
9. **SDL3 `event.motion.x/y` are `float`** — not `int` as in SDL2. Direct division by `g_fScreenRate_x` / `g_fScreenRate_y` without integer truncation.
10. **`SDL_ShowCursor()` / `SDL_HideCursor()`** — SDL3 split the single `SDL_ShowCursor(int)` into two separate functions. Verify against SDL3 `release-3.2.8` headers before implementing.

### PCC Project Constraints

**Prohibited (never use in new code):**
- Raw `new` / `delete` — use `std::unique_ptr<T>`
- `NULL` — use `nullptr`
- `#ifdef _WIN32` in game logic files — only permitted in `Platform/` abstraction layer and `PlatformCompat.h`
- Direct Win32 mouse APIs in new game logic — must go through shims or global mouse state
- `wprintf` for logging — use `g_ErrorReport.Write()` or `g_ConsoleDebug->Write()`

**Required patterns:**
- `[[nodiscard]]` on all functions that return error codes or handles
- `g_ErrorReport.Write()` for post-mortem errors with `MU_ERR_*` prefix
- `MU_ENABLE_SDL3` compile-time guard for all SDL3 code
- Catch2 v3.7.1 for tests (FetchContent, `BUILD_TESTING=ON`)
- `VS1-SDL-INPUT-MOUSE` flow code in log messages and test names

**Quality gate command:** `make -C MuMain format-check && make -C MuMain lint`

### References

- [Source: _bmad-output/project-context.md — Tech stack, prohibited/required patterns, banned Win32 API table]
- [Source: docs/development-standards.md §1 Banned Win32 API table (SetCapture/ReleaseCapture → SDL_CaptureMouse, ShowCursor → SDL_ShowCursor/HideCursor), §2 C++ Conventions, §2 Error Handling]
- [Source: _bmad-output/stories/2-1-1-sdl3-window-event-loop/story.md — SDL3 version, CMake guard pattern, CI Strategy B]
- [Source: _bmad-output/stories/2-1-2-sdl3-window-focus-display/story.md — extern pattern, focus loss handler, mouse state extern declarations]
- [Source: _bmad-output/stories/2-2-1-sdl3-keyboard-input/story.md — GetAsyncKeyState shim pattern, MuPlatformLogUnmappedVk pattern, CI Strategy B]
- [Source: MuMain/src/source/Platform/PlatformCompat.h — existing shim patterns (GetAsyncKeyState, timeGetTime, MessageBoxW, mu_wfopen)]
- [Source: MuMain/src/source/Platform/PlatformTypes.h — existing type shims (DWORD, BOOL, HWND, LOWORD/HIWORD)]
- [Source: MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp — PollEvents switch, HandleFocusLoss() mouse state externs already present]
- [Source: MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp L43-57 — Global mouse variable definitions]
- [Source: MuMain/src/source/Main/Winmain.cpp L614-690 — WM_MOUSE* WndProc handlers (logic to mirror)]
- [Source: MuMain/src/source/Main/Winmain.cpp L618-619 — g_fScreenRate_x/y coordinate normalization]
- [Source: MuMain/src/source/Core/Input.cpp — CInput::Create/Update Win32 API usage (GetCursorPos, ScreenToClient, GetDoubleClickTime, GetActiveWindow, VK_LBUTTON)]
- [Source: docs/CROSS_PLATFORM_PLAN.md Phase 1, Session 1.3 — SetCapture/ReleaseCapture → SDL_CaptureMouse]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (validate-create-story workflow)

### Debug Log References

### Completion Notes List

- Story created by validate-create-story workflow on 2026-03-06
- Story type: infrastructure (not frontend_feature / fullstack) — Visual Design Specification section not applicable
- Architecture decision: global-state population approach (mirrors story 2.2.1 keyboard shim pattern) — zero call-site changes in game logic
- Two-tier mouse architecture documented: Tier 1 (global state via WndProc/SDLEventLoop) + Tier 2 (CInput singleton via GetAsyncKeyState + GetCursorPos)
- MouseLButtonDBClick detection via event.button.clicks==2 (SDL3 native double-click support)
- SDL_CaptureMouse replaces SetCapture/ReleaseCapture — ensures events received outside window during drag
- CInput shims: GetCursorPos (no-op stub), ScreenToClient (no-op stub), GetDoubleClickTime (500ms constant), GetActiveWindow (returns non-null)
- VK_LBUTTON/RBUTTON/MBUTTON handled by extending GetAsyncKeyState shim with extern mouse state globals
- Mouse state externs (MouseLButton etc.) already declared in SDLEventLoop.cpp from story 2.1.2 — reuse, do not re-declare
- SDL3 API changes from SDL2 noted: motion.x/y are float; SDL_ShowCursor()/SDL_HideCursor() split; SDL_CaptureMouse takes bool
- 3 SetCursorPos call sites identified: ZzzInterface.cpp:4089, WSclient.cpp:6170, NewUITrade.cpp:600 — all shimmed with SDL_WarpMouseInWindow
- POINT/RECT/SIZE struct shims needed in PlatformTypes.h for CInput and legacy UI code compilation
- CI Strategy B maintained: all SDL3 code behind #ifdef MU_ENABLE_SDL3
- Previous story intelligence from 2.1.1, 2.1.2, 2.2.1 incorporated

### File List

| File | Status | Notes |
|------|--------|-------|
| `MuMain/src/source/Platform/PlatformTypes.h` | MODIFY | Add POINT, RECT, SIZE structs; PtInRect inline |
| `MuMain/src/source/Platform/PlatformCompat.h` | MODIFY | Add ShowCursor, SetCursorPos, GetDoubleClickTime, GetCursorPos, ScreenToClient, GetActiveWindow shims; extend GetAsyncKeyState for VK_LBUTTON/RBUTTON/MBUTTON; add extern MouseLButton/R/M |
| `MuMain/src/source/Platform/PlatformKeys.h` | MODIFY if needed | Add VK_LBUTTON (0x01), VK_RBUTTON (0x02), VK_MBUTTON (0x04) if not present |
| `MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp` | MODIFY | Add mouse event handlers; add MouseX/Y/Wheel/NoMouseTime externs; reset DBClick and Wheel each frame |
| `MuMain/tests/platform/test_platform_mouse.cpp` | NEW | Catch2 tests for mouse state transitions and shims |
| `MuMain/tests/platform/test_ac_std11_flow_code_2_2_2.cmake` | NEW | CMake script test verifying VS1-SDL-INPUT-MOUSE in SDLEventLoop.cpp |
| `MuMain/tests/platform/test_ac_std3_no_raw_win32_mouse.cmake` | NEW | CMake script regression test: no raw Win32 mouse APIs in new files |
| `docs/error-catalog.md` | MODIFY | Add MU_ERR_MOUSE_WARP_FAILED |
| `_bmad-output/test-scenarios/epic-2/2-2-2-sdl3-mouse-input.md` | NEW | Test scenarios for AC validation |
