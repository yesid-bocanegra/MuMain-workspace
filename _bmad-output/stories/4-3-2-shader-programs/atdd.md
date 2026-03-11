# ATDD Checklist — Story 4.3.2: Shader Programs (HLSL + SDL_shadercross)

**Story ID:** 4-3-2-shader-programs
**Story Type:** infrastructure
**Generated:** 2026-03-10
**Primary Test Level:** Unit (Catch2 3.7.1)
**Test File:** `MuMain/tests/render/test_shaderprograms.cpp`

---

## PCC Compliance Summary

| Check | Status | Detail |
|-------|--------|--------|
| Prohibited libraries | NONE | No `new`/`delete`, `NULL`, `wprintf`, `#ifdef _WIN32`, GL calls in test TU |
| Required patterns | OK | `TEST_CASE`/`SECTION`/`REQUIRE`/`CHECK`, `static_assert` for layout, no mocking framework |
| Test profiles | N/A | Infrastructure story — no Spring/testcontainers profiles |
| Coverage target | N/A | Incremental; 0 threshold, growing |
| E2E tool | N/A | Infrastructure story — no frontend E2E required |
| Bruno API collection | N/A | No HTTP endpoints |
| Framework | Catch2 3.7.1 | `MuTests` target, `tests/render/` directory |

---

## AC-to-Test Mapping

| AC | Description | Test Method | Test File | Status |
|----|-------------|-------------|-----------|--------|
| AC-1 | 5 HLSL shader files created in `src/shaders/` | Build-time verification (not unit-testable) | N/A — build artifact | Build-time |
| AC-2 | `basic_textured` fragment shader: texture×color, alpha discard, fog | Build-time / manual render validation | N/A | Build-time |
| AC-3 | `basic_colored` vert+frag: flat geometry, MVP, vertex color output | Build-time / manual render validation | N/A | Build-time |
| AC-4 | `shadow_volume` vertex shader: MVP only, no fragment output | Build-time / manual render validation | N/A | Build-time |
| AC-5 | SDL_shadercross CMake integration, blob output, `ShaderCompilation` target | Build-time / CMake configure verification | N/A | Build-time |
| AC-6 | `MuRendererSDLGpu.cpp` loads blobs from `MU_SHADER_DIR` via `std::ifstream`, selects by driver | `TEST_CASE("AC-6: ShaderBlobPath — driver-to-extension mapping")` | `test_shaderprograms.cpp` | PENDING |
| AC-7 | Fix copy/render pass overlap — single pre-frame copy pass | Code review + manual GPU validation | N/A | Code review |
| AC-8 | Fix Vertex3D/2D pipeline mismatch — separate `s_pipelines2D`/`s_pipelines3D` | `TEST_CASE("AC-8: Pipeline selection — Vertex3D uses 3D pipeline set")` | `test_shaderprograms.cpp` | PENDING |
| AC-9 | Fix `cycle=true` per-draw map — single map/unmap per frame | Code review (resolved by AC-7 restructuring) | N/A | Code review |
| AC-10 | Fog uniform buffer: created in `Init()`, updated in `SetFog()`, bound in draw calls | `TEST_CASE("AC-10: FogUniform — struct layout static_assert")` | `test_shaderprograms.cpp` | PENDING |
| AC-STD-1 | Code standards: `mu::` namespace, naming, no raw `new`/`delete`, etc. | `./ctl check` clang-format + cppcheck | Quality gate | Quality gate |
| AC-STD-2 | Catch2 tests: blob path resolution, FogUniform layout, pipeline selection | All three `TEST_CASE` blocks | `test_shaderprograms.cpp` | PENDING |
| AC-STD-3 | No placeholder SPIR-V arrays remain | `grep` verification | N/A | Grep check |
| AC-STD-5 | Error logging via `g_ErrorReport.Write` on all failure paths | Code review | N/A | Code review |
| AC-STD-6 | Conventional commit: `feat(render): add HLSL shader programs with SDL_shadercross` | Git history | N/A | Commit |
| AC-STD-12 | No frame time regression above 30 fps baseline | Manual performance check | N/A | Manual |
| AC-STD-13 | `./ctl check` passes, file count 707 → 708 C++ files | `./ctl check` | Quality gate | Quality gate |
| AC-STD-14 | Observability: `g_ErrorReport.Write` on all shader/fog buffer failure paths | Code review | N/A | Code review |
| AC-STD-15 | Git safety: no incomplete rebase, no force push | Git history | N/A | Commit |
| AC-STD-16 | Correct test infra: Catch2 3.7.1, `MuTests` target, `tests/render/` | `tests/CMakeLists.txt` verification | N/A | Build |
| AC-VAL-1 | Catch2 tests pass: blob path, FogUniform layout, pipeline selection | All three `TEST_CASE` blocks | `test_shaderprograms.cpp` | PENDING |
| AC-VAL-2 | `./ctl check` passes 0 errors | `./ctl check` | Quality gate | Quality gate |
| AC-VAL-3 | Windows D3D12 SSIM > 0.99 vs baseline | Deferred — no Windows env | N/A | Deferred |
| AC-VAL-4 | macOS Metal: `.msl` blobs loaded | Deferred — requires GPU device | N/A | Deferred |
| AC-VAL-5 | Fog zones render correctly | Deferred — Windows/macOS runtime | N/A | Deferred |
| AC-VAL-6 | No GL calls in modified/new files | `grep` verification | N/A | Grep check |

