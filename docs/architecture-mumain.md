# Architecture: MuMain C++ Game Client

## Executive Summary

MuMain is a C++20 game client for MU Online (Season 5.2→6 fork), rendering a 3D MMORPG world using SDL3 GPU (retained-mode) on macOS/Linux and OpenGL immediate mode on Windows. The client handles real-time 3D rendering, player input, UI overlays, audio (miniaudio), and network communication via a .NET Native AOT bridge. It runs cross-platform on macOS (arm64), Linux (x64), and Windows (x64), with the game fully playable on macOS as of April 2026. It follows a monolithic single-process architecture with global state management through extern globals and singleton managers.

## Technology Stack

| Category | Technology | Version | Notes |
|----------|-----------|---------|-------|
| Language | C++ | C++20 | `cxx_std_20` in CMake |
| Build System | CMake | 3.25+ | Presets for x86/x64 ± editor |
| Graphics | SDL3 GPU / OpenGL | SDL3 (retained-mode) | SDL_gpu on macOS/Linux; legacy OpenGL on Windows |
| Windowing | SDL3 / Win32 API | — | SDL3 on macOS/Linux; Win32 on Windows (via `SDL_main.h` remapping) |
| Audio | miniaudio / DirectSound | — | miniaudio on macOS/Linux (CoreAudio/ALSA); DirectSound on Windows |
| Image Loading | libjpeg-turbo | 3.1.3 | Static-linked, texture decoding |
| UI Framework | ImGui | Latest (submodule) | Editor only (`#ifdef _EDITOR`) |
| Network | .NET Native AOT DLL | .NET 10 | Via `coreclr_delegates.h` bridge |
| i18n | Custom JSON | — | 9 locales, 3 domains |

## Architecture Pattern

**Monolithic Game Loop with Scene State Machine**

```
main() → MuMain() → MainLoop()
                            │
                            ├── SDL3 Event Loop (PollEvents) / Win32 Message Pump (PeekMessage)
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

The entry point is `main()` which calls `MuMain()`. On Windows, `SDL_main.h` remaps `WinMain` to `main()` transparently. The game loop runs a fixed-timestep loop with `FrameTimingState` managing delta time. Each scene is responsible for its own input handling, rendering, and state management.

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
3. **Input → Globals**: SDL3 event loop (`SDLEventLoop.cpp`) / Win32 message handlers update input state globals
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

On SDL3 platforms, rendering uses the SDL3 GPU retained-mode renderer (`MuRendererSDLGpu.cpp`) with deferred draw commands (`RenderCmd`) recorded during the frame and replayed in `EndFrame`. On Windows, the legacy OpenGL immediate-mode path (`glBegin`/`glEnd`, 111 call sites) remains active.

## Platform Abstraction Layer

`PlatformCompat.h` (~2,585 lines) is the cornerstone of cross-platform support. On non-Windows builds (`#else` branch of `#ifdef _WIN32`), it provides 100+ inline shims that re-implement Win32 API functions using SDL3 and standard C++, allowing legacy Win32 game code to compile and run unchanged on macOS and Linux.

Key shim categories:

| Category | Functions | Implementation |
|----------|-----------|----------------|
| Window | `CreateWindowEx`, `GetDC`, `SetPixelFormat`, `ShowWindow` | SDL3 window via `MuPlatform` |
| Input | `GetCursorPos`, `GetAsyncKeyState`, `SetCursorPos` | SDL3 mouse/keyboard state globals |
| Focus | `GetFocus`, `GetActiveWindow` | Return `g_hWnd` sentinel `(HWND)1` |
| Messages | `PostMessage`, `SendMessage`, `PeekMessage` | No-op or direct dispatch |
| Timing | `timeGetTime`, `QueryPerformanceCounter` | `SDL_GetTicks` / `std::chrono` |
| GDI | `CreateFont`, `SelectObject`, `SetTextColor` | `CrossPlatformGDI.h` (SDL_ttf) |
| Strings | `wcsncpy_s`, `_wsplitpath`, `_wcsicmp` | POSIX equivalents |
| File I/O | `_wfopen`, `CreateDirectory`, `GetModuleFileName` | `std::filesystem` |
| Registry | `RegOpenKeyEx`, `RegQueryValueEx` | Return `ERROR_FILE_NOT_FOUND` |

**g_hWnd sentinel**: On SDL3 platforms, `g_hWnd` is set to `(HWND)1` during startup. The `GetFocus()` and `GetActiveWindow()` shims return this same sentinel, so hotkey checks like `GetFocus() == g_hWnd` pass correctly without a real Win32 HWND.

## SDL3 Event Loop

