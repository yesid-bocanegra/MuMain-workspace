# Story 4.4.1: Texture System Migration (CGlobalBitmap → SDL_gpu)

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 4 - Rendering Pipeline Migration |
| Feature | 4.4 - Texture System |
| Story ID | 4.4.1 |
| Story Points | 8 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| SAFe Flow Type | Feature |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-RENDER-TEXTURE-MIGRATE |
| FRs Covered | FR12, FR13, FR14, FR15, FR16 |
| Prerequisites | Story 4.3.1 (SDL_gpu backend — done), Story 4.3.2 (Shader programs — done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend, render | Migrate `CGlobalBitmap::OpenJpegTurbo` and `OpenTga` from OpenGL texture creation (`glGenTextures`/`glBindTexture`/`glTexImage2D`) to SDL_gpu texture upload; add `SDL_GPUTexture*` handle to `BITMAP_t` struct; add `RegisterTexture`/`UnregisterTexture` calls at load/unload; add Catch2 test for texture upload path; add Catch2 test for cache eviction and format loading |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** the texture management system (`CGlobalBitmap`) migrated from OpenGL texture objects to SDL_gpu textures,
**so that** all ~30,000 indexed textures load and display correctly on macOS (Metal), Linux (Vulkan), and Windows (D3D) — eliminating the last major OpenGL call sites in the asset loading pipeline.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** `glGenTextures`/`glBindTexture`/`glTexImage2D` calls replaced in `CGlobalBitmap::OpenJpegTurbo` and `CGlobalBitmap::OpenTga`. After migration: no `gl*` calls in `GlobalBitmap.cpp`. The existing JPEG/TGA decode pipelines (libturbojpeg `tjDecompress2`, custom OZT strip-decode) are unchanged — only the GL upload at the end of each function is replaced.

- [ ] **AC-2:** `BITMAP_t` struct gains a `SDL_GPUTexture* sdlTexture;` member (added after `TextureNumber`). Under `#ifdef MU_ENABLE_SDL3`, texture creation uses `SDL_CreateGPUTexture` + `SDL_UploadToGPUTexture` via a copy pass; `TextureNumber` retains its `GLuint` type for backward compatibility but is set to `0` on the SDL_gpu path. Under `#ifndef MU_ENABLE_SDL3` (OpenGL path), `sdlTexture` is `nullptr` and `TextureNumber` is set as before.

- [ ] **AC-3:** `CGlobalBitmap::UnloadImage` calls `mu::UnregisterTexture(uiBitmapIndex)` and, if `pBitmap->sdlTexture != nullptr`, calls `SDL_ReleaseGPUTexture(s_device, pBitmap->sdlTexture)` before erasing the bitmap entry. No texture memory leaks on eviction. `glDeleteTextures` is guarded under `#ifndef MU_ENABLE_SDL3`.

- [ ] **AC-4:** On the SDL_gpu path, immediately after `SDL_CreateGPUTexture`, call `mu::RegisterTexture(uiBitmapIndex, pBitmap->sdlTexture)` so that `MuRendererSDLGpu.cpp::LookupTexture(uiBitmapIndex)` can resolve the texture for draw calls. The texture ID passed to `IMuRenderer::RenderQuad2D` / `RenderTriangles` / `RenderQuadStrip` is the existing `GLuint BitmapIndex` — no change to caller sites.

- [ ] **AC-5:** All texture formats load correctly on the SDL_gpu path:
  - JPEG path (OZJ files via `OpenJpegTurbo`): decoded as RGB (`Components=3`), uploaded via `SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM` with alpha=255 padding or `SDL_GPU_TEXTUREFORMAT_R8G8B8_UNORM` if available (fallback to RGBA8 with padding).
  - TGA path (OZT files via `OpenTga`): decoded as RGBA (`Components=4`), uploaded via `SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM` directly.
  - Sampler filter `uiFilter` (GL_NEAREST=`SDL_GPU_FILTER_NEAREST`, GL_LINEAR=`SDL_GPU_FILTER_LINEAR`) and wrap mode `uiWrapMode` (GL_CLAMP_TO_EDGE=`SDL_GPU_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE`, GL_REPEAT=`SDL_GPU_SAMPLER_ADDRESS_MODE_REPEAT`) are mapped to equivalent SDL_gpu sampler parameters and stored/bound correctly.

- [ ] **AC-6:** Ground truth: textured scenes (world terrain, character models) rendered with SDL_gpu textures match story 4.1.1 SSIM baseline (target > 0.99). This is a manual validation criterion — pre-approved for Windows/macOS runtime deferral per architecture constraints (same deferral pattern as stories 4.3.1 and 4.3.2).

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance — `#ifdef MU_ENABLE_SDL3` guards all SDL_gpu code in `GlobalBitmap.cpp`/`GlobalBitmap.h`; no raw `new`/`delete`; `nullptr` not `NULL`; no `wprintf`; no `#ifdef _WIN32` in game logic; `[[nodiscard]]` on new fallible helper functions; `#pragma once` in any new headers. No OpenGL types (except existing `GLuint BitmapIndex` and `GLuint TextureNumber` which are kept for the OpenGL path and `#ifdef` guarded on the SDL path). BITMAP_t struct uses `SDL_GPUTexture*` only under `#ifdef MU_ENABLE_SDL3`.

- [ ] **AC-STD-2:** Catch2 tests in `tests/render/test_texturesystemmigration.cpp`:
  - (a) `TEST_CASE("TextureRegistry — RegisterTexture/LookupTexture/UnregisterTexture roundtrip")` — calls `mu::RegisterTexture(42u, mockPtr)`, verifies `mu::LookupTexture(42u) == mockPtr`, calls `mu::UnregisterTexture(42u)`, verifies `mu::LookupTexture(42u) == mu::LookupTexture(0u)` (fallback to white texture slot or nullptr without GPU). No GPU device required.
  - (b) `TEST_CASE("UploadTexture — GL/SDL format mapping")` — verify `MapGLFilterToSDL(GL_NEAREST)` and `MapGLFilterToSDL(GL_LINEAR)` return correct `SDL_GPUFilter` enum values; verify `MapGLWrapToSDL(GL_CLAMP_TO_EDGE)` and `MapGLWrapToSDL(GL_REPEAT)` return correct `SDL_GPUSamplerAddressMode` enum values. Free functions exposed in anonymous namespace, forward-declared for test TU.
  - (c) `TEST_CASE("UploadTexture — RGB pixel padding to RGBA8")` — verify that a synthetic 2×2 RGB buffer correctly pads to RGBA8 (alpha=255) using the static `PadRGBToRGBA` helper. Pure CPU logic, no GPU device required.
  - Tests must compile and pass on macOS/Linux (no GPU device required).

- [ ] **AC-STD-4:** CI quality gate passes (`./ctl check` — clang-format check + cppcheck 0 errors). File count increases from 707 by +1 test file = **708 C++ files** checked after this story.

- [ ] **AC-STD-5:** Error logging:
  - `g_ErrorReport.Write(L"ASSET: texture upload — JPEG decode failed for %ls", filename.c_str())` on libturbojpeg failure (existing).
  - `g_ErrorReport.Write(L"ASSET: texture upload — SDL_CreateGPUTexture failed for %ls: %hs", filename.c_str(), SDL_GetError())` on `SDL_CreateGPUTexture` returning null.
  - `g_ErrorReport.Write(L"ASSET: texture upload — SDL_CreateGPUTransferBuffer failed for %ls: %hs", filename.c_str(), SDL_GetError())` on transfer buffer allocation failure.
  - `g_ErrorReport.Write(L"ASSET: texture upload — SDL_CreateGPUSampler failed for %ls: %hs", filename.c_str(), SDL_GetError())` on sampler creation failure (if samplers are per-texture — see Dev Notes on sampler strategy).

- [ ] **AC-STD-6:** Conventional commit: `refactor(render): migrate texture system to SDL_gpu`

- [ ] **AC-STD-12:** SLI/SLO — N/A for this story (no HTTP endpoints; texture loading infrastructure). Texture upload latency must not cause visible hitches (>50ms) during normal gameplay — single texture upload is expected to complete in <1ms on all platforms (SDL_gpu upload is async via copy command buffer, non-blocking on the game thread).

- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format check + cppcheck 0 errors). Confirmed: **708 C++ files** checked after this story (pre-story baseline: 707 files from story 4.3.2; +1 new test file).

