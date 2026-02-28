---
stepsCompleted: [1, 2, 3-skipped, 4, 5, 6, 7, 8]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/prd-validation-report.md
  - _bmad-output/planning-artifacts/product-brief-MuMain-workspace-2026-02-26.md
  - _bmad-output/planning-artifacts/research/domain-ethical-mmo-ecosystem-research-2026-02-26.md
  - _bmad-output/project-context.md
  - docs/architecture-mumain.md
  - docs/architecture-rendering.md
  - docs/architecture-clientlibrary.md
  - docs/modular-reorganization.md
  - docs/development-standards.md
  - docs/CROSS_PLATFORM_PLAN.md
workflowType: 'architecture'
project_name: 'MuMain-workspace'
user_name: 'Paco'
date: '2026-02-27'
lastStep: 8
status: 'complete'
completedAt: '2026-02-28'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Requirements Overview

### Project Nature

Platform migration — an existing Windows-only C++20 game client (692 files, 84 UI windows, 82 maps, 200+ packet types) being migrated to run natively on macOS and Linux via SDL3, with three critical migration paths: rendering (SDL_gpu), networking (.NET Native AOT cross-platform), and audio (miniaudio).

### Functional Requirements Summary (40 FRs)

| Category | FRs | Nature | Architectural Impact |
|----------|-----|--------|---------------------|
| Platform & Build | FR1–FR5 | New | CMake toolchain files, platform detection, CI pipeline |
| Server Connectivity | FR6–FR11 | Migration | .NET AOT `.dylib`/`.so` loading, `char16_t` encoding, CMake RID |
| Rendering & Display | FR12–FR16 | Migration | MuRenderer abstraction → SDL_gpu backend (Metal/Vulkan/D3D) |
| Audio | FR17–FR19 | Migration | miniaudio replacing DirectSound/wzAudio |
| Input | FR20–FR22 | Migration | SDL3 input replacing Win32 `GetAsyncKeyState` |
| Gameplay Systems | FR23–FR36 | Regression | Must survive migration unchanged — combat, inventory, trading, guilds, PvP, all 84 UI windows |
| Stability & Error Handling | FR37–FR40 | New | 60+ min crash-free sessions on macOS/Linux, diagnostic logging |

### Non-Functional Requirements Summary (18 NFRs)

| Category | NFRs | Key Constraint |
|----------|------|----------------|
| Performance | NFR1–NFR3 | 30+ FPS sustained, <5ms added input latency, no >50ms hitches |
| Security | NFR4–NFR7 | Validate all network data, no assert on external input, encryption parity |
| Integration | NFR8–NFR10 | OpenMU protocol compatibility, correct .NET marshaling on all platforms |
| Portability | NFR11–NFR14 | Zero `#ifdef _WIN32` in game logic, forward-slash paths, UTF-8 serialization |
| Maintainability | NFR15–NFR18 | CI quality gates (format + lint + build), modern C++ conventions, conventional commits |

## Technical Constraints & Dependencies

### Three Critical Migration Paths

**1. SDL3 Migration (Rendering + Windowing + Input)**
- 111 `glBegin`/`glEnd` call sites across 14 files to replace
- Strategy: MuRenderer abstraction layer (~5 core functions), then swap OpenGL backend to SDL_gpu
- SDL_gpu provides platform-native backends: Metal (macOS), Vulkan (Linux), Direct3D (Windows)
- 5 HLSL shader programs (~150 lines): basic_colored, basic_textured, model_mesh, shadow_volume, shadow_apply
- Cross-compiled via SDL_shadercross to SPIR-V, MSL, DXIL
- OpenGL NOT used for lighting — per-vertex colors computed in C++ (no shader migration needed for lighting)

**2. .NET Native AOT Cross-Platform**
- Current: Windows `.dll` loaded via function pointers from `Dotnet/Connection.h`
- Migration: `.dylib` (macOS) / `.so` (Linux) with CMake RID detection
- String encoding: `wchar_t` (Windows, 2 bytes) → `char16_t` (cross-platform, guaranteed 2 bytes)
- XSLT code generation: packet binding headers generated from XML definitions — never hand-edit
- WSL interop: `wslpath -w` for `dotnet.exe` path conversion