`SDLEventLoop.cpp` (~350 lines, `Platform/sdl3/`) translates SDL3 events into the game's global input state variables (`MouseX`, `MouseY`, `MouseLButton`, `MouseLButtonPush`, `MouseRButton`, etc.).

- **Mouse push/edge flags** (`MouseLButtonPush`, `g_bMouseLButtonPressEdge`) accumulate across `PollEvents()` calls and survive frame throttling. They are cleared in `RenderScene` after game logic consumes them.
- **Text input** populates `g_szSDLTextInput[]` from `SDL_EVENT_TEXT_INPUT` events for `CUITextInputBox`.
- **Focus handling**: Clears mouse state on focus loss in windowed mode; throttles FPS when inactive in fullscreen.

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

**SDL3 platforms (macOS/Linux):**
- **miniaudio** (`MiniAudioBackend.cpp`) — Implements `IPlatformAudio` interface for both BGM and SFX playback. Uses CoreAudio on macOS, ALSA on Linux, and WASAPI on Windows.
- **`g_platformAudio`** — Global `IPlatformAudio*` pointer, initialized during `MuMain()` startup.
- wzAudio dependency removed; `Mp3FileName` global eliminated — same-track guard handled by `MiniAudioBackend::m_currentMusicName`.

**Windows (legacy):**
- **DirectSound** (`DSplaysound.cpp`) — Sound effect playback (still compiled on Windows, will be replaced by miniaudio)
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
    ├── FetchContent: SDL3, SDL_ttf (macOS/Linux)
    ├── Link: Win32 (user32, gdi32, ws2_32, opengl32, glu32) — Windows only
    ├── Link: GLEW, turbojpeg — Windows only
    ├── Link: miniaudio (header-only) — all platforms
    ├── Custom command: ClientLibrary .NET publish → Native AOT DLL
    └── Custom command: ConstantsReplacer build
```

**Presets:** `windows-x86`, `windows-x64`, `windows-x86-mueditor`, `windows-x64-mueditor`. macOS and Linux use the default CMake preset via `./ctl build`.

## Testing Strategy

No automated test suite. Testing is manual:
1. Visual verification: Window opens, 3D scene renders
2. Input validation: Mouse/keyboard targeting
3. Network: Connect to OpenMU server, complete login flow
4. UI: Inventory, shop, chat, minimap functional
5. Editor (debug): F12 toggle, console output, item editor

CI validates compilation on all three platforms natively (macOS arm64, Linux x64, Windows x64). Quality gate: `./ctl check` (build + test + clang-format + cppcheck).

## Cross-Platform Migration

SDL3/SDL_gpu migration (see `CROSS_PLATFORM_PLAN.md`). **Phases 1-6 completed** — the game is fully playable on macOS as of April 2026:

- **Phase 1-2** (done): SDL3 windowing + input (PlatformCompat.h shim layer, SDLEventLoop.cpp)
- **Phase 3-5** (done): SDL3 GPU rendering (retained-mode renderer, 45 pipelines, deferred draw commands)
- **Phase 6** (done): miniaudio (replaced DirectSound + wzAudio on SDL3 platforms)
- **Phase 7**: SDL_ttf text rendering (partially done — input boxes use SDL_ttf, bitmap font replacement in progress)
- **Phase 8**: Cross-platform .NET AOT (`dlopen`, `char16_t`) — all 191 packet bindings resolved
- **Phase 9-10**: Linux builds, CI/CD expansion

## Key Files Reference

| File | Lines | Role |
|------|-------|------|
| `MuMain.cpp` | ~670 | Entry point (`main()` → `MuMain()`), game loop, init |
| `PlatformCompat.h` | ~2,585 | Win32 API shim layer for SDL3 platforms |
| `SDLEventLoop.cpp` | ~350 | SDL3 event polling, mouse/keyboard/text input |
| `MuRendererSDLGpu.cpp` | ~2,000 | SDL3 GPU retained-mode renderer |
| `MiniAudioBackend.cpp` | ~500 | miniaudio audio backend (BGM + SFX) |
| `ZzzObject.cpp` | 10,852 | Object management and rendering |
| `_struct.h` | ~2,000 | Core data structures (CHARACTER, OBJECT, ITEM) |
| `_define.h` | ~1,500 | Constants and system limits |
| `Defined_Global.h` | ~200 | Feature flag toggles |
| `NewUISystem.cpp` | ~600 | UI window manager |
| `SceneManager.cpp` | ~400 | Scene state machine |
| `ZzzOpenglUtil.cpp` | ~1,200 | OpenGL initialization and utilities |
| `ZzzBMD.cpp` | ~3,000 | BMD model format handler |
