# Story 7-9-19: Strip All Conditional-Compilation Axes (Final Cross-Platform Unification)

| Field | Value |
|-------|-------|
| **Story Key** | 7-9-19 |
| **Title** | Strip `#ifdef _WIN32` and `#ifdef MU_ENABLE_SDL3` Across Codebase |
| **Epic** | EPIC-7 (Stability, Diagnostics & Quality Gates) |
| **Feature** | 7.9 — SDL3 Cross-Platform Runtime |
| **Value Stream** | VS-0 (Platform / Enabler) |
| **Flow Type** | Refactor |
| **Flow Code** | VS0-PLAT-CONDCOMP-UNIFY |
| **Story Points** | 5 |
| **Dependencies** | 7-9-5 (stub deletion), 7-9-14 (Win32 backend deletion), 7-9-15 (fatal-exit), 7-9-16 (IME), 7-9-17 (timer), 7-9-18 (point-fixes) — **all must land before this story** |
| **Status** | ready-for-dev |

---

## User Story

**As a** maintainer of the codebase,
**I want** every `#ifdef _WIN32` and `#ifdef MU_ENABLE_SDL3` block stripped (with the SDL3-side implementation kept as the unconditional path),
**So that** the codebase has one implementation, no platform-conditional source paths to test, and no build presets that produce a non-SDL3 binary.

---

## Background

### Two conditional axes — both go away

The codebase carries two project-specific conditional-compilation axes that this story collapses:

| Axis | Defined by | Files using it | Action |
|---|---|---|---|
| `_WIN32` | Compiler (true on Windows builds) | 15 source files | Delete `#ifdef _WIN32` blocks where they wrap vestigial Win32 code; keep only legitimate platform-API differences (signal handlers in `MuPlatform.cpp:40-46`) |
| `MU_ENABLE_SDL3` | Project (true on every supported build) | 19 source files | Delete `#ifdef` guards; the SDL3 path becomes unconditional |

By the time this story runs, prerequisites have removed the SDL3-vs-Win32-stub silent failures (7-9-15..7-9-18) and the Win32 platform backend (7-9-14). What's left is **mechanical removal of the now-redundant guards**.

### Files in scope

**`#ifdef _WIN32` axis (15 files; some overlap with `MU_ENABLE_SDL3` axis):**

| File | Blocks | After 7-9-14..18 land, what remains |
|---|---|---|
| `Platform/win32/*` | (5 files entirely wrapped) | Already deleted by 7-9-14 |
| `Platform/PlatformCompat.h` | 5 | Mostly Win32 type aliases — strip |
| `ThirdParty/UIControls.cpp` | 9 | After 7-9-16 deletes IME blocks: ~3 remaining (legacy edit-control fallback `m_hEditWnd`); strip |
| `Main/MuMain.cpp` | 1 (regkey include) | Already deleted by 7-9-14 |
| `ThirdParty/CBTMessageBox.{h,cpp}` | 2 | Win32 message-box wrapper — strip; `SDL_ShowSimpleMessageBox` already used elsewhere |
| `Platform/PlatformTypes.h` | 1 | Win32 typedef gate — strip |
| `Platform/PlatformKeys.h` | 1 | Win32 VK_* keycode fallback — strip; SDL keycodes are canonical |
| `Platform/PlatformCrypto.cpp` | 1 | Win32 DPAPI fallback — strip if dead, port if live |
| `Platform/MuPlatform.cpp` | 1 | The legitimate `#ifndef _WIN32` POSIX signal handler block at lines 40-46 — **KEEP** (genuine platform-API difference) |
| `Resources/Windows/resource.rc` | (entire file) | Already deleted by 7-9-14 |

**`#ifdef MU_ENABLE_SDL3` axis (19 files):**

