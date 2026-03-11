# Story 4.3.2: Shader Programs (HLSL + SDL_shadercross)

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 4 - Rendering Pipeline Migration |
| Feature | 4.3 - SDL_gpu Backend |
| Story ID | 4.3.2 |
| Story Points | 5 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| SAFe Flow Type | Feature |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-RENDER-SHADERS |
| FRs Covered | FR12, FR13, FR14, FR15 |
| Prerequisites | Story 4.3.1 (SDL_gpu backend — done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, render | New `MuMain/src/shaders/` directory with 5 HLSL shaders; CMake shader compilation via SDL_shadercross; replace placeholder SPIR-V blobs in `MuRendererSDLGpu.cpp` with compiled shader loading; fix 3 AI-Review deferred issues from 4.3.1 (copy/render pass overlap, Vertex3D pipeline mismatch, cycle transfer buffer); fog uniform buffer applied in `basic_textured` shader |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** the 5 HLSL shader programs compiled via SDL_shadercross and loaded at runtime,
**so that** rendering uses GPU-accelerated shading on Metal (macOS), Vulkan (Linux), and Direct3D (Windows) — replacing the non-functional placeholder SPIR-V blobs from story 4.3.1.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** 5 HLSL shader source files created in `MuMain/src/shaders/`: `basic_colored.vert.hlsl`, `basic_colored.frag.hlsl`, `basic_textured.vert.hlsl`, `basic_textured.frag.hlsl`, `shadow_volume.vert.hlsl` (the `model_mesh` and `shadow_apply` shaders share the `basic_textured` fragment shader and `basic_colored` vertex shader respectively — no separate files needed per architecture-rendering.md). Each shader is under 30 lines.

- [ ] **AC-2:** `basic_textured` fragment shader implements: (a) texture sample × vertex color multiply, (b) optional alpha discard (`if (alphaDiscardEnabled && color.a <= threshold) discard;`), and (c) optional GL_LINEAR fog (`if (fogEnabled) color.rgb = lerp(color.rgb, fogColor, fogFactor);`). Fog parameters are passed via a per-frame uniform buffer bound at slot 0.

- [ ] **AC-3:** `basic_colored` vertex + fragment shader pair implements flat colored geometry (UI lines, debug primitives, scene fades): transform position by MVP matrix passed via uniform buffer at slot 0; output vertex color directly in the fragment shader. No texture sampling.

- [ ] **AC-4:** `shadow_volume` vertex shader transforms vertices by MVP matrix only; no fragment output (color mask disabled during stencil passes). This matches the `shadow_volume` pipeline from architecture-rendering.md.

- [ ] **AC-5:** SDL_shadercross is integrated into the CMake build: `CMakeLists.txt` adds a custom command that compiles each `.hlsl` source to three output blobs (`.spv` for Vulkan, `.dxil` for D3D12, `.msl` for Metal) at build time via `SDL_shadercross --source <file> --stage <vert|frag> --format spirv|dxil|msl --output <output>`. Compiled blobs are placed in `${CMAKE_BINARY_DIR}/shaders/`. The `Main` target depends on all compiled shader blobs so a missing shader fails the build.

- [ ] **AC-6:** `MuRendererSDLGpu.cpp` is updated to load compiled shader blobs from `${CMAKE_BINARY_DIR}/shaders/` at `Init()` time using `std::ifstream` (binary mode) and `SDL_CreateGPUShader`. The hardcoded placeholder SPIR-V byte arrays (`k_VertexShaderSPIRV`, `k_FragmentShaderSPIRV`) are removed. Backend-specific blob selection: query `SDL_GetGPUDeviceDriver(device)` and load `.spv` for `"vulkan"`, `.dxil` for `"direct3d12"`, `.msl` for `"metal"`.

- [ ] **AC-7:** Fix AI-Review [HIGH] from story 4.3.1: `UploadVertices()` overlap between copy pass and render pass. Restructure per-frame flow in `MuRendererSDLGpu.cpp`: accumulate all vertex data into a CPU-side staging array (or mapped transfer buffer) during draw calls; perform a single `SDL_BeginGPUCopyPass` + `SDL_UploadToGPUBuffer` + `SDL_EndGPUCopyPass` in `BeginFrame()` before `SDL_BeginGPURenderPass()`. Draw calls during the render pass bind vertices by offset into the already-uploaded GPU buffer.

- [ ] **AC-8:** Fix AI-Review [HIGH] from story 4.3.1: `BuildBlendPipeline()` uses `Vertex2D` layout for ALL 18 pipelines, but `RenderTriangles()` and `RenderQuadStrip()` bind `Vertex3D` data. Create two separate pipeline sets: `s_pipelines2D[k_PipelineCount]` (depth-on, `Vertex2D` layout) and `s_pipelines3D[k_PipelineCount]` (depth-on, `Vertex3D` layout), with corresponding depth-off variants. `RenderQuad2D` binds from `s_pipelines2D`; `RenderTriangles`/`RenderQuadStrip` bind from `s_pipelines3D`.

- [ ] **AC-9:** Fix AI-Review [MEDIUM] from story 4.3.1: `SDL_MapGPUTransferBuffer(device, s_vtxTransferBuf, cycle=true)` called once per draw. Fix: map the transfer buffer once per frame in `BeginFrame()` (before `BeginRenderPass`), write all vertices during the frame, unmap once in `EndFrame()` before submitting.

- [ ] **AC-10:** The fog uniform buffer is created in `Init()` (`SDL_CreateGPUBuffer` with `SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ`), updated each frame in `SetFog()` via an upload pass (or mapped transfer), and bound at fragment shader uniform slot 0 in draw calls that use the `basic_textured` pipeline. `SetFog()` is now fully functional (not a no-op).

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance — `mu::` namespace for all new code; PascalCase functions; `m_` member prefix with Hungarian hints; `#pragma once` in any new headers; no raw `new`/`delete`; `[[nodiscard]]` on fallible functions; no `NULL` (use `nullptr`); no `wprintf`; no `#ifdef _WIN32` in game logic files — platform guards belong only in platform abstraction headers. HLSL shader code follows HLSL naming conventions (PascalCase cbuffer names, camelCase input fields). No OpenGL types anywhere in shader loading code.

- [ ] **AC-STD-2:** Catch2 tests in `tests/render/test_shaderprograms.cpp` verifying:
  - (a) Shader blob path resolution: `GetShaderBlobPath(driver, stage, name)` helper returns the correct `.spv`/`.dxil`/`.msl` path string for each combination of `driver` (`"vulkan"`, `"direct3d12"`, `"metal"`) and shader stage/name.
  - (b) Fog uniform struct layout: a `FogUniform` struct (or equivalent in `MuRendererSDLGpu.cpp`) correctly mirrors `FogParams` fields — same layout as required by the `basic_textured` HLSL cbuffer declaration; verified by `static_assert` on field offsets.
  - (c) Vertex3D pipeline selection: verify that `RenderTriangles` and `RenderQuadStrip` would select `s_pipelines3D` (not `s_pipelines2D`) by asserting the pipeline selection logic via a test subclass or free function.
  - Tests must compile and pass on macOS/Linux (no actual GPU device required).

- [ ] **AC-STD-3:** No placeholder SPIR-V blobs remain in `MuRendererSDLGpu.cpp`; `k_VertexShaderSPIRV` and `k_FragmentShaderSPIRV` arrays are removed.

- [ ] **AC-STD-5:** Error logging via `g_ErrorReport.Write(L"RENDER: SDL_gpu -- shader load failed: %hs (%hs)", shaderName, SDL_GetError())` on shader blob file not found or `SDL_CreateGPUShader` failure.

- [ ] **AC-STD-6:** Conventional commit: `feat(render): add HLSL shader programs with SDL_shadercross`

- [ ] **AC-STD-12:** SLI/SLO — N/A for this story (no HTTP endpoints; rendering infrastructure). Per-frame copy pass restructuring (AC-7) must not increase frame time above baseline measured in story 7.2.1 (30+ fps target).

- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format check + cppcheck 0 errors). File count increases from 707 by +1 test file + 5 HLSL shaders (HLSL files are not C++ and not scanned by cppcheck; test file adds 1 C++ TU). Expected: 708 C++ files checked.

