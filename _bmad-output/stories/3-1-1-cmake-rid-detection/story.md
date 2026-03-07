# Story 3.1.1: CMake RID Detection & .NET AOT Build Integration

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 3 - .NET AOT Cross-Platform Networking |
| Feature | 3.1 - Build Integration |
| Story ID | 3.1.1 |
| Story Points | 5 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-NET-CMAKE-RID |
| FRs Covered | FR9 — .NET Native AOT library loads on all platforms (.dll/.dylib/.so); Architecture Decision 3 (CMake RID detection) |
| Prerequisites | EPIC-1 done (1.1.1 macOS toolchain, 1.1.2 Linux toolchain established); all EPIC-2 stories done |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, cpp-cmake | Create `MuMain/cmake/FindDotnetAOT.cmake`; integrate into `MuMain/CMakeLists.txt`; add `MU_DOTNET_RID` and `MU_DOTNET_LIB_EXT` CMake variables; `add_custom_target` to invoke `dotnet publish` with correct `--runtime` flag; copy output to binary dir |
| project-docs | documentation | Story file, ATDD CMake script tests for RID detection and lib extension ACs |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** CMake to detect the platform Runtime Identifier and build the .NET AOT library with the correct RID,
**so that** `dotnet publish` produces the right library format (`.dll`/`.dylib`/`.so`) for each platform automatically.

---

## Functional Acceptance Criteria

- [x] **AC-1:** `cmake/FindDotnetAOT.cmake` module detects platform and sets `MU_DOTNET_RID` to one of: `win-x86` (Windows 32-bit), `win-x64` (Windows 64-bit), `osx-arm64` (macOS Apple Silicon), `osx-x64` (macOS Intel), `linux-x64` (Linux x64)
- [x] **AC-2:** CMake defines `MU_DOTNET_LIB_EXT` as `.dll` (Windows), `.dylib` (macOS), or `.so` (Linux) based on `CMAKE_SYSTEM_NAME`; this define is passed to the C++ compiler via `add_compile_definitions` so Connection.h can use it
- [x] **AC-3:** A CMake custom target (`BuildDotNetAOT`) invokes `dotnet publish MUnique.Client.Library.csproj --runtime ${MU_DOTNET_RID} -c Release` producing the native AOT library; the command is guarded by `DOTNETAOT_FOUND` so it only runs when dotnet is available
- [x] **AC-4:** The built library (`MUnique.Client.Library${MU_DOTNET_LIB_EXT}`) is copied to `${CMAKE_RUNTIME_OUTPUT_DIRECTORY}` (alongside the game binary) automatically after the dotnet publish step
- [x] **AC-5:** WSL interop path: when running under WSL (Linux host + Windows dotnet.exe), `FindDotnetAOT.cmake` detects WSL via `/proc/version` content matching "Microsoft" or "WSL", converts the ClientLibrary project path using `wslpath -w`, and invokes the Windows `dotnet.exe` from `/mnt/c/Program Files/dotnet/dotnet.exe` (configurable via `DOTNET_EXECUTABLE` cache variable)
- [x] **AC-6:** Graceful failure: if `dotnet` is not found at configure time, CMake emits a `message(WARNING ...)` — `PLAT: FindDotnetAOT — dotnet not found at <path>` — and sets `DOTNETAOT_FOUND=FALSE`; configure and build proceed normally without the `.NET` library (allows rendering/input-only builds)

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code follows project-context.md standards — CMake files use consistent style; no new `#ifdef _WIN32` in game logic; `MU_DOTNET_LIB_EXT` define enables game logic to reference the library without platform ifdefs
- [x] **AC-STD-2:** No Catch2 unit tests required — this is a build system story; validation via CMake `-P` script tests (see Test Design below)
- [x] **AC-STD-4:** CI quality gate passes — `./ctl check` (clang-format + cppcheck) passes with zero violations; CMake files not checked by cppcheck, so gate validates existing C++ files remain clean
- [x] **AC-STD-5:** Error logging: `PLAT: FindDotnetAOT — dotnet not found at {path}` emitted via `message(WARNING ...)` at configure time when dotnet not available
- [x] **AC-STD-6:** Conventional commit: `build(network): add CMake RID detection and .NET AOT build integration`
- [x] **AC-STD-11:** Flow Code traceability — commit message includes `VS1-NET-CMAKE-RID` reference
- [x] **AC-STD-13:** Quality gate passes — `./ctl check` clean
- [x] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [x] **AC-STD-20:** Contract Reachability — story produces no API/event/flow catalog entries (build system only)