**3. miniaudio Migration (Audio)**
- Replace DirectSound (sound effects) + wzAudio (BGM streaming) with miniaudio `ma_engine`
- Format support: WAV (MMIO → miniaudio decoder), OGG Vorbis, MP3
- Must handle ~30,000+ indexed audio assets via existing asset pipeline

### Hard Architectural Constraints

- **Single-threaded game loop** — monolithic WinMain() → MainLoop() with scene state machine
- **Global singletons** — `GetInstance()` pattern, extern globals for game entities (Hero, CharactersClient[], ObjectArray[])
- **No exceptions in game loop** — return codes only, assert for programmer invariants
- **Legacy naming coexistence** — Hungarian notation in existing code, modern C++20 in new code
- **CMake modular targets** — MUCommon → MUCore → MUProtocol/MUData/MURenderFX/MUAudio → MUGame → Main
- **CI quality gate** — MinGW cross-compile + clang-format 21.1.8 + clang-tidy + cppcheck on every push

### External Dependencies

| Dependency | Role | Migration Impact |
|------------|------|-----------------|
| SDL3 + SDL_gpu | Windowing, input, rendering | Core migration dependency |
| miniaudio | Audio playback | Replaces DirectSound/wzAudio |
| .NET 10 Native AOT | Network packet handling | Cross-platform library loading |
| libturbojpeg 3.1.3 | Texture decoding | Already cross-platform |
| GLEW | OpenGL extension loading | Removed after SDL_gpu migration |
| Catch2 3.7.1 | Unit testing | Already cross-platform |
| OpenMU (server) | Game server | Protocol compatibility constraint |

## Cross-Cutting Concerns

| Concern | Scope | Architectural Response |
|---------|-------|----------------------|
| Platform abstraction | All modules touching OS APIs | `PlatformCompat.h` + `PlatformTypes.h` isolation layer |
| Build unification | All platforms from one codebase | CMake toolchain files + presets + CI gate |
| Legacy/modern coexistence | Every modified file | Follow existing conventions in legacy, modern C++20 in new code |
| Error reporting | All platforms | `g_ErrorReport.Write()` → `MuError.log` cross-platform |
| Asset paths | File I/O throughout | `std::filesystem::path`, forward slashes, relative paths |
| Texture management | ~30,000 indexed textures | CGlobalBitmap with LRU cache, migrate GL calls to SDL_gpu |
| Test coverage | Growing from 1 test file | Catch2, no Win32 deps in tests, `tests/{module}/test_{name}.cpp` |
| i18n | User-facing strings | `GAME_TEXT("key")` macro, 9 locales, JSON translation files |

## Core Architectural Decisions

### Decision 1: Rendering — MuRenderer Abstraction Layer

**Decision:** Two-phase rendering migration via abstraction layer (Option B)

**Choice:** Create `MuRenderer` abstraction with ~5 core functions backed by OpenGL initially, then swap backend to SDL_gpu.

**Rationale:**
- Consolidates 111 `glBegin` call sites into ~5 abstraction functions
- Eliminates ~600 lines of duplication (9 `RenderBitmap*` variants, 7 `Enable*Blend` functions)
- Each phase is independently testable with visual regression via ground truth screenshots
- SDL_gpu backend swap becomes ~5 function implementations instead of ~111 site conversions
- Net zero time cost (2–3 weeks abstraction saves 1–2 weeks on backend swap)
- Already documented and analyzed in `architecture-rendering.md`

**Core MuRenderer API:**

| Function | Replaces | Coverage |
|----------|----------|----------|
| `RenderQuad2D()` | 9 `RenderBitmap*` variants | ~80% of all rendering (sprites, UI, terrain, effects) |
| `RenderTriangles()` | `glDrawArrays` path in ZzzBMD.cpp | Skeletal mesh rendering |
| `RenderQuadStrip()` | `GL_QUAD_STRIP` paths | Trail effects, ribbons |
| `SetBlendMode()` | 7 `Enable*Blend` functions | Alpha blending state |
| `SetDepthTest()` / `SetFog()` | `glEnable(GL_DEPTH_TEST)`, `glFogi` | Pipeline state |
| `MatrixStack` class | `glPushMatrix`/`glPopMatrix`/`glTranslatef` | Transform management |

