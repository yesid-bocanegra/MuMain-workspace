# ATDD Checklist — Story 7.3.0: macOS Native Build Compatibility Fixes

**Story Key:** 7-3-0
**Story Type:** infrastructure
**Flow Code:** VS0-QUAL-BUILDCOMPAT-MACOS
**Generated:** 2026-03-24
**Phase:** RED — tests registered; implementation pending

---

## PCC Compliance Summary

| Check | Status | Detail |
|-------|--------|--------|
| Prohibited libraries | PASS | No prohibited libraries referenced |
| Testing framework | PASS | Catch2 v3.7.1 (cmake script tests for build/infra ACs) |
| Test patterns | PASS | CMake `-P` script tests (established infra pattern), Catch2 for unit |
| AC-STD-2 constraint | NOTED | Story explicitly says "No new Catch2 tests required" — cmake script tests are used instead |
| Coverage target | N/A | Coverage threshold: 0 (project-wide, not applicable to cmake tests) |
| Platform rule | PASS | No new `#ifdef _WIN32` in game logic files per AC-STD-1 |

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Type | Phase |
|----|-------------|-----------|-----------|-------|
| AC-1 | cmake build exits 0 with 0 errors on macOS arm64 | `tests/build/test_ac3_macos_configure.sh` (existing) | Shell/CI | RED |
| AC-2 | `add_compile_definitions(MU_ENABLE_SDL3)` at project scope | `tests/build/test_ac2_cmake_mu_enable_sdl3_7_3_0.cmake` | CMake script | RED |
| AC-3 | `CONST` and `CP_UTF8` defined in PlatformTypes.h non-Win32 section | `tests/build/test_ac3_platform_types_const_cp_utf8.cmake` | CMake script | RED |
| AC-4 | `_wcsicmp`/`wcsicmp`, `_TRUNCATE`, `OutputDebugString` in PlatformCompat.h | `tests/build/test_ac4_platform_compat_wcsicmp_stubs.cmake` | CMake script | RED |
| AC-5 | NarrowPath uses `mu_wchar_to_utf8`, no `wstring_convert` | `tests/build/test_ac5_globalbitmaps_no_wstring_convert.cmake` | CMake script | RED |
| AC-6 | GL constants as numeric literals (`0x812Fu`/`0x2901u`) | `tests/build/test_ac6_globalbitmaps_gl_literals.cmake` | CMake script | RED |
| AC-7 | No `#include <shlwapi.h>` in LoadData.cpp | `tests/build/test_ac7_loaddata_no_shlwapi.cmake` | CMake script | RED |
| AC-8 | DPAPI calls guarded by `#ifdef _WIN32` with non-Win32 stubs | `tests/build/test_ac8_gameconfig_dpapi_guarded.cmake` | CMake script | RED |
| AC-9 | MinGW CI build remains green — no new Win32 guards in game logic | `tests/build/test_ac9_mingw_no_regression_7_3_0.cmake` | CMake script | RED |
| AC-STD-1 | No new `#ifdef _WIN32` in game logic (only Platform/ headers) | Covered by AC-9 regression test | CMake script | RED |
| AC-STD-2 | No new Catch2 tests required (build-system wiring fix) | N/A — constraint honored | — | N/A |
| AC-STD-11 | Flow code `VS0-QUAL-BUILDCOMPAT-MACOS` in commit + test files | `tests/build/test_ac_std11_flow_code_7_3_0.cmake` | CMake script | RED |
| AC-STD-13 | `./ctl check` exits 0 | CI quality gate (manual verification) | CI | — |
| AC-STD-15 | No incomplete rebase, no force push to main | Git safety (manual verification) | — | — |
| AC-STD-20 | No API/event/flow catalog entries (infrastructure only) | Manual verification | — | — |

---

## Implementation Checklist

### CMake / Build System (AC-2)

- [ ] `AC-2: add_compile_definitions(MU_ENABLE_SDL3)` added inside `if(MU_ENABLE_SDL3)` block in `MuMain/src/CMakeLists.txt`
- [ ] `AC-2: MU_ENABLE_SDL3 flag verified in MUCore, MUData, MURenderFX, MUProtocol, MUAudio targets`
- [ ] `AC-2: test_ac2_cmake_mu_enable_sdl3_7_3_0.cmake` passes (cmake -P)

### Platform Types (AC-3)

- [ ] `AC-3: #define CONST const` added to PlatformTypes.h non-Win32 `#else` section
- [ ] `AC-3: #define CP_UTF8 65001` added to PlatformTypes.h non-Win32 `#else` section
- [ ] `AC-3: test_ac3_platform_types_const_cp_utf8.cmake` passes (cmake -P)

### Platform Compat Stubs (AC-4)

- [ ] `AC-4: #define _wcsicmp wcscasecmp` added to PlatformCompat.h non-Win32 section
- [ ] `AC-4: #define wcsicmp wcscasecmp` added to PlatformCompat.h non-Win32 section
- [ ] `AC-4: #define _TRUNCATE ((size_t)-1)` added to PlatformCompat.h non-Win32 section
- [ ] `AC-4: inline void OutputDebugString(const wchar_t* /*msg*/) {}` added to PlatformCompat.h non-Win32 section
- [ ] `AC-4: MultiByteToWideChar/WideCharToMultiByte stubs using mu_utf8_to_wchar/mu_wchar_to_utf8` added with correct Win32-compatible signatures (returns int)
- [ ] `AC-4: test_ac4_platform_compat_wcsicmp_stubs.cmake` passes (cmake -P)