| File | Blocks | Action |
|---|---|---|
| `RenderFX/MuRendererSDLGpu.cpp` | 25 | **VERIFY in scope** — most are internal SDL3-specific feature gates, not platform-conditional. May not need stripping. |
| `ThirdParty/UIControls.cpp` | 10 | Strip — keep SDL3 side |
| `Data/GlobalBitmap.cpp` | 8 | Strip — keep SDL3 side |
| `Main/MuMain.cpp` | 5 | Strip — keep SDL3 side; biggest individual file effort (lines 110-114 / 414-442 / 453-462 / 611-626 / 655-657) |
| `Platform/PlatformCompat.h` | 4 | Strip — keep SDL3 side |
| `Platform/MuPlatform.cpp` | 4 | Strip — keep SDL3 side; SDL3 backend becomes unconditional |
| `Network/WSclient.cpp` | 3 | Strip — including the packet-bus block at line 14871-14881 (keep mutex+queue path, delete `PostMessage` `#else`) |
| `Gameplay/Items/ZzzInventory.cpp` | 3 | Strip — keep SDL3 side |
| `RenderFX/MuRenderer.h`, `Platform/sdl3/SDLWindow.{h,cpp}`, `Platform/sdl3/SDLEventLoop.{h,cpp}`, `Platform/sdl3/SDLKeyboardState.cpp`, `Platform/posix/PosixSignalHandlers.cpp` | 2 each | Strip cautiously — some may be header-include guards rather than code-conditional; verify each |

### Build configuration

CMake / build presets must define `MU_ENABLE_SDL3=ON` unconditionally on macOS, Linux, Windows. Verify after the strip pass that no preset still references the macro as a flag (it should be hardcoded ON, or removed entirely).

---

## Functional Acceptance Criteria

