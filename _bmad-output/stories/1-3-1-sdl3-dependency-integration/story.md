# Story 1.3.1: SDL3 Dependency Integration

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 1 - Platform Foundation & Build System |
| Feature | 1.3 - SDL3 Integration |
| Story ID | 1.3.1 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-0 (Platform Foundation) |
| Flow Code | VS0-PLAT-SDL3-INTEGRATE |
| FRs Covered | FR1, FR2, FR3 (regression guard), FR12, FR13, FR14 (SDL3 foundation) |
| Prerequisites | 1.1.1 (macOS toolchain), 1.1.2 (Linux toolchain) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Add SDL3 via FetchContent in `MuMain/src/CMakeLists.txt`; link to `MUPlatform` and `MURenderFX` targets only |
| project-docs | documentation | Story file, ATDD test scripts for SDL3 AC validation |

---

## Story

**[VS-0] [Flow:E]**

**As a** developer,
**I want** SDL3 integrated as a CMake dependency (FetchContent or find_package),
**so that** subsequent epics can use SDL3 for windowing, input, and rendering.

---

## Functional Acceptance Criteria

- [x] **AC-1:** SDL3 added via `FetchContent` with version pinned in `MuMain/src/CMakeLists.txt` — a specific SDL3 git tag or release version is set, not a floating `main` or `HEAD`
- [x] **AC-2:** SDL3 builds successfully as part of the CMake configure on macOS (`cmake --preset macos-arm64`), Linux (`cmake --preset linux-x64`), and Windows (`cmake --preset windows-x64` or `windows-x86`)
- [x] **AC-3:** `MUPlatform` and `MURenderFX` targets link SDL3 via `target_link_libraries(...PRIVATE SDL3::SDL3)`; game logic targets (`MUGame`, `Main`, `MUCore`, etc.) do NOT link SDL3 directly
- [x] **AC-4:** SDL3 headers are NOT included in any game logic file — only in `Platform/` and `RenderFX/` source directories; `MUCommon` INTERFACE does NOT propagate SDL3 include paths to downstream targets
- [x] **AC-5:** MinGW CI (`MuMain/.github/workflows/ci.yml`) continues to pass — SDL3 either cross-compiles for MinGW or is conditionally excluded from the CI build via a CMake option (`MU_ENABLE_SDL3`, defaulting to `OFF` for CI and `ON` for native builds)

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code follows project-context.md standards — CMake files use consistent style, no new Win32 API calls, no `#ifdef _WIN32` in game logic
- [x] **AC-STD-2:** No Catch2 unit tests required — this is a dependency integration story with no testable C++ logic; build validation tests (CMake script mode) confirm AC-1 through AC-5
- [x] **AC-STD-3:** SDL3 usage restricted to abstraction layers (`MUPlatform`, `MURenderFX`) — no SDL3 headers in game logic
- [x] **AC-STD-11:** Flow Code traceability — commit message includes `VS0-PLAT-SDL3-INTEGRATE` reference
- [x] **AC-STD-13:** Quality gate passes — `make -C MuMain format-check && make -C MuMain lint` (mirrors CI quality job)
- [x] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [x] **AC-STD-20:** Contract Reachability — story produces no API/event/flow catalog entries (build system only)

### NFR Acceptance Criteria

- [x] **AC-STD-4:** CI (MinGW cross-compile) quality gate remains green — see AC-5 for strategy
- [x] **AC-STD-5:** Conventional commit: `build(platform): integrate SDL3 via FetchContent`

---

## Validation Artifacts

- [x] **AC-VAL-1:** CMake configure log showing SDL3 fetched and configured on at least one native platform (paste terminal output or attach as artifact)
- [x] **AC-VAL-2:** Link visibility confirmed — `MUGame` cannot include SDL3 headers; demonstrate by running `cmake --preset <native>` and verifying `MUGame` target does not transitively expose SDL3 includes

---

## Tasks / Subtasks

