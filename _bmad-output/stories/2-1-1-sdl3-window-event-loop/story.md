# Story 2.1.1: SDL3 Window Creation & Event Loop

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 2 - SDL3 Windowing & Input Migration |
| Feature | 2.1 - SDL3 Window Management |
| Story ID | 2.1.1 |
| Story Points | 5 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-1 |
| Flow Code | VS1-SDL-WINDOW-CREATE |
| FRs Covered | EPIC-2 window/event-loop migration |
| Prerequisites | EPIC-1 done (1.3.1 SDL3 dependency integration complete) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | New Platform interfaces (IPlatformWindow, IPlatformEventLoop), SDL3 backend (SDLWindow.cpp), Win32 backend stub, WinMain refactor to MuMain(), CMake integration |
| project-docs | documentation | Test scenarios for epic-2, story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** game client developer,
**I want** the game window and main event loop to use SDL3 instead of Win32 `CreateWindowEx`/`GetMessage`/`DispatchMessage`,
**so that** the client can open a native window and run its main loop on macOS and Linux without any Win32 windowing APIs in game logic.

---

## Functional Acceptance Criteria

- [x] **AC-1:** A game window opens via `mu::MuPlatform::CreateWindow(title, width, height, flags)` — the call creates an SDL3 window on non-Windows platforms and delegates to the existing Win32 path on Windows; no direct `CreateWindowEx` in game logic.
- [x] **AC-2:** The main event loop calls `mu::MuPlatform::PollEvents()` instead of `GetMessage`/`DispatchMessage`; the loop correctly pumps SDL3 events on non-Windows and Win32 messages on Windows.
- [x] **AC-3:** Window lifecycle events (close / resize / focus-in / focus-out / minimize / restore) are translated by the SDL3 backend into the existing game engine's event model (or ignored where no corresponding handler exists), so the engine does not crash on these events.
- [x] **AC-4:** Window creation accepts a configurable title string and dimensions; the existing `g_bUseWindowMode` / `g_bUseFullscreenMode` globals are respected via the window flags parameter.
- [x] **AC-5:** `mu::MuPlatform::GetWindow()` returns a singleton handle to the active platform window; `Winmain.cpp` no longer stores a raw `HWND g_hWnd` for windowing purposes (it may remain as a no-op / null shim on non-Windows).
- [x] **AC-6:** On quit (window-close event or OS request), the event loop signals clean exit; `Destroy = true` is set so the existing shutdown sequence runs unchanged.
- [x] **AC-7:** The MinGW / MSVC Windows builds are unaffected — all new SDL3 code is compiled only when `MU_ENABLE_SDL3=ON`; the Windows path retains the existing Win32 WndProc and event loop.

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code standards compliance — PascalCase public functions, `m_` Hungarian member prefix, `std::unique_ptr` (no raw `new`/`delete`), `nullptr`, `#pragma once`, Allman braces, 4-space indent, LF line endings, UTF-8 files.
- [x] **AC-STD-2:** Testing requirements — Catch2 v3.7.1 unit tests in `MuMain/tests/`; tests cover: window creation succeeds, `GetWindow()` singleton is consistent, `PollEvents()` does not block when queue is empty.
- [x] **AC-STD-8:** Error codes — any new `MU_ERR_*` codes added to error catalog; SDL3 error strings surfaced via `g_ErrorReport.Write()`.
- [x] **AC-STD-10:** Contract catalogs — this story introduces no HTTP API or event-bus contracts; N/A.
- [x] **AC-STD-11:** Flow code `VS1-SDL-WINDOW-CREATE` appears in relevant log output, test names, and story artifacts.
- [x] **AC-STD-12:** SLI/SLO targets — N/A for this platform infrastructure story (no HTTP endpoints, no latency SLOs). Platform initialization must succeed (SDL_Init return value checked) and window creation must complete without blocking (verified by unit test in Task 6).
- [x] **AC-STD-13:** Quality gate passes: `make -C MuMain format-check && make -C MuMain lint`
- [x] **AC-STD-15:** Git safety — clean merge, no force push, no incomplete rebase.
- [x] **AC-STD-16:** Correct test infrastructure — Catch2 v3.7.1 via FetchContent, tests in `MuMain/tests/platform/`, `BUILD_TESTING=ON` opt-in.
- [x] **AC-STD-20:** N/A — no HTTP endpoints, event-bus entries, or nav-catalog screens in this story.