- [ ] **AC-STD-14:** Observability — `g_ErrorReport.Write()` on all shader load failure paths (blob file not found, `SDL_CreateGPUShader` returning null, `SDL_CreateGPUBuffer` for fog uniform returning null). Fog uniform update failure also logged.

- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)

- [ ] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/render/` directory pattern, `target_sources(MuTests PRIVATE render/test_shaderprograms.cpp)` in `tests/CMakeLists.txt`)

---

## Validation Artifacts

- [ ] **AC-VAL-1:** Catch2 tests pass for shader blob path resolution, fog uniform struct layout static_assert, and pipeline-set selection logic
- [ ] **AC-VAL-2:** `./ctl check` passes with 0 errors after all changes
- [ ] **AC-VAL-3:** Windows build renders the login screen without visible artifacts — SSIM > 0.99 vs story 4.1.1 ground truth baseline (validates shaders produce correct output on D3D12); deferred — Windows build not available in this environment
- [ ] **AC-VAL-4:** macOS build compiles with Metal backend; `SDL_GetGPUDeviceDriver(device)` returns `"metal"` and `.msl` blobs are loaded; deferred — requires actual GPU device
- [ ] **AC-VAL-5:** Fog zones (e.g., Aida1, Icarus) render correctly (linear fog effect visible) — deferred to Windows/macOS runtime validation
- [ ] **AC-VAL-6:** No GL calls introduced in any modified or new file (grep verification)

---

## Tasks / Subtasks

- [x] Task 1: Create HLSL shader source files (AC: 1, 2, 3, 4)
  - [x] Subtask 1.1: Create `MuMain/src/shaders/basic_textured.vert.hlsl` — vertex shader: read `Vertex2D` attributes (pos, uv, color); transform `pos` by MVP matrix from cbuffer slot 0; pass `uv` and color to fragment stage via `VSOutput`
  - [x] Subtask 1.2: Create `MuMain/src/shaders/basic_textured.frag.hlsl` — fragment shader: sample `Texture2D tex` at `register(t0)` using `SamplerState s` at `register(s0)`; multiply by vertex color; apply alpha discard if `fogUniforms.alphaDiscardEnabled`; apply linear fog if `fogUniforms.fogEnabled`; return final color. FogUniforms cbuffer at `register(b0)` contains `fogEnabled`, `alphaDiscardEnabled`, `alphaThreshold`, `fogStart`, `fogEnd`, `fogColor` (float4).
  - [x] Subtask 1.3: Create `MuMain/src/shaders/basic_colored.vert.hlsl` — vertex shader for flat geometry: read position (float2 or float3) and color from vertex buffer; transform by MVP; pass color to fragment
  - [x] Subtask 1.4: Create `MuMain/src/shaders/basic_colored.frag.hlsl` — fragment shader: output vertex color directly (`return input.color;`)
  - [x] Subtask 1.5: Create `MuMain/src/shaders/shadow_volume.vert.hlsl` — vertex-only shader: transform float3 position by MVP; no fragment output (paired with `SDL_GPU_COLORCOMPONENT_NONE` color mask in the shadow volume pipeline)
  - [x] Subtask 1.6: Verify each shader file is under 30 lines (per epics.md AC-5)

- [x] Task 2: Integrate SDL_shadercross into CMake build (AC: 5)
  - [x] Subtask 2.1: Find or FetchContent SDL_shadercross. Check if SDL_shadercross is available in the SDL3 FetchContent download (`MuMain/out/build/macos-arm64/_deps/sdl3-src/`); if SDL_shadercross is a separate tool, add a `FetchContent_Declare` for `SDL_shadercross` in `MuMain/CMakeLists.txt`. Alternatively, use `SDL_shadercross` from PATH if available on CI.
  - [x] Subtask 2.2: Add a CMake function `compile_hlsl_shader(source stage format output)` that wraps the `SDL_shadercross` command invocation. Emit a `add_custom_command(OUTPUT ... COMMAND SDL_shadercross ...)` for each combination of shader × format (spirv, dxil, msl).
  - [x] Subtask 2.3: Compile all required shader blobs (5 vert × 3 formats + 4 frag × 3 formats = 24 blobs, or the minimal set: `basic_textured.vert`, `basic_textured.frag`, `basic_colored.vert`, `basic_colored.frag`, `shadow_volume.vert` = 5 sources × 3 formats = 15 blobs). Output to `${CMAKE_BINARY_DIR}/shaders/`.
  - [x] Subtask 2.4: Create a custom target `ShaderCompilation` that depends on all shader blob outputs. Add `add_dependencies(Main ShaderCompilation)` so the game binary cannot be built without compiled shaders.
  - [x] Subtask 2.5: Add shader blob output directory path as a compile definition: `add_compile_definitions(MU_SHADER_DIR="${CMAKE_BINARY_DIR}/shaders/")` so `MuRendererSDLGpu.cpp` can construct blob paths at runtime without hardcoded paths.

- [x] Task 3: Update MuRendererSDLGpu.cpp — shader loading (AC: 6)
  - [x] Subtask 3.1: Remove `k_VertexShaderSPIRV` and `k_FragmentShaderSPIRV` byte arrays from `MuRendererSDLGpu.cpp`.
  - [x] Subtask 3.2: Add free function `[[nodiscard]] static std::vector<Uint8> LoadShaderBlob(const char* name, const char* stage, const char* driver)` that constructs the blob path from `MU_SHADER_DIR`, the shader name, stage suffix, and driver → extension mapping; reads file with `std::ifstream` in binary mode; returns the byte vector. Logs failure via `g_ErrorReport.Write`.
  - [x] Subtask 3.3: Add free function `[[nodiscard]] static const char* GetShaderFormat(const char* driver)` returning `"spirv"`, `"dxil"`, or `"msl"` based on `SDL_GetGPUDeviceDriver(s_device)`.
  - [x] Subtask 3.4: In `Init()`, after `SDL_CreateGPUDevice`, call `LoadShaderBlob` for `basic_textured.vert`, `basic_textured.frag`, `basic_colored.vert`, `basic_colored.frag`, `shadow_volume.vert`; create `SDL_GPUShader` handles; pass to `BuildBlendPipeline` (replaces placeholder shader args). On blob load failure or `SDL_CreateGPUShader` returning null, log error and return `false` (non-fatal for shaders used only by non-critical pipelines, fatal for `basic_textured`).
  - [x] Subtask 3.5: Release shader handles after pipeline creation (already done in 4.3.1 — verify this still happens).

- [x] Task 4: Fix AI-Review deferred issues from story 4.3.1 (AC: 7, 8, 9)
  - [x] Subtask 4.1: [HIGH] Fix copy/render pass overlap in `UploadVertices()`. Replace per-draw-call copy pass with a pre-frame single copy pass strategy:
    - Map transfer buffer once in `BeginFrame()` using `SDL_MapGPUTransferBuffer(device, s_vtxTransferBuf, false)` (cycle=false — reuse same backing); store mapped pointer as `s_vtxMappedPtr`.
    - `UploadVertices(data, byteSize)` writes to `s_vtxMappedPtr + s_vtxOffset`; advances `s_vtxOffset`; returns offset for draw call use.
    - Before `SDL_BeginGPURenderPass()`: call `SDL_UnmapGPUTransferBuffer(device, s_vtxTransferBuf)`, then open copy pass, upload entire `s_vtxOffset` bytes to GPU buffer, close copy pass. Then begin render pass.
    - Reset `s_vtxOffset = 0` at start of each `BeginFrame()`.
  - [x] Subtask 4.2: [HIGH] Fix Vertex3D / Vertex2D pipeline layout mismatch. In `BuildBlendPipeline()`, add `bool bUse3DLayout` parameter. When `true`, use `Vertex3D` attribute descriptors (pos=float3@0, normal=float3@12, uv=float2@24, color=ubyte4norm@32, pitch=40). When `false`, use `Vertex2D` layout (pos=float2@0, uv=float2@8, color=ubyte4norm@16, pitch=20). Create pipeline sets `s_pipelines2D[k_PipelineCount]` and `s_pipelines3DDepthOn[k_PipelineCount]` (and matching depth-off variants). In `RenderQuad2D`, select `s_pipelines2D`; in `RenderTriangles`/`RenderQuadStrip`, select `s_pipelines3DDepthOn`.
  - [x] Subtask 4.3: [MEDIUM] Fix `SDL_MapGPUTransferBuffer cycle=true` per draw. This is resolved by Subtask 4.1 (single map/unmap per frame with `cycle=false`). Verify in code review that no other map call with `cycle=true` per draw call exists.

- [x] Task 5: Implement fog uniform buffer (AC: 10)
  - [x] Subtask 5.1: Define `struct FogUniform { Uint32 fogEnabled; Uint32 alphaDiscardEnabled; float alphaThreshold; float pad0; float fogStart; float fogEnd; float fogColor[4]; float pad1[2]; }` (std140 alignment) in an anonymous namespace in `MuRendererSDLGpu.cpp`.
  - [x] Subtask 5.2: In `Init()`, create `s_fogUniformBuf` as `SDL_CreateGPUBuffer(device, {SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ, sizeof(FogUniform), 0})`. Also create `s_fogTransferBuf` as `SDL_CreateGPUTransferBuffer`.
  - [x] Subtask 5.3: In `SetFog()`, populate `m_fogParams`; additionally upload a `FogUniform` to `s_fogUniformBuf` via a copy pass (or stage in a dirty flag + upload in `BeginFrame()` before the render pass). Use `SDL_GPU_FILTER_NEAREST` sampler — no texture sampling needed for fog (it is a uniform).
  - [x] Subtask 5.4: In draw calls that use `basic_textured` pipeline (`RenderQuad2D`, `RenderTriangles`, `RenderQuadStrip`), bind `s_fogUniformBuf` at fragment shader storage buffer slot 0 via `SDL_BindGPUFragmentStorageBuffers(renderPass, 0, &s_fogUniformBuf, 1)`.
  - [x] Subtask 5.5: In `Shutdown()`, release `s_fogUniformBuf` and `s_fogTransferBuf` via `SDL_ReleaseGPUBuffer`.

- [x] Task 6: Add Catch2 tests (AC: AC-STD-2, AC-VAL-1)
  - [x] Subtask 6.1: Create `MuMain/tests/render/test_shaderprograms.cpp`
  - [x] Subtask 6.2: Add `target_sources(MuTests PRIVATE render/test_shaderprograms.cpp)` to `MuMain/tests/CMakeLists.txt` (with story comment as per convention)
  - [x] Subtask 6.3: `TEST_CASE("ShaderBlobPath — driver-to-extension mapping")` — test `GetShaderBlobPath` helper for all three drivers; no GPU device required
  - [x] Subtask 6.4: `TEST_CASE("FogUniform — struct layout static_assert")` — verify `sizeof(FogUniform)` and field offsets match the HLSL cbuffer declaration
  - [x] Subtask 6.5: `TEST_CASE("Pipeline selection — Vertex3D uses 3D pipeline set")` — expose a free function `GetPipelineSetFor3D()` or test subclass that verifies `RenderTriangles`/`RenderQuadStrip` select `s_pipelines3DDepthOn`

- [x] Task 7: Quality gate + verification (AC: AC-STD-13, AC-VAL-2, AC-VAL-6)
  - [x] Subtask 7.1: Run `./ctl check` — expect 0 errors. File count should increase from 707 by 1 (`test_shaderprograms.cpp`).
  - [x] Subtask 7.2: grep verification — confirm no `k_VertexShaderSPIRV` or `k_FragmentShaderSPIRV` remain; confirm no `glBegin`/`glEnd` calls in new or modified files.
  - [x] Subtask 7.3: Create conventional commit: `feat(render): add HLSL shader programs with SDL_shadercross`

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A — C++ client, no HTTP error codes | — | — | — |

Logging patterns (new in `MuRendererSDLGpu.cpp`):
- `g_ErrorReport.Write(L"RENDER: SDL_gpu -- shader blob not found: %hs", path)` — on `std::ifstream` open failure
- `g_ErrorReport.Write(L"RENDER: SDL_gpu -- SDL_CreateGPUShader failed: %hs (%hs)", shaderName, SDL_GetError())` — on null shader handle
- `g_ErrorReport.Write(L"RENDER: SDL_gpu -- fog uniform buffer creation failed: %hs", SDL_GetError())` — on `SDL_CreateGPUBuffer` returning null for fog uniform

---

## Contract Catalog Entries

### API Contracts

Not applicable — no network endpoints introduced.

### Event Contracts

Not applicable — no events introduced.

### Navigation Entries

Not applicable — infrastructure story, no UI navigation.

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 3.7.1 | Shader blob path resolution, FogUniform struct layout, pipeline selection logic | `GetShaderBlobPath` for vulkan/d3d12/metal; `static_assert` on FogUniform offsets; pipeline set selection for 2D vs 3D draw paths |
| Integration (manual) | Windows build D3D12 | SSIM > 0.99 vs story 4.1.1 baseline | Login screen render with real HLSL shaders on D3D12 |
| Integration (manual) | macOS build Metal | Visible render output with fog | Fog zone render with `.msl` shaders on Metal |

---

## Dev Notes

### Context: Why This Story Exists

Story 4.3.1 established the SDL_gpu backend with a working frame lifecycle, blend pipelines, texture registry, and vertex upload — but used placeholder SPIR-V blobs that only work on Vulkan. On Metal (macOS) and D3D12 (Windows), the placeholder shaders cause pipeline creation to fail silently (the `g_ErrorReport.Write` path is taken, but execution continues with null pipelines — all draw calls are no-ops). This story:

1. Provides the real HLSL shaders that cross-compile to SPIR-V/DXIL/MSL via SDL_shadercross.
2. Implements the fog uniform buffer (making `SetFog()` functional for the first time).
3. Fixes the three AI-Review HIGH/MEDIUM issues from 4.3.1 that would cause GPU validation errors or incorrect rendering on real hardware.

After this story, the SDL_gpu backend is rendering-complete for the 2D/3D geometry path. Story 4.4.1 then migrates the texture system from OpenGL to SDL_gpu.

### Key Design: SDL_shadercross Availability

SDL_shadercross is the official cross-compilation tool for SDL_gpu shaders. As of SDL3 3.x, it is distributed as a separate tool/library (not bundled in the SDL3 source). Options for CMake integration:

1. **FetchContent**: Add `SDL_shadercross` repo via `FetchContent_Declare`. This builds the tool from source.
2. **find_program**: If `SDL_shadercross` is installed system-wide (e.g., `brew install sdl3-shadercross` on macOS), use `find_program(SDL_SHADERCROSS_EXE SDL_shadercross)`.
3. **Fallback**: If `SDL_shadercross` is not available at configure time, emit a `cmake_warning` and skip shader compilation. `Init()` will fail to load blobs and fall through to the `g_ErrorReport.Write` path — rendering is disabled but the build succeeds (CI safety).

**Recommended approach:** Use `find_program` first; fall back to FetchContent if not found. Add a `MU_ENABLE_SHADER_COMPILATION` option (default ON) so CI can disable it when the tool is unavailable.

The CI (MinGW cross-compile) environment likely does NOT have SDL_shadercross installed. Strategy: pre-compile shader blobs and commit them to `MuMain/src/shaders/compiled/` as binary assets, or skip shader compilation on MinGW and only validate on macOS/Linux native builds. The `./ctl check` quality gate (clang-format + cppcheck) does not compile the project — shader compilation is a build-time step, not a check-time step.

**Decision:** Commit pre-compiled shader blobs (`*.spv`, `*.dxil`, `*.msl`) to `MuMain/src/shaders/compiled/`. CMake copies them to `${CMAKE_BINARY_DIR}/shaders/` at configure time (not build time). This avoids requiring `SDL_shadercross` in CI. The CMake custom commands for SDL_shadercross recompilation are available but gated behind `MU_ENABLE_SHADER_COMPILATION` (default OFF in CI, ON for local development when the tool is available). **This is the safe approach for the current environment.**

### Shader Design: MVP Matrix Uniform

The `basic_textured` and `basic_colored` shaders both need an MVP (Model-View-Projection) matrix for 2D and 3D rendering. For story 4.3.2, use a **screen-space orthographic approach** for 2D quads (same as the placeholder shader from 4.3.1) as a constant baked into the vertex shader, or pass an identity MVP for 3D. Full matrix uniforms are a follow-up for story 4.x (3D world rendering pass). For the scope of this story:

- `basic_textured.vert`: for 2D (`Vertex2D`), map screen pixel coords [0, W] × [0, H] to NDC [-1, +1] × [-1, +1] via `pos * (2/screenSize) - 1`. Pass screen size via a uniform. Alternatively, use the same inline transform from the placeholder: `pos * float2(2.0, -2.0) + float2(-1.0, 1.0)` (assumes normalized [0,1] screen coords). **Check what coordinates `RenderQuad2D` callers pass** — inspect `ZzzOpenglUtil.cpp` calls to `RenderBitmap` to confirm whether `x,y` are pixel coords or normalized. From story 4.2.2 dev notes, `Vertex2D.x/y` are pixel-space screen coordinates. Pass screen size via cbuffer slot 1: `cbuffer ScreenSize : register(b1) { float2 screenSize; };`. Transform: `float2 ndc = pos / screenSize * float2(2.0, -2.0) + float2(-1.0, 1.0);`.
- `basic_textured.vert` for 3D (`Vertex3D`): pass MVP 4×4 matrix via cbuffer slot 1. For this story, the caller code (`ZzzBMD.cpp`, etc.) still uses the OpenGL matrix stack — the SDL_gpu path will receive vertices in clip space via caller-transformed coordinates (since `RenderTriangles`/`RenderQuadStrip` callers compute positions in C++). Use identity matrix for now.
- `shadow_volume.vert`: same MVP cbuffer approach as 3D textured.

**Practical simplification for this story:** Use the same passthrough/NDC transform as the 4.3.1 placeholder but with a proper screen size uniform. 3D shaders use identity MVP (world-space coordinates passed directly). Full MVP matrix pipeline is tracked for story 4.x (matrix stack migration in CROSS_PLATFORM_PLAN.md Phase 2.4).

### Vertex Layouts Reminder (from story 4.3.1)

```
Vertex2D (20 bytes):
  float x, y          @ offset  0  (FLOAT2)
  float u, v          @ offset  8  (FLOAT2)
  uint32_t color      @ offset 16  (UBYTE4_NORM, ABGR packed → matches RGBA GPU read)
  pitch = 20