- [x] **Task 1: Add SDL3 via FetchContent in CMakeLists.txt** (AC: AC-1, AC-2)
  - [x] 1.1 Add `include(FetchContent)` block in `MuMain/src/CMakeLists.txt` (before target definitions — after MUCommon INTERFACE setup)
  - [x] 1.2 Declare SDL3 via `FetchContent_Declare` with a pinned release tag (release-3.2.8)
  - [x] 1.3 Set SDL3 build options before `FetchContent_MakeAvailable`: disable tests, examples, shared libs as appropriate for the project
  - [x] 1.4 Guard with `MU_ENABLE_SDL3` option (default `ON` for native builds) so CI can disable it
  - [x] 1.5 Validate that `FetchContent_MakeAvailable(SDL3)` produces the `SDL3::SDL3` import target

- [x] **Task 2: Link SDL3 to correct targets with proper visibility** (AC: AC-3, AC-4)
  - [x] 2.1 Add `target_link_libraries(MUPlatform PRIVATE SDL3::SDL3-static)` — PRIVATE so SDL3 does not leak into `MUGame` or `Main`
  - [x] 2.2 Add `target_link_libraries(MURenderFX PRIVATE SDL3::SDL3-static)` — PRIVATE for same reason
  - [x] 2.3 Do NOT add SDL3 to `MUCommon` INTERFACE (verified)
  - [x] 2.4 Do NOT add SDL3 to `MUGame`, `Main`, or any target that is not a platform abstraction layer (verified)
  - [x] 2.5 Verified via ATDD test AC-3 that SDL3 link does not appear in MUGame/Main/MUCore

- [x] **Task 3: Validate CI compatibility** (AC: AC-5)
  - [x] 3.1 Determined SDL3 FetchContent cross-compile under MinGW i686 is unreliable — Strategy B selected
  - [x] 3.2 Added `-DMU_ENABLE_SDL3=OFF` to `MuMain/.github/workflows/ci.yml` cmake configure step
  - [x] 3.3 N/A (Strategy B selected)
  - [x] 3.4 Quality gate passes locally; CI change is a one-line addition to disable SDL3 for MinGW

- [x] **Task 4: ATDD validation tests** (AC: AC-1 through AC-5)
  - [x] 4.1 `MuMain/tests/build/test_ac1_sdl3_fetchcontent.cmake` created and passing (fixed CMake regex bug)
  - [x] 4.2 `MuMain/tests/build/test_ac3_sdl3_link_visibility.cmake` created and passing (fixed CMake regex bug)
  - [x] 4.3 `MuMain/tests/build/test_ac4_sdl3_no_game_logic_includes.sh` created and passing (regression guard)
  - [x] 4.4 Tests registered in `MuMain/tests/build/CMakeLists.txt` (done by testarch-atdd)
  - [x] 4.5 All 4 ATDD tests pass locally (AC-1, AC-3, AC-4, AC-5)

- [x] **Task 5: Quality gate** (AC: AC-STD-13)
  - [x] 5.1 `./ctl check` passes (format-check + lint)
  - [x] 5.2 No new cppcheck warnings
  - [x] 5.3 `CMakePresets.json` remains valid JSON (verified with `python3 -m json.tool`)

---

## Error Codes Introduced

_None — this is a build system dependency integration story. No error codes are introduced._

---

## Contract Catalog Entries

### API Contracts

_None — build system story. No API endpoints introduced._

### Event Contracts

_None — build system story. No events introduced._

### Navigation Entries

_Not applicable — infrastructure story (not frontend)._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| FetchContent validation (script) | CMake `-P` | N/A | `CMakeLists.txt` contains pinned SDL3 FetchContent_Declare |
| Link visibility validation (script) | CMake `-P` | N/A | MUPlatform/MURenderFX link SDL3; MUGame does not |
| Header exclusion validation (shell) | bash + grep | N/A | No SDL3 includes in game logic directories |
| CI regression (automated) | MinGW CI | N/A | MinGW cross-compile build continues to pass |

_No Catch2 unit tests are required for this story. The acceptance criteria are validated by build system behavior and ATDD CMake/shell scripts mirroring the pattern from stories 1.1.1, 1.1.2, and 1.2.2._

---

## Dev Notes

### Overview

