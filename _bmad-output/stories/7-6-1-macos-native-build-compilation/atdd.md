# ATDD Checklist — Story 7.6.1: macOS Native Build — Remaining Compilation Gaps

**Story ID:** 7.6.1
**Flow Code:** VS0-QUAL-BUILDCOMP-MACOS
**Story Type:** infrastructure
**Test Framework:** CMake script mode (`cmake -P`) — static source verification
**Test Location:** `MuMain/tests/build/`
**ATDD Generated:** 2026-03-24

---

## AC-to-Test Mapping

| AC | Description | Test File | CTest Name | Phase |
|----|-------------|-----------|------------|-------|
| AC-1 | `cmake --build build` produces zero errors with Homebrew Clang 22 | _(runtime — quality gate verification)_ | `./ctl build` | Manual QG |
| AC-2 | `./ctl build` uses Homebrew Clang from `/opt/homebrew/opt/llvm/bin/` | `test_ac2_ctl_homebrew_llvm_7_6_1.cmake` | `7.6.1-AC-2:ctl-uses-homebrew-llvm` | Automated |
| AC-3 | `.pcc-config.yaml` build specifies Homebrew LLVM; no stale comment | `test_ac3_pcc_config_build_homebrew_7_6_1.cmake` | `7.6.1-AC-3:pcc-config-build-homebrew` | Automated |
| AC-4 | `quality_gate` in `.pcc-config.yaml` includes `cmake --build build` | `test_ac4_pcc_config_quality_gate_build_7_6_1.cmake` | `7.6.1-AC-4:pcc-config-quality-gate-includes-build` | Automated |
| AC-5 | `ZzzOpenglUtil.cpp` excluded from macOS CMake build | `test_ac5_wgl_cmake_exclusion_7_6_1.cmake` | `7.6.1-AC-5:wgl-cmake-exclusion` | Automated |
| AC-6 | `DSwaveIO.h` `#include <mmsystem.h>` guarded with `#ifdef _WIN32` | `test_ac6_dswaveio_mmsystem_guard_7_6_1.cmake` | `7.6.1-AC-6:dswaveio-mmsystem-guard` | Automated |
| AC-7 | All 9 GDI/Win32 stubs present in `PlatformCompat.h` non-Windows section | `test_ac7_platform_compat_gdi_stubs_7_6_1.cmake` | `7.6.1-AC-7:platform-compat-gdi-stubs` | Automated |
| AC-8 | `xstreambuf.cpp` `delete void*` fixed with `static_cast<char*>` (3 occurrences) | `test_ac8_xstreambuf_no_delete_void_7_6_1.cmake` | `7.6.1-AC-8:xstreambuf-no-delete-void` | Automated |
| AC-9 | `PosixSignalHandlers.cpp` uses `SA_SIGINFO`; `SA_SIGACTION` removed from code | `test_ac9_posix_sa_siginfo_7_6_1.cmake` | `7.6.1-AC-9:posix-sa-siginfo` | Automated |
| AC-10 | `ZzzOpenData.cpp` pragma wrapped with `__has_warning` guard | `test_ac10_pragma_has_warning_7_6_1.cmake` | `7.6.1-AC-10:pragma-has-warning-guard` | Automated |
| AC-11 | No new `#ifdef _WIN32` in modified game logic files (MinGW guard) | `test_ac11_mingw_no_regression_7_6_1.cmake` | `7.6.1-AC-11:mingw-no-regression` | Automated |
| AC-STD-1 | No new `#ifdef _WIN32` in game logic; stubs in `PlatformCompat.h` | _(code review verification)_ | Manual review | Manual |
| AC-STD-2 | `./ctl build` and `./ctl check` both pass | _(runtime — quality gate)_ | `./ctl check` | Manual QG |
| AC-STD-11 | Flow code `VS0-QUAL-BUILDCOMP-MACOS` in commit messages + test files | `test_ac_std11_flow_code_7_6_1.cmake` | `7.6.1-AC-STD-11:flow-code-traceability` | Automated |
| AC-STD-13 | Quality gate passes: `./ctl check && ./ctl build` | _(runtime — quality gate)_ | `./ctl check` | Manual QG |
| AC-STD-15 | Conventional commits with flow code | _(git log verification)_ | `git log` | Manual |
| AC-VAL-1 | `cmake --build build 2>&1 | grep "^FAILED:"` returns empty | _(runtime build verification)_ | Build output | Manual QG |
| AC-VAL-2 | Build complete message shown | _(runtime build verification)_ | Build output | Manual QG |
| AC-VAL-3 | `./ctl check` passes (format + lint) | _(runtime — quality gate)_ | `./ctl check` | Manual QG |
| AC-VAL-CONFIG | `.pcc-config.yaml` build contains `/opt/homebrew/opt/llvm/bin/clang++` | `test_ac3_pcc_config_build_homebrew_7_6_1.cmake` | `7.6.1-AC-3:pcc-config-build-homebrew` | Automated |

---

## Implementation Checklist

### Automated Test Verification (CMake Script Mode)

