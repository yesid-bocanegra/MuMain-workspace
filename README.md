# MuMain-workspace

MU Online game client (Season 5.2→6) — workspace repository containing the game client submodule, cross-platform migration planning, and project documentation.

## Components

| Component | Path | Tech Stack |
|-----------|------|------------|
| **MuMain** (Game Client) | `MuMain/src/source/` (697 files) | C++20, OpenGL, Win32, DirectSound |
| **ClientLibrary** (Network) | `MuMain/ClientLibrary/` | .NET 10, Native AOT, MUnique.OpenMU.Network.Packets |
| **ConstantsReplacer** (Code Gen) | `MuMain/ConstantsReplacer/` | .NET 8, WinForms |
| **MuEditor** (Debug Editor) | `MuMain/src/MuEditor/` | C++20, Dear ImGui |

## Architecture

- **Monolithic game loop** with function-based scene dispatch
- **.NET Native AOT bridge** for network packet handling (C++ ↔ C# interop via CoreCLR delegates)
- **XSLT code generation** from XML packet definitions (NuGet `MUnique.OpenMU.Network.Packets`)
- **10-phase SDL3 cross-platform migration** planned (Linux + macOS)

## Prerequisites

| Requirement | Version | Purpose |
|------------|---------|---------|
| **CMake** | 3.25+ | Build system (bundled with Visual Studio and CLion) |
| **.NET SDK** | 10.0+ | Building the ClientLibrary (Native AOT network layer) |
| **C++ Compiler** | MSVC 2022+ or MinGW-w64 | Game client compilation |
| **Ninja** | Latest | Fast parallel builds (recommended) |
| **Git** | Latest | Submodule management (ImGui) |
| **clang-format** | Latest | C++ formatting (enforced by pre-commit hook and CI) |
| **cppcheck** | Latest | Static analysis (enforced by CI) |
| **clang-tidy** | Latest | Deeper static analysis (optional) |

**Server**: A compatible [OpenMU](https://github.com/MUnique/OpenMU) server instance for testing connectivity.

### Installing on macOS (Homebrew)

```bash
brew install cmake ninja git dotnet llvm cppcheck

# LLVM is keg-only — add its tools to PATH (clang-format, clang-tidy)
echo 'export PATH="$(brew --prefix llvm)/bin:$PATH"' >> ~/.zshrc

# .NET SDK needs DOTNET_ROOT for other tools to find it
echo 'export DOTNET_ROOT="$(brew --prefix dotnet)/libexec"' >> ~/.zshrc

source ~/.zshrc
```

> **Note**: macOS builds use MinGW cross-compilation. Native macOS support is planned as part of the SDL3 migration.

### Installing on Linux (Ubuntu/Debian)

```bash
# Build essentials and cross-compiler
sudo apt-get update && sudo apt-get install -y \
  build-essential cmake ninja-build git \
  mingw-w64 g++-mingw-w64-i686 \
  clang-format clang-tidy cppcheck

# .NET SDK (https://learn.microsoft.com/dotnet/core/install/linux)
sudo apt-get install -y dotnet-sdk-10.0
```

For other distributions:

```bash
# Fedora/RHEL
sudo dnf install cmake ninja-build git mingw64-gcc-c++ \
  clang-tools-extra cppcheck dotnet-sdk-10.0

# Arch Linux
sudo pacman -S cmake ninja git mingw-w64-gcc \
  clang cppcheck dotnet-sdk
```

### Installing on Windows

**Option A: winget (recommended)**

```powershell
winget install Kitware.CMake
winget install Ninja-build.Ninja
winget install Git.Git
winget install Microsoft.DotNet.SDK.10
winget install LLVM.LLVM          # provides clang-format and clang-tidy
winget install --id Cppcheck.Cppcheck
```

**Option B: Visual Studio Installer**

Install **Visual Studio 2022** with the following workloads:
- **Desktop development with C++** (includes MSVC, CMake, Ninja)
- **.NET desktop development** (includes .NET SDK)
- Under Individual components, add: **C++ Clang tools for Windows** (clang-format, clang-tidy)

Then install cppcheck separately:
```powershell
winget install --id Cppcheck.Cppcheck
```

**Option C: Scoop**

```powershell
scoop install cmake ninja git dotnet-sdk llvm cppcheck
```

> **Verify installation** on any platform:
> ```bash
> cmake --version && ninja --version && dotnet --version && git --version
> clang-format --version && cppcheck --version
> ```

## Development Environment Setup

### 1. Clone and Initialize

```bash
git clone --recurse-submodules <repo-url>
cd MuMain-workspace

# If submodules weren't initialized automatically:
git submodule update --init
```

### 2a. Build with WSL + MinGW (Recommended)

This is the recommended workflow for daily development and Claude Code.

```bash
# Install toolchain (one-time)
sudo apt-get update && sudo apt-get install -y \
  mingw-w64 g++-mingw-w64-i686 cmake ninja-build

# Configure
cmake -S MuMain -B build-mingw -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=MuMain/cmake/toolchains/mingw-w64-i686.cmake \
  -DCMAKE_BUILD_TYPE=Debug \
  -DENABLE_EDITOR=ON \
  -DMU_TURBOJPEG_STATIC_LIB=_deps/mingw-i686/lib/libturbojpeg.a

# Build
cmake --build build-mingw -j$(nproc)
```

> **Tip**: Keep the repo on the WSL filesystem (`/home/<user>/...`), not on `/mnt/c/`. The Windows mount path is significantly slower.

### 2b. Build on Windows (MSVC Presets)

```powershell
# Standard x86 build
cmake --preset windows-x86 -S MuMain
cmake --build --preset windows-x86-debug

# With in-game editor (ImGui)
cmake --preset windows-x86-mueditor -S MuMain
cmake --build --preset windows-x86-mueditor-debug

# x64 builds
cmake --preset windows-x64 -S MuMain
cmake --build --preset windows-x64-debug
```

Available presets: `windows-x86`, `windows-x86-mueditor`, `windows-x64`, `windows-x64-mueditor` (each with `-debug` and `-release` build variants).

### 3. Set Up Code Quality Tools

```bash
cd MuMain

# Install git hooks (blocks commits with unformatted C++)
make hooks

# Verify tools are available
clang-format --version
cppcheck --version
```

### 4. Run the Client

```bash
# WSL/MinGW
cd build-mingw/src && ./Main.exe

# Windows x86
./MuMain/out/build/windows-x86/src/Debug/Main.exe

# With server connection parameters
main.exe connect /u192.168.0.20 /p55902
```

Default connection: `localhost:44406` (requires an [OpenMU](https://github.com/MUnique/OpenMU) server).

### 5. Run Tests

```bash
cd MuMain

# Build and run unit tests (Catch2)
make test

# Or manually:
cmake -S . -B build-test -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build build-test --target MuTests -j$(nproc)
ctest --test-dir build-test --output-on-failure
```

### 6. Daily Quality Workflow

```bash
cd MuMain

make format         # Format all C++ files
make format-check   # Check formatting without modifying (same as CI)
make lint           # Run cppcheck static analysis
make tidy           # Run clang-tidy (needs build-mingw/compile_commands.json)
```

## Build Configurations

| Preset | Architecture | Editor | Use Case |
|--------|-------------|--------|----------|
| `windows-x86` | 32-bit | No | Standard game build |
| `windows-x86-mueditor` | 32-bit | Yes | Debug with ImGui editor |
| `windows-x64` | 64-bit | No | 64-bit game build |
| `windows-x64-mueditor` | 64-bit | Yes | 64-bit debug with editor |

- **Debug** builds: Full symbols, editor support, assertions
- **Release** builds: Optimized, no editor, zero debug overhead
- **Editor toggle**: Press **F12** in-game, or launch with `--editor` flag

## Common Issues

| Issue | Solution |
|-------|----------|
| `Cannot find -lturbojpeg` | Install MinGW-w64 libjpeg-turbo or set `-DMU_TURBOJPEG_STATIC_LIB` |
| `.NET SDK not found` | Install .NET 10.0+ SDK; game builds without it but can't connect to server |
| ImGui submodule missing | `git submodule update --init` from repository root |
| NuGet cache fails (umlauts in path) | `cmake -DMU_NUGET_CACHE_DIR=C:/.mu-nuget` |
| Slow builds on `/mnt/c/` | Keep repo on WSL filesystem (`/home/<user>/...`) |

See [Troubleshooting](docs/troubleshooting.md) for more solutions and [Development Guide](docs/development-guide.md) for full IDE setup instructions (Visual Studio, CLion, Rider).

## Documentation

Full documentation lives in [`docs/`](docs/index.md):

- **[Project Overview](docs/project-overview.md)** — Executive summary and tech stack
- **[Development Guide](docs/development-guide.md)** — Build, run, environment setup
- **[Development Standards](docs/development-standards.md)** — Coding conventions, banned APIs, cross-platform rules
- **[Architecture: MuMain](docs/architecture-mumain.md)** — Game client architecture
- **[Implementation Recipes](docs/implementation-recipes.md)** — Step-by-step: add UI window, packet, manager, item, map, flag, scene
- **[Feature Impact Maps](docs/feature-impact-maps.md)** — Change blast radius per system, dependency chains
- **[Cross-Platform Plan](docs/CROSS_PLATFORM_PLAN.md)** — 10-phase SDL3/SDL_gpu migration roadmap

## License

[MIT](LICENSE)
