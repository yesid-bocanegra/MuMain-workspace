# MuMain-workspace Documentation Index

> Primary entry point for AI-assisted development. Generated 2026-02-23.

## Project Overview

- **Type:** Multi-part project with 4 components
- **Primary Language:** C++20
- **Secondary Language:** C# (.NET 10 / .NET 8)
- **Architecture:** Monolithic game loop + .NET Native AOT bridge + XSLT code generation
- **Domain:** MMORPG game client (MU Online Season 5.2→6)

## Quick Reference

### MuMain (mumain)
- **Type:** Game Client
- **Tech Stack:** C++20, OpenGL, Win32, DirectSound
- **Root:** `MuMain/src/source/` (691 files)
- **Entry Point:** `Winmain.cpp → WinMain()`

### ClientLibrary (clientlibrary)
- **Type:** Network Library
- **Tech Stack:** .NET 10, Native AOT, MUnique.OpenMU.Network.Packets v0.9.8
- **Root:** `MuMain/ClientLibrary/` (14 files)
- **Entry Point:** `ConnectionManager.cs`

### ConstantsReplacer (constantsreplacer)
- **Type:** Code Generation Tool
- **Tech Stack:** .NET 8, WinForms, UDE.CSharp
- **Root:** `MuMain/ConstantsReplacer/` (10 files)
- **Entry Point:** `Program.cs`

### MuEditor (mueditor)
- **Type:** Debug Editor
- **Tech Stack:** C++20, Dear ImGui
- **Root:** `MuMain/src/MuEditor/` (34 files)
- **Entry Point:** `MuEditorCore.cpp → Initialize()`

## Generated Documentation

### Core
- [Project Overview](./project-overview.md) — Executive summary, tech stack, key metrics
- [Source Tree Analysis](./source-tree-analysis.md) — Annotated directory structure with critical folders
- [Development Guide](./development-guide.md) — Build, run, test, environment setup
- [Development Standards](./development-standards.md) — Coding conventions, banned APIs, cross-platform rules
- [Integration Architecture](./integration-architecture.md) — Cross-component communication and data flows
- [Troubleshooting](./troubleshooting.md) — Common build/runtime issues and solutions
- [Testing Strategy](./testing-strategy.md) — Test approach, ground truth capture, CI validation

### Architecture (Per-Part)
- [Architecture: MuMain](./architecture-mumain.md) — Game client: rendering, scenes, UI, state management
- [Architecture: Rendering](./architecture-rendering.md) — OpenGL pipeline, MuRenderer abstraction, SDL_gpu migration
- [Architecture: ClientLibrary](./architecture-clientlibrary.md) — Network layer: packets, marshaling, XSLT pipeline
- [Architecture: ConstantsReplacer](./architecture-constantsreplacer.md) — Code gen tool: SQL→C++ constant sync
- [Architecture: MuEditor](./architecture-mueditor.md) — Debug editor: ImGui overlay, lifecycle, input blocking

### Reference
- [Game Systems Reference](./game-systems-reference.md) — All gameplay subsystems, entry points, data flow
- [Packet Protocol Reference](./packet-protocol-reference.md) — Network protocol, encryption, C++/C# boundary
- [Asset Pipeline](./asset-pipeline.md) — Asset formats, directory structure, loading pipeline

### Metadata
- [Project Parts](./project-parts.json) — Machine-readable project structure and integration points
- [Project Scan Report](./project-scan-report.json) — Documentation workflow state and findings

## Existing Documentation

### In MuMain Submodule
- [MuMain README](../MuMain/README.md) — Project overview, features, build instructions, credits
- [Build Guide](../MuMain/docs/build-guide.md) — Platform-specific build instructions (WSL, CLion, VS)
- [Translation System](../MuMain/TRANSLATION_SYSTEM_INTEGRATION.md) — i18n architecture: 3 domains, 9 locales
- [MuEditor README](../MuMain/src/MuEditor/README.md) — Editor architecture, ImGui integration, components

### Cross-Platform Planning
- [Cross-Platform Plan](./CROSS_PLATFORM_PLAN.md) — 10-phase, 58-session SDL3/SDL_gpu migration roadmap
- [Cross-Platform Decisions](./CROSS_PLATFORM_DECISIONS.md) — Research, library decisions, OpenGL audit, shader specs

### CI/CD
- [MinGW Build (main)](../MuMain/.github/workflows/mingw-build.yml) — Ubuntu MinGW-w64 cross-compile
- [MinGW Build (PR)](../MuMain/.github/workflows/mingw-build-pr.yml) — PR validation builds
- [MinGW Build (dev)](../MuMain/.github/workflows/mingw-build-dev.yml) — Dev branch builds

## Getting Started

1. **Read** [Project Overview](./project-overview.md) for executive summary
2. **Build** following [Development Guide](./development-guide.md) (WSL + MinGW recommended)
3. **Understand** the architecture via per-part docs above
4. **Plan features** using the [Integration Architecture](./integration-architecture.md) for cross-component work

### For AI-Assisted Development
When creating brownfield PRDs or feature plans, provide this index file as project context. The `CLAUDE.md` file at the workspace root provides quick context for Claude Code sessions. For:
- **Game client features** → Reference [Architecture: MuMain](./architecture-mumain.md) + [Game Systems](./game-systems-reference.md)
- **Rendering work** → Reference [Rendering Architecture](./architecture-rendering.md)
- **Network protocol changes** → Reference [Packet Protocol](./packet-protocol-reference.md) + [Architecture: ClientLibrary](./architecture-clientlibrary.md)
- **Cross-component features** → Reference [Integration Architecture](./integration-architecture.md)
- **Cross-platform work** → Reference [Cross-Platform Plan](./CROSS_PLATFORM_PLAN.md) + [Development Standards](./development-standards.md)
- **Asset/content work** → Reference [Asset Pipeline](./asset-pipeline.md)
