# ATDD Checklist — Story 2.2.1: SDL3 Keyboard Input Migration

**Flow Code:** VS1-SDL-INPUT-KEYBOARD
**Story Type:** infrastructure
**Generated:** 2026-03-06
**Phase:** RED — All tests written BEFORE implementation; all will FAIL until implementation is complete.

---

## PCC Compliance Summary

| Check | Status | Detail |
|-------|--------|--------|
| Guidelines loaded | PASS | project-context.md + development-standards.md loaded |
| Prohibited libraries | PASS | No raw new/delete, NULL, wprintf in test files |
| Required patterns | PASS | Catch2 v3.7.1, MU_ENABLE_SDL3 guard, VS1-SDL-INPUT-KEYBOARD flow code, g_ErrorReport |
| Test framework | PASS | Catch2 v3.7.1 (FetchContent, BUILD_TESTING=ON) |
| Test location | PASS | MuMain/tests/platform/ |
| Existing tests mapped | PASS | No pre-existing tests for story 2.2.1 — all ACs generate new tests |
| AC-N: prefixes | PASS | All TEST_CASE names include AC-N tag |
| No prohibited libraries | PASS | Only PlatformCompat.h, PlatformKeys.h, SDL3 headers, Catch2 used |

---

## AC-to-Test Mapping

| AC | Description | Test Method(s) | File |
|----|-------------|----------------|------|
| AC-1 | GetAsyncKeyState high-byte correct | `TEST_CASE("AC-1 [...]: GetAsyncKeyState shim returns 0x8000 when key is held")` | test_platform_input.cpp |
| AC-1 | GetAsyncKeyState returns 0 when not held | `TEST_CASE("AC-1 [...]: GetAsyncKeyState shim returns 0 when key is not held")` | test_platform_input.cpp |
| AC-1 | Unmapped VK returns 0 | `TEST_CASE("AC-1 [...]: GetAsyncKeyState shim returns 0 for unmapped VK code")` | test_platform_input.cpp |
| AC-2 | Navigation key mapping | `TEST_CASE("AC-2 [...]: MuVkToSdlScancode navigation keys")` | test_platform_input.cpp |
| AC-2 | Modifier key mapping (incl. VK_LCONTROL, VK_SNAPSHOT) | `TEST_CASE("AC-2 [...]: MuVkToSdlScancode modifier keys")` | test_platform_input.cpp |
| AC-2 | F1-F12 mapping | `TEST_CASE("AC-2 [...]: MuVkToSdlScancode F1 through F12")` | test_platform_input.cpp |
| AC-2 | Numpad key mapping | `TEST_CASE("AC-2 [...]: MuVkToSdlScancode numpad keys")` | test_platform_input.cpp |
| AC-2 | ASCII A-Z range mapping | `TEST_CASE("AC-2 [...]: MuVkToSdlScancode ASCII A through Z")` | test_platform_input.cpp |
| AC-2 | ASCII 0-9 range mapping | `TEST_CASE("AC-2 [...]: MuVkToSdlScancode ASCII 0 through 9")` | test_platform_input.cpp |
| AC-2 | Unmapped VK returns SDL_SCANCODE_UNKNOWN | `TEST_CASE("AC-2 [...]: MuVkToSdlScancode unmapped VK returns SDL_SCANCODE_UNKNOWN")` | test_platform_input.cpp |
| AC-3 | Hotkeys work on macOS/Linux | Manual scenarios 8-10 in test-scenarios doc | 2-2-1-sdl3-keyboard-input.md |
| AC-4 | Key repeat async model, HIBYTE correctness | `TEST_CASE("AC-4 [...]: HIBYTE of 0x8000 equals 128 (0x80)")` | test_platform_input.cpp |
| AC-4 | Winmain.cpp direct 0x8000 check pattern | `TEST_CASE("AC-4 [...]: GetAsyncKeyState direct 0x8000 check")` | test_platform_input.cpp |
| AC-5 | macOS Cmd NOT mapped to VK_CONTROL | `TEST_CASE("AC-5 [...]: macOS Cmd key NOT mapped to game controls")` | test_platform_input.cpp |
| AC-STD-2 | VK_LCONTROL, VK_SNAPSHOT defined | `TEST_CASE("AC-STD-2 [...]: VK_LCONTROL and VK_SNAPSHOT defined in PlatformKeys.h")` | test_platform_input.cpp |
| AC-STD-2 | g_sdl3KeyboardState array size 512 | `TEST_CASE("AC-STD-2 [...]: g_sdl3KeyboardState array size is 512")` | test_platform_input.cpp |
| AC-STD-3 | No raw GetAsyncKeyState outside Platform/ | CMake script test `2.2.1-AC-STD-3:no-raw-getasynckeystate` | test_ac_std3_no_raw_getasynckeystate.cmake |
| AC-STD-11 | VS1-SDL-INPUT-KEYBOARD flow code in PlatformCompat.h | CMake script test `2.2.1-AC-STD-11:flow-code-keyboard` | test_ac_std11_flow_code_2_2_1.cmake |
| AC-VAL-2 | Test scenarios documented | Manual test scenario document | 2-2-1-sdl3-keyboard-input.md |