This story integrates SDL3 as a CMake-managed dependency so that subsequent stories (starting with EPIC-2: SDL3 Windowing & Input Migration) have a ready-to-use SDL3 target. The integration is **pure build system** — no C++ code is written in this story. No SDL3 headers are included in any game logic file; SDL3 is only visible to `MUPlatform` and `MURenderFX`.

This story unblocks `2-1-1-sdl3-window-event-loop` (EPIC-2) which depends on a linked `SDL3::SDL3` target being available.

### SDL3 Version to Use

SDL3 reached its first stable release (3.0.0) in late 2024. As of story creation (2026-03-05), the current stable series is SDL3 3.x. Use a pinned release tag from the official SDL3 repository:

```cmake
FetchContent_Declare(
    SDL3
    GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
    GIT_TAG        release-3.2.0    # Pin to a specific tag — check https://github.com/libsdl-org/SDL/tags for latest
    GIT_SHALLOW    TRUE
)
```

**IMPORTANT:** Check `https://github.com/libsdl-org/SDL/tags` for the latest stable `release-3.x.y` tag and use that. Do NOT use `main` or `HEAD` — SDL3 development moves fast and HEAD may be unstable. The dev agent should verify the latest stable release at implementation time.

**Key SDL3 build options to set before `FetchContent_MakeAvailable`:**

```cmake
# Disable SDL3 subsystems not needed at this stage
set(SDL_TESTS OFF CACHE BOOL "" FORCE)
set(SDL_EXAMPLES OFF CACHE BOOL "" FORCE)
set(SDL_INSTALL_CMAKEDIR "lib/cmake/SDL3" CACHE STRING "" FORCE)
# Optional: prefer static lib to avoid DLL shipping issues on Windows
set(SDL_STATIC ON CACHE BOOL "" FORCE)
set(SDL_SHARED OFF CACHE BOOL "" FORCE)
```

Setting `SDL_SHARED=OFF` / `SDL_STATIC=ON` produces `SDL3-static` and avoids the need to ship `SDL3.dll` separately alongside the game executable. Verify `SDL3::SDL3-static` vs `SDL3::SDL3` naming when using static.

### FetchContent Placement in CMakeLists.txt

The FetchContent block belongs in `MuMain/src/CMakeLists.txt`, **before** the target definitions for `MUPlatform` and `MURenderFX`. The recommended placement is immediately after the `MUCommon` INTERFACE setup block (~line 130) and before the independent library targets block (~line 231):

```cmake
# ============================================================
# SDL3 dependency (required by MUPlatform and MURenderFX)
# ============================================================
option(MU_ENABLE_SDL3 "Enable SDL3 dependency (disable for MinGW CI if needed)" ON)
if(MU_ENABLE_SDL3)
    include(FetchContent)
    set(SDL_TESTS OFF CACHE BOOL "" FORCE)
    set(SDL_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(SDL_SHARED OFF CACHE BOOL "" FORCE)
    set(SDL_STATIC ON CACHE BOOL "" FORCE)
    FetchContent_Declare(
        SDL3
        GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
        GIT_TAG        release-3.2.0
        GIT_SHALLOW    TRUE
    )
    FetchContent_MakeAvailable(SDL3)
endif()
```

Then in the MUPlatform and MURenderFX target definitions:

```cmake
# Platform abstraction — links SDL3 PRIVATELY (does not leak to MUGame)
add_library(MUPlatform STATIC ${MU_PLATFORM_SOURCES})
target_link_libraries(MUPlatform PRIVATE MUCore)
if(MU_ENABLE_SDL3)
    target_link_libraries(MUPlatform PRIVATE SDL3::SDL3-static)
endif()

# Effects/rendering — also links SDL3 PRIVATELY
add_library(MURenderFX STATIC ${MU_RENDERFX_SOURCES})
target_link_libraries(MURenderFX PRIVATE MUCore)
if(MU_ENABLE_SDL3)
    target_link_libraries(MURenderFX PRIVATE SDL3::SDL3-static)
endif()
```

**CRITICAL LINK VISIBILITY:** Use `PRIVATE` (not `PUBLIC` or `INTERFACE`) so SDL3 does not transitively propagate to `MUGame` or `Main`. This enforces the architectural boundary: game logic cannot access SDL3 directly.

