# MuMain-workspace — Claude Code Context

## Project

MU Online game client (Season 5.2→6). C++20 monolithic game loop + .NET 10 Native AOT network bridge + XSLT code generation. Currently planning a 10-phase SDL3 cross-platform migration (Linux + macOS).

## Key Paths

- **Game client source:** `MuMain/src/source/` (691 files)
- **Entry point:** `MuMain/src/source/Winmain.cpp` → `WinMain()`
- **.NET network layer:** `MuMain/ClientLibrary/` (14 files)
- **Code gen tool:** `MuMain/ConstantsReplacer/` (10 files)
- **Debug editor:** `MuMain/src/MuEditor/` (34 files, `_EDITOR` builds)
- **Game assets:** `MuMain/src/bin/Data/`
- **Documentation:** `docs/`
- **Feature flags:** `MuMain/src/source/Defined_Global.h`
- **PCH:** `MuMain/src/source/stdafx.h`
- **Build presets:** `MuMain/CMakePresets.json`
- **i18n:** `MuMain/src/source/Translation/i18n.h`
- **CI:** `MuMain/.github/workflows/mingw-build.yml`

## Build Commands

```bash
# MinGW cross-compile (recommended for development)
cmake -S MuMain -B build-mingw -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=MuMain/cmake/toolchains/mingw-w64-i686.cmake \
  -DCMAKE_BUILD_TYPE=Debug -DENABLE_EDITOR=ON \
  -DMU_TURBOJPEG_STATIC_LIB=_deps/mingw-i686/lib/libturbojpeg.a
cmake --build build-mingw -j$(nproc)

# MSVC presets
cmake --preset windows-x64
cmake --build --preset windows-x64-debug
```

## Conventions

- **C++ naming:** PascalCase functions, `m_` prefix members with Hungarian hints (`by`, `w`, `dw`, `sz`, `p`), `CNewUI*` UI classes, UPPER_SNAKE constants
- **Formatting:** 4 spaces, UTF-8, LF, Allman braces (per `.editorconfig`)
- **New code:** `std::unique_ptr` (no raw `new`/`delete`), `nullptr` (not `NULL`), `std::chrono` (not `timeGetTime`), `std::filesystem` for paths
- **i18n:** `GAME_TEXT("key")` for user-facing strings, `EDITOR_TEXT("key")` in editor builds
- **Feature flags:** Author-prefixed defines in `Defined_Global.h` (e.g., `ASG_ADD_GENS_SYSTEM`)
- **C#:** StyleCop enforced, `[UnmanagedCallersOnly]` for AOT exports, VSTHRD103 as error

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

## Documentation Index

- `docs/index.md` — Master index, start here
- `docs/development-standards.md` — Coding rules, banned APIs, PR checklist
- `docs/CROSS_PLATFORM_PLAN.md` — 10-phase, 58-session migration roadmap
- `docs/CROSS_PLATFORM_DECISIONS.md` — Research, library decisions, issue register
- `docs/architecture-mumain.md` — Game client architecture
- `docs/architecture-rendering.md` — Rendering pipeline, GL→SDL_gpu migration
- `docs/game-systems-reference.md` — All gameplay subsystems
- `docs/packet-protocol-reference.md` — Network protocol, C++/C# boundary
- `docs/asset-pipeline.md` — Asset formats, loading pipeline
- `docs/testing-strategy.md` — Test approach, ground truth capture
- `docs/integration-architecture.md` — Cross-component communication
- `docs/development-guide.md` — Build, run, environment setup
