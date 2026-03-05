# MuMain Development Guide

## Prerequisites

| Requirement | Version | Purpose |
|------------|---------|---------|
| **CMake** | 3.25+ | Build system (bundled with Visual Studio and CLion) |
| **.NET SDK** | 10.0+ | Building the ClientLibrary (Native AOT) |
| **C++ Compiler** | MSVC 2022+ or MinGW-w64 | Game client compilation |
| **Ninja** | Latest | Fast parallel builds (recommended) |
| **Git** | Latest | Submodule management (ImGui) |

### IDE Options

| IDE | Best For | Notes |
|-----|----------|-------|
| **WSL + MinGW** (Recommended) | Daily dev, Claude Code | Fastest iteration |
| **Visual Studio 2022** | Debugging, MSVC builds | Open root `MuMain/` folder |
| **CLion** | Cross-platform dev | CMake native support |
| **Rider** | C# work | Needs VS solution generation |

## Quick Start

### 1. Clone and Initialize

```bash
git clone --recursive <repo-url>
cd MuMain-workspace/MuMain

# If submodules weren't initialized:
git submodule update --init
```

### 2. Build by OS

#### macOS — Quality Gates Only

macOS **cannot** compile the game client — the codebase requires Win32 APIs, DirectX, and `windows.h` which are unavailable on macOS. Use macOS for editing, code quality checks, and static analysis.

```bash
# Install quality tools (one-time)
brew install clang-format cppcheck

# Run quality gate (format-check + lint, mirrors CI)
cd .. && ./ctl check

# Auto-format all C++ files
./ctl format

# Individual checks
make format-check
make lint
```

#### macOS — Native Build (arm64)

macOS can now configure the CMake project natively using the `macos-arm64` preset. Full compilation is blocked until the SDL3 windowing migration (EPIC-2) removes Win32 API dependencies from game logic, but the configure step succeeds and validates the build system.

**Prerequisites:**

| Requirement | Version | Install |
|-------------|---------|---------|
| Xcode Command Line Tools | Latest | `xcode-select --install` |
| Clang | 15+ (ships with Xcode CLI tools) | Included with Xcode CLI tools |
| CMake | 3.25+ | `brew install cmake` |
| Ninja | Latest | `brew install ninja` |

```bash
# Install build tools (one-time, Clang ships with Xcode CLI tools)
xcode-select --install
brew install cmake ninja

# Configure (from MuMain/ directory)
cd MuMain
cmake --preset macos-arm64

# Attempt build (will partially succeed — Win32 translation units fail until EPIC-2)
cmake --build --preset macos-arm64-debug
```

> **Note:** SDL3 is fetched via FetchContent on the first configure (requires internet, ~30 seconds). Subsequent configures use the cached download. To skip SDL3 for quality-gate-only work, use `./ctl check` from the workspace root instead.