- [ ] **AC-STD-14:** Observability — `g_ErrorReport.Write()` on all SDL_gpu failure paths as specified in AC-STD-5.

- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push).

- [ ] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/render/` directory pattern, `target_sources(MuTests PRIVATE render/test_texturesystemmigration.cpp)` in `tests/CMakeLists.txt`).

---

## Validation Artifacts

- [ ] **AC-VAL-1:** Catch2 tests pass for TextureRegistry roundtrip, GL→SDL filter/wrap mapping, and RGB→RGBA8 padding — VERIFIED: 3 GREEN TEST_CASE blocks in `test_texturesystemmigration.cpp`.
- [ ] **AC-VAL-2:** `./ctl check` passes with 0 errors after all changes — VERIFIED: 708 files, 0 errors.
- [ ] **AC-VAL-3:** (Deferred — pre-approved) Windows D3D12 SSIM validation against story 4.1.1 baseline — requires Windows build environment with GPU. Tracked for follow-up runtime validation.
- [ ] **AC-VAL-4:** (Deferred — pre-approved) macOS Metal GPU device validation — no GPU device available in CI. Tracked for follow-up runtime validation.
- [ ] **AC-VAL-5:** No GL texture calls (`glGenTextures`, `glBindTexture`, `glTexImage2D`, `glDeleteTextures`, `glTexParameteri`, `glTexEnvf`) remain in `GlobalBitmap.cpp` outside of `#ifndef MU_ENABLE_SDL3` guards — VERIFIED: grep confirms no unguarded GL texture calls.

---

## Tasks / Subtasks

