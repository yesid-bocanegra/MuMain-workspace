# MuMain-workspace — Claude Code Context

## Project

MU Online game client (Season 5.2→6). C++20 monolithic game loop + .NET 10 Native AOT network bridge + XSLT code generation. Currently planning a 10-phase SDL3 cross-platform migration (Linux + macOS).

## Key Paths

- **Game client source:** `MuMain/src/source/` (692 files in 20 module directories)
- **Entry point:** `MuMain/src/source/Main/Winmain.cpp` → `WinMain()`
- **Module structure:** See `docs/modular-reorganization.md` for directory map and CMake targets
- **.NET network layer:** `MuMain/ClientLibrary/` (14 files)
- **Code gen tool:** `MuMain/ConstantsReplacer/` (10 files)
- **Debug editor:** `MuMain/src/MuEditor/` (34 files, `_EDITOR` builds)
- **Game assets:** `MuMain/src/bin/Data/`
- **Documentation:** `docs/`
- **Feature flags:** `MuMain/src/source/Core/Defined_Global.h`
- **PCH:** `MuMain/src/source/Main/stdafx.h`
- **Build presets:** `MuMain/CMakePresets.json`
- **i18n:** `MuMain/src/source/Translation/i18n.h`
- **CI:** `MuMain/.github/workflows/ci.yml`

## Build Commands (by OS)

### macOS — Quality Gates Only

macOS **cannot** compile the game client (requires Win32 APIs, DirectX, `windows.h`). Use macOS for code quality checks and editing only.

```bash
brew install clang-format cppcheck          # one-time
./ctl check                                 # format-check + lint (mirrors CI)
./ctl format                                # auto-format all C++ files
```

### macOS — Native Build (arm64)

macOS can configure the CMake project natively. Full compilation is blocked until EPIC-2 (SDL3 windowing migration), but configure succeeds and validates the build system.

```bash
# Install build tools (one-time, Clang ships with Xcode CLI tools)
xcode-select --install
brew install cmake ninja

# Configure and attempt build (from MuMain/ directory)
cd MuMain
cmake --preset macos-arm64
cmake --build --preset macos-arm64-debug    # partial — Win32 TUs fail until EPIC-2
```

> **Note:** SDL3 is fetched via FetchContent on first configure (internet required, ~30 sec). `.NET` SDK needed for server connectivity.

### Linux / WSL — MinGW Cross-Compile (Recommended)

MinGW cross-compiles a Windows `.exe` from Linux. WSL is the recommended daily-dev environment.

```bash
# Install toolchain (one-time)
sudo apt-get update && sudo apt-get install -y mingw-w64 g++-mingw-w64-i686 cmake ninja-build

# Build
cmake -S MuMain -B build-mingw -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=MuMain/cmake/toolchains/mingw-w64-i686.cmake \
  -DCMAKE_BUILD_TYPE=Debug -DENABLE_EDITOR=ON \
  -DMU_TURBOJPEG_STATIC_LIB=_deps/mingw-i686/lib/libturbojpeg.a
cmake --build build-mingw -j$(nproc)

# Quality gates
./ctl check
```

> **Note:** .NET Native AOT (`ClientLibrary/`) requires Windows `dotnet.exe`. WSL finds it via interop at `/mnt/c/Program Files/dotnet/dotnet.exe`. Without it, the game compiles but cannot connect to servers.

### Linux — Native Build (x64)

Linux can configure the CMake project natively. Full compilation is blocked until EPIC-2 (SDL3 windowing migration), but configure succeeds and validates the build system.

```bash
# Install toolchain (one-time)
sudo apt-get update && sudo apt-get install -y cmake ninja-build gcc g++ libgl1-mesa-dev

# Configure and attempt build (from MuMain/ directory)
cd MuMain
cmake --preset linux-x64
cmake --build --preset linux-x64-debug      # partial — Win32 TUs fail until EPIC-2
```

> **Note:** SDL3 is fetched via FetchContent on first configure (internet required, ~30 sec). GCC 12+ required for full C++20 support.

### Windows — MSVC Presets

```powershell
cmake --preset windows-x64
cmake --build --preset windows-x64-debug

# With editor
cmake --preset windows-x64-mueditor
cmake --build --preset windows-x64-mueditor-debug
```

## Conventions

