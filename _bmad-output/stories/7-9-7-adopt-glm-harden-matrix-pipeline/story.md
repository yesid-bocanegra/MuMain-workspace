# Story 7.9.7: Adopt GLM and Harden Renderer Matrix Pipeline

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.9 - macOS Game Loop & Win32 Render Path Migration |
| Story ID | 7.9.7 |
| Story Points | 13 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-RENDER-GLM-MATRIX |
| FRs Covered | Correct 3D perspective rendering, particle billboards, depth testing, and fog on SDL_GPU (Metal/Vulkan/D3D12) |
| Prerequisites | 7-9-6 (completeness-gate), 7-9-2 (done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Replace hand-rolled mat4:: with GLM; fix depth conventions, particle billboards, terrain rendering, fog uniform binding; centralize viewport scaling |
| project-docs | documentation | Story artifacts |

---

## Background

Story 7-9-6 migrated 250+ raw GL calls to MuRenderer and a follow-up commit (21a0fd14) implemented a hand-rolled matrix stack (`mat4::` namespace) to replace OpenGL's fixed-function pipeline. This restored 3D perspective rendering — architecture, models, and chains now render correctly.

However, several rendering subsystems remain broken:

1. **Particle effects and light billboards** render as misaligned flat rectangles instead of camera-facing sprites (orange/red boxes visible in scene)
2. **Terrain data** is partially missing (ground geometry not fully rendering)
3. **Depth convention mismatch** — hand-rolled `mat4::Perspective` uses OpenGL Z [-1,1] but SDL_GPU (Metal/Vulkan) uses Z [0,1], causing depth buffer artifacts
4. **Fog uniform binding** uses `SDL_BindGPUFragmentStorageBuffers` but the compiled MSL shader declares `constant FogUniforms& [[buffer(0)]]` — potential slot mismatch
5. **Viewport scaling** is computed in multiple places (BeginScene, ConvertX/ConvertY, RenderQuad2D ortho) with risk of double-scaling
6. **Compiled shader blobs** in `src/shaders/compiled/` are stale and don't match HLSL source — MinGW/offline builds load wrong shaders

### Why GLM

The hand-rolled `mat4::` utilities (~150 lines) duplicate what GLM provides as a battle-tested, header-only, MIT-licensed library. GLM:
- Has exact `gluPerspective`/`glOrtho`/`glRotate`/`glTranslate` equivalents
- Handles depth conventions explicitly: `glm::perspectiveLH_ZO()` for Vulkan/Metal Z [0,1]
- Is the industry standard for OpenGL→modern API migrations
- Is header-only — zero runtime cost, no shared library management

---

## Story

**[VS-0] [Flow:Enabler]**

**As a** developer,
**I want** the SDL_GPU renderer to use GLM for all matrix math with correct depth conventions,
**so that** the 3D scene renders correctly on Metal/Vulkan/D3D12 (perspective, particles, terrain, fog, depth).

---

## Functional Acceptance Criteria

- [ ] **AC-1:** GLM integrated via CMake FetchContent (header-only, no binary dependency). Version: latest stable (1.0.1+).
- [ ] **AC-2:** `mat4::` namespace in MuRendererSDLGpu.cpp fully replaced with `glm::` equivalents. No hand-rolled matrix math remains.
- [ ] **AC-3:** Perspective projection uses `glm::perspectiveLH_ZO` (left-handed, Z [0,1]) matching SDL_GPU/Metal/Vulkan depth convention. Depth buffer correctly clips near/far geometry.
- [ ] **AC-4:** Orthographic projection uses `glm::orthoLH_ZO` for 2D rendering. Loading screen, login UI, and HUD elements render at correct scale and position.
- [ ] **AC-5:** Particle billboard effects render as camera-facing quads (not misaligned flat rectangles). Light sources, fire effects, and glow halos display correctly.
- [ ] **AC-6:** Terrain geometry renders completely — no missing ground patches or holes in the landscape.
- [ ] **AC-7:** Fog uniform binding corrected — fog data reaches the fragment shader and fog renders when enabled by the game code.
- [ ] **AC-8:** Viewport scaling centralized — single source of truth for 640×480 design space → physical pixel conversion. No double-scaling.
- [ ] **AC-9:** Pre-compiled shader blobs in `src/shaders/compiled/` updated to match current HLSL source (float4x4 mvp uniform). MinGW/offline builds load correct shaders.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance (naming, logging, error taxonomy per project-context.md)
- [ ] **AC-STD-2:** Testing Requirements — matrix math unit tests (perspective, ortho, rotate, translate, multiply) using Catch2
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format + cppcheck)
- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)

---

## Tasks / Subtasks

- [x] Task 1: Integrate GLM via FetchContent (AC: 1) — DONE commit 71fcd688
  - [x] 1.1: Add GLM to `CMakeLists.txt` via `FetchContent_Declare` / `FetchContent_MakeAvailable`
  - [x] 1.2: Add `glm::glm` to `target_link_libraries` for MURenderFX (header-only — propagates include path)
  - [x] 1.3: Verify `#include <glm/glm.hpp>` compiles in MuRendererSDLGpu.cpp

- [x] Task 2: Replace mat4:: with GLM (AC: 2, 3, 4) — DONE commits aae0bb42, bc8c7780
  - [x] 2.1-2.10: All mat4:: functions replaced with glm:: equivalents
  - [x] 2.8: `gluPerspective()` uses `glm::perspective()` with `GLM_FORCE_DEPTH_ZERO_TO_ONE`
  - [x] 2.9: Deleted `namespace mat4 {}` (~150 lines)
  - [x] 2.10: Matrix stack members use `glm::mat4` type
  - [x] 2.11: Fixed handedness — removed `GLM_FORCE_LEFT_HANDED` (game uses right-handed OpenGL convention)

- [ ] Task 3: Create depth buffer for render pass (AC: 5, 6) — **CRITICAL: HIGHEST PRIORITY**
  - [ ] 3.1: Create `SDL_GPUTexture` with depth format (`SDL_GPU_TEXTUREFORMAT_D24_UNORM` or `D32_FLOAT`) at swapchain dimensions
  - [ ] 3.2: Pass depth texture as `SDL_GPUDepthStencilTargetInfo` to `SDL_BeginGPURenderPass()` (currently `nullptr` at line ~726)
  - [ ] 3.3: Set `has_depth_stencil_target = true` in pipeline `SDL_GPUGraphicsPipelineTargetInfo` (currently `false` at line ~1867)
  - [ ] 3.4: Set depth clear to 1.0 (far plane) with `SDL_GPU_LOADOP_CLEAR` on the depth target
  - [ ] 3.5: Recreate depth texture on window resize (match swapchain dimensions)
  - **Why:** Without a depth buffer, ALL geometry draws on top of each other. Pipelines already enable depth test/write but there's no depth texture — the depth test silently does nothing. This causes the overlapping/z-fighting visible in the screenshot.
  - **Files:** `MuRendererSDLGpu.cpp` — `Init()` (create texture), `BeginFrame()` (attach to render pass), `BuildBlendPipeline()` (set has_depth_stencil_target=true)

- [ ] Task 4: Fix alpha discard for particle transparency (AC: 5) — **CRITICAL**
  - [ ] 4.1: In `SetAlphaTest(bool enabled)` override, update `m_fogUniform.alphaDiscardEnabled` to `enabled ? 1u : 0u` and set `s_fogDirty = true`
  - [ ] 4.2: In `SetAlphaFunc(int func, float ref)` override, update `m_fogUniform.alphaThreshold = ref` and set `s_fogDirty = true`
  - [ ] 4.3: Verify the fog uniform upload in `BeginFrame()` picks up the dirty flag and pushes updated data to the GPU
  - **Why:** `EnableAlphaTest()` in ZzzOpenglUtil.cpp calls `SetAlphaTest(true)` and `SetAlphaFunc(GL_GREATER, 0.25f)`. The renderer stores the bool but never propagates to the fog uniform's `alphaDiscardEnabled` field. The fragment shader's `discard` never fires — full quad rectangles render instead of alpha-masked particle sprites.
  - **Files:** `MuRendererSDLGpu.cpp` — `SetAlphaTest()` (line ~1422), `SetAlphaFunc()` (new override needed)

- [ ] Task 5: Fix fog uniform binding — storage vs constant buffer (AC: 7)
  - [ ] 5.1: Investigate SDL3 Metal backend buffer slot mapping: does `SDL_BindGPUFragmentStorageBuffers(slot=0)` map to `[[buffer(0)]]` when `numUniformBuffers=0`?
  - [ ] 5.2: If not — switch fog data to `SDL_PushGPUFragmentUniformData()` instead of storage buffer binding. Update shader `numStorageBuffers` from 1→0 and `numUniformBuffers` from 0→1 in `createShader()` call.
  - [ ] 5.3: Alternative: keep storage buffer but verify the compiled MSL uses `device` address space (not `constant`). If spirv-cross compiles cbuffer→constant, the binding type must match.
  - [ ] 5.4: Add fogFactor computation in the vertex shader — currently hardcoded to `0.0` (line 16 basic_textured.vert.hlsl). Compute `fogFactor = clamp((fogEnd - dist) / (fogEnd - fogStart), 0, 1)` where `dist = length(mvPosition.xyz)` (eye-space distance).
  - **Why:** The fog uniform buffer is created as `SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ` but the compiled MSL expects `constant FogUniforms& [[buffer(0)]]`. If SDL3's Metal backend maps storage buffers to different slots than constant buffers, the shader reads uninitialized data.
  - **Files:** `MuRendererSDLGpu.cpp` — `Init()` (buffer creation, line ~2033), draw calls (binding, lines ~1124/1215/1369), `LoadShaders()` (createShader metadata, line ~1607). `basic_textured.vert.hlsl` (fogFactor). `basic_textured.frag.hlsl` (unchanged).

- [ ] Task 6: Fix particle billboard rendering (AC: 5) — depends on Tasks 3+4
  - [ ] 6.1: Verify `RenderSprite()` in ZzzOpenglUtil.cpp (line ~806) produces correct Vertex3D data after matrix stack fix
  - [ ] 6.2: Verify `CameraMatrix` extraction via `GetOpenGLMatrix()` (line ~165) returns correct values from the GLM modelview matrix
  - [ ] 6.3: Verify `VectorTransform(Position, CameraMatrix, p2)` correctly transforms world→camera space
  - [ ] 6.4: Check blend mode pipeline selection — `EnableAlphaBlend()` maps to `BlendMode::Glow` (additive GL_ONE, GL_ONE). Verify pipeline index resolves correctly.
  - [ ] 6.5: Check if `BITMAP_LIGHT`, `BITMAP_FIRE`, `BITMAP_FLARE` textures load and register in TextureRegistry
  - **Why:** The orange rectangles are particle quads. With depth buffer + alpha discard fixed (Tasks 3+4), many of these should resolve. Remaining issues would be texture loading, blend mode, or camera matrix extraction.
  - **Files:** `ZzzOpenglUtil.cpp` (RenderSprite ~806, GetOpenGLMatrix ~165), `ZzzEffectParticle.cpp` (RenderParticles ~9017)

- [ ] Task 7: Verify terrain rendering (AC: 6) — depends on Task 3
  - [ ] 7.1: Terrain uses `RenderTriangles()` NOT `RenderQuadStrip()` — two triangles per quad via `{v0,v1,v2, v0,v2,v3}` pattern
  - [ ] 7.2: Verify terrain per-vertex colors: `mu::PackABGR(light[0], light[1], light[2], 1.f)` — check that `PrimaryTerrainLight` values are reasonable (loaded from JPEG light maps)
  - [ ] 7.3: Verify terrain texture binding: `BindTexture(BITMAP_MAPTILE + tileIndex)` — check these textures exist in TextureRegistry
  - [ ] 7.4: The bright white floor in the screenshot may be the terrain with all-white vertex colors (lighting data not loaded or zero). Investigate `CreateTerrainLight()` (~line 498) and `OpenTerrainLight()` (~line 557)
  - **Why:** With depth buffer (Task 3), terrain will render at correct depth. The white color is likely terrain vertex lighting — either the light JPEG didn't load or the luminosity calculation produces all-white.
  - **Files:** `World/ZzzLodTerrain.cpp` (RenderFace ~1262, RenderTerrainFace ~1468, CreateTerrainLight ~498)

- [ ] Task 8: Update pre-compiled shader blobs (AC: 9)
  - [ ] 8.1: Copy `out/build/macos-arm64/shaders/*.msl` → `src/shaders/compiled/` (basic_textured.vert.msl has float4x4 mvp now)
  - [ ] 8.2: Cross-compile SPIR-V blobs for Vulkan/Linux: update `src/shaders/compiled/*.spv`
  - [ ] 8.3: Verify MinGW offline build (`MU_ENABLE_SHADER_COMPILATION=OFF`) picks up correct blobs

- [ ] Task 9: Unit tests for GLM matrix stack (AC: STD-2)
  - [ ] 9.1: Add `tests/render/test_matrix_math.cpp` with Catch2 tests
  - [ ] 9.2: Test perspective projection Z range [0,1] for known near/far values
  - [ ] 9.3: Test ortho projection maps screen corners to NDC correctly
  - [ ] 9.4: Test matrix stack push/pop preserves/restores state

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 | Core matrix ops | Perspective Z [0,1], ortho [0,W]→NDC, stack push/pop, GLM integration |
| Visual | Manual | All scenes | Loading screen, login, character select, main game (terrain, particles, fog) |
| Regression | Manual | 2D rendering | CSprite positioning, RenderBitmap scaling, UI elements |

---

## Dev Notes

### Architecture

**Matrix Stack (DONE):** `MuRendererSDLGpu.cpp` — `glm::mat4` members for projection, modelview, and MVP. Push/pop stacks 16 deep. MVP recomputed on every change.

**GLM Convention:** `GLM_FORCE_DEPTH_ZERO_TO_ONE` only (Metal/Vulkan Z [0,1]). NO `GLM_FORCE_LEFT_HANDED` — game code uses OpenGL's right-handed convention.

**Uniform Push:** Vertex shader `basic_textured.vert.hlsl` expects `float4x4 mvp` at `cbuffer Transform : register(b1)`. Pushed as 64 bytes via `SDL_PushGPUVertexUniformData(cmdBuf, 0, ...)`. 2D path pushes ortho, 3D path pushes perspective×view from matrix stack.

### Critical Findings from Research (2026-04-01)

#### 1. NO DEPTH BUFFER (Task 3 — highest priority)
- `SDL_BeginGPURenderPass(s_cmdBuf, &colorTarget, 1, nullptr)` — the 4th param (depth target) is NULL
- `targetInfo.has_depth_stencil_target = false` in pipeline creation
- Pipelines DO enable `enable_depth_test = true` and `enable_depth_write = true`
- **Result:** depth test silently no-ops → all geometry overlaps → z-fighting everywhere
- **Fix:** Create `SDL_GPUTexture` with depth format, pass as depth target, set `has_depth_stencil_target = true`

#### 2. ALPHA DISCARD NON-FUNCTIONAL (Task 4)
- `SetAlphaTest(bool)` only sets `m_alphaTestEnabled` flag — never updates `m_fogUniform.alphaDiscardEnabled`
- `SetAlphaFunc(int, float)` is inherited as no-op — never updates `m_fogUniform.alphaThreshold`
- Fragment shader: `if (alphaDiscardEnabled && color.a <= alphaThreshold) discard;` — condition always false
- Game calls: `EnableAlphaTest()` → `SetAlphaTest(true)` + `SetAlphaFunc(GL_GREATER, 0.25f)` (ZzzOpenglUtil.cpp ~399)
- **Result:** Full quad rectangles render instead of alpha-masked particle sprites → orange boxes
- **Fix:** Propagate alpha test state to fog uniform and mark dirty

#### 3. FOG BUFFER TYPE MISMATCH (Task 5)
- Created as: `SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ` (storage buffer)
- Bound as: `SDL_BindGPUFragmentStorageBuffers(renderPass, 0, &buf, 1)`
- Shader declares: `cbuffer FogUniforms : register(b0)` → compiled MSL: `constant FogUniforms& [[buffer(0)]]`
- Shader metadata: `createShader(..., numSamplers=1, numStorageBuffers=1, numUniformBuffers=0)`
- On Metal: slot mapping depends on `numUniformBuffers` offset. With 0 uniform buffers, storage slot 0 likely maps to `[[buffer(0)]]` — but this should be verified.
- Fog factor is hardcoded to `0.0` in vertex shader — fog blend never applied even if data is correct.

