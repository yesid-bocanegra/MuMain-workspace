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

## Documentation — Load On Demand

Start with `docs/index.md` (~100 lines) for the full index with section navigation hints. Load individual docs only when relevant to your current task.

| When working on... | Load (lines) |
|---------------------|-------------|
| Cross-platform migration | `modular-reorganization.md` (~120) + `development-standards.md` §1 (~150 lines) + `CROSS_PLATFORM_PLAN.md` (relevant phase, ~100 lines each) |
| Game client features | `game-systems-reference.md` (~300) + `architecture-mumain.md` (~185) |
| Rendering / shaders | `architecture-rendering.md` (~190) |
| Network protocol | `packet-protocol-reference.md` (~230) + `architecture-clientlibrary.md` (~140) |
| Build / CI issues | `development-guide.md` (~210) + `troubleshooting.md` (~150) |
| Asset loading | `asset-pipeline.md` (~230) |
| Planning a new feature | `implementation-recipes.md` (relevant recipe, ~80-120 lines each) |
| Assessing change impact | `feature-impact-maps.md` (relevant system, ~25-45 lines each) |

Large files (>400 lines): `CROSS_PLATFORM_PLAN.md` (970 lines) — always read specific phase sections, never the full file.

<!-- PCC-START — managed by PCC deploy, do not edit manually -->
# PCC Workflow System - Claude Instructions

## Overview

PCC (Project-specific Customizations and Constraints) is a **BMAD add-on module** that enriches the BMAD workflow with project-specific constraints while protecting the workflow if BMAD changes.

**Key Insight:** Workflows are prompts that Claude reads directly. There is no code-based "workflow engine."

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│  User runs: ./paw story-key                              │
│       ↓                                                  │
│  paw_runner/ (orchestration package)                     │
│    - Determines next step from artifacts                 │
│    - Invokes Claude with skill command                   │
│       ↓                                                  │
│  Claude Code                                             │
│    - Receives skill: /bmad:pcc:workflows:X               │
│    - Reads workflow instructions (XML/Markdown)          │
│    - Follows instructions directly                       │
│       ↓                                                  │
│  Produces artifacts                                      │
│    - Story files, ATDD checklists, progress files        │
│       ↓                                                  │
│  paw_runner/ detects artifacts, moves to next step      │
└──────────────────────────────────────────────────────────┘
```

## Key Documents

| Document | Purpose |
|----------|---------|
| `docs/specification/pcc-gap-analysis.md` | What works, what's wrong, gaps to fill |
| `docs/specification/pcc-task-catalog.md` | All 44 PCC tasks |
| `docs/specification/pcc-workflow-catalog.md` | All 71 PCC workflows |
| `docs/specification/pcc-evolution-guidelines.md` | How to safely modify the system |
| `docs/specification/pcc-testing-strategy.md` | Testing at all levels |
| `paw_runner/` | Modular automation package (15 modules) |
| `_bmad/pcc/` | PCC module (71 workflows, 44 tasks, 11 templates, 10 rules, 5 agents, 76 commands) |

## What Works

1. **paw_runner/** - Modular automation package with:
   - Step sequencing (CREATE_STORY → ... → COMPLETENESS_GATE → ... → CODE_REVIEW_FINALIZE)
   - Pipeline self-healing: retry (1 per step), regression (back to DEV_STORY, max 2), feedback files
   - Artifact detection and auto-resume
   - `--from`/`--to` step selection
   - Batch processing and logging

2. **PCC Workflows** - 71 workflows in `_bmad/pcc/workflows/`:
   - 5 wrappers (wrap BMM with PCC constraints)
   - 44 extended (PCC-specific features across 8 phases)
   - 22 pcc-only (workspace-configure, scaffold-quality-config, design-system-init, bootstrap-reachability, reorganize-docs, sprint-health-audit, sprint-remediate, sprint-replan, sprint-metrics, sprint-complete, sprint-retrospective, sprint-backfill, epic-start, epic-retrospective, epic-backfill, project-init, milestone-validation, milestone-plan, milestone-review, qbr, backlog-refinement, epic-replan)

3. **PCC Tasks** - 44 tasks in `_bmad/pcc/tasks/`

4. **PCC Rules** - 10 rules in `_bmad/pcc/rules/` (ac-compliance, e2e-test-quality, epic-completion, milestone-completion, pcc-critical, pencil-design-rules, reachability, sprint-completion, story-completion, test-policy)

5. **PCC Agents** - 5 agents in `_bmad/pcc/agents/` (pcc, pcc-dev, pcc-qa, pcc-scope, pcc-discovery)

6. **PCC Commands** - 76 commands in `_bmad/pcc/commands/` (71 workflow + 5 agent slash commands)

7. **Pencil MCP** - Default design system (v3.3.0+):
   - `.pen` screens are the authoritative design specification
   - HTML mockups retained as legacy migration context only
   - `validate-pen-compliance` for structural validation
   - `validate-functional-requirements` for functional validation

8. **Skill Invocation** - Works today:
   ```bash
   /bmad:pcc:workflows:dev-story
   /bmad:pcc:workflows:code-review-quality-gate
   /bmad:pcc:tasks:load-guidelines
   ```

## Principles

1. **BMAD Add-On** - PCC enriches BMAD, doesn't replace it
2. **Protection Strategy** - If BMAD changes, PCC has wrappers/fallbacks
3. **Workflows Are Prompts** - Claude reads them directly, no transformation
4. **Document First** - Changes go to specification docs, then implementation
5. **Test What Works** - Verify before/after changes

## Working on This Module

### When Adding Features

1. Read existing formalization docs first
2. Follow evolution guidelines in `docs/specification/pcc-evolution-guidelines.md`
3. Add tasks to `_bmad/pcc/tasks/` as XML
4. Add workflows to `_bmad/pcc/workflows/` with workflow.yaml + instructions
5. **Run the propagation checklist** in `_bmad/pcc/docs/propagation-checklist.md` — lists every file that must be updated for each type of change (new workflow, new task, version bump, etc.)

### Do NOT

- Build code to "process" or "transform" workflows
- Create YAML workflow definitions for code to execute
- Build a "workflow engine" or "dispatcher"
- Duplicate what paw_runner/ already does

## Module Location

The PCC module lives at `_bmad/pcc/` (workflows, tasks, templates, agents, rules).
BMM (BMAD Method) that PCC wraps is available via skill invocation (`/bmad:bmm:*`).

## Adapters (Future)

The `adapters/` folder contains technology-specific configurations that Claude can read when making stack-specific decisions. Currently reference only.

## Current Status

**Phase:** Formalization complete
**System State:** Working (paw_runner/ + _bmad/pcc/)
**Gaps:** See `docs/specification/pcc-gap-analysis.md`
<!-- PCC-END -->

