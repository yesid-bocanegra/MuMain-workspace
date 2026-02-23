# MuMain Project Overview

## Project Identity

- **Name:** MuMain-workspace
- **Type:** Multi-part project (4 components)
- **Domain:** MMORPG game client (MU Online Season 5.2→6)
- **Origin:** Fork of [sven-n/MuMain](https://github.com/sven-n/MuMain) — a C++ client compatible with the [OpenMU](https://github.com/MUnique/OpenMU) server emulator
- **Repository Structure:** Parent workspace with MuMain as a git submodule

## Purpose

MuMain is a modern C++ game client for MU Online that connects to OpenMU servers. It provides:
- Full 3D rendering of the MU Online game world (OpenGL)
- Network protocol compatibility with OpenMU server via .NET Native AOT bridge
- In-game debug editor (ImGui) for development
- Cross-platform build support (Windows primary, Linux/macOS planned)
- Internationalization for 9 languages

## Architecture Summary

| Component | Type | Technology | Purpose |
|-----------|------|-----------|---------|
| **MuMain** | Game Client | C++20, OpenGL, Win32 | 3D MMORPG rendering and gameplay |
| **ClientLibrary** | Network Library | .NET 10, Native AOT | Server communication, packet handling |
| **ConstantsReplacer** | Dev Tool | .NET 8, WinForms | Sync game constants from server DB |
| **MuEditor** | Debug Editor | ImGui, C++20 | In-process game state editor |

```
MuMain (C++20) ◄──► ClientLibrary (.NET AOT) ◄──► OpenMU Server
     ▲                      ▲
     │ same process          │ XSLT code gen
     │ (#ifdef _EDITOR)      │
MuEditor (ImGui)     ConstantsReplacer (.NET 8)
```

## Technology Stack

| Category | Technology | Version |
|----------|-----------|---------|
| Primary Language | C++ | C++20 |
| Secondary Language | C# | .NET 10 / .NET 8 |
| Build System | CMake | 3.25+ |
| Graphics | OpenGL (immediate mode) | 1.x via GLEW |
| Windowing | Win32 API | — |
| Audio | DirectSound + wzAudio + OGG Vorbis | — |
| UI (Debug) | Dear ImGui | Latest (submodule) |
| Network Protocol | MUnique.OpenMU.Network.Packets | 0.9.8 |
| Code Generation | XSLT 1.0 | 4 transforms |
| CI/CD | GitHub Actions | MinGW-w64 cross-compile |
| i18n | Custom JSON | 9 locales |

## Key Metrics

| Metric | Value |
|--------|-------|
| C++ Source Files | 691 (325 .cpp + 366 .h) |
| Game Assets | 13,169 files |
| UI Windows | 84 CNewUI* classes |
| Scenes | 6 (ServerList → Main gameplay) |
| Supported Languages | 9 |
| Feature Flags | 15+ in Defined_Global.h |
| CI Workflows | 3 (main, PR, dev) |
| Buff System Macros | 80+ |

## Repository Layout

```
MuMain-workspace/              # Parent workspace
├── docs/                      # Project knowledge base (this documentation)
├── _bmad/                     # BMAD framework
├── MuMain/                    # Game client submodule
│   ├── src/source/            # Core C++ game client (691 files)
│   ├── src/MuEditor/          # ImGui debug editor (34 files)
│   ├── src/bin/               # Runtime assets & config
│   ├── ClientLibrary/         # .NET network layer
│   ├── ConstantsReplacer/     # Constants sync tool
│   └── .github/workflows/     # CI pipelines
└── .gitmodules                # Submodule definition
```

## Getting Started

See [Development Guide](./development-guide.md) for build instructions.

**Quick start (WSL + MinGW):**
```bash
cd MuMain
git submodule update --init
cmake -S . -B build-mingw -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/mingw-w64-i686.cmake \
  -DCMAKE_BUILD_TYPE=Debug -DENABLE_EDITOR=ON
cmake --build build-mingw -j$(nproc)
```

**Default server:** `localhost:44406` (requires [OpenMU](https://github.com/MUnique/OpenMU))

## Documentation Map

| Document | Description |
|----------|-------------|
| [Project Overview](./project-overview.md) | This file — executive summary |
| [Architecture: MuMain](./architecture-mumain.md) | Game client architecture |
| [Architecture: ClientLibrary](./architecture-clientlibrary.md) | Network layer architecture |
| [Architecture: ConstantsReplacer](./architecture-constantsreplacer.md) | Code gen tool architecture |
| [Architecture: MuEditor](./architecture-mueditor.md) | Debug editor architecture |
| [Integration Architecture](./integration-architecture.md) | Cross-component communication |
| [Source Tree Analysis](./source-tree-analysis.md) | Annotated directory structure |
| [Development Guide](./development-guide.md) | Build, run, test instructions |
| [Cross-Platform Plan](./CROSS_PLATFORM_PLAN.md) | SDL3/SDL_gpu migration roadmap |
| [Cross-Platform Decisions](./CROSS_PLATFORM_DECISIONS.md) | Migration research & rationale |

## Active Development

### Cross-Platform Migration
A 10-phase, 58-session plan to port the client from Win32/OpenGL to SDL3/SDL_gpu/miniaudio for Linux and macOS support. See [CROSS_PLATFORM_PLAN.md](./CROSS_PLATFORM_PLAN.md).

### Key Architectural Decisions
- Native AOT for .NET interop (no runtime dependency)
- XSLT code generation for packet protocol bindings
- ImGui for debug tooling (zero release overhead)
- Conditional compilation for editor isolation
