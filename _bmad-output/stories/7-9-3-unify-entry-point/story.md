# Story 7.9.3: Unify Entry Point — Delete WinMain, Single main() for All Platforms

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.9 - macOS Game Loop & Win32 Render Path Migration |
| Story ID | 7.9.3 |
| Story Points | 8 |
| Priority | P1 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-RENDER-UNIFYENTRY |
| FRs Covered | Single entry point for all platforms — no divergent init paths, no `#ifdef _WIN32` blocks in Winmain.cpp |
| Prerequisites | 7-9-2-sdl3-2d-scene-sprite-render (in-progress) — all GL through IMuRenderer must land first |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Delete WinMain() + all Win32-only functions (WndProc, MainLoop, KillGLWindow); merge missing WinMain init into MuMain(); remove `#ifdef _WIN32` / `#ifndef _WIN32` guards from Winmain.cpp; single `main()` entry point |
| project-docs | documentation | Story artifacts |

---

## Background

`Winmain.cpp` (1721 lines) has two completely separate init paths:

| Region | Lines | Path | Platform |
|--------|-------|------|----------|
| 27–978 | 951 | Win32-only functions: `WndProc`, `MainLoop`, `KillGLWindow`, helpers | Windows only (`#ifdef _WIN32`) |
| 979–1441 | 462 | `WinMain()` — Win32 entry point: GameConfig, CreateWindowEx, OpenGL ctx, GLEW, Win32 message loop | Windows only |
| 1442–1721 | 279 | `MuMain()` + `main()` — SDL3 entry point: GameConfig, SDL window, SDL_gpu, SDL event loop | macOS/Linux only (`#ifndef _WIN32`) |

Every bug fixed this session was caused by this split:
- `g_strSelectedML` not set in MuMain → locale file paths broken
- `GameConfig::GetInstance().Load()` not called in MuMain → settings not loaded
- `CInput::Create()` not called in MuMain → screen dimensions 0 → SIGSEGV
- `g_fScreenRate_x/y` not set in MuMain → UI scaling wrong

The root problem: two init paths that must stay in sync manually. They never will.

### What WinMain Has That MuMain Still Needs

| Init step | WinMain line | MuMain status | Action |
|-----------|-------------|---------------|--------|
| Error report header (version, sysinfo) | 1002–1017 | Missing | Port to MuMain |
| Command line server override | 1024–1037 | Missing | Port to MuMain (use `argc`/`argv` not `GetCommandLine()`) |
| `g_fScreenRate_x/y` | 1077–1078 | Missing | Port to MuMain |
| Display mode enumeration | 1085–1131 | Not needed | SDL3 handles this |
| Win32 window creation | 1137–1172 | Not needed | SDL3 `CreateWindow` already in MuMain |
| OpenGL context setup | 1176–1241 | Not needed | SDL_gpu already in MuMain |
| GLEW init | ~1250 | Not needed | No GLEW on SDL3 |
| `ShowWindow`/`UpdateWindow` | ~1300 | Not needed | SDL3 handles this |
| `CInput::Create(g_hWnd)` | 1309 | Partial (SetScreenSize) | Already fixed |
| `SetTimer` / `CreateFont` / IME | ~1310–1400 | Not needed | SDL3 handles timers; font/IME future work |
| `MainLoop()` | 1416 | Not needed | SDL3 game loop in MuMain already |

### What Can Be Deleted

| Code | Lines | Reason |
|------|-------|--------|
| `WndProc()` | ~350 | Win32 message handler → SDL3 `PollEvents` |
| `MainLoop()` | ~70 | Win32 render loop → SDL3 game loop in MuMain |
| `KillGLWindow()` | ~30 | Win32/OpenGL teardown → SDL3 `Shutdown()` |
| `WinMain()` | ~462 | Entire function — replaced by MuMain |
| `#ifdef _WIN32` guard (lines 27–978) | 951 | All Win32-only helpers |
| `#ifndef _WIN32` guard (lines 1442, 1722) | 2 | No longer needed — MuMain is universal |

**Net change: ~950 lines deleted, ~30 lines added (missing init steps).**

> **Rule:** After this story, Winmain.cpp has ZERO `#ifdef _WIN32` blocks. One `main()`, one
> init sequence, one game loop. The Windows build uses SDL3 exactly like macOS and Linux.

---

## Story

**[VS-0] [Flow:E]**

**As a** developer maintaining the game client,
**I want** a single `main()` → `MuMain()` entry point on all platforms,
**so that** initialization bugs from divergent WinMain/MuMain paths can never happen again.

---

## Functional Acceptance Criteria

- [ ] **AC-1: Port remaining WinMain init to MuMain**
  These init steps from `WinMain()` are added to `MuMain()`:
  - Error report log header (version string, system info)
  - Command line server override parsing (via `argc`/`argv`, not `GetCommandLine()`)
  - `g_fScreenRate_x = (float)WindowWidth / 640; g_fScreenRate_y = (float)WindowHeight / 480;`
  Win32-only init (EnumDisplaySettings, ChangeDisplaySettings, CreateFont, SetTimer, IME,
  screensaver suppression) is NOT ported — SDL3 handles these or they're irrelevant.

- [ ] **AC-2: Delete WinMain and all Win32-only functions**
  These are removed from `Winmain.cpp`:
  - `WinMain()` (entire function)
  - `WndProc()` (Win32 message handler)
  - `MainLoop()` (Win32 render loop)
  - `KillGLWindow()` (Win32/OpenGL teardown)
  - All helper functions inside the `#ifdef _WIN32` block (lines 27–978)
  - The `#ifdef _WIN32` and `#ifndef _WIN32` guards themselves

