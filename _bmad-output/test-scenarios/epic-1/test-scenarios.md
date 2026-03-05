# Test Scenarios: Epic 1 — Platform Foundation & Build System

**Generated:** 2026-03-05
**Epic:** EPIC-1 (VS-0, Enabler)
**Project:** MuMain-workspace

These scenarios cover the manual validation of Epic 1's acceptance criteria. As an infrastructure/build-system epic with no UI, all scenarios are build-system and filesystem verification steps.

---

## Story 1-1-1: Create macOS CMake Toolchain & Presets

### Scenario 1: macOS ARM64 toolchain file exists and is correctly configured
- **Given:** A fresh clone of the MuMain repository on macOS (Apple Silicon)
- **When:** Inspect `MuMain/cmake/toolchains/macos-arm64.cmake`
- **Then:** File exists, contains Clang configuration, C++20 standard, and `CMAKE_OSX_DEPLOYMENT_TARGET 12.0`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 2: CMakePresets.json includes macOS presets
- **Given:** `MuMain/CMakePresets.json` is opened
- **When:** Search for `macos-arm64` preset name
- **Then:** Both configure preset and build preset for `macos-arm64` are present; `windows-x64` presets are unchanged
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 3: macOS CMake configure succeeds
- **Given:** macOS arm64 machine with Xcode CLI tools and CMake installed
- **When:** `cmake --preset macos-arm64` is run from the `MuMain/` directory
- **Then:** Configure step completes successfully (full build not expected until EPIC-2 SDL3 migration)
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 4: Windows MSVC presets are unaffected
- **Given:** Windows machine with MSVC and CMake installed
- **When:** `cmake --preset windows-x64` is run
- **Then:** Configure step and debug build succeed with no regressions
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## Story 1-1-2: Create Linux CMake Toolchain & Presets

### Scenario 1: Linux x64 toolchain file exists and is correctly configured
- **Given:** Repository on Linux x64
- **When:** Inspect `MuMain/cmake/toolchains/linux-x64.cmake`
- **Then:** File exists, contains GCC configuration and C++20 standard
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 2: CMakePresets.json includes linux-x64 presets
- **Given:** `MuMain/CMakePresets.json` is opened
- **When:** Search for `linux-x64` preset name
- **Then:** Both configure and build presets for `linux-x64` are present
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 3: Linux CMake configure succeeds
- **Given:** Linux x64 machine with GCC, CMake, and Ninja installed
- **When:** `cmake --preset linux-x64` is run from the `MuMain/` directory
- **Then:** Configure step completes successfully
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## Story 1-2-1: Platform Abstraction Headers

### Scenario 1: PlatformCompat.h and PlatformTypes.h exist
- **Given:** Repository on any platform
- **When:** Inspect `MuMain/src/source/Platform/`
- **Then:** Both `PlatformCompat.h` and `PlatformTypes.h` exist and use `#pragma once`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 2: Type aliases are correctly defined
- **Given:** `PlatformTypes.h` on non-Windows platform
- **When:** Compile a test that uses `DWORD`, `BOOL` on macOS/Linux
- **Then:** `sizeof(DWORD) == 4` and `sizeof(BOOL) == 4` — types compile without system header conflicts
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 3: No `#ifdef _WIN32` leaked into game logic
- **Given:** The game logic source files in `MuMain/src/source/`
- **When:** Search for `#ifdef _WIN32` or `#if defined(_WIN32)` in non-Platform directories
- **Then:** Zero occurrences found in game logic; all platform conditionals contained in `Platform/` headers
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 4: Headers compile on macOS and Linux
- **Given:** macOS (Clang) or Linux (GCC) machine
- **When:** `./ctl check` is run (format-check + cppcheck lint)
- **Then:** Quality gate passes with 0 violations
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## Story 1-2-2: MUPlatform Library with win32/posix Backends

### Scenario 1: PlatformLibrary.h interface is correct
- **Given:** `MuMain/src/source/Platform/PlatformLibrary.h`
- **When:** Review the file
- **Then:** `Load()`, `GetSymbol()`, and `Unload()` functions declared; `Load()` and `GetSymbol()` are `[[nodiscard]]`; no `#ifdef _WIN32` in the header
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 2: win32 backend uses LoadLibrary/GetProcAddress
- **Given:** `MuMain/src/source/Platform/win32/PlatformLibrary.cpp`
- **When:** Review the file
- **Then:** Uses `LoadLibrary`, `GetProcAddress`, `FreeLibrary`; error messages prefixed with `PLAT:`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 3: POSIX backend uses dlopen/dlsym
- **Given:** `MuMain/src/source/Platform/posix/PlatformLibrary.cpp`
- **When:** Review the file
- **Then:** Uses `dlopen`, `dlsym`, `dlclose`; error messages prefixed with `PLAT:`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 4: CMake selects correct backend
- **Given:** `MuMain/CMakeLists.txt` or platform CMake config
- **When:** Review CMake target definition for `MUPlatform`
- **Then:** `if(WIN32)` selects `win32/PlatformLibrary.cpp`, else selects `posix/PlatformLibrary.cpp`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 5: Catch2 tests pass on MinGW CI
- **Given:** MinGW CI environment
- **When:** CI runs Catch2 tests for PlatformLibrary
- **Then:** Load a known library, resolve a known symbol, verify null on missing library — all PASS
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## Story 1-3-1: SDL3 Dependency Integration

