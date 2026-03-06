# MuMain Error Catalog

Error codes used with `g_ErrorReport.Write()` for post-mortem diagnostics.

## Platform Errors

| Code | Category | Introduced | Description |
|------|----------|-----------|-------------|
| MU_ERR_SDL_INIT_FAILED | Platform | 2.1.1 | SDL3 initialization failed |
| MU_ERR_WINDOW_CREATE_FAILED | Platform | 2.1.1 | Window creation via SDL3 failed |
| MU_ERR_FULLSCREEN_FAILED | Platform | 2.1.2 | SDL3 fullscreen set failed |
| MU_ERR_DISPLAY_QUERY_FAILED | Platform | 2.1.2 | SDL3 display mode query failed |
| MU_ERR_INPUT_UNMAPPED_VK | Platform | 2.2.1 | GetAsyncKeyState shim: VK code has no SDL_Scancode mapping — `INPUT: key mapping — unmapped VK code 0x{XX} [VS1-SDL-INPUT-KEYBOARD]` |
| MU_ERR_MOUSE_WARP_FAILED | Platform | 2.2.2 | SetCursorPos shim: SDL_WarpMouseInWindow failed — `MOUSE: cursor warp failed [VS1-SDL-INPUT-MOUSE]: {SDL_GetError()}` |