- [ ] **AC-3: Single `main()` on all platforms**
  After deletion, `Winmain.cpp` contains:
  - Shared globals and includes (no `#ifdef _WIN32`)
  - `MuMain(int argc, char* argv[])` — the universal entry point
  - `int main(int argc, char* argv[]) { return MuMain(argc, argv); }`
  The Windows build compiles and links with `main()` as the entry point (SDL3 provides
  `SDL_main` → `main` remapping via `SDL_MAIN_HANDLED` or the SDL3 main header).

- [ ] **AC-4: Windows build passes with MuMain**
  The MinGW cross-compile CI build passes: `cmake --build --preset windows-x64-debug`.
  The Windows build uses `MuMain()` → SDL3 window → SDL_gpu renderer, same as macOS/Linux.

- [ ] **AC-5: Zero `#ifdef _WIN32` in Winmain.cpp**
  `grep -c '#ifdef _WIN32' src/source/Main/Winmain.cpp` returns 0.
  `grep -c '#ifndef _WIN32' src/source/Main/Winmain.cpp` returns 0.
  Platform-specific code lives ONLY in `Platform/PlatformCompat.h` and renderer backends.

- [ ] **AC-6: Quality gate passes**
  `./ctl check` exits 0 on macOS and Linux. MinGW cross-compile passes.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — clang-format clean; zero `#ifdef _WIN32` in Winmain.cpp.
- [ ] **AC-STD-2:** Testing Requirements — Catch2 test suite passes; no regressions.
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.

---

## Tasks / Subtasks

- [ ] **Task 1: Port missing WinMain init to MuMain** (AC-1)
  - [ ] 1.1: Add error report log header (version, system info) after CWD setup
  - [ ] 1.2: Add `argc`/`argv` server override parsing (replace `GetCommandLine()`)
  - [ ] 1.3: Add `g_fScreenRate_x/y` calculation after GameConfig window dimensions
  - [ ] 1.4: Verify all WinMain init steps are either in MuMain or explicitly not needed

- [ ] **Task 2: Verify Windows builds with MuMain** (AC-4)
  - [ ] 2.1: Ensure SDL3 main header is included for Windows `WinMain` → `main` remapping
  - [ ] 2.2: Verify MinGW cross-compile links with `main()` entry point
  - [ ] 2.3: Verify MSVC preset links with `main()` entry point (if testable)

- [ ] **Task 3: Delete WinMain and Win32-only code** (AC-2, AC-5)
  - [ ] 3.1: Remove entire `#ifdef _WIN32` block (lines 27–978): WndProc, MainLoop, KillGLWindow, helpers
  - [ ] 3.2: Remove `WinMain()` function (lines 979–1441)
  - [ ] 3.3: Remove `#ifndef _WIN32` / `#endif` guards around MuMain/main
  - [ ] 3.4: Remove `g_hWnd`, `g_hDC`, `g_hRC`, `g_hInst` globals (Win32 handles no longer needed)
  - [ ] 3.5: Audit all files that reference removed globals — replace with SDL3 equivalents or remove

- [ ] **Task 4: Quality gate** (AC-6)
  - [ ] 4.1: `./ctl check` — macOS
  - [ ] 4.2: `./ctl check` — Linux (if available)
  - [ ] 4.3: MinGW cross-compile — Windows
  - [ ] 4.4: Verify zero `#ifdef _WIN32` in Winmain.cpp

---

## Dev Notes

### SDL3 Main Entry Point on Windows

SDL3 provides `SDL_main.h` which remaps `main()` to `SDL_main()` on Windows, handling the
`WinMain` → `main` translation automatically. Include `<SDL3/SDL_main.h>` and define
`SDL_MAIN_HANDLED` if needed. The CMake target already links SDL3, so this should work
out of the box.

### Globals to Remove

These Win32 globals are only used by `WinMain`/`WndProc`/`MainLoop`:

| Global | Used by | Replacement |
|--------|---------|-------------|
| `g_hWnd` | WndProc, CInput, SetTimer, IME | `mu::MuPlatform::GetWindow()->GetNativeHandle()` (if needed) |
| `g_hDC` | OpenGL context, SwapBuffers | Not needed — SDL_gpu owns the context |
| `g_hRC` | OpenGL context | Not needed |
| `g_hInst` | CreateWindow, LoadIcon | Not needed — SDL3 handles this |

**Warning:** `g_hWnd` is referenced in many files (MessageBox shim, CInput, etc.). The
`PlatformCompat.h` shim for `MessageBox` → `SDL_ShowSimpleMessageBox` already doesn't need
`g_hWnd`. But CInput and other places may still reference it — audit all usages.

### Files That Reference WinMain-Only Globals

Search: `grep -rn "g_hWnd\|g_hDC\|g_hRC\|g_hInst" src/source/ --include="*.cpp" --include="*.h"`
Each reference must be either removed or replaced with a cross-platform equivalent.

### Net Impact

- **~950 lines deleted** from Winmain.cpp (Win32-only code)
- **~30 lines added** (missing init steps ported to MuMain)
- **Winmain.cpp drops from 1721 to ~770 lines**
- **Zero divergent init paths** — one truth, all platforms

### References

- [Source: Winmain.cpp:27–978] — Win32-only block to delete
- [Source: Winmain.cpp:979–1441] — WinMain to delete
- [Source: Winmain.cpp:1464–1721] — MuMain + main (kept, enhanced)
- [Source: Story 7-9-1] — Created MuMain with SDL3 game loop
- [Source: Story 7-9-2] — All GL through IMuRenderer (prerequisite)

---

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
