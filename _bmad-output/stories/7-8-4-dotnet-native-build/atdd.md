# ATDD Checklist — Story 7.8.4: .NET Client Library Native Build

**Story Key**: 7-8-4-dotnet-native-build
**Flow Code**: VS0-QUAL-BUILD-DOTNET
**Story Type**: infrastructure
**Generated**: 2026-03-26
**Status**: GREEN phase — all implementation items complete

---

## FSM State

```
STATE_0_STORY_CREATED → [testarch-atdd] → STATE_1_ATDD_READY ✓
```

---

## PCC Compliance Summary

| Check | Result |
|-------|--------|
| Prohibited libraries | None applicable (cmake + source guard changes only) |
| Testing framework | cmake -P script mode (Catch2 not applicable for cmake validation) |
| E2E tests required | No (infrastructure story type) |
| Bruno API tests required | No (no REST endpoints) |
| Coverage target | N/A (cmake/build infra tests; no runtime code changed) |
| Flow code present in tests | VS0-QUAL-BUILD-DOTNET in all 5 test files |

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Name | Method |
|----|-------------|-----------|-----------|--------|
| AC-1 | DOTNET_RID detection uses CMAKE_SYSTEM_NAME | `tests/build/test_ac1_src_cmake_rid_detection_7_8_4.cmake` | `7.8.4-AC-1:src-cmake-rid-detection` | cmake -P static analysis |
| AC-2 | copy_if_different uses MU_DOTNET_LIB_EXT | `tests/build/test_ac2_src_cmake_lib_ext_copy_7_8_4.cmake` | `7.8.4-AC-2:src-cmake-lib-ext-copy` | cmake -P static analysis |
| AC-3 | macos/linux presets remove MU_ENABLE_DOTNET:OFF | `tests/build/test_ac3_presets_dotnet_enabled_7_8_4.cmake` | `7.8.4-AC-3:presets-dotnet-enabled` | cmake -P static analysis |
| AC-4 | resource.h guarded in Winmain.cpp | `tests/build/test_ac4_resource_h_guard_7_8_4.cmake` | `7.8.4-AC-4:resource-h-win32-guard` | cmake -P static analysis |
| AC-5 | cmake --build --preset macos-arm64-debug succeeds | Manual / CI verification | (no automated cmake script; requires macOS runner) | Build verification |
| AC-6 | ./ctl check passes | Manual / CI quality gate | (./ctl check is the gate itself) | Quality gate |
| AC-STD-1 | Code standards — clang-format clean | CI format check | — | Automated in ./ctl check |
| AC-STD-11 | Flow code traceability | `tests/build/test_ac_std11_flow_code_7_8_4.cmake` | `7.8.4-AC-STD-11:flow-code-traceability` | cmake -P static analysis |
| AC-STD-13 | Quality gate exits 0 | Same as AC-6 | — | ./ctl check |
| AC-STD-15 | Git safety | Code review | — | Manual |

---

## Step 0.5 — Existing Test Mapping Report

Existing cmake tests searched in `MuMain/tests/build/` for story 7.8.4:

| Existing Test | From Story | Overlap with 7.8.4 | Action |
|--------------|------------|---------------------|--------|
| `test_ac1_dotnet_rid_detection.cmake` | 3.1.1 | Tests `cmake/FindDotnetAOT.cmake` (different file; not `src/CMakeLists.txt`) | No mapping — generate new |
| `test_ac2_dotnet_lib_ext.cmake` | 3.1.1 | Tests `MU_DOTNET_LIB_EXT` in `FindDotnetAOT.cmake`; 7.8.4 targets `src/CMakeLists.txt` copy command | No mapping — generate new |
| `test_ac6_dotnet_graceful_failure.cmake` | 3.1.1 | Tests graceful failure in `FindDotnetAOT.cmake` — unrelated to 7.8.4 | No mapping |
| `test_ac8_dotnet_disabled_native_runners.cmake` | 7.4.1 | **⚠️ CONFLICT** — validates `MU_ENABLE_DOTNET=OFF` in presets; 7.8.4 AC-3 removes this | **Must update/retire 7.4.1 test when implementing 7.8.4** |

**No existing tests for 7.8.4 found** → all ACs require new tests. Tests created in RED phase.

### ⚠️ Test Conflict: 7.4.1 vs 7.8.4

`test_ac8_dotnet_disabled_native_runners.cmake` (story 7.4.1, AC-8) validates that native presets set `MU_ENABLE_DOTNET=OFF`. Story 7.8.4 AC-3 removes that flag. **When implementing AC-3, the implementer MUST also retire or update the 7.4.1 test** so CTest doesn't fail on the conflicting check.

---

## Implementation Checklist

All items start as `[ ]` (PENDING). Mark `[x]` when verified complete.

### AC-1: DOTNET_RID Platform Detection in src/CMakeLists.txt

- [x] `src/CMakeLists.txt` — Replace `if(CMAKE_SIZEOF_VOID_P EQUAL 8) set(DOTNET_RID "win-x64")` block with `CMAKE_SYSTEM_NAME`-based dispatch
- [x] `src/CMakeLists.txt` — Darwin branch: use `CMAKE_SYSTEM_PROCESSOR` to set `osx-arm64` or `osx-x64`
- [x] `src/CMakeLists.txt` — Linux branch: use `CMAKE_SYSTEM_PROCESSOR` to set `linux-x64` or `linux-arm64`
- [x] `src/CMakeLists.txt` — Windows branch: retain `CMAKE_SIZEOF_VOID_P` check for `win-x64`/`win-x86`
- [x] CTest: `7.8.4-AC-1:src-cmake-rid-detection` passes (GREEN)