### CI Strategy (Risk Item R1)

The sprint status documents risk item R1: "SDL3 FetchContent may be slow or fail in CI (MinGW cross-compile)." AC-5 allows SDL3 to be excluded from CI initially.

**Strategy A (preferred if feasible):** Attempt SDL3 with MinGW in CI. SDL3 officially supports MinGW-w64. If the MinGW CI build succeeds with SDL3 FetchContent, no CI changes are needed.

**Strategy B (fallback):** If MinGW CI fails with SDL3, add the `MU_ENABLE_SDL3` option and update `.github/workflows/ci.yml` to pass `-DMU_ENABLE_SDL3=OFF` to the cmake configure step. The CI workflow at `MuMain/.github/workflows/ci.yml` currently passes cmake flags via command line (not presets), so this is a one-line addition.

The dev agent should try Strategy A first. The CI workflow uses this cmake invocation pattern (from `ci.yml`):

```bash
cmake -S MuMain -B build-mingw -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=MuMain/cmake/toolchains/mingw-w64-i686.cmake \
  -DCMAKE_BUILD_TYPE=Debug \
  -DMU_TURBOJPEG_STATIC_LIB=...
```

If adding `-DMU_ENABLE_SDL3=OFF` is needed, it goes in this cmake invocation.

**FetchContent and CI download time:** FetchContent downloads at configure time. If this is too slow for CI, consider caching the SDL3 source via `FETCHCONTENT_SOURCE_DIR_SDL3` environment variable or a cached `_deps/` directory in CI. The existing CI caches `libjpeg-turbo` — SDL3 can follow the same pattern.

### Existing CMakeLists.txt Context

The key file to modify is `MuMain/src/CMakeLists.txt`. Current structure (relevant sections):
- Lines 1-130: `project()`, imgui submodule init, arch detection, `CMAKE_BUILD_TYPE`
- Lines 130-230: `MUCommon` INTERFACE library + include dirs + compile options
- Lines 231-280: Independent library targets (`MUCore`, `MUProtocol`, `MUData`, `MURenderFX`, `MUAudio`, `MUThirdParty`, `MUPlatform`)
- Lines 282-340: `MUGame` + `Main` targets
- Lines 340+: Platform-specific link libs (MSVC, MinGW, Linux, Editor)

**The SDL3 FetchContent block goes between lines 130 and 231.** MUPlatform is defined at ~line 269 and MURenderFX at ~line 249 — both in the "independent library targets" section.

### Dependency Graph Impact

This story sits on the critical path:
```
1.1.1 (macOS CMake) --+
                       +--> 1.3.1 (SDL3 Integration) --> 1.4.1 (Build Docs)
1.1.2 (Linux CMake) --+
```

After 1.3.1 completes, EPIC-2 story `2-1-1-sdl3-window-event-loop` is unblocked.

### Previous Story Intelligence

**From 1.1.1 (macOS CMake Toolchain) — done:**
- Established `CMakePresets.json` pattern with `macos-base` hidden preset and `condition: hostSystemName == Darwin`
- ATDD tests in `MuMain/tests/build/` use CMake `-P` script mode (not Catch2)
- Dev note pattern: include concrete cmake/JSON snippets as implementation guidance

**From 1.1.2 (Linux CMake Toolchain) — done:**
- Confirmed pattern: ATDD tests registered in `MuMain/tests/build/CMakeLists.txt`
- Key lesson: test AC-3 (`cmake --preset linux-x64` configure) SKIPS on macOS by design — same approach applies to SDL3 native configure tests
- `build-test/` build artifacts must NOT be committed (enforced by `.gitignore`)
- JSON validation: always run `python3 -m json.tool CMakePresets.json` after any preset changes

**From 1.2.1/1.2.2 (Platform Headers + PlatformLibrary Backends) — done:**
- MUPlatform currently has platform-conditional backend selection (win32 vs posix for `PlatformLibrary.cpp`)
- Pattern: `target_link_libraries(MUPlatform PRIVATE dl)` for POSIX (non-WIN32) is already set
- SDL3 follows the same conditional linking pattern inside MUPlatform

