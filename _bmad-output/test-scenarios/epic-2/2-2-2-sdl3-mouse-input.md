# Test Scenarios: Story 2.2.2 — SDL3 Mouse Input Migration

**Generated:** 2026-03-06
**Story:** 2.2.2 SDL3 Mouse Input Migration
**Flow Code:** VS1-SDL-INPUT-MOUSE
**Project:** MuMain-workspace

These scenarios cover manual validation of Story 2.2.2 acceptance criteria.
Automated tests (Catch2 unit + CMake script) are in `MuMain/tests/platform/`.
Manual scenarios require full game compilation (blocked until EPIC-4 rendering
migration completes).

---

## AC-1: Mouse Position from SDL_EVENT_MOUSE_MOTION

### Scenario 1: Mouse position updates in 640x480 virtual space
- **Given:** Game running on macOS arm64 or Linux x64 with MU_ENABLE_SDL3=ON (requires EPIC-4)
- **When:** Player moves the mouse across the game window
- **Then:** `MouseX` and `MouseY` update to the correct virtual position (0-640, 0-480); cursor tracks pointer correctly
- **Automated:** `TEST_CASE("AC-1 [VS1-SDL-INPUT-MOUSE]: Mouse coordinate normalization clamps to 0-640 x range")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 2: Mouse clamped at window boundaries
- **Given:** Game running on non-Windows platform, SDL_CaptureMouse active (button held)
- **When:** Player moves mouse outside the game window edges while a button is held
- **Then:** `MouseX` clamps to [0, 640] and `MouseY` clamps to [0, 480]; no negative or out-of-range values
- **Automated:** `TEST_CASE("AC-1 [VS1-SDL-INPUT-MOUSE]: Mouse coordinate normalization clamps to 0-640 x range")` — boundary sections
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 3: Screen-rate scaling correct at different window sizes
- **Given:** Game window set to a non-native resolution (e.g., 1280x960 — 2x scale)
- **When:** Player clicks at the center of the window
- **Then:** `MouseX` ≈ 320, `MouseY` ≈ 240 — coordinates correctly mapped from pixel space to 640x480 virtual space
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-2: Mouse Button State — Down, Up, Double-Click

### Scenario 4: Left button click-to-move
- **Given:** Game running on macOS arm64 or Linux x64 (requires EPIC-4)
- **When:** Player left-clicks on a walkable floor tile
- **Then:** Character begins moving to that location; `MouseLButton`, `MouseLButtonPush`, `MouseLButtonPop` transition correctly each frame
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 5: Left button drag-and-drop (inventory)
- **Given:** Game running on non-Windows platform, inventory window open
- **When:** Player holds left mouse button, drags an item, and releases
- **Then:** Item drags correctly; `MouseLButton = true` during drag, `MouseLButtonPop = true` on release; SDL_CaptureMouse keeps events during drag outside window
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 6: Right-click context menu
- **Given:** Game running on non-Windows platform, a monster or NPC targeted
- **When:** Player right-clicks
- **Then:** Context menu appears; `MouseRButton`, `MouseRButtonPush`, `MouseRButtonPop` transition correctly
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 7: Double-click on item (auto-equip)
- **Given:** Game running on non-Windows platform, inventory open
- **When:** Player double-clicks an equippable item
- **Then:** Item auto-equips; `MouseLButtonDBClick = true` on second click; reset to false next frame
- **Automated:** `TEST_CASE("AC-2 [VS1-SDL-INPUT-MOUSE]: LButton double-click sets MouseLButtonDBClick=true")`
- **Note:** Manual end-to-end test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 8: No stuck button state after Alt-Tab (windowed mode)
- **Given:** Game running on non-Windows platform in windowed mode, left button held
- **When:** Player Alt-Tabs out of the game window
- **Then:** On return, `MouseLButton`, `MouseLButtonPush`, `MouseLButtonPop`, `MouseRButton`, `MouseRButtonPush`, `MouseMButton`, `MouseMButtonPush`, `MouseMButtonPop`, `MouseLButtonDBClick`, `MouseWheel` are all cleared; no stuck-button behavior
- **Note:** HIGH-1 fix (MouseLButtonPush) applied in code-review-finalize 2026-03-06
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-3: Mouse Wheel Scroll

### Scenario 9: Mouse wheel scrolls chat log
- **Given:** Game running on non-Windows platform (requires EPIC-4), chat log visible
- **When:** Player scrolls mouse wheel up (away from user)
- **Then:** Chat log scrolls up; `MouseWheel > 0` (positive = scroll up, same as Win32 WHEEL_DELTA)
- **Automated:** `TEST_CASE("AC-3 [VS1-SDL-INPUT-MOUSE]: MouseWheel positive y maps to positive MouseWheel")`
- **Note:** Manual end-to-end test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 10: Mouse wheel scrolls list windows
- **Given:** Game running on non-Windows platform, a UI list window (party, guild) visible
- **When:** Player scrolls mouse wheel down (toward user)
- **Then:** List scrolls down; `MouseWheel < 0` (negative = scroll down)
- **Automated:** `TEST_CASE("AC-3 [VS1-SDL-INPUT-MOUSE]: MouseWheel negative y maps to negative MouseWheel")`
- **Note:** Manual end-to-end test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 11: MouseWheel reset each frame
- **Given:** Game running on non-Windows platform
- **When:** Player does NOT scroll the wheel for one frame
- **Then:** `MouseWheel = 0` — no phantom scroll from previous frame
- **Automated:** `TEST_CASE("AC-3 [VS1-SDL-INPUT-MOUSE]: MouseWheel reset to zero each frame")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-4: Cursor Visibility Toggle

