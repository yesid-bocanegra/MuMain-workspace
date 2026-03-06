# Test Scenarios: Story 2.2.1 — SDL3 Keyboard Input Migration

**Generated:** 2026-03-06
**Story:** 2.2.1 SDL3 Keyboard Input Migration
**Flow Code:** VS1-SDL-INPUT-KEYBOARD
**Project:** MuMain-workspace

These scenarios cover manual validation of Story 2.2.1 acceptance criteria.
Automated tests (Catch2 unit + CMake script) are in `MuMain/tests/platform/`.
Manual scenarios require full game compilation (blocked until EPIC-4 rendering
migration completes).

---

## AC-1: GetAsyncKeyState Shim — High-Byte Return Value

### Scenario 1: Shim returns correct high-byte when key is held
- **Given:** Game running on macOS arm64 or Linux x64 with MU_ENABLE_SDL3=ON
- **When:** Player holds the Escape key
- **Then:** `HIBYTE(GetAsyncKeyState(VK_ESCAPE))` returns 0x80 (== 128); the in-game pause/menu closes correctly
- **Automated:** `TEST_CASE("AC-1 [VS1-SDL-INPUT-KEYBOARD]: GetAsyncKeyState shim returns 0x8000 when key is held")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 2: Shim returns 0 when key is released
- **Given:** Game running on macOS or Linux
- **When:** Player releases the Escape key
- **Then:** `HIBYTE(GetAsyncKeyState(VK_ESCAPE))` returns 0; game stops responding to Escape
- **Automated:** `TEST_CASE("AC-1 [VS1-SDL-INPUT-KEYBOARD]: GetAsyncKeyState shim returns 0 when key is not held")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 3: HIBYTE pattern compatibility (ZzzInterface.cpp pattern)
- **Given:** Game running on non-Windows platform
- **When:** Alt key (VK_MENU) is held
- **Then:** `HIBYTE(GetAsyncKeyState(VK_MENU))` is truthy (non-zero) — Alt-modifier bindings activate correctly (e.g., Alt+1..0 skill shortcuts)
- **Automated:** `TEST_CASE("AC-4 [VS1-SDL-INPUT-KEYBOARD]: HIBYTE of 0x8000 equals 128 (0x80)")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-2: VK -> SDL_Scancode Mapping Table Coverage

### Scenario 4: Navigation keys map correctly
- **Given:** Game running on non-Windows platform
- **When:** Player presses arrow keys, Page Up/Down, Home, End, Insert, Delete
- **Then:** Character moves or UI navigation responds correctly; keys are not swapped or silent
- **Automated:** `TEST_CASE("AC-2 [VS1-SDL-INPUT-KEYBOARD]: MuVkToSdlScancode navigation keys")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 5: VK_LCONTROL and VK_SNAPSHOT are defined and mapped
- **Given:** Codebase compiled on non-Windows with updated PlatformKeys.h
- **When:** Build is run (`cmake --preset macos-arm64 && cmake --build`)
- **Then:** No "VK_LCONTROL undeclared" or "VK_SNAPSHOT undeclared" compile errors; `ZzzCharacter.cpp` and `SceneManager.cpp` compile cleanly
- **Automated:** `TEST_CASE("AC-STD-2 [VS1-SDL-INPUT-KEYBOARD]: VK_LCONTROL and VK_SNAPSHOT defined in PlatformKeys.h")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 6: ASCII letter keys map correctly (WASD/QERF camera)
- **Given:** Game running on non-Windows platform
- **When:** Player presses W, A, S, D in camera-control context
- **Then:** Camera moves in expected directions; key presses are not silent
- **Automated:** `TEST_CASE("AC-2 [VS1-SDL-INPUT-KEYBOARD]: MuVkToSdlScancode ASCII A through Z")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 7: Digit keys map correctly (Alt+1-0 skill shortcuts)
- **Given:** Game running on non-Windows platform, player has skills assigned to slots 1-0
- **When:** Player holds Alt and presses digit keys 1 through 0
- **Then:** Corresponding skills are used; no skill slot unresponsive
- **Automated:** `TEST_CASE("AC-2 [VS1-SDL-INPUT-KEYBOARD]: MuVkToSdlScancode ASCII 0 through 9")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-3: All Hotkeys Work on macOS and Linux

### Scenario 8: F1-F12 hotkeys functional
- **Given:** Game running on macOS arm64 (full EPIC-4 required)
- **When:** Player presses F1 through F12
- **Then:** Each function key triggers its associated game action (F1 = character window, F2 = inventory, etc.)
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 9: Ctrl+click modifiers functional
- **Given:** Game running on Linux x64 (full EPIC-4 required)
- **When:** Player holds Ctrl and clicks an item
- **Then:** Ctrl+click action executes (e.g., item to party member); distinct from plain click
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 10: Enter/Escape in menus functional
- **Given:** Game running on non-Windows platform, a dialog is open
- **When:** Player presses Enter or Escape
- **Then:** Dialog confirms or cancels correctly; behavior identical to Windows build
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-4: Key Repeat Behavior (Async State Model)

### Scenario 11: Key held fires continuously, not just on initial press
- **Given:** Game running on non-Windows platform, ScanAsyncKeyState() polling every frame
- **When:** Player holds down VK_LEFT (arrow key) for 2 seconds
- **Then:** Character/camera moves continuously; state remains true for entire hold duration (mirrors Win32 async state model, not WM_KEYDOWN repeat)
- **Automated:** `TEST_CASE("AC-4 [VS1-SDL-INPUT-KEYBOARD]: HIBYTE pattern: held key satisfies both == 128 and & 0x80 checks")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 12: No stuck keys after Alt-Tab
- **Given:** Game running on non-Windows platform
- **When:** Player Alt-Tabs out and back into game while holding a key
- **Then:** No keys appear stuck; `g_sdl3KeyboardState` cleared on `SDL_EVENT_WINDOW_FOCUS_LOST`
- **Note:** Requires HandleFocusLoss() clearing logic from Task 3.4
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-5: macOS Cmd Key NOT Mapped to Game Controls