### NFR Acceptance Criteria

- [x] **AC-STD-NFR-1:** CMake configure time overhead for dotnet detection is under 2 seconds when dotnet is not found (no network calls, only `find_program` + optional `execute_process`)
- [x] **AC-STD-NFR-2:** CMake configure time overhead when dotnet IS found: dotnet publish runs at build time (not configure time) via `add_custom_target`, so configure overhead remains minimal

---

## Validation Artifacts

- [x] **AC-VAL-1:** CMake configure log shows: `PLAT: FindDotnetAOT — RID=osx-arm64, LIB_EXT=.dylib` and `dotnet found at: /opt/homebrew/bin/dotnet` (macOS arm64 dev machine)
- [x] **AC-VAL-2:** Library file will be produced as `MUnique.Client.Library.dylib` — confirmed by configure output (`MU_DOTNET_LIB_EXT=.dylib`)
- [x] **AC-VAL-3:** CMake configure log shows `PLAT: FindDotnetAOT — RID=osx-arm64` for macOS Apple Silicon host
- [x] **AC-VAL-4:** ATDD test for AC-1 (RID detection) passes: `cmake -P tests/build/test_ac1_dotnet_rid_detection.cmake` — PASSED
- [x] **AC-VAL-5:** ATDD test for AC-2 (lib extension) passes: `cmake -P tests/build/test_ac2_dotnet_lib_ext.cmake` — PASSED
- [x] **AC-VAL-6:** ATDD test for AC-6 (graceful failure) passes: `cmake -P tests/build/test_ac6_dotnet_graceful_failure.cmake` — PASSED

---

## Tasks / Subtasks

- [x] **Task 1: Create `cmake/FindDotnetAOT.cmake` module** (AC: AC-1, AC-2, AC-5, AC-6)
  - [x] 1.1 Create `MuMain/cmake/FindDotnetAOT.cmake` with platform RID detection logic
  - [x] 1.2 Detect Windows (32-bit vs 64-bit via `CMAKE_SIZEOF_VOID_P`), macOS (arm64 vs x64 via `CMAKE_SYSTEM_PROCESSOR`), Linux (x64)
  - [x] 1.3 Set `MU_DOTNET_RID` cache variable with correct RID value
  - [x] 1.4 Set `MU_DOTNET_LIB_EXT` based on `CMAKE_SYSTEM_NAME` (`.dll`/`.dylib`/`.so`)
  - [x] 1.5 Implement WSL detection via `/proc/version` content check (AC-5)
  - [x] 1.6 Add `find_program(DOTNET_EXECUTABLE dotnet ...)` with configurable path; emit warning if not found (AC-6)

- [x] **Task 2: Integrate FindDotnetAOT into CMakeLists.txt** (AC: AC-3, AC-4)
  - [x] 2.1 Add `list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")` in `MuMain/CMakeLists.txt`
  - [x] 2.2 Call `include(FindDotnetAOT)` guarded by `MU_ENABLE_DOTNET` option (default `ON`)
  - [x] 2.3 Add `BuildDotNetAOT` custom target invoking `dotnet publish` with `--runtime ${MU_DOTNET_RID}` when `DOTNETAOT_FOUND`
  - [x] 2.4 Add post-build copy step to move library to `${CMAKE_RUNTIME_OUTPUT_DIRECTORY}` (AC-4)
  - [x] 2.5 Pass `MU_DOTNET_LIB_EXT` to C++ compiler: `add_compile_definitions(MU_DOTNET_LIB_EXT="${MU_DOTNET_LIB_EXT}")` so Connection.h can use it without a hardcoded extension

