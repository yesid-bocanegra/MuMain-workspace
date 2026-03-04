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

- [ ] Create `MuMain/cmake/toolchains/linux-x64.cmake`
- [ ] Set `CMAKE_SYSTEM_NAME Linux`
- [ ] Set `CMAKE_SYSTEM_PROCESSOR x86_64`
- [ ] Set `CMAKE_C_COMPILER gcc`
- [ ] Set `CMAKE_CXX_COMPILER g++`
- [ ] Set `CMAKE_CXX_STANDARD 20`
- [ ] Set `CMAKE_CXX_EXTENSIONS OFF`
- [ ] Verify NO `CMAKE_FIND_ROOT_PATH_MODE_*` settings (native build, not cross-compile)
- [ ] Verify NO `static-libgcc`/`static-libstdc++` flags (MinGW-specific)
- [ ] Run AC-1 test: `cmake -DTOOLCHAIN_FILE=cmake/toolchains/linux-x64.cmake -P tests/build/test_ac1_linux_toolchain_file.cmake` -- must PASS

### CMakePresets.json (AC-2)

- [ ] Add `linux-base` hidden configure preset
- [ ] Set generator to `"Ninja Multi-Config"`
- [ ] Set `CMAKE_EXPORT_COMPILE_COMMANDS ON`
- [ ] Add `condition` block: `hostSystemName == "Linux"`
- [ ] Add `linux-x64` configure preset inheriting `linux-base`
- [ ] Reference `cmake/toolchains/linux-x64.cmake` as toolchainFile
- [ ] Add `linux-x64-debug` build preset
- [ ] Add `linux-x64-release` build preset
- [ ] Validate JSON: `python3 -m json.tool MuMain/CMakePresets.json`
- [ ] Verify existing Windows presets unchanged (regression)
- [ ] Run AC-2 test: `cmake -DPRESETS_FILE=CMakePresets.json -P tests/build/test_ac2_linux_presets.cmake` -- must PASS

### Configure Validation (AC-3)

- [ ] On Linux x64: Run `cmake --preset linux-x64` -- configure step completes
- [ ] Note any warnings (acceptable at this stage -- Win32 headers not yet replaced)
- [ ] Capture configure output as validation artifact
- [ ] Run AC-3 test: `bash tests/build/test_ac3_linux_configure.sh` -- must PASS on Linux

### Standard Acceptance Criteria

- [ ] AC-STD-1: CMake files use consistent style, no new Win32 API calls
- [ ] AC-STD-2: No Catch2 tests required (build system story -- CMake script tests used instead)
- [ ] AC-STD-3: No banned Win32 APIs introduced
- [ ] AC-STD-4: CI MinGW cross-compile quality gate remains green
- [ ] AC-STD-5: Commit: `build(platform): add Linux CMake toolchain and presets`
- [ ] AC-STD-11: Flow Code traceability -- commit references VS0-PLAT-CMAKE-LINUX
- [ ] AC-STD-13: Quality gate passes -- `./ctl check`
- [ ] AC-STD-15: Git safety -- no incomplete rebase, no force push
- [ ] AC-STD-20: No API/event/flow catalog entries (build system only)

### PCC Compliance

- [ ] No prohibited libraries used (N/A -- CMake files only)
- [ ] Testing patterns follow project conventions (CMake script + CTest)
- [ ] No `#ifdef _WIN32` in game logic (N/A -- CMake files only)
- [ ] No backslash path literals
- [ ] Forward slashes in all paths
- [ ] CI build invariant maintained

### Validation Artifacts

- [ ] AC-VAL-1: Linux configure log showing successful `cmake --preset linux-x64`

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