### Scenario 1: SDL3 is fetched via FetchContent with pinned version
- **Given:** `MuMain/CMakeLists.txt`
- **When:** Search for `FetchContent_Declare` or `FetchContent_MakeAvailable` for SDL3
- **Then:** SDL3 version is pinned to `release-3.2.8`; `SDL_STATIC=ON`, `SDL_SHARED=OFF`
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 2: SDL3 builds as part of CMake configure on macOS and Linux
- **Given:** macOS arm64 or Linux x64 with internet access
- **When:** `cmake --preset macos-arm64` (or `linux-x64`) is run (first time, SDL3 fetched)
- **Then:** SDL3 FetchContent fetches and configures successfully
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 3: SDL3 link visibility is restricted
- **Given:** CMake target definitions
- **When:** Review `target_link_libraries` for `MUPlatform` and `MURenderFX` vs game logic targets
- **Then:** SDL3 linked as `PRIVATE` to `MUPlatform` and `MURenderFX` only; `MUGame` cannot include SDL3 headers
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 4: MinGW CI remains green with SDL3 excluded
- **Given:** CI pipeline on MinGW cross-compile
- **When:** CI runs with `MU_ENABLE_SDL3=OFF`
- **Then:** CI build completes with 0 errors; SDL3 gracefully excluded
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## Story 1-4-1: Build Documentation Per Platform

### Scenario 1: macOS build section in development-guide.md
- **Given:** `docs/development-guide.md`
- **When:** Read the macOS section
- **Then:** Contains prerequisites, exact `cmake --preset macos-arm64` command, and a note that no runnable binary is produced until EPIC-2
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 2: Linux build section in development-guide.md
- **Given:** `docs/development-guide.md`
- **When:** Read the Linux section
- **Then:** Contains prerequisites, exact `cmake --preset linux-x64` command, and a note that no runnable binary is produced until EPIC-2
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 3: Troubleshooting section covers common failures
- **Given:** `docs/development-guide.md`
- **When:** Inspect troubleshooting section
- **Then:** Common failure modes for macOS and Linux are documented
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 4: CLAUDE.md build commands updated
- **Given:** `CLAUDE.md`
- **When:** Inspect "Build Commands (by OS)" section
- **Then:** macOS arm64 and Linux x64 presets are documented; line count reference for development-guide.md is accurate (~400 lines)
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 5: Fresh-clone build test (macOS)
- **Given:** Fresh clone of the repository on macOS arm64 with prerequisites installed
- **When:** Follow only the docs/development-guide.md macOS instructions
- **Then:** CMake configure completes in under 30 minutes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 6: Fresh-clone build test (Linux)
- **Given:** Fresh clone of the repository on Linux x64 with prerequisites installed
- **When:** Follow only the docs/development-guide.md Linux instructions
- **Then:** CMake configure completes in under 30 minutes
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## Epic 1 Validation Criteria — End-to-End Verification

### Scenario 1: CMake configures on all platforms
- **Given:** The repository is cloned on macOS arm64, Linux x64, and Windows x64
- **When:** Run `cmake --preset macos-arm64`, `cmake --preset linux-x64`, `cmake --preset windows-x64`
- **Then:** All three configure steps succeed
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 2: MUPlatform compiles with correct platform backend
- **Given:** MinGW CI or Windows MSVC build
- **When:** CMake build runs with `MUPlatform` target
- **Then:** win32 backend selected on Windows; posix backend selected on Linux/macOS
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 3: PlatformLibrary loads a dynamic library
- **Given:** macOS or Linux with a known system library (e.g., `libm.so`, `libSystem.dylib`)
- **When:** Catch2 test exercises `mu::platform::PlatformLibrary::Load()`
- **Then:** Library loads successfully, symbol resolved, unload succeeds
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 4: SDL3 available as linked dependency
- **Given:** CMake project configured on macOS or Linux
- **When:** A test binary linked against `MUPlatform` compiles and links
- **Then:** SDL3 headers accessible from `MUPlatform`; not accessible from `MUGame` targets
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 5: MinGW CI remains green
- **Given:** Current state of the `main` branch
- **When:** CI pipeline runs (GitHub Actions MinGW cross-compile)
- **Then:** All CI jobs pass: format-check, cppcheck lint, MinGW cross-compile
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 6: Build documentation covers all three platforms
- **Given:** `docs/development-guide.md` and `CLAUDE.md`
- **When:** Review both documents
- **Then:** macOS, Linux, and Windows sections each documented with toolchain requirements and exact commands
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

*Test scenarios generated by BMAD Epic Validation Workflow — 2026-03-05*