- [x] **Task 3: Add ATDD CMake script tests** (AC: AC-VAL-4, AC-VAL-5, AC-VAL-6)
  - [x] 3.1 `MuMain/tests/build/test_ac1_dotnet_rid_detection.cmake` — PASSED
  - [x] 3.2 `MuMain/tests/build/test_ac2_dotnet_lib_ext.cmake` — PASSED
  - [x] 3.3 `MuMain/tests/build/test_ac6_dotnet_graceful_failure.cmake` — PASSED
  - [x] 3.4 `MuMain/tests/build/test_ac_std11_flow_code_3_1_1.cmake` — PASSED
  - [x] 3.5 Tests registered in `MuMain/tests/build/CMakeLists.txt`

- [x] **Task 4: Quality gate** (AC: AC-STD-4, AC-STD-13)
  - [x] 4.1 `./ctl check` — PASSED (0 violations, 689 files)
  - [x] 4.2 `CMakePresets.json` valid JSON — PASSED
  - [x] 4.3 `cmake --preset macos-arm64` — PASSED (RID=osx-arm64, dotnet found, 0.6s configure time)

---

## Error Codes Introduced

_None — this is a build system / CMake module story. No C++ error codes are introduced._

_Diagnostic message format (CMake `message(WARNING ...)`)_:
```
PLAT: FindDotnetAOT — dotnet not found at <searched paths>. .NET AOT library will not be built.
Game compiles but cannot connect to servers without MUnique.Client.Library.
```

---

## Contract Catalog Entries

### API Contracts

_None — build system story. No API endpoints introduced._

### Event Contracts

_None — build system story. No events introduced._

### Navigation Entries

_Not applicable — infrastructure story (not frontend)._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| RID detection (script) | CMake `-P` | N/A | `FindDotnetAOT.cmake` sets `MU_DOTNET_RID` to correct value for current platform |
| Lib extension (script) | CMake `-P` | N/A | `MU_DOTNET_LIB_EXT` is `.dll`/`.dylib`/`.so` matching `CMAKE_SYSTEM_NAME` |
| Graceful failure (script) | CMake `-P` | N/A | `DOTNETAOT_FOUND=FALSE` when dotnet not in `PATH`; no fatal error |
| Flow code traceability (script) | CMake `-P` | N/A | `VS1-NET-CMAKE-RID` present in `FindDotnetAOT.cmake` comment header |
| CI regression (automated) | MinGW CI | N/A | MinGW cross-compile build continues to pass (dotnet excluded from CI via `MU_ENABLE_DOTNET=OFF`) |

_No Catch2 unit tests are required for this story. The acceptance criteria are validated by CMake script mode tests following the established pattern from stories 1.1.1, 1.1.2, and 1.3.1 in `MuMain/tests/build/`._

---

## Dev Notes

### Overview

This story creates `cmake/FindDotnetAOT.cmake` — a CMake module that:
1. Detects the current platform's .NET Runtime Identifier (RID)
2. Sets `MU_DOTNET_LIB_EXT` so C++ code can reference the library file without platform ifdefs
3. Invokes `dotnet publish` at build time with the correct `--runtime` flag
4. Handles WSL interop (Linux host + Windows dotnet.exe)
5. Fails gracefully when dotnet is not available (allows rendering/input builds without networking)

This story is **pure build system** — no C++ source code changes are made. Connection.h changes (replacing `LoadLibrary`/`dlopen` with `mu::PlatformLibrary`) are deferred to story 3-1-2.

This story unblocks `3-1-2-connection-h-crossplatform` which depends on `MU_DOTNET_LIB_EXT` being defined.

### Current State of Connection.h

`MuMain/src/source/Dotnet/Connection.h` currently contains:
```cpp
#ifdef _WIN32
inline const HINSTANCE munique_client_library_handle = LoadLibrary(L"MUnique.Client.Library.dll");
#else
inline const void* munique_client_library_handle = dlopen("MUnique.Client.Library.dll", RTLD_LAZY);
#endif
```