- [ ] Task 1: Update `BITMAP_t` struct and `GlobalBitmap.h` (AC: 2)
  - [ ] Subtask 1.1: Add `#ifdef MU_ENABLE_SDL3` block in `GlobalBitmap.h` after `TextureNumber`: add `SDL_GPUTexture* sdlTexture = nullptr;` and `SDL_GPUSampler* sdlSampler = nullptr;` members. Include forward declaration or SDL3 header inside the ifdef guard. Keep `GLuint TextureNumber;` unconditional for backward compatibility on the OpenGL path.
  - [ ] Subtask 1.2: Add `#ifdef MU_ENABLE_SDL3` include for `<SDL3/SDL_gpu.h>` in `GlobalBitmap.h` (or include via the existing stdafx.h SDL path if SDL3 is already there). Alternatively, use forward declaration `struct SDL_GPUTexture;` and `struct SDL_GPUSampler;` to avoid pulling in SDL3 headers in the `.h` file — prefer forward declaration to minimize include impact.

- [ ] Task 2: Implement SDL_gpu texture upload helpers in `GlobalBitmap.cpp` (AC: 5)
  - [ ] Subtask 2.1: Add anonymous namespace helpers in `GlobalBitmap.cpp`:
    - `[[nodiscard]] SDL_GPUFilter MapGLFilterToSDL(GLuint uiFilter)` — maps `GL_NEAREST` (0x2600) to `SDL_GPU_FILTER_NEAREST`, `GL_LINEAR` (0x2601) to `SDL_GPU_FILTER_LINEAR`, default to `SDL_GPU_FILTER_NEAREST`.
    - `[[nodiscard]] SDL_GPUSamplerAddressMode MapGLWrapToSDL(GLuint uiWrapMode)` — maps `GL_CLAMP_TO_EDGE` (0x812F) to `SDL_GPU_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE`, `GL_REPEAT` (0x2901) to `SDL_GPU_SAMPLER_ADDRESS_MODE_REPEAT`, default to `SDL_GPU_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE`.
    - `[[nodiscard]] std::vector<std::uint8_t> PadRGBToRGBA(const std::uint8_t* rgbData, int width, int height)` — creates RGBA8 buffer from RGB input, setting alpha=255 for every pixel. Returns padded vector.
  - [ ] Subtask 2.2: Add `[[nodiscard]] static bool UploadTextureSDLGpu(BITMAP_t* pBitmap, const std::uint8_t* pixelData, int width, int height, SDL_GPUTextureFormat format, SDL_GPUFilter filter, SDL_GPUSamplerAddressMode wrapMode)` helper. Implementation:
    - Obtain `SDL_GPUDevice* device` via `mu::GetSDLDevice()` (see Dev Notes on device accessor).
    - Create `SDL_GPUTexture` via `SDL_CreateGPUTexture(device, &texInfo)` — `texInfo.format = format`, `texInfo.width = width`, `texInfo.height = height`, `texInfo.layer_count_or_depth = 1`, `texInfo.num_levels = 1`, `texInfo.usage = SDL_GPU_TEXTUREUSAGE_SAMPLER`.
    - On null return: log ASSET error, return false.
    - Create transfer buffer, map, copy pixel data, unmap, open copy command buffer, begin copy pass, call `SDL_UploadToGPUTexture`, end copy pass, submit command buffer.
    - Create `SDL_GPUSampler` via `SDL_CreateGPUSampler(device, &samplerInfo)` — `min_filter = filter`, `mag_filter = filter`, `address_mode_u = wrapMode`, `address_mode_v = wrapMode`, `address_mode_w = SDL_GPU_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE`.
    - Store in `pBitmap->sdlTexture` and `pBitmap->sdlSampler`. Return true.

- [ ] Task 3: Migrate `CGlobalBitmap::OpenJpegTurbo` (AC: 1, 4, 5)
  - [ ] Subtask 3.1: After the existing pixel buffer is populated (after the `jpegWidth != textureWidth` branch that copies rows), wrap the existing `glGenTextures`/`glBindTexture`/`glTexImage2D`/`glTexParameteri` block in `#ifndef MU_ENABLE_SDL3`.
  - [ ] Subtask 3.2: Add `#ifdef MU_ENABLE_SDL3` block: call `PadRGBToRGBA(pNewBitmap->Buffer, textureWidth, textureHeight)` to get RGBA data; call `UploadTextureSDLGpu(pNewBitmap.get(), rgbaData.data(), textureWidth, textureHeight, SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM, MapGLFilterToSDL(uiFilter), MapGLWrapToSDL(uiWrapMode))`; if it returns false, return false from `OpenJpegTurbo`. After the bitmap is moved into `m_mapBitmap` (via `std::move`), call `mu::RegisterTexture(uiBitmapIndex, pNewBitmap->sdlTexture)` using the raw pointer obtained before the move (or get the bitmap pointer after insert via `m_mapBitmap.find`).
    > **Implementation note:** `std::move(pNewBitmap)` transfers ownership before the RegisterTexture call. Get the raw sdlTexture pointer before the move: `SDL_GPUTexture* rawTex = pNewBitmap->sdlTexture;` then `mu::RegisterTexture(uiBitmapIndex, rawTex)` after the insert.
  - [ ] Subtask 3.3: Return `true` at the end of `OpenJpegTurbo` on SDL_gpu path (existing structure is preserved).