- **Commits:** Conventional Commits format — `type(scope): description` (e.g., `feat(ui):`, `fix(network):`, `refactor:`). Semantic-release parses these for automated versioning. See `docs/development-standards.md` §6.
- **C++ naming:** PascalCase functions, `m_` prefix members with Hungarian hints (`by`, `w`, `dw`, `sz`, `p`), `CNewUI*` UI classes, UPPER_SNAKE constants
- **Formatting:** 4 spaces, UTF-8, LF, Allman braces (per `.editorconfig`)
- **New code:** `std::unique_ptr` (no raw `new`/`delete`), `nullptr` (not `NULL`), `std::chrono` (not `timeGetTime`), `std::filesystem` for paths
- **i18n:** `GAME_TEXT("key")` for user-facing strings, `EDITOR_TEXT("key")` in editor builds
- **Feature flags:** Author-prefixed defines in `Defined_Global.h` (e.g., `ASG_ADD_GENS_SYSTEM`)
- **C#:** StyleCop enforced, `[UnmanagedCallersOnly]` for AOT exports, VSTHRD103 as error
- **Logging:** `g_ErrorReport.Write()` for post-mortem, `g_ConsoleDebug->Write()` for live debug; no `wprintf` in new code
- **Error handling:** Return codes (no exceptions in game loop), `assert` for internal invariants only, `[[nodiscard]]` on new fallible functions

## Generated Files — DO NOT EDIT

XSLT-generated from XML packet definitions. Located in `MuMain/src/source/Dotnet/`:
- `PacketBindings_*.h`
- `PacketFunctions_*.h` / `.cpp`

## Cross-Platform Rules

- No new Win32 API calls — check banned API table in `docs/development-standards.md`
- No `#ifdef _WIN32` in game logic — only in platform abstraction layer
- No backslash path literals, no `wchar_t` in new serialization
- Forward slashes, `std::filesystem::path` for new code
- CI (MinGW) build must pass on all changes

## Documentation — Load On Demand

Start with `docs/index.md` (~100 lines) for the full index with section navigation hints. Load individual docs only when relevant to your current task.

| When working on... | Load (lines) |
|---------------------|-------------|
| Cross-platform migration | `modular-reorganization.md` (~120) + `development-standards.md` §1 (~150 lines) + `CROSS_PLATFORM_PLAN.md` (relevant phase, ~100 lines each) |
| Game client features | `game-systems-reference.md` (~300) + `architecture-mumain.md` (~185) |
| Rendering / shaders | `architecture-rendering.md` (~190) |
| Network protocol | `packet-protocol-reference.md` (~230) + `architecture-clientlibrary.md` (~140) |
| Build / CI issues | `development-guide.md` (~400) + `troubleshooting.md` (~150) + `ci-workflows.md` (~130) |
| Asset loading | `asset-pipeline.md` (~230) |
| Error handling / logging | `development-standards.md` §2 Error Handling & Logging (~110 lines) |
| Static analysis (cppcheck) | `cppcheck-guidance.md` (~100) |
| Planning a new feature | `implementation-recipes.md` (relevant recipe, ~80-120 lines each) |
| Assessing change impact | `feature-impact-maps.md` (relevant system, ~25-45 lines each) |
| Security review | `security-guidelines.md` (~130) |
| Performance optimization | `performance-guidelines.md` (~130) |
| Architectural decisions | `adr/README.md` + relevant ADR files |

Large files (>400 lines): `CROSS_PLATFORM_PLAN.md` (970 lines) — always read specific phase sections, never the full file.

<!-- PCC-START — managed by PCC deploy, do not edit manually -->
# PCC Module

PCC (Project-specific Customizations and Constraints) is a BMAD add-on that provides automated story lifecycle, quality gates, and sprint management.

## Key Paths

- `_bmad/pcc/` — workflows, tasks, templates, agents, rules
- `paw_runner/` — automation pipeline (invoked via `./paw`)

## Usage

Run the full story pipeline:
```bash
./paw story-key          # auto-detect and resume from last step
./paw story-key --from DEV_STORY --to CODE_REVIEW_QG
```

Invoke workflows directly:
```bash
/bmad:pcc:workflows:dev-story
/bmad:pcc:workflows:code-review-quality-gate
/bmad:pcc:tasks:load-guidelines
```

## Do NOT

- Build code to "process" or "transform" workflows — they are prompts Claude reads directly
- Create YAML workflow definitions for code to execute
- Build a "workflow engine" or "dispatcher"
- Duplicate what `paw_runner/` already does

## Project Configuration

**Project:** MuMain

**Components:**
- `project-docs` — documentation (./_bmad-output) [documentation]
- `mumain` — cpp-cmake (./MuMain) [backend]

**Pencil design screens:** disabled
<!-- PCC-END -->
