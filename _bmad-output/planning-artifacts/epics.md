---
stepsCompleted: ['step-01-prerequisites', 'step-02-design-epics', 'step-03-create-stories', 'step-04-final-validation']
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/project-context.md
  - _bmad-output/test-artifacts/test-design-architecture.md
workflowType: 'create-epics-and-stories'
project_name: 'MuMain-workspace'
user_name: 'Paco'
date: '2026-02-28'
status: 'complete'
total_epics: 7
total_stories: 45
total_story_points: 172
---

# MuMain-workspace - Epic Breakdown

## Overview

This document decomposes the MuMain cross-platform migration requirements into 7 implementation-ready epics with 45 stories totaling 172 story points. The epic structure follows the architecture's 10-phase migration sequence (Decision 6), with .NET AOT moved early to Phase 2.5 for end-to-end validation.

**Value Streams:**
- **VS-0 (Platform Foundation):** Infrastructure, build system, platform abstraction, CI, diagnostics
- **VS-1 (Core Experience):** Rendering, audio, input, networking, gameplay — what the player experiences

**Adapted Standards:** This is a C++20 game client, not a web API. Standard acceptance criteria are adapted from the PCC template to reflect the project's actual technology stack (Catch2 testing, MinGW CI, error taxonomy prefixes, cross-platform constraints).

## Requirements Inventory

### Functional Requirements

| ID | Category | Description |
|----|----------|-------------|
| FR1 | Platform & Build | Build MuMain from source on macOS using CMake |
| FR2 | Platform & Build | Build MuMain from source on Linux using CMake |
| FR3 | Platform & Build | Build MuMain from source on Windows using MSVC (must not regress) |
| FR4 | Platform & Build | Documented build instructions per platform (clone to running in <30 min) |
| FR5 | Platform & Build | CI validates every commit (build, formatting, static analysis) |
| FR6 | Server Connectivity | Connect to OpenMU server from macOS |
| FR7 | Server Connectivity | Connect to OpenMU server from Linux |
| FR8 | Server Connectivity | Connect to OpenMU server from Windows (must not regress) |
| FR9 | Server Connectivity | .NET Native AOT library loads on all platforms (.dll/.dylib/.so) |
| FR10 | Server Connectivity | Error messages identify failure type and suggest corrective action |
| FR11 | Server Connectivity | Configurable server connection target (address and port) |
| FR12 | Rendering & Display | Game world rendered via SDL_gpu on macOS (Metal) |
| FR13 | Rendering & Display | Game world rendered via SDL_gpu on Linux (Vulkan) |
| FR14 | Rendering & Display | Game world rendered via SDL_gpu on Windows (Direct3D) |
| FR15 | Rendering & Display | Visual parity validated through ground truth screenshot comparison |
| FR16 | Rendering & Display | Game window interaction (resize, minimize, focus) via SDL3 |
| FR17 | Audio | Background music on all platforms via miniaudio |
| FR18 | Audio | Sound effects on all platforms via miniaudio |
| FR19 | Audio | All game audio assets (WAV, OGG, MP3) on all platforms |
| FR20 | Input | Keyboard control on all platforms via SDL3 |
| FR21 | Input | Mouse interaction on all platforms via SDL3 |
| FR22 | Input | Text input in chat/fields on all platforms via SDL3 |
| FR23 | Gameplay | Authenticate and log in to OpenMU server |
| FR24 | Gameplay | Create, select, and manage characters |
| FR25 | Gameplay | Navigate game world across all 82 maps |
| FR26 | Gameplay | Combat (melee, ranged, skills) with monsters and players |
| FR27 | Gameplay | Manage inventory (equip, unequip, move, drop across 120 slots) |
| FR28 | Gameplay | Trade items with other players |
| FR29 | Gameplay | Join and manage guilds |
| FR30 | Gameplay | Participate in party gameplay |
| FR31 | Gameplay | Use quest system |
| FR32 | Gameplay | Manage pets and companions |
| FR33 | Gameplay | Use NPC shops and services |
| FR34 | Gameplay | Participate in PvP (duels, guild wars, castle siege) |
| FR35 | Gameplay | Use all 84 UI windows |
| FR36 | Gameplay | Chat (normal, party, guild, whisper channels) |
| FR37 | Stability | 60+ minute session on macOS without crashes |
| FR38 | Stability | 60+ minute session on Linux without crashes |
| FR39 | Stability | Diagnostic logs to MuError.log on all platforms |
| FR40 | Stability | No bugs that crash, corrupt data, or prevent core gameplay |

### Non-Functional Requirements

| ID | Category | Description |
|----|----------|-------------|
| NFR1 | Performance | 30+ FPS sustained on macOS/Linux (target 60 FPS) |
| NFR2 | Performance | Input latency adds no more than 5ms over Windows baseline |
| NFR3 | Performance | No frame hitches (>50ms) during 60+ minute sessions |
| NFR4 | Security | All network packet data validated before use |
| NFR5 | Security | No assert() on network, file, or user input data |
| NFR6 | Security | Packet encryption (SimpleModulus + XOR3) correct on all platforms |
| NFR7 | Security | No credentials stored in plaintext on disk |
| NFR8 | Integration | Protocol compatibility with current stable OpenMU |
| NFR9 | Integration | .NET interop marshaling correct on all platforms (char16_t) |
| NFR10 | Integration | Compatible OpenMU version documented |
| NFR11 | Portability | Zero #ifdef _WIN32 in game logic |
| NFR12 | Portability | Forward slashes and std::filesystem::path only |
| NFR13 | Portability | New serialization uses char + UTF-8, not wchar_t |
| NFR14 | Portability | Single codebase, single CMake build system, three platforms |
| NFR15 | Maintainability | CI quality gates (formatting, static analysis, build) |
| NFR16 | Maintainability | Modern C++ conventions in new code |
| NFR17 | Maintainability | Conventional commits for automated versioning |
| NFR18 | Maintainability | Diagnostic logging on all platforms |

### Additional Requirements (from Architecture & Test Design)

| Source | Requirement | Impact |
|--------|-------------|--------|
| Arch Decision 1 | MuRenderer abstraction with ~5 core functions before SDL_gpu swap | Rendering migration strategy |
| Arch Decision 2 | Compile-time CMake backends (win32/ + posix/) in MUPlatform | Platform code organization |
| Arch Decision 3 | char16_t at .NET interop boundary, CMake RID detection | String encoding correctness |
| Arch Decision 4 | MuAudio abstraction with miniaudio backend | Audio migration strategy |
| Arch Decision 6 | .NET AOT moved to Phase 2.5 for early e2e validation | Sequencing constraint |
| Test Design R1 | Ground truth capture before rendering migration | BLOCKER for Phase 3 |
| Test Design R5 | -DENABLE_GROUND_TRUTH_CAPTURE build flag | Implementation requirement |
| Test Design §3 | Perceptual diff (SSIM > 0.99) not exact pixel match | Rendering validation method |
| Test Design §3 | Dependency inversion for new abstraction layers (IMuRenderer, IMuAudio) | Testability |

### FR Coverage Map

| FR | Epic | Story |
|----|------|-------|
| FR1 | EPIC-1 | 1.1 |
| FR2 | EPIC-1 | 1.2 |
| FR3 | EPIC-1 | 1.1, 1.2 (regression) |
| FR4 | EPIC-1 | 1.6 |
| FR5 | EPIC-1 | 1.5; EPIC-7: 7.7 |
| FR6 | EPIC-3 | 3.4 |
| FR7 | EPIC-3 | 3.5 |
| FR8 | EPIC-3 | 3.4, 3.5 (regression) |
| FR9 | EPIC-1: 1.4; EPIC-3 | 3.1, 3.2 |
| FR10 | EPIC-3 | 3.6 |
| FR11 | EPIC-3 | 3.7 |
| FR12 | EPIC-4 | 4.7 |
| FR13 | EPIC-4 | 4.7 |
| FR14 | EPIC-4 | 4.7 |
| FR15 | EPIC-4 | 4.1, 4.2–4.6, 4.9 |
| FR16 | EPIC-2 | 2.2 |
| FR17 | EPIC-5 | 5.2 |
| FR18 | EPIC-5 | 5.3 |
| FR19 | EPIC-5 | 5.4 |
| FR20 | EPIC-2 | 2.3 |
| FR21 | EPIC-2 | 2.4 |
| FR22 | EPIC-2 | 2.5 |
| FR23 | EPIC-6 | 6.1 |
| FR24 | EPIC-6 | 6.1 |
| FR25 | EPIC-6 | 6.2 |
| FR26 | EPIC-6 | 6.3 |
| FR27 | EPIC-6 | 6.4 |
| FR28 | EPIC-6 | 6.4 |
| FR29 | EPIC-6 | 6.5 |
| FR30 | EPIC-6 | 6.5 |
| FR31 | EPIC-6 | 6.6 |
| FR32 | EPIC-6 | 6.6 |
| FR33 | EPIC-6 | 6.4 |
| FR34 | EPIC-6 | 6.6 |
| FR35 | EPIC-6 | 6.7 |
| FR36 | EPIC-6 | 6.5 |
| FR37 | EPIC-7 | 7.4 |
| FR38 | EPIC-7 | 7.5 |
| FR39 | EPIC-7 | 7.1 |
| FR40 | EPIC-7 | 7.6 |

## Epic List

| Epic | Title | Value Stream | Flow Type | Stories | Points | Priority | Phase |
|------|-------|-------------|-----------|---------|--------|----------|-------|
| EPIC-1 | Platform Foundation & Build System | VS-0 | Enabler | 6 | 18 | P0 | 0 |
| EPIC-2 | SDL3 Windowing & Input Migration | VS-1 | Feature | 5 | 17 | P0 | 1–2 |
| EPIC-3 | .NET AOT Cross-Platform Networking | VS-1 | Feature | 7 | 24 | P0 | 2.5 |
| EPIC-4 | Rendering Pipeline Migration | VS-1 | Feature | 9 | 48 | P0 | 3–5 |
| EPIC-5 | Audio System Migration | VS-1 | Feature | 5 | 18 | P0 | 6 |
| EPIC-6 | Cross-Platform Gameplay Validation | VS-1 | Feature | 7 | 23 | P0 | 9–10 |
| EPIC-7 | Stability, Diagnostics & Quality Gates | VS-0 | Enabler | 6 | 24 | P0 | 0 + 10 |

---

## Epic 1: Platform Foundation & Build System

**[VS-0] [Flow:Enabler]**

> Establish the cross-platform build infrastructure, platform abstraction layer, and CI foundation that all subsequent migration epics depend on.

### Epic Overview

| Attribute | Value |
|-----------|-------|
| Epic ID | EPIC-1 |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Type | Enabler Flow |
| Total Story Points | 18 |
| Prerequisites | None — this is the foundation |
| PRD References | FR1–FR5, FR9 (partial) |
| Contributing Milestones | Architecture Phase 0 |

