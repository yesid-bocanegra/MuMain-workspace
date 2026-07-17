# Sending a friend invite can terminate the game client

**Date:** 2026-07-17
**Discovered during:** User-reported runtime bug review
**Context:** Standalone review of social-system and account-switch failures
**Discovery type:** bug
**Urgency:** this-sprint
**Urgency justification:** A normal social action can terminate the client and lose the active play session.

## Summary

Submitting the add-friend dialog crosses two deferred UI and native-to-managed boundaries using a manually owned raw string pointer. The supplied workspace contains no crash dump or runtime log, so the exact fault instruction is not proven, but this path has no safe ownership contract or test and is the only friend-add path that allocates, queues, casts, and manually frees the user input.

## Root Causes

### RCA-1: Friend name ownership crosses a deferred UI message as a raw pointer

**What:** `CUITextInputWindow::ReturnText` allocates a `wchar_t[]`, stores its address in a generic UI message, closes the source window, and relies on a different window to eventually send and delete the buffer. Correctness depends on message ordering and exactly-once handling instead of explicit value ownership.
**Evidence:** `MuMain/src/source/UI/Legacy/UIWindows.cpp:4942` allocates the buffer; `MuMain/src/source/UI/Legacy/UIWindows.cpp:4952` queues its address; `MuMain/src/source/UI/Legacy/UIWindows.cpp:3480` reconstructs the pointer; `MuMain/src/source/UI/Legacy/UIWindows.cpp:3487` frees it.
**Affected scope:** Friend-add text dialog, legacy UI message transport, 64-bit desktop builds.
**Proposed fix:** Keep returned text as an owned string value until consumption. Minimum safe change: add a dedicated friend-name value field or callback on the target window and remove heap-pointer transport through `UI_MESSAGE::m_iParam2`.
**Estimated lines:** ~20 lines across 2 files

### RCA-2: Native friend-add dispatch calls a dynamically resolved function without a validity guard

**What:** The native wrapper invokes `dotnet_SendFriendAddRequest` unconditionally. A missing or failed export resolution becomes a null or stale indirect call and terminates the process before managed exception handling can run.
**Evidence:** `MuMain/src/source/Dotnet/PacketFunctions_ClientToServer.cpp:716` calls the function pointer without checking it; `MuMain/src/source/Dotnet/Connection.cpp:230` resolves the export dynamically. No built client library or crash artifact exists in this workspace to confirm export state at failure time.
**Affected scope:** Friend-add packet dispatch and any build/package where native AOT exports drift from generated bindings.
**Proposed fix:** Validate required exports during connection initialization and fail connection setup with a logged error. Add a narrow defensive check in `SendFriendAddRequest` until centralized validation exists.
**Estimated lines:** ~10 lines across 2 files

## Implementation Plan

1. Change `UIWindows.cpp` and its matching header to pass friend names by owned value, removing raw pointer allocation and deletion from the UI message path.
2. Change `Connection.cpp` to validate the `SendFriendAddRequest` export during binding, so packaging errors fail before gameplay.
3. Change `PacketFunctions_ClientToServer.cpp` to reject an unavailable binding without an indirect call.
4. Add one focused test or runnable harness covering dialog submit, cancel, repeated submit, and a missing export.

## Post-Fix Verification

1. Build with the normal project preset and confirm no compile or link errors.
2. Log in, open friend list, submit a valid name, an invalid name, and the same name twice; expected result is a packet/result dialog with no crash.
3. Submit via Enter and via the OK button; expected result is exactly one request per action.
4. Run a build with the friend-add export intentionally unavailable; expected result is a logged initialization/send failure, not process termination.

## Scope Assessment

**Type:** bug
**Story count:** 1 story
**Epic home:** social systems
**Milestone relevance:** Runtime stability and cross-platform client completion
**Estimated points:** 3