### Scenario 12: Cursor hidden during gameplay
- **Given:** Game running on non-Windows platform (requires EPIC-4), gameplay mode active
- **When:** Game calls `ShowCursor(FALSE)` / `ShowCursor(false)`
- **Then:** Mouse cursor is hidden via `SDL_HideCursor()`; cursor not visible during combat/movement
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 13: Cursor shown in menus
- **Given:** Game running on non-Windows platform, a menu or dialog is open
- **When:** Game calls `ShowCursor(TRUE)` / `ShowCursor(true)`
- **Then:** Mouse cursor is visible via `SDL_ShowCursor()`; player can see and click menu items
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-5: SetCursorPos Shim via SDL_WarpMouseInWindow

### Scenario 14: Trade window cursor warp
- **Given:** Game running on non-Windows platform (requires EPIC-4), trade window open
- **When:** `NewUITrade.cpp:600` calls `SetCursorPos(x, y)` to warp the cursor to a UI position
- **Then:** Cursor warps to the expected position in the game window; no visible glitch or wrong-window warp
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 15: ZzzInterface cursor warp (line 4089)
- **Given:** Game running on non-Windows platform, interface interaction triggers cursor warp
- **When:** `ZzzInterface.cpp:4089` calls `SetCursorPos(x, y)`
- **Then:** Cursor moves to the target position correctly; `SDL_WarpMouseInWindow(nullptr, ...)` targets the focused window
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-STD-3: No Raw Win32 Mouse APIs in New Files

### Scenario 16: CMake regression test passes
- **Given:** All story 2.2.2 implementation files in place
- **When:** CTest runs `2.2.2-AC-STD-3:no-raw-win32-mouse`
- **Then:** Test passes — no `WM_MOUSEMOVE`, `WM_LBUTTONDOWN`, `SetCapture`, `ReleaseCapture` found in new game logic files; only expected in Winmain.cpp WndProc and Platform/ layer
- **Automated:** `test_ac_std3_no_raw_win32_mouse.cmake`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-STD-8 / AC-STD-14: Error Logging via g_ErrorReport.Write

### Scenario 17: Mouse warp failure logged with flow code
- **Given:** `SDL_WarpMouseInWindow` returns false (simulated failure or non-initialized SDL)
- **When:** `SetCursorPos()` shim calls `MuPlatformLogMouseWarpFailed()`
- **Then:** `g_ErrorReport.Write()` records `MU_ERR_MOUSE_WARP_FAILED [VS1-SDL-INPUT-MOUSE]: {SDL_GetError()}` in the post-mortem error report
- **Note:** Integration test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-STD-11: Flow Code in Artifacts

### Scenario 18: VS1-SDL-INPUT-MOUSE present in SDLEventLoop.cpp
- **Given:** Story 2.2.2 implementation complete
- **When:** CTest runs `2.2.2-AC-STD-11:flow-code-mouse`
- **Then:** Test passes — `VS1-SDL-INPUT-MOUSE` found in `SDLEventLoop.cpp`
- **Automated:** `test_ac_std11_flow_code_2_2_2.cmake`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## Quality Gate Verification

### Scenario 19: format-check passes
- **Given:** All story 2.2.2 files formatted per .clang-format (Allman, 4-space, 120-col)
- **When:** `make -C MuMain format-check` is run
- **Then:** No formatting differences reported; exit code 0
- **Status:** [x] Passed — 2026-03-06 (format-check exit 0, no diff output)

### Scenario 20: lint (cppcheck) passes
- **Given:** New Platform/ files have no cppcheck warnings
- **When:** `make -C MuMain lint` is run
- **Then:** No warnings reported for new files; 689/689 files checked clean
- **Status:** [x] Passed — 2026-03-06 (689/689 files, 0 warnings)

### Scenario 21: MinGW CI build unaffected (MU_ENABLE_SDL3=OFF)
- **Given:** All new SDL3 code guarded by `#ifdef MU_ENABLE_SDL3`
- **When:** MinGW CI job runs (`cmake ... -DMU_ENABLE_SDL3=OFF`)
- **Then:** Build succeeds; no compile errors from new mouse input files
- **Note:** Enforced by CI guard pattern from story 2.1.1 (CI Strategy B)
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed
