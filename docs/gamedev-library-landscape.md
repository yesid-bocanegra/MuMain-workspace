# C++ Game Development Library Landscape

> Reference for evaluating third-party libraries. Surveyed April 2026 against the MuMain codebase and SDL3 migration. See [CROSS_PLATFORM_DECISIONS.md](CROSS_PLATFORM_DECISIONS.md) for decisions already made.

## Current MuMain Stack

| Category | Library | Form | How integrated |
|----------|---------|------|----------------|
| Platform / Windowing | SDL3 | FetchContent | `src/CMakeLists.txt` |
| GPU Rendering | SDL_GPU (via SDL3) | — | `MuRendererSDLGpu.cpp` |
| Math | GLM 1.0.1 | FetchContent | `CMakeLists.txt` (story 7-9-7) |
| Audio | miniaudio | Vendored headers | `dependencies/miniaudio/` |
| JPEG Decoding | libjpeg-turbo (turbojpeg) | System / static lib | `find_library` / `MU_TURBOJPEG_STATIC_LIB` |
| Image Write | stb_image_write | Vendored header | `src/ThirdParty/stb/` |
| JSON | nlohmann/json | Vendored header | `src/ThirdParty/json.hpp` |
| Debug UI | Dear ImGui | Git submodule | `src/ThirdParty/imgui/` |
| Shader Compilation | glslang + SPIRV-Cross | FetchContent | `CMakeLists.txt` |

---

## 1. Math / Linear Algebra

| Library | License | Form | Status | Best for |
|---------|---------|------|--------|----------|
| **GLM** | MIT | Header-only | Active (10.8k stars) | Cross-platform, GLSL-style API — mirrors shader code |
| **DirectXMath** | MIT | Header-only | Active (Microsoft) | Windows/Xbox; SIMD-native types (`XMMATRIX`) |
| **cglm** | MIT | Header-only | Active (2.9k stars) | C projects; GLM equivalent for C with SIMD |
| **Eigen** | MPL 2.0 | Header-only | Active | Robotics, ML — overkill for game math |
| **Realtime Math (RTM)** | MIT | Header-only | Stable (780 stars) | Animation runtimes, SIMD-optimized QVV transforms |
| **HandmadeMath** | Public Domain | Header-only | Community | Single-header C; minimal vec/mat/quat |

**MuMain choice: GLM.** Mirrors GLSL naming, provides depth-convention variants (`perspectiveLH_ZO` for Vulkan/Metal Z [0,1]), replaces hand-rolled `mat4::` namespace. SIMD optional via `GLM_FORCE_INTRINSICS`.

---

## 2. Physics

| Library | License | Form | Status | Notable users |
|---------|---------|------|--------|---------------|
| **Jolt Physics** | MIT | Compiled | Very active (9.9k stars) | Horizon Forbidden West |
| **Bullet** | zlib | Compiled | Mature (14.4k stars) | GTA V, Red Dead Redemption |
| **Box2D** | MIT | Compiled | Active (v3.0 rewrite, 9.6k stars) | Angry Birds, Limbo |
| **PhysX** | BSD 3-Clause | Compiled | Active (NVIDIA, 3.5k stars) | Unreal Engine default |
| **Havok** | Proprietary ($50k flat) | Binary SDK | Active | Doom Eternal, Destiny 2, FF XVI |

**MuMain relevance: Low.** MU Online uses server-authoritative game logic with client-side animation. No client-side physics simulation needed. If ever needed, Jolt is the modern pick — MIT, multithreaded, proven in AAA.

---

## 3. Audio

| Library | License | Form | Status | Notable users |
|---------|---------|------|--------|---------------|
| **miniaudio** | Public Domain / MIT | Single header | Active (6.6k stars) | raylib, custom engines |
| **OpenAL Soft** | LGPL 2.0 | Compiled | Active (2.6k stars) | Minecraft Java Edition |
| **SoLoud** | zlib | Compiled | Stable (2.1k stars) | Indie engines |
| **FMOD** | Proprietary (free < $200k rev) | Binary SDK | Active | Celeste, WoW, Crysis, Forza |
| **Wwise** | Proprietary (free < $250k budget) | Binary SDK | Active | Overwatch, Witcher 3 |

