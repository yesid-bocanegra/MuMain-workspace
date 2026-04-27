# Story 7-9-14: Delete Vestigial Win32 Platform Backend

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-14 |
| **Title** | Delete Vestigial Win32 Platform Backend |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-0 (Platform / Enabler) |
| **Flow Type** | Refactor |
| **Flow Code** | VS0-PLAT-WIN32-BACKEND-REMOVAL |
| **Story Points** | 5 |
| **Dependencies** | 7-9-3 (unify-entry-point, done), 7-9-15..7-9-18 (cross-platform replacements for remaining Win32-stub callers) |
| **Status** | ready-for-dev |

---

## User Story

**As a** maintainer of the cross-platform game client,
**I want** the legacy Win32 platform backend (`Platform/win32/*`) and its supporting `#ifdef _WIN32` includes deleted entirely,
**So that** Windows builds go through the same SDL3 path as macOS and Linux — one implementation, no vestigial Win32 code surface to maintain or test.

---

## Background

### Current State

`MuPlatform.cpp:79-98` selects between two backends:

```cpp
#ifdef MU_ENABLE_SDL3
    auto window = std::make_unique<SDLWindow>();
    // ...
    s_pEventLoop = std::make_unique<SDLEventLoop>();
#elif defined(_WIN32)
    auto window = std::make_unique<Win32Window>();
    s_pEventLoop = std::make_unique<Win32EventLoop>();
#else
    return false;
#endif
```

The `Win32Window` and `Win32EventLoop` backend lives in `Platform/win32/` (5 files, 241 LOC, all wrapped in `#ifdef _WIN32`). It is **only reachable** when `MU_ENABLE_SDL3` is undefined — i.e., legacy Windows-only builds. The SDL3 backend works on Windows too (no nested `_WIN32` checks inside the SDL3 path).

Per the cross-platform mandate, every build configuration must use SDL3. The Win32 backend is therefore vestigial and must be removed.

### Files in scope

| File | LOC | Action |
|---|---|---|
| `src/source/Platform/win32/PlatformLibrary.cpp` | 84 | Delete |
| `src/source/Platform/win32/Win32EventLoop.cpp` | 35 | Delete |
| `src/source/Platform/win32/Win32EventLoop.h` | 21 | Delete |
| `src/source/Platform/win32/Win32Window.cpp` | 66 | Delete |
| `src/source/Platform/win32/Win32Window.h` | 35 | Delete |
| `src/source/Platform/win32/` directory | — | Delete |
| `src/source/Resources/Windows/resource.rc` | small | Delete (Windows resource compiler input — no SDL3 equivalent needed) |
| `src/source/Main/MuMain.cpp:33-35` | 3 | Delete `#ifdef _WIN32 #include "ThirdParty/regkey.h" #endif` |
| `src/source/ThirdParty/regkey.h` | small | Delete (zero callers; only `MuMain.cpp` includes it) |
| `src/source/Platform/MuPlatform.cpp:12-21` | 10 | Strip `#elif defined(_WIN32)` Win32 includes — keep SDL3 unconditional |
| `src/source/Platform/MuPlatform.cpp:79-98` | 20 | Strip `#elif defined(_WIN32)` and `#else return false;` branches — SDL3 path becomes unconditional |

### Build configuration

The build must define `MU_ENABLE_SDL3` on **all** target platforms (macOS, Linux, Windows). Verify via CMake / build presets that no preset still produces a Win32-backend binary.

---

## Functional Acceptance Criteria

