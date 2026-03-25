# ATDD Checklist — Story 7.6.2: Win32 String Conversion and Include Guard Cleanup

**Story ID:** 7-6-2-win32-string-include-cleanup
**Flow Code:** VS0-QUAL-WIN32CLEAN-STRINCLUDE
**Story Type:** infrastructure
**Phase:** RED (tests created, implementation pending)
**Generated:** 2026-03-25

---

## PCC Compliance Summary

| Requirement | Status |
|-------------|--------|
| No prohibited libraries | ✅ Catch2 v3.7.1 only (approved) |
| Required test patterns | ✅ Catch2 `TEST_CASE`/`SECTION`/`REQUIRE`/`CHECK` |
| No Win32 API in tests | ✅ Tests use only PlatformCompat.h cross-platform shims |
| Test location | ✅ `MuMain/tests/platform/` (Catch2) + `MuMain/tests/build/` (CMake) |
| Coverage target | ✅ 0% threshold (growing incrementally per project-context.md) |
| Flow code traceability | ✅ `VS0-QUAL-WIN32CLEAN-STRINCLUDE` in all test files |

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Name |
|----|-------------|-----------|-----------|
| AC-1 | check-win32-guards.py exits 0 | `tests/build/test_ac1_win32_guard_check_7_6_2.cmake` | `7.6.2-AC-1:win32-guard-check-script` |
| AC-2 | muConsoleDebug.cpp uses mu_wchar_to_utf8 | `tests/build/test_ac2_console_debug_migration_7_6_2.cmake` + `tests/platform/test_win32_string_cleanup_7_6_2.cpp` | `7.6.2-AC-2:console-debug-migration` + `AC-2: mu_wchar_to_utf8 converts ASCII correctly` |
| AC-3 | StringUtils.h uses mu_wchar_to_utf8 | `tests/build/test_ac3_string_utils_migration_7_6_2.cmake` + `tests/platform/test_win32_string_cleanup_7_6_2.cpp` | `7.6.2-AC-3:string-utils-migration` + `AC-3: mu_wchar_to_utf8 handles Unicode BMP characters` |
| AC-4 | GlobalBitmap.cpp uses mu_wchar_to_utf8 | `tests/build/test_ac4_global_bitmap_migration_7_6_2.cmake` + `tests/platform/test_win32_string_cleanup_7_6_2.cpp` | `7.6.2-AC-4:global-bitmap-migration` + `AC-4: mu_wchar_to_utf8 replacement produces same output` |
| AC-5 | MsgBoxIGSBuyConfirm.cpp uses mu_swprintf | `tests/build/test_ac5_msgbox_swprintf_migration_7_6_2.cmake` + `tests/platform/test_win32_string_cleanup_7_6_2.cpp` | `7.6.2-AC-5:msgbox-swprintf-migration` + `AC-5: mu_swprintf formats integers correctly` |
| AC-6 | ZzzCharacter.cpp no <eh.h> | `tests/build/test_ac6_zzz_character_no_eh_7_6_2.cmake` | `7.6.2-AC-6:zzz-character-no-eh` |
| AC-7 | MuRendererSDLGpu.cpp SDL3 includes unconditional | `tests/build/test_ac7_sdl_gpu_unconditional_7_6_2.cmake` | `7.6.2-AC-7:sdl-gpu-unconditional-includes` |
| AC-8 | Scene headers have #else / PlatformCompat.h | `tests/build/test_ac8_scene_headers_else_branch_7_6_2.cmake` | `7.6.2-AC-8:scene-headers-else-branch` |
| AC-9 | Data headers have #else / PlatformCompat.h | `tests/build/test_ac9_data_headers_else_branch_7_6_2.cmake` | `7.6.2-AC-9:data-headers-else-branch` |
| AC-10 | ./ctl check passes | Quality gate (not a unit test) | Run `./ctl check` manually |
| AC-STD-1 | No new #ifdef _WIN32 outside Platform/ | `tests/build/test_ac1_win32_guard_check_7_6_2.cmake` | `7.6.2-AC-1:win32-guard-check-script` |
| AC-STD-2 | ./ctl test passes | Quality gate | Run `./ctl check` |
| AC-STD-11 | Flow code traceability | `tests/build/test_ac_std11_flow_code_7_6_2.cmake` | `7.6.2-AC-STD-11:flow-code-traceability` |
| AC-STD-13 | ./ctl check exits 0 | Quality gate | Run `./ctl check` |
| AC-STD-15 | Git safety | Operational | No force push, no incomplete rebase |

---

## Test Files Created (RED Phase)

### Catch2 Unit Tests (MuTests target)

**File:** `MuMain/tests/platform/test_win32_string_cleanup_7_6_2.cpp`