### Feature Map

| Feature | Stories | Points | Priority |
|---------|---------|--------|----------|
| 1.1–1.2 CMake Toolchains | 2 | 5 | P0 |
| 1.3–1.4 Platform Abstraction | 2 | 8 | P0 |
| 1.5 SDL3 Integration | 1 | 3 | P0 |
| 1.6 Build Docs & CI | 1 | 2 | P0 |

---

### Story 1.1: Create macOS CMake Toolchain & Presets

**[VS-0] [Flow:E]**

**As a** developer,
**I want** CMake toolchain files and presets for macOS (arm64 + x64),
**So that** I can build MuMain natively on macOS with a single cmake command.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** None
**Flow Code:** VS0-PLAT-CMAKE-MACOS

#### Functional Acceptance Criteria

- [ ] **AC-1:** `cmake/toolchains/macos-arm64.cmake` exists with Clang configuration, C++20 standard, and correct system framework paths
- [ ] **AC-2:** `CMakePresets.json` includes `macos-arm64` configure and build presets
- [ ] **AC-3:** `cmake --preset macos-arm64` succeeds on macOS (configure step — full build not expected until SDL3 migration)
- [ ] **AC-4:** Windows MSVC presets (`windows-x64`, `windows-x64-mueditor`) are unchanged and still work

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** No Catch2 tests required (build system only)
- [ ] **AC-STD-3:** No banned Win32 APIs introduced
- [ ] **AC-STD-4:** CI quality gate passes (existing MinGW + clang-format + cppcheck)
- [ ] **AC-STD-5:** Conventional commit: `build(platform): add macOS CMake toolchain and presets`

#### Validation Artifacts

- [ ] **AC-VAL-1:** macOS configure log showing successful CMake run
- [ ] **AC-VAL-2:** Windows build confirmed not regressed

---

### Story 1.2: Create Linux CMake Toolchain & Presets

**[VS-0] [Flow:E]**

**As a** developer,
**I want** CMake toolchain files and presets for Linux (x64),
**So that** I can build MuMain natively on Linux with a single cmake command.

**Story Points:** 2
**Priority:** P0 - Must Have
**Prerequisites:** None (can run parallel with 1.1)
**Flow Code:** VS0-PLAT-CMAKE-LINUX

#### Functional Acceptance Criteria

- [ ] **AC-1:** `cmake/toolchains/linux-x64.cmake` exists with GCC configuration, C++20 standard
- [ ] **AC-2:** `CMakePresets.json` includes `linux-x64` configure and build presets
- [ ] **AC-3:** `cmake --preset linux-x64` succeeds on Linux (configure step)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** No Catch2 tests required (build system only)
- [ ] **AC-STD-3:** No banned Win32 APIs introduced
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Conventional commit: `build(platform): add Linux CMake toolchain and presets`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Linux configure log showing successful CMake run

---

### Story 1.3: Platform Abstraction Headers

**[VS-0] [Flow:E]**

**As a** developer,
**I want** cross-platform type aliases and function declarations in shared headers,
**So that** game logic code can use platform-independent types and functions without `#ifdef _WIN32`.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** None
**Flow Code:** VS0-PLAT-ABSTRACT-HEADERS

#### Functional Acceptance Criteria

- [ ] **AC-1:** `PlatformCompat.h` declares cross-platform function shims (timing, message box, file I/O wrappers)
- [ ] **AC-2:** `PlatformTypes.h` defines platform type aliases (DWORD → uint32_t, BOOL → int, etc.) on non-Windows
- [ ] **AC-3:** Both headers use `#pragma once` and are included in MUPlatform CMake target
- [ ] **AC-4:** Headers compile without errors on macOS (Clang), Linux (GCC), and Windows (MSVC/MinGW)
- [ ] **AC-5:** No game logic files need modification to compile with these headers (they wrap existing types)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards (PascalCase, mu:: namespace for new code)
- [ ] **AC-STD-2:** Catch2 tests validate type size assertions (sizeof(DWORD) == 4, etc.)
- [ ] **AC-STD-3:** Zero `#ifdef _WIN32` leaked into game logic — all platform ifdefs contained in these headers
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Conventional commit: `refactor(platform): add cross-platform type aliases and compat headers`

#### Validation Artifacts

- [ ] **AC-VAL-1:** MinGW CI build passes with new headers
- [ ] **AC-VAL-2:** Clang compile on macOS (quality check) passes

---

### Story 1.4: MUPlatform Library with win32/posix Backends

**[VS-0] [Flow:E]**

**As a** developer,
**I want** a PlatformLibrary abstraction for dynamic library loading with win32 and posix implementations,
**So that** .NET AOT and any future dynamic libraries can be loaded without platform-specific code in game logic.

**Story Points:** 5
**Priority:** P0 - Must Have
**Prerequisites:** 1.3 (Platform headers)
**Flow Code:** VS0-PLAT-LIBRARY-BACKENDS

#### Functional Acceptance Criteria

- [ ] **AC-1:** `PlatformLibrary.h` defines interface: `Load(path) → handle`, `GetSymbol(handle, name) → pointer`, `Unload(handle)`
- [ ] **AC-2:** `win32/PlatformLibrary.cpp` implements via `LoadLibrary`/`GetProcAddress`/`FreeLibrary`
- [ ] **AC-3:** `posix/PlatformLibrary.cpp` implements via `dlopen`/`dlsym`/`dlclose`
- [ ] **AC-4:** CMake selects correct backend: `if(WIN32) → win32/` else `→ posix/`
- [ ] **AC-5:** Error handling: Load failure logs `PLAT: PlatformLibrary::Load() — {dlerror()/GetLastError()}` and returns null handle
- [ ] **AC-6:** `[[nodiscard]] bool` return pattern on all fallible functions

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards (mu:: namespace, PascalCase, `#pragma once`)
- [ ] **AC-STD-2:** Catch2 tests: load a known library, resolve a known symbol, verify null on missing library
- [ ] **AC-STD-3:** No `#ifdef _WIN32` in PlatformLibrary.h — compile-time CMake selection only
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging uses PLAT taxonomy prefix
- [ ] **AC-STD-6:** Conventional commit: `feat(platform): implement PlatformLibrary with win32/posix backends`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Catch2 test passes on MinGW CI
- [ ] **AC-VAL-2:** Manual validation on macOS (dlopen smoke test)

---

### Story 1.5: SDL3 Dependency Integration

**[VS-0] [Flow:E]**

**As a** developer,
**I want** SDL3 integrated as a CMake dependency (FetchContent or find_package),
**So that** subsequent epics can use SDL3 for windowing, input, and rendering.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 1.1, 1.2 (toolchains must exist)
**Flow Code:** VS0-PLAT-SDL3-INTEGRATE

#### Functional Acceptance Criteria

- [ ] **AC-1:** SDL3 added via `FetchContent` with version pinned in CMakeLists.txt
- [ ] **AC-2:** SDL3 builds successfully as part of the CMake configure on macOS, Linux, and Windows
- [ ] **AC-3:** `MUPlatform` and `MURenderFX` targets can link SDL3; game logic targets cannot (link visibility)
- [ ] **AC-4:** SDL3 headers are NOT included in any game logic file — only in MUPlatform and MURenderFX source
- [ ] **AC-5:** MinGW CI continues to pass (SDL3 cross-compiles or is excluded from CI initially)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** No Catch2 tests required (dependency integration only)
- [ ] **AC-STD-3:** SDL3 usage restricted to abstraction layers
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Conventional commit: `build(platform): integrate SDL3 via FetchContent`

#### Validation Artifacts

- [ ] **AC-VAL-1:** CMake configure log showing SDL3 fetched and configured
- [ ] **AC-VAL-2:** Link visibility confirmed (MUGame cannot include SDL3 headers)

---

### Story 1.6: Build Documentation Per Platform

**[VS-0] [Flow:E]**

**As a** developer,
**I want** documented build instructions for macOS, Linux, and Windows,
**So that** I can go from clone to running binary in under 30 minutes on any platform.

**Story Points:** 2
**Priority:** P0 - Must Have
**Prerequisites:** 1.1, 1.2, 1.5 (build system must work first)
**Flow Code:** VS0-PLAT-DOCS-BUILD

#### Functional Acceptance Criteria

- [ ] **AC-1:** `docs/development-guide.md` updated with macOS build section (prerequisites, cmake command, run)
- [ ] **AC-2:** Linux build section added (prerequisites, cmake command, run)
- [ ] **AC-3:** Each platform section lists exact toolchain requirements and versions
- [ ] **AC-4:** Troubleshooting section covers common failure modes per platform
- [ ] **AC-5:** CLAUDE.md build commands section updated to reflect new presets

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Documentation follows existing style in docs/
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Conventional commit: `docs(platform): add macOS and Linux build instructions`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Fresh clone → build on macOS completed in <30 min following only the docs
- [ ] **AC-VAL-2:** Fresh clone → build on Linux completed in <30 min following only the docs

---

### Epic 1 Story Dependency Graph

```
1.1 (macOS CMake) ──┐
                    ├──► 1.5 (SDL3 Integration) ──► 1.6 (Build Docs)
1.2 (Linux CMake) ──┘

1.3 (Platform Headers) ──► 1.4 (PlatformLibrary Backends)
```

**Parallel Execution:** Stories 1.1/1.2 and 1.3 can run concurrently. Story 1.4 depends on 1.3. Story 1.5 depends on 1.1+1.2. Story 1.6 depends on 1.5.

**Critical Path:** 1.1 → 1.5 → 1.6 (8 points)

---

### Epic 1 Validation Criteria

Before proceeding to EPIC-2, verify:

- [ ] CMake configures successfully on macOS, Linux, and Windows
- [ ] MUPlatform library compiles with correct platform backends
- [ ] PlatformLibrary can load a dynamic library on each platform
- [ ] SDL3 is available as a linked dependency for MUPlatform and MURenderFX
- [ ] MinGW CI remains green
- [ ] Build documentation covers all three platforms

---

## Epic 2: SDL3 Windowing & Input Migration

**[VS-1] [Flow:Feature]**

> Replace Win32 windowing and input (CreateWindowEx, GetAsyncKeyState, WM_* messages) with SDL3, enabling the game to launch and accept user input on macOS and Linux.

### Epic Overview

| Attribute | Value |
|-----------|-------|
| Epic ID | EPIC-2 |
| Value Stream | VS-1 (Core Experience) |
| Flow Type | Feature Flow |
| Total Story Points | 17 |
| Prerequisites | EPIC-1 (Platform Foundation) |
| PRD References | FR16, FR20–FR22 |
| Contributing Milestones | Architecture Phases 1–2 |

### Feature Map

| Feature | Stories | Points | Priority |
|---------|---------|--------|----------|
| 2.1–2.2 Windowing | 2 | 8 | P0 |
| 2.3–2.5 Input | 3 | 9 | P0 |

---

### Story 2.1: SDL3 Window Creation & Event Loop

**[VS-1] [Flow:F]**

**As a** player,
**I want** MuMain to create a window and run the game loop using SDL3,
**So that** the game launches on macOS and Linux with a visible window.

**Story Points:** 5
**Priority:** P0 - Must Have
**Prerequisites:** EPIC-1 complete (1.5 SDL3 integrated)
**Flow Code:** VS1-SDL-WINDOW-CREATE

#### Functional Acceptance Criteria

- [ ] **AC-1:** SDL3 window created at game startup via `mu::MuPlatform::CreateWindow()` wrapper
- [ ] **AC-2:** SDL3 event loop replaces Win32 message pump (`GetMessage`/`DispatchMessage`)
- [ ] **AC-3:** Window resize, minimize, maximize, close events handled correctly
- [ ] **AC-4:** Window title, size, and position configurable (matching existing behavior)
- [ ] **AC-5:** `mu::MuPlatform::GetWindow()` singleton accessor provides SDL_Window* to MURenderFX
- [ ] **AC-6:** Game exits cleanly on window close (no orphan processes)
- [ ] **AC-7:** Windows build continues to work (SDL3 windowing replaces Win32 on all platforms)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards (mu:: namespace, PascalCase)
- [ ] **AC-STD-2:** Catch2 test: window creation and destruction lifecycle
- [ ] **AC-STD-3:** No Win32 windowing APIs remain in game logic; SDL3 calls only in MUPlatform
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging: `PLAT: MuPlatform::CreateWindow() — SDL_GetError()`
- [ ] **AC-STD-6:** Conventional commit: `refactor(platform): replace Win32 windowing with SDL3`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Game window opens on macOS, Linux, and Windows
- [ ] **AC-VAL-2:** Window events (resize, close) behave identically on all platforms

---

### Story 2.2: SDL3 Window Focus & Display Management

**[VS-1] [Flow:F]**

**As a** player,
**I want** proper window focus handling and display resolution detection,
**So that** the game behaves correctly with Alt-Tab, fullscreen toggle, and multi-monitor setups.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 2.1 (SDL3 window exists)
**Flow Code:** VS1-SDL-WINDOW-FOCUS

#### Functional Acceptance Criteria

- [ ] **AC-1:** Focus gain/loss events pause/resume game appropriately (existing behavior preserved)
- [ ] **AC-2:** Display mode detection (resolution, refresh rate) via SDL3
- [ ] **AC-3:** Fullscreen toggle works on all platforms via SDL3
- [ ] **AC-4:** Mouse cursor confinement/release on focus change

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-3:** No Win32 display APIs (EnumDisplaySettings, ChangeDisplaySettings)
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Conventional commit: `refactor(platform): SDL3 focus and display management`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Alt-Tab works correctly on all platforms
- [ ] **AC-VAL-2:** Fullscreen toggle tested on macOS + Linux

---

### Story 2.3: SDL3 Keyboard Input Migration

**[VS-1] [Flow:F]**

**As a** player,
**I want** keyboard input handled by SDL3,
**So that** I can control my character and use hotkeys on macOS and Linux.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 2.1 (SDL3 event loop)
**Flow Code:** VS1-SDL-INPUT-KEYBOARD

#### Functional Acceptance Criteria

- [ ] **AC-1:** All `GetAsyncKeyState()` calls replaced with SDL3 keyboard state queries via `g_platformInput->IsKeyDown()`
- [ ] **AC-2:** Virtual key code mapping from Win32 VK_* to SDL scancodes
- [ ] **AC-3:** All hotkeys (F1–F12, skill shortcuts, chat toggle) work correctly
- [ ] **AC-4:** Key repeat behavior matches existing Windows client
- [ ] **AC-5:** macOS Cmd key mapped appropriately (Cmd → Ctrl equivalent for game controls)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 test: key mapping table validation (VK_* → SDL scancode coverage)
- [ ] **AC-STD-3:** No `GetAsyncKeyState` calls remain; SDL3 calls only in MUPlatform
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging: `INPUT: key mapping — unmapped VK code {x}`
- [ ] **AC-STD-6:** Conventional commit: `refactor(input): migrate keyboard input to SDL3`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Character movement (WASD or arrow keys) on all platforms
- [ ] **AC-VAL-2:** All hotkeys tested on macOS (Cmd key mapping verified)

---

### Story 2.4: SDL3 Mouse Input Migration

**[VS-1] [Flow:F]**

**As a** player,
**I want** mouse input handled by SDL3,
**So that** I can click UI elements, select targets, and navigate on macOS and Linux.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 2.1 (SDL3 event loop)
**Flow Code:** VS1-SDL-INPUT-MOUSE

#### Functional Acceptance Criteria

- [ ] **AC-1:** Mouse position, click, and scroll events from SDL3 replace Win32 WM_MOUSEMOVE/WM_LBUTTONDOWN/etc.
- [ ] **AC-2:** Cursor position correctly maps to game coordinates on all resolutions
- [ ] **AC-3:** Right-click context menus, drag-and-drop (inventory), and double-click work
- [ ] **AC-4:** Mouse cursor visibility toggle (hidden during gameplay, visible in menus)
- [ ] **AC-5:** Mouse wheel scrolling for UI lists and chat

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 test: mouse coordinate mapping at different resolutions
- [ ] **AC-STD-3:** No Win32 mouse APIs remain in game logic
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `refactor(input): migrate mouse input to SDL3`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Click-to-move, inventory drag, and UI interaction on all platforms
- [ ] **AC-VAL-2:** Cursor behavior in fullscreen vs windowed modes

---

### Story 2.5: SDL3 Text Input Migration

**[VS-1] [Flow:F]**

**As a** player,
**I want** text input handled by SDL3,
**So that** I can type in chat and text fields on macOS and Linux with correct character encoding.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 2.3 (keyboard input)
**Flow Code:** VS1-SDL-INPUT-TEXT

#### Functional Acceptance Criteria

- [ ] **AC-1:** SDL3 text input events (`SDL_EVENT_TEXT_INPUT`) replace Win32 WM_CHAR/WM_IME_*
- [ ] **AC-2:** Chat input field accepts typed characters correctly
- [ ] **AC-3:** Special characters and accented letters work on macOS/Linux keyboard layouts
- [ ] **AC-4:** Backspace, Delete, Home, End, arrow keys work in text fields
- [ ] **AC-5:** Text input activates/deactivates appropriately (only when text fields are focused)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-3:** No Win32 IME APIs remain
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `refactor(input): migrate text input to SDL3`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Chat typing tested on macOS and Linux
- [ ] **AC-VAL-2:** Special characters validated on non-US keyboard layouts

---

### Epic 2 Story Dependency Graph

```
2.1 (Window + Event Loop)
  ├──► 2.2 (Focus/Display)
  ├──► 2.3 (Keyboard) ──► 2.5 (Text Input)
  └──► 2.4 (Mouse)
```

**Parallel Execution:** Stories 2.2, 2.3, 2.4 can run concurrently after 2.1.

**Critical Path:** 2.1 → 2.3 → 2.5 (11 points)

---

### Epic 2 Validation Criteria

Before proceeding to EPIC-3, verify:

- [ ] Game window opens and runs game loop on macOS, Linux, and Windows
- [ ] Keyboard, mouse, and text input work correctly on all platforms
- [ ] No Win32 windowing or input APIs remain in game logic
- [ ] MinGW CI remains green

---

## Epic 3: .NET AOT Cross-Platform Networking

**[VS-1] [Flow:Feature]**

> Enable server connectivity on macOS and Linux by cross-platforming the .NET Native AOT network library, including dynamic loading, string encoding, and graceful error handling.

### Epic Overview

| Attribute | Value |
|-----------|-------|
| Epic ID | EPIC-3 |
| Value Stream | VS-1 (Core Experience) |
| Flow Type | Feature Flow |
| Total Story Points | 24 |
| Prerequisites | EPIC-1 (1.4 PlatformLibrary) |
| PRD References | FR6–FR11 |
| Contributing Milestones | Architecture Phase 2.5 |

### Feature Map

| Feature | Stories | Points | Priority |
|---------|---------|--------|----------|
| 3.1–3.2 Build Integration | 2 | 8 | P0 |
| 3.3 Encoding | 1 | 5 | P0 |
| 3.4–3.5 Platform Validation | 2 | 6 | P0 |
| 3.6–3.7 UX & Config | 2 | 5 | P0/P1 |

---

### Story 3.1: CMake RID Detection & .NET AOT Build Integration

**[VS-1] [Flow:F]**

**As a** developer,
**I want** CMake to detect the platform Runtime Identifier and build the .NET AOT library with the correct RID,
**So that** `dotnet publish` produces the right library format (.dll/.dylib/.so) for each platform.

**Story Points:** 5
**Priority:** P0 - Must Have
**Prerequisites:** EPIC-1 (1.1, 1.2 toolchains)
**Flow Code:** VS1-NET-CMAKE-RID

#### Functional Acceptance Criteria

- [ ] **AC-1:** `cmake/FindDotnetAOT.cmake` module detects platform and sets RID (`win-x86`, `win-x64`, `osx-arm64`, `osx-x64`, `linux-x64`)
- [ ] **AC-2:** CMake defines `MU_DOTNET_LIB_EXT` (`.dll`, `.dylib`, `.so`) based on platform
- [ ] **AC-3:** `add_custom_command` invokes `dotnet publish` with correct `--runtime` flag at configure time
- [ ] **AC-4:** Built library copied to binary output directory automatically
- [ ] **AC-5:** WSL interop path: `wslpath -w` conversion for dotnet.exe still works
- [ ] **AC-6:** Graceful failure: if dotnet not found, configure warns but doesn't fail (allows rendering-only builds)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** No Catch2 tests required (build system)
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging: `PLAT: FindDotnetAOT — dotnet not found at {path}`
- [ ] **AC-STD-6:** Conventional commit: `build(network): add CMake RID detection and .NET AOT build integration`

#### Validation Artifacts

- [ ] **AC-VAL-1:** `dotnet publish` produces correct library on each platform
- [ ] **AC-VAL-2:** Library appears in build output directory after cmake build

---

### Story 3.2: Connection.h Cross-Platform Updates

**[VS-1] [Flow:F]**

**As a** developer,
**I want** Connection.h to use PlatformLibrary for loading and platform-independent types,
**So that** the .NET interop code works on macOS and Linux without platform ifdefs.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** EPIC-1 (1.4 PlatformLibrary), 3.1 (CMake RID)
**Flow Code:** VS1-NET-CONNECTION-XPLAT

#### Functional Acceptance Criteria

- [ ] **AC-1:** `Connection.h` uses `mu::PlatformLibrary::Load()` instead of `LoadLibrary()`
- [ ] **AC-2:** Library path constructed via `MU_DOTNET_LIB_EXT` CMake define
- [ ] **AC-3:** Function pointer binding via `mu::PlatformLibrary::GetSymbol()` instead of `GetProcAddress`
- [ ] **AC-4:** No `#ifdef _WIN32` in Connection.h — all platform differences in PlatformLibrary
- [ ] **AC-5:** Existing Windows functionality unchanged (regression)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 test: Connection init with mock library path
- [ ] **AC-STD-3:** Zero platform ifdefs in Connection.h
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging: `NET: Connection — library load failed: {path}`
- [ ] **AC-STD-6:** Conventional commit: `refactor(network): cross-platform Connection.h via PlatformLibrary`

#### Validation Artifacts

- [ ] **AC-VAL-1:** MinGW CI build passes
- [ ] **AC-VAL-2:** Windows build confirmed working (regression check)

---

### Story 3.3: char16_t Encoding at .NET Interop Boundary

**[VS-1] [Flow:F]**

**As a** developer,
**I want** all C++/.NET string marshaling to use `char16_t` instead of `wchar_t`,
**So that** string encoding is correct on all platforms (wchar_t is 4 bytes on Linux/macOS, protocol expects 2).

**Story Points:** 5
**Priority:** P0 - Must Have
**Prerequisites:** 3.2 (Connection.h updated)
**Flow Code:** VS1-NET-CHAR16T-ENCODING

#### Functional Acceptance Criteria

- [ ] **AC-1:** All function pointer signatures in Connection.h use `char16_t*` instead of `wchar_t*`
- [ ] **AC-2:** .NET `[UnmanagedCallersOnly]` exports updated to match `char16_t` (UTF-16LE guaranteed)
- [ ] **AC-3:** XSLT code generation templates updated to produce `char16_t` binding code
- [ ] **AC-4:** String conversion utilities: `wchar_t ↔ char16_t` for legacy code compatibility
- [ ] **AC-5:** Korean, Latin, and mixed-script strings round-trip correctly through the boundary

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 tests: round-trip Korean + Latin + mixed strings, compare byte output to Windows wchar_t baseline (Risk R3 mitigation)
- [ ] **AC-STD-3:** No wchar_t at the .NET interop boundary
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging: `NET: char16_t marshaling — encoding mismatch for {context}`
- [ ] **AC-STD-6:** Conventional commit: `refactor(network): replace wchar_t with char16_t at .NET boundary`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Catch2 string round-trip tests pass
- [ ] **AC-VAL-2:** Byte-level output matches Windows baseline for all test vectors

---

### Story 3.4: macOS Server Connectivity Validation

**[VS-1] [Flow:F]**

**As a** player on macOS,
**I want** to connect to an OpenMU server,
**So that** I can play MU Online natively on my Mac.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 3.1, 3.2, 3.3 (all .NET plumbing complete)
**Flow Code:** VS1-NET-VALIDATE-MACOS

#### Functional Acceptance Criteria

- [ ] **AC-1:** ClientLibrary.dylib loads successfully via PlatformLibrary on macOS (arm64)
- [ ] **AC-2:** All exported function pointers resolve correctly
- [ ] **AC-3:** Client connects to OpenMU server, completes handshake, receives server list
- [ ] **AC-4:** Packet encryption (SimpleModulus + XOR3) produces correct output on macOS
- [ ] **AC-5:** Character data loads correctly (no encoding corruption)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 smoke test: load library → resolve symbols → ping (Risk R2 mitigation)
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `feat(network): validate macOS OpenMU connectivity`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Screenshot: server list displayed on macOS
- [ ] **AC-VAL-2:** Packet capture: handshake bytes match Windows baseline

---

### Story 3.5: Linux Server Connectivity Validation

**[VS-1] [Flow:F]**

**As a** player on Linux,
**I want** to connect to an OpenMU server,
**So that** I can play MU Online on Linux.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 3.1, 3.2, 3.3 (all .NET plumbing complete)
**Flow Code:** VS1-NET-VALIDATE-LINUX

#### Functional Acceptance Criteria

- [ ] **AC-1:** ClientLibrary.so loads successfully via PlatformLibrary on Linux (x64)
- [ ] **AC-2:** All exported function pointers resolve correctly
- [ ] **AC-3:** Client connects to OpenMU server, completes handshake, receives server list
- [ ] **AC-4:** Packet encryption produces correct output on Linux
- [ ] **AC-5:** Character data loads correctly

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 smoke test: load library → resolve symbols → ping
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `feat(network): validate Linux OpenMU connectivity`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Screenshot: server list displayed on Linux
- [ ] **AC-VAL-2:** Packet capture: handshake bytes match Windows baseline

---

### Story 3.6: Connection Error Messaging & Graceful Degradation

**[VS-1] [Flow:F]**

**As a** player,
**I want** clear error messages when server connection fails,
**So that** I can understand what went wrong and how to fix it.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 3.2 (Connection.h updated)
**Flow Code:** VS1-NET-ERROR-MESSAGING

#### Functional Acceptance Criteria

- [ ] **AC-1:** If .NET library not found: "Network library not found at {path}. Build ClientLibrary for {platform} or check build docs."
- [ ] **AC-2:** If library loads but symbol resolution fails: "Network library loaded but function {name} not found. Version mismatch?"
- [ ] **AC-3:** If server unreachable: "Cannot connect to {address}:{port}. Server may be offline."
- [ ] **AC-4:** If protocol mismatch: "Server handshake failed. Check OpenMU version compatibility."
- [ ] **AC-5:** If authentication fails: "Login failed. Check credentials."
- [ ] **AC-6:** Game launches without .NET library (rendering + input testable without network)
- [ ] **AC-7:** All error messages written to both screen (via MessageBox/SDL dialog) and MuError.log

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-5:** Error logging uses NET taxonomy prefix with specific failure context
- [ ] **AC-STD-6:** Conventional commit: `feat(network): add connection error messaging and graceful degradation`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Each error scenario manually triggered and message verified
- [ ] **AC-VAL-2:** Game launches and renders without .NET library present

---

### Story 3.7: Server Connection Configuration

**[VS-1] [Flow:F]**

**As a** player,
**I want** to configure the server address and port,
**So that** I can connect to different OpenMU servers.

**Story Points:** 2
**Priority:** P1 - Should Have
**Prerequisites:** 3.4 or 3.5 (basic connectivity working)
**Flow Code:** VS1-NET-CONFIG-SERVER

#### Functional Acceptance Criteria

- [ ] **AC-1:** Server address and port configurable via existing config file mechanism
- [ ] **AC-2:** Default values: `localhost:44405` (OpenMU default)
- [ ] **AC-3:** Config file uses cross-platform path (`std::filesystem::path`)
- [ ] **AC-4:** Invalid config values produce clear error messages

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `feat(network): configurable server connection target`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Connect to non-default server address

---

### Epic 3 Story Dependency Graph

```
3.1 (CMake RID) ──► 3.2 (Connection.h) ──► 3.3 (char16_t) ──┬──► 3.4 (macOS Validation)
                                                               ├──► 3.5 (Linux Validation)
                                            3.2 ──► 3.6 (Error Messaging)
                                            3.4/3.5 ──► 3.7 (Server Config)
```

**Parallel Execution:** Stories 3.4, 3.5, and 3.6 can run concurrently after 3.3/3.2.

**Critical Path:** 3.1 → 3.2 → 3.3 → 3.4 (16 points)

---

### Epic 3 Validation Criteria

Before proceeding to EPIC-4, verify:

- [ ] .NET AOT library builds and loads on macOS, Linux, and Windows
- [ ] Server connectivity works on all three platforms
- [ ] char16_t encoding produces correct packets
- [ ] Error messages help diagnose connection failures
- [ ] Game can launch without .NET library (graceful degradation)

---

## Epic 4: Rendering Pipeline Migration

**[VS-1] [Flow:Feature]**

> Migrate the rendering pipeline from OpenGL 1.x immediate mode to SDL_gpu via the MuRenderer abstraction layer, enabling native Metal (macOS), Vulkan (Linux), and Direct3D (Windows) rendering.

### Epic Overview

| Attribute | Value |
|-----------|-------|
| Epic ID | EPIC-4 |
| Value Stream | VS-1 (Core Experience) |
| Flow Type | Feature Flow |
| Total Story Points | 48 |
| Prerequisites | EPIC-1 (1.5 SDL3), EPIC-2 (2.1 windowing) |
| PRD References | FR12–FR15 |
| Contributing Milestones | Architecture Phases 3–5 |

### Feature Map

| Feature | Stories | Points | Priority |
|---------|---------|--------|----------|
| 4.1 Ground Truth | 1 | 5 | P0 |
| 4.2–4.6 MuRenderer Abstraction (Phase 3) | 5 | 22 | P0 |
| 4.7–4.8 SDL_gpu Backend (Phase 4) | 2 | 13 | P0 |
| 4.9 Texture System (Phase 5) | 1 | 8 | P0 |

---

### Story 4.1: Ground Truth Capture Mechanism

**[VS-1] [Flow:F]**

**As a** developer,
**I want** an automated ground truth screenshot capture system,
**So that** I can validate rendering parity after each migration step against the Windows OpenGL baseline.

**Story Points:** 5
**Priority:** P0 - Must Have
**Prerequisites:** EPIC-2 (2.1 windowing)
**Flow Code:** VS1-RENDER-GROUNDTRUTH-CAPTURE

#### Functional Acceptance Criteria

- [ ] **AC-1:** `-DENABLE_GROUND_TRUTH_CAPTURE` CMake flag enables capture mode (Test Design R5)
- [ ] **AC-2:** Capture mechanism: `glReadPixels` → PNG + SHA256 hash per frame/scene
- [ ] **AC-3:** Automated sweep: iterate through UI windows (CNewUI* `Show()`), capture each
- [ ] **AC-4:** Output to `tests/golden/` directory with structured naming: `{scene}_{resolution}.png`
- [ ] **AC-5:** Comparison tool: SSIM perceptual diff (threshold > 0.99) not exact pixel match (Test Design §3)
- [ ] **AC-6:** Comparison reports failures with visual diff image showing divergent regions

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 test: SSIM comparison function with known-similar and known-different images
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging: `RENDER: ground truth — capture failed for {scene}`
- [ ] **AC-STD-6:** Conventional commit: `feat(render): implement ground truth capture and SSIM comparison`

#### Validation Artifacts

- [ ] **AC-VAL-1:** `tests/golden/` populated with baseline screenshots from Windows OpenGL build
- [ ] **AC-VAL-2:** SSIM tool correctly identifies identical images (score 1.0) and different images (score < 0.99)

---

### Story 4.2: MuRenderer Core API with OpenGL Backend

**[VS-1] [Flow:F]**

**As a** developer,
**I want** the MuRenderer class with core rendering functions backed by the existing OpenGL implementation,
**So that** game code can render through a stable abstraction instead of calling OpenGL directly.

**Story Points:** 8
**Priority:** P0 - Must Have
**Prerequisites:** 4.1 (ground truth baselines captured)
**Flow Code:** VS1-RENDER-ABSTRACT-CORE

#### Functional Acceptance Criteria

- [ ] **AC-1:** `MuRenderer.h` defines abstract interface (IMuRenderer) with core functions: `RenderQuad2D()`, `RenderTriangles()`, `RenderQuadStrip()`, `SetBlendMode()`, `SetDepthTest()`, `SetFog()` (Test Design §3 — dependency inversion)
- [ ] **AC-2:** `MuRenderer.cpp` implements OpenGL backend (wrapping existing glBegin/glEnd patterns)
- [ ] **AC-3:** `MuRenderer::GetInstance()` provides singleton access (matching existing codebase pattern)
- [ ] **AC-4:** MatrixStack class replaces `glPushMatrix`/`glPopMatrix`/`glTranslatef`
- [ ] **AC-5:** `mu::` namespace, `MURenderFX` CMake target
- [ ] **AC-6:** No game logic files modified in this story — abstraction is created but not yet wired in

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards (mu:: namespace, PascalCase)
- [ ] **AC-STD-2:** Catch2 tests: MatrixStack push/pop/transform correctness, blend mode state tracking
- [ ] **AC-STD-3:** OpenGL calls only in MuRenderer.cpp — never in MuRenderer.h interface
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging: `RENDER: MuRenderer::{function} — {error context}`
- [ ] **AC-STD-6:** Conventional commit: `feat(render): create MuRenderer abstraction with OpenGL backend`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Catch2 tests pass for matrix and state management
- [ ] **AC-VAL-2:** MuRenderer.h interface reviewed for SDL_gpu compatibility

---

### Story 4.3: Migrate RenderBitmap Variants to RenderQuad2D

**[VS-1] [Flow:F]**

**As a** developer,
**I want** all 9 `RenderBitmap*` variant call sites migrated to `MuRenderer::RenderQuad2D()`,
**So that** ~80% of all rendering goes through the abstraction layer.

**Story Points:** 8
**Priority:** P0 - Must Have
**Prerequisites:** 4.2 (MuRenderer API exists)
**Flow Code:** VS1-RENDER-MIGRATE-QUAD2D

#### Functional Acceptance Criteria

- [ ] **AC-1:** All 9 `RenderBitmap*` variants (sprites, UI, terrain, effects) call `MuRenderer::RenderQuad2D()`
- [ ] **AC-2:** ~600 lines of duplicated rendering code eliminated
- [ ] **AC-3:** Each migrated function validated with ground truth screenshot comparison (SSIM > 0.99)
- [ ] **AC-4:** One function migrated per commit (Pattern 7: migration commit granularity)
- [ ] **AC-5:** No mixed OpenGL + MuRenderer in the same render pass (Anti-pattern)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-3:** No direct `glBegin`/`glEnd` calls remain in migrated files
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commits: `refactor(render): migrate {variant} to MuRenderer::RenderQuad2D`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Ground truth comparison passes for all migrated screens
- [ ] **AC-VAL-2:** Windows rendering unchanged (regression check)

---

### Story 4.4: Migrate Skeletal Mesh Rendering to RenderTriangles

**[VS-1] [Flow:F]**

**As a** developer,
**I want** the skeletal mesh rendering in ZzzBMD.cpp migrated to `MuRenderer::RenderTriangles()`,
**So that** character models, monsters, and NPCs render through the abstraction.

**Story Points:** 5
**Priority:** P0 - Must Have
**Prerequisites:** 4.2 (MuRenderer API exists)
**Flow Code:** VS1-RENDER-MIGRATE-TRIANGLES

#### Functional Acceptance Criteria

- [ ] **AC-1:** `glDrawArrays` path in ZzzBMD.cpp replaced with `MuRenderer::RenderTriangles()`
- [ ] **AC-2:** Vertex attribute binding (position, normal, texcoord, color) handled by MuRenderer
- [ ] **AC-3:** All character classes, monsters, and NPCs render correctly
- [ ] **AC-4:** Ground truth comparison passes for character model scenes

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `refactor(render): migrate skeletal mesh to MuRenderer::RenderTriangles`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Ground truth: character model screenshots match baseline
- [ ] **AC-VAL-2:** Multiple character classes verified (DK, DW, FE, MG, DL)

---

### Story 4.5: Migrate Trail Effects to RenderQuadStrip

**[VS-1] [Flow:F]**

**As a** developer,
**I want** trail effects and ribbons migrated to `MuRenderer::RenderQuadStrip()`,
**So that** all particle/trail rendering goes through the abstraction.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 4.2 (MuRenderer API exists)
**Flow Code:** VS1-RENDER-MIGRATE-QUADSTRIP

#### Functional Acceptance Criteria

- [ ] **AC-1:** `GL_QUAD_STRIP` paths replaced with `MuRenderer::RenderQuadStrip()`
- [ ] **AC-2:** Skill effects, weapon trails, and environmental ribbons render correctly
- [ ] **AC-3:** Ground truth comparison passes for effect-heavy scenes

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `refactor(render): migrate trail effects to MuRenderer::RenderQuadStrip`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Ground truth: combat effects match baseline

---

### Story 4.6: Migrate Blend & Pipeline State to MuRenderer

**[VS-1] [Flow:F]**

**As a** developer,
**I want** all blend mode, depth test, and fog state calls migrated to MuRenderer,
**So that** no direct OpenGL state management remains in game logic.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 4.2 (MuRenderer API exists)
**Flow Code:** VS1-RENDER-MIGRATE-STATE

#### Functional Acceptance Criteria

- [ ] **AC-1:** 7 `Enable*Blend` functions consolidated into `MuRenderer::SetBlendMode(mode)`
- [ ] **AC-2:** `glEnable(GL_DEPTH_TEST)` calls replaced with `MuRenderer::SetDepthTest(enabled)`
- [ ] **AC-3:** `glFogi`/`glFogf` calls replaced with `MuRenderer::SetFog(params)`
- [ ] **AC-4:** All GL state changes go through MuRenderer — no direct `glEnable`/`glDisable` in game logic

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 tests: blend mode state transitions, depth test toggle
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `refactor(render): consolidate blend/depth/fog state into MuRenderer`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Ground truth: alpha-blended effects (water, particles) match baseline
- [ ] **AC-VAL-2:** No `glEnable`/`glDisable` calls outside MuRenderer.cpp

---

### Story 4.7: SDL_gpu Backend Implementation

**[VS-1] [Flow:F]**

**As a** developer,
**I want** the MuRenderer OpenGL backend replaced with an SDL_gpu backend,
**So that** rendering uses Metal on macOS, Vulkan on Linux, and Direct3D on Windows.

**Story Points:** 8
**Priority:** P0 - Must Have
**Prerequisites:** 4.3, 4.4, 4.5, 4.6 (all call sites migrated to MuRenderer)
**Flow Code:** VS1-RENDER-SDLGPU-BACKEND

#### Functional Acceptance Criteria

- [ ] **AC-1:** `MuRendererSDLGpu.cpp` implements all MuRenderer/IMuRenderer interface functions using SDL_gpu API
- [ ] **AC-2:** SDL_gpu device created using platform-preferred backend (Metal/Vulkan/D3D)
- [ ] **AC-3:** Render pass management: begin/end pass, clear, present
- [ ] **AC-4:** Vertex buffer upload and draw calls via SDL_gpu
- [ ] **AC-5:** Texture binding via SDL_gpu texture objects
- [ ] **AC-6:** Ground truth comparison passes on Windows (D3D backend vs OpenGL baseline, SSIM > 0.99)
- [ ] **AC-7:** GLEW dependency removed from MUGame link targets

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 tests: device creation, render pass lifecycle
- [ ] **AC-STD-3:** No OpenGL calls remain anywhere in the codebase
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging: `RENDER: SDL_gpu — {SDL_GetError()}`
- [ ] **AC-STD-6:** Conventional commit: `feat(render): implement SDL_gpu backend for MuRenderer`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Ground truth passes on Windows (D3D), macOS (Metal), Linux (Vulkan)
- [ ] **AC-VAL-2:** FPS within 10% of OpenGL baseline on Windows

---

### Story 4.8: Shader Programs (HLSL + SDL_shadercross)

**[VS-1] [Flow:F]**

**As a** developer,
**I want** the 5 HLSL shader programs compiled via SDL_shadercross for all platforms,
**So that** rendering uses GPU-accelerated shading on Metal, Vulkan, and Direct3D.

**Story Points:** 5
**Priority:** P0 - Must Have
**Prerequisites:** 4.7 (SDL_gpu backend)
**Flow Code:** VS1-RENDER-SHADERS

#### Functional Acceptance Criteria

- [ ] **AC-1:** 5 HLSL shaders implemented: `basic_colored`, `basic_textured`, `model_mesh`, `shadow_volume`, `shadow_apply`
- [ ] **AC-2:** SDL_shadercross cross-compiles to SPIR-V (Vulkan), MSL (Metal), DXIL (D3D)
- [ ] **AC-3:** Shader compilation integrated into CMake build (compiled at build time, not runtime)
- [ ] **AC-4:** Compiled shader binaries included in output directory
- [ ] **AC-5:** All shaders are under 30 lines each (~150 total) per architecture spec

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Shader code follows HLSL conventions
- [ ] **AC-STD-4:** CI quality gate passes (shaders cross-compile in MinGW CI)
- [ ] **AC-STD-6:** Conventional commit: `feat(render): add HLSL shader programs with SDL_shadercross`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Shaders compile for all three backends without errors
- [ ] **AC-VAL-2:** Ground truth: lit/shadowed scenes match baseline

---

### Story 4.9: Texture System Migration (CGlobalBitmap → SDL_gpu)

**[VS-1] [Flow:F]**

**As a** developer,
**I want** the texture management system (CGlobalBitmap) migrated from OpenGL texture objects to SDL_gpu textures,
**So that** all ~30,000 indexed textures load and display correctly on all platforms.

**Story Points:** 8
**Priority:** P0 - Must Have
**Prerequisites:** 4.7 (SDL_gpu backend)
**Flow Code:** VS1-RENDER-TEXTURE-MIGRATE

#### Functional Acceptance Criteria

- [ ] **AC-1:** `glGenTextures`/`glBindTexture`/`glTexImage2D` replaced with SDL_gpu texture creation
- [ ] **AC-2:** CGlobalBitmap LRU cache works with SDL_gpu texture handles
- [ ] **AC-3:** libturbojpeg JPEG decoding pipeline feeds into SDL_gpu texture upload
- [ ] **AC-4:** All texture formats (JPEG, BMP, TGA) load correctly on all platforms
- [ ] **AC-5:** No texture memory leaks (SDL_gpu texture cleanup on eviction)
- [ ] **AC-6:** Ground truth: textured scenes (world terrain, character models) match baseline

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 test: texture creation, cache eviction, format loading
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging: `ASSET: texture upload — {format} decode failed for {path}`
- [ ] **AC-STD-6:** Conventional commit: `refactor(render): migrate texture system to SDL_gpu`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Ground truth: world terrain textures match baseline
- [ ] **AC-VAL-2:** Memory usage stable during extended texture loading (LRU working)

---

### Epic 4 Story Dependency Graph

```
4.1 (Ground Truth) ──► 4.2 (MuRenderer Core API)
                          ├──► 4.3 (RenderQuad2D migration)
                          ├──► 4.4 (RenderTriangles migration)
                          ├──► 4.5 (RenderQuadStrip migration)
                          └──► 4.6 (Blend/State migration)
                                      │
                          ┌───────────┘ (all 4.3–4.6 complete)
                          ▼
                       4.7 (SDL_gpu backend) ──► 4.8 (Shaders)
                                               └──► 4.9 (Texture system)
```

**Parallel Execution:** Stories 4.3, 4.4, 4.5, 4.6 can run concurrently after 4.2.

**Critical Path:** 4.1 → 4.2 → 4.3 → 4.7 → 4.9 (37 points)

---

### Epic 4 Validation Criteria

Before proceeding to EPIC-5, verify:

- [ ] All OpenGL calls removed from the codebase
- [ ] GLEW dependency removed
- [ ] Game renders correctly on macOS (Metal), Linux (Vulkan), Windows (D3D)
- [ ] Ground truth SSIM > 0.99 for all baseline screenshots on all platforms
- [ ] No frame time regression (FPS within 10% of OpenGL baseline)
- [ ] All ~30,000 textures load correctly

---

## Epic 5: Audio System Migration

**[VS-1] [Flow:Feature]**

> Replace DirectSound and wzAudio with the MuAudio abstraction layer backed by miniaudio, enabling cross-platform background music and sound effects.

### Epic Overview

| Attribute | Value |
|-----------|-------|
| Epic ID | EPIC-5 |
| Value Stream | VS-1 (Core Experience) |
| Flow Type | Feature Flow |
| Total Story Points | 18 |
| Prerequisites | EPIC-1 (Platform Foundation) |
| PRD References | FR17–FR19 |
| Contributing Milestones | Architecture Phase 6 |

### Feature Map

| Feature | Stories | Points | Priority |
|---------|---------|--------|----------|
| 5.1 Abstraction | 1 | 3 | P0 |
| 5.2–5.3 Implementation | 2 | 10 | P0 |
| 5.4 Format Support | 1 | 3 | P0 |
| 5.5 Volume Controls | 1 | 2 | P1 |

---

### Story 5.1: MuAudio Abstraction Layer

**[VS-1] [Flow:F]**

**As a** developer,
**I want** a clean audio interface (IMuAudio) with Init/Shutdown/PlayBGM/PlaySFX/Volume functions,
**So that** the audio backend can be implemented and tested independently from game logic.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** None (MUAudio CMake target exists)
**Flow Code:** VS1-AUDIO-ABSTRACT-API

#### Functional Acceptance Criteria

- [ ] **AC-1:** `MuAudio.h` defines abstract interface (IMuAudio): `Init()`, `Shutdown()`, `PlayBGM(path)`, `StopBGM()`, `PlaySFX(id, volume)`, `SetBGMVolume(level)`, `SetSFXVolume(level)`, `IsEnabled()` (Test Design §3 — dependency inversion)
- [ ] **AC-2:** Concrete implementation class follows `GetInstance()` singleton pattern
- [ ] **AC-3:** `mu::` namespace, `MUAudio` CMake target
- [ ] **AC-4:** `[[nodiscard]] bool Init()` with error return
- [ ] **AC-5:** Interface designed for test double injection (IMuAudio)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 tests: API call sequence validation (init → play → stop → shutdown)
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `feat(audio): create MuAudio abstraction layer`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Interface reviewed for completeness against existing audio usage

---

### Story 5.2: miniaudio BGM Implementation

**[VS-1] [Flow:F]**

**As a** player,
**I want** background music playing via miniaudio on all platforms,
**So that** I can hear the MU Online soundtrack while playing.

**Story Points:** 5
**Priority:** P0 - Must Have
**Prerequisites:** 5.1 (MuAudio interface)
**Flow Code:** VS1-AUDIO-MINIAUDIO-BGM

#### Functional Acceptance Criteria

- [ ] **AC-1:** `MuAudio::PlayBGM(path)` streams background music via `ma_engine` / `ma_sound`
- [ ] **AC-2:** BGM transitions (stop current → start new) are smooth (no audio pop/click)
- [ ] **AC-3:** BGM loops correctly (MU Online music tracks are designed to loop)
- [ ] **AC-4:** BGM plays on macOS, Linux, and Windows
- [ ] **AC-5:** wzAudio dependency removed for BGM playback

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 test: BGM load, play, stop lifecycle (using test audio file)
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging: `AUDIO: BGM — decode failed for {path}`
- [ ] **AC-STD-6:** Conventional commit: `feat(audio): implement BGM playback via miniaudio`

#### Validation Artifacts

- [ ] **AC-VAL-1:** BGM plays in Lorencia on all three platforms
- [ ] **AC-VAL-2:** Zone transition BGM change works smoothly

---

### Story 5.3: miniaudio SFX Implementation

**[VS-1] [Flow:F]**

**As a** player,
**I want** sound effects playing via miniaudio on all platforms,
**So that** I can hear combat sounds, UI clicks, and environmental audio.

**Story Points:** 5
**Priority:** P0 - Must Have
**Prerequisites:** 5.1 (MuAudio interface)
**Flow Code:** VS1-AUDIO-MINIAUDIO-SFX

#### Functional Acceptance Criteria

- [ ] **AC-1:** `MuAudio::PlaySFX(id, volume)` plays sound effects via `ma_engine`
- [ ] **AC-2:** Multiple SFX can play simultaneously (combat with multiple attackers)
- [ ] **AC-3:** SFX mapped to existing ~30,000+ indexed audio assets via asset pipeline
- [ ] **AC-4:** DirectSound dependency removed for SFX playback
- [ ] **AC-5:** SFX plays on macOS, Linux, and Windows
- [ ] **AC-6:** No audio latency added beyond 10ms from trigger to playback

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 test: SFX trigger, concurrent playback
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging: `AUDIO: SFX — asset {id} not found`
- [ ] **AC-STD-6:** Conventional commit: `feat(audio): implement SFX playback via miniaudio`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Combat sounds play correctly on all platforms
- [ ] **AC-VAL-2:** Concurrent SFX (e.g., group combat) doesn't clip or drop

---

### Story 5.4: Audio Format Support Validation

**[VS-1] [Flow:F]**

**As a** player,
**I want** all game audio assets (WAV, OGG, MP3) to play correctly via miniaudio,
**So that** no audio is missing or corrupted after the migration.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 5.2, 5.3 (BGM + SFX working)
**Flow Code:** VS1-AUDIO-FORMAT-VALIDATE

#### Functional Acceptance Criteria

- [ ] **AC-1:** WAV files (PCM) decode and play correctly (majority of SFX assets)
- [ ] **AC-2:** OGG Vorbis files decode and play correctly (BGM tracks)
- [ ] **AC-3:** MP3 files decode and play correctly (if any exist in asset set)
- [ ] **AC-4:** WAV PCM SHA256 comparison against DirectSound decoded baseline (Risk R9 mitigation)
- [ ] **AC-5:** No audio quality degradation (sample rate, bit depth preserved)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 tests: decode each format, compare PCM output hash to baseline
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `test(audio): validate WAV/OGG/MP3 format support via miniaudio`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Format-specific test results documented
- [ ] **AC-VAL-2:** Sample of 50 audio assets spot-checked on each platform

---

### Story 5.5: Volume Controls & Audio State Management

**[VS-1] [Flow:F]**

**As a** player,
**I want** BGM and SFX volume controls that persist across sessions,
**So that** I can set my preferred audio levels.

**Story Points:** 2
**Priority:** P1 - Should Have
**Prerequisites:** 5.2, 5.3 (BGM + SFX working)
**Flow Code:** VS1-AUDIO-VOLUME-CONTROLS

#### Functional Acceptance Criteria

- [ ] **AC-1:** `MuAudio::SetBGMVolume(level)` and `MuAudio::SetSFXVolume(level)` work in real-time
- [ ] **AC-2:** Volume range: 0.0 (mute) to 1.0 (full)
- [ ] **AC-3:** Audio can be fully disabled via `MuAudio::IsEnabled()` returning false
- [ ] **AC-4:** Volume settings saved/loaded from config file

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `feat(audio): add volume controls and audio state management`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Volume slider in UI controls audio level in real-time

---

### Epic 5 Story Dependency Graph

```
5.1 (MuAudio API)
  ├──► 5.2 (BGM) ──┬──► 5.4 (Format Validation)
  └──► 5.3 (SFX) ──┤
                    └──► 5.5 (Volume Controls)
```

**Parallel Execution:** Stories 5.2 and 5.3 can run concurrently after 5.1.

**Critical Path:** 5.1 → 5.2 → 5.4 (11 points)

---

### Epic 5 Validation Criteria

Before proceeding to EPIC-6, verify:

- [ ] Background music and sound effects play on all three platforms
- [ ] All audio formats (WAV, OGG, MP3) decode correctly
- [ ] DirectSound and wzAudio dependencies removed
- [ ] No audio latency or quality degradation vs Windows baseline
- [ ] Volume controls functional

---

## Epic 6: Cross-Platform Gameplay Validation

**[VS-1] [Flow:Feature]**

> Validate that all existing gameplay systems (FR23–FR36) survive the cross-platform migration intact on macOS and Linux. These are regression requirements — the systems exist, they must keep working.

### Epic Overview

| Attribute | Value |
|-----------|-------|
| Epic ID | EPIC-6 |
| Value Stream | VS-1 (Core Experience) |
| Flow Type | Feature Flow |
| Total Story Points | 23 |
| Prerequisites | EPIC-2, EPIC-3, EPIC-4, EPIC-5 (all migration complete) |
| PRD References | FR23–FR36 |
| Contributing Milestones | Architecture Phases 9–10 |

### Feature Map

| Feature | Stories | Points | Priority |
|---------|---------|--------|----------|
| 6.1–6.2 Core Loop | 2 | 6 | P0 |
| 6.3–6.4 Combat & Economy | 2 | 6 | P0 |
| 6.5–6.6 Social & Systems | 2 | 6 | P0 |
| 6.7 UI Validation | 1 | 5 | P0 |

---