---

## Validation Artifacts

- [x] **AC-VAL-1:** N/A — no HTTP endpoints.
- [x] **AC-VAL-2:** Test scenarios documented in `_bmad-output/test-scenarios/epic-2/2-1-1-window-event-loop.md`
- [x] **AC-VAL-3:** N/A — no seed data.
- [x] **AC-VAL-4:** N/A — no API catalog entries.
- [x] **AC-VAL-5:** N/A — no event-bus events.
- [x] **AC-VAL-6:** Flow catalog entry `VS1-SDL-WINDOW-CREATE` confirmed in flow catalog or story.

---

## Tasks / Subtasks

- [x] **Task 1 — Define Platform Interfaces** (AC: 1, 2, 5)
  - [x]1.1 Create `MuMain/src/source/Platform/IPlatformWindow.h` — abstract interface with `Create()`, `Destroy()`, `GetNativeHandle()`, `SetTitle()`, `SetSize()` declarations.
  - [x]1.2 Create `MuMain/src/source/Platform/IPlatformEventLoop.h` — abstract interface with `PollEvents()` → `bool` (returns false on quit) declaration.
  - [x]1.3 Create `MuMain/src/source/Platform/MuPlatform.h` — static façade header exposing `mu::MuPlatform::CreateWindow(...)`, `mu::MuPlatform::GetWindow()`, `mu::MuPlatform::PollEvents()`.
  - [x]1.4 Add `MuPlatform.cpp` to `MUPlatform` CMake target.

- [x] **Task 2 — SDL3 Backend** (AC: 1, 2, 3, 4, 5, 6)
  - [x]2.1 Create `MuMain/src/source/Platform/sdl3/SDLWindow.h` + `SDLWindow.cpp` — `SDLWindow` class implementing `IPlatformWindow` using `SDL_CreateWindow` / `SDL_DestroyWindow`. Guard entire file with `#ifdef MU_ENABLE_SDL3`.
  - [x]2.2 Create `MuMain/src/source/Platform/sdl3/SDLEventLoop.h` + `SDLEventLoop.cpp` — `SDLEventLoop` implementing `IPlatformEventLoop` using `SDL_PollEvent`. Map `SDL_EVENT_QUIT` → set `Destroy = true`. Map window events (resize, focus) to no-ops initially. Guard with `#ifdef MU_ENABLE_SDL3`.
  - [x]2.3 Implement `MuPlatform.cpp` — `#ifdef MU_ENABLE_SDL3` → instantiate `SDLWindow` + `SDLEventLoop`; `#else` → Win32 stub path (empty or existing Win32 code path).
  - [x]2.4 Ensure `SDL_Init(SDL_INIT_VIDEO)` is called once at startup (in `MuPlatform::Initialize()` or equivalent) and `SDL_Quit()` on teardown.

- [x] **Task 3 — Win32 Backend Stub** (AC: 7)
  - [x]3.1 Create `MuMain/src/source/Platform/win32/Win32Window.h` + `Win32Window.cpp` — `Win32Window` implementing `IPlatformWindow` by wrapping existing `g_hWnd` and `HINSTANCE`-based window creation. Delegates to existing `Winmain.cpp` code so Windows behavior is unchanged.
  - [x]3.2 Create `MuMain/src/source/Platform/win32/Win32EventLoop.h` + `Win32EventLoop.cpp` — `Win32EventLoop` implementing `IPlatformEventLoop` wrapping existing `GetMessage`/`DispatchMessage` loop.

