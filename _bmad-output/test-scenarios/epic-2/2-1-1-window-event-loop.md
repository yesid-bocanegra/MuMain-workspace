# Test Scenarios: Story 2.1.1 — SDL3 Window Creation & Event Loop

**Generated:** 2026-03-07
**Story:** 2.1.1 SDL3 Window Creation & Event Loop
**Flow Code:** VS1-SDL-WINDOW-CREATE
**Project:** MuMain-workspace

These scenarios cover manual validation of Story 2.1.1 acceptance criteria.
Automated tests (Catch2 unit + CMake script) are in `MuMain/tests/platform/`.
Manual scenarios require full game compilation (blocked until EPIC-4 rendering
migration completes).

---

## AC-1: Window Created via MuPlatform::CreateWindow

### Scenario 1: Game window opens on macOS arm64
- **Given:** Game compiled with `MU_ENABLE_SDL3=ON` on macOS arm64 (requires EPIC-4)
- **When:** `WinMain()` calls `mu::MuPlatform::CreateWindow(title, width, height, flags)`
- **Then:** A native macOS window appears; no Win32 `CreateWindowEx` call in game logic; window title matches game title
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 2: Game window opens on Linux x64
- **Given:** Game compiled with `MU_ENABLE_SDL3=ON` on Linux x64 (requires EPIC-4)
- **When:** `WinMain()` calls `mu::MuPlatform::CreateWindow(title, width, height, flags)`
- **Then:** A native Linux window appears (X11 or Wayland); window is visible and focusable
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 3: Windows build delegates to Win32 path unchanged
- **Given:** Game compiled with `MU_ENABLE_SDL3=OFF` on Windows (MinGW or MSVC)
- **When:** `WinMain()` starts
- **Then:** Existing Win32 `CreateWindowEx` path executes; no regression; game runs identically to pre-EPIC-2
- **Automated:** CI MinGW build with `MU_ENABLE_SDL3=OFF` (CI Strategy B)
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-2: Main Event Loop via PollEvents

### Scenario 4: Event loop runs without blocking on macOS/Linux
- **Given:** Game running on non-Windows platform with SDL3 event loop
- **When:** Main loop calls `mu::MuPlatform::PollEvents()` each frame
- **Then:** Loop does not block; events are pumped and processed; frame rate is not throttled by event starvation
- **Automated:** `TEST_CASE("AC-2 [VS1-SDL-WINDOW-CREATE]: PollEvents returns immediately when event queue is empty")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 5: Win32 path retains GetMessage/DispatchMessage loop
- **Given:** Game compiled with `MU_ENABLE_SDL3=OFF` on Windows
- **When:** Main loop runs
- **Then:** Existing `GetMessage`/`DispatchMessage` loop is used; no SDL3 event loop code active; behavior unchanged
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-3: Window Lifecycle Events Handled Without Crash

### Scenario 6: Window close event triggers clean shutdown
- **Given:** Game running on non-Windows platform with SDL3 event loop
- **When:** User clicks the window close button (X button)
- **Then:** `SDL_EVENT_QUIT` sets `Destroy = true`; existing shutdown sequence runs; game exits cleanly without crash
- **Automated:** `TEST_CASE("AC-6 [VS1-SDL-WINDOW-CREATE]: Quit event sets Destroy flag")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 7: Window resize event does not crash
- **Given:** Game running on non-Windows platform in windowed mode
- **When:** User resizes the game window
- **Then:** No crash; engine handles or ignores `SDL_EVENT_WINDOW_RESIZED` gracefully
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 8: Window minimize and restore do not crash
- **Given:** Game running on non-Windows platform
- **When:** User minimizes then restores the game window
- **Then:** No crash; game resumes after restore
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes; extended coverage in story 2.1.2
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-4: Title, Dimensions, and Window Mode Flags Respected

### Scenario 9: Windowed mode respects g_bUseWindowMode
- **Given:** Game configured for windowed mode (`g_bUseWindowMode = true`)
- **When:** `CreateWindow()` is called with windowed flags
- **Then:** Window opens in windowed mode at configured dimensions; not fullscreen
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 10: Fullscreen mode respects g_bUseFullscreenMode
- **Given:** Game configured for fullscreen mode (`g_bUseFullscreenMode = true`)
- **When:** `CreateWindow()` is called with fullscreen flags (`mu::MU_WINDOW_FULLSCREEN`)
- **Then:** Window opens fullscreen; no window border; display fills screen
- **Note:** Manual test — deferred until EPIC-4 rendering migration completes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 11: MU_WINDOW_FULLSCREEN constant defined (no magic 0x1)
- **Given:** Story 2.1.1 implementation in place
- **When:** Source inspected or compiled
- **Then:** `mu::MU_WINDOW_FULLSCREEN` constant (= 0x1) used in all call sites; no inline `0x1` magic number literals
- **Automated:** Code review confirmed this fix applied in code-review-finalize 2026-03-06
- **Status:** [x] Passed — 2026-03-06 (constant introduced in IPlatformWindow.h)

