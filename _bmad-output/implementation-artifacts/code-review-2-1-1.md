# Code Review — Story 2-1-1
# SDL3 Window Creation & Event Loop

**Story Key:** 2-1-1
**Date:** 2026-03-06
**Story File:** _bmad-output/stories/2-1-1-sdl3-window-event-loop/story.md
**Story Type:** infrastructure

---

## Pipeline Status

| Step | Status | Notes |
|------|--------|-------|
| 1. Quality Gate | PASSED | format-check + lint green, sonar N/A |
| 2. Code Review Analysis | COMPLETED | 4 HIGH, 3 MEDIUM, 2 LOW — 4 auto-fixed |
| 3. Finalize | pending | |

---

## Quality Gate Progress

| Phase | Status | Iterations | Issues Fixed |
|-------|--------|------------|--------------|
| Backend Local (mumain) | PASSED | 1 | 0 |
| Backend SonarCloud (mumain) | SKIPPED (not configured — no sonar_key in cpp-cmake profile) | - | - |
| Frontend Local | SKIPPED (no frontend components) | - | - |
| Frontend SonarCloud | SKIPPED (no frontend components) | - | - |

---

## Affected Components

| Component | Type | Path | Tags |
|-----------|------|------|------|
| mumain | cpp-cmake | ./MuMain | backend |
| project-docs | documentation | ./_bmad-output | documentation |

**Tech Profile:** cpp-cmake
**Quality Gate Command:** `make -C MuMain format-check && make -C MuMain lint`
**SonarCloud:** Not configured (no sonar_key on mumain component)
**Build/Test:** Skipped (per quality_gates.skip_checks: [build, test] — macOS cannot compile Win32/DirectX)

---

## Fix Iterations

### Iteration 1 (2026-03-06, code-review-analysis)

| # | Finding | File | Fix Applied |
|---|---------|------|-------------|
| 1 | CreateWindow fallthrough returns true without backend | MuPlatform.cpp:53-85 | Changed `#else #ifdef _WIN32` to `#elif defined(_WIN32)` with `#else return false` fallthrough |
| 2 | Missing null/bounds validation in CreateWindow | MuPlatform.cpp:59-63 | Added `title == nullptr`, `width <= 0`, `height <= 0` validation |
| 3 | CMake compiles both Win32 and SDL3 backends on Windows | src/CMakeLists.txt:293-310 | Made Win32 window/event backends mutually exclusive with SDL3 via nested `if(MU_ENABLE_SDL3)` |
| 4 | MessageBoxW UTF-8 conversion missing 4-byte sequences | PlatformCompat.h:48-92 | Extracted `mu_wchar_to_utf8()` helper with full 4-byte support and surrogate pair skipping, consistent with `mu_wfopen` |

**Quality gate re-run:** PASSED (688/688 files, 0 violations)

---

## Step 1: Quality Gate — PASSED

### Backend: mumain (cpp-cmake, ./MuMain)

| Check | Command | Status | Notes |
|-------|---------|--------|-------|
| format-check | `make -C MuMain format-check` | PASSED | Exit 0, no formatting violations |
| lint (cppcheck) | `make -C MuMain lint` | PASSED | Exit 0, 688/688 files checked, 0 violations |
| build | skipped | SKIPPED | Per quality_gates.skip_checks: [build] — macOS cannot compile Win32/DirectX |
| test | skipped | SKIPPED | Per quality_gates.skip_checks: [test] — no test runner on macOS |
| coverage | n/a | SKIPPED | `echo 'No coverage configured yet'` |
| SonarCloud | not configured | SKIPPED | No sonar_key in cpp-cmake profile / mumain component |

### AC Compliance

Story type: `infrastructure` — AC compliance check skipped per workflow rules.

### quality_gate_status: PASSED

---

## Step 2: Code Review Analysis

**Reviewer:** claude-opus-4-6 (code-review-analysis workflow)
**Date:** 2026-03-06
**Mode:** Adversarial senior developer review (unattended automation)