---

## Implementation Checklist

### Task 1: Extend PlatformKeys.h (AC-2)

- [ ] `1.1` Add `VK_LCONTROL 0xA2` to PlatformKeys.h (non-Windows block)
- [ ] `1.2` Add `VK_SNAPSHOT 0x2C` to PlatformKeys.h (non-Windows block)
- [ ] `1.3` Add `VK_CAPITAL 0x14`, `VK_NUMLOCK 0x90`, `VK_SCROLL 0x91`, `VK_PAUSE 0x13`
- [ ] `1.4` Add `VK_OEM_1 0xBA`, `VK_OEM_PLUS 0xBB`, `VK_OEM_COMMA 0xBC`, `VK_OEM_MINUS 0xBD`, `VK_OEM_PERIOD 0xBE`
- [ ] `1.5` Add `VK_MULTIPLY 0x6A`, `VK_ADD 0x6B`, `VK_SEPARATOR 0x6C`, `VK_SUBTRACT 0x6D`, `VK_DECIMAL 0x6E`, `VK_DIVIDE 0x6F`
- [ ] `1.6` Add `VK_LSHIFT 0xA0`, `VK_RSHIFT 0xA1`, `VK_RCONTROL 0xA3`, `VK_LMENU 0xA4`, `VK_RMENU 0xA5`

### Task 2: Add GetAsyncKeyState shim to PlatformCompat.h (AC-1, AC-4)

- [ ] `2.1` Add `HIBYTE` macro (non-Windows, `#ifndef HIBYTE` guard): `#define HIBYTE(w) (static_cast<uint8_t>((static_cast<uint16_t>(w) >> 8) & 0xFF))`
- [ ] `2.2` Check PlatformTypes.h for `BYTE` typedef — add `using BYTE = uint8_t;` if missing (non-Windows)
- [ ] `2.3` Add `extern bool g_sdl3KeyboardState[512]` declaration in PlatformCompat.h (inside `#ifdef MU_ENABLE_SDL3` block)
- [ ] `2.4` Add `MuVkToSdlScancode(int vk)` inline function implementing full VK->SDL_Scancode table from Dev Notes
- [ ] `2.5` Add `GetAsyncKeyState(int vk)` inline shim (inside `#ifdef MU_ENABLE_SDL3` inside `#else // !_WIN32`):
      - Returns `uint16_t(0x8000)` when `g_sdl3KeyboardState[sc]` is true
      - Returns `0` when key not held or scancode unknown
      - Logs `MU_ERR_INPUT_UNMAPPED_VK [VS1-SDL-INPUT-KEYBOARD]` via `g_ErrorReport.Write()` for unknown VK