> **Note:** .NET SDK is required for server connectivity. The game configures without it, but cannot connect to servers. See the [.NET SDK note](#3-run) for details.

> **Current limitation:** `cmake --build` will fail on translation units that include Win32 headers (`windows.h`, DirectX). This is expected — the SDL3 cross-platform migration (EPIC-2+) will progressively remove these dependencies. The configure step validates that CMake, toolchains, and SDL3 integration are working correctly.

> **Running:** No runnable binary is produced on macOS until EPIC-2 completes the Win32→SDL3 windowing migration. Once available, the binary will be at `build-macos-arm64/bin/MuMain`. For now, use the MinGW cross-compile on WSL to produce a runnable Windows `.exe`.

#### Linux / WSL — Full Build (Recommended)

MinGW cross-compiles a 32-bit Windows `.exe` from Linux. **WSL is the recommended daily-dev environment** — fastest iteration with Claude Code.

```bash
# Install toolchain (one-time)
sudo apt-get update && sudo apt-get install -y mingw-w64 g++-mingw-w64-i686 cmake ninja-build

# Configure
cmake -S . -B build-mingw -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/mingw-w64-i686.cmake \
  -DCMAKE_BUILD_TYPE=Debug \
  -DENABLE_EDITOR=ON \
  -DMU_TURBOJPEG_STATIC_LIB=_deps/mingw-i686/lib/libturbojpeg.a

# Build
cmake --build build-mingw -j$(nproc)

# Quality gate
cd .. && ./ctl check
```

> **Note:** .NET Native AOT (`ClientLibrary/`) requires Windows `dotnet.exe`. On WSL, it is found via interop at `/mnt/c/Program Files/dotnet/dotnet.exe`. On native Linux without Windows, the game compiles but cannot connect to servers (the .NET DLL is skipped).

#### Linux — Native Build (x64)

Linux can configure and attempt to build the project natively using the `linux-x64` preset. Like macOS, full compilation is blocked until the SDL3 windowing migration (EPIC-2) removes Win32 API dependencies, but the configure step succeeds and validates the build system. This is distinct from the MinGW/WSL cross-compile above, which produces a Windows `.exe`.

**Prerequisites:**

| Requirement | Version | Install |
|-------------|---------|---------|
| GCC | 12+ (for full C++20 support) | `sudo apt-get install gcc g++` |
| CMake | 3.25+ | `sudo apt-get install cmake` |
| Ninja | Latest | `sudo apt-get install ninja-build` |
| OpenGL dev headers | Latest | `sudo apt-get install libgl1-mesa-dev` |

```bash
# Install toolchain (one-time)
sudo apt-get update && sudo apt-get install -y cmake ninja-build gcc g++ libgl1-mesa-dev

# Configure (from MuMain/ directory)
cd MuMain
cmake --preset linux-x64

# Attempt build (will partially succeed — Win32 translation units fail until EPIC-2)
cmake --build --preset linux-x64-debug
```

> **Note:** SDL3 is fetched via FetchContent on the first configure (requires internet, ~30 seconds). Subsequent configures use the cached download.

> **Note:** The native Linux build produces a native Linux binary (not a Windows `.exe`). Game logic still includes Win32 headers, but cross-platform abstraction headers from EPIC-1 guard them. Full compilation will succeed progressively as EPIC-2+ removes Win32 dependencies.

> **Note:** .NET SDK is required for server connectivity. On native Linux without Windows, the .NET DLL is skipped — the game configures but cannot connect to servers.

> **Running:** No runnable binary is produced on native Linux until EPIC-2 completes the Win32→SDL3 windowing migration. Once available, the binary will be at `build-linux-x64/bin/MuMain`. For now, use the MinGW cross-compile (above) to produce a runnable Windows `.exe`.

#### Windows — MSVC Presets

Native Windows build using Visual Studio and CMake presets. Full .NET Native AOT support included.

```powershell
# x86 (standard 32-bit game build)
cmake --preset windows-x86
cmake --build --preset windows-x86-debug

# x86 with editor
cmake --preset windows-x86-mueditor
cmake --build --preset windows-x86-mueditor-debug

# x64
cmake --preset windows-x64
cmake --build --preset windows-x64-debug

# x64 with editor
cmake --preset windows-x64-mueditor
cmake --build --preset windows-x64-mueditor-debug
```

### 3. Run

```bash
# WSL/MinGW
cd build-mingw/src && ./Main.exe

# Windows x86
./out/build/windows-x86/src/Debug/Main.exe

# Windows x64
./out/build/windows-x64/src/Debug/Main.exe

# With server connection
Main.exe connect /u192.168.0.20 /p55902
```

Default connection: `localhost:44406` (requires [OpenMU](https://github.com/MUnique/OpenMU) server).

## Build Configurations

| Preset | Architecture | Editor | Use Case |
|--------|-------------|--------|----------|
| `windows-x86` | 32-bit | No | Standard game build |
| `windows-x86-mueditor` | 32-bit | Yes | Debug with ImGui editor |
| `windows-x64` | 64-bit | No | 64-bit game build |
| `windows-x64-mueditor` | 64-bit | Yes | 64-bit debug with editor |

### Debug vs Release

- **Debug** (`_DEBUG`, `_FOREIGN_DEBUG`): Full symbols, editor support, assertions
- **Release** (`NDEBUG`, `_FOREIGN_NDEBUG`, `LDS_PATCH_GLOBAL_100520`): Optimized, no editor

### Editor Toggle

- Compile-time: `-DENABLE_EDITOR=ON` (adds `_EDITOR` define)
- Runtime: Press **F12** to toggle, or launch with `--editor` flag
- Release builds: Zero editor overhead — all code excluded via `#ifdef _EDITOR`

## Environment Setup

### Configuration File

`src/bin/config.ini` — auto-created on first run:

```ini
[Window]
Width=1024
Height=768
Windowed=1

[Graphics]
ColorDepth=0
RenderTextType=0

[Audio]
SoundEnabled=0
MusicEnabled=0
VolumeLevel=5

[CONNECTION SETTINGS]
ServerIP=127.127.127.127
ServerPort=44406
```

### Game Assets

Assets are in `src/bin/Data/` (13,169 files). The post-build step automatically copies them to the build output directory. No manual asset setup needed.

### Translations

9 supported locales in `src/bin/Translations/`:
- English (en), German (de), Spanish (es), Portuguese (pt)
- Russian (ru), Polish (pl), Ukrainian (uk), Indonesian (id), Tagalog (tl)

Each locale has 3 JSON files: `game.json`, `editor.json` (debug), `metadata.json` (debug).

## Key Development Commands

### Chat Commands (In-Game)

| Command | Description |
|---------|-------------|
| `$fps <value>` | Set FPS limit |
| `$vsync on/off` | Toggle VSync |
| `$fpscounter on/off` | Show FPS counter |
| `$details on/off` | Show performance overlay |

### Build System

```bash
# Clean build
rm -rf build-mingw  # or: Remove-Item -Recurse out (Windows)

# Rebuild only C++ (skip .NET if unchanged)
cmake --build build-mingw -j$(nproc)

# Force .NET rebuild
touch ClientLibrary/ConnectionManager.cs && cmake --build build-mingw
```

### Code Generation (Packet Bindings)

The XSLT code generation runs automatically during Visual Studio builds (PreBuild target). For MinGW builds, use the ConstantsReplacer tool or regenerate manually.

**Generated files** (do not edit directly):
- `src/source/Dotnet/PacketBindings_*.h`
- `src/source/Dotnet/PacketFunctions_*.h/cpp`
- `ClientLibrary/ConnectionManager.*Functions.cs`

## Code Quality Tooling

### Setup (one-time)

```bash
cd MuMain

# Install git hooks (blocks commits with unformatted C++)
make hooks

# Verify tools are available
clang-format --version   # formatting
cppcheck --version       # static analysis
clang-tidy --version     # deeper static analysis (optional)
```

### Daily Workflow

```bash
# Format all C++ files
make format

# Check formatting without modifying (same check CI runs)
make format-check

# Run static analysis
make lint

# Run clang-tidy (needs a configured build directory)
make tidy

# Build and run unit tests
make test
```

### What Gets Enforced

| Gate | Tool | When | Blocks? |
|------|------|------|---------|
| Formatting | clang-format | Pre-commit hook + CI | Yes |
| Compiler warnings | `-Wall -Wextra -Werror` | Every build | Yes |
| Static analysis | cppcheck | CI (changed files) | Yes |
| Deep analysis | clang-tidy | Local (`make tidy`) | No (manual) |
| Unit tests | Catch2 | Local (`make test`) | No (opt-in) |

### Configuration Files

| File | Purpose |
|------|---------|
| `.clang-format` | Formatting rules (Allman braces, 4-space indent) |
| `.clang-tidy` | Static analysis checks (bugprone, modernize, performance) |
| `.cppcheck` | cppcheck configuration |
| `.editorconfig` | Editor indent/encoding settings |
| `scripts/pre-commit` | Git hook source |
| `scripts/install-hooks.sh` | Hook installer |

## Testing

### Unit Tests (Catch2)

```bash
# Build with tests enabled
cmake -S . -B build-test -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build build-test --target MuTests -j$(nproc)
ctest --test-dir build-test --output-on-failure

# Or use the shortcut
make test
```

Test files live in `tests/` with the same module structure as `src/source/`.

### Manual Testing Checklist

1. **Window/rendering**: Game opens, 3D scene renders correctly
2. **Input**: Mouse click targets, keyboard shortcuts (F1-F12, arrows, Ctrl+combos)
3. **Audio**: Sound effects play, music loops
4. **Network**: Connect to OpenMU server, login flow completes
5. **UI**: Inventory, shop, chat, minimap all functional
6. **Editor** (debug): F12 toggles, console shows output, item editor works

### CI Validation

GitHub Actions runs on every PR to `main`:

1. **Code Quality Gates** (parallel job): clang-format + cppcheck on changed C++ files
2. **MinGW Build**: Cross-compile with `-Werror` — all warnings are errors
3. Both jobs must pass for the PR to merge

## Common Issues

### General / MinGW / Windows

| Issue | Solution |
|-------|----------|
| `Cannot find -lturbojpeg` | Install MinGW-w64 libjpeg-turbo or set `MU_TURBOJPEG_STATIC_LIB` |
| `.NET SDK not found` | Install .NET 10.0+ SDK; game runs without it but can't connect to server |
| ImGui submodule missing | `git submodule update --init` from repository root |
| NuGet cache fails (umlauts in path) | Set `cmake -DMU_NUGET_CACHE_DIR=C:/.mu-nuget` |
| Z: drive slow builds (CLion) | Put build output on Windows-native drive: `C:\build\MuMain-...` |

### macOS

| Issue | Solution |
|-------|----------|
| SDL3 FetchContent slow or fails | Check internet connection. FetchContent downloads SDL3 from GitHub on first configure (~30 sec). If behind a proxy, configure `HTTP_PROXY`/`HTTPS_PROXY` environment variables. To skip SDL3 entirely for quality-gate-only work, use `./ctl check` instead of configuring with a preset. |
| `Cannot find framework` / missing system headers | Ensure Xcode Command Line Tools are installed: `xcode-select --install`. If recently updated macOS, re-run the install command. |
| `cmake --preset macos-arm64` fails with "preset not found" | Ensure you are running from the `MuMain/` directory (not the workspace root). Presets are defined in `MuMain/CMakePresets.json`. |
| Build fails on Win32 translation units | Expected behavior until EPIC-2 completes the SDL3 windowing migration. The configure step succeeding is the current goal. |

### Linux

| Issue | Solution |
|-------|----------|
| `libGL not found` / `GL/gl.h: No such file` | Install OpenGL development headers: `sudo apt-get install libgl1-mesa-dev` |
| C++20 features not available / compilation errors | Upgrade to GCC 12+: `sudo apt-get install gcc-12 g++-12` and set `CC=gcc-12 CXX=g++-12` before configuring. |
| SDL3 FetchContent slow or fails | Same as macOS — check internet connection. FetchContent downloads SDL3 from GitHub on first configure. Configure proxy variables if needed. |
| `cmake --preset linux-x64` fails with "preset not found" | Ensure you are running from the `MuMain/` directory. Also verify the host OS condition: the preset requires `hostSystemName == Linux` (will not work under WSL if CMake reports Windows). |
| Build fails on Win32 translation units | Expected behavior until EPIC-2 completes the SDL3 windowing migration. The configure step succeeding is the current goal. |

## Project Conventions

- **C++ Standard**: C++20 (`cxx_std_20`)
- **Character Encoding**: UTF-16LE in memory, UTF-8 for files/network
- **Naming**: PascalCase for classes, camelCase for locals, ALL_CAPS for constants/enums
- **Feature Flags**: `#define` in `Defined_Global.h` (e.g., `ASG_ADD_GENS_SYSTEM`)
- **UI Classes**: `CNewUI*` prefix for all UI windows
- **Precompiled Header**: `stdafx.h` — must be included first in every .cpp
