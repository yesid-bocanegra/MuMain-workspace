# ATDD Implementation Checklist -- Story 1.3.1: SDL3 Dependency Integration

**Story ID:** 1.3.1
**Story Type:** infrastructure
**Date:** 2026-03-05
**Primary Test Level:** Build system validation (CMake script mode + shell scripts)

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Name | Status |
|----|-------------|-----------|-----------|--------|
| AC-1 | SDL3 FetchContent with pinned version | `test_ac1_sdl3_fetchcontent.cmake` | `1.3.1-AC-1:sdl3-fetchcontent` | GREEN |
| AC-2 | SDL3 builds on macOS/Linux/Windows | (validated by native configure -- no separate test) | N/A | GREEN |
| AC-3 | MUPlatform/MURenderFX link SDL3 PRIVATE; game logic does not | `test_ac3_sdl3_link_visibility.cmake` | `1.3.1-AC-3:sdl3-link-visibility` | GREEN |
| AC-4 | SDL3 headers not in game logic | `test_ac4_sdl3_no_game_logic_includes.sh` | `1.3.1-AC-4:sdl3-no-game-logic-includes` | GREEN |
| AC-5 | MinGW CI passes with MU_ENABLE_SDL3 option | `test_ac5_sdl3_ci_option.cmake` | `1.3.1-AC-5:sdl3-ci-option` | GREEN |

---

## Implementation Checklist

### Task 1: Add SDL3 via FetchContent

- [x] 1.1 Add `include(FetchContent)` block in `MuMain/src/CMakeLists.txt`
- [x] 1.2 Declare SDL3 via `FetchContent_Declare` with pinned release tag (release-3.2.8)
- [x] 1.3 Set SDL3 build options (SDL_TESTS OFF, SDL_EXAMPLES OFF, SDL_SHARED OFF, SDL_STATIC ON)
- [x] 1.4 Guard with `MU_ENABLE_SDL3` option (default ON)
- [x] 1.5 Call `FetchContent_MakeAvailable(SDL3)` to produce SDL3::SDL3 target

### Task 2: Link SDL3 with correct visibility

- [x] 2.1 `target_link_libraries(MUPlatform PRIVATE SDL3::SDL3-static)` inside `if(MU_ENABLE_SDL3)`
- [x] 2.2 `target_link_libraries(MURenderFX PRIVATE SDL3::SDL3-static)` inside `if(MU_ENABLE_SDL3)`
- [x] 2.3 Verify MUCommon INTERFACE does NOT reference SDL3
- [x] 2.4 Verify MUGame, Main, MUCore do NOT link SDL3
- [x] 2.5 Verify PRIVATE visibility (not PUBLIC/INTERFACE)

### Task 3: CI compatibility

- [x] 3.1 Strategy B selected: MinGW i686 cross-compile with SDL3 unreliable
- [x] 3.2 Added `-DMU_ENABLE_SDL3=OFF` to CI cmake invocation
- [x] 3.3 Quality gate passes locally; CI change verified

### Task 4: ATDD validation tests

- [x] 4.1 `test_ac1_sdl3_fetchcontent.cmake` created and registered
- [x] 4.2 `test_ac3_sdl3_link_visibility.cmake` created and registered
- [x] 4.3 `test_ac4_sdl3_no_game_logic_includes.sh` created and registered
- [x] 4.4 `test_ac5_sdl3_ci_option.cmake` created and registered
- [x] 4.5 Tests registered in `MuMain/tests/build/CMakeLists.txt`
- [x] 4.6 AC-1, AC-3, AC-5 tests confirmed GREEN after implementation
- [x] 4.7 AC-4 regression guard confirmed passing

### Task 5: Quality gate

- [x] 5.1 `./ctl check` passes (format-check + lint)
- [x] 5.2 `CMakePresets.json` remains valid JSON
- [x] 5.3 No new cppcheck warnings

### PCC Compliance

- [x] No prohibited libraries used
- [x] CMake style follows project conventions (Allman braces in C++ code, consistent indentation)
- [x] PRIVATE link visibility enforced for SDL3 (no PUBLIC/INTERFACE leakage)
- [x] FetchContent uses pinned GIT_TAG (release-3.2.8, no floating main/HEAD)
- [x] Platform abstraction boundary maintained (SDL3 only in MUPlatform + MURenderFX)
- [x] No `#ifdef _WIN32` in game logic
- [x] Conventional commit format: `build(platform): integrate SDL3 via FetchContent`

---

## Test Files Created

| File | Type | Purpose |
|------|------|---------|
| `MuMain/tests/build/test_ac1_sdl3_fetchcontent.cmake` | CMake script | Validates FetchContent_Declare with pinned SDL3 tag |
| `MuMain/tests/build/test_ac3_sdl3_link_visibility.cmake` | CMake script | Validates MUPlatform/MURenderFX link SDL3 PRIVATE; MUGame does not |
| `MuMain/tests/build/test_ac4_sdl3_no_game_logic_includes.sh` | Shell script | Regression guard: no SDL3 headers in game logic dirs |
| `MuMain/tests/build/test_ac5_sdl3_ci_option.cmake` | CMake script | Validates MU_ENABLE_SDL3 option with guard blocks |
| `MuMain/tests/build/CMakeLists.txt` | CMake | Updated to register all 1.3.1 ATDD tests |

---

## PCC Compliance Summary

| Check | Status |
|-------|--------|
| Prohibited libraries | PASS -- no prohibited libraries in story |
| Required testing patterns | PASS -- CMake script mode + shell scripts (matching 1.1.1/1.1.2 pattern) |
| Test profiles | N/A -- infrastructure story |
| Coverage target | N/A -- no Catch2 unit tests (build system validation only) |
| Platform abstraction | PASS -- SDL3 confined to MUPlatform + MURenderFX |
| Conventional commits | PASS -- `build(platform): integrate SDL3 via FetchContent` |