### ATDD Completeness

| Metric | Value |
|--------|-------|
| Total checklist items | 42 |
| Checked items | 42 |
| Completion | **100%** |
| Status | **PASS** (threshold: 80%) |

### Acceptance Criteria Verification

| AC | Verified | Method | Notes |
|----|----------|--------|-------|
| AC-1 | YES | Code inspection + test | `MuPlatform::CreateWindow` delegates to `SDLWindow::Create` (SDL3) or `Win32Window::Create` (Win32). Test in test_platform_window.cpp:15-27. CMake test verifies interface headers exist. |
| AC-2 | YES | Code inspection + test | `MuPlatform::PollEvents` delegates to `SDLEventLoop::PollEvents` which calls `SDL_PollEvent`. Test in test_platform_window.cpp:33-47. |
| AC-3 | YES | Code inspection | SDLEventLoop.cpp handles SDL_EVENT_WINDOW_RESIZED, FOCUS_GAINED, FOCUS_LOST, MINIMIZED, RESTORED as no-ops. No crash path. |
| AC-4 | YES | Code inspection + test | `SDLWindow::Create` accepts title, width, height, flags. `MU_WINDOW_FULLSCREEN` constant defined. Test in test_platform_window.cpp:75-92. Winmain.cpp:1398 passes `g_bUseFullscreenMode` flag. |
| AC-5 | YES | Code inspection + test | `MuPlatform::GetWindow()` returns `s_pWindow.get()` (singleton). Test verifies `window1 == window2` and nullptr before CreateWindow. |
| AC-6 | YES | Code inspection | SDLEventLoop.cpp:20-21 sets `Destroy = true` on SDL_EVENT_QUIT. Lines 24-25 same for SDL_EVENT_WINDOW_CLOSE_REQUESTED. Winmain.cpp:1405 `while (!Destroy)` loop exits. |
| AC-7 | YES | Code inspection + CMake tests | All SDL3 files guarded with `#ifdef MU_ENABLE_SDL3`. CMake uses `if(MU_ENABLE_SDL3)` for sources and compile definitions. Two CMake script-mode tests verify both guards. |
| AC-STD-1 | YES | Code inspection | PascalCase functions, `m_` prefix, `std::unique_ptr`, `nullptr`, `#pragma once`, Allman braces, 4-space indent. |
| AC-STD-2 | YES | File inspection | Catch2 v3.7.1 tests in `test_platform_window.cpp` with 7 TEST_CASEs covering window creation, singleton, PollEvents, lifecycle, fullscreen flag, Catch2 version. |
| AC-STD-8 | YES | Code inspection | `MU_ERR_SDL_INIT_FAILED` and `MU_ERR_WINDOW_CREATE_FAILED` in `MuPlatform.cpp:30,64` via `g_ErrorReport.Write()`. |
| AC-STD-11 | YES | Code + test inspection | Flow code `VS1-SDL-WINDOW-CREATE` in test_platform_window.cpp:2. CMake test verifies. |
| AC-STD-13 | YES | Live verification | `./ctl check` passes: 688/688 files, 0 violations. |
| AC-STD-16 | YES | Code + test | Catch2 v3.7.1 via FetchContent in tests/CMakeLists.txt:3-7. Test verifies CATCH_VERSION_MAJOR == 3. |

### Task Completion Verification

