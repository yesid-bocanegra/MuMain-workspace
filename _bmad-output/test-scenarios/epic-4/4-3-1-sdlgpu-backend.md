# Test Scenarios: Story 4.3.1 — SDL_gpu Backend Implementation

**Generated:** 2026-03-10
**Story:** 4.3.1 SDL_gpu Backend Implementation
**Flow Code:** VS1-RENDER-SDLGPU-BACKEND
**Project:** MuMain-workspace
**Story Type:** infrastructure

These scenarios cover validation of Story 4.3.1 acceptance criteria.
Automated tests (Catch2 unit tests in `MuMain/tests/render/test_sdlgpubackend.cpp`) cover
TextureRegistry, BlendMode factor table, and FogParams storage without requiring a GPU device.
Integration and platform scenarios require a physical GPU and a supported OS build environment.

---

## AC-1: MuRendererSDLGpu Implements Full IMuRenderer Interface

### Scenario 1: All pure virtual methods implemented (Catch2 — no GPU required)
- **Given:** `MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp` compiled into `MURenderFX`
- **When:** `FogCaptureMock` (a `MuRendererSDLGpu` test subclass) is instantiated in `test_sdlgpubackend.cpp`
- **Then:** The mock compiles and all inherited pure virtual methods are overridden — the compiler enforces this (no abstract class instantiation errors)
- **Automated:** `TEST_CASE("AC-STD-2(c) [4-3-1]: SetFog -- FogParams storage round-trip")` — `FogCaptureMock` inherits `MuRendererSDLGpu`
- **Status:** [x] Passed — 2026-03-10 (implementation complete, 1401 lines)

---

## AC-2: SDL_gpu Device Created at Startup

### Scenario 2: Device creation on macOS (Metal backend)
- **Given:** macOS arm64 build with Metal drivers available
- **When:** `MuRendererSDLGpu::Init(pWindow)` is called after `SDL_CreateWindow()`
- **Then:** `SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL | SDL_GPU_SHADERFORMAT_MSL, true, NULL)` returns a non-null `SDL_GPUDevice*`; `SDL_GetGPUDeviceDriver(device)` returns `"metal"`
- **Note:** Deferred — requires actual GPU device and macOS build (EPIC-2 SDL3 window required)
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 3: Device creation failure logged
- **Given:** GPU device creation fails (e.g., unsupported driver)
- **When:** `SDL_CreateGPUDevice()` returns `nullptr`
- **Then:** `g_ErrorReport.Write(L"RENDER: SDL_gpu -- device creation failed: %hs", SDL_GetError())` is called; `Init()` returns `false`
- **Automated:** Code path verified by review; `g_ErrorReport.Write()` call pattern inspected in `MuRendererSDLGpu.cpp`
- **Status:** [x] Verified — 2026-03-10 (code review)

---

## AC-3: Window Claimed and Per-Frame Command Buffer Lifecycle

### Scenario 4: BeginFrame/EndFrame replace SDL_GL_SwapWindow
- **Given:** Game loop in `Winmain.cpp` with SDL3 event loop active
- **When:** Each game frame executes the render path
- **Then:** `BeginFrame()` calls `SDL_AcquireGPUCommandBuffer()` + `SDL_AcquireGPUSwapchainTexture()` + `SDL_BeginGPURenderPass()`; `EndFrame()` calls `SDL_EndGPURenderPass()` + `SDL_SubmitGPUCommandBuffer()`; no `SDL_GL_SwapWindow()` call
- **Note:** Deferred — requires running game on platform with GPU (EPIC-2 SDL3 window + actual GPU device)
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

### Scenario 5: Minimized window skips frame
- **Given:** Game window is minimized (swapchain unavailable)
- **When:** `SDL_AcquireGPUSwapchainTexture()` returns `nullptr`
- **Then:** Draw calls are skipped for that frame; no error logged; game loop continues
- **Automated:** Code path verified by review in `MuRendererSDLGpu.cpp::BeginFrame()`
- **Status:** [x] Verified — 2026-03-10 (code review)

---

## AC-4: Vertex Data Upload via SDL_GPUTransferBuffer

### Scenario 6: Dynamic vertex data upload per frame
- **Given:** Game rendering quad sprites with `RenderQuad2D()` calls
- **When:** Each draw call invokes `UploadVertices()`
- **Then:** Vertex data is written to the transfer buffer via `SDL_MapGPUTransferBuffer()` + `memcpy()`; a copy pass uploads to the GPU buffer before the render pass
- **Note:** Deferred — requires running game with GPU (visual validation only)
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-5: TextureRegistry Map Operations