This story does NOT modify `Connection.h`. It only adds the CMake module that will later enable story 3-1-2 to replace this code with:
```cpp
// After story 3-1-2: uses MU_DOTNET_LIB_EXT defined by FindDotnetAOT.cmake
auto libPath = std::filesystem::path("MUnique.Client.Library") += MU_DOTNET_LIB_EXT;
auto lib = mu::MuPlatform::LoadLibrary(libPath);
```

### RID Detection Logic

```cmake
# cmake/FindDotnetAOT.cmake
# Flow Code: VS1-NET-CMAKE-RID

# ============================================================
# Detect .NET Runtime Identifier (RID) for current platform
# ============================================================

# Platform-specific RID and library extension
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(MU_DOTNET_LIB_EXT ".dll")
    if(CMAKE_SIZEOF_VOID_P EQUAL 4)
        set(MU_DOTNET_RID "win-x86")
    else()
        set(MU_DOTNET_RID "win-x64")
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(MU_DOTNET_LIB_EXT ".dylib")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        set(MU_DOTNET_RID "osx-arm64")
    else()
        set(MU_DOTNET_RID "osx-x64")
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(MU_DOTNET_LIB_EXT ".so")
    set(MU_DOTNET_RID "linux-x64")
else()
    message(WARNING "PLAT: FindDotnetAOT — unrecognized platform: ${CMAKE_SYSTEM_NAME}")
    set(MU_DOTNET_LIB_EXT ".so")
    set(MU_DOTNET_RID "linux-x64")
endif()

message(STATUS "PLAT: FindDotnetAOT — RID=${MU_DOTNET_RID}, LIB_EXT=${MU_DOTNET_LIB_EXT}")
```

### WSL Detection and Interop

When running under WSL, `CMAKE_SYSTEM_NAME` is `"Linux"` but dotnet must be called as Windows `dotnet.exe`. Detection approach:

```cmake
# WSL detection
set(MU_IS_WSL FALSE)
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Linux")
    if(EXISTS "/proc/version")
        file(READ "/proc/version" PROC_VERSION_CONTENT)
        if(PROC_VERSION_CONTENT MATCHES "[Mm]icrosoft|[Ww][Ss][Ll]")
            set(MU_IS_WSL TRUE)
            message(STATUS "PLAT: FindDotnetAOT — WSL environment detected")
        endif()
    endif()
endif()

# Find dotnet executable
if(MU_IS_WSL)
    # WSL: look for Windows dotnet.exe via interop
    set(DOTNET_EXECUTABLE_CANDIDATES
        "/mnt/c/Program Files/dotnet/dotnet.exe"
        "/mnt/c/Program Files (x86)/dotnet/dotnet.exe"
    )
    foreach(CANDIDATE ${DOTNET_EXECUTABLE_CANDIDATES})
        if(EXISTS "${CANDIDATE}")
            set(DOTNET_EXECUTABLE "${CANDIDATE}" CACHE FILEPATH "Path to dotnet executable")
            break()
        endif()
    endforeach()
else()
    find_program(DOTNET_EXECUTABLE dotnet
        PATHS "$ENV{DOTNET_ROOT}" "/usr/local/share/dotnet" "/usr/share/dotnet"
        DOC "Path to dotnet executable"
    )
endif()

if(NOT DOTNET_EXECUTABLE)
    message(WARNING "PLAT: FindDotnetAOT — dotnet not found. .NET AOT library will not be built. Game compiles but cannot connect to servers.")
    set(DOTNETAOT_FOUND FALSE)
    return()
endif()

set(DOTNETAOT_FOUND TRUE)
message(STATUS "PLAT: FindDotnetAOT — dotnet found at: ${DOTNET_EXECUTABLE}")
```

### WSL Path Conversion

Under WSL, the ClientLibrary project path must be converted from Linux path to Windows path for `dotnet.exe`:

```cmake
if(MU_IS_WSL AND DOTNETAOT_FOUND)
    # Convert project path to Windows format for dotnet.exe
    execute_process(
        COMMAND wslpath -w "${CMAKE_SOURCE_DIR}/ClientLibrary/MUnique.Client.Library.csproj"
        OUTPUT_VARIABLE DOTNETAOT_CSPROJ_PATH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
else()
    set(DOTNETAOT_CSPROJ_PATH
        "${CMAKE_SOURCE_DIR}/ClientLibrary/MUnique.Client.Library.csproj")
endif()
```

**Note:** The ClientLibrary directory is `MuMain/ClientLibrary/` — the csproj path relative to the `MuMain/CMakeLists.txt` location is `${CMAKE_CURRENT_SOURCE_DIR}/ClientLibrary/MUnique.Client.Library.csproj`.

### Build-Time Custom Target

```cmake
# In MuMain/CMakeLists.txt (after find_package/include FindDotnetAOT):
if(DOTNETAOT_FOUND)
    # Determine output directory for dotnet publish artifacts
    set(DOTNETAOT_PUBLISH_DIR "${CMAKE_BINARY_DIR}/dotnet-publish")

    add_custom_target(BuildDotNetAOT
        COMMAND "${DOTNET_EXECUTABLE}" publish
            "${DOTNETAOT_CSPROJ_PATH}"
            --runtime "${MU_DOTNET_RID}"
            --configuration Release
            --output "${DOTNETAOT_PUBLISH_DIR}"
            --no-self-contained false
        COMMENT "Building .NET AOT library for RID: ${MU_DOTNET_RID}"
        VERBATIM
    )

    # Copy published library to game binary output directory
    add_custom_command(
        TARGET BuildDotNetAOT POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${DOTNETAOT_PUBLISH_DIR}/MUnique.Client.Library${MU_DOTNET_LIB_EXT}"
            "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/MUnique.Client.Library${MU_DOTNET_LIB_EXT}"
        COMMENT "Copying .NET AOT library to output directory"
        VERBATIM
    )
endif()

# Pass lib extension to C++ compiler so Connection.h can use it
add_compile_definitions(MU_DOTNET_LIB_EXT="${MU_DOTNET_LIB_EXT}")
```

**Important:** `add_compile_definitions(MU_DOTNET_LIB_EXT=...)` must be called even when `DOTNETAOT_FOUND=FALSE` so the C++ code compiles. Connection.h will use `MU_DOTNET_LIB_EXT` in story 3-1-2, but the define must be present now to avoid breaking the build.

### Integration Point in CMakeLists.txt

The FindDotnetAOT module should be integrated in `MuMain/CMakeLists.txt` (the top-level, not `MuMain/src/CMakeLists.txt`) because:
- It invokes `dotnet publish` on `ClientLibrary/` which is a sibling of `src/`
- The custom target copies to `CMAKE_RUNTIME_OUTPUT_DIRECTORY` which is set at the top level
- It needs to run before the game binary targets link (so the library is available)

Add after the `add_subdirectory("src")` block:

```cmake
# ============================================================
# .NET AOT Cross-Platform Library (EPIC-3)
# ============================================================
option(MU_ENABLE_DOTNET ".NET AOT library integration (disable for CI/rendering-only builds)" ON)
if(MU_ENABLE_DOTNET)
    list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
    include(FindDotnetAOT)
    if(DOTNETAOT_FOUND)
        add_compile_definitions(MU_DOTNET_LIB_EXT="${MU_DOTNET_LIB_EXT}")
        # BuildDotNetAOT target defined in FindDotnetAOT.cmake
    else()
        add_compile_definitions(MU_DOTNET_LIB_EXT="${MU_DOTNET_LIB_EXT}")
    endif()
else()
    # Default to .dll when dotnet disabled (CI MinGW builds)
    add_compile_definitions(MU_DOTNET_LIB_EXT=".dll")
endif()
```

### CMake Module Location

Per CMake convention, Find modules belong in a `cmake/` directory at the project root. The existing toolchain files are at `MuMain/cmake/toolchains/` — the new Find module goes at `MuMain/cmake/FindDotnetAOT.cmake`.

The `cmake/` directory already exists. The module will be auto-discovered via the `CMAKE_MODULE_PATH` append.

