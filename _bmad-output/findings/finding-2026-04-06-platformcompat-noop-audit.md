# PlatformCompat.h No-Op Audit: Functions That Silently Break Functionality

**Date:** 2026-04-06
**Discovered during:** UI click debugging and no-op audit
**Context:** Sprint 7, SDL3 cross-platform migration
**Discovery type:** compat-gap
**Urgency:** this-sprint
**Urgency justification:** Multiple user-facing features silently broken on SDL3

---

## Summary

Audit of `PlatformCompat.h` identified function shims that are no-ops on SDL3 but have callers that depend on real behavior. The project rule is "no stubs, no excuses — ALL code must build AND run with full functionality on every platform."

---

## FIXED (2026-04-06)

### GetCursorPos (PlatformCompat.h:851)
Was: returned (0, 0). Fix: returns MouseX/MouseY scaled to window pixel coordinates. CInput::m_ptCursor now tracks real cursor position for UI hit-testing.

### PostMessage for WM_RECEIVE_BUFFER (PlatformCompat.h:553)
Was: no-op dropped all network packets. Fix: thread-safe packet queue + DrainPacketQueue().

---

## BROKEN — Needs Fix

### SetTimer / KillTimer (PlatformCompat.h:1551-1558)
**Impact:** Game timers don't fire — buff durations, chat connection timeouts, periodic events.
**Call sites:** UIWindows.cpp (chat timer), w_BuffTimeControl.cpp (buff timers)
**Fix:** SDL_AddTimer wrapper with timer ID map.

### GetScrollPos / SetScrollPos (PlatformCompat.h:1538-1545)
**Impact:** UI scrollbars non-functional — can't scroll inventory, chat, quest logs.
**Fix:** Per-control scroll state map.

### GetCurrentDirectory (PlatformCompat.h:1561-1566)
**Impact:** Game shop script/banner downloads fail silently.
**Fix:** `std::filesystem::current_path()` implementation.

### IsWindowVisible (PlatformCompat.h:368-371)
**Impact:** Returns FALSE always — text input guard may skip processing.
**Fix:** Return TRUE when window handle is non-null (same pattern as GetActiveWindow).

---

## ACCEPTABLE — Correctly No-Op'd

Window management (CreateWindowEx, DestroyWindow, SetWindowPos, ShowWindow) — SDL3 handles these.
Console I/O (GetConsoleScreenBufferInfo, etc.) — not used in game loop.
Display settings (EnumDisplaySettings, ChoosePixelFormat) — SDL3 handles these.
IME advanced functions (ImmSetCompositionWindow, etc.) — SDL3 text input handles basics.

---

## NOT BROKEN — Has Real Implementation

GDI functions (CreateFont, TextOut, GetTextExtentPoint32, CreateDIBSection, SelectObject, etc.) all route to `CrossPlatformGDI.cpp` with a working 8x16 bitmap font rasterizer. Font rendering issue is likely in the texture upload path (WriteText/UploadText), not in the GDI shims.
