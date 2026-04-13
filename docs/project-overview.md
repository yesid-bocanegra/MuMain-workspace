# MuMain Project Overview

## Project Identity

- **Name:** MuMain-workspace
- **Type:** Multi-part project (4 components)
- **Domain:** MMORPG game client (MU Online Season 5.2→6)
- **Origin:** Fork of [sven-n/MuMain](https://github.com/sven-n/MuMain) — a C++ client compatible with the [OpenMU](https://github.com/MUnique/OpenMU) server emulator
- **Repository Structure:** Parent workspace with MuMain as a git submodule

## Purpose

MuMain is a modern C++ game client for MU Online that connects to OpenMU servers. It provides:
- Full 3D rendering of the MU Online game world (SDL3/SDL_gpu)
- Network protocol compatibility with OpenMU server via .NET 10 Native AOT bridge
- In-game debug editor (ImGui) for development
- Cross-platform native builds: Windows x64, macOS arm64, Linux x64
- Internationalization for 9 languages

## Architecture Summary

| Component | Type | Technology | Purpose |
|-----------|------|-----------|---------|
| **MuMain** | Game Client | C++20, SDL3/SDL_gpu | 3D MMORPG rendering and gameplay |
| **ClientLibrary** | Network Bridge | .NET 10, Native AOT | Server communication, packet handling |
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
| Build System | CMake + Ninja | 3.25+ |
| Graphics | SDL3/SDL_gpu (Vulkan/Metal/D3D12 backends) | SDL 3.2.8 via FetchContent |
| Windowing / Input | SDL3 | SDL 3.2.8 |
| Text Rendering | SDL_ttf (GPU text engine) | 3.x via FetchContent |
| Math | GLM (header-only) | via FetchContent |
| Audio | miniaudio (CoreAudio/WASAPI/PulseAudio) + OGG Vorbis | Vendored header-only |
| Logging | spdlog | 1.15.3 via FetchContent |
| UI (Debug) | Dear ImGui | Latest (submodule) |
| Network Protocol | MUnique.OpenMU.Network.Packets | 0.9.8 |
| Code Generation | XSLT 1.0 | 4 transforms |
| CI/CD | GitHub Actions | Native builds (Windows, macOS, Linux) |
| i18n | Custom JSON | 9 locales |

## Key Metrics

| Metric | Value |
|--------|-------|
| C++ Source Files | ~742 across 20 module directories |
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
│   ├── src/source/            # Core C++ game client (~742 files)
│   ├── src/MuEditor/          # ImGui debug editor (34 files)
│   ├── src/bin/               # Runtime assets & config
│   ├── ClientLibrary/         # .NET network layer
│   ├── ConstantsReplacer/     # Constants sync tool
│   └── .github/workflows/     # CI pipelines
└── .gitmodules                # Submodule definition
```

## Getting Started

See [Development Guide](./development-guide.md) for build instructions.

**Quick start (any platform):**
```bash
# From the workspace root (ctl handles directory changes)
./ctl build          # configure + build (SDL3 fetched automatically on first run)
./ctl test           # run tests via ctest
./ctl check          # full quality gate: build + test + format-check + lint
```

All three platforms build natively -- no cross-compilation or WSL required. SDL3, SDL_ttf, GLM, and spdlog are fetched via CMake FetchContent on first configure (~30 sec, internet required). .NET SDK is needed for server connectivity.

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

### Cross-Platform Migration (Sprint 7 -- largely complete)
The client has been migrated from Win32/OpenGL/DirectSound to SDL3/SDL_gpu/miniaudio. As of April 2026, the game is fully playable on macOS (arm64) with rendering, input, hotkeys, audio, and network all working. Linux x64 and Windows x64 also build and run natively. CI builds all three platforms. See [CROSS_PLATFORM_PLAN.md](./CROSS_PLATFORM_PLAN.md) for the original 10-phase roadmap.

### Key Architectural Decisions
- **SDL3/SDL_gpu** replaces OpenGL immediate mode -- Vulkan on Linux, Metal on macOS, D3D12 on Windows (selected automatically)
- **miniaudio** replaces DirectSound -- CoreAudio on macOS, WASAPI on Windows, PulseAudio on Linux
- **.NET 10 Native AOT** for network interop (no runtime dependency, all 191 packet bindings resolved)
- XSLT code generation for packet protocol bindings
- ImGui for debug tooling (zero release overhead)
- Conditional compilation for editor isolation