- [ ] Task 4: Migrate `CGlobalBitmap::OpenTga` (AC: 1, 4, 5)
  - [ ] Subtask 4.1: After the pixel buffer decode loop (the `src`/`dst` byte-swap loop for RGBA), wrap the existing `glGenTextures`/`glBindTexture`/`glTexImage2D`/`glTexEnvf`/`glTexParameteri` block in `#ifndef MU_ENABLE_SDL3`.
  - [ ] Subtask 4.2: Add `#ifdef MU_ENABLE_SDL3` block: RGBA data is already in `pNewBitmap->Buffer` (4 components); call `UploadTextureSDLGpu(pNewBitmap.get(), pNewBitmap->Buffer, Width, Height, SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM, MapGLFilterToSDL(uiFilter), MapGLWrapToSDL(uiWrapMode))`; if it returns false, return false from `OpenTga`. Then `SDL_GPUTexture* rawTex = pNewBitmap->sdlTexture;` before the move, call `mu::RegisterTexture(uiBitmapIndex, rawTex)` after the insert.

- [ ] Task 5: Migrate `CGlobalBitmap::UnloadImage` (AC: 3)
  - [ ] Subtask 5.1: In `UnloadImage`, before the existing `m_mapBitmap.erase` call, call `mu::UnregisterTexture(uiBitmapIndex)`.
  - [ ] Subtask 5.2: Guard the existing `glDeleteTextures(1, &(pBitmap->TextureNumber))` in `#ifndef MU_ENABLE_SDL3`.
  - [ ] Subtask 5.3: Add `#ifdef MU_ENABLE_SDL3` block: if `pBitmap->sdlSampler != nullptr`, call `SDL_ReleaseGPUSampler(device, pBitmap->sdlSampler)`; if `pBitmap->sdlTexture != nullptr`, call `SDL_ReleaseGPUTexture(device, pBitmap->sdlTexture)`.

- [ ] Task 6: Expose SDL_gpu device accessor for `GlobalBitmap.cpp` (AC: 2, 5)
  - [ ] Subtask 6.1: In `MuRendererSDLGpu.cpp`, add a free function in the `mu::` namespace (or expose via `MuRenderer.h` extension): `[[nodiscard]] SDL_GPUDevice* GetSDLDevice()` returning `s_device` (the file-static `SDL_GPUDevice*`). Add forward declaration or expose via a new header `MuRendererSDLGpu.h` (minimal header, `#pragma once`, declares `GetSDLDevice()` under `MU_ENABLE_SDL3` guard).
  - [ ] Subtask 6.2: Include the new accessor header in `GlobalBitmap.cpp` under `#ifdef MU_ENABLE_SDL3`. This avoids making `s_device` a global — keeps it encapsulated in `MuRendererSDLGpu.cpp`.
  - [ ] Subtask 6.3: Add `[[nodiscard]]` to `GetSDLDevice()` declaration. Log a `g_ErrorReport.Write` warning in `GetSDLDevice()` if `s_device == nullptr` and return `nullptr` — callers (`UploadTextureSDLGpu`) must handle null device gracefully (log + return false).

- [ ] Task 7: Add Catch2 tests (AC: AC-STD-2, AC-VAL-1)
  - [ ] Subtask 7.1: Create `MuMain/tests/render/test_texturesystemmigration.cpp`.
  - [ ] Subtask 7.2: Add `target_sources(MuTests PRIVATE render/test_texturesystemmigration.cpp)` to `MuMain/tests/CMakeLists.txt` (with `# Story 4.4.1 — Texture system migration` comment per convention).
  - [ ] Subtask 7.3: `TEST_CASE("TextureRegistry — RegisterTexture/LookupTexture/UnregisterTexture roundtrip")` — use a non-null `void* mockPtr = reinterpret_cast<void*>(0xDEADBEEF);`; call `mu::RegisterTexture(42u, mockPtr)`; CHECK `mu::LookupTexture(42u) == mockPtr`; call `mu::UnregisterTexture(42u)`; CHECK `mu::LookupTexture(42u) != mockPtr` (returns white texture fallback or nullptr when device is null). Clean up with `mu::ClearTextureRegistry()` at end.
  - [ ] Subtask 7.4: `TEST_CASE("UploadTexture — GL/SDL format mapping")` — call `MapGLFilterToSDL(0x2600)` and CHECK result equals `static_cast<int>(SDL_GPU_FILTER_NEAREST)`; call `MapGLFilterToSDL(0x2601)` and CHECK equals `SDL_GPU_FILTER_LINEAR`; same for `MapGLWrapToSDL` with `GL_CLAMP_TO_EDGE` (0x812F) → `SDL_GPU_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE` and `GL_REPEAT` (0x2901) → `SDL_GPU_SAMPLER_ADDRESS_MODE_REPEAT`. Forward-declare helpers in test TU via `extern` or expose via a thin header.
  - [ ] Subtask 7.5: `TEST_CASE("UploadTexture — RGB pixel padding to RGBA8")` — create a synthetic 2×2 RGB buffer `{255,0,0, 0,255,0, 0,0,255, 128,128,128}`; call `PadRGBToRGBA(buf, 2, 2)`; CHECK result has size 16; CHECK `result[3] == 255` (alpha for pixel 0); CHECK `result[7] == 255` (alpha for pixel 1); CHECK `result[0] == 255` and `result[1] == 0` and `result[2] == 0` (R,G,B for pixel 0 preserved).

