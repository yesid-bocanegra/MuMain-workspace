# ATDD Implementation Checklist: Story 1.1.1 - macOS CMake Toolchain & Presets

**Story ID:** 1-1-1-macos-cmake-toolchain
**Story Type:** infrastructure
**Date Generated:** 2026-03-04
**Primary Test Level:** Unit (CMake script validation) + Integration (configure step)

---

## AC-to-Test Mapping

| AC | Description | Test File | Test Name | Status |
|----|-------------|-----------|-----------|--------|
| AC-1 | macOS arm64 toolchain file with Clang, C++20, SDK detection | `tests/build/test_ac1_macos_toolchain_file.cmake` | AC-1:macos-toolchain-file | RED |
| AC-2 | CMakePresets.json with macos-base, macos-arm64, build presets, Darwin condition | `tests/build/test_ac2_macos_presets.cmake` | AC-2:macos-presets | RED |
| AC-3 | cmake --preset macos-arm64 configure succeeds on macOS | `tests/build/test_ac3_macos_configure.sh` | AC-3:macos-configure | RED |
| AC-4 | Windows MSVC presets unchanged, all existing presets remain valid | `tests/build/test_ac4_macos_windows_presets_unchanged.cmake` | AC-4:windows-presets-unchanged | RED |

---

## Implementation Checklist

### Toolchain File (AC-1)

- [ ] Create `MuMain/cmake/toolchains/macos-arm64.cmake`
- [ ] Set `CMAKE_SYSTEM_NAME Darwin`
- [ ] Set `CMAKE_SYSTEM_PROCESSOR arm64`
- [ ] Set `CMAKE_OSX_ARCHITECTURES arm64`
- [ ] Set `CMAKE_C_COMPILER clang`
- [ ] Set `CMAKE_CXX_COMPILER clang++`
- [ ] Set `CMAKE_CXX_STANDARD 20`
- [ ] Set `CMAKE_CXX_STANDARD_REQUIRED ON`
- [ ] Set `CMAKE_CXX_EXTENSIONS OFF`
- [ ] Add macOS SDK detection (xcrun or CMAKE_OSX_SYSROOT)
- [ ] Add comment block explaining configure-only status (full compile blocked until SDL3 migration)
- [ ] Verify NO `CMAKE_FIND_ROOT_PATH_MODE_*` settings (native build, not cross-compile)
- [ ] Verify NO `static-libgcc`/`static-libstdc++` flags (MinGW-specific)
- [ ] Run AC-1 test: `cmake -DTOOLCHAIN_FILE=cmake/toolchains/macos-arm64.cmake -P tests/build/test_ac1_macos_toolchain_file.cmake` -- must PASS

### CMakePresets.json (AC-2)

- [ ] Add `macos-base` hidden configure preset
- [ ] Set generator to `"Ninja Multi-Config"`
- [ ] Set `CMAKE_EXPORT_COMPILE_COMMANDS ON`
- [ ] Add `condition` block: `hostSystemName == "Darwin"`
- [ ] Add `macos-arm64` configure preset inheriting `macos-base`
- [ ] Reference `cmake/toolchains/macos-arm64.cmake` as toolchainFile
- [ ] Add `macos-arm64-debug` build preset
- [ ] Add `macos-arm64-release` build preset
- [ ] Validate JSON: `python3 -m json.tool MuMain/CMakePresets.json`
- [ ] Run AC-2 test: `cmake -DPRESETS_FILE=CMakePresets.json -P tests/build/test_ac2_macos_presets.cmake` -- must PASS

### Configure Validation (AC-3)

- [ ] On macOS: Run `cmake --preset macos-arm64` -- configure step completes (exit code 0)
- [ ] Note any warnings (acceptable at this stage -- Win32 headers not yet replaced)
- [ ] Capture configure output as validation artifact
- [ ] Run AC-3 test: `bash tests/build/test_ac3_macos_configure.sh` -- must PASS on macOS

### Regression Safety (AC-4)

- [ ] Verify existing Windows presets unchanged (windows-base, windows-x86, windows-x64, mueditor variants)
- [ ] Verify existing Linux presets unchanged (linux-base, linux-x64, build presets)
- [ ] Run AC-4 test: `cmake -DPRESETS_FILE=CMakePresets.json -P tests/build/test_ac4_macos_windows_presets_unchanged.cmake` -- must PASS

### Standard Acceptance Criteria

- [ ] AC-STD-1: CMake files use forward slashes, no hardcoded absolute paths, follow conventions from existing toolchains
- [ ] AC-STD-2: No Catch2 tests required (build system story -- CMake script tests used instead)
- [ ] AC-STD-3: No banned Win32 APIs introduced
- [ ] AC-STD-4: CI quality gate passes (`./ctl check`)
- [ ] AC-STD-5: Conventional commit: `build(platform): add macOS CMake toolchain and presets`
- [ ] AC-STD-13: Quality gate passes: format-check + lint
- [ ] AC-STD-15: Git safety: no incomplete rebase, no force push, no `--no-verify` hooks

### PCC Compliance

- [ ] No prohibited libraries used (N/A -- CMake files only)
- [ ] Testing patterns follow project conventions (CMake script + shell script + CTest)
- [ ] No `#ifdef _WIN32` in game logic (N/A -- CMake files only)
- [ ] No backslash path literals
- [ ] Forward slashes in all paths
- [ ] CI build invariant maintained

### Validation Artifacts

- [ ] AC-VAL-1: macOS configure log showing successful `cmake --preset macos-arm64` run (exit code 0)
- [ ] AC-VAL-2: Windows build confirmed not regressed -- existing presets still valid JSON and unchanged

---

## Test Execution Commands

```bash
# Run individual AC tests (from MuMain/ directory):
cmake -DTOOLCHAIN_FILE=cmake/toolchains/macos-arm64.cmake -P tests/build/test_ac1_macos_toolchain_file.cmake
cmake -DPRESETS_FILE=CMakePresets.json -P tests/build/test_ac2_macos_presets.cmake
bash tests/build/test_ac3_macos_configure.sh
cmake -DPRESETS_FILE=CMakePresets.json -P tests/build/test_ac4_macos_windows_presets_unchanged.cmake

# Run via CTest (requires BUILD_TESTING=ON):
cmake -S . -B build-test -DBUILD_TESTING=ON
cd build-test && ctest -R "AC-[1234]" --output-on-failure
```

---

## RED Phase Verification

All tests confirmed FAILING (RED) as of 2026-03-04 (pre-implementation):

| Test | Result | Error |
|------|--------|-------|
| AC-1:macos-toolchain-file | FAIL | Toolchain file does not exist: cmake/toolchains/macos-arm64.cmake |
| AC-2:macos-presets | FAIL | CMakePresets.json missing 'macos-base' hidden preset |
| AC-3:macos-configure | FAIL | Toolchain file does not exist |
| AC-4:windows-presets-unchanged | FAIL | macos-base preset is missing (macOS presets not added yet) |
