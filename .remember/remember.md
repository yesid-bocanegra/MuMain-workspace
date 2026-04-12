# Handoff

## State
**GAME IS FULLY PLAYABLE on macOS/SDL3 — rendering, input, hotkeys, and audio all working.** Two-session fix tally: viewport globals for 3D picking, Begin2DPass viewport reset, RenderColor default 0xCC000000, text input DoAction, CachTexture removal, BeginOpengl render state sync, g_hWnd sentinel for hotkeys, mouse push/edge flag lifecycle, audio config enabled.

## Next
1. **`PlatformLibrary::GetSymbol() failed` spam** — ~190 warning lines at startup from ConnectServer/ChatServer bindings resolving before .NET library loads. Harmless but noisy.
2. **g_petProcess null crash on exit** — `ThePetProcess()` assert in `CNewUIMyInventory::Release()` during shutdown. Only on exit.
3. **RenderColor audit** — 0xCC000000 default covers ~90%. Some colored bars/borders may need explicit Alpha/Flag.
4. **Missing assets** — Object74/75 models, ExtTile textures, some Skill/Effect files. Distribution issue, not code.
5. **Intermittent click loss** — some clicks not delivered at OS/SDL level. Flag lifecycle fixes improved it but didn't eliminate 100%.

## Context
- Connection.cpp needs Bindings headers BEFORE Functions headers (order-sensitive include)
- BeginOpengl syncs ALL render state (texture2D, alphaTest, depthTest, depthMask, cullFace) with tracking variables
- CachTexture optimization removed — was causing desync with direct BindTexture calls in UIControls/ZzzInventory
- Mouse push/edge flags: accumulate across PollEvents (survive frame throttling), cleared in RenderScene after game logic
- g_hWnd = (HWND)1 sentinel matches GetFocus()/GetActiveWindow() shims
- Audio: config.ini SoundEnabled=1/MusicEnabled=1 required; MiniAudioBackend uses CoreAudio via miniaudio
- `g_iChatInputType = 1` (CUITextInputBox path active)
