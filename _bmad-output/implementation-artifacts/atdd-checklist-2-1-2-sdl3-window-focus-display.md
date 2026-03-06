# ATDD Implementation Checklist — Story 2.1.2: SDL3 Window Focus & Display Management

**Story ID:** 2-1-2-sdl3-window-focus-display
**Story Type:** infrastructure
**Flow Code:** VS1-SDL-WINDOW-FOCUS
**Primary Test Level:** Unit (Catch2 v3.7.1)
**Generated:** 2026-03-06
**Phase:** RED (all tests fail — implementation pending)

---

## AC-to-Test Mapping

| AC | Description | Test Method(s) | Test File |
|----|-------------|----------------|-----------|
| AC-1 | Focus gain/loss events | (Integration/manual — cannot inject SDL events in unit tests; verified via code review of SDLEventLoop.cpp handlers) | SDLEventLoop.cpp |
| AC-2 | Display mode detection | `AC-2: MuPlatform::GetDisplaySize returns false when no window created`, `AC-2: MuPlatform::GetDisplaySize returns positive dimensions with window` | test_platform_window.cpp |
| AC-3 | Fullscreen toggle | `AC-3: SDLWindow::SetFullscreen does not crash when window is null`, `AC-3: MuPlatform::SetFullscreen toggles without crash on active window` | test_platform_window.cpp |
| AC-4 | Mouse cursor confinement | `AC-4: SDLWindow::SetMouseGrab does not crash when window is null`, `AC-4: MuPlatform::SetMouseGrab state transitions do not crash` | test_platform_window.cpp |
| AC-5 | Minimize/restore events | (Integration/manual — same as AC-1; verified via code review of SDLEventLoop.cpp handlers) | SDLEventLoop.cpp |
| AC-STD-2 | Testing requirements (null-guards) | All three null-guard tests above (AC-2, AC-3, AC-4 null cases) | test_platform_window.cpp |
| AC-STD-11 | Flow code VS1-SDL-WINDOW-FOCUS | `2.1.2-AC-STD-11:flow-code-focus` (CMake script test) | test_ac_std11_flow_code_2_1_2.cmake |

---

## Implementation Checklist

### Task 1 — Extend IPlatformWindow interface (AC-3, AC-4, AC-2)

- [ ] 1.1 Add `SetFullscreen(bool fullscreen)` pure virtual to IPlatformWindow.h
- [ ] 1.2 Add `SetMouseGrab(bool grab)` pure virtual to IPlatformWindow.h
- [ ] 1.3 Add `[[nodiscard]] bool GetDisplaySize(int& outWidth, int& outHeight) const` pure virtual to IPlatformWindow.h

### Task 2 — Implement SDL3 backend methods (AC-1, AC-2, AC-3, AC-4, AC-5)

- [ ] 2.1 SDLWindow::SetFullscreen — SDL_SetWindowFullscreen with null-guard and error logging (MU_ERR_FULLSCREEN_FAILED)
- [ ] 2.2 SDLWindow::SetMouseGrab — SDL_SetWindowMouseGrab with null-guard
- [ ] 2.3 SDLWindow::GetDisplaySize — SDL_GetCurrentDisplayMode via SDL_GetDisplayForWindow with null-guard and error logging (MU_ERR_DISPLAY_QUERY_FAILED)

### Task 3 — Implement Win32 backend stubs (AC-3, AC-4)

- [ ] 3.1 Win32Window::SetFullscreen — no-op stub with documenting comment
- [ ] 3.2 Win32Window::SetMouseGrab — no-op stub with documenting comment
- [ ] 3.3 Win32Window::GetDisplaySize — GetSystemMetrics(SM_CXSCREEN/SM_CYSCREEN) implementation

### Task 4 — Extend MuPlatform facade (AC-2, AC-3, AC-4)

- [ ] 4.1 MuPlatform::SetFullscreen — delegates to s_pWindow->SetFullscreen if window exists
- [ ] 4.2 MuPlatform::SetMouseGrab — delegates to s_pWindow->SetMouseGrab if window exists
- [ ] 4.3 MuPlatform::GetDisplaySize — delegates to s_pWindow->GetDisplaySize, returns false if no window

