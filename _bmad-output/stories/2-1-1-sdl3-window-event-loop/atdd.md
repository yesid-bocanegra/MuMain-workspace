# ATDD Implementation Checklist: Story 2.1.1 — SDL3 Window Creation & Event Loop

**Story ID:** 2.1.1
**Story Key:** 2-1-1-sdl3-window-event-loop
**Story Type:** infrastructure
**Flow Code:** VS1-SDL-WINDOW-CREATE
**Primary Test Level:** Unit (Catch2 v3.7.1) + Integration (CMake script-mode)
**Date Generated:** 2026-03-06

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Method / Name |
|----|-------------|-----------|-------------------|
| AC-1 | Window creation via MuPlatform::CreateWindow | test_platform_window.cpp | `AC-1: MuPlatform::CreateWindow creates a window` |
| AC-1 | Platform interface headers exist | test_ac1_platform_interfaces.cmake | `2.1.1-AC-1:platform-interfaces-exist` |
| AC-2 | Event loop via MuPlatform::PollEvents | test_platform_window.cpp | `AC-2: MuPlatform::PollEvents pumps events without blocking` |
| AC-3 | Window lifecycle events no crash | test_platform_window.cpp | `AC-3: Window lifecycle events do not crash` |
| AC-4 | Configurable title/dimensions/flags | test_platform_window.cpp | `AC-4: Window creation accepts title and dimensions` |
| AC-5 | GetWindow() singleton handle | test_platform_window.cpp | `AC-5: MuPlatform::GetWindow returns consistent singleton` |
| AC-6 | Quit event signals clean exit | test_platform_window.cpp | `AC-6: Clean exit on quit event` |
| AC-7 | SDL3 code guarded by MU_ENABLE_SDL3 | test_ac7_cmake_sdl3_guard.cmake | `2.1.1-AC-7:cmake-sdl3-guard` |
| AC-7 | SDL3 files have ifdef guard | test_ac7_sdl3_ifdef_guard.cmake | `2.1.1-AC-7:sdl3-ifdef-guard` |
| AC-STD-2 | Catch2 unit tests exist | test_platform_window.cpp | `AC-STD-2: Platform module has Catch2 unit tests` |
| AC-STD-8 | Error codes defined | test_platform_window.cpp | `AC-STD-8: SDL3 error codes defined` |
| AC-STD-11 | Flow code in artifacts | test_ac_std11_flow_code.cmake | `2.1.1-AC-STD-11:flow-code` |
| AC-STD-16 | Catch2 v3.7.1 infrastructure | test_platform_window.cpp | `AC-STD-16: Test infrastructure uses Catch2 v3.7.1` |

---

## Implementation Checklist

### Platform Interfaces (Task 1)

- [x]IPlatformWindow.h created with Create/Destroy/GetNativeHandle/SetTitle/SetSize
- [x]IPlatformEventLoop.h created with PollEvents() -> bool
- [x]MuPlatform.h created with static facade: Initialize, CreateWindow, GetWindow, PollEvents, Shutdown
- [x]MuPlatform.cpp added to MUPlatform CMake target
- [x]All headers use #pragma once
- [x]All headers use [[nodiscard]] on fallible functions

### SDL3 Backend (Task 2)

- [x]SDLWindow.h + SDLWindow.cpp created in Platform/sdl3/
- [x]SDLEventLoop.h + SDLEventLoop.cpp created in Platform/sdl3/
- [x]MuPlatform.cpp routes to SDL3 backend when MU_ENABLE_SDL3 defined
- [x]SDL_Init(SDL_INIT_VIDEO) called once at startup
- [x]SDL_Quit called on teardown
- [x]SDL_EVENT_QUIT maps to Destroy = true
- [x]SDL_EVENT_WINDOW_CLOSE_REQUESTED maps to Destroy = true
- [x]Window resize/focus events handled (no-op or mapped)
- [x]All SDL3 files guarded with #ifdef MU_ENABLE_SDL3

### Win32 Backend Stub (Task 3)

- [x]Win32Window.h + Win32Window.cpp created in Platform/win32/
- [x]Win32EventLoop.h + Win32EventLoop.cpp created in Platform/win32/
- [x]Win32 backend wraps existing g_hWnd and HINSTANCE code
- [x]Win32 behavior unchanged from pre-migration

### WinMain Refactor (Task 4)