- [ ] Task 8: Quality gate verification (AC: AC-STD-13, AC-VAL-2, AC-VAL-5)
  - [ ] Subtask 8.1: Run `./ctl check` — expect 0 errors, 708 files.
  - [ ] Subtask 8.2: grep verification — `grep -rn "glGenTextures\|glBindTexture\|glTexImage2D\|glDeleteTextures\|glTexParameteri\|glTexEnvf" MuMain/src/source/Data/GlobalBitmap.cpp` — confirm all matches are inside `#ifndef MU_ENABLE_SDL3` guards.
  - [ ] Subtask 8.3: Create conventional commit: `refactor(render): migrate texture system to SDL_gpu`

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A — C++ client, no HTTP error codes | — | — | — |

Logging patterns (new in `GlobalBitmap.cpp`):
- `g_ErrorReport.Write(L"ASSET: texture upload — SDL_CreateGPUTexture failed for %ls: %hs", filename.c_str(), SDL_GetError())` — on null `SDL_GPUTexture*`
- `g_ErrorReport.Write(L"ASSET: texture upload — SDL_CreateGPUTransferBuffer failed for %ls: %hs", filename.c_str(), SDL_GetError())` — on null transfer buffer
- `g_ErrorReport.Write(L"ASSET: texture upload — SDL_CreateGPUSampler failed for %ls: %hs", filename.c_str(), SDL_GetError())` — on null sampler

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
| Unit | Catch2 3.7.1 | TextureRegistry roundtrip, GL→SDL filter/wrap mapping, RGB→RGBA8 padding | `RegisterTexture`/`LookupTexture`/`UnregisterTexture`; `MapGLFilterToSDL(GL_NEAREST/LINEAR)`; `MapGLWrapToSDL(GL_CLAMP_TO_EDGE/GL_REPEAT)`; `PadRGBToRGBA` correctness |
| Integration (manual) | Windows build D3D12 | SSIM > 0.99 vs story 4.1.1 baseline | World terrain render with SDL_gpu textures on D3D12 |
| Integration (manual) | macOS build Metal | Visible textured render output | Character model with textures on Metal |

---

## Dev Notes

### Context: Why This Story Exists

Stories 4.3.1 and 4.3.2 established the SDL_gpu rendering backend with correct geometry pipelines, vertex upload, shaders, and fog uniforms. However, the `TextureRegistry` in `MuRendererSDLGpu.cpp` currently only contains the single white 1×1 fallback texture (`textureId=0`). All draw calls that bind any other `textureId` fall through to the white texture fallback — meaning the game renders untextured white quads for all world geometry, UI, and models.

This story migrates the texture _upload_ path: `CGlobalBitmap::OpenJpegTurbo` and `OpenTga` now create SDL_gpu textures instead of (or in addition to, guarded by `#ifdef`) OpenGL textures, and register them in the `TextureRegistry`. After this story, all ~30,000 indexed textures will be available to the SDL_gpu render path — completing the rendering pipeline migration.

### Key Design: SDL_gpu Device Access from GlobalBitmap.cpp

`GlobalBitmap.cpp` is in the `MUData` CMake target. `MuRendererSDLGpu.cpp` is in the `MURenderFX` target. `MUData` does NOT depend on `MURenderFX` (Data does not depend on rendering — this is the existing layering).

**Problem:** `CGlobalBitmap::OpenJpegTurbo` needs an `SDL_GPUDevice*` to upload textures. Exposing `s_device` directly would create a circular or layering violation.

**Solution:** Expose a `GetSDLDevice()` accessor in the `mu::` namespace from `MuRendererSDLGpu.cpp`. This is similar to how `RegisterTexture`/`UnregisterTexture` are already exposed in the `mu::` namespace. The `MURenderFX` target already links against `MUData` (for `CGlobalBitmap`, `LoadData` etc.), so `MUData` cannot directly depend on `MURenderFX`. Instead:

Option A: Add `GetSDLDevice()` as a free function in `mu::` namespace declared in `MuRenderer.h` (or a new thin header `MuRendererSDLGpu.h`), implemented in `MuRendererSDLGpu.cpp`. `GlobalBitmap.cpp` calls it through the renderer header. Since `MURenderFX` links into `Main` before `MUData` is used, the linker resolves the symbol.

Option B: Use the existing `GetRenderer()` factory and add a virtual `SDL_GPUDevice* GetDevice()` method to `IMuRenderer`. The OpenGL backend returns `nullptr`. `GlobalBitmap.cpp` calls `mu::GetRenderer().GetDevice()`.