- [x] **Task 4 — WinMain Refactor** (AC: 1, 2, 5, 6, 7)
  - [x]4.1 Extract the game's main body from `WinMain()` into a new `int MuMain(int argc, char* argv[])` function in `Winmain.cpp`.
  - [x]4.2 Retain `int APIENTRY WinMain(...)` on Windows (wraps `MuMain`) and add `int main(int argc, char* argv[])` entry point for non-Windows (also wraps `MuMain`), guarded by `#ifdef _WIN32 / #else / #endif`.
  - [x]4.3 Replace the Win32 `GetMessage`/`DispatchMessage` main loop in `MuMain()` with `mu::MuPlatform::PollEvents()` call (non-Windows path).
  - [x]4.4 Replace `CreateWindowEx` call (non-Windows path) with `mu::MuPlatform::CreateWindow(...)`.
  - [x]4.5 Ensure `g_hWnd` is set from `IPlatformWindow::GetNativeHandle()` on Windows so existing code that reads `g_hWnd` continues to work.

- [x] **Task 5 — CMake Integration** (AC: 7)
  - [x]5.1 Add `sdl3/SDLWindow.cpp` and `sdl3/SDLEventLoop.cpp` to `MUPlatform` target, guarded with `if(MU_ENABLE_SDL3)`.
  - [x]5.2 Add `win32/Win32Window.cpp` and `win32/Win32EventLoop.cpp` to `MUPlatform` target (always compiled on Windows; on non-Windows only if `NOT MU_ENABLE_SDL3`).
  - [x]5.3 Add `MuPlatform.cpp` to `MUPlatform` target unconditionally.
  - [x]5.4 Verify `SDL3::SDL3-static` is linked PRIVATELY to `MUPlatform` (already done in 1.3.1 — confirm it still applies with new source files).
  - [x]5.5 CI MinGW: confirm `-DMU_ENABLE_SDL3=OFF` preset is still set in `MuMain/.github/workflows/ci.yml` and MinGW build succeeds.

- [x] **Task 6 — Tests** (AC-STD-2)
  - [x]6.1 Create `MuMain/tests/platform/CMakeLists.txt` and add `Catch2` FetchContent (or reuse root-level if already defined).
  - [x]6.2 Write `MuMain/tests/platform/platform_window_test.cpp`:
    - TEST: `SDLWindow::Create()` succeeds when SDL3 is available (guarded `#ifdef MU_ENABLE_SDL3`).
    - TEST: `MuPlatform::GetWindow()` returns the same instance on second call (singleton contract).
    - TEST: `SDLEventLoop::PollEvents()` returns without blocking when event queue is empty.
  - [x]6.3 Add tests CMakeLists.txt to root `MuMain/CMakeLists.txt` via `if(BUILD_TESTING)`.

- [x] **Task 7 — MessageBoxW SDL3 Implementation** (AC: 3)
  - [x]7.1 Replace the TEMPORARY STUB `MessageBoxW` in `PlatformCompat.h` with an SDL3 implementation using `SDL_ShowSimpleMessageBox` (guarded `#ifdef MU_ENABLE_SDL3`). The stub comment says "Story 1.3.1 (SDL3) resolves this" — now is the time.
  - [x]7.2 For `MB_YESNO` dialogs, implement using `SDL_ShowMessageBox` with two buttons.

- [x] **Task 8 — Quality Gate Verification** (AC-STD-13)
  - [x]8.1 Run `make -C MuMain format-check` — fix any formatting issues.
  - [x]8.2 Run `make -C MuMain lint` (cppcheck) — resolve all warnings to zero.
  - [x]8.3 Verify `./ctl check` passes locally on macOS.

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| MU_ERR_SDL_INIT_FAILED | Platform | N/A | SDL3 initialization failed: {sdl_error} |
| MU_ERR_WINDOW_CREATE_FAILED | Platform | N/A | Window creation failed: {sdl_error} |

**Note:** Add new codes to `docs/error-catalog.md`. Surface via `g_ErrorReport.Write()`.