### Story 6.1: Authentication & Character Management Validation

**[VS-1] [Flow:F]**

**As a** player on macOS/Linux,
**I want** login, character creation, and character selection to work correctly,
**So that** I can access my characters on any platform.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** EPIC-3 (networking), EPIC-4 (rendering), EPIC-2 (input)
**Flow Code:** VS1-GAME-VALIDATE-AUTH

#### Functional Acceptance Criteria

- [ ] **AC-1:** Login screen displays correctly on macOS and Linux
- [ ] **AC-2:** Username/password entry works (SDL3 text input)
- [ ] **AC-3:** Character list loads and displays correctly
- [ ] **AC-4:** Character creation (all 5 classes) works
- [ ] **AC-5:** Character selection and world entry work
- [ ] **AC-6:** Logout and character switch work

#### Standard Acceptance Criteria

- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `test(game): validate auth and character management on macOS/Linux`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Screenshots: login, character select, and character creation on macOS
- [ ] **AC-VAL-2:** Same screenshots on Linux
- [ ] **AC-VAL-3:** Windows regression: same flows still work

---

### Story 6.2: World Navigation Validation

**[VS-1] [Flow:F]**

**As a** player on macOS/Linux,
**I want** to navigate across all 82 game maps without issues,
**So that** the full game world is accessible.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 6.1 (can log in and enter world)
**Flow Code:** VS1-GAME-VALIDATE-NAVIGATION

#### Functional Acceptance Criteria

- [ ] **AC-1:** Character movement (click-to-move, keyboard) works on macOS/Linux
- [ ] **AC-2:** Map transitions (portals, warps) load correctly
- [ ] **AC-3:** Map rendering: terrain, objects, NPCs visible
- [ ] **AC-4:** Minimap displays correctly
- [ ] **AC-5:** Sample of key maps tested: Lorencia, Devias, Noria, Dungeon, Lost Tower, Atlans

#### Standard Acceptance Criteria

- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `test(game): validate world navigation on macOS/Linux`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Screenshots from 6+ maps on macOS
- [ ] **AC-VAL-2:** Ground truth comparison for key map renders

---

### Story 6.3: Combat System Validation

**[VS-1] [Flow:F]**

**As a** player on macOS/Linux,
**I want** combat (melee, ranged, skills) to work correctly with monsters and players,
**So that** the core gameplay loop functions on all platforms.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 6.2 (can navigate to combat areas)
**Flow Code:** VS1-GAME-VALIDATE-COMBAT

#### Functional Acceptance Criteria

- [ ] **AC-1:** Melee attacks hit monsters, damage numbers display
- [ ] **AC-2:** Skill activation (hotkey or click) works, effects render
- [ ] **AC-3:** Monster death animations and loot drops work
- [ ] **AC-4:** Player death and respawn work
- [ ] **AC-5:** Health/mana bars update correctly
- [ ] **AC-6:** Audio: combat sound effects play (depends on EPIC-5)

#### Standard Acceptance Criteria

- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `test(game): validate combat system on macOS/Linux`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Video or screenshot sequence of combat on macOS
- [ ] **AC-VAL-2:** Skill effects visual comparison to Windows baseline

---

### Story 6.4: Inventory, Trading & Shops Validation

**[VS-1] [Flow:F]**

**As a** player on macOS/Linux,
**I want** inventory management, player trading, and NPC shops to work correctly,
**So that** the item economy functions on all platforms.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 6.1 (logged in with character)
**Flow Code:** VS1-GAME-VALIDATE-ECONOMY

#### Functional Acceptance Criteria

- [ ] **AC-1:** Inventory opens, displays items correctly (all 120 slots)
- [ ] **AC-2:** Equip/unequip items to character model
- [ ] **AC-3:** Drag-and-drop item movement within inventory
- [ ] **AC-4:** Player-to-player trade window works
- [ ] **AC-5:** NPC shop buy/sell works
- [ ] **AC-6:** Item tooltips display correctly

#### Standard Acceptance Criteria

- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `test(game): validate inventory, trading, and shops on macOS/Linux`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Screenshots: inventory, trade window, NPC shop on macOS
- [ ] **AC-VAL-2:** Item drag-and-drop verified via mouse input

---

### Story 6.5: Social Systems Validation

**[VS-1] [Flow:F]**

**As a** player on macOS/Linux,
**I want** guilds, parties, and chat to work correctly,
**So that** multiplayer social features function on all platforms.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 6.1 (logged in)
**Flow Code:** VS1-GAME-VALIDATE-SOCIAL

#### Functional Acceptance Criteria

- [ ] **AC-1:** Chat messages send and receive (normal, party, guild, whisper channels)
- [ ] **AC-2:** Party creation, invitation, and member display work
- [ ] **AC-3:** Guild information panel displays correctly
- [ ] **AC-4:** Player names and guild tags render above characters
- [ ] **AC-5:** Chat encoding: Korean and Latin characters display correctly (char16_t validation)

#### Standard Acceptance Criteria

- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `test(game): validate social systems on macOS/Linux`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Chat messages displayed correctly on macOS
- [ ] **AC-VAL-2:** Korean character rendering verified

---

### Story 6.6: Advanced Game Systems Validation

**[VS-1] [Flow:F]**

**As a** player on macOS/Linux,
**I want** quests, pets, and PvP to work correctly,
**So that** all secondary gameplay systems function on all platforms.

**Story Points:** 3
**Priority:** P1 - Should Have
**Prerequisites:** 6.3 (combat works)
**Flow Code:** VS1-GAME-VALIDATE-SYSTEMS

#### Functional Acceptance Criteria

- [ ] **AC-1:** Quest UI opens and displays quest information
- [ ] **AC-2:** Pet companion follows player and can be managed
- [ ] **AC-3:** PvP targeting and combat works between players
- [ ] **AC-4:** Duel invitation and acceptance work

#### Standard Acceptance Criteria

- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `test(game): validate quests, pets, and PvP on macOS/Linux`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Quest and pet UI screenshots on macOS

---

### Story 6.7: UI Windows Comprehensive Validation

**[VS-1] [Flow:F]**

**As a** player on macOS/Linux,
**I want** all 84 UI windows to open, display, and function correctly,
**So that** no UI element is broken after the migration.

**Story Points:** 5
**Priority:** P0 - Must Have
**Prerequisites:** 6.1 (logged in), EPIC-4 (rendering), EPIC-2 (input)
**Flow Code:** VS1-GAME-VALIDATE-UI

#### Functional Acceptance Criteria

- [ ] **AC-1:** All 84 CNewUI* windows open without crashes on macOS and Linux
- [ ] **AC-2:** Window positioning, sizing, and layering correct
- [ ] **AC-3:** Button clicks, scroll bars, and list selections work (mouse input)
- [ ] **AC-4:** Window close/toggle behavior correct
- [ ] **AC-5:** Ground truth comparison for key UI windows (inventory, character info, skills, map, chat)

#### Standard Acceptance Criteria

- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `test(game): validate all 84 UI windows on macOS/Linux`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Ground truth SSIM comparison for 10+ key UI windows
- [ ] **AC-VAL-2:** Checklist of all 84 windows tested (open/close/interact)

---

### Epic 6 Story Dependency Graph

```
6.1 (Auth/Characters) ──► 6.2 (Navigation) ──► 6.3 (Combat) ──► 6.6 (Advanced Systems)
         │                                           │
         ├──► 6.4 (Inventory/Trading)                │
         ├──► 6.5 (Social)                           │
         └──► 6.7 (UI Windows)                       │
```

**Parallel Execution:** Stories 6.4, 6.5, 6.7 can run concurrently after 6.1. Story 6.6 requires 6.3.

**Critical Path:** 6.1 → 6.2 → 6.3 → 6.6 (12 points)

---

### Epic 6 Validation Criteria

Before proceeding to EPIC-7 (final stability), verify:

- [ ] All core gameplay systems work on macOS and Linux
- [ ] No gameplay regression on Windows
- [ ] All 84 UI windows function correctly
- [ ] Chat and social features work with correct encoding
- [ ] Showstopper bugs identified and tracked

---

## Epic 7: Stability, Diagnostics & Quality Gates

**[VS-0] [Flow:Enabler]**

> Implement cross-platform diagnostics, validate 60+ minute stability on macOS and Linux, establish native CI runners, and fix showstopper bugs blocking MVP.

### Epic Overview

| Attribute | Value |
|-----------|-------|
| Epic ID | EPIC-7 |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Type | Enabler Flow |
| Total Story Points | 24 |
| Prerequisites | EPIC-1 (partial, for early stories); EPIC-2–6 (for stability sessions) |
| PRD References | FR37–FR40, NFR1–NFR3, NFR15, NFR18 |
| Contributing Milestones | Architecture Phase 0 (diagnostics) + Phase 10 (stability) |

### Feature Map

| Feature | Stories | Points | Priority |
|---------|---------|--------|----------|
| 7.1–7.2 Diagnostics (Phase 0) | 2 | 6 | P0 |
| 7.3 Performance Instrumentation | 1 | 3 | P0 |
| 7.4–7.5 Stability Sessions | 2 | 8 | P0 |
| 7.6 Native CI | 1 | 3 | P1 |

**Note:** Stories 7.1–7.3 should be implemented during Phase 0 alongside EPIC-1. Stories 7.4–7.5 are end-of-migration validation. Story 7.6 is post-migration CI expansion.

---

### Story 7.1: Cross-Platform Error Reporting

**[VS-0] [Flow:E]**

**As a** developer,
**I want** `g_ErrorReport.Write()` to produce `MuError.log` on macOS and Linux,
**So that** I can diagnose issues on all platforms using the existing error reporting mechanism.

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** EPIC-1 (1.3 platform headers)
**Flow Code:** VS0-QUAL-ERRORREPORT-XPLAT

#### Functional Acceptance Criteria

- [ ] **AC-1:** `MuError.log` created in the game binary directory on macOS and Linux
- [ ] **AC-2:** `g_ErrorReport.Write()` formats and writes correctly on all platforms
- [ ] **AC-3:** File I/O uses `std::filesystem::path` and `std::ofstream` (not Win32 file APIs)
- [ ] **AC-4:** Log includes timestamp, domain prefix, and message
- [ ] **AC-5:** Existing Windows logging behavior unchanged

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-2:** Catch2 test: write log entry, verify file contents
- [ ] **AC-STD-3:** No Win32 file I/O APIs (CreateFile, WriteFile) in error reporting
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `refactor(core): cross-platform MuError.log via std::ofstream`

#### Validation Artifacts

- [ ] **AC-VAL-1:** MuError.log produced on macOS with correct content
- [ ] **AC-VAL-2:** MuError.log produced on Linux with correct content

---

### Story 7.2: POSIX Signal Handlers for Crash Diagnostics

**[VS-0] [Flow:E]**

