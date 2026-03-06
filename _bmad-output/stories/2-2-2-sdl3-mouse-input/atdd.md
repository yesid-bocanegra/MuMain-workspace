# ATDD Checklist — Story 2.2.2: SDL3 Mouse Input Migration

**Story ID:** 2-2-2-sdl3-mouse-input
**Story Type:** infrastructure
**Flow Code:** VS1-SDL-INPUT-MOUSE
**Phase:** RED — All tests written; implementation pending.
**ATDD Date:** 2026-03-06

---

## AC-to-Test Mapping

| AC | Description | Test Method(s) | File |
|----|-------------|----------------|------|
| AC-1 | MouseX/Y from SDL_EVENT_MOUSE_MOTION, clamped to 640x480 | `AC-1 [VS1-SDL-INPUT-MOUSE]: Mouse coordinate normalization clamps to 0-640 x range` (3 sections) | `test_platform_mouse.cpp` |
| AC-2 | Button state: LButton/RButton/MButton + DBClick globals updated | `AC-2 [VS1-SDL-INPUT-MOUSE]: LButton down sets ...`, `LButton up sets ...`, `RButton ...`, `MButton ...`, `GetAsyncKeyState VK_LBUTTON/RBUTTON/MBUTTON ...`, `VK_LBUTTON VK_RBUTTON VK_MBUTTON constants defined` | `test_platform_mouse.cpp` |
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
| Flow code in logs | PENDING | `VS1-SDL-INPUT-MOUSE` must appear in `SDLEventLoop.cpp` error log |
| Quality gate | PENDING | `make -C MuMain format-check && make -C MuMain lint` |

---

## Implementation Checklist

### Task 1 — PlatformTypes.h: POINT / RECT / SIZE struct shims

- [ ] `[AC-5]` POINT struct added to PlatformTypes.h inside `#else // !_WIN32` block: `struct POINT { long x; long y; };`
- [ ] `[AC-5]` `inline bool PtInRect(const RECT* prc, POINT pt)` shim added (used by Win.cpp, WinEx.cpp, Slider.cpp)
- [ ] `[AC-5]` RECT struct verified or added: `struct RECT { long left, top, right, bottom; };`
- [ ] `[AC-5]` SIZE struct verified or added: `struct SIZE { long cx; long cy; };`

### Task 2 — PlatformCompat.h: Mouse API shims

- [ ] `[AC-4]` `ShowCursor(bool show)` shim added inside `#ifdef MU_ENABLE_SDL3` / `#else // !_WIN32` block (routes to `SDL_ShowCursor()` / `SDL_HideCursor()`)
- [ ] `[AC-5]` `SetCursorPos(int x, int y)` shim added — routes to `SDL_WarpMouseInWindow(nullptr, float(x), float(y))`
- [ ] `[AC-4]` `GetDoubleClickTime()` shim added inside `#else // !_WIN32` — returns `500u`
- [ ] `[AC-5]` `ScreenToClient(HWND, POINT*)` no-op stub added inside `#else // !_WIN32`
- [ ] `[AC-5]` `GetCursorPos(POINT* ppt)` stub added inside `#else // !_WIN32` — sets ppt to {0,0} (SDL3 path uses MouseX/Y globals)
- [ ] `[AC-5]` `GetActiveWindow()` stub added inside `#else // !_WIN32` — returns `reinterpret_cast<HWND>(1)` (non-null = active)

### Task 3 — PlatformCompat.h: GetAsyncKeyState extension for mouse VK codes

- [ ] `[AC-2]` `extern bool MouseLButton / MouseRButton / MouseMButton` declarations added inside `#ifdef MU_ENABLE_SDL3` block in PlatformCompat.h
- [ ] `[AC-2]` `GetAsyncKeyState()` shim extended with mouse VK switch before scancode lookup: `case 0x01 (VK_LBUTTON)`, `case 0x02 (VK_RBUTTON)`, `case 0x04 (VK_MBUTTON)` — each returns `0x8000` when corresponding global is `true`, else `0`
- [ ] `[AC-2]` `VK_LBUTTON (0x01)`, `VK_RBUTTON (0x02)`, `VK_MBUTTON (0x04)` defines verified or added in PlatformKeys.h

### Task 4 — SDLEventLoop.cpp: Mouse event handlers