**Shader Programs (SDL_gpu backend):**

| Shader | Purpose | Lines |
|--------|---------|-------|
| `basic_colored` | Flat colored geometry (UI lines, debug, fades) | ~20 |
| `basic_textured` | Textured quads with vertex color multiply (~80% of rendering) | ~25 |
| `model_mesh` | Skeletal mesh rendering (ZzzBMD.cpp) | ~25 |
| `shadow_volume` | Stencil shadow INCR/DECR passes | ~15 |
| `shadow_apply` | Fullscreen shadow overlay | ~15 |

**What this affects:** FR12–FR16 (rendering), NFR1 (performance), NFR11 (portability)

### Decision 2: Platform Abstraction — Compile-Time CMake Backends

**Decision:** Platform-specific code selected at compile time via CMake (Option C)

**Choice:** `MUPlatform` library contains platform-specific `.cpp` files in subdirectories, selected by CMake based on target OS. Shared headers define the interface.

**Structure:**
```
MUPlatform/
├── PlatformCompat.h          # Shared interface (type aliases, function declarations)
├── PlatformTypes.h            # Platform type mappings
├── PlatformLibrary.h          # Dynamic library loading interface
├── win32/
│   ├── PlatformCompat.cpp     # Win32 implementations
│   └── PlatformLibrary.cpp    # LoadLibrary/GetProcAddress
└── posix/
    ├── PlatformCompat.cpp     # POSIX implementations (macOS + Linux)
    └── PlatformLibrary.cpp    # dlopen/dlsym
```

**CMake selection:**
```cmake
if(WIN32)
    target_sources(MUPlatform PRIVATE win32/PlatformCompat.cpp win32/PlatformLibrary.cpp)
else()
    target_sources(MUPlatform PRIVATE posix/PlatformCompat.cpp posix/PlatformLibrary.cpp)
endif()
```

**Rationale:**
- Zero runtime overhead (no virtual dispatch, no function pointers for platform calls)
- Clean separation — platform code lives in dedicated files, not scattered `#ifdef` blocks
- `MUPlatform` CMake target already exists (currently empty, pre-migration)
- macOS and Linux share POSIX APIs for library loading, file I/O, timing — one `posix/` directory covers both
- Platform-specific divergence (macOS Metal init vs Linux Vulkan init) handled by SDL3, not our code

**What this affects:** NFR11 (zero `#ifdef _WIN32` in game logic), NFR14 (single codebase)

### Decision 3: .NET AOT — Cross-Platform Library Loading with char16_t

**Decision:** Platform-abstracted dynamic library loading + `char16_t` string encoding

**Key choices:**
1. **Library loading:** `PlatformLibrary.h` interface wrapping `LoadLibrary`/`GetProcAddress` (Win32) and `dlopen`/`dlsym` (POSIX)
2. **String encoding:** Replace `wchar_t` with `char16_t` at the C++/.NET interop boundary — guarantees 2-byte encoding on all platforms (OpenMU protocol expects UTF-16LE)
3. **Build integration:** CMake detects platform RID (`win-x86`, `osx-arm64`, `linux-x64`), invokes `dotnet publish` with correct RID at configure time, copies output to build directory
4. **Graceful degradation:** If .NET library not found at runtime, game launches with clear error message (FR10) — allows rendering/input testing without network

**Library extension mapping:**

| Platform | RID | Extension | Loader |
|----------|-----|-----------|--------|
| Windows | `win-x86` / `win-x64` | `.dll` | `LoadLibrary` |
| macOS | `osx-arm64` / `osx-x64` | `.dylib` | `dlopen` |
| Linux | `linux-x64` | `.so` | `dlopen` |

**What this affects:** FR6–FR11 (server connectivity), NFR8–NFR10 (integration), NFR9 (.NET marshaling)

### Decision 4: Audio — MuAudio Abstraction with miniaudio Backend