| Test Case | AC | Phase |
|-----------|-----|-------|
| `AC-2: mu_wchar_to_utf8 converts ASCII correctly` | AC-2 | 🟢 GREEN (shim already exists) |
| `AC-3: mu_wchar_to_utf8 handles Unicode BMP characters` | AC-3 | 🟢 GREEN (shim already exists) |
| `AC-4: mu_wchar_to_utf8 replacement produces same output as WideCharToMultiByte on Windows` | AC-4 | 🟢 GREEN (shim already exists) |
| `AC-5: mu_swprintf formats integers correctly` | AC-5 | 🟢 GREEN (shim already exists) |
| `AC-5: mu_swprintf_s safe variant` | AC-5 | 🟢 GREEN (shim already exists) |

> Note: Catch2 tests for mu_wchar_to_utf8 and mu_swprintf are GREEN immediately because the
> replacement functions are already implemented in PlatformCompat.h and stdafx.h. These tests
> serve as regression guards verifying the replacement functions work correctly before the
> Win32 call sites are migrated.

### CMake Script Tests (build test suite)

| File | AC | Phase |
|------|-----|-------|
| `tests/build/test_ac1_win32_guard_check_7_6_2.cmake` | AC-1 | 🔴 RED (fails until all tasks complete) |
| `tests/build/test_ac2_console_debug_migration_7_6_2.cmake` | AC-2 | 🔴 RED (fails until Task 1) |
| `tests/build/test_ac3_string_utils_migration_7_6_2.cmake` | AC-3 | 🔴 RED (fails until Task 2) |
| `tests/build/test_ac4_global_bitmap_migration_7_6_2.cmake` | AC-4 | 🔴 RED (fails until Task 3) |
| `tests/build/test_ac5_msgbox_swprintf_migration_7_6_2.cmake` | AC-5 | 🔴 RED (fails until Task 4) |
| `tests/build/test_ac6_zzz_character_no_eh_7_6_2.cmake` | AC-6 | 🔴 RED (fails until Task 5) |
| `tests/build/test_ac7_sdl_gpu_unconditional_7_6_2.cmake` | AC-7 | 🔴 RED (fails until Task 6) |
| `tests/build/test_ac8_scene_headers_else_branch_7_6_2.cmake` | AC-8 | 🔴 RED (fails until Task 7) |
| `tests/build/test_ac9_data_headers_else_branch_7_6_2.cmake` | AC-9 | 🔴 RED (fails until Task 8) |
| `tests/build/test_ac_std11_flow_code_7_6_2.cmake` | AC-STD-11 | 🟢 GREEN (flow codes present) |

---

## Implementation Checklist

All items start as `[ ]` (pending). Developer checks off each item as tasks are completed.

### Setup & Preparation

- [ ] Story 7-6-1 prerequisite verified complete (macOS native build compiles)
- [ ] `python3 MuMain/scripts/check-win32-guards.py` run on baseline — documents initial violations

### Task 1: Core/muConsoleDebug.cpp (AC-2)

- [ ] `1.1` Remove `#ifdef _WIN32 / #include <io.h> / #else / #include <unistd.h> / #endif` include-selection block
- [ ] `1.2` Replace `WideCharToMultiByte(CP_UTF8, ...)` call with `mu_wchar_to_utf8(src, ...)` from PlatformCompat.h
- [ ] `1.3` Verify no remaining `#ifdef _WIN32` code-wrapping blocks in the file
- [ ] `1.4` `./ctl check` passes after this task (format + lint clean)
- [ ] `AC-2 cmake test` passes: `7.6.2-AC-2:console-debug-migration`

### Task 2: Core/StringUtils.h (AC-3)

- [ ] `2.1` Replace `WideCharToMultiByte` with `mu_wchar_to_utf8()` call
- [ ] `2.2` Remove `windows.h` include-selection block if PlatformCompat.h is already included via stdafx.h
- [ ] `2.3` Verify no bare `#ifdef _WIN32` wrapping any utility function
- [ ] `2.4` `./ctl check` passes after this task
- [ ] `AC-3 cmake test` passes: `7.6.2-AC-3:string-utils-migration`

### Task 3: Data/GlobalBitmap.cpp (AC-4)

- [ ] `3.1` Replace `WideCharToMultiByte(CP_UTF8, ...)` block with `mu_wchar_to_utf8()` call
- [ ] `3.2` Remove `#ifdef _WIN32` wrapper around the WideCharToMultiByte call
- [ ] `3.3` `./ctl check` passes after this task
- [ ] `AC-4 cmake test` passes: `7.6.2-AC-4:global-bitmap-migration`

### Task 4: GameShop/MsgBoxIGSBuyConfirm.cpp (AC-5)