- [ ] **AC-1: Backend files deleted.** `Platform/win32/` directory and all 5 files inside are removed. `src/source/Resources/Windows/resource.rc` removed. `src/source/ThirdParty/regkey.h` removed. `git rm` recorded in commit.
- [ ] **AC-2: MuPlatform.cpp unconditional.** `MuPlatform.cpp` contains no `#elif defined(_WIN32)` and no `#else` branch in `CreateWindow()`. The SDL3 backend path is the only path. Header includes contain only `sdl3/SDLWindow.h`, `sdl3/SDLEventLoop.h`, `<SDL3/SDL.h>`.
- [ ] **AC-3: MuMain.cpp regkey block deleted.** Lines 33-35 (`#ifdef _WIN32 #include "ThirdParty/regkey.h" #endif`) removed. No remaining reference to `regkey.h` in any source file.
- [ ] **AC-4: Build configuration.** All build presets (CMake `mumain-macos-debug`, `mumain-linux-debug`, `mumain-windows-debug`, equivalents for release) define `MU_ENABLE_SDL3=ON`. No preset produces a binary that would link against the deleted Win32 backend.
- [ ] **AC-5: Build passes on all platforms.** `cmake --build` succeeds on macOS, Linux, Windows. No undefined references to deleted symbols (`Win32Window::*`, `Win32EventLoop::*`, `RegKey<*>`).
- [ ] **AC-6: Smoke test.** Game launches on macOS, Linux, Windows. Reaches login screen. Logs in. Renders chat. No regression vs. pre-deletion behavior.
- [ ] **AC-7: `MuPlatform::CreateWindow` macro-collision guard.** Add `#undef CreateWindow` (and `#undef CreateWindowA` / `CreateWindowW` for safety) at the top of `Platform/MuPlatform.h`, after any potential `<windows.h>` include site. This is belt-and-suspenders against future translation units that pull in `<windows.h>` alongside `MuPlatform.h` — the existing `PlatformCompat.h:2016` comment ("CreateWindow macro NOT defined here") only protects the current PlatformCompat.h shim path. Sourced from PR-329 review #5.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance (naming, logging, PascalCase, `m_` prefix, `#pragma once`)
- [ ] **AC-STD-2:** Testing Requirements — smoke test on all three platforms (no new Catch2 unit tests; this is a deletion story)
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check` — format-check + cppcheck)
- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)

---

## Tasks / Subtasks

- [ ] Task 1: Verify dependency story status (AC: 1)
  - [ ] 1.1: Confirm 7-9-15..7-9-18 have landed (their fixes remove the cross-platform-but-broken callers that 7-9-14 would otherwise leave unresolved)
- [ ] Task 2: Delete Win32 backend files (AC: 1)
  - [ ] 2.1: `git rm src/source/Platform/win32/` (recursive)
  - [ ] 2.2: `git rm src/source/Resources/Windows/resource.rc`
  - [ ] 2.3: `git rm src/source/ThirdParty/regkey.h`
- [ ] Task 3: Strip MuPlatform.cpp Win32 paths (AC: 2)
  - [ ] 3.1: Delete `#elif defined(_WIN32)` includes block (lines 17-20)
  - [ ] 3.2: Delete `#elif defined(_WIN32)` Win32Window/Win32EventLoop branch in CreateWindow (lines 88-95)
  - [ ] 3.3: Delete `#else return false;` branch in CreateWindow (lines 96-97)
  - [ ] 3.4: Remove `#ifdef MU_ENABLE_SDL3` guard around the surviving SDL3 block — make unconditional
- [ ] Task 4: Strip MuMain.cpp regkey include (AC: 3)
  - [ ] 4.1: Delete lines 33-35
- [ ] Task 5: Update CMake build configuration (AC: 4)
  - [ ] 5.1: Verify `MU_ENABLE_SDL3=ON` in all platform presets
  - [ ] 5.2: Remove any CMake glob patterns that referenced `Platform/win32/*.cpp`
- [ ] Task 6: `MuPlatform::CreateWindow` macro-collision guard (AC: 7)
  - [ ] 6.1: Add `#undef CreateWindow`, `#undef CreateWindowA`, `#undef CreateWindowW` near the top of `Platform/MuPlatform.h`, in a small block clearly commented as a `<windows.h>`-collision guard
  - [ ] 6.2: Verify the build still passes — confirms the `#undef`s don't accidentally break a real caller of those macros (none expected since the project is migrating off Win32 directly, but check)
- [ ] Task 7: Build + smoke test (AC: 5, 6)
  - [ ] 7.1: Clean build on macOS, Linux, Windows
  - [ ] 7.2: Smoke test: launch → login → chat → logout on each platform
  - [ ] 7.3: `./ctl check` passes

---

## Dev Notes

### Risk

The biggest risk is that some currently-unguarded cross-platform code (e.g., `SendMessage(g_hWnd, WM_DESTROY)`, `ImmGetContext`, `SetTimer(g_hWnd, ...)`) calls Win32 stubs in `PlatformCompat.h` that depend on the Win32 backend's `g_hWnd` global. If 7-9-15..7-9-18 have NOT landed when this story is worked, those call sites will compile but silently no-op. This is why this story's dependency list explicitly blocks on 7-9-15..7-9-18.

### Out of scope

- The 5 `#ifdef MU_ENABLE_SDL3` blocks in `MuMain.cpp` — those are unified by 7-9-19.
- Stripping `#ifdef _WIN32` from non-Platform/win32 files — those are unified by 7-9-19.
- Crash-handler unification — POSIX signal handlers (`#ifndef _WIN32` in `MuPlatform.cpp:40-46`) are a legitimate platform-API difference, not vestigial. Stays as-is.