- [x] AC-2: `ctest -R "7.6.1-AC-2"` passes — `./ctl` uses Homebrew LLVM compiler paths
- [x] AC-3: `ctest -R "7.6.1-AC-3"` passes — `.pcc-config.yaml` build references Homebrew LLVM
- [x] AC-4: `ctest -R "7.6.1-AC-4"` passes — `quality_gate` includes native build step
- [x] AC-5: `ctest -R "7.6.1-AC-5"` passes — `ZzzOpenglUtil.cpp` excluded from non-Windows builds in CMakeLists.txt
- [x] AC-6: `ctest -R "7.6.1-AC-6"` passes — `DSwaveIO.h` mmsystem.h include is Win32-guarded
- [x] AC-7: `ctest -R "7.6.1-AC-7"` passes — all 9 GDI/Win32 stubs present in `PlatformCompat.h`
- [x] AC-8: `ctest -R "7.6.1-AC-8"` passes — no untyped `delete void*` in `xstreambuf.cpp`
- [x] AC-9: `ctest -R "7.6.1-AC-9"` passes — `PosixSignalHandlers.cpp` uses `SA_SIGINFO`
- [x] AC-10: `ctest -R "7.6.1-AC-10"` passes — `ZzzOpenData.cpp` pragma uses `__has_warning`
- [x] AC-11: `ctest -R "7.6.1-AC-11"` passes — no new Win32 guards in modified game logic files
- [x] AC-STD-11: `ctest -R "7.6.1-AC-STD-11"` passes — flow code present in test files

### Runtime / Quality Gate Verification

- [ ] AC-1: `./ctl build` exits 0 with zero compiler errors (Homebrew Clang 22)
- [ ] AC-2 (runtime): `grep "CMAKE_CXX_COMPILER:FILEPATH" build/CMakeCache.txt` shows `/opt/homebrew/opt/llvm/bin/clang++`
- [ ] AC-STD-2 / AC-STD-13: `./ctl check` exits 0 (format-check + lint + native build)
- [ ] AC-VAL-1: `cmake --build build 2>&1 | grep "^FAILED:"` returns empty
- [ ] AC-VAL-2: `cmake --build build 2>&1 | grep "Build complete"` shows success
- [ ] AC-VAL-3: `./ctl check` passes without format or lint errors

### Code Standards Compliance

- [ ] AC-STD-1: No new `#ifdef _WIN32` in game logic source files — all guards in `PlatformCompat.h`
- [ ] AC-STD-1: CMake conditionals (`if(NOT WIN32)`) used for file exclusion, not source code guards
- [ ] AC-STD-1: `PlatformCompat.h` is the only non-CMake location with platform `#ifdef` guards
- [ ] AC-STD-15: All commits use conventional commits format with flow code `VS0-QUAL-BUILDCOMP-MACOS`

### PCC Compliance

- [ ] PCC: No prohibited libraries used (no new Win32 API headers in game logic)
- [ ] PCC: Testing follows project Catch2 + CMake-script pattern (`tests/build/`)
- [ ] PCC: All test files have `# Flow Code: VS0-QUAL-BUILDCOMP-MACOS` header comment
- [ ] PCC: All test files follow RED/GREEN phase documentation pattern
- [ ] PCC: CMakeLists.txt updated with all story 7.6.1 `add_test()` entries
- [ ] PCC: No `ThirdParty/` source files formatted (excluded from format/lint enforcement)

---

## Test Files Created (RED Phase → GREEN Phase)

All tests were generated as CMake script-mode static analysis tests. Since implementation
was completed concurrent with story creation, tests are in GREEN phase upon creation.

```
MuMain/tests/build/
├── test_ac2_ctl_homebrew_llvm_7_6_1.cmake        # AC-2: ctl Homebrew LLVM paths
├── test_ac3_pcc_config_build_homebrew_7_6_1.cmake # AC-3: .pcc-config.yaml build command
├── test_ac4_pcc_config_quality_gate_build_7_6_1.cmake # AC-4: quality_gate includes build
├── test_ac5_wgl_cmake_exclusion_7_6_1.cmake       # AC-5: ZzzOpenglUtil.cpp CMake exclusion
├── test_ac6_dswaveio_mmsystem_guard_7_6_1.cmake   # AC-6: DSwaveIO.h mmsystem.h guard
├── test_ac7_platform_compat_gdi_stubs_7_6_1.cmake # AC-7: PlatformCompat.h GDI stubs
├── test_ac8_xstreambuf_no_delete_void_7_6_1.cmake # AC-8: xstreambuf.cpp typed delete
├── test_ac9_posix_sa_siginfo_7_6_1.cmake          # AC-9: PosixSignalHandlers SA_SIGINFO
├── test_ac10_pragma_has_warning_7_6_1.cmake       # AC-10: ZzzOpenData.cpp __has_warning
├── test_ac11_mingw_no_regression_7_6_1.cmake      # AC-11: MinGW regression guard
└── test_ac_std11_flow_code_7_6_1.cmake            # AC-STD-11: flow code traceability
```

---

## PCC Compliance Summary

| Requirement | Status | Notes |
|-------------|--------|-------|
| Prohibited libraries | PASS | No prohibited Win32 headers in game logic |
| Required test patterns | PASS | CMake script-mode + CTest (project standard for build tests) |
| Test profiles | N/A | Infrastructure story — no backend test profiles |
| Coverage target | N/A | Infrastructure story — structural verification only |
| Playwright (E2E) | N/A | Infrastructure story |
| Bruno (API) | N/A | Infrastructure story |
| Flow code present | PASS | `VS0-QUAL-BUILDCOMP-MACOS` in all test files |

---

## Test Design Rationale

Story 7.6.1 is an `infrastructure` type story fixing macOS compilation errors. Per the test
selection table, infrastructure stories use unit + integration tests — but the "units" here
are build system artifacts, configuration files, and source file structural properties.

The project's established pattern for this class of test is **CMake script mode** (`cmake -P`),
which enables static analysis of source files, CMake build definitions, and configuration files
without requiring a full build. This pattern is used across stories 7.3.0, 7.4.1, and 7.5.1.

AC-1 (build produces zero errors) is a **runtime integration test** verified by the quality gate
(`./ctl check`). It cannot be meaningfully automated as a cmake-P script because it requires
running the actual compiler. The quality gate command IS the test for AC-1.