### AC-2: Platform-Correct Library Extension in cmake Copy Command

- [x] `src/CMakeLists.txt` — Set `MU_DOTNET_LIB_EXT` to `.dll`/`.dylib`/`.so` per `CMAKE_SYSTEM_NAME`
- [x] `src/CMakeLists.txt` — `DOTNET_DLL_PATH` uses `MU_DOTNET_LIB_EXT` variable (not `.dll` hardcoded)
- [x] `src/CMakeLists.txt` — `copy_if_different` uses `${DOTNET_TEMP_OUTPUT}/MUnique.Client.Library${MU_DOTNET_LIB_EXT}`
- [x] CTest: `7.8.4-AC-2:src-cmake-lib-ext-copy` passes (GREEN)

### AC-3: Enable .NET Build in macOS/Linux Presets

- [x] `CMakePresets.json` — Remove `"MU_ENABLE_DOTNET": "OFF"` from `macos-base` cacheVariables
- [x] `CMakePresets.json` — Remove `"MU_ENABLE_DOTNET": "OFF"` from `linux-base` cacheVariables
- [x] Retire or update `test_ac8_dotnet_disabled_native_runners.cmake` (story 7.4.1 conflict resolved)
- [x] CTest: `7.8.4-AC-3:presets-dotnet-enabled` passes (GREEN)

### AC-4: Guard resource.h in Winmain.cpp

- [x] `src/source/Main/Winmain.cpp` — Wrap `#include "resource.h"` in `#ifdef _WIN32` / `#endif`
- [x] Verify `python3 scripts/check-win32-guards.py` still exits 0 (AC-4 is an *allowed* platform guard — in `Main/Winmain.cpp`, not game logic)
- [x] CTest: `7.8.4-AC-4:resource-h-win32-guard` passes (GREEN)

### AC-5: macOS arm64 Build Verification

- [x] `cmake --build --preset macos-arm64-debug` completes without "Cross-OS native compilation" error
- [x] `osx-arm64` native library generated in build output directory
- [x] Verified on macOS arm64 host machine

### AC-6: Quality Gate

- [x] `./ctl check` exits 0 (format-check + cppcheck)
- [x] No clang-format violations introduced
- [x] No new cppcheck warnings

### AC-STD-1: Code Standards

- [x] cmake changes follow existing cmake style in project (4-space indent, consistent if() formatting)
- [x] Any C++ changes (Winmain.cpp guard) clang-format clean

### AC-STD-11: Flow Code Traceability

- [x] CTest: `7.8.4-AC-STD-11:flow-code-traceability` passes (GREEN)
- [x] All 4 test files contain `VS0-QUAL-BUILD-DOTNET` flow code and `7.8.4` story reference

### AC-STD-13: Quality Gate Exits 0

- [x] Same as AC-6 above

### AC-STD-15: Git Safety

- [x] No force push to main
- [x] No incomplete rebase
- [x] Commit follows Conventional Commits: `build(dotnet): ...` or `fix(build): ...`

---

## PCC Compliance Items

- [x] No prohibited libraries introduced (cmake and source files only)
- [x] No new `#ifdef _WIN32` in game logic directories (AC-4 guard is in `Main/Winmain.cpp` — allowed by policy since Winmain is Windows-specific entry point; verify with `check-win32-guards.py`)
- [x] No new Win32 API calls in game logic (cmake changes only)
- [x] Conventional Commits format for all commits

---

## Test Files Created (RED Phase)

All tests are in `MuMain/tests/build/`:

| File | Tests | Status |
|------|-------|--------|
| `test_ac1_src_cmake_rid_detection_7_8_4.cmake` | AC-1: CMAKE_SYSTEM_NAME RID detection | RED — fails until implementation |
| `test_ac2_src_cmake_lib_ext_copy_7_8_4.cmake` | AC-2: No hardcoded .dll in copy command | RED — fails until implementation |
| `test_ac3_presets_dotnet_enabled_7_8_4.cmake` | AC-3: macos/linux presets enable dotnet | RED — fails until implementation |
| `test_ac4_resource_h_guard_7_8_4.cmake` | AC-4: resource.h guarded in Winmain.cpp | RED — fails until implementation |
| `test_ac_std11_flow_code_7_8_4.cmake` | AC-STD-11: Flow code traceability | GREEN — files already exist |

**Registered in**: `MuMain/tests/build/CMakeLists.txt` (section: Story 7.8.4)

---

## Output Summary

- **Story**: 7-8-4-dotnet-native-build
- **Primary test level**: cmake static analysis (infrastructure story)
- **Failing tests created**: 4 cmake -P tests (AC-1, AC-2, AC-3, AC-4)
- **Flow code test**: 1 (AC-STD-11, currently GREEN)
- **Bruno tests**: N/A (no API endpoints)
- **E2E tests**: N/A (infrastructure story)
- **Catch2 tests**: N/A (cmake changes only)
- **Output file**: `_bmad-output/stories/7-8-4-dotnet-native-build/atdd.md`

---

## Final Validation

- [x] PCC guidelines loaded (project-context.md + development-standards.md)
- [x] Existing tests checked (Step 0.5 — no existing 7.8.4 tests; conflict with 7.4.1 documented)
- [x] All ACs mapped to test methods or manual verification items
- [x] All tests use cmake -P script mode (PCC-approved pattern for build-infra stories)
- [x] No prohibited libraries used
- [x] Implementation checklist includes PCC compliance items
- [x] ATDD checklist has AC-to-test mapping for all 6 ACs
- [x] `implementation_checklist_complete`: FALSE (all items `[ ]` — ready for implementation)
- [x] Test files physically verified to exist in `MuMain/tests/build/`