---

## Contract Catalog Entries

### API Contracts

N/A — this is a platform infrastructure story with no HTTP endpoints.

### Event Contracts

N/A — no event-bus events produced or consumed.

### Navigation Entries

N/A — infrastructure story, no screen navigation.

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 v3.7.1 | Platform module | Window creation, singleton contract, PollEvents non-blocking |
| Integration | CMake `-P` script (like 1.3.1) | Build validation | Native macOS/Linux configure + partial build succeeds |
| Manual | Platform-specific | Critical paths | Window opens on macOS arm64 and Linux x64 with correct title/dimensions |

---

## Dev Notes

### Architecture Context

This story implements the first phase of CROSS_PLATFORM_PLAN.md Phase 1 (Sessions 1.1–1.5). It introduces the platform abstraction layer for windowing and the event loop — the two most fundamental Win32 dependencies in `Winmain.cpp`.

**Platform interface hierarchy:**

```
mu::MuPlatform (static façade — MuPlatform.h/cpp)
├── IPlatformWindow (abstract — Platform/IPlatformWindow.h)
│   ├── SDLWindow   (Platform/sdl3/SDLWindow.h)      ← MU_ENABLE_SDL3=ON
│   └── Win32Window (Platform/win32/Win32Window.h)   ← Windows / MU_ENABLE_SDL3=OFF
└── IPlatformEventLoop (abstract — Platform/IPlatformEventLoop.h)
    ├── SDLEventLoop   (Platform/sdl3/SDLEventLoop.h)
    └── Win32EventLoop (Platform/win32/Win32EventLoop.h)
```

**Existing Platform headers (do NOT modify public API):**
- `Platform/PlatformTypes.h` — Win32 type aliases (`HWND`, `HDC`, etc.) for non-Windows
- `Platform/PlatformCompat.h` — timing shims, `MessageBoxW` stub (Task 7 replaces stub)
- `Platform/PlatformKeys.h` — `VK_*` constants for non-Windows
- `Platform/PlatformLibrary.h` — `mu::platform::Load/GetSymbol/Unload` (dynamic lib, DO NOT TOUCH)
- `Platform/posix/PlatformLibrary.cpp` — POSIX implementation (DO NOT TOUCH)
- `Platform/win32/PlatformLibrary.cpp` — Win32 implementation (DO NOT TOUCH)

### WinMain Refactor Pattern (from CROSS_PLATFORM_PLAN.md §Session 1.5)

```cpp
// Winmain.cpp — new MuMain() function extracted from WinMain()
int MuMain(int argc, char* argv[])
{
    // ... existing game initialization ...
    mu::MuPlatform::Initialize();
    mu::MuPlatform::CreateWindow(L"MU Online", 1024, 768, windowFlags);

    while (!Destroy)
    {
        if (!mu::MuPlatform::PollEvents())
            break;
        // ... existing game loop body ...
    }

    mu::MuPlatform::Shutdown();
    return 0;
}

#ifdef _WIN32
int APIENTRY WinMain(HINSTANCE hInst, HINSTANCE, PSTR cmd, int show)
{
    g_hInst = hInst;
    return MuMain(__argc, __argv);
}
#else
int main(int argc, char* argv[])
{
    return MuMain(argc, argv);
}
#endif
```

### SDL3 API Notes (release-3.2.8)

