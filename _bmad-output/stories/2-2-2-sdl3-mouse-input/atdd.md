# ATDD Checklist — Story 2.2.2: SDL3 Mouse Input Migration

**Story ID:** 2-2-2-sdl3-mouse-input
**Story Type:** infrastructure
**Flow Code:** VS1-SDL-INPUT-MOUSE
**Phase:** GREEN — Implementation complete and verified by code-review-finalize workflow.
**ATDD Date:** 2026-03-06

---

## AC-to-Test Mapping

| AC | Description | Test Method(s) | File |
|----|-------------|----------------|------|
| AC-1 | MouseX/Y from SDL_EVENT_MOUSE_MOTION, clamped to 640x480 | `AC-1 [VS1-SDL-INPUT-MOUSE]: Mouse coordinate normalization clamps to 0-640 x range` (3 sections) | `test_platform_mouse.cpp` |
| AC-2 | Button state: LButton/RButton/MButton + DBClick globals updated | `AC-2 [VS1-SDL-INPUT-MOUSE]: LButton down sets ...`, `LButton up sets ...`, `LButton double-click sets MouseLButtonDBClick=true`, `RButton ...`, `MButton ...`, `GetAsyncKeyState VK_LBUTTON/RBUTTON/MBUTTON ...`, `VK_LBUTTON VK_RBUTTON VK_MBUTTON constants defined` | `test_platform_mouse.cpp` |
| AC-3 | MouseWheel sign/delta matches Win32 | `AC-3 [VS1-SDL-INPUT-MOUSE]: MouseWheel positive y ...`, `MouseWheel negative y ...`, `MouseWheel reset to zero each frame` | `test_platform_mouse.cpp` |
| AC-4 | ShowCursor/GetDoubleClickTime shims | `AC-4 [VS1-SDL-INPUT-MOUSE]: GetDoubleClickTime shim returns 500ms`, `ShowCursor shim is callable ...` | `test_platform_mouse.cpp` |
| AC-5 | SetCursorPos shim + POINT struct | `AC-5 [VS1-SDL-INPUT-MOUSE]: POINT struct shim is defined in PlatformTypes.h` | `test_platform_mouse.cpp` |
| AC-STD-2 | Catch2 tests in MuMain/tests/platform/ | All TEST_CASEs in `test_platform_mouse.cpp` | `test_platform_mouse.cpp` |
| AC-STD-3 | No raw Win32 mouse WM_* in new files | `2.2.2-AC-STD-3:no-raw-win32-mouse` (CMake script test) | `test_ac_std3_no_raw_win32_mouse.cmake` |
| AC-STD-11 | VS1-SDL-INPUT-MOUSE flow code in SDLEventLoop.cpp | `2.2.2-AC-STD-11:flow-code-mouse` (CMake script test) | `test_ac_std11_flow_code_2_2_2.cmake` |

---

## PCC Compliance Summary

| Check | Status | Detail |
|-------|--------|--------|
| Prohibited libraries | PASS | No raw `new`/`delete`, no `NULL`, no `#ifdef _WIN32` in game logic |
| Required test patterns | PASS | Catch2 v3.7.1, `MU_ENABLE_SDL3` guard, GIVEN/WHEN/THEN structure |
| Test profiles | PASS | `BUILD_TESTING=ON` opt-in, FetchContent Catch2 |
| Frontend E2E | N/A | Infrastructure story — no frontend, no Playwright |
| Bruno API collection | N/A | No HTTP endpoints |
| Coverage target | N/A | Coverage threshold = 0 (growing incrementally per .pcc-config.yaml) |
| Flow code in logs | PASS | `VS1-SDL-INPUT-MOUSE` appears in `SDLEventLoop.cpp` (comments + MuPlatformLogMouseWarpFailed via SDLKeyboardState.cpp) |
| Quality gate | PASS | `make -C MuMain format-check && make -C MuMain lint` — 689/689 files clean |

---

## Implementation Checklist

### Task 1 — PlatformTypes.h: POINT / RECT / SIZE struct shims