| Task | Status | Verified | Notes |
|------|--------|----------|-------|
| Task 1 — Platform Interfaces | [x] | YES | IPlatformWindow.h, IPlatformEventLoop.h, MuPlatform.h/cpp all exist with correct declarations |
| Task 2 — SDL3 Backend | [x] | YES | SDLWindow.h/cpp, SDLEventLoop.h/cpp in Platform/sdl3/, all guarded with MU_ENABLE_SDL3 |
| Task 3 — Win32 Backend Stub | [x] | YES | Win32Window.h/cpp, Win32EventLoop.h/cpp in Platform/win32/, guarded with _WIN32 |
| Task 4 — WinMain Refactor | [x] | YES | MuMain() at Winmain.cpp:1391, main() at :1420, uses MuPlatform for window/events |
| Task 5 — CMake Integration | [x] | YES | SDL3 sources guarded, Win32 on WIN32, MuPlatform.cpp unconditional, SDL3::SDL3-static PRIVATE |
| Task 6 — Tests | [x] | YES | test_platform_window.cpp + 4 CMake script-mode tests registered in platform/CMakeLists.txt |
| Task 7 — MessageBoxW SDL3 | [x] | YES | PlatformCompat.h:45-116 SDL3 implementation with MB_OK and MB_YESNO support |
| Task 8 — Quality Gate | [x] | YES | `./ctl check` passes live on macOS |

### Findings

#### Finding 1: CreateWindow fallthrough returns true without creating anything

| Attribute | Value |
|-----------|-------|
| **Severity** | HIGH |
| **File** | MuPlatform.cpp:53-81 |
| **Category** | Logic defect |
| **Status** | **FIX** |

**Description:** When compiled without `MU_ENABLE_SDL3` and without `_WIN32` (e.g., plain Linux build with `-DMU_ENABLE_SDL3=OFF`), `MuPlatform::CreateWindow()` falls through both `#ifdef` blocks and returns `true` on line 80 without creating any window or event loop. Subsequent `GetWindow()` returns nullptr, `PollEvents()` returns false immediately.

**Impact:** Silent success with no window. Caller has no way to detect the misconfiguration.

**Fix:** Return false at the fallthrough to signal that no backend is available.

---

#### Finding 2: Missing null/bounds validation in MuPlatform::CreateWindow

| Attribute | Value |
|-----------|-------|
| **Severity** | HIGH |
| **File** | MuPlatform.cpp:53 |
| **Category** | Input validation |
| **Status** | **FIX** |

**Description:** `MuPlatform::CreateWindow(title, width, height, flags)` does not validate `title != nullptr` or `width > 0` / `height > 0`. A nullptr title is passed through to `SDL_CreateWindow` which may crash. Non-positive dimensions produce undefined behavior.

**Fix:** Add null/bounds check at the top of CreateWindow.

---

#### Finding 3: CMake compiles both Win32 and SDL3 backends simultaneously on Windows

| Attribute | Value |
|-----------|-------|
| **Severity** | HIGH |
| **File** | MuMain/src/CMakeLists.txt:293-305 |
| **Category** | Build system defect |
| **Status** | **FIX** |

**Description:** When `WIN32=ON` and `MU_ENABLE_SDL3=ON`, lines 293-296 add Win32 backend files AND lines 300-305 add SDL3 backend files. Both compile into `MUPlatform`. Runtime selection works correctly via `#ifdef MU_ENABLE_SDL3` in MuPlatform.cpp, but Win32 backend becomes dead code, bloating binary and increasing compile time.

**Fix:** Make SDL3 and Win32 backends mutually exclusive — skip Win32 window/event files when SDL3 is enabled.

---

#### Finding 4: MessageBoxW UTF-8 conversion missing 4-byte sequence support

| Attribute | Value |
|-----------|-------|
| **Severity** | HIGH |
| **File** | PlatformCompat.h:48-87 |
| **Category** | Data loss / Inconsistency |
| **Status** | **FIX** |

**Description:** The wchar_t-to-UTF8 conversion in `MessageBoxW` handles only up to 3-byte UTF-8 sequences (BMP, U+0000–U+FFFF). On macOS/Linux where `wchar_t` is 32-bit, codepoints above U+FFFF (emoji, CJK Extension B, etc.) are single wchar_t values > 0xFFFF that need 4-byte UTF-8 encoding. These are currently encoded incorrectly as 3-byte sequences, producing invalid UTF-8.

