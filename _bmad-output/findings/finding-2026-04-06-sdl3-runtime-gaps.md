# SDL3 Runtime Gaps: Outstanding Issues After Network + Rendering Fixes

**Date:** 2026-04-06
**Discovered during:** SDL3 cross-platform testing session
**Context:** Sprint 7, EPIC-4 (Rendering Pipeline Migration) + EPIC-7 (Stability)
**Discovery type:** compat-gap
**Urgency:** next-sprint

---

## Summary

After fixing deferred rendering (streaks), packet pipeline (PostMessage no-op), .NET SIOF (null function pointers), signal handler conflict, and UI click detection (GetCursorPos), several runtime gaps remain that affect user-visible functionality.

---

## 1. Docker Server Returns Unreachable IP

**Symptom:** After selecting a game server from the list, the client receives `191.106.5.252:55902` (Docker-internal IP) and fails to connect with "Operation timed out."

**Root cause:** The OpenMU Docker server's connect server returns its internal Docker network IP instead of the host-accessible address (localhost / 127.0.0.1).

**Fix:** Configure the Docker OpenMU server to advertise `127.0.0.1` as the game server IP. This is a server-side configuration change, not a client code change.

**Workaround:** Override the game server IP in the client's connection code or configure Docker networking to expose the internal IP.

---

## 2. Crash After Failed Game Server Connection

**Symptom:** After the .NET library reports "Operation timed out" connecting to the game server, the client segfaults.

**Root cause:** `CreateSocket()` in WSclient.cpp creates a `Connection` object that fails to connect (handle=-1). Callers likely dereference `SocketClient` members without checking `IsConnected()`, or the error UI path uses `PostMessage(WM_CLOSE)` which is a no-op on SDL3.

**Fix:** Add null/connection-state checks in the connection failure path. Ensure the error message UI (MESSAGE_SERVER_LOST popup) works on SDL3.

**Files:** `WSclient.cpp` CreateSocket(), `SceneManager.cpp` CheckServerConnection(), `MsgWin.cpp` MESSAGE_SERVER_LOST handler

---

## 3. Font/Text Not Rendering on UI Elements

**Symptom:** UI buttons and panels are visible and clickable, but no text labels appear on them.

**Root cause:** NOT a PlatformCompat no-op issue. The GDI layer (CrossPlatformGDI.cpp) has working implementations of CreateFont, TextOut, CreateDIBSection, etc. with an embedded 8x16 bitmap font. The issue is likely in `CUIRenderTextOriginal::UploadText()` — the path from GDI bitmap to SDL_GPU texture. The text is rasterized to a DIB bitmap correctly but may not be uploaded to the GPU or rendered as a textured quad.

**Files:** `UIControls.cpp` CUIRenderTextOriginal::WriteText/UploadText (line ~2694), `MuRendererSDLGpu.cpp` texture upload path

---

## 4. SetTimer / KillTimer No-Op (PlatformCompat.h:1551-1558)

**Symptom:** Game timers don't fire — buff durations don't count down, chat connection timeouts don't trigger, periodic events don't execute.

**Call sites:** UIWindows.cpp (CHATCONNECT_TIMER), w_BuffTimeControl.cpp (buff timers)

**Fix:** Implement SDL_AddTimer wrapper with a timer ID map. Route WM_TIMER to the game loop.

---

## 5. GetScrollPos / SetScrollPos No-Op (PlatformCompat.h:1538-1545)

**Symptom:** UI scrollbars non-functional. Can't scroll through inventory, shop items, chat history, quest logs.

**Fix:** Maintain per-control scroll position state in a map. Return stored position from GetScrollPos, store in SetScrollPos.

---

## 6. GetCurrentDirectory No-Op (PlatformCompat.h:1561-1566)

**Symptom:** Game shop script/banner downloads fail silently.

**Call sites:** InGameShopSystem.cpp ScriptDownload(), BannerDownload()

**Fix:** Implement using `std::filesystem::current_path()`.

---

## 7. IsWindowVisible Returns FALSE (PlatformCompat.h:368-371)

**Symptom:** Text input guard may incorrectly skip processing.

**Fix:** Return TRUE for non-null HWND (same pattern as GetActiveWindow sentinel).

---

## 8. ClientToServer Packet Bindings Not Resolved

**Symptom:** Only ConnectServer and ChatServer packet send functions are re-resolved in ResolvePacketBindings(). The 191 ClientToServer bindings (login, movement, combat, inventory, etc.) may be NULL due to the same SIOF that affected SendServerListRequest.

**Fix:** Either generate a complete ResolvePacketBindings() from XSLT alongside the bindings, or add a generic resolver that iterates all bindings by name.

**Files:** Connection.cpp ResolvePacketBindings(), PacketBindings_ClientToServer.h (191 inline vars)

---

## Priority Order

| # | Gap | Urgency | Blocks |
|---|-----|---------|--------|
| 8 | ClientToServer bindings SIOF | **Critical** | Login, gameplay — all game server packets |
| 2 | Crash on failed connection | **High** | Graceful error handling |
| 3 | Font/text not rendering | **High** | UI readability |
| 1 | Docker server IP | **High** | Server-side config, not client code |
| 4 | SetTimer/KillTimer | **Medium** | Buffs, chat timers |
| 5 | GetScrollPos/SetScrollPos | **Medium** | Scrollable UI lists |
| 6 | GetCurrentDirectory | **Low** | Game shop only |
| 7 | IsWindowVisible | **Low** | Edge case in text input |