**MuMain choice: miniaudio** (adopted story 7-9-4). Zero dependencies, cross-platform, single-header. FMOD/Wwise are for games needing adaptive music systems, real-time mixing, and sound designer tools.

---

## 4. Networking

| Library | License | Form | Status | Notable users |
|---------|---------|------|--------|---------------|
| **GameNetworkingSockets** | BSD 3-Clause | Compiled | Active (Valve, 9.3k stars) | CS:GO, Dota 2, TF2 |
| **ENet** | MIT | Compiled | Stable (3.2k stars) | Indie multiplayer games |
| **yojimbo** | BSD 3-Clause | Compiled | Stable | FPS-style netcode |
| **RakNet** | BSD 2-Clause | Compiled | **Abandoned** | Historical MMO use |

**MuMain relevance: None.** MU uses a .NET Native AOT network bridge (`ClientLibrary/`) speaking the MU Online server protocol with XSLT-generated packet bindings. None of these libraries apply.

---

## 5. Rendering / Graphics Helpers

| Library | License | Form | Status | Use case |
|---------|---------|------|--------|----------|
| **meshoptimizer** | MIT | Compiled | Very active (7.4k stars) | Vertex cache, overdraw, LOD, Nanite-style clusterlod |
| **SPIRV-Cross** | Apache 2.0 | Compiled | Active (Khronos) | SPIR-V to GLSL/HLSL/MSL transpilation |
| **glslang** | BSD 3-Clause | Compiled | Active (Khronos) | GLSL/HLSL front-end, SPIR-V generation |
| **KTX-Software** | Apache 2.0 | Compiled | Active (Khronos, 1.2k stars) | GPU-compressed texture containers |
| **tinyobjloader** | MIT | Header-only | Stable | Wavefront OBJ loading |

**MuMain uses: glslang + SPIRV-Cross** for the HLSL shader pipeline. meshoptimizer could optimize `.bmd` mesh loading in a future offline asset pipeline.

---

## 6. UI / GUI

| Library | License | Form | Status | Notable users |
|---------|---------|------|--------|---------------|
| **Dear ImGui** | MIT | Source files | Very active (72.3k stars) | Nearly every custom engine |
| **Nuklear** | Public Domain / MIT | Header-only | Active (11k stars) | C-based engines |
| **RmlUi** | MIT | Compiled | Active (4k stars) | HTML/CSS-style game UIs |

**MuMain uses: Dear ImGui** for `_EDITOR` debug builds. Player-facing UI uses the custom `CNewUI*` class hierarchy. RmlUi would be a consideration only for a full UI rewrite.

---

## 7. Serialization / Data

| Library | License | Form | Status | Notable users |
|---------|---------|------|--------|---------------|
| **nlohmann/json** | MIT | Header-only | Active (49.3k stars) | Universal C++ JSON |
| **RapidJSON** | MIT | Header-only | Stable (15k stars) | Tencent; performance-critical JSON |
| **simdjson** | Apache 2.0 | Compiled | Active (23.6k stars) | Fastest JSON parser (SIMD) |
| **FlatBuffers** | Apache 2.0 | Compiled + codegen | Active (Google, 25.7k stars) | Zero-copy; designed for games |
| **cereal** | BSD 3-Clause | Header-only | Stable (4.6k stars) | C++ binary/XML/JSON serialization |
| **MessagePack** | Boost | Header-only | Active | Compact binary serialization |

**MuMain uses: nlohmann/json** (vendored as `json.hpp`). Adequate for config files and i18n data. FlatBuffers would be relevant only for high-throughput binary data paths.

---

## 8. Profiling / Debugging

| Library | License | Form | Status | Notable users |
|---------|---------|------|--------|---------------|
| **Tracy** | BSD 3-Clause | Compiled + viewer | Very active (15.6k stars) | Godot Engine |
| **Optick** | MIT | Compiled | Stable (3.1k stars) | O3DE |
| **RenderDoc** | MIT | Standalone app | Active (10.6k stars) | Industry standard GPU debugger |
| **Superluminal** | Proprietary | Standalone app | Active | AAA studios |

**MuMain relevance: Tracy is a strong future candidate.** Once the renderer stabilizes post-7-9-7, frame profiling will be needed. Tracy covers CPU + GPU + memory + locks. Its instrumentation macros (`ZoneScoped`) compile to zero cost when disabled.

---

## 9. Asset Loading

| Library | License | Form | Status | Use case |
|---------|---------|------|--------|----------|
| **Assimp** | BSD 3-Clause | Compiled | Active (12.8k stars) | 40+ format importer |
| **tinygltf** | MIT | Header-only | Active (2.4k stars) | glTF 2.0 loading |
| **stb libraries** | Public Domain / MIT | Header-only | Active (33.2k stars) | Image, font, vorbis, etc. |
| **cgltf** | MIT | Header-only | Active | Lightweight glTF for C |

**MuMain relevance: None.** Assets use proprietary MU Online formats (`.bmd`, `.ozj`, `.ozb`, `.att`, `.map`) with custom loaders. These libraries don't understand MU's formats.

---

## 10. ECS Frameworks

| Library | License | Form | Status | Notable users |
|---------|---------|------|--------|---------------|
| **EnTT** | MIT | Header-only | Very active (12.5k stars) | Minecraft Bedrock, Diablo II: Resurrected, CoD Vanguard |
| **flecs** | MIT | Compiled / header | Very active (8.2k stars) | Hytale (Hypixel Studios) |

**MuMain relevance: None.** MU uses OOP class hierarchies (`CHARACTER`, `OBJECT`, `PART_t`). Adopting ECS would require a full architectural rewrite.

---

## 11. Scripting Integration

| Library | License | Form | Status | Notable users |
|---------|---------|------|--------|---------------|
| **Lua + sol2** | MIT | Compiled + header-only | Stable (5k stars) | WoW, Roblox (Luau variant) |
| **LuaJIT** | MIT | Compiled | Maintained | Near-C performance scripting |
| **AngelScript** | zlib | Compiled | Active | It Takes Two (1.7M lines), The Finals |
| **ChaiScript** | BSD 3-Clause | Header-only | Stable | Small custom engines |

**MuMain relevance: Low.** Game logic is compiled C++. Scripting could be useful for modding or quest systems in the future. If needed, Lua + sol2 is the safest choice; AngelScript suits C++-heavy codebases.

---

## 12. Platform / Utility

| Library | License | Form | Status | Notable users |
|---------|---------|------|--------|---------------|
| **SDL3** | zlib | Compiled | Very active (15.2k stars) | Valve (Steam Deck) |
| **GLFW** | zlib | Compiled | Active (14.9k stars) | OpenGL/Vulkan windowing |
| **{fmt}** | MIT | Header-only | Very active (23.4k stars) | Basis of C++20 `std::format` |
| **spdlog** | MIT | Header-only / compiled | Active (28.6k stars) | Structured logging |
| **raylib** | zlib | Compiled | Very active | Education, rapid prototyping |

**MuMain uses: SDL3.** Covers windowing, input, GPU rendering, gamepad, haptics. GLFW is redundant when using SDL3. `{fmt}` is unnecessary — C++20 provides `std::format`. `spdlog` is unnecessary — existing `g_ErrorReport` + `g_ConsoleDebug` pattern is established.

---

## Decision Summary

| Category | Current | Future candidate | Not needed |
|----------|---------|------------------|------------|
| Math | **GLM** (adopting) | — | Eigen, DirectXMath |
| Audio | **miniaudio** | — | FMOD, Wwise, OpenAL |
| Platform | **SDL3** | — | GLFW, raylib |
| GPU | **SDL_GPU** | — | Raw Vulkan/Metal |
| Shaders | **glslang + SPIRV-Cross** | — | shaderc |
| Debug UI | **Dear ImGui** | — | Nuklear |
| JSON | **nlohmann/json** | — | RapidJSON, simdjson |
| Image | **stb_image_write + turbojpeg** | — | stb_image |
| Profiling | `g_ErrorReport` / `g_ConsoleDebug` | **Tracy** | Optick, Superluminal |
| Mesh Optimization | — | **meshoptimizer** (if asset pipeline built) | — |
| Rendering Debug | — | **RenderDoc** (external tool) | — |
| Physics | — | **Jolt** (if ever needed) | Bullet, PhysX |
| Scripting | — | **Lua + sol2** (if modding desired) | ChaiScript |
| ECS | — | — | EnTT, flecs (arch. mismatch) |
| Networking | **.NET AOT bridge** | — | ENet, GNS, RakNet |
| Asset Loading | Custom MU loaders | — | Assimp, tinygltf |