**Decision:** Clean audio interface in `MUAudio` module, implemented with miniaudio (Option B)

**MuAudio API:**

| Function | Purpose | Replaces |
|----------|---------|----------|
| `MuAudio::Init()` | Initialize audio engine | `DirectSoundCreate` |
| `MuAudio::Shutdown()` | Cleanup | `IDirectSound::Release` |
| `MuAudio::PlayBGM(path)` | Stream background music | wzAudio BGM streaming |
| `MuAudio::StopBGM()` | Stop current BGM | wzAudio stop |
| `MuAudio::PlaySFX(id, volume)` | Play sound effect | `IDirectSoundBuffer::Play` |
| `MuAudio::SetBGMVolume(level)` | BGM volume control | wzAudio volume |
| `MuAudio::SetSFXVolume(level)` | SFX volume control | DirectSound volume |
| `MuAudio::IsEnabled()` | Check if audio available | — |

**Implementation:** miniaudio `ma_engine` for high-level playback, `ma_decoder` for format support (WAV, OGG, MP3). Single-header library, no external dependencies, cross-platform out of the box.

**Rationale:**
- Mirrors the MuRenderer strategy — abstraction first, backend behind it
- `MUAudio` CMake target already exists
- miniaudio is battle-tested, single-header, supports all required formats
- Clean API makes it testable and replaceable if needed

**What this affects:** FR17–FR19 (audio), NFR1 (performance — audio must not cause frame hitches)

### Decision 5: Build & CI — Phased Multi-Platform Expansion

**Decision:** Keep MinGW CI now, add native platform CI after migration completes (Option C)

**Phase 1 (Current → During Migration):**
- MinGW cross-compile CI (existing, catches regressions)
- clang-format + clang-tidy + cppcheck quality gates (existing)
- Developer-validated native builds on macOS/Linux

**Phase 2 (After SDL3 Migration Complete):**
- Add macOS runner (GitHub Actions `macos-latest`) — native Clang build
- Add Linux runner (GitHub Actions `ubuntu-latest`) — native GCC build
- All three platforms built and quality-gated in CI

**CMake additions for cross-platform:**
- New toolchain files: `cmake/toolchains/macos-arm64.cmake`, `cmake/toolchains/linux-x64.cmake`
- New presets in `CMakePresets.json` for macOS and Linux
- SDL3 as FetchContent or find_package dependency
- miniaudio as vendored single-header

**What this affects:** FR1–FR5 (platform build), NFR15 (CI quality gates)

### Decision 6: Migration Sequencing — .NET AOT Early

**Decision:** Move .NET AOT cross-platform (originally Phase 8) to Phase 2.5 — after SDL3 windowing/input, before rendering migration

**Revised sequence:**

| Phase | Content | Enables |
|-------|---------|---------|
| 0 | CMake scaffolding, platform headers, SDL3 dependency | Foundation |
| 1 | SDL3 windowing + message pump | App launches on Mac/Linux |
| 2 | SDL3 input | User interaction |
| **2.5** | **.NET AOT cross-platform (`.dylib`/`.so`, `char16_t`)** | **Server connectivity on Mac/Linux** |
| 3 | MuRenderer abstraction (OpenGL backend) | Rendering consolidation |
| 4 | SDL_gpu backend swap | Cross-platform rendering |
| 5 | Texture system migration | Asset loading via SDL_gpu |
| 6 | miniaudio migration | Cross-platform audio |
| 7 | FreeType text rendering | Post-MVP |
| 9 | Linux build + testing | Platform validation |
| 10 | macOS build + testing | Platform validation |

**Rationale:**
- .NET AOT is well-scoped (library loading + char16_t) and low risk
- Enables end-to-end testing ("connect to OpenMU on Mac") from Phase 2.5 onward
- All subsequent phases can be validated with real server connectivity
- Without early .NET, you'd complete rendering migration but couldn't test the full gameplay loop until Phase 8

**What this affects:** All FRs — sequencing determines when each requirement becomes testable

## Implementation Patterns & Consistency Rules

_These patterns ensure AI agents write consistent, compatible code during the migration. They complement the 47 rules in project-context.md._