- [ ] `4.1` Remove `#ifdef _WIN32 / #include <strsafe.h> / #endif` include block
- [ ] `4.2` Replace `StringCbPrintf` / `StringCchPrintf` calls with `mu_swprintf` (from stdafx.h)
- [ ] `4.3` Remove any remaining `#ifdef _WIN32` call-site wrappers
- [ ] `4.4` `./ctl check` passes after this task
- [ ] `AC-5 cmake test` passes: `7.6.2-AC-5:msgbox-swprintf-migration`

### Task 5: Gameplay/Characters/ZzzCharacter.cpp (AC-6)

- [ ] `5.1` Remove `#ifdef _WIN32 / #include <eh.h> / #endif` block
- [ ] `5.2` Verify no `__try` / `__except` blocks remain outside a `#ifdef _WIN32` guard
- [ ] `5.3` `./ctl check` passes after this task
- [ ] `AC-6 cmake test` passes: `7.6.2-AC-6:zzz-character-no-eh`

### Task 6: RenderFX/MuRendererSDLGpu.cpp (AC-7)

- [ ] `6.1` Make SDL3 includes unconditional (`SDL3/SDL_gpu.h`, `SDL3/SDL.h`)
- [ ] `6.2` Remove `#ifdef MU_ENABLE_SDL3` wrapper around include block at top of file
- [ ] `6.3` Verify CMakeLists.txt already conditionally compiles this TU with `if(MU_ENABLE_SDL3)`
- [ ] `6.4` `./ctl check` passes after this task
- [ ] `AC-7 cmake test` passes: `7.6.2-AC-7:sdl-gpu-unconditional-includes`

### Task 7: Scene headers (AC-8)

- [ ] `7.1` `Scenes/CharacterScene.h` — verify `#ifdef _WIN32 / #include <windows.h> / #else / #include "PlatformCompat.h" / #endif` pattern complete
- [ ] `7.2` Same for `Scenes/LoginScene.h`
- [ ] `7.3` Same for `Scenes/MainScene.h`
- [ ] `7.4` Same for `Scenes/SceneManager.h`
- [ ] `7.5` Confirm no `#ifdef _WIN32` wraps any class members or method declarations
- [ ] `7.6` `./ctl check` passes after this task
- [ ] `AC-8 cmake test` passes: `7.6.2-AC-8:scene-headers-else-branch`

### Task 8: Data struct headers (AC-9)

- [ ] `8.1` `Data/Items/ItemStructs.h` — verify include-selection has `#else / #include "PlatformCompat.h"` branch
- [ ] `8.2` `Data/Skills/SkillStructs.h` — same
- [ ] `8.3` `./ctl check` passes after this task
- [ ] `AC-9 cmake test` passes: `7.6.2-AC-9:data-headers-else-branch`

### Task 9: Validate (AC-1, AC-10)

- [ ] `9.1` Run `python3 MuMain/scripts/check-win32-guards.py` — zero violations for all files in scope
- [ ] `9.2` Run `./ctl check` — exits 0 (anti-pattern check + macOS native build + format-check + cppcheck lint)
- [ ] `AC-1 cmake test` passes: `7.6.2-AC-1:win32-guard-check-script`
- [ ] `AC-STD-11 cmake test` passes: `7.6.2-AC-STD-11:flow-code-traceability`

### PCC Compliance Items

- [ ] No new `#ifdef _WIN32` introduced in game logic outside `Platform/`, `ThirdParty/`, `Audio/DSwaveIO*`
- [ ] All replacements use approved patterns from project-context.md (`mu_wchar_to_utf8`, `mu_swprintf`)
- [ ] clang-format clean (no whitespace or brace violations in changed files)
- [ ] cppcheck lint clean (no new warnings/errors in changed files)
- [ ] Catch2 tests compile and pass on macOS arm64 without Win32 or game loop
- [ ] CMake script tests registered in `tests/build/CMakeLists.txt` and pass under CTest

### Git Safety (AC-STD-15)

- [ ] No force push to main
- [ ] No incomplete rebase
- [ ] Commit messages follow Conventional Commits format (`refactor(build):`, `fix(platform):`, etc.)

---

## Notes

- **Infrastructure story**: No API, event, or navigation contracts introduced. No Bruno tests required.
- **Story type = infrastructure**: Unit + Integration test levels only (no E2E, no API collection).
- **Catch2 tests are GREEN immediately** because `mu_wchar_to_utf8` and `mu_swprintf` already exist in PlatformCompat.h and stdafx.h. They serve as regression guards.
- **CMake tests are RED** until each task removes the corresponding Win32 guard from the source file.
- **AC-10 and AC-STD-13** are quality gate checks (`./ctl check`) — not individual test files. The developer runs these after completing all tasks.
- **Fix Decision Tree** (from story dev notes): If removing a `#ifdef _WIN32` block causes a compile error → add a stub to `PlatformCompat.h`. Do NOT add a new `#ifdef _WIN32` call site.