### Scenario 7: Register, lookup, and unregister a texture (Catch2 — no GPU required)
- **Given:** `RegisterTexture(1, pTex)` called with a valid `SDL_GPUTexture*` pointer
- **When:** `LookupTexture(1)` is called
- **Then:** Returns the same pointer that was registered
- **Automated:** `TEST_CASE("AC-STD-2(a) [4-3-1]: TextureRegistry -- register and lookup")` SECTION "lookup registered texture"
- **Status:** [x] Passed — 2026-03-10

### Scenario 8: Unregister removes texture from map (Catch2 — no GPU required)
- **Given:** `RegisterTexture(1, pTex)` followed by `UnregisterTexture(1)`
- **When:** `LookupTexture(1)` is called
- **Then:** Returns `nullptr`
- **Automated:** `TEST_CASE("AC-STD-2(a) [4-3-1]: TextureRegistry -- register and lookup")` SECTION "unregister removes texture"
- **Status:** [x] Passed — 2026-03-10

### Scenario 9: Unknown texture ID skips draw and logs warning
- **Given:** `textureId = 99` not registered in TextureRegistry
- **When:** `RenderQuad2D()` is called with `textureId = 99`
- **Then:** Draw is skipped; `g_ErrorReport.Write(L"RENDER: SDL_gpu::RenderQuad2D -- unknown textureId %u, skipping", textureId)` is called; no crash
- **Automated:** Code path verified by review; logging pattern present in `MuRendererSDLGpu.cpp`
- **Status:** [x] Verified — 2026-03-10 (code review)

---

## AC-6: Six Blend Mode Pipeline Objects

### Scenario 10: BlendMode → SDL_GPUBlendFactor table (Catch2 — no GPU required)
- **Given:** `GetBlendFactors(BlendMode)` free function implemented in `MuRendererSDLGpu.cpp`
- **When:** Called for each of the 8 `BlendMode` enum values (Alpha, Additive, Subtract, InverseColor, Mixed, LightMap, Glow, Luminance)
- **Then:** `src_color_blendfactor` and `dst_color_blendfactor` match the architecture-rendering.md specification table
- **Automated:** `TEST_CASE("AC-STD-2(b) [4-3-1]: BlendMode -- SDL_gpu factor table")` — all 8 modes verified with proxy constants
- **Status:** [x] Passed — 2026-03-10

### Scenario 11: No-blend pipeline (DisableBlend)
- **Given:** `DisableBlend()` called on `MuRendererSDLGpu` instance
- **When:** Draw call is made
- **Then:** Pipeline with `blend_enable = false` is bound (index 8 in `s_pipelines[]`)
- **Automated:** Code path verified by review; `DisableBlend()` sets `m_activeBlendMode` to index 8
- **Status:** [x] Verified — 2026-03-10 (code review)

---

## AC-7: GetRenderer() Returns MuRendererSDLGpu

### Scenario 12: GetRenderer() returns SDL_gpu backend by default
- **Given:** `MU_USE_OPENGL_BACKEND` CMake option is OFF (default)
- **When:** `mu::GetRenderer()` is called at runtime
- **Then:** Returns a `MuRendererSDLGpu` static instance (not `MuRendererGL`)
- **Automated:** `MuRenderer.cpp` wrapped in `#ifdef MU_USE_OPENGL_BACKEND` — `GetRenderer()` unconditionally returns `MuRendererSDLGpu` when flag is OFF; verified by code inspection
- **Status:** [x] Verified — 2026-03-10 (code review)

---

## AC-8: GLEW Removed; MU_USE_OPENGL_BACKEND Option Added

### Scenario 13: CMake configures without GLEW (macOS native build)
- **Given:** macOS arm64 build with `MU_USE_OPENGL_BACKEND=OFF` (default)
- **When:** `cmake --preset macos-arm64` runs
- **Then:** CMake does not attempt `find_package(GLEW)` and `MURenderFX` does not link `GLEW::GLEW`; configure succeeds
- **Automated:** `MuMain/CMakeLists.txt` conditional verified by code inspection
- **Status:** [x] Verified — 2026-03-10 (code review)

### Scenario 14: stdafx.h excludes GLEW without MU_USE_OPENGL_BACKEND
- **Given:** `MU_USE_OPENGL_BACKEND` not defined (default)
- **When:** `stdafx.h` is included in a translation unit on macOS/Linux
- **Then:** `#include <GL/glew.h>` is not compiled; OpenGL stubs are retained for files with pre-existing GL calls (deferred migration)
- **Automated:** `stdafx.h` conditional verified by code inspection
- **Status:** [x] Verified — 2026-03-10 (code review)