**As a** developer,
**I want** POSIX signal handlers that write crash context to MuError.log on macOS/Linux,
**So that** crashes can be diagnosed without a debugger attached (Test Design R8).

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** 7.1 (error reporting works on POSIX)
**Flow Code:** VS0-QUAL-SIGNAL-HANDLERS

#### Functional Acceptance Criteria

- [ ] **AC-1:** SIGSEGV, SIGABRT, SIGBUS handlers installed at startup on macOS/Linux
- [ ] **AC-2:** Handler writes signal type, last error report context, and backtrace (if available) to MuError.log
- [ ] **AC-3:** Handler calls `_exit()` after writing (no re-entrant crash risk)
- [ ] **AC-4:** Existing Windows SEH/crash handling unchanged
- [ ] **AC-5:** Signal handler code lives in `MUPlatform/posix/`

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards
- [ ] **AC-STD-3:** Signal handler code only in MUPlatform/posix/ — no platform ifdefs in game logic
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-5:** Error logging: `PLAT: signal handler — caught {SIGSEGV/SIGABRT/SIGBUS}`
- [ ] **AC-STD-6:** Conventional commit: `feat(platform): add POSIX signal handlers for crash diagnostics`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Intentional crash (null pointer deref) produces diagnostic output in MuError.log on macOS

---

### Story 7.3: Frame Time Instrumentation

**[VS-0] [Flow:E]**

**As a** developer,
**I want** frame time measurement and variance logging,
**So that** I can validate NFR1–NFR3 performance requirements (30+ FPS, no >50ms hitches).

**Story Points:** 3
**Priority:** P0 - Must Have
**Prerequisites:** EPIC-1 (MUCore available)
**Flow Code:** VS0-QUAL-FRAMETIMER

#### Functional Acceptance Criteria

- [ ] **AC-1:** `mu::MuTimer` class in MUCore: `FrameStart()`, `FrameEnd()`, `GetFrameTimeMs()`, `GetFPS()`
- [ ] **AC-2:** Uses `std::chrono::steady_clock` (not `timeGetTime`)
- [ ] **AC-3:** Logs frame time variance and hitch count (>50ms frames) to MuError.log periodically
- [ ] **AC-4:** Provides running average FPS for display
- [ ] **AC-5:** Minimal overhead (<0.1ms per frame)

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code follows project-context.md standards (mu:: namespace)
- [ ] **AC-STD-2:** Catch2 tests: timer accuracy, hitch detection with simulated delays
- [ ] **AC-STD-4:** CI quality gate passes
- [ ] **AC-STD-6:** Conventional commit: `feat(core): add MuTimer frame time instrumentation`

#### Validation Artifacts

- [ ] **AC-VAL-1:** MuError.log shows frame time statistics after 5-minute session
- [ ] **AC-VAL-2:** FPS counter displays correct value

---

### Story 7.4: macOS 60-Minute Stability Session

**[VS-0] [Flow:E]**

**As a** player on macOS,
**I want** to play for 60+ minutes without crashes or disconnects,
**So that** macOS is validated as a stable gameplay platform.

**Story Points:** 5
**Priority:** P0 - Must Have
**Prerequisites:** EPIC-2–6 complete (full game functional on macOS)
**Flow Code:** VS0-QUAL-STABILITY-MACOS

#### Functional Acceptance Criteria

- [ ] **AC-1:** 60+ minute gameplay session completed on macOS without crashes
- [ ] **AC-2:** Session includes: login → world exploration (3+ maps) → combat → inventory → trading → chat → logout
- [ ] **AC-3:** No server disconnects during session
- [ ] **AC-4:** Frame time log shows sustained 30+ FPS with no >50ms hitches
- [ ] **AC-5:** MuError.log shows no ERROR-level entries during session
- [ ] **AC-6:** Memory usage stable (no leaks visible over 60 minutes)

#### Standard Acceptance Criteria

- [ ] **AC-STD-6:** Conventional commit: `test(platform): macOS 60-minute stability session passed`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Session log: timestamp, activities performed, FPS statistics
- [ ] **AC-VAL-2:** MuError.log from the session (attached or referenced)
- [ ] **AC-VAL-3:** Memory usage graph or snapshots (start vs end)

---

### Story 7.5: Linux 60-Minute Stability Session

**[VS-0] [Flow:E]**

**As a** player on Linux,
**I want** to play for 60+ minutes without crashes or disconnects,
**So that** Linux is validated as a stable gameplay platform.

**Story Points:** 5
**Priority:** P0 - Must Have
**Prerequisites:** EPIC-2–6 complete (full game functional on Linux)
**Flow Code:** VS0-QUAL-STABILITY-LINUX

#### Functional Acceptance Criteria

- [ ] **AC-1:** 60+ minute gameplay session completed on Linux without crashes
- [ ] **AC-2:** Session includes: login → world exploration (3+ maps) → combat → inventory → trading → chat → logout
- [ ] **AC-3:** No server disconnects during session
- [ ] **AC-4:** Frame time log shows sustained 30+ FPS with no >50ms hitches
- [ ] **AC-5:** MuError.log shows no ERROR-level entries
- [ ] **AC-6:** Memory usage stable

#### Standard Acceptance Criteria

- [ ] **AC-STD-6:** Conventional commit: `test(platform): Linux 60-minute stability session passed`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Session log with activities and FPS statistics
- [ ] **AC-VAL-2:** MuError.log from the session
- [ ] **AC-VAL-3:** Memory usage snapshots

---

### Story 7.6: Native Platform CI Runners

**[VS-0] [Flow:E]**

**As a** developer,
**I want** CI runners that build and test natively on macOS and Linux,
**So that** every push validates the codebase on all three platforms.

**Story Points:** 5
**Priority:** P1 - Should Have
**Prerequisites:** EPIC-4 complete (SDL_gpu rendering compiles on all platforms)
**Flow Code:** VS0-QUAL-CI-NATIVE

#### Functional Acceptance Criteria

- [ ] **AC-1:** GitHub Actions workflow adds `macos-latest` runner with Clang build
- [ ] **AC-2:** GitHub Actions workflow adds `ubuntu-latest` runner with GCC build
- [ ] **AC-3:** Both runners execute: CMake configure → build → Catch2 test suite
- [ ] **AC-4:** Quality gates (clang-format, cppcheck) run on all three platforms
- [ ] **AC-5:** Existing MinGW cross-compile job remains (regression safety net)
- [ ] **AC-6:** All three platform builds must pass for PR merge

#### Standard Acceptance Criteria

- [ ] **AC-STD-1:** CI config follows existing workflow patterns in `.github/workflows/ci.yml`
- [ ] **AC-STD-4:** All three CI jobs pass
- [ ] **AC-STD-6:** Conventional commit: `build(ci): add native macOS and Linux CI runners`

#### Validation Artifacts

- [ ] **AC-VAL-1:** Green CI run with all three platform jobs passing
- [ ] **AC-VAL-2:** Intentional failure (e.g., missing include) caught by native runners

---

### Epic 7 Story Dependency Graph

```
Phase 0 (early):
7.1 (Error Reporting) ──► 7.2 (Signal Handlers)
7.3 (Frame Timer) [independent]

Phase 10 (late):
7.4 (macOS Stability) [requires EPIC-2–6]
7.5 (Linux Stability) [requires EPIC-2–6]
7.6 (Native CI) [requires EPIC-4]
```

**Parallel Execution:** 7.1 and 7.3 can run concurrently. 7.4 and 7.5 can run concurrently. 7.6 is independent after EPIC-4.

**Critical Path:** 7.1 → 7.2 (6 points for Phase 0); 7.4 or 7.5 (5 points for Phase 10)

---

### Epic 7 Validation Criteria

MVP is complete when:

- [ ] 60+ minute stability sessions pass on macOS and Linux
- [ ] MuError.log works on all platforms with domain prefixes
- [ ] Crash diagnostics (signal handlers) produce useful output
- [ ] Frame time instrumentation confirms 30+ FPS sustained
- [ ] Native CI runners validate every push on all three platforms

---

## Epic Dependency Graph (Project Level)

```
EPIC-1 (Platform Foundation)
  ├──► EPIC-2 (Windowing & Input) ──┐
  │                                  ├──► EPIC-4 (Rendering) ──┐
  ├──► EPIC-3 (.NET AOT) ──────────┘                           │
  │                                                             ├──► EPIC-6 (Gameplay Validation) ──► EPIC-7.4/7.5 (Stability)
  ├──► EPIC-5 (Audio) ─────────────────────────────────────────┘
  │
  └──► EPIC-7.1–7.3 (Diagnostics — Phase 0, parallel with EPIC-1)
                                     EPIC-4 ──► EPIC-7.6 (Native CI)
```

**Phase Alignment:**
- **Phase 0:** EPIC-1 + EPIC-7 (7.1–7.3)
- **Phases 1–2:** EPIC-2
- **Phase 2.5:** EPIC-3
- **Phases 3–5:** EPIC-4
- **Phase 6:** EPIC-5
- **Phases 9–10:** EPIC-6 + EPIC-7 (7.4–7.6)

**Critical Path:** EPIC-1 → EPIC-2 → EPIC-4 → EPIC-6 → EPIC-7.4/7.5 (18 + 17 + 48 + 23 + 5 = 111 points)

**Parallel Opportunities:**
- EPIC-3 (.NET) can start after EPIC-1.4, parallel with EPIC-2
- EPIC-5 (Audio) can start after EPIC-1, parallel with EPIC-3/4
- EPIC-7.1–7.3 (Diagnostics) should start with EPIC-1 (Phase 0)

---

## Summary

| Metric | Value |
|--------|-------|
| Total Epics | 7 |
| Total Stories | 45 |
| Total Story Points | 172 |
| P0 Stories | 41 |
| P1 Stories | 4 |
| Critical Path Points | 111 |
| Enabler Epics | 2 (EPIC-1, EPIC-7) |
| Feature Epics | 5 (EPIC-2–6) |

### FR Coverage Summary

| FR Range | Description | Epic | Coverage |
|----------|-------------|------|----------|
| FR1–FR5 | Platform & Build | EPIC-1 | Complete |
| FR6–FR11 | Server Connectivity | EPIC-3 | Complete |
| FR12–FR16 | Rendering & Display | EPIC-2 (FR16), EPIC-4 (FR12–FR15) | Complete |
| FR17–FR19 | Audio | EPIC-5 | Complete |
| FR20–FR22 | Input | EPIC-2 | Complete |
| FR23–FR36 | Gameplay (Regression) | EPIC-6 | Complete |
| FR37–FR40 | Stability | EPIC-7 | Complete |

**All 40 FRs covered. All 18 NFRs addressed as cross-cutting concerns across epics.**

---

*Generated using BMAD create-epics-and-stories workflow with PCC SAFe customizations.*
*Adapted for C++20 game client project (not web API) — AC-STD sections reflect project-context.md standards.*