#### 4. PARTICLE/BILLBOARD RENDERING PATH
- `RenderSprite()` (ZzzOpenglUtil.cpp ~806) — NOT using glPushMatrix/glTranslate
- Uses `VectorTransform(worldPos, CameraMatrix, cameraPos)` for world→camera transform
- `CameraMatrix` extracted via `GetOpenGLMatrix()` which calls `GetMatrix(GL_MODELVIEW_MATRIX, ...)`
- Builds `Vertex3D[6]` (2 triangles) and calls `RenderTriangles()`
- Blend mode set per-particle: Components==3 → `EnableAlphaBlend()` (additive), Components==4 → `EnableAlphaTest()`
- With depth buffer + alpha discard fixed, many particle issues should resolve automatically

#### 5. TERRAIN RENDERING PATH
- `RenderFace()` (ZzzLodTerrain.cpp ~1262) builds 2 triangles per quad → `RenderTriangles()`
- Uses per-vertex colors from `PrimaryTerrainLight` array (loaded from JPEG light maps)
- Color packed as `mu::PackABGR(light[0], light[1], light[2], 1.f)`
- White floor in screenshot = terrain with all-white vertex colors (lighting loaded but possibly saturated)
- With depth buffer, terrain will render at correct depth behind other objects

### Key Files

| File | Lines | What to Change |
|------|-------|---------------|
| `MuRendererSDLGpu.cpp` | ~726 | Add depth target to `SDL_BeginGPURenderPass` |
| `MuRendererSDLGpu.cpp` | ~1867 | Set `has_depth_stencil_target = true` in pipeline |
| `MuRendererSDLGpu.cpp` | ~1422 | `SetAlphaTest()` → update fog uniform alphaDiscardEnabled |
| `MuRendererSDLGpu.cpp` | new | `SetAlphaFunc()` override → update fog uniform alphaThreshold |
| `MuRendererSDLGpu.cpp` | ~1607 | Verify/fix fog shader metadata (storage vs uniform) |
| `MuRendererSDLGpu.cpp` | ~2033 | Verify fog buffer creation type |
| `basic_textured.vert.hlsl` | ~16 | fogFactor computation (currently hardcoded 0.0) |
| `ZzzOpenglUtil.cpp` | ~806 | Verify RenderSprite camera matrix extraction |
| `World/ZzzLodTerrain.cpp` | ~1262 | Verify terrain vertex colors |
| `src/shaders/compiled/*` | all | Refresh stale blobs |

### PCC Project Constraints

- **Prohibited:** No new Win32 API calls, no raw `new`/`delete`, no `wchar_t` in new serialization
- **Required:** `std::unique_ptr`, `nullptr`, `std::filesystem::path`, `[[nodiscard]]`
- **Quality Gate:** `./ctl check` (clang-format + cppcheck)
- **References:** `docs/project-context.md`, `docs/development-standards.md`

### Known Issues (pre-existing, unrelated)

- `PacketFunctions_ChatServer` / `WSclient.h` incomplete type errors in `Connection.cpp`
- These cause test target link failures but NOT the main executable

### References

- [Source: MuRendererSDLGpu.cpp — SDL_BeginGPURenderPass depth target, ~line 726]
- [Source: MuRendererSDLGpu.cpp — SetAlphaTest, ~line 1422]
- [Source: MuRendererSDLGpu.cpp — fog buffer creation, ~line 2033]
- [Source: ZzzOpenglUtil.cpp — RenderSprite billboard, ~line 806]
- [Source: ZzzOpenglUtil.cpp — EnableAlphaTest, ~line 399]
- [Source: ZzzLodTerrain.cpp — RenderFace terrain, ~line 1262]
- [Source: ZzzEffectParticle.cpp — RenderParticles, ~line 9017]
- [Source: basic_textured.frag.hlsl — alpha discard, line 20]
- [Source: GLM docs — https://github.com/g-truc/glm]

---

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