---

## AC-5: GetWindow() Singleton and No Raw HWND

### Scenario 12: GetWindow() returns consistent singleton
- **Given:** Game running on non-Windows platform
- **When:** `mu::MuPlatform::GetWindow()` is called multiple times
- **Then:** Always returns the same singleton pointer; pointer is not null after window creation
- **Automated:** `TEST_CASE("AC-5 [VS1-SDL-WINDOW-CREATE]: GetWindow singleton is consistent")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 13: No raw HWND g_hWnd for windowing on non-Windows
- **Given:** Game compiled with `MU_ENABLE_SDL3=ON`
- **When:** Source compiled
- **Then:** `g_hWnd` may remain as null shim; windowing does not depend on it; no Win32 `CreateWindowEx` or `HWND` usage in game logic paths
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-6: Clean Exit on Window Close

### Scenario 14: Destroy flag set on SDL quit event
- **Given:** Game running on non-Windows platform
- **When:** SDL quit event received (window close, OS shutdown signal)
- **Then:** `Destroy = true` is set; existing shutdown sequence runs cleanly; no hanging or crash
- **Automated:** `TEST_CASE("AC-6 [VS1-SDL-WINDOW-CREATE]: Quit event sets Destroy flag")`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-7: Windows Build Unaffected (MU_ENABLE_SDL3=OFF)

### Scenario 15: MinGW CI build passes with SDL3 code disabled
- **Given:** All new SDL3 code guarded by `#ifdef MU_ENABLE_SDL3`
- **When:** MinGW CI job runs (`cmake ... -DMU_ENABLE_SDL3=OFF`)
- **Then:** Build succeeds; no compile errors from new window/event loop files; game links correctly
- **Automated:** CI Strategy B — enforced on all SDL3 stories
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 16: MSVC build passes with SDL3 code disabled
- **Given:** All new SDL3 code guarded by `#ifdef MU_ENABLE_SDL3`
- **When:** MSVC build runs (`cmake --preset windows-x64`)
- **Then:** Build succeeds; no regression in Windows-native path
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-STD-8: Error Logging via g_ErrorReport

### Scenario 17: SDL_Init failure logged with error code
- **Given:** Simulated `SDL_Init` failure (or non-SDL environment)
- **When:** `MuPlatform::CreateWindow()` is called and SDL init fails
- **Then:** `g_ErrorReport.Write()` records `MU_ERR_SDL_INIT_FAILED [VS1-SDL-WINDOW-CREATE]: {SDL_GetError()}` in post-mortem log
- **Automated:** Code review confirmed fix applied 2026-03-06 (HIGH #5 from session summary)
- **Status:** [x] Passed — 2026-03-06 (g_ErrorReport.Write added for SDL_Init and CreateWindow failures)

### Scenario 18: CreateWindow failure logged with error code
- **Given:** Simulated SDL window creation failure
- **When:** `SDL_CreateWindow` returns null
- **Then:** `g_ErrorReport.Write()` records `MU_ERR_WINDOW_CREATE_FAILED [VS1-SDL-WINDOW-CREATE]: {SDL_GetError()}` in post-mortem log
- **Status:** [x] Passed — 2026-03-06 (same fix as Scenario 17)

---

## AC-STD-11: Flow Code in Artifacts

### Scenario 19: VS1-SDL-WINDOW-CREATE present in source artifacts
- **Given:** Story 2.1.1 implementation complete
- **When:** CTest runs `2.1.1-AC-STD-11:flow-code-window-create`
- **Then:** Test passes — `VS1-SDL-WINDOW-CREATE` found in test file headers and CMake validation
- **Automated:** Code review confirmed flow code added 2026-03-06 (HIGH #6 from session summary)
- **Status:** [x] Passed — 2026-03-06

---

## Quality Gate Verification

### Scenario 20: format-check passes
- **Given:** All story 2.1.1 files formatted per .clang-format (Allman, 4-space, 120-col)
- **When:** `./ctl check` runs
- **Then:** No formatting differences reported; exit code 0
- **Status:** [x] Passed — 2026-03-06 (688/688 files clean at time of code-review-finalize)

### Scenario 21: cppcheck lint passes
- **Given:** New Platform/ files have no cppcheck warnings
- **When:** `./ctl check` runs
- **Then:** No warnings reported for new files; exit code 0
- **Status:** [x] Passed — 2026-03-06 (688/688 files clean at code-review-finalize)

### Scenario 22: Input validation guards CreateWindow
- **Given:** Caller passes null title, zero width, or negative height
- **When:** `MuPlatform::CreateWindow()` is called
- **Then:** Validation returns false before any backend selection; no crash or UB
- **Automated:** Code review confirmed fix applied 2026-03-06 (HIGH #2 from session summary)
- **Status:** [x] Passed — 2026-03-06 (null/bounds checks added at lines 60-63)
