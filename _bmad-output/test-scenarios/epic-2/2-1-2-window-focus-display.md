# Test Scenarios — Story 2.1.2: SDL3 Window Focus & Display Management

**Flow Code:** VS1-SDL-WINDOW-FOCUS

---

## Automated Tests (Catch2 Unit)

| Test | AC | File |
|------|-----|------|
| SetFullscreen null-guard | AC-3, AC-STD-2 | test_platform_window.cpp |
| SetMouseGrab null-guard | AC-4, AC-STD-2 | test_platform_window.cpp |
| GetDisplaySize returns false with no window | AC-2, AC-STD-2 | test_platform_window.cpp |
| GetDisplaySize returns positive dims with window | AC-2 | test_platform_window.cpp |
| SetFullscreen on active window no crash | AC-3 | test_platform_window.cpp |
| SetMouseGrab state transitions no crash | AC-4 | test_platform_window.cpp |

## Automated Tests (CMake Script)

| Test | AC | File |
|------|-----|------|
| Flow code VS1-SDL-WINDOW-FOCUS in SDLEventLoop.cpp | AC-STD-11 | test_ac_std11_flow_code_2_1_2.cmake |

## Manual Test Scenarios

### MTS-1: Alt-Tab Focus Behavior (macOS/Linux)

**Prerequisites:** Game running on macOS arm64 or Linux x64 with SDL3 backend.

1. Launch game in windowed mode
2. Alt-Tab to another application
3. **Expected:** `g_bWndActive` set to false, mouse buttons cleared, game continues at normal FPS
4. Alt-Tab back to game
5. **Expected:** `g_bWndActive` set to true, game resumes normally

### MTS-2: Alt-Tab Focus Behavior in Fullscreen

**Prerequisites:** Game running in fullscreen mode with SDL3 backend.

1. Launch game in fullscreen mode
2. Alt-Tab to another application
3. **Expected:** `g_bWndActive` set to false, FPS throttled to 25fps (`REFERENCE_FPS`), mouse grab released
4. Alt-Tab back to game
5. **Expected:** `g_bWndActive` set to true, FPS restored to previous value, mouse grab re-engaged

### MTS-3: Fullscreen Toggle

**Prerequisites:** Game running on macOS arm64 or Linux x64 with SDL3 backend.

1. Launch game in windowed mode
2. Trigger fullscreen toggle (via `MuPlatform::SetFullscreen(true)`)
3. **Expected:** Window enters fullscreen without crash or hang
4. Trigger windowed toggle (via `MuPlatform::SetFullscreen(false)`)
5. **Expected:** Window returns to windowed mode

### MTS-4: Display Resolution Detection

**Prerequisites:** Game running with SDL3 backend.

1. Launch game
2. Check log for `[VS1-SDL-WINDOW-FOCUS] Display size: WxH`
3. **Expected:** Width and height match the display's native resolution
4. On multi-monitor: verify the reported resolution matches the display the window is on

### MTS-5: Minimize/Restore Behavior

**Prerequisites:** Game running with SDL3 backend.

1. Minimize the game window
2. **Expected:** Same behavior as focus-loss (inactive, FPS throttled in fullscreen)
3. Restore the game window
4. **Expected:** Same behavior as focus-gain (active, FPS restored)