- [ ] `2.6` Verify flow code `VS1-SDL-INPUT-KEYBOARD` appears in `g_ErrorReport.Write()` call (AC-STD-11, AC-STD-14)
- [ ] `2.7` Add `static_assert(SDL_SCANCODE_A == 4)` and `static_assert(SDL_SCANCODE_1 == 30)` (Task 5.4)

### Task 3: Define g_sdl3KeyboardState array (AC-1, AC-4)

- [ ] `3.1` Choose implementation: Option A (SDLKeyboardState.cpp) or Option B (inline C++20 in PlatformCompat.h)
- [ ] `3.2` If Option A: Create `MuMain/src/source/Platform/sdl3/SDLKeyboardState.cpp` with `bool g_sdl3KeyboardState[512] = {};` inside `#ifdef MU_ENABLE_SDL3`
- [ ] `3.3` If Option A: Add `SDLKeyboardState.cpp` to MUPlatform CMake target inside `if(MU_ENABLE_SDL3)` block

### Task 4: Feed keyboard state from SDLEventLoop (AC-1, AC-4)

- [ ] `4.1` Add `SDL_EVENT_KEY_DOWN` handler in `SDLEventLoop.cpp PollEvents()`: set `g_sdl3KeyboardState[event.key.scancode] = true` (with bounds check `< 512`)
- [ ] `4.2` Add `SDL_EVENT_KEY_UP` handler: set `g_sdl3KeyboardState[event.key.scancode] = false`
- [ ] `4.3` In `HandleFocusLoss()`: clear all entries — `std::fill(std::begin(g_sdl3KeyboardState), std::end(g_sdl3KeyboardState), false)` (prevents stuck keys on Alt-Tab)
- [ ] `4.4` Add `#include <algorithm>` if not already present in SDLEventLoop.cpp

### Task 5: ASCII and extended key mappings (AC-2, AC-3)

- [ ] `5.1` In `MuVkToSdlScancode()`: add range mapping for 'A'-'Z' (0x41-0x5A) -> `SDL_SCANCODE_A + (vk - 'A')`
- [ ] `5.2` In `MuVkToSdlScancode()`: add range mapping for '1'-'9' (0x31-0x39) -> `SDL_SCANCODE_1 + (vk - '1')`
- [ ] `5.3` In `MuVkToSdlScancode()`: add mapping for '0' (0x30) -> `SDL_SCANCODE_0`
- [ ] `5.4` Add compile-time `static_assert` for SDL scancode values (verified in test_platform_input.cpp)

### Task 6: Tests (AC-STD-2, AC-STD-16)

- [ ] `6.1` Verify `test_platform_input.cpp` compiles with `MU_ENABLE_SDL3=ON` (all TEST_CASEs fail — RED phase)
- [ ] `6.2` Verify `test_platform_input.cpp` compiles with `MU_ENABLE_SDL3=OFF` (empty TU — no errors — CI safe)
- [ ] `6.3` Verify `test_ac_std11_flow_code_2_2_1.cmake` FAILS before implementation (PlatformCompat.h has no flow code yet)
- [ ] `6.4` Verify `test_ac_std3_no_raw_getasynckeystate.cmake` passes (no unexpected new GetAsyncKeyState calls)
- [ ] `6.5` Verify new tests registered in `MuMain/tests/CMakeLists.txt` and `MuMain/tests/platform/CMakeLists.txt`

### Task 7: Quality Gate (AC-STD-13)

- [ ] `7.1` `make -C MuMain format-check` passes (Allman braces, 4-space, 120-col, LF, UTF-8)
- [ ] `7.2` `make -C MuMain lint` passes (zero cppcheck warnings in new Platform/ files)
- [ ] `7.3` `./ctl check` passes on macOS
- [ ] `7.4` All new SDL3 code inside `#ifdef MU_ENABLE_SDL3` — MinGW CI build unaffected

