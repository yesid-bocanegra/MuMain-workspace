# ATDD Implementation Checklist: Story 3.1.1 - CMake RID Detection & .NET AOT Build Integration

**Story ID:** 3-1-1-cmake-rid-detection
**Story Type:** infrastructure
**Date Generated:** 2026-03-06
**Primary Test Level:** CMake script validation (cmake -P)

---

## PCC Compliance Summary

| Check | Result | Notes |
|-------|--------|-------|
| Framework | Catch2 NOT used (correct) | infrastructure story — CMake -P script tests only per AC-STD-2 |
| Prohibited libraries | N/A | CMake files only |
| No `#ifdef _WIN32` in game logic | Required | MU_DOTNET_LIB_EXT replaces the need for platform ifdefs in Connection.h |
| No hardcoded .dll/.dylib/.so in new C++ code | Required | Connection.h NOT modified in this story |
| Forward slashes in all paths | Required | CMake files only |
| Coverage target | N/A | Build system story |
| Bruno/Playwright | NOT applicable | infrastructure story, no API endpoints |

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Name | Status |
|----|-------------|-----------|-----------|--------|
| AC-1 | RID detection — all 5 RIDs in FindDotnetAOT.cmake | `tests/build/test_ac1_dotnet_rid_detection.cmake` | 3.1.1-AC-1:dotnet-rid-detection | GREEN |
| AC-2 | MU_DOTNET_LIB_EXT set per platform; passed via add_compile_definitions | `tests/build/test_ac2_dotnet_lib_ext.cmake` | 3.1.1-AC-2:dotnet-lib-ext | GREEN |
| AC-3 | BuildDotNetAOT custom target structure | Covered by AC-6 test (DOTNETAOT_FOUND guard) + manual validation AC-VAL-1 | — | GREEN |
| AC-4 | Library copy to CMAKE_RUNTIME_OUTPUT_DIRECTORY | Manual validation only (AC-VAL-2 — requires dotnet present) | — | GREEN |
| AC-5 | WSL detection via /proc/version | Folded into `test_ac1_dotnet_rid_detection.cmake` | 3.1.1-AC-1:dotnet-rid-detection | GREEN |
| AC-6 | Graceful failure — WARNING not FATAL_ERROR, DOTNETAOT_FOUND=FALSE | `tests/build/test_ac6_dotnet_graceful_failure.cmake` | 3.1.1-AC-6:dotnet-graceful-failure | GREEN |
| AC-STD-11 | Flow code VS1-NET-CMAKE-RID traceability | `tests/build/test_ac_std11_flow_code_3_1_1.cmake` | 3.1.1-AC-STD-11:flow-code-traceability | GREEN |

---

## Implementation Checklist

### Task 1: Create `cmake/FindDotnetAOT.cmake` (AC-1, AC-2, AC-5, AC-6)

