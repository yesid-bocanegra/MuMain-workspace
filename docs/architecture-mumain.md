# Architecture: MuMain C++ Game Client

## Executive Summary

MuMain is a C++20 game client for MU Online (Season 5.2→6 fork), rendering a 3D MMORPG world using OpenGL immediate mode on Win32. The client handles real-time 3D rendering, player input, UI overlays, audio, and network communication via a .NET Native AOT bridge. It follows a monolithic single-process architecture with global state management through extern globals and singleton managers.

## Technology Stack

| Category | Technology | Version | Notes |
|----------|-----------|---------|-------|
| Language | C++ | C++20 | `cxx_std_20` in CMake |
| Build System | CMake | 3.25+ | Presets for x86/x64 ± editor |
| Graphics | OpenGL | 1.x (immediate mode) | via GLEW, 111 `glBegin` sites |
| Windowing | Win32 API | — | `CreateWindowEx`, message pump |
| Audio | DirectSound + wzAudio | — | WAV via MMIO, OGG via Vorbis |
| Image Loading | libjpeg-turbo | 3.1.3 | Static-linked, texture decoding |
| UI Framework | ImGui | Latest (submodule) | Editor only (`#ifdef _EDITOR`) |
| Network | .NET Native AOT DLL | .NET 10 | Via `coreclr_delegates.h` bridge |
| i18n | Custom JSON | — | 9 locales, 3 domains |

## Architecture Pattern

**Monolithic Game Loop with Scene State Machine**

```
WinMain() → MuMain() → MainLoop()
                            │
                            ├── Win32 Message Pump (PeekMessage)
                            ├── SceneManager::RenderScene()
                            │       ├── ServerListScene
                            │       ├── WebzenScene
                            │       ├── LoginScene
                            │       ├── LoadingScene
                            │       ├── CharacterScene
                            │       └── MainScene (gameplay)
                            │
                            ├── Network Packet Processing (callbacks from .NET)
                            ├── Audio Update
                            └── MuEditor Update (debug builds)
```

The game loop runs a fixed-timestep loop with `FrameTimingState` managing delta time. Each scene is responsible for its own input handling, rendering, and state management.

## State Management

**Pattern:** Global extern variables + singleton managers

- `CHARACTER Hero` — Player character state
- `CHARACTER CharactersClient[]` — All visible characters
- `OBJECT ObjectArray[]` — World objects
- `ITEM_ATTRIBUTE ItemAttribute[]` — Item database
- Singletons: `NewUISystem`, `SceneManager`, `GameConfig`, `Translator`

State flows:
1. **Network → Globals**: Packet callbacks in `PacketFunctions_*.cpp` write directly to global arrays
2. **Globals → Rendering**: Scene render functions read globals to draw the world
3. **Input → Globals**: Win32 message handlers update input state globals
4. **Config → Globals**: `GameConfig` reads INI at startup, writes on settings change

## Rendering Architecture

```
OpenGL Immediate Mode Pipeline
├── ZzzOpenglUtil.cpp      — GL context, camera setup, blend modes
├── ZzzBMD.cpp             — BMD model format: skeletal animation, mesh rendering
├── ZzzObject.cpp          — Object management (10,852 lines), world object rendering
├── ZzzLodTerrain.cpp      — Terrain with LOD
├── CSWaterTerrain.cpp     — Water surface effects
├── Sprite.cpp             — 2D billboard sprites
├── ShadowVolume.cpp       — Stencil shadow volumes
├── ZzzEffectJoint.cpp     — Trail/joint visual effects
├── ZzzEffectBlurSpark.cpp — Particle blur/spark effects
└── ZzzEffectMagicSkill.cpp — Magic skill VFX
```

All rendering uses `glBegin`/`glEnd` immediate mode (111 call sites across 14 files). A planned migration to SDL_gpu with retained-mode rendering is documented in `CROSS_PLATFORM_PLAN.md`.

## UI System

**84 `CNewUI*` classes** managed by `NewUISystem` singleton:

| Category | Examples |
|----------|---------|
| HUD | `NewUIMainFrameWindow`, `NewUIMiniMap`, `NewUISkillList` |
| Inventory | `NewUIMyInventory`, `NewUITrade`, `NewUIPersonalShopSale` |
| Character | `NewUICharacterInfoWindow`, `NewUIGuildInfoWindow` |
| Chat | `NewUIChatLogWindow`, `NewUIChatInputBox` |
| Dialogs | `NewUICommonMessageBox`, `NewUIOptionWindow` |
| Shop | `NewUIInGameShop`, `MsgBoxIGS*` (6 types) |

