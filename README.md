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

## Quick Start

```bash
# Clone with submodule
git clone --recurse-submodules <repo-url>

# MinGW cross-compile (recommended)
cmake -S MuMain -B build-mingw -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=MuMain/cmake/toolchains/mingw-w64-i686.cmake \
  -DCMAKE_BUILD_TYPE=Debug -DENABLE_EDITOR=ON \
  -DMU_TURBOJPEG_STATIC_LIB=_deps/mingw-i686/lib/libturbojpeg.a
cmake --build build-mingw -j$(nproc)

# MSVC presets
cmake --preset windows-x64
cmake --build --preset windows-x64-debug
```

See [Development Guide](docs/development-guide.md) for full build instructions (WSL, CLion, Visual Studio).

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