- [x] Create `MuMain/cmake/FindDotnetAOT.cmake`
- [x] Add file header comment block containing `VS1-NET-CMAKE-RID` flow code and story reference `3.1.1`
- [x] Implement Windows RID detection: `CMAKE_SIZEOF_VOID_P EQUAL 4` → `win-x86`, else `win-x64`; set `MU_DOTNET_LIB_EXT ".dll"`
- [x] Implement macOS RID detection: `CMAKE_SYSTEM_PROCESSOR MATCHES arm64|aarch64` → `osx-arm64`, else `osx-x64`; set `MU_DOTNET_LIB_EXT ".dylib"`
- [x] Implement Linux RID detection: `linux-x64`; set `MU_DOTNET_LIB_EXT ".so"`
- [x] Add fallback branch with `message(WARNING ...)` for unrecognized platform
- [x] Emit `message(STATUS "PLAT: FindDotnetAOT — RID=${MU_DOTNET_RID}, LIB_EXT=${MU_DOTNET_LIB_EXT}")`
- [x] Implement WSL detection via `file(READ "/proc/version" ...)` checking for `Microsoft` or `WSL` pattern (AC-5)
- [x] Set `MU_IS_WSL TRUE/FALSE` based on detection result
- [x] Implement `find_program(DOTNET_EXECUTABLE dotnet ...)` for non-WSL (search `$ENV{DOTNET_ROOT}`, `/usr/local/share/dotnet`, `/usr/share/dotnet`)
- [x] Implement WSL dotnet.exe search: `/mnt/c/Program Files/dotnet/dotnet.exe`, `/mnt/c/Program Files (x86)/dotnet/dotnet.exe`
- [x] Set `DOTNET_EXECUTABLE` as `CACHE FILEPATH` variable (configurable)
- [x] When dotnet NOT found: emit `message(WARNING "PLAT: FindDotnetAOT — dotnet not found ...")` with exact prefix; set `DOTNETAOT_FOUND FALSE`; call `return()`
- [x] When dotnet IS found: emit `message(STATUS "PLAT: FindDotnetAOT — dotnet found at: ${DOTNET_EXECUTABLE}")`; set `DOTNETAOT_FOUND TRUE`
- [x] Implement WSL path conversion: `execute_process(COMMAND wslpath -w ...)` to get Windows-format csproj path for `dotnet.exe`
- [x] Set `DOTNETAOT_CSPROJ_PATH` (Windows path under WSL, native path otherwise) pointing to `ClientLibrary/MUnique.Client.Library.csproj`
- [x] `BuildDotNetAOT` custom target defined in CMakeLists.txt invoking `dotnet publish ... --runtime ${MU_DOTNET_RID} --configuration Release`
- [x] `add_custom_command(TARGET BuildDotNetAOT POST_BUILD ...)` copying library to `${CMAKE_RUNTIME_OUTPUT_DIRECTORY}`
- [x] For `win-x86` RID: pass `/p:Platform=x86 /p:PlatformTarget=x86` to dotnet publish
- [x] Run AC-1 test: PASSED
- [x] Run AC-6 test: PASSED
- [x] Run AC-STD-11 test: PASSED

### Task 2: Integrate FindDotnetAOT into `CMakeLists.txt` (AC-2, AC-3, AC-4)

- [x] Add `option(MU_ENABLE_DOTNET ".NET AOT library integration (disable for CI/rendering-only builds)" ON)` to `MuMain/CMakeLists.txt` (after `add_subdirectory("src")`)
- [x] Add `if(MU_ENABLE_DOTNET)` guard block
- [x] Inside guard: `list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")`
- [x] Inside guard: `include(FindDotnetAOT)`
- [x] Inside guard (both `if(DOTNETAOT_FOUND)` and `else()` branches): `add_compile_definitions(MU_DOTNET_LIB_EXT="${MU_DOTNET_LIB_EXT}")`
- [x] Outside guard (else branch for `MU_ENABLE_DOTNET=OFF`): `add_compile_definitions(MU_DOTNET_LIB_EXT=".dll")` (CI fallback)
- [x] Verify `add_compile_definitions(MU_DOTNET_LIB_EXT=...)` is reachable for ALL build configurations (dotnet present, dotnet absent, dotnet disabled)
- [x] Run AC-2 test: PASSED

### Task 3: Update CI workflow (AC-3 guard)

- [x] Open `MuMain/.github/workflows/ci.yml`
- [x] Add `-DMU_ENABLE_DOTNET=OFF` to the MinGW cmake configure step (same pattern as `-DMU_ENABLE_SDL3=OFF` from story 1.3.1)
- [x] Verify CI workflow is valid YAML after edit

### Task 4: Register ATDD tests in `tests/build/CMakeLists.txt`

- [x] Add `3.1.1-AC-1:dotnet-rid-detection` test (MODULE_FILE → `cmake/FindDotnetAOT.cmake`)
- [x] Add `3.1.1-AC-2:dotnet-lib-ext` test (MODULE_FILE + CMAKELISTS_FILE)
- [x] Add `3.1.1-AC-6:dotnet-graceful-failure` test (MODULE_FILE + CMAKELISTS_FILE)
- [x] Add `3.1.1-AC-STD-11:flow-code-traceability` test (MODULE_FILE)

### Standard Acceptance Criteria

- [x] AC-STD-1: CMake files use consistent style; forward slashes; no new `#ifdef _WIN32` in game logic
- [x] AC-STD-2: No Catch2 tests (build system story — CMake script tests only)
- [x] AC-STD-4: CI quality gate passes — `./ctl check` (clang-format + cppcheck) zero violations
- [x] AC-STD-5: Warning message uses exact prefix `PLAT: FindDotnetAOT — dotnet not found at <path>`
- [x] AC-STD-6: Conventional commit: `build(network): add CMake RID detection and .NET AOT build integration`
- [x] AC-STD-11: Flow code `VS1-NET-CMAKE-RID` present in `FindDotnetAOT.cmake` header comment
- [x] AC-STD-13: Quality gate passes — `./ctl check` clean
- [x] AC-STD-15: Git safety — no incomplete rebase, no force push to main
- [x] AC-STD-20: No API/event/flow catalog entries (build system only — confirmed)