---

## Implementation Checklist

### Task 1 — HLSL Shader Source Files (AC-1, AC-2, AC-3, AC-4)

- [ ] Create `MuMain/src/shaders/basic_textured.vert.hlsl` — Vertex2D input, screen-size cbuffer slot b1, NDC transform, fogFactor=0 output
- [ ] Create `MuMain/src/shaders/basic_textured.frag.hlsl` — texture×color multiply, alpha discard, linear fog with FogUniforms cbuffer at b0
- [ ] Create `MuMain/src/shaders/basic_colored.vert.hlsl` — position + color input, MVP cbuffer, flat color output
- [ ] Create `MuMain/src/shaders/basic_colored.frag.hlsl` — return vertex color directly
- [ ] Create `MuMain/src/shaders/shadow_volume.vert.hlsl` — MVP transform only, no fragment output
- [ ] Verify each shader file is under 30 lines

### Task 2 — SDL_shadercross CMake Integration (AC-5)

- [ ] Add `MU_ENABLE_SHADER_COMPILATION` option (default OFF for CI safety) to `MuMain/CMakeLists.txt`
- [ ] Add `find_program(SDL_SHADERCROSS_EXE SDL_shadercross)` with FetchContent fallback when `MU_ENABLE_SHADER_COMPILATION=ON`
- [ ] Add `compile_hlsl_shader(source stage format output)` CMake function wrapping `add_custom_command`
- [ ] Compile 5 shaders × 3 formats = 15 blobs (`.spv`, `.dxil`, `.msl`) to `${CMAKE_BINARY_DIR}/shaders/`
- [ ] Create `ShaderCompilation` custom target depending on all 15 blob outputs
- [ ] Add `add_dependencies(Main ShaderCompilation)` so Main target requires compiled shaders
- [ ] Add `add_compile_definitions(MU_SHADER_DIR="${CMAKE_BINARY_DIR}/shaders/")` so runtime path construction works
- [ ] Commit pre-compiled shader blobs to `MuMain/src/shaders/compiled/` as CI-safe fallback
- [ ] CMake copies pre-compiled blobs to `${CMAKE_BINARY_DIR}/shaders/` at configure time (when `MU_ENABLE_SHADER_COMPILATION=OFF`)

### Task 3 — MuRendererSDLGpu.cpp Shader Loading (AC-6)

- [ ] Remove `k_VertexShaderSPIRV` and `k_FragmentShaderSPIRV` placeholder byte arrays
- [ ] Add `[[nodiscard]] static std::vector<Uint8> LoadShaderBlob(const char* name, const char* stage, const char* driver)` in anonymous namespace
- [ ] `LoadShaderBlob` uses `std::filesystem::path` for path construction (no backslash literals)
- [ ] `LoadShaderBlob` reads with `std::ifstream` in binary mode; logs via `g_ErrorReport.Write(L"RENDER: SDL_gpu -- shader blob not found: %hs", path)` on failure
- [ ] Add `[[nodiscard]] static const char* GetShaderFormat(const char* driver)` returning `"spirv"`, `"dxil"`, or `"msl"`
- [ ] Expose `GetShaderBlobPath(const char* driver, const char* stage, const char* name)` as free function callable from test TU (in `mu::` namespace or anonymous namespace with forward declaration pattern)
- [ ] Update `Init()`: call `LoadShaderBlob` for all 5 shaders after `SDL_CreateGPUDevice`
- [ ] Create `SDL_GPUShader` handles from loaded blobs; log `g_ErrorReport.Write(L"RENDER: SDL_gpu -- SDL_CreateGPUShader failed: %hs (%hs)", shaderName, SDL_GetError())` on null
- [ ] Return `false` from `Init()` on fatal shader load failure (`basic_textured` shaders are critical)
- [ ] Release shader handles after pipeline creation (verify existing `SDL_ReleaseGPUShader` calls still present)

### Task 4 — Fix AI-Review Issues from 4.3.1 (AC-7, AC-8, AC-9)