---

## AC-STD-2: Catch2 Unit Tests

### Scenario 15: Full TextureRegistry round-trip (Catch2)
- **Given:** `MuTests` binary compiled with `test_sdlgpubackend.cpp`
- **When:** `TEST_CASE("AC-VAL-1 [4-3-1]: TextureRegistry contract verified")` runs
- **Then:** All SECTION blocks pass: register, lookup, overwrite, unregister, clear
- **Automated:** Yes — Catch2 3.7.1, `MuTests` target
- **Status:** [x] Passed — 2026-03-10

### Scenario 16: SetFog FogParams storage (Catch2)
- **Given:** `FogCaptureMock` test subclass of `MuRendererSDLGpu` with FogParams captured
- **When:** `SetFog(FogParams{mode=GL_EXP, density=0.05f, start=10.f, end=100.f, color={0.5,0.5,0.5,1.0}})` is called
- **Then:** `m_fogParams.density == 0.05f`, `m_fogParams.mode == GL_EXP`, start/end/color correct
- **Automated:** `TEST_CASE("AC-STD-2(c) [4-3-1]: SetFog -- FogParams storage round-trip")`
- **Status:** [x] Passed — 2026-03-10

---

## AC-STD-13: Quality Gate

### Scenario 17: ./ctl check passes 0 errors
- **Given:** All implementation files in `MuMain/src/source/` + new files `MuRendererSDLGpu.cpp` and `test_sdlgpubackend.cpp`
- **When:** `./ctl check` runs (clang-format-check + cppcheck)
- **Then:** 0 format violations, 0 cppcheck errors; 707 files checked
- **Automated:** Yes — `./ctl check`
- **Status:** [x] Passed — 2026-03-10 (707 files, 0 errors)

---

## AC-9 / AC-VAL-3: Ground Truth SSIM (Deferred)

### Scenario 18: SSIM > 0.99 on login screen — D3D12 vs OpenGL baseline
- **Given:** Windows build with D3D12 backend via `MU_USE_OPENGL_BACKEND=OFF`; ground truth baseline captured in story 4.1.1
- **When:** Login screen rendered via SDL_gpu D3D12 path and captured via screenshot tool
- **Then:** SSIM comparison against story 4.1.1 baseline returns > 0.99
- **Note:** Deferred to story 4.3.2 — requires Windows + D3D12 environment not available in current macOS CI
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-VAL-4: macOS Metal Backend Selection (Deferred)

### Scenario 19: SDL_GetGPUDeviceDriver returns "metal" on macOS
- **Given:** macOS arm64 build with GPU device successfully created
- **When:** `SDL_GetGPUDeviceDriver(device)` is called after `MuRendererSDLGpu::Init()`
- **Then:** Returns `"metal"` string; no OpenGL or software renderer fallback
- **Note:** Deferred — requires actual GPU device and macOS build with linked game
- **Status:** [ ] Not Tested / [ ] Passed / [ ] Failed

---

## AC-VAL-5: No Stray GL Calls in MuRendererSDLGpu.cpp

### Scenario 20: Grep confirms zero GL calls in new backend file
- **Given:** `MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp` (1401 lines, complete implementation)
- **When:** `grep -rn "glBegin\|glEnd\|glVertex\|glTexCoord\|glBindTexture\|glBlendFunc" MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp` is run
- **Then:** Zero matches
- **Automated:** Grep command — run manually or in CI
- **Status:** [x] Verified — 2026-03-10 (zero GL calls in MuRendererSDLGpu.cpp)

---

## Review Follow-up Issues (Tracked for Story 4.3.2)

The following issues were identified during AI code review and are deferred to story 4.3.2:

| Severity | Description | File | Fix Story |
|----------|-------------|------|-----------|
| HIGH | `UploadVertices()` opens copy pass while render pass active — SDL_gpu API violation | `MuRendererSDLGpu.cpp:UploadVertices` | 4.3.2 |
| HIGH | `BuildBlendPipeline()` uses `Vertex2D` layout for all 18 pipelines — `Vertex3D` draws have layout mismatch | `MuRendererSDLGpu.cpp:BuildBlendPipeline` | 4.3.2 |
| MEDIUM | `SDL_MapGPUTransferBuffer(cycle=true)` per draw call may discard accumulated data | `MuRendererSDLGpu.cpp:UploadVertices` | 4.3.2 |

---

*Test scenarios generated by PCC dev-story workflow for Story 4.3.1*