### Task 5 — Implement focus/minimize/restore handlers in SDLEventLoop (AC-1, AC-4, AC-5)

- [ ] 5.1 Replace 5 no-op stubs with real handler code; import necessary externs (verify exact types via grep)
- [ ] 5.2 SDL_EVENT_WINDOW_FOCUS_GAINED: g_bWndActive=true, restore FPS, mouse grab in fullscreen
- [ ] 5.3 SDL_EVENT_WINDOW_FOCUS_LOST: g_bWndActive=false, throttle FPS in fullscreen, clear mouse state in windowed, release mouse grab
- [ ] 5.4 SDL_EVENT_WINDOW_MINIMIZED: apply focus-loss logic (minimized = inactive)
- [ ] 5.5 SDL_EVENT_WINDOW_RESTORED: apply focus-gain logic (restored = active)

### Task 6 — Replace EnumDisplaySettings in non-Windows path (AC-2)

- [ ] 6.1 Add MuPlatform::GetDisplaySize call in MuMain() SDL3 init path (#ifdef MU_ENABLE_SDL3)
- [ ] 6.2 Log display size with flow code: [VS1-SDL-WINDOW-FOCUS]

### Task 7 — Tests (AC-STD-2, AC-STD-11)

- [ ] 7.1 Unit tests: 3 null-guard tests + 3 active-window tests in test_platform_window.cpp (RED phase — compile but fail until implementation)
- [ ] 7.2 CMake script test: test_ac_std11_flow_code_2_1_2.cmake verifies VS1-SDL-WINDOW-FOCUS in SDLEventLoop.cpp
- [ ] 7.3 Register CMake test in tests/platform/CMakeLists.txt

### Task 8 — Quality Gate Verification (AC-STD-13)

- [ ] 8.1 Run format-check — fix any formatting issues
- [ ] 8.2 Run lint (cppcheck) — resolve all warnings
- [ ] 8.3 Verify ./ctl check passes locally on macOS

---

## PCC Compliance Verification

- [ ] No prohibited libraries used (no raw new/delete, no NULL, no wprintf, no Win32 APIs in game logic)
- [ ] Required patterns followed: [[nodiscard]] on GetDisplaySize, std::unique_ptr for ownership, g_ErrorReport.Write() for errors with MU_ERR_* prefix
- [ ] MU_ENABLE_SDL3 compile-time guard on all SDL3 code paths
- [ ] Catch2 v3.7.1 via FetchContent with BUILD_TESTING=ON opt-in
- [ ] Flow code VS1-SDL-WINDOW-FOCUS in log messages and test names
- [ ] Tests do not depend on Win32 APIs — test logic via MuPlatform facade
- [ ] No #ifdef _WIN32 in game logic — only in Platform/ abstraction layer
- [ ] Error codes MU_ERR_FULLSCREEN_FAILED and MU_ERR_DISPLAY_QUERY_FAILED documented in error-catalog.md

---

## Test Files Created (RED Phase)

| File | Type | Status |
|------|------|--------|
| `MuMain/tests/platform/test_platform_window.cpp` | Catch2 unit tests | MODIFIED — 6 new test cases added (fail until Tasks 1-4 implemented) |
| `MuMain/tests/platform/test_ac_std11_flow_code_2_1_2.cmake` | CMake script test | NEW — fails until Task 5 adds flow code to SDLEventLoop.cpp |
| `MuMain/tests/platform/CMakeLists.txt` | CMake test registration | MODIFIED — registered 2.1.2 CMake test |

---

## Output Summary

- **Story:** 2-1-2-sdl3-window-focus-display (infrastructure)
- **Primary test level:** Unit (Catch2 v3.7.1)
- **Failing tests created:** 6 unit tests (Catch2) + 1 CMake script test = 7 total
- **PCC compliance:** All items pending verification during GREEN phase
- **Output path:** `_bmad-output/implementation-artifacts/atdd-checklist-2-1-2-sdl3-window-focus-display.md`