### NFR Acceptance Criteria

- [x] AC-STD-NFR-1: CMake configure time overhead when dotnet NOT found is under 2 seconds (no network calls, only `find_program` + optional `execute_process`)
- [x] AC-STD-NFR-2: `dotnet publish` runs at BUILD time (custom target), not at configure time — configure overhead remains minimal

### PCC Compliance

- [x] No prohibited libraries used (N/A — CMake files only)
- [x] Testing patterns follow project conventions (CMake -P script mode + CTest)
- [x] No `#ifdef _WIN32` in game logic — `MU_DOTNET_LIB_EXT` replaces platform ifdefs in Connection.h (Connection.h NOT modified in this story)
- [x] No backslash path literals in new CMake files
- [x] Forward slashes in all CMake paths
- [x] CI MinGW build invariant maintained (MU_ENABLE_DOTNET=OFF disables dotnet for CI)
- [x] `add_compile_definitions(MU_DOTNET_LIB_EXT=...)` reachable for ALL build configurations

### Validation Artifacts

- [x] AC-VAL-1: Configure log shows `PLAT: FindDotnetAOT — dotnet found at: /opt/homebrew/bin/dotnet` (macOS arm64)
- [x] AC-VAL-2: `MU_DOTNET_LIB_EXT=.dylib` confirmed — library will produce `.dylib` on macOS
- [x] AC-VAL-3: Configure log shows `PLAT: FindDotnetAOT — RID=osx-arm64`
- [x] AC-VAL-4: ATDD test for AC-1 passes — PASSED
- [x] AC-VAL-5: ATDD test for AC-2 passes — PASSED
- [x] AC-VAL-6: ATDD test for AC-6 passes — PASSED

---

## Test Execution Commands

```bash
# Run individual AC tests (from MuMain/ directory):
cmake -DMODULE_FILE=cmake/FindDotnetAOT.cmake \
    -P tests/build/test_ac1_dotnet_rid_detection.cmake

cmake -DMODULE_FILE=cmake/FindDotnetAOT.cmake \
    -DCMAKELISTS_FILE=CMakeLists.txt \
    -P tests/build/test_ac2_dotnet_lib_ext.cmake

cmake -DMODULE_FILE=cmake/FindDotnetAOT.cmake \
    -DCMAKELISTS_FILE=CMakeLists.txt \
    -P tests/build/test_ac6_dotnet_graceful_failure.cmake

cmake -DMODULE_FILE=cmake/FindDotnetAOT.cmake \
    -P tests/build/test_ac_std11_flow_code_3_1_1.cmake

# Run all story 3.1.1 tests via CTest (requires BUILD_TESTING=ON):
cmake -S . -B build-test -DBUILD_TESTING=ON
cd build-test && ctest -R "3.1.1" --output-on-failure

# Quality gate:
./ctl check

# CMakePresets.json validity check:
python3 -m json.tool CMakePresets.json > /dev/null && echo "VALID"

# macOS configure test (dotnet not present — should show graceful WARNING):
cmake --preset macos-arm64
```

---

## RED Phase Verification

All tests confirmed FAILING (RED) as of 2026-03-06 (pre-implementation):

| Test | Result | Error |
|------|--------|-------|
| 3.1.1-AC-1:dotnet-rid-detection | FAIL | AC-1: FindDotnetAOT.cmake does not exist: cmake/FindDotnetAOT.cmake |
| 3.1.1-AC-2:dotnet-lib-ext | FAIL | AC-2: FindDotnetAOT.cmake does not exist: cmake/FindDotnetAOT.cmake |
| 3.1.1-AC-6:dotnet-graceful-failure | FAIL | AC-6: FindDotnetAOT.cmake does not exist: cmake/FindDotnetAOT.cmake |
| 3.1.1-AC-STD-11:flow-code-traceability | FAIL | AC-STD-11: FindDotnetAOT.cmake does not exist: cmake/FindDotnetAOT.cmake |