### GlobalBitmap.cpp (AC-5, AC-6)

- [ ] `AC-5: NarrowPath() body replaced — uses mu_wchar_to_utf8() on #ifndef _WIN32, WideCharToMultiByte on Windows`
- [ ] `AC-5: No std::wstring_convert or std::codecvt_utf8_utf16 in cross-platform path`
- [ ] `AC-5: test_ac5_globalbitmaps_no_wstring_convert.cmake` passes (cmake -P)
- [ ] `AC-6: GL_CLAMP_TO_EDGE replaced with 0x812Fu at line ~651`
- [ ] `AC-6: GL_REPEAT replaced with 0x2901u at line ~652`
- [ ] `AC-6: test_ac6_globalbitmaps_gl_literals.cmake` passes (cmake -P)

### LoadData.cpp (AC-7)

- [ ] `AC-7: #include <shlwapi.h> removed from LoadData.cpp`
- [ ] `AC-7: test_ac7_loaddata_no_shlwapi.cmake` passes (cmake -P)

### GameConfig.cpp (AC-8)

- [ ] `AC-8: DATA_BLOB, CryptProtectData, CryptUnprotectData wrapped in #ifdef _WIN32`
- [ ] `AC-8: #else stubs added — DecryptSetting and EncryptSetting return input unchanged on non-Windows`
- [ ] `AC-8: test_ac8_gameconfig_dpapi_guarded.cmake` passes (cmake -P)

### Verification (AC-1, AC-9)

- [ ] `AC-1: cmake --build --preset macos-arm64-debug exits 0 (0 compilation errors)`
- [ ] `AC-9: test_ac9_mingw_no_regression_7_3_0.cmake` passes (cmake -P)`
- [ ] `AC-9: MinGW CI build passes (./ctl check exits 0)`

### Quality Gate (AC-STD-11, AC-STD-13)

- [ ] `AC-STD-11: test_ac_std11_flow_code_7_3_0.cmake` passes (cmake -P)
- [ ] `AC-STD-11: Commit message includes VS0-QUAL-BUILDCOMPAT-MACOS flow code`
- [ ] `AC-STD-13: ./ctl check exits 0 (clang-format clean + 0 cppcheck errors)`

### Contract Reachability (AC-STD-20)

- [ ] `AC-STD-20: No new API/event/flow catalog entries produced (infrastructure story)`

---

## Test Files Created (RED Phase)

All tests are **CMake script tests** registered in `MuMain/tests/build/CMakeLists.txt`.
These are the established pattern for infrastructure/build verification in this project.

```
MuMain/tests/build/
├── test_ac2_cmake_mu_enable_sdl3_7_3_0.cmake    [NEW] AC-2
├── test_ac3_platform_types_const_cp_utf8.cmake  [NEW] AC-3
├── test_ac4_platform_compat_wcsicmp_stubs.cmake [NEW] AC-4
├── test_ac5_globalbitmaps_no_wstring_convert.cmake [NEW] AC-5
├── test_ac6_globalbitmaps_gl_literals.cmake     [NEW] AC-6
├── test_ac7_loaddata_no_shlwapi.cmake           [NEW] AC-7
├── test_ac8_gameconfig_dpapi_guarded.cmake      [NEW] AC-8
├── test_ac9_mingw_no_regression_7_3_0.cmake     [NEW] AC-9
└── test_ac_std11_flow_code_7_3_0.cmake          [NEW] AC-STD-11
```

**Note:** AC-STD-2 states "No new Catch2 tests required — this is a build-system wiring fix."
CMake script tests are used instead as they verify structural/build properties without requiring compilation on macOS.

**Note:** AC-1 (cmake build succeeds) is verified by the macOS CI runner added in story 7.4.1 (`test_ac3_macos_configure.sh` existing test + manual `cmake --build` run).

---

## CTest Registration Summary

Tests added to `MuMain/tests/build/CMakeLists.txt` under story 7.3.0 section:

| CTest Name | Verifies |
|------------|---------|
| `7.3.0-AC-2:cmake-mu-enable-sdl3-project-scope` | AC-2 |
| `7.3.0-AC-3:platform-types-const-cp-utf8` | AC-3 |
| `7.3.0-AC-4:platform-compat-wcsicmp-stubs` | AC-4 |
| `7.3.0-AC-5:globalbitmaps-no-wstring-convert` | AC-5 |
| `7.3.0-AC-6:globalbitmaps-gl-literals` | AC-6 |
| `7.3.0-AC-7:loaddata-no-shlwapi` | AC-7 |
| `7.3.0-AC-8:gameconfig-dpapi-guarded` | AC-8 |
| `7.3.0-AC-9:mingw-no-regression` | AC-9 |
| `7.3.0-AC-STD-11:flow-code-traceability` | AC-STD-11 |

---

## Final Validation

- [x] PCC project guidelines loaded (project-context.md, development-standards.md)
- [x] Existing tests searched — no pre-existing tests match story 7-3-0 ACs
- [x] No prohibited libraries referenced
- [x] All tests use CMake script pattern (project-approved for infrastructure stories)
- [x] AC-N: naming convention used in cmake test file names and CTest names
- [x] Implementation checklist includes all ACs with `[ ]` pending items
- [x] AC-STD-2 constraint honored (no new Catch2 unit tests)
- [x] Flow code VS0-QUAL-BUILDCOMPAT-MACOS present in all test file headers
- [x] ATDD checklist saved to `_bmad-output/stories/7-3-0-macos-build-compat/atdd.md`