### Pattern 1: Abstraction Layer Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Namespace | `mu::` (lowercase) | `mu::MuRenderer`, `mu::MuAudio` |
| Public classes | `Mu` prefix, PascalCase | `MuRenderer`, `MuAudio`, `MuPlatform` |
| File naming | PascalCase matching class | `MuRenderer.h`, `MuRenderer.cpp` |
| Internal helpers | `snake_case` in anonymous namespace | `static void flush_batch()` |
| Header guards | `#pragma once` only | — |
| Singleton access | `GetInstance()` (matches existing codebase) | `MuRenderer::GetInstance()` |

```cpp
// MuRenderer.h
#pragma once
namespace mu {
class MuRenderer {
public:
    static MuRenderer& GetInstance();
    void RenderQuad2D(/* params */);
};
} // namespace mu
```

### Pattern 2: OpenGL → MuRenderer Migration (The Three-Line Swap)

**Before (legacy):**
```cpp
glBegin(GL_TRIANGLE_FAN);
glTexCoord2f(u0, v0); glVertex3f(x0, y0, z0);
glTexCoord2f(u1, v1); glVertex3f(x1, y1, z1);
glEnd();
```

**After (MuRenderer):**
```cpp
mu::MuRenderer::GetInstance().RenderQuad2D(texture, rect, uvRect, color, blendMode);
```

**Rules:**
- Never mix OpenGL calls and MuRenderer calls in the same render pass
- Migrate one function at a time, not one file at a time (smaller PRs)
- Each migration PR must include ground truth screenshot comparison
- If a `glBegin` site doesn't fit the existing MuRenderer API, extend the API — don't bypass the abstraction

### Pattern 3: Platform-Specific Code Placement

**Rule:** Zero platform `#ifdef` in game logic. All platform code in `MUPlatform/`.

```cpp
// WRONG — in game logic
#ifdef _WIN32
    HMODULE lib = LoadLibrary("ClientLibrary.dll");
#else
    void* lib = dlopen("libClientLibrary.dylib", RTLD_NOW);
#endif

// RIGHT — in game logic
auto lib = mu::MuPlatform::LoadLibrary("ClientLibrary");
// Implementation lives in MUPlatform/win32/ and MUPlatform/posix/
```

**If you need a one-off platform check:** Wrap it in a `mu::MuPlatform::` function, even if trivial. The abstraction is the contract.

### Pattern 4: Error Handling & Error Taxonomy

**Error Taxonomy — Log Prefix Convention:**

All `g_ErrorReport.Write()` calls in new and migrated code must use a domain prefix for structured diagnostics:

| Prefix | Domain | When |
|--------|--------|------|
| `PLAT` | Platform / OS | Library loading, window creation, file I/O failures |
| `RENDER` | Rendering pipeline | Shader compile, texture upload, GPU device lost |
| `AUDIO` | Audio system | Device init, decode failure, playback error |
| `NET` | Network / .NET interop | Connection, protocol mismatch, marshaling errors |
| `ASSET` | Asset loading | Missing file, corrupt data, format error |
| `GAME` | Game logic | Invalid state, unexpected conditions |
| `INPUT` | Input system | SDL3 input init, device enumeration |

**Format:** `PREFIX: context — what failed`

```cpp
g_ErrorReport.Write(L"ASSET: texture load failed — Data/Texture/%hs", path);
g_ErrorReport.Write(L"NET: OpenMU handshake failed — protocol version mismatch");
g_ErrorReport.Write(L"PLAT: dlopen failed — %hs", dlerror());
```

**Optional enum for programmatic use (in MUCore):**

```cpp
namespace mu {
enum class ErrorDomain : uint8_t
{
    Platform,
    Render,
    Audio,
    Net,
    Asset,
    Game,
    Input
};
} // namespace mu
```

The enum enables future error counting by category or severity filtering without requiring infrastructure now. The prefix strings alone give `grep RENDER MuError.log` for all rendering issues.

**Error Handling Rules:**