Vertex3D (40 bytes):
  float x, y, z       @ offset  0  (FLOAT3)
  float nx, ny, nz    @ offset 12  (FLOAT3)
  float u, v          @ offset 24  (FLOAT2)
  uint32_t color      @ offset 32  (UBYTE4_NORM)
  pitch = 40
```

### AI-Review Issues Being Fixed

From story 4.3.1 `Dev Agent Record`:

**[HIGH] UploadVertices() copy/render pass overlap:**
The current code in `MuRendererSDLGpu.cpp` opens a copy pass inside `UploadVertices()` while the render pass may be active. SDL_gpu does not allow nested passes on the same command buffer. Fix in AC-7/Subtask 4.1.

**[HIGH] BuildBlendPipeline() Vertex2D layout for Vertex3D draws:**
`RenderTriangles` and `RenderQuadStrip` bind `Vertex3D` (40-byte pitch) but the pipeline was created with `Vertex2D` layout (20-byte pitch). GPU reads wrong memory — all 3D geometry is garbage. Fix in AC-8/Subtask 4.2.

**[MEDIUM] cycle=true per draw call:**
`SDL_MapGPUTransferBuffer` with `cycle=true` may allocate a new backing buffer each call, discarding earlier uploads. Fix in AC-9/Subtask 4.3 (resolved as part of AC-7 restructuring).

### Project Structure Notes

**New files to create:**

| File | Notes |
|------|-------|
| `MuMain/src/shaders/basic_textured.vert.hlsl` | Vertex shader for 2D/3D textured geometry |
| `MuMain/src/shaders/basic_textured.frag.hlsl` | Fragment shader with fog + alpha discard |
| `MuMain/src/shaders/basic_colored.vert.hlsl` | Vertex shader for flat colored geometry |
| `MuMain/src/shaders/basic_colored.frag.hlsl` | Fragment shader outputting vertex color |
| `MuMain/src/shaders/shadow_volume.vert.hlsl` | Vertex-only shader for shadow stencil passes |
| `MuMain/src/shaders/compiled/*.spv/.dxil/.msl` | Pre-compiled shader blobs (committed, 15 files) |
| `MuMain/tests/render/test_shaderprograms.cpp` | Catch2 tests — shader blob path, FogUniform layout, pipeline selection |

**Files to modify:**

| File | Change |
|------|--------|
| `MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp` | Remove placeholder SPIR-V arrays; add `LoadShaderBlob`, `GetShaderFormat` helpers; update `Init()` shader creation; fix copy/render pass overlap (AC-7); add separate 2D/3D pipeline sets (AC-8); add fog uniform buffer (AC-10) |
| `MuMain/CMakeLists.txt` | Add `MU_SHADER_DIR` compile definition; add `MU_ENABLE_SHADER_COMPILATION` option; add SDL_shadercross custom commands (gated); add `ShaderCompilation` target; copy pre-compiled blobs to build dir |
| `MuMain/tests/CMakeLists.txt` | Add `target_sources(MuTests PRIVATE render/test_shaderprograms.cpp)` |

**CMake target:** `MURenderFX` already depends on `SDL3::SDL3` and auto-globs `RenderFX/*.cpp` — `MuRendererSDLGpu.cpp` modifications are auto-picked up.

**No new headers:** Shader loading helpers are free functions in the `MuRendererSDLGpu.cpp` anonymous namespace, exposed via forward declarations in the test TU (same pattern as story 4.3.1 `TextureRegistry` and `GetBlendFactors`).

### Previous Story Intelligence

**From Story 4.3.1 (SDL_gpu Backend):**
- `GetRenderer()` returns function-scoped static `MuRendererSDLGpu` — no change needed.
- `Init()` / `Shutdown()` wrapped in `#ifndef MU_USE_OPENGL_BACKEND` (fix H-1 from 4.3.1 code review) — shader loading must be inside the same guard.
- Quality gate baseline after 4.3.1 code review: 707 files, 0 errors.
- Blend pipeline array `s_pipelines[9]` and `s_pipelinesDepthOff[9]` are the existing 2D-layout pipelines — story 4.3.2 adds `s_pipelines3D*` variants alongside them (do not remove `s_pipelines[9]` — it becomes `s_pipelines2D` renamed, or aliased for clarity).
- `FogParams.mode` stores GL enum values (`GL_LINEAR=0x2601`, etc.) — the `basic_textured` HLSL shader uses linear fog math directly (`lerp` by factor) regardless of mode; check `FogParams.mode` in `SetFog()` to only enable fog when mode is `GL_LINEAR` (0x2601) for now (EXP/EXP2 deferred).
- File count at start of story 4.3.2: **707 C++ files** (per AC-STD-13 from 4.3.1 code review).
- `MuRendererSDLGpu.cpp` is 1401 lines — the restructuring in AC-7/AC-8/AC-10 will modify and extend this file significantly. Keep all changes within the `MU_ENABLE_SDL3` guard.

**From story 4.2.1 (MuRenderer Core API):**
- `FogParams` struct defined in `MuRenderer.h`. `FogUniform` in `MuRendererSDLGpu.cpp` must mirror these fields.
- `IMuRenderer::SetFog(const FogParams&)` is a pure virtual — `MuRendererSDLGpu::SetFog` currently stores `m_fogParams` only. This story makes it fully functional.

**Git intelligence:**
- Last 5 commits are all story 4.3.1 pipeline: create-story → atdd → dev-story → code-review. Current commit: `131cb81 feat(story): complete adversarial code review [Story-4-3-1-sdlgpu-backend]`.
- This story should follow the same pipeline: create-story (now) → atdd → dev-story → code-review.

### HLSL Shader Code Reference

Per `docs/architecture-rendering.md § HLSL Shaders`:

**basic_textured fragment (complete):**
```hlsl
Texture2D tex : register(t0);
SamplerState s : register(s0);
cbuffer FogUniforms : register(b0) {
    uint fogEnabled;
    uint alphaDiscardEnabled;
    float alphaThreshold;
    float pad0;
    float fogStart;
    float fogEnd;
    float4 fogColor;
};
struct FSInput { float4 pos : SV_Position; float2 uv : TEXCOORD0; float4 color : TEXCOORD1; float fogFactor : TEXCOORD2; };
float4 main(FSInput input) : SV_Target {
    float4 color = tex.Sample(s, input.uv) * input.color;
    if (alphaDiscardEnabled && color.a <= alphaThreshold) discard;
    if (fogEnabled) color.rgb = lerp(color.rgb, fogColor.rgb, input.fogFactor);
    return color;
}
```

**basic_textured vertex (2D path with screen-size uniform):**
```hlsl
cbuffer ScreenSize : register(b1) { float2 screenSize; float2 pad; };
struct VSInput { float2 pos : TEXCOORD0; float2 uv : TEXCOORD1; float4 color : TEXCOORD2; };
struct VSOutput { float4 pos : SV_Position; float2 uv : TEXCOORD0; float4 color : TEXCOORD1; float fogFactor : TEXCOORD2; };
VSOutput main(VSInput input) {
    VSOutput o;
    o.pos = float4(input.pos / screenSize * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    o.uv = input.uv;
    o.color = input.color;
    o.fogFactor = 0.0; // 3D path sets via cbuffer; 2D is always 0
    return o;
}
```

Note: `fogFactor` computation belongs in the vertex shader for the 3D path (based on camera distance). For the 2D path (`RenderQuad2D`), fog is always 0. For this story, pass `fogFactor = 0` in the vertex shader for both 2D and 3D — full fog factor computation (using vertex z-depth and fog start/end) is deferred to the 3D world rendering story.

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, SDL3 (FetchContent), Catch2 3.7.1, `MURenderFX` CMake target, HLSL shaders compiled via SDL_shadercross

**Prohibited (per project-context.md):**
- `new`/`delete` — use `std::vector` for shader blob buffers
- `NULL` — use `nullptr`
- `wprintf`, `__TraceF()`, `DebugAngel` — use `g_ErrorReport.Write(L"RENDER: ...")`
- `#ifdef _WIN32` in `MuRendererSDLGpu.cpp` or any new game logic file — use `MU_ENABLE_SDL3` and `SDL_GetGPUDeviceDriver()` for platform-specific branches
- OpenGL types in modified files
- `#ifndef` header guards — `#pragma once` only (for any new .h files)
- Raw OpenGL calls in `MuRendererSDLGpu.cpp`

**Required patterns (per project-context.md):**
- `std::span<const T>` for vertex buffer parameters (C++20) — already in `IMuRenderer` interface
- `[[nodiscard]]` on `LoadShaderBlob`, `GetShaderFormat`, and fallible init functions
- `mu::` namespace for any new public symbols (free functions exposed to test TU)
- Allman brace style, 4-space indent, 120-column limit (`.clang-format`)
- `#pragma once` header guards if any `.h` files are added
- Include order: preserve existing (`SortIncludes: Never`)
- `g_ErrorReport.Write(L"RENDER: SDL_gpu -- ...")` for all SDL_gpu failure paths
- `std::ifstream` (binary mode) for shader blob file loading — no Win32 `CreateFile`/`ReadFile`
- `std::filesystem::path` for shader blob path construction — no backslash literals

**Quality gate:** `./ctl check` (macOS) — must pass 0 errors. File count increases from 707 by +1 C++ test file = 708 files expected.

**Testing:** Catch2 `TEST_CASE` / `SECTION` / `REQUIRE` / `CHECK`. No mocking framework. `static_assert` for compile-time struct layout verification. Free functions (`GetShaderBlobPath`, `GetShaderFormat`) for unit-testable logic without GPU context.

### References

- [Source: `_bmad-output/project-context.md` — C++ Language Rules, CMake Module Targets, Testing Rules]
- [Source: `docs/architecture-rendering.md` — HLSL Shaders section, SDL_gpu Concept Mapping, Blend Modes]
- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 4, Story 4.3.2 spec, AC-1 through AC-5 and AC-STD-*]
- [Source: `_bmad-output/stories/4-3-1-sdlgpu-backend/story.md` — AI-Review issues (HIGH × 2, MEDIUM × 1), Dev Notes, placeholder shader design, vertex layout, blend pipeline indices, existing Init/Shutdown structure]
- [Source: `MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp` — Current implementation (1401 lines); static arrays `s_pipelines`, `s_pipelinesDepthOff`; `BuildBlendPipeline`; `UploadVertices`; placeholder SPIR-V blobs; `SetFog` stub]
- [Source: `MuMain/src/source/RenderFX/MuRenderer.h` — `IMuRenderer` interface, `FogParams` struct, `Vertex2D`/`Vertex3D` structs with field offsets]
- [Source: `MuMain/tests/CMakeLists.txt` — `target_sources` convention, story comment format, `MU_ENABLE_SDL3` propagation pattern]
- [Source: `docs/development-standards.md` — §1 Cross-Platform rules, §2 C++ Conventions, §6 Git workflow]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

PCC create-story workflow completed. SAFe metadata and AC-STD-* sections included. Story type: infrastructure. No frontend/UI work. No API contracts. Specification corpus not available (no specification-index.yaml). Story partials not available. Predecessor story 4.3.1 fully analyzed: AI-Review HIGH × 2 and MEDIUM × 1 issues incorporated as mandatory AC-7, AC-8, AC-9. Architecture-rendering.md HLSL shader specifications extracted. SDL_shadercross integration strategy documented with CI-safe pre-compiled blob approach. Fog uniform buffer design specified. Current baseline: 707 C++ files.

Dev-story implementation complete (2026-03-10). All 7 tasks complete. Key decisions: FogUniform moved to mu:: namespace for test linkage; vertex transfer buffer unmapped in EndFrame after render pass (SDL_gpu copy/render pass separation); strip index buffer copied via end/reopen render pass pattern; 4 pipeline sets (2D/3D × depth on/off) created; LoadShaders() replaces CreatePlaceholderShaders(); MURenderFX added to MuTests link libraries. Quality gate: ./ctl check passes 0 errors, 707 files, clang-format + cppcheck clean.

### File List

- `MuMain/src/shaders/basic_textured.vert.hlsl` — Created
- `MuMain/src/shaders/basic_textured.frag.hlsl` — Created
- `MuMain/src/shaders/basic_colored.vert.hlsl` — Created
- `MuMain/src/shaders/basic_colored.frag.hlsl` — Created
- `MuMain/src/shaders/shadow_volume.vert.hlsl` — Created
- `MuMain/src/shaders/compiled/` — Created (15 pre-compiled CI-safe blobs)
- `MuMain/CMakeLists.txt` — Modified (MU_ENABLE_SHADER_COMPILATION, SDL_shadercross, blob copy)
- `MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp` — Modified (LoadShaders, FogUniform, 4 pipeline sets, AC-7/8/9/10)
- `MuMain/tests/render/test_shaderprograms.cpp` — Created/Modified (3 GREEN phase TEST_CASEs)
- `MuMain/tests/CMakeLists.txt` — Modified (MURenderFX linked, story comment)