**Inconsistency:** The `mu_wfopen` function at PlatformCompat.h:139-189 correctly handles 4-byte sequences (lines 169-176) including surrogate pair skipping. The MessageBoxW conversion duplicates the logic but with this gap.

**Fix:** Add 4-byte handling to MessageBoxW's conversion loops, consistent with mu_wfopen.

---

#### Finding 5: Non-atomic `extern bool Destroy` shared between event loop and main loop

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | SDLEventLoop.cpp:7, Winmain.cpp:1405 |
| **Category** | Thread safety |
| **Status** | DEFERRED |

**Description:** `Destroy` is a plain `bool` modified by `SDLEventLoop::PollEvents()` and read by `while (!Destroy)` in `MuMain()`. Per C++ standard, unsynchronized access to a non-atomic shared variable is undefined behavior. Currently safe because both run on the main thread, but the design doesn't enforce single-thread access.

**Deferral rationale:** Previous code review (2026-03-06) documented this as single-threaded by design. Converting to `std::atomic<bool>` would require modifying `Destroy` declaration which is used throughout the legacy codebase (693+ files). This is out of scope for story 2-1-1 and should be addressed in a dedicated tech debt story.

---

#### Finding 6: Static globals in MuPlatform.cpp lack thread safety documentation

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | MuPlatform.cpp:21-23 |
| **Category** | Thread safety |
| **Status** | DEFERRED |

**Description:** `s_pWindow`, `s_pEventLoop`, and `s_bInitialized` are static globals with no synchronization. If future code calls MuPlatform methods from multiple threads, data races would occur. Same single-threaded design assumption as Finding 5.

**Deferral rationale:** Same as Finding 5 — single-threaded by design, documented in previous code review.

---

#### Finding 7: Win32Window::Create ignores all parameters

| Attribute | Value |
|-----------|-------|
| **Severity** | MEDIUM |
| **File** | Win32Window.cpp:11 |
| **Category** | Contract violation (by design) |
| **Status** | ACCEPTED |

**Description:** `Win32Window::Create(title, width, height, flags)` ignores all parameters and returns `g_hWnd != nullptr`. This is documented in the story: "Win32 window creation is still handled by WinMain() directly." The stub provides interface compatibility while the actual window creation remains in `WinMain()`. This is intentional for the migration phase but violates the `IPlatformWindow::Create` contract semantically.

**Acceptance rationale:** Story 2-1-1 explicitly documents this as the design for the Win32 compatibility path. Future stories will migrate Win32 window creation into the platform abstraction.

---

#### Finding 8: SDLWindow::Create returns false on re-creation without error reporting

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | SDLWindow.cpp:17-19 |
| **Category** | Error reporting |
| **Status** | ACCEPTED |

**Description:** If `Create()` is called on an SDLWindow that already has a window (`m_pWindow != nullptr`), it silently returns false. No error logging via `g_ErrorReport.Write()` to help diagnose the issue.

**Acceptance rationale:** MuPlatform controls access to SDLWindow and ensures single creation. The guard is defensive, not a normal flow.

---

#### Finding 9: Redundant null check in PlatformCompat.h loop condition

| Attribute | Value |
|-----------|-------|
| **Severity** | LOW |
| **File** | PlatformCompat.h:52, 71 |
| **Category** | Code quality |
| **Status** | ACCEPTED |

**Description:** `for (const wchar_t* p = text; p && *p; ++p)` checks `p != nullptr` on every iteration, but after the first check, `p` is only modified by `++p` and cannot become null. Minor inefficiency.

**Acceptance rationale:** Defensive coding style, negligible performance impact.

### Summary

| Severity | Total | Fixed | Deferred | Accepted |
|----------|-------|-------|----------|----------|
| HIGH | 4 | 4 | 0 | 0 |
| MEDIUM | 3 | 0 | 2 | 1 |
| LOW | 2 | 0 | 0 | 2 |
| **Total** | **9** | **4** | **2** | **3** |