- [x] `[AC-5]` POINT struct added to PlatformTypes.h inside `#else // !_WIN32` block: `struct POINT { long x; long y; };`
- [x] `[AC-5]` `inline bool PtInRect(const RECT* prc, POINT pt)` shim added (used by Win.cpp, WinEx.cpp, Slider.cpp)
- [x] `[AC-5]` RECT struct verified or added: `struct RECT { long left, top, right, bottom; };`
- [x] `[AC-5]` SIZE struct verified or added: `struct SIZE { long cx; long cy; };`

### Task 2 — PlatformCompat.h: Mouse API shims

- [x] `[AC-4]` `ShowCursor(bool show)` shim added inside `#ifdef MU_ENABLE_SDL3` / `#else // !_WIN32` block (routes to `SDL_ShowCursor()` / `SDL_HideCursor()`)
- [x] `[AC-5]` `SetCursorPos(int x, int y)` shim added — routes to `SDL_WarpMouseInWindow(nullptr, float(x), float(y))`
- [x] `[AC-4]` `GetDoubleClickTime()` shim added inside `#else // !_WIN32` — returns `500u`
- [x] `[AC-5]` `ScreenToClient(HWND, POINT*)` no-op stub added inside `#else // !_WIN32`
- [x] `[AC-5]` `GetCursorPos(POINT* ppt)` stub added inside `#else // !_WIN32` — sets ppt to {0,0} (SDL3 path uses MouseX/Y globals)
- [x] `[AC-5]` `GetActiveWindow()` stub added inside `#else // !_WIN32` — returns `reinterpret_cast<HWND>(1)` (non-null = active)

### Task 3 — PlatformCompat.h: GetAsyncKeyState extension for mouse VK codes

- [x] `[AC-2]` `extern bool MouseLButton / MouseRButton / MouseMButton` declarations added inside `#ifdef MU_ENABLE_SDL3` block in PlatformCompat.h
- [x] `[AC-2]` `GetAsyncKeyState()` shim extended with mouse VK switch before scancode lookup: `case 0x01 (VK_LBUTTON)`, `case 0x02 (VK_RBUTTON)`, `case 0x04 (VK_MBUTTON)` — each returns `0x8000` when corresponding global is `true`, else `0`
- [x] `[AC-2]` `VK_LBUTTON (0x01)`, `VK_RBUTTON (0x02)`, `VK_MBUTTON (0x04)` defines verified or added in PlatformKeys.h

### Task 4 — SDLEventLoop.cpp: Mouse event handlers

- [x] `[AC-1]` `extern int MouseX / MouseY;` externs added (or verified) in SDLEventLoop.cpp
- [x] `[AC-3]` `extern int MouseWheel;` extern added (or verified) in SDLEventLoop.cpp
- [x] `[AC-2]` `extern bool MouseLButtonDBClick;` extern added (or verified)
- [x] `[AC-1]` `extern int g_iNoMouseTime;` extern added (or verified)
- [x] `[AC-1]` `extern float g_fScreenRate_x / g_fScreenRate_y;` externs added (or verified)
- [x] `[AC-5]` `extern int g_iMousePopPosition_x / g_iMousePopPosition_y;` externs added (or verified)
- [x] `[AC-2]` `MouseLButtonDBClick = false;` reset added at the START of `PollEvents()` (before while loop)
- [x] `[AC-3]` `MouseWheel = 0;` reset added at the START of `PollEvents()` (before while loop)
- [x] `[AC-1]` `SDL_EVENT_MOUSE_MOTION` handler added: normalizes `event.motion.x / g_fScreenRate_x` → `MouseX`, clamps to [0, 640]; same for Y/480
- [x] `[AC-2]` `SDL_EVENT_MOUSE_BUTTON_DOWN` handler added for `SDL_BUTTON_LEFT` / `SDL_BUTTON_RIGHT` / `SDL_BUTTON_MIDDLE` — sets Push flags, SDL_CaptureMouse(true)
- [x] `[AC-2]` Double-click detection added inside `SDL_BUTTON_LEFT` case: `if (event.button.clicks == 2) MouseLButtonDBClick = true;`
- [x] `[AC-2]` `SDL_EVENT_MOUSE_BUTTON_UP` handler added for all three buttons — sets Pop flags, clears Push, SDL_CaptureMouse(false); sets g_iMousePopPosition_x/y on left-up
- [x] `[AC-3]` `SDL_EVENT_MOUSE_WHEEL` handler added: `MouseWheel = static_cast<int>(event.wheel.y);`
- [x] `[AC-STD-11]` Flow code `VS1-SDL-INPUT-MOUSE` appears in at least one `g_ErrorReport.Write()` call path — `MuPlatformLogMouseWarpFailed()` in SDLKeyboardState.cpp:33; flow code in SDLEventLoop.cpp comments (lines 28, 42, 123, 180)