- [ ] **AC-7 [HIGH]**: Map transfer buffer once per frame in `BeginFrame()` with `cycle=false`; store `s_vtxMappedPtr`
- [ ] **AC-7**: `UploadVertices()` writes to `s_vtxMappedPtr + s_vtxOffset`; returns offset; no longer opens its own copy pass
- [ ] **AC-7**: Before `SDL_BeginGPURenderPass()`: unmap, open single copy pass, upload `s_vtxOffset` bytes, close copy pass, then begin render pass
- [ ] **AC-7**: Reset `s_vtxOffset = 0` at start of `BeginFrame()`
- [ ] **AC-8 [HIGH]**: Add `bool bUse3DLayout` parameter to `BuildBlendPipeline()`
- [ ] **AC-8**: Create `s_pipelines2D[k_PipelineCount]` with `Vertex2D` layout (pitch=20, float2 pos, float2 uv, ubyte4 color)
- [ ] **AC-8**: Create `s_pipelines3DDepthOn[k_PipelineCount]` with `Vertex3D` layout (pitch=40, float3 pos, float3 normal, float2 uv, ubyte4 color)
- [ ] **AC-8**: `RenderQuad2D` selects from `s_pipelines2D`; `RenderTriangles`/`RenderQuadStrip` select from `s_pipelines3DDepthOn`
- [ ] **AC-9 [MEDIUM]**: Verify no remaining `SDL_MapGPUTransferBuffer` calls with `cycle=true` per draw (resolved by AC-7)

### Task 5 — Fog Uniform Buffer (AC-10)

- [ ] Define `struct FogUniform` (std140 layout) in anonymous namespace in `MuRendererSDLGpu.cpp`: `fogEnabled`, `alphaDiscardEnabled`, `alphaThreshold`, `pad0`, `fogStart`, `fogEnd`, `fogColor[4]`, `pad1[2]`
- [ ] `static_assert` on `sizeof(FogUniform)` and field offsets to match HLSL cbuffer declaration (also verified in Catch2 test)
- [ ] Create `s_fogUniformBuf` in `Init()` via `SDL_CreateGPUBuffer(device, {SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ, sizeof(FogUniform), 0})`; log `g_ErrorReport.Write(L"RENDER: SDL_gpu -- fog uniform buffer creation failed: %hs", SDL_GetError())` on null
- [ ] Create `s_fogTransferBuf` in `Init()` for fog uploads
- [ ] `SetFog()` populates `m_fogParams` AND uploads `FogUniform` to `s_fogUniformBuf` via copy pass (or staged dirty flag + upload in `BeginFrame()`)
- [ ] `SetFog()` only enables fog when `FogParams.mode == 0x2601` (GL_LINEAR); EXP/EXP2 deferred
- [ ] `RenderQuad2D`, `RenderTriangles`, `RenderQuadStrip` bind `s_fogUniformBuf` at fragment shader storage buffer slot 0 via `SDL_BindGPUFragmentStorageBuffers(renderPass, 0, &s_fogUniformBuf, 1)`
- [ ] `Shutdown()` releases `s_fogUniformBuf` and `s_fogTransferBuf` via `SDL_ReleaseGPUBuffer`

### Task 6 — Catch2 Tests (AC-STD-2, AC-VAL-1)

- [ ] Create `MuMain/tests/render/test_shaderprograms.cpp` (RED phase — tests compile but FAIL until implementation)
- [ ] Add `target_sources(MuTests PRIVATE render/test_shaderprograms.cpp)` to `MuMain/tests/CMakeLists.txt` with story comment
- [ ] `TEST_CASE("AC-6: ShaderBlobPath — driver-to-extension mapping")` passes for all 3 drivers × 3 stages (9 assertions minimum)
- [ ] `TEST_CASE("AC-10: FogUniform — struct layout static_assert")` verifies `sizeof(FogUniform)`, offset of `fogStart`, offset of `fogColor`, alignment compliance
- [ ] `TEST_CASE("AC-8: Pipeline selection — Vertex3D uses 3D pipeline set")` asserts `RenderTriangles`/`RenderQuadStrip` select `s_pipelines3DDepthOn`, not `s_pipelines2D`
- [ ] All tests compile and run on macOS/Linux — no GPU device, no Win32, no OpenGL types in test TU

### Task 7 — Quality Gate + Verification (AC-STD-3, AC-STD-13, AC-VAL-2, AC-VAL-6)

- [ ] `./ctl check` passes 0 errors; file count = 708 C++ files (+1 test TU)
- [ ] `grep` confirms `k_VertexShaderSPIRV` and `k_FragmentShaderSPIRV` are fully removed from `MuRendererSDLGpu.cpp`
- [ ] `grep` confirms no `glBegin`, `glEnd`, `glVertex*`, `glEnable`, `glDisable` in new or modified files
- [ ] All 3 Catch2 `TEST_CASE`s compile (even in RED phase before implementation)
- [ ] Conventional commit created: `feat(render): add HLSL shader programs with SDL_shadercross`