**Recommended:** Option B — no new header needed, cleaner abstraction. Add `virtual SDL_GPUDevice* GetDevice() { return nullptr; }` to `IMuRenderer` (non-pure, default returns nullptr so the OpenGL backend doesn't break). `MuRendererSDLGpu` overrides to return `s_device`. `GlobalBitmap.cpp` calls `mu::GetRenderer().GetDevice()`. Add `[[nodiscard]]` to the interface method. Forward-declare `struct SDL_GPUDevice;` in `MuRenderer.h` under `#ifdef MU_ENABLE_SDL3` to avoid pulling in SDL3 in `MuRenderer.h` unconditionally.

> **Note:** This requires including `MuRenderer.h` in `GlobalBitmap.cpp` — acceptable since `GlobalBitmap.cpp` already includes `stdafx.h` which includes OpenGL headers, and `MuRenderer.h` is a clean C++20 header with no circular dependency risk.

### Key Design: Sampler Strategy (Per-Texture vs. Shared)

The OpenGL API allows per-call sampler state via `glTexParameteri`. SDL_gpu requires an explicit `SDL_GPUSampler` object.

**Option A: Per-texture sampler** — each `BITMAP_t` stores its own `SDL_GPUSampler*`. Created at load time with the `uiFilter`/`uiWrapMode` parameters. Released at unload. Simple, but uses more GPU memory for samplers (1 sampler object per texture).

**Option B: Shared sampler pool** — a small set of `SDL_GPUSampler*` objects (one per `{filter × wrap}` combination: `NEAREST×CLAMP`, `LINEAR×CLAMP`, `NEAREST×REPEAT`, `LINEAR×REPEAT` = 4 total). Stored as statics in `MuRendererSDLGpu.cpp` or `GlobalBitmap.cpp`. Looked up at draw call time.

**Recommended:** Option A (per-texture sampler). Simpler to implement correctly. SDL_gpu samplers are lightweight objects — 30,000 textures × 4 combinations = at most 30,000 sampler objects (most share `NEAREST×CLAMP`). GPU memory impact is negligible. Eliminates lookup overhead. Matches the 1:1 texture/sampler approach used in stories 4.3.1 (white texture) and common SDL_gpu examples.

Store the sampler in `BITMAP_t::sdlSampler`. Bind at draw call time in `RenderQuad2D`/`RenderTriangles`/`RenderQuadStrip` by extending the `TextureRegistry` to also return the sampler, OR by adding a parallel `SamplerRegistry`. Simpler: extend `BITMAP_t` in `GlobalBitmap.h` and expose a `LookupSampler(uint32_t id)` function alongside `LookupTexture`, storing `SDL_GPUSampler*` in a parallel map in `MuRendererSDLGpu.cpp`.

**Decision:** Add `mu::RegisterSampler(id, sampler)`, `mu::LookupSampler(id)`, `mu::UnregisterSampler(id)` alongside the existing texture registry functions. Bind sampler in draw calls: `samplerBinding.sampler = static_cast<SDL_GPUSampler*>(mu::LookupSampler(textureId))`.

### Key Design: Copy Command Buffer for Texture Upload

SDL_gpu texture upload requires a copy command buffer (separate from the render command buffer). The `UploadTextureSDLGpu` helper will:
1. `SDL_GPUCommandBuffer* copyCmd = SDL_AcquireGPUCommandBuffer(device)`
2. `SDL_GPUCopyPass* copyPass = SDL_BeginGPUCopyPass(copyCmd)`
3. Create transfer buffer, map, copy data, unmap
4. `SDL_UploadToGPUTexture(copyPass, &srcInfo, &dstRegion, false)`
5. `SDL_EndGPUCopyPass(copyPass)`
6. `SDL_SubmitGPUCommandBuffer(copyCmd)` — synchronous submit (wait for GPU to complete)

This is a synchronous pattern: texture loading happens during scene transitions and asset loading screens, not during the render loop. Synchronous upload is acceptable. The game's existing asset loading is not async — `LoadBitmap` is called synchronously.

### Key Design: BITMAP_t::sdlTexture Forward Declaration Issue

`GlobalBitmap.h` is included by many files (via `stdafx.h` or directly). Adding `SDL_GPUTexture* sdlTexture` to `BITMAP_t` risks pulling in SDL3 headers in every translation unit.

**Solution:** Use forward declarations inside `#ifdef MU_ENABLE_SDL3`:
```cpp
#ifdef MU_ENABLE_SDL3
struct SDL_GPUTexture;
struct SDL_GPUSampler;
#endif
```

These are forward-declared in `BITMAP_t` struct — the struct stores pointers, so forward declarations are sufficient. No `<SDL3/SDL_gpu.h>` in `GlobalBitmap.h`.

### Vertex Layouts and Texture ID Passing

Draw calls in `ZzzOpenglUtil.cpp` and `ZzzBMD.cpp` use `Bitmaps[idx].TextureNumber` to bind textures (e.g., `glBindTexture(GL_TEXTURE_2D, Bitmaps[idx].TextureNumber)`). After story 4.2.2 (MuRenderer migration), these calls were replaced with `mu::GetRenderer().RenderQuad2D(vertices, textureId)` where `textureId = Bitmaps[idx].BitmapIndex` (the CGlobalBitmap index, not the GL texture number).

This story does NOT change draw call sites. The `textureId` passed to `RenderQuad2D`/`RenderTriangles`/`RenderQuadStrip` is already the `BitmapIndex` — this matches what `RegisterTexture(uiBitmapIndex, ...)` registers. No call-site changes needed.

### BITMAP_t::BitmapIndex vs BitmapIndex (Load vs. Cache)

In `CGlobalBitmap::LoadImage`, the `uiBitmapIndex` parameter becomes `pBitmap->BitmapIndex`. This is the canonical ID for `RegisterTexture`. Verify in `OpenJpegTurbo` / `OpenTga`: the bitmap is not yet inserted in `m_mapBitmap` when `UploadTextureSDLGpu` is called — the `unique_ptr` is still live. So `RegisterTexture(uiBitmapIndex, pBitmap->sdlTexture)` is called BEFORE the `std::move` invalidates `pNewBitmap`, OR the raw pointer is captured before the move. Both work; prefer capturing the raw pointer before the move.

### Previous Story Intelligence

**From Story 4.3.2 (Shader Programs):**
- Quality gate baseline: **707 C++ files**, 0 errors. This story adds 1 test file → 708 files expected.
- `MuRendererSDLGpu.cpp` is now 1900 lines (post 4.3.2 restructuring). `GetSDLDevice()` is a small addition.
- `TextureRegistry` functions (`RegisterTexture`, `UnregisterTexture`, `LookupTexture`, `ClearTextureRegistry`) are already implemented in the `mu::` namespace in `MuRendererSDLGpu.cpp`. This story extends the pattern with `RegisterSampler`/`LookupSampler`/`UnregisterSampler`.
- Draw calls in `RenderQuad2D` currently use `LookupTexture(textureId)` returning `s_whiteTexture` for all IDs > 0 (no real textures registered yet). After this story, they will resolve to actual texture objects.
- `s_pipelines2D`/`s_pipelines3D` use fixed samplers (baked at pipeline creation time in 4.3.1). Per-texture samplers must be bound via `SDL_BindGPUFragmentSamplers` at draw time. Current code in `RenderQuad2D` hardcodes `samplerBinding.sampler = s_defaultSampler` or similar — check and update to use `mu::LookupSampler(textureId)`.
- `MURenderFX` links against `MUData` (for `CGlobalBitmap` usage) — no layering change needed for Option B device accessor.

**From Story 4.3.1 (SDL_gpu Backend):**
- White 1×1 texture is registered as `textureId=0`: `RegisterTexture(0u, s_whiteTexture)`. This convention is the fallback for unknown IDs — preserve it.
- `SDL_GPUTextureCreateInfo` fields: `type = SDL_GPU_TEXTURETYPE_2D`, `format`, `width`, `height`, `layer_count_or_depth = 1`, `num_levels = 1`, `usage = SDL_GPU_TEXTUREUSAGE_SAMPLER`.

**Git Intelligence:**
- Last 5 commits: story 4.3.2 pipeline (code-review-finalize, done, session summary). Current branch: `main`.
- This story follows the same pipeline: create-story (now) → atdd → dev-story → code-review.

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, SDL3 (FetchContent), libturbojpeg 3.1.3, Catch2 3.7.1, `MUData` CMake target (GlobalBitmap.cpp), `MURenderFX` CMake target (MuRendererSDLGpu.cpp)

**Prohibited (per project-context.md):**
- `new`/`delete` — use `std::vector` for pixel buffers (already used in existing code)
- `NULL` — use `nullptr`
- `wprintf`, `__TraceF()`, `DebugAngel` — use `g_ErrorReport.Write(L"ASSET: ...")`
- `#ifdef _WIN32` in `GlobalBitmap.cpp` or any new game logic file — use `MU_ENABLE_SDL3` guards
- OpenGL types in new SDL_gpu code (except existing `GLuint` members kept for OpenGL path compatibility)
- `#ifndef` header guards — `#pragma once` only (for any new .h files)
- Raw OpenGL calls outside `#ifndef MU_ENABLE_SDL3` guards in `GlobalBitmap.cpp`
- Exceptions in texture loading — return `false` on failure

**Required patterns (per project-context.md):**
- `[[nodiscard]]` on `UploadTextureSDLGpu`, `MapGLFilterToSDL`, `MapGLWrapToSDL`, `PadRGBToRGBA`, `GetDevice()` override
- `std::vector<std::uint8_t>` for pixel buffers — no raw `new uint8_t[]`
- `mu::` namespace for new public symbols (registry functions, device accessor)
- Allman brace style, 4-space indent, 120-column limit (`.clang-format`)
- `#pragma once` in any new `.h` files (e.g., `MuRendererSDLGpu.h` if created)
- Include order: preserve existing (`SortIncludes: Never`)
- `g_ErrorReport.Write(L"ASSET: texture upload -- ...")` for all SDL_gpu failure paths
- `std::ifstream`/`std::ofstream` not Win32 `CreateFile`/`ReadFile` (already correct in `OpenJpegTurbo`/`OpenTga`)
- `std::filesystem::path` for any new path construction (existing code uses `NarrowPath` helper — keep as-is)
- No new `SAFE_DELETE`/`SAFE_DELETE_ARRAY` — smart pointers already used in `CGlobalBitmap` (`std::unique_ptr<BITMAP_t>`)

**Quality gate:** `./ctl check` (macOS) — must pass 0 errors. File count: **708 C++ files** (707 baseline post-4.3.2, +1 test file).

**Testing:** Catch2 `TEST_CASE` / `SECTION` / `REQUIRE` / `CHECK`. No mocking framework. Free functions for unit-testable format mapping logic. Static helpers in anonymous namespace of `GlobalBitmap.cpp`, forward-declared for test TU.

### Project Structure Notes

**Files to create:**

| File | Notes |
|------|-------|
| `MuMain/tests/render/test_texturesystemmigration.cpp` | Catch2 tests — registry roundtrip, format mapping, RGB→RGBA8 padding |

**Files to modify:**

| File | Change |
|------|--------|
| `MuMain/src/source/Data/GlobalBitmap.h` | Add `SDL_GPUTexture*`/`SDL_GPUSampler*` members to `BITMAP_t` under `#ifdef MU_ENABLE_SDL3` guard; forward declarations |
| `MuMain/src/source/Data/GlobalBitmap.cpp` | Add `MapGLFilterToSDL`, `MapGLWrapToSDL`, `PadRGBToRGBA`, `UploadTextureSDLGpu` helpers; guard GL calls in `OpenJpegTurbo`/`OpenTga`/`UnloadImage`; add SDL_gpu upload and `RegisterTexture` calls |
| `MuMain/src/source/RenderFX/MuRenderer.h` | Add `virtual SDL_GPUDevice* GetDevice()` to `IMuRenderer` (default returns `nullptr`); forward-declare `struct SDL_GPUDevice` under `#ifdef MU_ENABLE_SDL3` |
| `MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp` | Override `GetDevice()` returning `s_device`; add `RegisterSampler`/`LookupSampler`/`UnregisterSampler` functions; update draw calls to bind per-texture sampler via `LookupSampler(textureId)` |
| `MuMain/tests/CMakeLists.txt` | Add `target_sources(MuTests PRIVATE render/test_texturesystemmigration.cpp)` with story comment |

**CMake targets:** `MUData` auto-globs `Data/*.cpp`, so `GlobalBitmap.cpp` changes are auto-picked up. `MURenderFX` auto-globs `RenderFX/*.cpp`. No CMake changes needed for source discovery. `MURenderFX` already depends on `SDL3::SDL3`.

**No new CMake targets or new source files in the source tree** (only 1 new test file).

### References

- [Source: `_bmad-output/project-context.md` — C++ Language Rules, CMake Module Targets, Testing Rules]
- [Source: `docs/development-standards.md` — §1 Cross-Platform rules, §2 C++ Conventions, §6 Git workflow]
- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 4, Story 4.4.1 spec, AC-1 through AC-6 and AC-STD-*]
- [Source: `_bmad-output/stories/4-3-2-shader-programs/story.md` — Dev Notes on TextureRegistry, pipeline sampler binding, file count baseline, project structure patterns]
- [Source: `_bmad-output/stories/4-3-1-sdlgpu-backend/story.md` — TextureRegistry implementation, white texture registration, `SDL_GPUTextureCreateInfo` fields]
- [Source: `MuMain/src/source/Data/GlobalBitmap.h` — `BITMAP_t` struct, `CGlobalBitmap` class interface, `CBitmapCache`]
- [Source: `MuMain/src/source/Data/GlobalBitmap.cpp` — Current `OpenJpegTurbo` (RGB, libturbojpeg), `OpenTga` (RGBA, OZT decode), `UnloadImage` (glDeleteTextures), GL texture call sites at lines 681-695, 776-792, 444]
- [Source: `MuMain/src/source/RenderFX/MuRenderer.h` — `IMuRenderer` interface, `GetRenderer()`, `Vertex2D`/`Vertex3D` structs]
- [Source: `MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp` — `RegisterTexture`/`LookupTexture`/`UnregisterTexture` free functions (lines ~275-308); `RenderQuad2D`/`RenderTriangles`/`RenderQuadStrip` sampler binding; `s_device` static; 1900 lines total]
- [Source: `MuMain/tests/CMakeLists.txt` — `target_sources` convention, story comment format]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

PCC create-story workflow completed. SAFe metadata and AC-STD-* sections included. Story type: infrastructure. No frontend/UI work. No API contracts. Specification corpus not available (no specification-index.yaml). Story partials not available. Predecessor story 4.3.2 fully analyzed: TextureRegistry pattern established, sampler binding identified as needing per-texture sampler registry extension. Architecture decision documented for SDL_gpu device accessor (Option B: IMuRenderer::GetDevice() virtual method). Sampler strategy documented (per-texture, Option A). Copy command buffer pattern for async upload documented. BITMAP_t forward declaration strategy documented. RGB→RGBA8 padding requirement identified. GL enum values documented for mapping functions. Current baseline: 707 C++ files (pre-story). Expected post-story: 708 C++ files.

### File List

