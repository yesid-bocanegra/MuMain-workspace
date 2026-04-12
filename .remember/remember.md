# Handoff

## State
**GAME IS PLAYABLE on macOS/SDL3 — rendering stable, input working.** Session fixes: viewport globals for 3D picking, Begin2DPass viewport reset, RenderColor default 0xCC000000, text input DoAction, CachTexture removal, BeginOpengl render state sync, g_hWnd sentinel for hotkeys, mouse push/edge flag lifecycle (accumulate across PollEvents, clear in RenderScene after consumption).

## Next
1. **Sound playback** — nothing plays (BGM, SFX, ambient). SDL3 audio backend needs investigation.
2. **g_petProcess null crash on exit** — `ThePetProcess()` assert in `CNewUIMyInventory::Release()` during shutdown.
3. **RenderColor audit** — 0xCC000000 default fixes most cases but some UI elements may need explicit Alpha/Flag.
4. **Missing assets** — genuinely missing from game distribution (not a code bug).

## Context
- Connection.cpp needs Bindings headers BEFORE Functions headers (order-sensitive)
- BeginOpengl syncs ALL render state with tracking variables (texture2D, alphaTest, depthTest, depthMask, cullFace)
- CachTexture optimization removed — was causing desync with direct BindTexture calls
- Mouse push/edge flags: accumulate in PollEvents (survive frame throttling), cleared in RenderScene after game logic
- g_hWnd = (HWND)1 sentinel matches GetFocus()/GetActiveWindow() shims
- `g_iChatInputType = 1` (CUITextInputBox path active)