- [ ] `[AC-1]` `extern float MouseX / MouseY;` externs added (or verified) in SDLEventLoop.cpp
- [ ] `[AC-3]` `extern int MouseWheel;` extern added (or verified) in SDLEventLoop.cpp
- [ ] `[AC-2]` `extern bool MouseLButtonDBClick;` extern added (or verified)
- [ ] `[AC-1]` `extern int g_iNoMouseTime;` extern added (or verified)
- [ ] `[AC-1]` `extern float g_fScreenRate_x / g_fScreenRate_y;` externs added (or verified)
- [ ] `[AC-5]` `extern int g_iMousePopPosition_x / g_iMousePopPosition_y;` externs added (or verified)
- [ ] `[AC-3]` `MouseLButtonDBClick = false;` reset added at the START of `PollEvents()` (before while loop)
- [ ] `[AC-3]` `MouseWheel = 0;` reset added at the START of `PollEvents()` (before while loop)
- [ ] `[AC-1]` `SDL_EVENT_MOUSE_MOTION` handler added: normalizes `event.motion.x / g_fScreenRate_x` → `MouseX`, clamps to [0, 640]; same for Y/480
- [ ] `[AC-2]` `SDL_EVENT_MOUSE_BUTTON_DOWN` handler added for `SDL_BUTTON_LEFT` / `SDL_BUTTON_RIGHT` / `SDL_BUTTON_MIDDLE` — sets Push flags, SDL_CaptureMouse(true)
- [ ] `[AC-2]` Double-click detection added inside `SDL_BUTTON_LEFT` case: `if (event.button.clicks == 2) MouseLButtonDBClick = true;`
- [ ] `[AC-2]` `SDL_EVENT_MOUSE_BUTTON_UP` handler added for all three buttons — sets Pop flags, clears Push, SDL_CaptureMouse(false); sets g_iMousePopPosition_x/y on left-up
- [ ] `[AC-3]` `SDL_EVENT_MOUSE_WHEEL` handler added: `MouseWheel = static_cast<int>(event.wheel.y);`
- [ ] `[AC-STD-11]` Flow code `VS1-SDL-INPUT-MOUSE` appears in at least one `g_ErrorReport.Write()` call in SDLEventLoop.cpp (e.g., `MU_ERR_MOUSE_WARP_FAILED [VS1-SDL-INPUT-MOUSE]`)

### Task 5 — Tests

- [ ] `[AC-STD-2]` `MuMain/tests/platform/test_platform_mouse.cpp` created (RED phase — all tests fail until implementation)
- [ ] `[AC-STD-11]` `MuMain/tests/platform/test_ac_std11_flow_code_2_2_2.cmake` created
- [ ] `[AC-STD-3]` `MuMain/tests/platform/test_ac_std3_no_raw_win32_mouse.cmake` created
- [ ] `[AC-STD-16]` `test_platform_mouse.cpp` registered in `MuMain/tests/CMakeLists.txt` via `target_sources(MuTests PRIVATE ...)`
- [ ] `[AC-STD-16]` CMake script tests registered in `MuMain/tests/platform/CMakeLists.txt` via `add_test()`

### Task 6 — Quality Gate

- [ ] `[AC-STD-13]` `make -C MuMain format-check` passes (zero formatting violations)
- [ ] `[AC-STD-13]` `make -C MuMain lint` (cppcheck) passes with zero warnings
- [ ] `[AC-STD-13]` `./ctl check` passes locally on macOS
- [ ] `[AC-STD-13]` All new SDL3 code is inside `#ifdef MU_ENABLE_SDL3` — MinGW CI build unaffected

### PCC Compliance Items

- [ ] No prohibited libraries used: no raw `new`/`delete`, no `NULL`, no `#ifdef _WIN32` in game logic files
- [ ] Required testing patterns: Catch2 v3.7.1 via FetchContent, `BUILD_TESTING=ON` opt-in, `MU_ENABLE_SDL3` guard
- [ ] Correct test profiles: tests in `MuMain/tests/platform/`, named `test_platform_mouse.cpp`
- [ ] Flow code `VS1-SDL-INPUT-MOUSE` in: SDLEventLoop.cpp log message, test names, story artifacts
- [ ] No Win32 mouse WM_* patterns introduced outside Winmain.cpp and Platform/ (verified by AC-STD-3 cmake test)
- [ ] `[[nodiscard]]` on any new fallible functions (shims are `inline void` — not applicable)
- [ ] Error code `MU_ERR_MOUSE_WARP_FAILED` added to `docs/error-catalog.md`

---

## Test Files Created (RED Phase)

| File | Type | Status |
|------|------|--------|
| `MuMain/tests/platform/test_platform_mouse.cpp` | Catch2 unit tests | RED — will fail until implementation |
| `MuMain/tests/platform/test_ac_std11_flow_code_2_2_2.cmake` | CMake script test | RED — will fail until VS1-SDL-INPUT-MOUSE in SDLEventLoop.cpp |
| `MuMain/tests/platform/test_ac_std3_no_raw_win32_mouse.cmake` | CMake script regression | Will PASS on clean codebase (no new Win32 mouse patterns yet) |

---

## Validation Notes

- Manual validation (deferred to post-EPIC-2 integration): click-to-move, inventory drag-and-drop, cursor visibility toggle, mouse wheel in chat log on macOS arm64 and Linux x64 — requires full game compilation blocked until EPIC-4.
- `test_ac_std3_no_raw_win32_mouse.cmake` is expected to PASS immediately (no new raw Win32 mouse calls exist yet). It is a regression guard — will fail if a developer accidentally adds `WM_MOUSEMOVE` etc. to a new game logic file.
- `test_ac_std11_flow_code_2_2_2.cmake` will FAIL (RED) until `SDLEventLoop.cpp` is modified to include the flow code in a log message.