| Rule | Implementation |
|------|---------------|
| Fallible functions return `bool` | `[[nodiscard]] bool Init()` |
| Log with taxonomy prefix before returning false | `g_ErrorReport.Write(L"RENDER: context — what failed")` |
| No exceptions from abstraction layers | Return codes only |
| No `assert()` on runtime conditions | Explicit validation + error return |
| Error messages identify failure type | Prefix + function name + what was attempted + what failed |

```cpp
[[nodiscard]] bool MuRenderer::Init()
{
    if (!InitSDLGpu())
    {
        g_ErrorReport.Write(L"RENDER: MuRenderer::Init() — SDL_gpu initialization failed");
        return false;
    }
    return true;
}
```

### Pattern 5: Asset Path Handling

- All new path construction: `std::filesystem::path`
- Forward slashes only — never `\\`
- Relative paths from game binary directory (`Data/...`)
- Platform library extensions resolved at build time:
  ```cpp
  // CMake: -DMU_DOTNET_LIB_EXT=".dylib"
  auto libPath = std::filesystem::path("ClientLibrary") += MU_DOTNET_LIB_EXT;
  ```
- Legacy `char*` paths: wrap in `std::filesystem::path` at the boundary, don't refactor legacy internals

### Pattern 6: SDL3 API Usage

- SDL3 calls only in `MUPlatform/` and `MURenderFX/` (abstraction layers) — never in game logic
- Error checking: `if (result < 0) { g_ErrorReport.Write(L"SDL: %hs", SDL_GetError()); }`
- Resource cleanup: RAII wrappers or explicit cleanup in shutdown path
- Window handle: singleton access via `mu::MuPlatform::GetWindow()` — never passed through game logic

### Pattern 7: Migration Commit Granularity

| Element | Convention |
|---------|-----------|
| Scope | One migration unit per commit (one function, one call site group) |
| Message format | `refactor(render): migrate RenderBitmap to MuRenderer::RenderQuad2D` |
| Scope tags | `render`, `audio`, `platform`, `network`, `input` |
| Batching | Never batch unrelated migrations in one commit |
| Visual changes | Reference ground truth screenshots in commit body |

### Anti-Patterns (Never Do This)

| Anti-Pattern | Why | Instead |
|-------------|-----|---------|
| `#ifdef _WIN32` in game logic | Breaks NFR11, scatters platform code | `mu::MuPlatform::` function |
| Direct `glBegin` alongside MuRenderer | Mixed rendering paths cause state corruption | Complete migration per function |
| `assert()` on SDL/audio/network failures | Crashes in production | `[[nodiscard]] bool` + error log |
| Hardcoded `.dll`/`.dylib`/`.so` | Non-portable | CMake define `MU_DOTNET_LIB_EXT` |
| `wchar_t` at .NET boundary | 4 bytes on Linux, protocol expects 2 | `char16_t` |
| `new`/`delete` in new code | Memory leaks | `std::unique_ptr` |
| Modifying generated `Dotnet/` files | Overwritten by XSLT codegen | Edit XML definitions instead |

## Project Structure & Boundaries

### Current Module Structure

```
MuMain/src/source/
├── Main/           → Main (entry point, WinMain, stdafx)
├── Core/           → MUCore (error reporting, utilities, platform compat)
├── Protocol/       → MUProtocol (crypto, packet encoding)
├── Data/           → MUData (game data loading, i18n)
├── RenderFX/       → MURenderFX (effects, models, textures, OpenGL)
├── Audio/          → MUAudio (sound system)
├── ThirdParty/     → MUThirdParty (external code)
├── Platform/       → MUPlatform (platform abstraction — currently empty)
├── Game/           → MUGame (network, world, gameplay, UI, scenes, dotnet)
│   ├── Network/
│   ├── World/
│   ├── Gameplay/
│   ├── UI/
│   ├── Scenes/
│   └── Dotnet/     (generated — DO NOT EDIT)
└── Translation/    → (part of MUData)
```

### Migration Additions

