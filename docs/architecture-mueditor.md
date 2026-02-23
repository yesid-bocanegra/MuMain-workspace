# Architecture: MuEditor ImGui Debug Editor

## Executive Summary

MuEditor is an in-game debug editor built with Dear ImGui, compiled into the MuMain game client via `#ifdef _EDITOR` conditional compilation. It runs in the same process and address space as the game, providing live inspection and editing of game state (items, skills, characters) through an overlay UI. It is excluded entirely from release builds with zero overhead.

## Technology Stack

| Category | Technology | Version | Notes |
|----------|-----------|---------|-------|
| UI Framework | Dear ImGui | Latest | Git submodule in `src/ThirdParty/imgui/` |
| Backend (Window) | `imgui_impl_win32` | — | Win32 window integration |
| Backend (Render) | `imgui_impl_opengl2` | — | OpenGL immediate mode rendering |
| Language | C++ | C++20 | Same as MuMain |
| Build Toggle | CMake | — | `-DENABLE_EDITOR=ON` adds `_EDITOR` define |

## Architecture Pattern

**Same-Process Overlay with Singleton Lifecycle**

```
MuMain Game Process
├── Game Loop (MainLoop)
│   ├── Game Update
│   ├── Game Render (OpenGL)
│   ├── MuEditorCore::Update()     ← #ifdef _EDITOR
│   └── MuEditorCore::Render()     ← #ifdef _EDITOR
│
├── MuEditorCore (Singleton)
│   ├── Initialize() — called in WinMain
│   ├── Update() — per-frame logic
│   ├── Render() — ImGui draw calls
│   └── Shutdown() — cleanup
│
└── MuInputBlockerCore
    └── Blocks game input when hovering editor UI
```

## Component Hierarchy

```
MuEditorCore (Singleton)
├── Core/
│   ├── MuEditorCore.cpp/h         — Lifecycle: Initialize/Update/Render/Shutdown
│   └── MuInputBlockerCore.cpp/h   — Input blocking when ImGui wants focus
│
├── Config/
│   └── MuEditorConfig.cpp/h       — Editor settings persistence
│
└── UI/
    ├── Common/
    │   ├── Toolbar                 — Top toolbar with tool buttons
    │   └── CenterPane              — Central workspace area
    │
    ├── Console/
    │   └── Dual-panel console      — Editor log + game log panels
    │
    ├── ItemEditor/ (7 files)
    │   └── Live item attribute editor — Modify items in real-time
    │
    └── SkillEditor/ (7 files)
        └── Skill tree editor       — Inspect/modify skill data
```

**Total: 34 files** (headers + sources)

## Integration Points

### Console Redirection
`stdafx.h` contains macros that redirect `wprintf` output to ImGui console panels:
- Game output → Game console panel
- Editor output → Editor console panel

### Input Management
`MuInputBlockerCore` intercepts Win32 input messages:
- When mouse hovers over ImGui windows → blocks game input
- When mouse is over game viewport → normal game input
- Prevents accidental game actions while editing

### Lifecycle
1. `WinMain()` calls `MuEditorCore::Initialize()` after OpenGL context creation
2. Each frame: `MuEditorCore::Update()` → `MuEditorCore::Render()` after game rendering
3. `MuEditorCore::Shutdown()` on application exit

### Direct Memory Access
The editor reads and writes game state directly:
- `CHARACTER Hero` — Player stats, position, equipment
- `ITEM_ATTRIBUTE[]` — Item database entries
- `SKILL_ATTRIBUTE[]` — Skill definitions
- No serialization boundary — same address space

## Runtime Controls

| Control | Action |
|---------|--------|
| **F12** | Toggle editor visibility |
| `--editor` flag | Launch with editor open |
| Compile-time | `-DENABLE_EDITOR=ON` required |

## Build Configuration

```cmake
# Enable editor
cmake -DENABLE_EDITOR=ON ...

# This sets the _EDITOR preprocessor define
# CMake GLOB_RECURSE includes src/MuEditor/**/*.cpp
# Links ImGui submodule (src/ThirdParty/imgui/)
```

Release builds completely exclude all editor code — no `_EDITOR` define means all ImGui code, headers, and source files are absent from compilation.

## Cross-Platform Migration

Planned backend changes (see `CROSS_PLATFORM_PLAN.md`):
- `imgui_impl_win32` → `imgui_impl_sdl3`
- `imgui_impl_opengl2` → `imgui_impl_sdlgpu3`
- Input blocking adapts to SDL3 event system

## Key Files Reference

| File | Lines | Role |
|------|-------|------|
| `MuEditorCore.cpp/h` | ~300 | Singleton lifecycle manager |
| `MuInputBlockerCore.cpp/h` | ~150 | Input interception |
| `MuEditorConfig.cpp/h` | ~100 | Settings persistence |
| `ItemEditor/*.cpp/h` | 7 files | Live item editing |
| `SkillEditor/*.cpp/h` | 7 files | Skill tree editing |