### Task 5 — Tests

- [x] `[AC-STD-2]` `MuMain/tests/platform/test_platform_mouse.cpp` created (GREEN phase — implementation complete)
- [x] `[AC-STD-11]` `MuMain/tests/platform/test_ac_std11_flow_code_2_2_2.cmake` created
- [x] `[AC-STD-3]` `MuMain/tests/platform/test_ac_std3_no_raw_win32_mouse.cmake` created
- [x] `[AC-STD-16]` `test_platform_mouse.cpp` registered in `MuMain/tests/CMakeLists.txt` via `target_sources(MuTests PRIVATE ...)`
- [x] `[AC-STD-16]` CMake script tests registered in `MuMain/tests/platform/CMakeLists.txt` via `add_test()`

### Task 6 — Quality Gate

- [x] `[AC-STD-13]` `make -C MuMain format-check` passes (zero formatting violations)
- [x] `[AC-STD-13]` `make -C MuMain lint` (cppcheck) passes with zero warnings — 689/689 files clean
- [x] `[AC-STD-13]` `./ctl check` passes locally on macOS
- [x] `[AC-STD-13]` All new SDL3 code is inside `#ifdef MU_ENABLE_SDL3` — MinGW CI build unaffected

### PCC Compliance Items

- [x] No prohibited libraries used: no raw `new`/`delete`, no `NULL`, no `#ifdef _WIN32` in game logic files
- [x] Required testing patterns: Catch2 v3.7.1 via FetchContent, `BUILD_TESTING=ON` opt-in, `MU_ENABLE_SDL3` guard
- [x] Correct test profiles: tests in `MuMain/tests/platform/`, named `test_platform_mouse.cpp`
- [x] Flow code `VS1-SDL-INPUT-MOUSE` in: SDLEventLoop.cpp log message path (SDLKeyboardState.cpp:33), SDLEventLoop.cpp comments, test names, story artifacts
- [x] No Win32 mouse WM_* patterns introduced outside Winmain.cpp and Platform/ (verified by AC-STD-3 cmake test)
- [x] `[[nodiscard]]` on any new fallible functions (shims are `inline void` — not applicable)
- [x] Error code `MU_ERR_MOUSE_WARP_FAILED` added to `docs/error-catalog.md`

---

## Test Files Created (GREEN Phase)

| File | Type | Status |
|------|------|--------|
| `MuMain/tests/platform/test_platform_mouse.cpp` | Catch2 unit tests | GREEN — implementation complete; all tests pass including added double-click test |
| `MuMain/tests/platform/test_ac_std11_flow_code_2_2_2.cmake` | CMake script test | GREEN — VS1-SDL-INPUT-MOUSE present in SDLEventLoop.cpp |
| `MuMain/tests/platform/test_ac_std3_no_raw_win32_mouse.cmake` | CMake script regression | GREEN — no raw Win32 mouse patterns in new files |

---

## Validation Notes

- Manual validation (deferred to post-EPIC-2 integration): click-to-move, inventory drag-and-drop, cursor visibility toggle, mouse wheel in chat log on macOS arm64 and Linux x64 — requires full game compilation blocked until EPIC-4.
- `test_ac_std3_no_raw_win32_mouse.cmake` PASSES (no new raw Win32 mouse calls in new files). Regression guard active.
- `test_ac_std11_flow_code_2_2_2.cmake` PASSES — `VS1-SDL-INPUT-MOUSE` string verified in `SDLEventLoop.cpp`.
- Code review finalize workflow applied fixes on 2026-03-06: HIGH-1 (MouseLButtonPush missing from HandleFocusLoss), MEDIUM-2 (MouseLButtonPop position-drift clearing added to PollEvents), LOW-1 (double-click test case added to test_platform_mouse.cpp).