```
MuMain/src/source/
├── Platform/                      ← MUPlatform (Decision 2)
│   ├── PlatformCompat.h           # Shared interface declarations
│   ├── PlatformTypes.h            # Cross-platform type aliases
│   ├── PlatformLibrary.h          # Dynamic library loading interface
│   ├── win32/
│   │   ├── PlatformCompat.cpp     # Win32 implementations
│   │   └── PlatformLibrary.cpp    # LoadLibrary/GetProcAddress
│   └── posix/
│       ├── PlatformCompat.cpp     # POSIX implementations (macOS + Linux)
│       └── PlatformLibrary.cpp    # dlopen/dlsym
│
├── RenderFX/                      ← MURenderFX (Decision 1)
│   ├── MuRenderer.h               # Rendering abstraction interface
│   ├── MuRenderer.cpp             # (Phase 3: OpenGL backend)
│   ├── MuRendererSDLGpu.cpp       # (Phase 4: SDL_gpu backend, replaces above)
│   └── shaders/                   # (Phase 4: SDL_gpu shaders)
│       ├── basic_colored.hlsl
│       ├── basic_textured.hlsl
│       ├── model_mesh.hlsl
│       ├── shadow_volume.hlsl
│       └── shadow_apply.hlsl
│
├── Audio/                         ← MUAudio (Decision 4)
│   ├── MuAudio.h                  # Audio abstraction interface
│   ├── MuAudio.cpp                # miniaudio implementation
│   └── miniaudio.h                # Vendored single-header library
│
└── Game/Dotnet/                   ← .NET AOT (Decision 3)
    └── Connection.h               # Updated: char16_t, platform library loading

MuMain/cmake/
├── toolchains/
│   ├── mingw-w64-i686.cmake       # Existing
│   ├── macos-arm64.cmake          # New: macOS native build
│   └── linux-x64.cmake            # New: Linux native build
└── FindDotnetAOT.cmake            # New: CMake module for .NET AOT RID detection
```

### Architectural Boundaries

| Boundary | Rule | Enforcement |
|----------|------|-------------|
| Game logic → Platform | Call `mu::MuPlatform::` functions, never OS APIs | Code review + clang-tidy |
| Game logic → Renderer | Call `mu::MuRenderer::` API, never OpenGL directly | Remove GLEW from MUGame link |
| Game logic → Audio | Call `mu::MuAudio::` API, never DirectSound/miniaudio | Remove DirectSound from MUGame link |
| Game logic → .NET | Through `Dotnet/Connection.h` function pointers | Existing pattern, unchanged |
| Platform → SDL3 | Only `MUPlatform` and `MURenderFX` may include SDL3 | CMake target link visibility |
| Generated code | `Dotnet/PacketBindings_*.h`, `PacketFunctions_*.h/.cpp` read-only | CI check |
| Legacy ↔ Modern | Existing keeps conventions; new code uses modern C++20 | Code review guidance |

### CMake Dependency Graph (Post-Migration)

```
MUCommon (INTERFACE)
    │
    ├── MUCore
    │     ├── MUPlatform ← SDL3 (windowing, input) + platform backends
    │     ├── MUProtocol
    │     ├── MUData
    │     ├── MURenderFX ← SDL3_gpu (rendering) + shaders
    │     ├── MUAudio ← miniaudio
    │     └── MUThirdParty
    │
    └── MUGame ← links all above + .NET AOT at runtime
          └── Main (entry point)
```

### Requirements → Structure Mapping

| Requirement | Module | Key Files |
|-------------|--------|-----------|
| FR1–FR5 (Build) | CMake | `CMakePresets.json`, `cmake/toolchains/`, `CMakeLists.txt` |
| FR6–FR11 (Network) | MUGame/Dotnet + MUPlatform | `Connection.h`, `PlatformLibrary.h` |
| FR12–FR16 (Rendering) | MURenderFX | `MuRenderer.h`, `MuRendererSDLGpu.cpp`, `shaders/` |
| FR17–FR19 (Audio) | MUAudio | `MuAudio.h`, `MuAudio.cpp` |
| FR20–FR22 (Input) | MUPlatform | `PlatformCompat.h`, SDL3 input wrapping |
| FR23–FR36 (Gameplay) | MUGame | Existing files — regression, no structural changes |
| FR37–FR40 (Stability) | MUCore + MUPlatform | `ErrorReport.h`, platform-specific logging |
| NFR11–NFR14 (Portability) | MUPlatform | All platform isolation enforced here |
| NFR15–NFR18 (Maintainability) | CI + CMake | `.github/workflows/ci.yml`, `.clang-format` |

