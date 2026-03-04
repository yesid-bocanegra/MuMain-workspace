# ATDD Implementation Checklist: Story 1.1.2 - Linux CMake Toolchain & Presets

**Story ID:** 1-1-2-linux-cmake-toolchain
**Story Type:** infrastructure
**Date Generated:** 2026-03-04
**Primary Test Level:** Unit (CMake script validation) + Integration (configure step)

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Name | Status |
|----|-------------|-----------|-----------|--------|
| AC-1 | Linux x64 toolchain file with GCC, C++20, no cross-compile artifacts | `tests/build/test_ac1_linux_toolchain_file.cmake` | AC-1:linux-toolchain-file | RED |
| AC-2 | CMakePresets.json with linux-base, linux-x64, build presets, condition block | `tests/build/test_ac2_linux_presets.cmake` | AC-2:linux-presets | RED |
| AC-3 | cmake --preset linux-x64 configure succeeds on Linux x64 | `tests/build/test_ac3_linux_configure.sh` | AC-3:linux-configure | RED (skips on non-Linux) |

---

## Implementation Checklist

### Toolchain File (AC-1)

- [x] Create `MuMain/cmake/toolchains/linux-x64.cmake`
- [x] Set `CMAKE_SYSTEM_NAME Linux`
- [x] Set `CMAKE_SYSTEM_PROCESSOR x86_64`
- [x] Set `CMAKE_C_COMPILER gcc`
- [x] Set `CMAKE_CXX_COMPILER g++`
- [x] Set `CMAKE_CXX_STANDARD 20`
- [x] Set `CMAKE_CXX_EXTENSIONS OFF`
- [x] Verify NO `CMAKE_FIND_ROOT_PATH_MODE_*` settings (native build, not cross-compile)
- [x] Verify NO `static-libgcc`/`static-libstdc++` flags (MinGW-specific)
- [x] Run AC-1 test: `cmake -DTOOLCHAIN_FILE=cmake/toolchains/linux-x64.cmake -P tests/build/test_ac1_linux_toolchain_file.cmake` -- must PASS

### CMakePresets.json (AC-2)

- [x] Add `linux-base` hidden configure preset
- [x] Set generator to `"Ninja Multi-Config"`
- [x] Set `CMAKE_EXPORT_COMPILE_COMMANDS ON`
- [x] Add `condition` block: `hostSystemName == "Linux"`
- [x] Add `linux-x64` configure preset inheriting `linux-base`
- [x] Reference `cmake/toolchains/linux-x64.cmake` as toolchainFile
- [x] Add `linux-x64-debug` build preset
- [x] Add `linux-x64-release` build preset
- [x] Validate JSON: `python3 -m json.tool MuMain/CMakePresets.json`
- [x] Verify existing Windows presets unchanged (regression)
- [x] Run AC-2 test: `cmake -DPRESETS_FILE=CMakePresets.json -P tests/build/test_ac2_linux_presets.cmake` -- must PASS

### Configure Validation (AC-3)

- [x] On Linux x64: Run `cmake --preset linux-x64` -- configure step completes
- [x] Note any warnings (acceptable at this stage -- Win32 headers not yet replaced)
- [x] Capture configure output as validation artifact
- [x] Run AC-3 test: `bash tests/build/test_ac3_linux_configure.sh` -- must PASS on Linux

### Standard Acceptance Criteria

- [x] AC-STD-1: CMake files use consistent style, no new Win32 API calls
- [x] AC-STD-2: No Catch2 tests required (build system story -- CMake script tests used instead)
- [x] AC-STD-3: No banned Win32 APIs introduced
- [x] AC-STD-4: CI MinGW cross-compile quality gate remains green
- [ ] AC-STD-5: Commit: `build(platform): add Linux CMake toolchain and presets`
- [ ] AC-STD-11: Flow Code traceability -- commit references VS0-PLAT-CMAKE-LINUX
- [x] AC-STD-13: Quality gate passes -- `./ctl check`
- [x] AC-STD-15: Git safety -- no incomplete rebase, no force push
- [x] AC-STD-20: No API/event/flow catalog entries (build system only)

### PCC Compliance

- [x] No prohibited libraries used (N/A -- CMake files only)
- [x] Testing patterns follow project conventions (CMake script + CTest)
- [x] No `#ifdef _WIN32` in game logic (N/A -- CMake files only)
- [x] No backslash path literals
- [x] Forward slashes in all paths
- [x] CI build invariant maintained

### Validation Artifacts

- [x] AC-VAL-1: Linux configure log showing successful `cmake --preset linux-x64`

---

## Test Execution Commands

```bash
# Run individual AC tests (from MuMain/ directory):
cmake -DTOOLCHAIN_FILE=cmake/toolchains/linux-x64.cmake -P tests/build/test_ac1_linux_toolchain_file.cmake
cmake -DPRESETS_FILE=CMakePresets.json -P tests/build/test_ac2_linux_presets.cmake
bash tests/build/test_ac3_linux_configure.sh

# Run via CTest (requires BUILD_TESTING=ON):
cmake -S . -B build-test -DBUILD_TESTING=ON
cd build-test && ctest -R "AC-[123]" --output-on-failure
```

---

## RED Phase Verification

All tests confirmed FAILING (RED) as of 2026-03-04:

| Test | Result | Error |
|------|--------|-------|
| AC-1:linux-toolchain-file | FAIL | Toolchain file does not exist: cmake/toolchains/linux-x64.cmake |
| AC-2:linux-presets | FAIL | CMakePresets.json missing 'linux-base' hidden preset |
| AC-3:linux-configure | SKIP (macOS) | Would FAIL on Linux -- toolchain and preset do not exist |