- [x]MuMain(int argc, char* argv[]) function extracted from WinMain()
- [x]WinMain wrapper retained on Windows (#ifdef _WIN32)
- [x]main() entry point added for non-Windows (#else)
- [x]Non-Windows path uses MuPlatform::PollEvents() instead of GetMessage/DispatchMessage
- [x]Non-Windows path uses MuPlatform::CreateWindow() instead of CreateWindowEx
- [x]g_hWnd set from IPlatformWindow::GetNativeHandle() on Windows

### CMake Integration (Task 5)

- [x]SDL3 sources added to MUPlatform with if(MU_ENABLE_SDL3) guard
- [x]Win32 sources added to MUPlatform (Windows or NOT MU_ENABLE_SDL3)
- [x]MuPlatform.cpp added unconditionally
- [x]SDL3::SDL3-static linked PRIVATELY to MUPlatform
- [x]CI MinGW -DMU_ENABLE_SDL3=OFF still set and build succeeds

### Tests (Task 6)

- [x]test_platform_window.cpp compiles with Catch2 v3.7.1
- [x]AC-1 test: CreateWindow succeeds
- [x]AC-2 test: PollEvents returns without blocking on empty queue
- [x]AC-5 test: GetWindow() returns same singleton instance
- [x]AC-5 test: GetWindow() returns nullptr before CreateWindow
- [x]AC-7 CMake test: SDL3 sources guarded by MU_ENABLE_SDL3
- [x]AC-7 CMake test: All SDL3 files have #ifdef MU_ENABLE_SDL3
- [x]AC-1 CMake test: Platform interface headers exist with correct declarations
- [x]AC-STD-11 CMake test: Flow code and story references in test files

### MessageBoxW SDL3 Implementation (Task 7)

- [x]PlatformCompat.h stub replaced with SDL_ShowSimpleMessageBox (MU_ENABLE_SDL3 guarded)
- [x]MB_YESNO dialogs use SDL_ShowMessageBox with two buttons

### Quality Gate (Task 8)

- [x]format-check passes (make -C MuMain format-check)
- [x]lint passes (make -C MuMain lint)
- [x]./ctl check passes on macOS

### PCC Compliance

- [x]No prohibited libraries used (no raw new/delete, no NULL, no #ifdef _WIN32 in game logic)
- [x]Required patterns followed: [[nodiscard]], std::unique_ptr, g_ErrorReport.Write(), PRIVATE CMake linking
- [x]MU_ENABLE_SDL3 compile-time guard on all SDL3 code
- [x]Catch2 v3.7.1 via FetchContent for tests
- [x]No new Win32 API calls in game logic (only in Platform/ layer)
- [x]Forward slashes only in paths, no wchar_t in new serialization
- [x]Error codes MU_ERR_SDL_INIT_FAILED and MU_ERR_WINDOW_CREATE_FAILED added to error catalog

---

## Test Files Created (RED Phase)

| File | Type | Status |
|------|------|--------|
| `MuMain/tests/platform/test_platform_window.cpp` | Catch2 unit test | RED (will not compile — MuPlatform.h does not exist yet) |
| `MuMain/tests/platform/test_ac1_platform_interfaces.cmake` | CMake script-mode | RED (interface headers do not exist) |
| `MuMain/tests/platform/test_ac7_cmake_sdl3_guard.cmake` | CMake script-mode | RED (SDL3 sources not in CMakeLists.txt) |
| `MuMain/tests/platform/test_ac7_sdl3_ifdef_guard.cmake` | CMake script-mode | RED (Platform/sdl3/ directory does not exist) |
| `MuMain/tests/platform/test_ac_std11_flow_code.cmake` | CMake script-mode | GREEN (test file already has [2-1-1] tags) |

---

## PCC Compliance Summary

| Check | Status |
|-------|--------|
| Prohibited libraries | CLEAN — no prohibited libraries in tests or story |
| Required testing patterns | COMPLIANT — Catch2 v3.7.1, GIVEN/WHEN/THEN structure |
| Test profiles | N/A — no database/profile setup needed |
| Coverage target | 0 threshold (growing incrementally per project-context.md) |
| Playwright E2E | N/A — infrastructure story, no frontend |
| Bruno API tests | N/A — infrastructure story, no HTTP endpoints |

---

## Output Summary

- **Story ID:** 2.1.1 (2-1-1-sdl3-window-event-loop)
- **Primary test level:** Unit (Catch2) + Integration (CMake script-mode)
- **Failing tests created:** 4 RED files (1 Catch2 unit test, 3 CMake script-mode)
- **GREEN tests:** 1 (AC-STD-11 flow code — already passes)
- **Output file:** `_bmad-output/implementation-artifacts/atdd-checklist-2-1-1.md`
