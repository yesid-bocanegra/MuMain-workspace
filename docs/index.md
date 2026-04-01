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
- **Root:** `MuMain/src/source/` (692 files in 20 module directories)
- **Entry Point:** `Main/MuMain.cpp → WinMain()`

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
- [Project Overview](./project-overview.md) — Executive summary, tech stack, key metrics *(~120 lines)*
- [Source Tree Analysis](./source-tree-analysis.md) — Annotated directory structure with critical folders *(~300 lines)*
- [Development Guide](./development-guide.md) — Build, run, test, environment setup *(~210 lines)*
- [Development Standards](./development-standards.md) — Coding conventions, banned APIs, cross-platform rules, error handling & logging *(~530 lines; §1 banned APIs, §2 C++ + error/logging, §3 C#, §4 generated code, §5 i18n)*
- [cppcheck Guidance](./cppcheck-guidance.md) — Static analysis suppression policy and fix examples *(~100 lines)*
- [Integration Architecture](./integration-architecture.md) — Cross-component communication and data flows *(~175 lines)*
- [Troubleshooting](./troubleshooting.md) — Common build/runtime issues and solutions *(~150 lines)*
- [Testing Strategy](./testing-strategy.md) — Test approach, ground truth capture, CI validation *(~185 lines)*

### Architecture (Per-Part)
- [Architecture: MuMain](./architecture-mumain.md) — Game client: rendering, scenes, UI, state management *(~185 lines)*
- [Architecture: Rendering](./architecture-rendering.md) — OpenGL pipeline, MuRenderer abstraction, SDL_gpu migration *(~190 lines; §Current Pipeline, §MuRenderer, §SDL_gpu, §HLSL Shaders)*
- [Architecture: ClientLibrary](./architecture-clientlibrary.md) — Network layer: packets, marshaling, XSLT pipeline *(~140 lines)*
- [Architecture: ConstantsReplacer](./architecture-constantsreplacer.md) — Code gen tool: SQL→C++ constant sync *(~105 lines)*
- [Architecture: MuEditor](./architecture-mueditor.md) — Debug editor: ImGui overlay, lifecycle, input blocking *(~130 lines)*

### Reference
- [Game Systems Reference](./game-systems-reference.md) — All gameplay subsystems, entry points, data flow *(~300 lines; §Core Loop, §Global State, §Gameplay Systems, §Map/World, §UI System)*
- [Packet Protocol Reference](./packet-protocol-reference.md) — Network protocol, encryption, C++/C# boundary *(~230 lines; §Framing, §Encryption, §C++/C# Boundary, §Code Gen)*
- [Asset Pipeline](./asset-pipeline.md) — Asset formats, directory structure, loading pipeline *(~230 lines)*
- [Implementation Recipes](./implementation-recipes.md) — Step-by-step: add UI window, packet, manager, item, map, flag, scene *(~700 lines; 7 recipes, ~80-120 lines each)*
- [Feature Impact Maps](./feature-impact-maps.md) — Change blast radius per system, dependency chains, feature flags *(~450 lines; 9 system maps, quick-lookup, init chain)*
- [Game Dev Library Landscape](./gamedev-library-landscape.md) — C++ library survey: current stack, alternatives, adoption decisions *(~230 lines; 12 categories)*

### Guidelines
- [Security Guidelines](./security-guidelines.md) — Input validation, memory safety, crypto migration, logging security *(~130 lines)*
- [Performance Guidelines](./performance-guidelines.md) — Game loop constraints, timing, memory, rendering, .NET hot paths *(~130 lines)*
- [Architecture Decision Records](./adr/README.md) — ADR process, template, and decision log

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
- [Modular Reorganization](./modular-reorganization.md) — Phase -1: module directory structure, CMake library targets, dependency map *(~120 lines)*
- [Cross-Platform Plan](./CROSS_PLATFORM_PLAN.md) — 10-phase, 58-session SDL3/SDL_gpu migration roadmap *(~970 lines — load specific phase sections, not entire file)*
- [Cross-Platform Decisions](./CROSS_PLATFORM_DECISIONS.md) — Research, library decisions, OpenGL audit, shader specs *(~435 lines)*

### CI/CD
- [CI Workflows](./ci-workflows.md) — Consolidated CI: quality gates + build pipeline, Makefile as source of truth *(~110 lines)*
- [CI Workflow](../MuMain/.github/workflows/ci.yml) — Single workflow: quality gates + MinGW cross-compile + artifact upload

## Getting Started

1. **Read** [Project Overview](./project-overview.md) for executive summary
2. **Build** following [Development Guide](./development-guide.md) (WSL + MinGW recommended)
3. **Understand** the architecture via per-part docs above
4. **Plan features** using the [Integration Architecture](./integration-architecture.md) for cross-component work

### For AI-Assisted Development

**Context loading strategy:** Use this index to identify which docs are relevant, then load only the needed documents. For large docs (>200 lines), use section-targeted reads — section names are listed in parentheses above.

| Task | Load These Docs | Skip |
|------|----------------|------|
| Game client features | Architecture: MuMain + Game Systems Reference | Rendering, Protocol, Asset |
| Rendering work | Architecture: Rendering (full) | Game Systems, Protocol |
| Network protocol changes | Packet Protocol + Architecture: ClientLibrary | Rendering, Game Systems |
| Cross-component features | Integration Architecture | Per-part architecture docs |
| Cross-platform migration | Development Standards §1 + Cross-Platform Plan (relevant phase only) | Full plan, Game Systems |
| Asset/content work | Asset Pipeline | Protocol, Rendering |
| Build/CI issues | Development Guide + Troubleshooting | Architecture docs |
| Planning new features | Implementation Recipes (relevant recipe) | Impact Maps (if unsure of blast radius) |
| Assessing change impact | Feature Impact Maps (relevant system) | Full plan, Rendering details |
| New contributor onboarding | Project Overview + Development Guide + Development Standards | Reference docs |

The `CLAUDE.md` file at the workspace root provides quick context (~75 lines) for Claude Code sessions — it is loaded automatically and should not be re-read manually.