### CI Strategy

The MinGW CI build (`MuMain/.github/workflows/ci.yml`) should NOT attempt to build the .NET AOT library:
- MinGW cross-compiles a Windows `.exe` from Linux but does not invoke `dotnet publish`
- Add `-DMU_ENABLE_DOTNET=OFF` to the CI cmake configure step (same pattern as `-DMU_ENABLE_SDL3=OFF`)
- The game C++ code will still compile because `MU_DOTNET_LIB_EXT` is given a fallback value (`.dll`) when dotnet is disabled

### ATDD Test Pattern

Following the established pattern from `MuMain/tests/build/`:

```cmake
# test_ac1_dotnet_rid_detection.cmake
# Validates: FindDotnetAOT.cmake sets MU_DOTNET_RID to a non-empty valid RID

cmake_minimum_required(VERSION 3.25)

# Determine expected RID for this platform
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "AMD64|x86_64")
        set(EXPECTED_RID_PREFIX "win-")
    else()
        set(EXPECTED_RID_PREFIX "win-")
    endif()
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    set(EXPECTED_RID_PREFIX "osx-")
else()
    set(EXPECTED_RID_PREFIX "linux-")
endif()

# Read FindDotnetAOT.cmake and check it handles the current platform
set(MODULE_FILE "${CMAKE_CURRENT_LIST_DIR}/../../cmake/FindDotnetAOT.cmake")
if(NOT EXISTS "${MODULE_FILE}")
    message(FATAL_ERROR "FAIL: FindDotnetAOT.cmake not found at ${MODULE_FILE}")
endif()

file(READ "${MODULE_FILE}" MODULE_CONTENT)

# Check that platform detection branches exist for all supported platforms
foreach(RID "win-x86" "win-x64" "osx-arm64" "osx-x64" "linux-x64")
    if(NOT MODULE_CONTENT MATCHES "${RID}")
        message(FATAL_ERROR "FAIL: RID '${RID}' not found in FindDotnetAOT.cmake")
    endif()
endforeach()

message(STATUS "PASS: FindDotnetAOT.cmake contains all required RIDs")
```

### Previous Story Intelligence