### PCC Compliance Items

- [ ] No prohibited libraries used: no `new`/`delete` (use `std::vector` for shader blobs), no `NULL`, no `wprintf`, no `#ifdef _WIN32` in game logic
- [ ] All new fallible functions have `[[nodiscard]]` attribute
- [ ] `mu::` namespace used for any symbols exposed across TU boundary (`GetShaderBlobPath`, etc.)
- [ ] `g_ErrorReport.Write(L"RENDER: SDL_gpu -- ...")` on all SDL_gpu failure paths (shader blob load, `SDL_CreateGPUShader`, fog buffer creation)
- [ ] `std::ifstream` (binary mode) used for shader blob loading — no `CreateFile`/`ReadFile`
- [ ] `std::filesystem::path` for blob path construction — no backslash literals
- [ ] HLSL code follows HLSL naming conventions (PascalCase cbuffer names, camelCase input fields)
- [ ] No OpenGL types anywhere in shader loading or pipeline code
- [ ] `#pragma once` in any new header files (no new public headers expected; pattern is anonymous namespace + forward decl)
- [ ] All shader changes inside `#ifndef MU_USE_OPENGL_BACKEND` (or `#ifdef MU_ENABLE_SDL3`) guard — matches 4.3.1 pattern
- [ ] Include order preserved (`SortIncludes: Never` — do not reorder includes in modified files)
- [ ] Allman brace style, 4-space indent, 120-column limit enforced (verified by `./ctl check`)

---

## Test Files (RED Phase)

### `MuMain/tests/render/test_shaderprograms.cpp`

> RED PHASE: Tests compile but FAIL until `GetShaderBlobPath`, `FogUniform`, and pipeline selection logic are implemented in `MuRendererSDLGpu.cpp`.

**TEST_CASE AC-6: ShaderBlobPath — driver-to-extension mapping**
- Covers: `GetShaderBlobPath(driver, stage, name)` helper for all 3 drivers
- Assertions: `"vulkan"` → `.spv`; `"direct3d12"` → `.dxil`; `"metal"` → `.msl`; path contains `MU_SHADER_DIR` prefix; stage suffix (`vert`/`frag`) included in filename

**TEST_CASE AC-10: FogUniform — struct layout static_assert**
- Covers: `FogUniform` struct mirrors HLSL `FogUniforms` cbuffer (std140 alignment)
- Assertions: `sizeof(FogUniform) == 48` (or expected std140 size); `offsetof(FogUniform, fogStart)` matches HLSL layout; `offsetof(FogUniform, fogColor)` matches; static_asserts pass at compile time

**TEST_CASE AC-8: Pipeline selection — Vertex3D uses 3D pipeline set**
- Covers: `RenderTriangles`/`RenderQuadStrip` bind `s_pipelines3DDepthOn`, not `s_pipelines2D`
- Assertions: Exposed free function `GetPipelineSetFor(DrawMode)` or equivalent returns `PipelineSet::Pipelines3D` for `RenderTriangles`/`RenderQuadStrip` and `PipelineSet::Pipelines2D` for `RenderQuad2D`
- No GPU device required; logic tested via pure enum/function selector

---

## Outputs for Downstream Workflows

| Output | Value |
|--------|-------|
| `atdd_checklist_path` | `/Users/joseybv/workspace/mu/MuMain-workspace/_bmad-output/stories/4-3-2-shader-programs/atdd.md` |
| `test_files_created` | `["MuMain/tests/render/test_shaderprograms.cpp"]` |
| `implementation_checklist_complete` | `false` (all items `[ ]` — ready for dev-story) |
| `ac_test_mapping` | `{"AC-6": "ShaderBlobPath driver-to-extension mapping", "AC-8": "Pipeline selection Vertex3D uses 3D pipeline set", "AC-10": "FogUniform struct layout static_assert"}` |

---

## Notes

- Story type `infrastructure` → no E2E tests (Playwright), no Bruno API collection required.
- AC-VAL-3, AC-VAL-4, AC-VAL-5 are explicitly deferred to Windows/macOS runtime validation — pre-approved in story.md. These are NOT DEFERRED in the prohibited sense; the story documents the rationale (no Windows/GPU device in CI environment).
- The three deferred GPU validation items use `@Disabled` equivalent: they are marked in story.md as "deferred to Windows/macOS runtime" with explicit rationale per architecture constraints.
- Pre-compiled shader blobs committed to `src/shaders/compiled/` are the CI-safe strategy documented in story Dev Notes — not a workaround, but the explicit design decision.
- `MuRendererSDLGpu.cpp` baseline: 1401 lines, 707 C++ files at story start. Expected after story: 708 C++ files.