UI windows register with `NewUISystem` and are rendered as 2D overlays atop the 3D scene. Each window manages its own input handling and rendering.

## Scene State Machine

6 scenes with linear progression:

```
ServerListScene → WebzenScene → LoginScene → LoadingScene → CharacterScene → MainScene
                                                                                  ↑
                                                                           (gameplay loop)
```

Each scene implements:
- `Create()` / `Destroy()` — Resource lifecycle
- `Update(delta)` — Logic tick
- `Render()` — OpenGL draw calls
- Scene transitions managed by `SceneManager`

## Audio Architecture

- **DirectSound** (`DSplaysound.cpp`) — Sound effect playback
- **wzAudio.dll** — Proprietary audio library (BGM, streaming)
- **DSwaveIO.cpp** — WAV file loading via Win32 MMIO API
- **OGG Vorbis** (`ogg.dll` + `vorbisfile.dll`) — Compressed audio codec

## Configuration

`GameConfig` reads/writes `src/bin/config.ini`:

| Section | Keys | Purpose |
|---------|------|---------|
| `[Window]` | Width, Height, Windowed | Display settings |
| `[Graphics]` | ColorDepth, RenderTextType | Render quality |
| `[Audio]` | SoundEnabled, MusicEnabled, VolumeLevel | Audio toggles |
| `[CONNECTION SETTINGS]` | ServerIP, ServerPort | Server targeting |

## Feature Flag System

`Defined_Global.h` contains 15+ `#define` toggles:

- `ASG_ADD_GENS_SYSTEM` — Gens faction system
- `LDS_PATCH_GLOBAL_100520` — Release build flag
- `_EDITOR` — MuEditor conditional compilation
- `_DEBUG` / `_FOREIGN_DEBUG` — Debug mode flags

## Build Architecture

```
CMakeLists.txt (root)
└── src/CMakeLists.txt (482 lines)
    ├── GLOB_RECURSE src/source/**/*.cpp  (691 files)
    ├── GLOB_RECURSE src/MuEditor/**/*.cpp (if ENABLE_EDITOR)
    ├── ImGui submodule auto-init
    ├── Link: Win32 (user32, gdi32, ws2_32, opengl32, glu32)
    ├── Link: GLEW, turbojpeg, wzAudio
    ├── Custom command: ClientLibrary .NET publish → Native AOT DLL
    └── Custom command: ConstantsReplacer build
```

**Presets:** `windows-x86`, `windows-x64`, `windows-x86-mueditor`, `windows-x64-mueditor`

## Testing Strategy

No automated test suite. Testing is manual:
1. Visual verification: Window opens, 3D scene renders
2. Input validation: Mouse/keyboard targeting
3. Network: Connect to OpenMU server, complete login flow
4. UI: Inventory, shop, chat, minimap functional
5. Editor (debug): F12 toggle, console output, item editor

CI validates compilation only (MinGW-w64 cross-compile on Ubuntu).

## Cross-Platform Migration

Planned SDL3/SDL_gpu migration (see `CROSS_PLATFORM_PLAN.md`):
- **Phase 1-2**: SDL3 windowing + input (replace Win32 API)
- **Phase 3-5**: SDL_gpu rendering (replace 111 glBegin sites)
- **Phase 6**: miniaudio (replace DirectSound + wzAudio)
- **Phase 7**: FreeType (replace GDI text rendering)
- **Phase 8**: Cross-platform .NET AOT (`dlopen`, `char16_t`)
- **Phase 9-10**: Linux/macOS builds, CI/CD expansion

## Key Files Reference

| File | Lines | Role |
|------|-------|------|
| `Winmain.cpp` | ~800 | Entry point, game loop, window creation |
| `ZzzObject.cpp` | 10,852 | Object management and rendering |
| `_struct.h` | ~2,000 | Core data structures (CHARACTER, OBJECT, ITEM) |
| `_define.h` | ~1,500 | Constants and system limits |
| `Defined_Global.h` | ~200 | Feature flag toggles |
| `NewUISystem.cpp` | ~600 | UI window manager |
| `SceneManager.cpp` | ~400 | Scene state machine |
| `ZzzOpenglUtil.cpp` | ~1,200 | OpenGL initialization and utilities |
| `ZzzBMD.cpp` | ~3,000 | BMD model format handler |