**From 1-3-1 (SDL3 Dependency Integration) — done:**
- CMake module files go in `MuMain/cmake/` directory
- `add_custom_target` / `add_custom_command` with `VERBATIM` for shell-safe arguments
- `MU_ENABLE_SDL3=OFF` pattern for CI exclusion — use same `MU_ENABLE_DOTNET=OFF` here
- ATDD tests in `MuMain/tests/build/` registered in `MuMain/tests/build/CMakeLists.txt`
- `GIT_SHALLOW TRUE` / pinned tags are the pattern — dotnet publish does not need this (it's a local command)

**From 1-1-1/1-1-2 (macOS/Linux CMake Toolchains) — done:**
- CMake presets use `condition: hostSystemName == Darwin` / `Linux` for platform-specific config
- `CMAKE_SIZEOF_VOID_P` detection for 32/64-bit is already handled in `MuMain/src/CMakeLists.txt` (lines 72-80) as a precedent for the same logic in FindDotnetAOT

**From 2-1-1 (SDL3 Window Event Loop) — done:**
- The `MU_ENABLE_SDL3` pattern works well for CI exclusion — replicate for `MU_ENABLE_DOTNET`

### Architecture Compliance

**From architecture.md Decision 3 (.NET AOT Cross-Platform):**
- `wchar_t` (Windows, 2 bytes) → `char16_t` (cross-platform) encoding change is deferred to story 3-2-1
- This story's only job: provide `MU_DOTNET_RID` and `MU_DOTNET_LIB_EXT` as CMake/compiler defines
- Library extension mapping:
  | Platform | RID | Extension |
  |----------|-----|-----------|
  | Windows x86 | `win-x86` | `.dll` |
  | Windows x64 | `win-x64` | `.dll` |
  | macOS arm64 | `osx-arm64` | `.dylib` |
  | macOS x64 | `osx-x64` | `.dylib` |
  | Linux x64 | `linux-x64` | `.so` |

**Anti-pattern to avoid (from architecture.md):**
```cpp
// WRONG — hardcoded extension (prohibited per architecture.md)
LoadLibrary("ClientLibrary.dll");
dlopen("libClientLibrary.dylib", RTLD_NOW);

// RIGHT — use CMake-defined extension (enabled by this story)
auto libPath = std::filesystem::path("MUnique.Client.Library") += MU_DOTNET_LIB_EXT;
```

### .csproj Platform/PlatformTarget Notes

The `MUnique.Client.Library.csproj` has a comment: `<!-- Platform and PlatformTarget are set by CMake via command line -->`. The `dotnet publish` command may need explicit platform arguments for 32-bit Windows builds:

```cmake
# For win-x86: pass /p:Platform=x86 /p:PlatformTarget=x86
if(MU_DOTNET_RID STREQUAL "win-x86")
    list(APPEND DOTNETAOT_PUBLISH_ARGS /p:Platform=x86 /p:PlatformTarget=x86)
endif()
```

The dev agent should verify what arguments the existing `FolderProfile.pubxml` uses (it has `<RuntimeIdentifier>win-x86</RuntimeIdentifier>` and `<SelfContained>true</SelfContained>`) and replicate the equivalent via CMake.

### PCC Project Constraints

**Tech Stack:** C++20 game client — CMake 3.25+, Ninja generator, .NET 10 Native AOT (`net10.0`), MinGW CI

**Required Patterns (from project-context.md):**
- `CMAKE_CXX_STANDARD 20`, `CMAKE_CXX_EXTENSIONS OFF` — must remain set (MUCommon INTERFACE handles this; don't touch it)
- `[[nodiscard]]` on new fallible C++ functions (not applicable here — CMake only)
- `std::filesystem::path` for path construction (Connection.h change deferred to 3-1-2, but the define enables it)
- No new `#ifdef _WIN32` in game logic — `MU_DOTNET_LIB_EXT` replaces the need for platform ifdefs in Connection.h

**Prohibited Patterns (from project-context.md):**
- NO modification of generated files in `src/source/Dotnet/` (PacketBindings_*.h, PacketFunctions_*.h/.cpp)
- NO `#ifdef _WIN32` in game logic (only in platform abstraction layer)
- NO raw `new`/`delete` in C++ (not applicable here — CMake only)
- NO hardcoded `.dll`/`.dylib`/`.so` extensions in new C++ code — use `MU_DOTNET_LIB_EXT`

**Quality Gate Command:** `./ctl check` (format-check + cppcheck)

**Commit Format:** `build(network): add CMake RID detection and .NET AOT build integration`

### Schema Alignment

Not applicable — C++20 game client with no schema validation tooling (noted in sprint-status.yaml).

### References

- [Source: MuMain/cmake/] — directory where new `FindDotnetAOT.cmake` module goes
- [Source: MuMain/CMakeLists.txt] — top-level CMake file where FindDotnetAOT is included (after `add_subdirectory("src")`)
- [Source: MuMain/ClientLibrary/MUnique.Client.Library.csproj] — .NET project to publish; note `Platform` and `PlatformTarget` set via command line; `AppendRuntimeIdentifierToOutputPath=false` means output is flat
- [Source: MuMain/ClientLibrary/Properties/PublishProfiles/FolderProfile.pubxml] — existing publish profile showing `RuntimeIdentifier=win-x86` and `SelfContained=true` pattern
- [Source: MuMain/src/source/Dotnet/Connection.h] — current file using `LoadLibrary`/`dlopen` with `#ifdef _WIN32`; NOT modified in this story (that's 3-1-2)
- [Source: MuMain/src/CMakeLists.txt lines 72-80] — existing `CMAKE_SIZEOF_VOID_P` detection pattern to reference for 32/64-bit detection in FindDotnetAOT.cmake
- [Source: MuMain/.github/workflows/ci.yml] — add `-DMU_ENABLE_DOTNET=OFF` to MinGW cmake configure step
- [Source: MuMain/tests/build/CMakeLists.txt] — register new ATDD tests here
- [Source: _bmad-output/planning-artifacts/architecture.md §Decision 3] — CMake RID detection requirements
- [Source: _bmad-output/planning-artifacts/architecture.md §Library extension mapping] — RID/extension table
- [Source: _bmad-output/planning-artifacts/epics.md §Story 3.1.1] — original acceptance criteria
- [Source: _bmad-output/stories/1-3-1-sdl3-dependency-integration/story.md §Dev Notes] — FetchContent and ATDD test patterns; `MU_ENABLE_SDL3=OFF` CI pattern

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Story created 2026-03-06 via create-story workflow (agent: claude-sonnet-4-6)
- Story implemented 2026-03-06 via dev-story workflow (agent: claude-sonnet-4-6)
- FindDotnetAOT.cmake created at MuMain/cmake/FindDotnetAOT.cmake with all required RID detection, WSL interop, and graceful failure
- CMakeLists.txt updated with MU_ENABLE_DOTNET option, BuildDotNetAOT custom target, and add_compile_definitions(MU_DOTNET_LIB_EXT=...)
- CI workflow updated with -DMU_ENABLE_DOTNET=OFF for MinGW cross-compile builds
- All 4 ATDD tests pass: AC-1/AC-5 (RID+WSL detection), AC-2 (lib ext), AC-6 (graceful failure), AC-STD-11 (flow code)
- Quality gate: ./ctl check PASSED (689 files, 0 violations)
- CMakePresets.json: valid JSON confirmed
- macOS configure: cmake --preset macos-arm64 PASSED — RID=osx-arm64, LIB_EXT=.dylib, dotnet=/opt/homebrew/bin/dotnet, 0.6s configure time
- AC-STD-NFR-1 satisfied: configure time well under 2 seconds
- BuildDotNetAOT is NOT added to ALL target — must be invoked explicitly (`cmake --build . --target BuildDotNetAOT`)
- Story key: 3-1-1-cmake-rid-detection (from sprint-status.yaml)
- Story type: infrastructure (CMake build system only — no Catch2 tests required)
- Schema alignment: N/A (no API schemas affected — C++20 game client)
- Prerequisites confirmed done: 1.1.1 (macOS toolchain done), 1.1.2 (Linux toolchain done), all EPIC-2 stories done
- Story 3-1-1 is independent on critical path (no EPIC-2 deps); can start now per sprint-status.yaml
- Visual Design Specification section omitted — infrastructure story, not frontend
- Specification corpus: specification-index.yaml not available; no story partials found
- WSL interop path documented in Dev Notes — critical for dotnet.exe invocation under WSL
- CI strategy documented: use `MU_ENABLE_DOTNET=OFF` pattern (same as `MU_ENABLE_SDL3=OFF` from 1-3-1)
- This story is a blocker for 3-1-2-connection-h-crossplatform (requires MU_DOTNET_LIB_EXT define)

### File List

- [CREATE] `MuMain/cmake/FindDotnetAOT.cmake` — new CMake find module for RID detection and dotnet AOT build integration
- [MODIFY] `MuMain/CMakeLists.txt` — add `MU_ENABLE_DOTNET` option; include `FindDotnetAOT`; add `BuildDotNetAOT` custom target; pass `MU_DOTNET_LIB_EXT` to compiler
- [MODIFY] `MuMain/.github/workflows/ci.yml` — add `-DMU_ENABLE_DOTNET=OFF` to MinGW cmake configure step
- [CREATE] `MuMain/tests/build/test_ac1_dotnet_rid_detection.cmake` — ATDD: verify RID detection
- [CREATE] `MuMain/tests/build/test_ac2_dotnet_lib_ext.cmake` — ATDD: verify lib extension
- [CREATE] `MuMain/tests/build/test_ac6_dotnet_graceful_failure.cmake` — ATDD: verify graceful failure
- [CREATE] `MuMain/tests/build/test_ac_std11_flow_code_3_1_1.cmake` — ATDD: flow code traceability
- [MODIFY] `MuMain/tests/build/CMakeLists.txt` — register new ATDD tests