- [ ] **AC-1: `#ifdef MU_ENABLE_SDL3` removed from all source files.** `grep -rln "MU_ENABLE_SDL3" src/source/` returns at most a handful of legitimate uses (e.g., a single CMake-driven `#define` in a config header, or feature-gate macros internal to `MuRendererSDLGpu.cpp`). All paired `#ifdef MU_ENABLE_SDL3 / #else / #endif` blocks have been collapsed: SDL3 body kept, `#else` body deleted, guards removed.
- [ ] **AC-2: `#ifdef _WIN32` removed from non-platform files.** `grep -rln "_WIN32" src/source/ | grep -v Platform/` returns zero matches except for legitimate internal uses (e.g., a comment, or a SDL header that uses `_WIN32` internally — both fine). All `_WIN32` checks in game-code files (`UIControls.cpp`, `CBTMessageBox.*`, `ZzzInventory.cpp`, etc.) are deleted.
- [ ] **AC-3: `#ifdef _WIN32` retained ONLY for legitimate platform-API differences.** `MuPlatform.cpp:40-46` (`#ifndef _WIN32` for POSIX signal handlers) is preserved with a justifying comment. Any other surviving `_WIN32` guards in `Platform/` are documented inline as legitimate API differences (Windows crash-handler API vs. POSIX `sigaction`, etc.) — list them in the story Closing Notes.
- [ ] **AC-4: Build configuration unconditional.** `MU_ENABLE_SDL3` is no longer a build flag — every CMake preset compiles the SDL3 path. Either the macro is hard-`#define`d in a config header included everywhere, or all reference to it is removed (compilation succeeds without it being defined because the conditional code that needed it is gone).
- [ ] **AC-5: All builds pass.** `cmake --build` succeeds on macOS, Linux, Windows. No undefined references, no warnings about unreachable code, no "macro not defined" errors.
- [ ] **AC-6: Smoke test on all platforms.** Game launches → login → chat → logout on macOS, Linux, Windows. No regression vs. pre-strip behavior.
- [ ] **AC-7: Final stub-line gate.** `grep -cE "return (nullptr|NULL|FALSE|0);" src/source/Platform/PlatformCompat.h` count documented in story Closing Notes. Should be substantially lower than the 59 baseline (most stubs gone after 7-9-5 deletions + this story's stub removals from 7-9-15..18).

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance
- [ ] **AC-STD-2:** Smoke test on all three platforms; no new unit tests required (mechanical strip)
- [ ] **AC-STD-13:** Quality Gate passes
- [ ] **AC-STD-15:** Git Safety

---

## Tasks / Subtasks

- [ ] Task 1: Verify all prerequisites landed (AC: 1)
  - [ ] 1.1: 7-9-5, 7-9-14, 7-9-15, 7-9-16, 7-9-17, 7-9-18 all `Status: done`
  - [ ] 1.2: Re-grep current state — confirm no Category C call sites remain in unguarded code
- [ ] Task 2: Strip `MU_ENABLE_SDL3` axis (AC: 1)
  - [ ] 2.1: `Main/MuMain.cpp` — 5 blocks
  - [ ] 2.2: `Platform/MuPlatform.cpp` — 4 blocks (SDL3 path becomes unconditional `CreateWindow`)
  - [ ] 2.3: `Platform/PlatformCompat.h` — 4 blocks
  - [ ] 2.4: `ThirdParty/UIControls.cpp` — 10 blocks
  - [ ] 2.5: `Data/GlobalBitmap.cpp` — 8 blocks
  - [ ] 2.6: `Network/WSclient.cpp` — 3 blocks (incl. packet-bus block at 14871-14881)
  - [ ] 2.7: `Gameplay/Items/ZzzInventory.cpp` — 3 blocks
  - [ ] 2.8: `RenderFX/MuRenderer.h`, `Platform/sdl3/*`, `Platform/posix/PosixSignalHandlers.cpp` — verify each (some may be header-include guards, not platform-conditional)
- [ ] Task 3: Strip `_WIN32` axis (AC: 2, 3)
  - [ ] 3.1: `Platform/PlatformCompat.h` — 5 blocks (Win32 type aliases)
  - [ ] 3.2: `ThirdParty/UIControls.cpp` — remaining `_WIN32` blocks after 7-9-16's deletions
  - [ ] 3.3: `ThirdParty/CBTMessageBox.{h,cpp}` — Win32 message-box wrapper
  - [ ] 3.4: `Platform/PlatformTypes.h`, `Platform/PlatformKeys.h`, `Platform/PlatformCrypto.cpp` — verify each
  - [ ] 3.5: Document the `MuPlatform.cpp:40-46` POSIX-signal-handler `#ifndef _WIN32` as legitimate (add inline comment if absent)
- [ ] Task 4: Update CMake / build configuration (AC: 4)
  - [ ] 4.1: Hard-`#define MU_ENABLE_SDL3` in a project config header, or remove all references
  - [ ] 4.2: Verify all presets still build
- [ ] Task 5: Build + smoke test (AC: 5, 6)
  - [ ] 5.1: Clean build on macOS, Linux, Windows
  - [ ] 5.2: Smoke test: launch → login → chat → logout on each platform
  - [ ] 5.3: `./ctl check` passes
- [ ] Task 6: Closing Notes (AC: 3, 7)
  - [ ] 6.1: Document any preserved `_WIN32` blocks with inline justifying comments
  - [ ] 6.2: Record final `PlatformCompat.h` stub-line count

---

## Dev Notes

### Why this is the last story in the sequence

Earlier stories (7-9-15..18) replace the *callers* of Win32-stub functions with cross-platform implementations. 7-9-14 deletes the *Win32 backend*. 7-9-5 deletes *dead stub declarations*. After all those, what's left is the conditional-compilation scaffolding that *was* needed to keep the two paths in sync — it has no purpose once one path remains. This story removes the scaffolding.

### Sequence recovery

If the strip pass uncovers a Category C call site that was missed by 7-9-15..18 (a stub call hidden inside a `#else` branch that becomes unconditional after the strip), the correct response is **stop the strip, file a sibling story for the missed pattern, land it, then resume**. Do not paper over with a temporary `#ifdef` — that defeats the story's purpose.

### Out of scope

- Internal feature gates inside `MuRendererSDLGpu.cpp` that happen to use `MU_ENABLE_SDL3` for non-platform reasons (e.g., gating an experimental render path) — keep those.
- POSIX signal handlers (`MuPlatform.cpp:40-46`) — legitimate platform-API difference, not vestigial.
- `_EDITOR` macro and the ImGui Win32 backend gated by it (`MuMain.cpp:58-66`) — separate build configuration concern, separate story if needed.