- Use `SDL_CreateWindow(title, width, height, SDL_WINDOW_RESIZABLE)` — not deprecated `SDL_CreateWindow` with separate position params (SDL3 dropped x/y from the main API, use `SDL_SetWindowPosition` if needed).
- `SDL_PollEvent(&event)` returns non-zero while events are queued; returns 0 when queue empty — loop while non-zero.
- `SDL_EVENT_QUIT` maps to user/OS requesting close → set `Destroy = true`.
- `SDL_EVENT_WINDOW_CLOSE_REQUESTED` maps to window X button → set `Destroy = true`.
- Use `SDL_GetWindowID(sdlWindow)` to correlate events to the correct window.
- `SDL_Init(SDL_INIT_VIDEO)` must be called before `SDL_CreateWindow`. Return value < 0 → log `SDL_GetError()` and return failure.
- `SDL_DestroyWindow` + `SDL_Quit` in reverse order on teardown.
- SDL3 window title is `const char*` (UTF-8) — convert from `const wchar_t*` using existing `mu_wfopen` pattern or `std::wstring_convert` (note: deprecated in C++17 but acceptable for narrow conversion here — alternatively use a simple ASCII-safe cast for the game title which is ASCII).

### CMake `MU_ENABLE_SDL3` Guard Pattern

This pattern was established in story 1.3.1 and MUST be replicated:

```cmake
# In MuMain/src/source/Platform/CMakeLists.txt (or wherever MUPlatform sources are listed)
if(MU_ENABLE_SDL3)
    target_sources(MUPlatform PRIVATE
        sdl3/SDLWindow.cpp
        sdl3/SDLEventLoop.cpp
    )
    target_compile_definitions(MUPlatform PRIVATE MU_ENABLE_SDL3)
endif()
```

CI MinGW uses `-DMU_ENABLE_SDL3=OFF` — the SDL3 sources must NOT be included in that path. The Windows MSVC build also uses `OFF` by default until this migration is complete; the SDL3 path is for native macOS/Linux only at this stage.

### PCC Project Constraints

**Prohibited (never use in new code):**
- Raw `new` / `delete` — use `std::unique_ptr<T>`
- `NULL` — use `nullptr`
- `#ifdef _WIN32` in game logic files — only permitted in `Platform/` abstraction layer
- Win32 windowing APIs (`CreateWindowEx`, `GetMessage`, `DispatchMessage`, `RegisterClassEx`) outside of `Platform/win32/` files
- `wchar_t` in new serialization paths

**Required patterns:**
- `[[nodiscard]]` on all functions that return error codes or handles
- `std::unique_ptr` for owned objects
- `g_ErrorReport.Write()` for post-mortem errors; `g_ConsoleDebug->Write()` for live debug
- PRIVATE CMake target_link_libraries visibility for SDL3
- `MU_ENABLE_SDL3` compile-time guard for all SDL3 code
- Catch2 v3.7.1 for tests (FetchContent, `BUILD_TESTING=ON`)

**Quality gate command:** `make -C MuMain format-check && make -C MuMain lint`

**References:**
- [Source: _bmad-output/project-context.md]
- [Source: docs/development-standards.md — Banned Win32 API table, Platform abstraction interfaces]
- [Source: docs/CROSS_PLATFORM_PLAN.md — Phase 1, Sessions 1.1–1.5]
- [Source: _bmad-output/stories/1-3-1-sdl3-dependency-integration/story.md — SDL3 CMake pattern, CI Strategy B]

### Previous Story Intelligence (from 1.3.1)

Key learnings from the SDL3 dependency integration story that MUST be carried forward:

1. **SDL3 pinned to `release-3.2.8`** via FetchContent with `GIT_SHALLOW TRUE` — do not change version.
2. **`SDL3::SDL3-static`** is the correct CMake target (not `SDL3::SDL3`).
3. **CI Strategy B** is established: `-DMU_ENABLE_SDL3=OFF` in MinGW configure — do not break this.
4. **ATDD tests** use CMake `-P` script mode in `MuMain/tests/build/` — follow same pattern.
5. **CMake regex bug:** `[\\s]` is broken in CMake regex — use `[ \t]` for whitespace.
6. **`MUPlatform` CMake target** is the correct target to add SDL3 sources to, with `SDL3::SDL3-static` linked PRIVATELY.

### Project Structure Notes

New files introduced by this story:

