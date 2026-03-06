# Progress: Story 2-2-2-sdl3-mouse-input

## Quick Resume

| Field | Value |
|-------|-------|
| story_key | 2-2-2-sdl3-mouse-input |
| next_action | code-review |
| active_file | N/A |
| blocker | none |

## Current Position

| Field | Value |
|-------|-------|
| completed_count | 24 |
| total_count | 24 |
| current_task | COMPLETE |
| task_progress | 100% |

## Session History

### Session 1 — 2026-03-06

- Status: Completed (dev-story)
- Previous: Failed due to ConnectionRefused API error (transient)
- Completed all 6 task groups (Tasks 1-6)

## Technical Decisions

- Approach: global-state population (mirrors story 2.2.1 keyboard pattern)
- All SDL3 code behind #ifdef MU_ENABLE_SDL3
- MouseX/MouseY are `int` (not float) — ZzzOpenglUtil.cpp defines them as int; test file fixed accordingly
- VK_LBUTTON/RBUTTON/MBUTTON already defined in PlatformKeys.h — no change needed
- GetActiveWindow() uses static sentinel to avoid cppcheck intToPointerCast warning
- MuPlatformLogMouseWarpFailed() added to SDLKeyboardState.cpp to keep g_ErrorReport out of inline shims
- GetAsyncKeyState extended with switch for mouse buttons before keyboard lookup

## Files Touched

- `MuMain/src/source/Platform/PlatformTypes.h` — Added POINT, RECT, SIZE structs + PtInRect
- `MuMain/src/source/Platform/PlatformCompat.h` — Added ShowCursor, SetCursorPos, GetDoubleClickTime, GetCursorPos, ScreenToClient, GetActiveWindow; extended GetAsyncKeyState for mouse VK codes; added MouseLButton/R/M externs
- `MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp` — Added mouse extern declarations + per-frame reset + MOUSE_MOTION, BUTTON_DOWN, BUTTON_UP, WHEEL handlers
- `MuMain/src/source/Platform/sdl3/SDLKeyboardState.cpp` — Added MuPlatformLogMouseWarpFailed
- `MuMain/tests/platform/test_platform_mouse.cpp` — Fixed extern types int vs float; test logic updated
- `docs/error-catalog.md` — Added MU_ERR_MOUSE_WARP_FAILED