### Scenario 13: Cmd key does not trigger Ctrl bindings on macOS
- **Given:** Game running on macOS arm64
- **When:** Player presses Cmd+W (common macOS quit shortcut)
- **Then:** Game does NOT treat Cmd as a Ctrl modifier; Cmd+W does not trigger Ctrl+W game action; no unintended Ctrl-binding fires
- **Automated:** `TEST_CASE("AC-5 [VS1-SDL-INPUT-KEYBOARD]: macOS Cmd key NOT mapped to game controls")`
- **Note:** Manual confirmation required on physical macOS hardware
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 14: Physical Ctrl key works on macOS (not replaced by Cmd)
- **Given:** Game running on macOS arm64
- **When:** Player holds physical Ctrl key (not Cmd) and clicks
- **Then:** Ctrl+click game action fires; Ctrl is recognized via SDL_SCANCODE_LCTRL mapping from VK_CONTROL
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-STD-3: No Unshimmed GetAsyncKeyState Calls

### Scenario 15: CMake script regression test passes
- **Given:** All story 2.2.1 implementation files in place
- **When:** CTest runs `2.2.1-AC-STD-3:no-raw-getasynckeystate`
- **Then:** Test passes — reports 7 known call-site files (handled by shim), 0 unexpected files
- **Automated:** `test_ac_std3_no_raw_getasynckeystate.cmake`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-STD-11: Flow Code in Artifacts

### Scenario 16: VS1-SDL-INPUT-KEYBOARD present in PlatformCompat.h
- **Given:** Story 2.2.1 implementation complete
- **When:** CTest runs `2.2.1-AC-STD-11:flow-code-keyboard`
- **Then:** Test passes — VS1-SDL-INPUT-KEYBOARD found in `PlatformCompat.h` unmapped-VK error log string
- **Automated:** `test_ac_std11_flow_code_2_2_1.cmake`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## Quality Gate Verification

### Scenario 17: format-check passes
- **Given:** All story 2.2.1 files formatted per .clang-format (Allman, 4-space, 120-col)
- **When:** `make -C MuMain format-check` is run
- **Then:** No formatting differences reported; exit code 0
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 18: lint (cppcheck) passes
- **Given:** New Platform/ files have no cppcheck warnings
- **When:** `make -C MuMain lint` is run
- **Then:** No warnings reported for new files; exit code 0
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 19: MinGW CI build unaffected (MU_ENABLE_SDL3=OFF)
- **Given:** All new SDL3 code guarded by `#ifdef MU_ENABLE_SDL3`
- **When:** MinGW CI job runs (`cmake ... -DMU_ENABLE_SDL3=OFF`)
- **Then:** Build succeeds; no compile errors from new keyboard input files
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed
