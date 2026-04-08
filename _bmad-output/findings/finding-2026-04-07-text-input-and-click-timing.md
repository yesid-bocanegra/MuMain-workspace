# Text Input Forms and Click Timing — Remaining SDL3 Gaps

**Date:** 2026-04-07
**Discovered during:** SDL3 cross-platform testing
**Context:** Sprint 7, SDL3 runtime
**Discovery type:** compat-gap
**Urgency:** next-sprint

---

## 1. Text Input Boxes Not Functional (LOGIN BLOCKER)

**Symptom:** Username and password input fields on the login screen don't show typed text or respond to keyboard input, even though:
- `CUITextInputBox::Init()` creates the memory DC via `SetSize()` ✓
- `GiveFocus()` sets `m_bSDLHasFocus = true` and calls `MuStartTextInput()` ✓
- `DoActionSub()` has full SDL3 text input consumption code ✓
- `Render()` bypasses the Win32 `m_hEditWnd` null check ✓
- `m_hMemDC` and `m_pFontBuffer` are non-null (diagnostic confirmed) ✓

**Investigation status:** The rendering path executes, focus is granted, and the SDL3 DoActionSub code exists. Possible remaining issues:
- `DoActionSub()` might not be called during the login scene's frame loop
- `g_szSDLTextInput` might not be populated (SDL_StartTextInput may need the window handle)
- The GDI bitmap font TextOut on SDL3 might produce empty output for the input box's font
- The text might render but be invisible (wrong color, zero alpha, or position outside clip rect)
- The `QueueTextureUpdate` for BITMAP_FONT might not work correctly (texture format mismatch)

**Needs:** Interactive debugging with breakpoints or extensive logging in DoActionSub + Render to trace the exact data flow.

**Files:** `UIControls.cpp:3486-3565` (DoActionSub SDL3), `UIControls.cpp:3950-4057` (Render SDL3 path), `LoginWin.cpp:197-209` (login form rendering)

---

## 2. ScanAsyncKeyState Polling vs SDL Event Delivery (CLICK RELIABILITY)

**Symptom:** Very fast clicks (press+release in the same frame) can be missed because `ScanAsyncKeyState` only polls the current state, not event history.

**Root cause:** On Win32, `GetAsyncKeyState` returns the state including edges (the low bit indicates "pressed since last query"). On SDL3, our shim returns only the current held state from `MouseLButton`/keyboard arrays. If a press-and-release both occur within a single `PollEvents()` call, `MouseLButton` ends up `false` and `ScanAsyncKeyState` sees no transition → `KEY_PRESS` state is never reached.

**Impact:** Fast clicks are occasionally missed. Most clicks work after the hover-before-click fix, but edge cases remain.

**Fix approach:** Track press/release EDGES in the SDL event loop, not just current state. Add `MouseLButtonWasPressed` flag that's set on BUTTON_DOWN and cleared after `ScanAsyncKeyState` consumes it. Similar to how `MouseLButtonPush` already works, but needs to be wired into the `GetAsyncKeyState` shim.

**Files:** `SDLEventLoop.cpp` (event delivery), `PlatformCompat.h:1228-1250` (GetAsyncKeyState shim), `NewUICommon.cpp:175-202` (ScanAsyncKeyState)

---

## 3. Some Menu Items Missing Text

**Symptom:** Some UI menu items show no text labels despite SDL_ttf rendering working for most text.

**Possible causes:**
- Font variant not loaded (g_hFontBold, g_hFixFont, g_hFontBig)
- Text rendered via old GDI path that doesn't have QueueTextureUpdate
- Text color has zero alpha
- CUIRenderTextOriginal still used in some code paths despite SDL_ttf factory selection

**Needs:** Identify which specific menu items are missing text and trace their rendering path.