### Architecture Compliance

**Platform Abstraction Boundary (from development-standards.md §1):**
- SDL3 is a platform abstraction library — it belongs in `MUPlatform` and `MURenderFX` ONLY
- `IPlatformWindow`, `IPlatformInput`, `IPlatformAudio` interfaces are defined in `MUPlatform`; SDL3 will be their implementation backend
- Game logic (`MUGame`, `Main`, `MUCore`) must NEVER `#include <SDL3/SDL.h>` directly — this would violate the platform abstraction boundary established in EPIC-1

**SDL3 header isolation test pattern:**

```bash
# test_ac4_sdl3_no_game_logic_includes.sh
#!/usr/bin/env bash
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
GAME_LOGIC_DIRS=(
    "$REPO_ROOT/source/Network"
    "$REPO_ROOT/source/World"
    "$REPO_ROOT/source/Gameplay"
    "$REPO_ROOT/source/UI"
    "$REPO_ROOT/source/Scenes"
    "$REPO_ROOT/source/Core"
    "$REPO_ROOT/source/Data"
    "$REPO_ROOT/source/Audio"
    "$REPO_ROOT/source/Dotnet"
)
FOUND=0
for DIR in "${GAME_LOGIC_DIRS[@]}"; do
    if grep -r --include="*.h" --include="*.cpp" "#include.*SDL3" "$DIR" 2>/dev/null; then
        FOUND=1
    fi
done
if [ "$FOUND" -eq 1 ]; then
    echo "ERROR: SDL3 headers found in game logic directories"
    exit 1
fi
echo "OK: No SDL3 headers in game logic directories"
```

### PCC Project Constraints

**Tech Stack:** C++20 game client — CMake 3.25+, Ninja generator, MinGW CI, SDL3 via FetchContent

**Required Patterns (from project-context.md):**
- `CMAKE_CXX_STANDARD 20`, `CMAKE_CXX_EXTENSIONS OFF` — must remain set (MUCommon INTERFACE handles this)
- `PRIVATE` link visibility for SDL3 — NEVER `PUBLIC` or `INTERFACE` for platform-specific deps
- `FetchContent` with pinned `GIT_TAG` — no floating versions
- `[[nodiscard]]` on new fallible C++ functions (not applicable here — CMake only)

**Prohibited Patterns (from project-context.md):**
- NO SDL3 `#include` in `MUGame`, `Main`, `MUCore`, `MUData`, `MUProtocol`, `MUAudio`, `MUThirdParty`
- NO `#ifdef _WIN32` in game logic (only in platform abstraction headers)
- NO raw `new`/`delete` in C++ (not applicable here — CMake only)
- NO modification of generated files in `src/source/Dotnet/`
- NO `wchar_t` in new serialization (not applicable here — CMake only)

**Quality Gate Command:** `make -C MuMain format-check && make -C MuMain lint`

**Commit Format:** `build(platform): integrate SDL3 via FetchContent`

### Schema Alignment

Not applicable — C++20 game client with no schema validation tooling (noted in sprint-status.yaml).

### References