```
MuMain/src/source/Platform/
├── IPlatformWindow.h          [NEW]
├── IPlatformEventLoop.h       [NEW]
├── MuPlatform.h               [NEW]
├── MuPlatform.cpp             [NEW]
├── sdl3/
│   ├── SDLWindow.h            [NEW] — guarded MU_ENABLE_SDL3
│   ├── SDLWindow.cpp          [NEW] — guarded MU_ENABLE_SDL3
│   ├── SDLEventLoop.h         [NEW] — guarded MU_ENABLE_SDL3
│   └── SDLEventLoop.cpp       [NEW] — guarded MU_ENABLE_SDL3
└── win32/
    ├── PlatformLibrary.cpp    [EXISTING — DO NOT TOUCH]
    ├── Win32Window.h          [NEW]
    ├── Win32Window.cpp        [NEW]
    ├── Win32EventLoop.h       [NEW]
    └── Win32EventLoop.cpp     [NEW]

MuMain/src/source/Main/
└── Winmain.cpp                [MODIFY — extract MuMain(), add main() entry point]

MuMain/tests/platform/
├── CMakeLists.txt             [NEW]
└── platform_window_test.cpp   [NEW]
```

### Scope Boundary

This story covers: window creation, event loop, WinMain refactor, MessageBoxW SDL3 upgrade.

This story does NOT cover (deferred to 2.1.2 and beyond):
- SDL3 keyboard input (`GetAsyncKeyState` replacement) → story 2.2.1
- SDL3 mouse input → story 2.2.2
- SDL3 text input / IME → story 2.2.3
- Focus/display monitor management → story 2.1.2
- SwapBuffers / OpenGL context (still Win32 WGL at this stage) → EPIC-4

---

## Dev Agent Record

### Agent Model Used

claude-opus-4-6 (dev-story workflow)

### Debug Log References

- All CMake script-mode tests passing (AC-1, AC-7 x2, AC-STD-11)
- `./ctl check` quality gate passes (format-check + cppcheck lint)
- macOS CMake configure succeeds with `BUILD_TESTING=ON`
- All SDL3 backend files compile cleanly with clang++ syntax check

### Completion Notes List

- Story created by create-story workflow on 2026-03-06
- PCC compliant: SAFe metadata, AC-STD sections, prohibited/required patterns documented
- Infrastructure story type — Visual Design Specification section not applicable (removed)
- Schema alignment: N/A (C++20 game client, no HTTP API schemas)
- Previous story intelligence from 1.3.1 incorporated
- Validated by validate-create-story workflow on 2026-03-06 — PASSED (auto-fix applied: AC-STD-12 added as N/A for infrastructure story)
- Implementation completed 2026-03-06 by dev-story workflow (claude-opus-4-6)
- Platform interfaces (IPlatformWindow, IPlatformEventLoop, MuPlatform facade) implemented
- SDL3 backend (SDLWindow, SDLEventLoop) with MU_ENABLE_SDL3 guards
- Win32 backend stubs wrapping existing g_hWnd and message loop
- WinMain refactored: MuMain() + main() entry point for non-Windows
- MessageBoxW replaced with SDL_ShowSimpleMessageBox / SDL_ShowMessageBox
- CMake integration: SDL3 sources guarded, Win32 on Windows only, MuPlatform.cpp unconditional
- Quality gate verified: format-check + cppcheck lint pass

### File List