## Architecture Validation

### Coherence Validation

| Check | Result |
|-------|--------|
| MuRenderer (D1) ↔ Platform abstraction (D2) | **Pass** — Renderer in MURenderFX uses SDL_gpu; platform layer handles windowing separately |
| .NET AOT (D3) → Platform abstraction (D2) | **Pass** — Library loading through `PlatformLibrary.h` in MUPlatform |
| MuAudio (D4) independent of rendering (D1) | **Pass** — Both depend on MUCore only, no cross-dependency |
| Build/CI (D5) supports all platform decisions | **Pass** — Phased: MinGW now, native runners post-migration |
| Migration sequencing (D6) respects dependencies | **Pass** — Foundation → windowing → input → .NET → rendering → audio |
| Patterns (Step 5) align with project-context.md | **Pass** — Extends existing 47 rules, no contradictions |
| Error taxonomy (Pattern 4) compatible with existing logging | **Pass** — Prefix convention on existing `g_ErrorReport.Write()` |

### Requirements Coverage

**Functional Requirements — 40/40 covered:**

| FR Group | Architecture Support |
|----------|---------------------|
| FR1–FR5 (Build) | CMake toolchain files + presets + CI pipeline (Decision 5) |
| FR6–FR11 (Network) | PlatformLibrary + char16_t + CMake RID (Decision 3) |
| FR12–FR16 (Rendering) | MuRenderer + SDL_gpu + 5 shaders (Decision 1) |
| FR17–FR19 (Audio) | MuAudio + miniaudio (Decision 4) |
| FR20–FR22 (Input) | SDL3 input in MUPlatform (Decision 2) |
| FR23–FR36 (Gameplay) | Regression — no architectural changes, existing code preserved |
| FR37–FR40 (Stability) | Error taxonomy + diagnostic logging + error handling patterns |

**Non-Functional Requirements — 18/18 covered:**

| NFR Group | Architecture Support | Notes |
|-----------|---------------------|-------|
| NFR1–NFR3 (Performance) | SDL_gpu native backends, game loop preserved | Add `mu::MuTimer` in MUCore for frame time instrumentation |
| NFR4–NFR7 (Security) | Packet validation preserved, no-assert rule enforced | |
| NFR8–NFR10 (Integration) | char16_t encoding, CMake RID, OpenMU version doc | |
| NFR11–NFR14 (Portability) | Platform abstraction, compile-time CMake selection | |
| NFR15–NFR18 (Maintainability) | CI gates, modern C++, conventional commits | |

### Gap Analysis

| Gap | Severity | Resolution |
|-----|----------|------------|
| Frame time instrumentation (NFR1–NFR3) | Minor | `mu::MuTimer` utility in MUCore — `std::chrono::steady_clock` wrapper with `FrameStart()`/`FrameEnd()`/`GetFrameTimeMs()`, logs variance to `MuError.log` |
| OpenMU compatible version documentation | Minor | Add to build docs during Phase 2.5 (.NET AOT cross-platform) |

No critical gaps. Architecture covers all requirements.

### Specification-Only Content Check

| Check | Status |
|-------|--------|
| No method bodies in code blocks | **Pass** — Examples are 3–5 line patterns, not implementations |
| No full class implementations | **Pass** — APIs as function signatures and tables |
| No SQL DDL | **N/A** |
| No service logic | **Pass** |

### Architecture Completeness

- [x] All 6 core decisions documented with rationale and alternatives considered
- [x] Abstraction APIs specified (MuRenderer, MuAudio, PlatformLibrary)
- [x] Directory structure with migration additions mapped
- [x] Boundaries defined and enforcement mechanisms identified
- [x] Migration sequence with dependency ordering
- [x] 7 implementation patterns + anti-patterns for agent consistency
- [x] Error taxonomy defined (7 domain prefixes)
- [x] All 40 FRs and 18 NFRs have architectural support
- [x] No prohibited libraries referenced
- [x] No implementation code in architecture document