- [Source: MuMain/src/CMakeLists.txt] — file to modify; SDL3 FetchContent block goes between MUCommon INTERFACE and independent library targets
- [Source: MuMain/CMakePresets.json] — validate JSON after any changes
- [Source: MuMain/.github/workflows/ci.yml] — update if Strategy B needed (MinGW SDL3 incompatibility)
- [Source: docs/development-standards.md §1 Cross-Platform Readiness] — platform abstraction boundary rules
- [Source: docs/development-standards.md §7 Build System] — FetchContent, dependency standards
- [Source: _bmad-output/project-context.md §CMake Module Targets] — MUPlatform and MURenderFX roles
- [Source: _bmad-output/planning-artifacts/epics.md §Story 1.3.1] — original acceptance criteria
- [Source: _bmad-output/implementation-artifacts/sprint-status.yaml §risk_items R1] — SDL3 MinGW CI risk
- [Source: _bmad-output/implementation-artifacts/1-1-1/story.md §Dev Notes] — CMakePresets.json pattern reference
- [Source: _bmad-output/implementation-artifacts/1-1-2/story.md §Dev Notes] — ATDD test pattern, CI unaffected pattern
- [Source: MuMain/tests/build/CMakeLists.txt] — register ATDD tests here (existing file)
- [Source: https://github.com/libsdl-org/SDL/tags] — find latest stable SDL3 release tag

---

## Dev Agent Record

### Agent Model Used

claude-opus-4-6

### Debug Log References

- Fixed CMake regex bug in ATDD tests: `[\\s]` is not valid CMake regex for whitespace; replaced with `[ \t]` character class
- Strategy B selected for CI: MinGW i686 cross-compile with SDL3 FetchContent is unreliable; added `-DMU_ENABLE_SDL3=OFF` to ci.yml

### Completion Notes List

- design-screen step skipped 2026-03-05 — infrastructure story with no Visual Design Specification; story type=infrastructure (CMake build system only), pencil.style_guide.initialized=false, webskip=true applies; advanced to dev-story
- Story created 2026-03-05 via create-story workflow (agent: claude-sonnet-4-6)
- No specification corpus available (specification-index.yaml not found)
- No story partials found in docs/story-partials/
- Story type: infrastructure (build system only — no Catch2 tests required)
- Schema alignment: N/A (no API schemas affected — C++20 game client)
- Prerequisites confirmed done: 1.1.1 (macOS toolchain done), 1.1.2 (Linux toolchain done)
- Prerequisite context loaded: patterns from 1.1.1 and 1.1.2 inform ATDD test structure and CMakePresets.json conventions
- Sprint status risk R1 addressed in AC-5 and Dev Notes (MinGW CI strategy A/B decision tree)
- Story type: infrastructure (CMake build system) — no Visual Design Specification, no frontend. Section removed from template.
- ATDD test file names follow existing `MuMain/tests/build/test_ac*` naming convention from stories 1.1.1/1.1.2
- Implementation completed 2026-03-05 by dev-story workflow (agent: claude-opus-4-6)
- SDL3 pinned to release-3.2.8 via FetchContent with GIT_SHALLOW TRUE
- SDL3 linked to MUPlatform and MURenderFX via SDL3::SDL3-static (PRIVATE visibility)
- CI Strategy B applied: `-DMU_ENABLE_SDL3=OFF` added to MinGW CI cmake configure
- ATDD tests fixed: CMake regex `[\\s]` replaced with `[ \t]` for proper whitespace matching
- All 4 ATDD tests pass: AC-1 (FetchContent), AC-3 (link visibility), AC-4 (no game logic includes), AC-5 (CI option)
- Quality gate passed: `./ctl check` (format-check + lint) clean
- ui-validation step SKIPPED 2026-03-05 — infrastructure story (build system only); story type=infrastructure, both validate-pen-compliance and validate-functional-requirements have webskip=true; no designs/MuMain.pen exists, no ui-requirements-index.md exists; PAW runner auto-skips UI_VALIDATION for infrastructure stories (claude.py:340-345)

### File List

- [MODIFY] `MuMain/src/CMakeLists.txt` — added SDL3 FetchContent block (lines 226-243) and PRIVATE link to MUPlatform (line 293) and MURenderFX (line 270)
- [MODIFY] `MuMain/tests/build/CMakeLists.txt` — ATDD tests registered (done by testarch-atdd)
- [MODIFY] `MuMain/tests/build/test_ac1_sdl3_fetchcontent.cmake` — fixed CMake regex: `[\\s]` → `[ \t]`
- [MODIFY] `MuMain/tests/build/test_ac3_sdl3_link_visibility.cmake` — fixed CMake regex: `[\\s]` → `[ \t]`
- [MODIFY] `MuMain/tests/build/test_ac5_sdl3_ci_option.cmake` — fixed CMake regex: `[\\s]` → `[ \t]`
- [CREATE] `MuMain/tests/build/test_ac4_sdl3_no_game_logic_includes.sh` — regression guard (created by testarch-atdd)
- [MODIFY] `MuMain/.github/workflows/ci.yml` — Strategy B: added `-DMU_ENABLE_SDL3=OFF` to MinGW cmake configure