### PCC Compliance Items

- [ ] No prohibited libraries used (no raw new/delete, no NULL, no wprintf in new code)
- [ ] Required patterns present: `[[nodiscard]]` on fallible functions, `g_ErrorReport.Write()` with `MU_ERR_*` prefix
- [ ] MU_ENABLE_SDL3 compile-time guard on all SDL3 code
- [ ] Catch2 v3.7.1 via FetchContent, tests in `MuMain/tests/platform/`, BUILD_TESTING=ON opt-in
- [ ] VS1-SDL-INPUT-KEYBOARD flow code in log messages AND test names AND story artifacts
- [ ] No `#ifdef _WIN32` in game logic files — only in Platform/ abstraction layer and PlatformCompat.h
- [ ] `#pragma once` only (no `#ifndef` guards) in all new headers

### AC-STD-3: No Unshimmed Calls

- [ ] All 8 known GetAsyncKeyState call-site files compile through shim with zero source changes
- [ ] CMake script test `2.2.1-AC-STD-3:no-raw-getasynckeystate` passes

### Error Catalog (AC-STD-8, AC-STD-14)

- [ ] `MU_ERR_INPUT_UNMAPPED_VK` added to `docs/error-catalog.md`
- [ ] Error message format: `MU_ERR_INPUT_UNMAPPED_VK [VS1-SDL-INPUT-KEYBOARD]: unmapped VK code 0x{XX}`
- [ ] Logged via `g_ErrorReport.Write()` (not wprintf, not g_ConsoleDebug)

### Manual Validation (AC-VAL-2 — deferred to post-EPIC-4)

- [ ] WASD camera, Ctrl+click, Alt+number skill shortcuts tested on macOS arm64
- [ ] WASD camera, Ctrl+click, Alt+number skill shortcuts tested on Linux x64
- [ ] macOS Cmd key confirmed NOT triggering Ctrl bindings (AC-5)
- [ ] No stuck keys after Alt-Tab (AC-4, Task 3.4)

---

## Test Files Created (RED Phase)

| File | Type | Status |
|------|------|--------|
| `MuMain/tests/platform/test_platform_input.cpp` | Catch2 unit tests | RED — will FAIL until implementation |
| `MuMain/tests/platform/test_ac_std11_flow_code_2_2_1.cmake` | CMake script test | RED — will FAIL until PlatformCompat.h has flow code |
| `MuMain/tests/platform/test_ac_std3_no_raw_getasynckeystate.cmake` | CMake script regression | GREEN — passes now (no unexpected calls yet) |
| `_bmad-output/test-scenarios/epic-2/2-2-1-sdl3-keyboard-input.md` | Manual test scenarios | DOCUMENTED |

## CMakeLists.txt Updated

| File | Change |
|------|--------|
| `MuMain/tests/CMakeLists.txt` | Added `platform/test_platform_input.cpp` to MuTests target |
| `MuMain/tests/platform/CMakeLists.txt` | Added `2.2.1-AC-STD-11` and `2.2.1-AC-STD-3` CTest registrations |

---

## Handoff Contract (to dev-story workflow)

| Output | Value |
|--------|-------|
| `atdd_checklist_path` | `_bmad-output/stories/2-2-1-sdl3-keyboard-input/atdd.md` |
| `test_files_created` | `MuMain/tests/platform/test_platform_input.cpp`, `test_ac_std11_flow_code_2_2_1.cmake`, `test_ac_std3_no_raw_getasynckeystate.cmake` |
| `implementation_checklist_complete` | FALSE (all items `[ ]` — ready for implementation) |
| `ac_test_mapping` | See AC-to-Test Mapping table above |

**STATE TRANSITION:** STATE_0_STORY_CREATED → [testarch-atdd] → STATE_1_ATDD_READY