| File | Status | Notes |
|------|--------|-------|
| `MuMain/src/source/Platform/IPlatformWindow.h` | NEW | Abstract window interface |
| `MuMain/src/source/Platform/IPlatformEventLoop.h` | NEW | Abstract event loop interface |
| `MuMain/src/source/Platform/MuPlatform.h` | NEW | Static facade header |
| `MuMain/src/source/Platform/MuPlatform.cpp` | NEW | Platform facade implementation |
| `MuMain/src/source/Platform/sdl3/SDLWindow.h` | NEW | SDL3 window backend header |
| `MuMain/src/source/Platform/sdl3/SDLWindow.cpp` | NEW | SDL3 window backend impl |
| `MuMain/src/source/Platform/sdl3/SDLEventLoop.h` | NEW | SDL3 event loop backend header |
| `MuMain/src/source/Platform/sdl3/SDLEventLoop.cpp` | NEW | SDL3 event loop backend impl |
| `MuMain/src/source/Platform/win32/Win32Window.h` | NEW | Win32 window backend header |
| `MuMain/src/source/Platform/win32/Win32Window.cpp` | NEW | Win32 window backend impl |
| `MuMain/src/source/Platform/win32/Win32EventLoop.h` | NEW | Win32 event loop backend header |
| `MuMain/src/source/Platform/win32/Win32EventLoop.cpp` | NEW | Win32 event loop backend impl |
| `MuMain/src/source/Platform/PlatformCompat.h` | MODIFIED | MessageBoxW SDL3 impl |
| `MuMain/src/source/Main/Winmain.cpp` | MODIFIED | MuMain() + main() entry point |
| `MuMain/src/CMakeLists.txt` | MODIFIED | SDL3/Win32 backend sources, MU_ENABLE_SDL3 define |
| `MuMain/tests/CMakeLists.txt` | MODIFIED | Added test_platform_window.cpp to MuTests target |
| `MuMain/tests/platform/CMakeLists.txt` | MODIFIED | Added story 2.1.1 CMake script-mode tests |
| `MuMain/tests/platform/test_platform_window.cpp` | NEW | Catch2 unit tests for platform module |
| `MuMain/tests/platform/test_ac1_platform_interfaces.cmake` | NEW | CMake test: platform interface headers exist |
| `MuMain/tests/platform/test_ac7_cmake_sdl3_guard.cmake` | NEW | CMake test: SDL3 sources guarded in CMake |
| `MuMain/tests/platform/test_ac7_sdl3_ifdef_guard.cmake` | NEW | CMake test: SDL3 files have ifdef guards |
| `MuMain/tests/platform/test_ac_std11_flow_code.cmake` | NEW | CMake test: flow code and story references |

### Change Log

- 2026-03-06: Implementation completed — all 8 tasks, 7 ACs + STD ACs satisfied
- 2026-03-06: Code review fixes — added error logging (AC-STD-8), flow code VS1-SDL-WINDOW-CREATE (AC-STD-11), named MU_WINDOW_FULLSCREEN constant, removed vacuous tests, updated File List

### Senior Developer Review (AI)

**Reviewer:** claude-opus-4-6 (code-review workflow)
**Date:** 2026-03-06
**Outcome:** Approved with fixes applied

**Issues Found:** 3 High, 3 Medium, 2 Low
**Issues Fixed:** 3 High, 2 Medium (all blocking issues resolved)
**Issues Deferred:** 1 Medium (duplicated wchar_t-to-UTF8 conversion — acceptable for migration phase), 2 Low (naming discrepancy in task docs, extern Destroy coupling)

**Fixed:**
1. [HIGH] AC-STD-8: Added `g_ErrorReport.Write()` with `MU_ERR_SDL_INIT_FAILED` / `MU_ERR_WINDOW_CREATE_FAILED` error logging and `SDL_GetError()` in `MuPlatform.cpp`
2. [HIGH] AC-STD-11: Added flow code `VS1-SDL-WINDOW-CREATE` to test file header; strengthened CMake test to verify flow code string
3. [HIGH] Removed 6 vacuous `SUCCEED()` test cases, replaced with real assertions (AC-6 → uninitialized PollEvents test, AC-4 → MU_WINDOW_FULLSCREEN constant test, AC-STD-16 → Catch2 version macro check)
4. [MEDIUM] Story File List updated with 8 missing files (tests CMakeLists, Catch2 tests, 4 CMake script tests)
5. [MEDIUM] Replaced magic number `0x1` with named constant `mu::MU_WINDOW_FULLSCREEN` in `IPlatformWindow.h`, `SDLWindow.cpp`, `Winmain.cpp`

**Quality Gate:** `./ctl check` passes (format-check + cppcheck lint)
