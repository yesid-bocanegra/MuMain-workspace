# ATDD Checklist — Story 7.9.6: Migrate All Raw OpenGL Calls to MuRenderer

**Story ID**: 7-9-6
**Story Type**: infrastructure
**Flow Code**: VS0-RENDER-GL-MIGRATE
**ATDD Phase**: RED (tests generated, awaiting implementation)
**Test File**: `MuMain/tests/render/test_gl_migration_7_9_6.cpp`
**Date Generated**: 2026-03-31

---

## PCC Compliance Summary

| Check | Status | Notes |
|-------|--------|-------|
| Project guidelines loaded | ✅ | `_bmad-output/project-context.md` loaded |
| Development standards loaded | ✅ | `docs/development-standards.md` referenced |
| Prohibited libraries check | ✅ | No prohibited libraries used |
| Testing framework | ✅ | Catch2 v3.7.1 (project-required) |
| No Win32 API in tests | ✅ | File-scan tests guarded `#ifndef _WIN32` |
| No mock framework | ✅ | Inline capture mock only |
| No OpenGL headers in test TU | ✅ | Only `MuRenderer.h` + Catch2 |
| `MU_SOURCE_DIR` injection | ✅ | Already injected by Story 7.9.3 CMake entry |
| CMakeLists.txt registration | ✅ | Added after 7-9-2 entry |
| AC-N: prefix pattern | ✅ | All TEST_CASEs use `"AC-N [7-9-6]: ..."` |

---

## Test Levels Selected

| Level | Included | Rationale |
|-------|----------|-----------|
| Unit (interface mock) | ✅ | IMuRenderer API contract tests — compile-time RED phase |
| Integration (file-scan) | ✅ | AC-1, AC-2, AC-9 — grep source for zero GL calls |
| E2E | ❌ | Infrastructure story — no user-facing flows |
| API Collection (Bruno) | ❌ | No REST endpoints |

---

## AC → Test Method Mapping

### AC-1: Zero gl* calls outside stdafx.h / MuRendererSDLGpu.cpp

| Test | Method | Type | Status |
|------|--------|------|--------|
| `"AC-1 [7-9-6]: Zero raw gl* calls outside stdafx.h and MuRendererSDLGpu.cpp"` | `SECTION("No gl* calls in ZzzOpenglUtil.cpp outside include guards (post-migration)")` | File-scan / Integration | `[ ]` |
| `"AC-1 [7-9-6]: ..."` | `SECTION("No gl* calls in ShadowVolume.cpp (stencil shadow migration)")` | File-scan / Integration | `[ ]` |

**Verification command**: `grep -rn 'gl[A-Z]' src/source/ --include='*.cpp' | grep -v stdafx.h | grep -v MuRendererSDLGpu.cpp`
**Expected post-migration**: zero results

### AC-2: stdafx.h GL stubs section deleted entirely

| Test | Method | Type | Status |
|------|--------|------|--------|
| `"AC-2 [7-9-6]: stdafx.h contains no inline GL function stubs after migration"` | `SECTION("No inline GL stub definitions in stdafx.h")` | File-scan / Integration | `[ ]` |

**Verification command**: `grep -c 'inline.*gl[A-Z]' src/source/Main/stdafx.h`
**Expected post-migration**: 0

### AC-3: SetClearColor replaces glClearColor (19 call sites)

| Test | Method | Type | Status |
|------|--------|------|--------|
| `"AC-3 [7-9-6]: SetClearColor is callable on IMuRenderer"` | `SECTION("SetClearColor records RGBA values")` | Unit / Interface | `[ ]` |
| | `SECTION("SetClearColor with pure black (alpha = 1.0)")` | Unit / Interface | `[ ]` |
| | `SECTION("SetClearColor called multiple times per scene — last call wins")` | Unit / Interface | `[ ]` |
| | `SECTION("SetClearColor accepts float-normalized [0, 1] range values")` | Unit / Interface | `[ ]` |

**New method required**: `virtual void SetClearColor(float r, float g, float b, float a) {}`
**Call sites**: SceneManager.cpp (11), MainScene.cpp (3), LoginScene.cpp (2), CharacterScene.cpp (2), GMHellas.cpp (1) = 19 total

### AC-4: Matrix stack API replaces glPushMatrix/glPopMatrix/etc. (82 call sites, 15 files)

| Test | Method | Type | Status |
|------|--------|------|--------|
| `"AC-4 [7-9-6]: Matrix stack methods are callable on IMuRenderer"` | `SECTION("PushMatrix and PopMatrix are callable in matched pairs")` | Unit / Interface | `[ ]` |
| | `SECTION("Multiple PushMatrix/PopMatrix pairs are independent")` | Unit / Interface | `[ ]` |
| | `SECTION("LoadIdentity resets current matrix")` | Unit / Interface | `[ ]` |
| | `SECTION("SetMatrixMode captures mode value")` | Unit / Interface | `[ ]` |
| | `SECTION("Translate captures all three components")` | Unit / Interface | `[ ]` |
| | `SECTION("Rotate captures angle and axis")` | Unit / Interface | `[ ]` |
| | `SECTION("Scale captures all three axis scales")` | Unit / Interface | `[ ]` |
| | `SECTION("MultMatrix captures the 16-element column-major matrix")` | Unit / Interface | `[ ]` |
| | `SECTION("LoadMatrix captures the 16-element column-major matrix")` | Unit / Interface | `[ ]` |
| | `SECTION("GetMatrix captures mode and writes back matrix data")` | Unit / Interface | `[ ]` |
| | `SECTION("Typical 3D object transform sequence: SetMatrixMode, PushMatrix, Translate+Rotate, PopMatrix")` | Unit / Interface | `[ ]` |

**New methods required** (all `virtual void` with default no-op `{}`):
- `SetMatrixMode(int mode)`
- `PushMatrix()`
- `PopMatrix()`
- `LoadIdentity()`
- `Translate(float x, float y, float z)`
- `Rotate(float angle, float x, float y, float z)`
- `Scale(float x, float y, float z)`
- `MultMatrix(const float* m)`
- `LoadMatrix(const float* m)`
- `GetMatrix(int mode, float* m)`

### AC-5: Texture state API (BindTexture/SetTexture2D pre-existing; glTexParameteri/glTexEnvi → SDL GPU upload)

| Test | Method | Type | Status |
|------|--------|------|--------|
| `"AC-5 [7-9-6]: Texture API BindTexture and SetTexture2D are callable"` | `SECTION("BindTexture is callable on IMuRenderer (pre-existing method)")` | Unit / Interface | `[ ]` |
| | `SECTION("SetTexture2D is callable on IMuRenderer (pre-existing method)")` | Unit / Interface | `[ ]` |
| | `SECTION("glTexParameteri migration note: handled at SDL GPU upload time")` | Documentation | `[ ]` |

**Pre-existing methods**: `BindTexture(int)`, `SetTexture2D(bool)` — no new methods needed
**glTexParameteri**: handled at SDL GPU texture upload time in GlobalBitmap.cpp
**glTexEnvi/glTexEnvf**: texture environment modes → shader state (no new method)

### AC-6: Depth/stencil/viewport API (17+ call sites)

| Test | Method | Type | Status |
|------|--------|------|--------|
| `"AC-6 [7-9-6]: Depth/stencil/viewport API methods are callable on IMuRenderer"` | `SECTION("SetDepthFunc captures function enum value")` | Unit / Interface | `[ ]` |
| | `SECTION("SetAlphaFunc captures function and reference threshold")` | Unit / Interface | `[ ]` |
| | `SECTION("SetStencilFunc captures all three parameters")` | Unit / Interface | `[ ]` |
| | `SECTION("SetStencilOp captures fail/depth-fail/depth-pass operations")` | Unit / Interface | `[ ]` |
| | `SECTION("SetColorMask captures per-channel boolean flags")` | Unit / Interface | `[ ]` |
| | `SECTION("SetColorMask with all channels enabled (restore after stencil pass)")` | Unit / Interface | `[ ]` |
| | `SECTION("SetViewport captures all four parameters")` | Unit / Interface | `[ ]` |
| | `SECTION("SetScissor captures rect parameters")` | Unit / Interface | `[ ]` |
| | `SECTION("SetScissorEnabled captures boolean state")` | Unit / Interface | `[ ]` |
| | `SECTION("Shadow volume stencil render sequence (ShadowVolume.cpp pattern)")` | Unit / Behavioral | `[ ]` |

**New methods required** (all `virtual void` with default no-op `{}`):
- `SetDepthFunc(int func)`
- `SetAlphaFunc(int func, float ref)`
- `SetStencilFunc(int func, int ref, unsigned int mask)`
- `SetStencilOp(int sfail, int dpfail, int dppass)`
- `SetColorMask(bool r, bool g, bool b, bool a)`
- `SetViewport(int x, int y, int w, int h)`
- `SetScissor(int x, int y, int w, int h)`
- `SetScissorEnabled(bool enabled)`

### AC-7: ReadPixels replaces glReadPixels (3 call sites, screenshot)

| Test | Method | Type | Status |
|------|--------|------|--------|
| `"AC-7 [7-9-6]: ReadPixels is callable on IMuRenderer (replaces glReadPixels)"` | `SECTION("ReadPixels captures all parameters (fullscreen screenshot)")` | Unit / Interface | `[ ]` |
| | `SECTION("ReadPixels with offset origin (partial capture)")` | Unit / Interface | `[ ]` |
| | `SECTION("ReadPixels accepts nullptr data without crash (degenerate case)")` | Unit / Robustness | `[ ]` |

**New method required**: `virtual void ReadPixels(int x, int y, int w, int h, void* data) {}`
**SDL3 replacement**: `SDL_GPUDownloadFromGPUTexture` or `SDL_RenderReadPixels`

### AC-8: GetGPUDriverName replaces glGetString (4 call sites)

| Test | Method | Type | Status |
|------|--------|------|--------|
| `"AC-8 [7-9-6]: GetGPUDriverName provides GPU info (replaces glGetString)"` | `SECTION("GetGPUDriverName is callable and returns non-null string")` | Unit / Interface | `[ ]` |
| | `SECTION("GetGPUDriverName default returns 'unknown' (OpenGL/mock backends)")` | Unit / Behavioral | `[ ]` |
| | `SECTION("GetGPUDriverName is const — callable on const IMuRenderer reference")` | Unit / Const-correctness | `[ ]` |

**Pre-existing method**: `GetGPUDriverName()` already on IMuRenderer (Story 7-6-7 AC-3)
**No new method needed**: call sites just need to call `mu::GetRenderer().GetGPUDriverName()`

### AC-9: Dead WGL/extension calls deleted (13 call sites, 2 files)

| Test | Method | Type | Status |
|------|--------|------|--------|
| `"AC-9 [7-9-6]: Dead WGL/extension function calls are deleted"` | `SECTION("No wglGetProcAddress calls in source files (13 WGL call sites deleted)")` | File-scan / Integration | `[ ]` |

**Deleted calls**: `wglGetProcAddress`, `glSwapIntervalEXT`, `glGetExtensionsStringARB/EXT`, `glChoosePixelFormatARB`, `glGetCurrentDC`, `glGetSwapIntervalEXT`
**Files**: primarily `ZzzBMD.cpp` and `ZzzOpenglUtil.cpp`

### AC-10: Visual verification (manual only)

| Test | Method | Type | Status |
|------|--------|------|--------|
| Login scene renders correctly | Manual: run game, verify background + UI | Visual / Manual | `[ ]` |
| Character scene renders correctly | Manual: verify 3D character model | Visual / Manual | `[ ]` |
| Main scene renders correctly | Manual: verify terrain + objects + effects | Visual / Manual | `[ ]` |
| Blend modes work | Manual: verify transparency + glow effects | Visual / Manual | `[ ]` |
| Fog renders correctly | Manual: verify fog distance gradient | Visual / Manual | `[ ]` |

**Note**: AC-10 cannot be automated — requires running the SDL3 GPU backend on a physical device.

### AC-STD-1 / AC-STD-13: Quality Gate

| Test | Method | Type | Status |
|------|--------|------|--------|
| Interface completeness check | `"AC-STD-1 [7-9-6]: IMuRenderer extended interface — all 7-9-6 methods callable"` | Unit / Compile-time | `[ ]` |
| Non-regression: pre-existing methods | `SECTION("Pre-existing IMuRenderer methods remain callable (non-regression)")` | Unit / Non-regression | `[ ]` |
| No GL types in interface | `SECTION("IMuRenderer 7-9-6 methods have no OpenGL types in their signatures")` | Unit / Compile-time | `[ ]` |
| Quality gate passes | `./ctl check` (clang-format + cppcheck, 0 errors) | CI / Quality Gate | `[ ]` |

---

## Implementation Checklist

### IMuRenderer Interface Extensions (MuRenderer.h)

- [ ] `SetClearColor(float r, float g, float b, float a)` — default no-op `{}`
- [ ] `SetMatrixMode(int mode)` — default no-op `{}`
- [ ] `PushMatrix()` — default no-op `{}`
- [ ] `PopMatrix()` — default no-op `{}`
- [ ] `LoadIdentity()` — default no-op `{}`
- [ ] `Translate(float x, float y, float z)` — default no-op `{}`
- [ ] `Rotate(float angle, float x, float y, float z)` — default no-op `{}`
- [ ] `Scale(float x, float y, float z)` — default no-op `{}`
- [ ] `MultMatrix(const float* m)` — default no-op `{}`
- [ ] `LoadMatrix(const float* m)` — default no-op `{}`
- [ ] `GetMatrix(int mode, float* m)` — default no-op `{}`
- [ ] `SetDepthFunc(int func)` — default no-op `{}`
- [ ] `SetAlphaFunc(int func, float ref)` — default no-op `{}`
- [ ] `SetStencilFunc(int func, int ref, unsigned int mask)` — default no-op `{}`
- [ ] `SetStencilOp(int sfail, int dpfail, int dppass)` — default no-op `{}`
- [ ] `SetColorMask(bool r, bool g, bool b, bool a)` — default no-op `{}`
- [ ] `SetViewport(int x, int y, int w, int h)` — default no-op `{}`
- [ ] `SetScissor(int x, int y, int w, int h)` — default no-op `{}`
- [ ] `SetScissorEnabled(bool enabled)` — default no-op `{}`
- [ ] `ReadPixels(int x, int y, int w, int h, void* data)` — default no-op `{}`

### SDL GPU Backend Implementation (MuRendererSDLGpu.cpp)

- [ ] `SetClearColor`: store RGBA, apply in `SDL_GPURenderPassColorTargetInfo.clear_color` in `BeginFrame()`
- [ ] `SetMatrixMode`: switch between modelview/projection matrix stacks
- [ ] `PushMatrix` / `PopMatrix` / `LoadIdentity`: route to internal `mu::MatrixStack` member
- [ ] `Translate` / `Rotate` / `Scale`: apply transform to top of active MatrixStack
- [ ] `MultMatrix` / `LoadMatrix` / `GetMatrix`: matrix data operations on active stack
- [ ] Upload matrix uniform buffer to GPU in each draw call (before RenderTriangles/RenderQuad2D)
- [ ] `SetDepthFunc`: map int → `SDL_GPUCompareOp`, update pipeline state cache
- [ ] `SetAlphaFunc`: map to fragment shader alpha test uniform or discard logic
- [ ] `SetStencilFunc` / `SetStencilOp`: map to `SDL_GPUStencilOpState`, rebuild pipeline
- [ ] `SetColorMask`: map to `SDL_GPUColorTargetDescription.color_write_mask`
- [ ] `SetViewport`: call `SDL_SetGPUViewport()` with current render pass
- [ ] `SetScissor` / `SetScissorEnabled`: call `SDL_SetGPUScissor()` / set `enable_scissor_test`
- [ ] `ReadPixels`: implement via `SDL_GPUDownloadFromGPUTexture` (async GPU read-back)

### Migration Call Sites (AC-1)

- [ ] `RenderFX/ZzzOpenglUtil.cpp` — 26 raw gl* calls → MuRenderer API
- [ ] `UI/Legacy/UIWindows.cpp` — 20 raw gl* calls → matrix + state methods
- [ ] `RenderFX/ShadowVolume.cpp` — 19 raw gl* calls → stencil API
- [ ] `ThirdParty/UIControls.cpp` — 17 raw gl* calls → state + matrix methods
- [ ] `RenderFX/ZzzBMD.cpp` — 17 raw gl* calls (excl. WGL) → matrix + state methods
- [ ] `Data/GlobalBitmap.cpp` — 14 raw gl* calls → already SDL3-guarded, migrate remaining
- [ ] `Scenes/SceneManager.cpp` — 11 raw gl* calls → SetClearColor + SetViewport
- [ ] `Scenes/SceneCommon.cpp` — 10 raw gl* calls → matrix + state methods
- [ ] `UI/Windows/.../NewUIRegistrationLuckyCoin.cpp` — 10 raw gl* calls → matrix methods
- [ ] `UI/Framework/NewUI3DRenderMng.cpp` — 10 raw gl* calls → matrix + state methods
- [ ] `UI/Events/NewUIGoldBowmanLena.cpp` — 10 raw gl* calls → matrix + state methods
- [ ] `GameShop/NewUIInGameShop.cpp` — 10 raw gl* calls → matrix + state methods
- [ ] `Scenes/MainScene.cpp` — 8 raw gl* calls → SetClearColor + state methods
- [ ] Remaining 22 files (1-5 calls each) — migrate to MuRenderer API

### Delete Dead Code (AC-2, AC-9)

- [ ] Delete WGL calls from `ZzzBMD.cpp` (13 sites): `wglGetProcAddress`, `glSwapIntervalEXT`, `glGetExtensionsString*`, `glChoosePixelFormatARB`, `glGetCurrentDC`, `glGetSwapIntervalEXT`
- [ ] Delete remaining `glBegin/glEnd` sites (should have been in 7-9-2, verify zero)
- [ ] Delete display list stubs if present
- [ ] Delete "OpenGL Constants" section from `stdafx.h` (GLenum defines, GL_* constants)
- [ ] Delete "OpenGL Function stubs" section from `stdafx.h` (~70 inline no-op functions)
- [ ] Verify build succeeds with no GL stubs — all calls route through MuRenderer

### PCC Compliance

- [ ] No prohibited libraries used (verified: Catch2 only, no OpenGL in test TU)
- [ ] All test methods use `AC-N:` prefix naming convention
- [ ] All new test methods use `GIVEN/WHEN/THEN` comment structure
- [ ] Catch2 `REQUIRE`/`CHECK` used (no raw asserts)
- [ ] `TEST_CASE` / `SECTION` structure used throughout
- [ ] No Win32 API calls in test TU (file-scan tests guarded `#ifndef _WIN32`)
- [ ] `MU_SOURCE_DIR` used for file-scan tests (already injected by CMake)
- [ ] Quality gate: `./ctl check` passes with 0 errors after implementation

---

## Output Summary

| Item | Value |
|------|-------|
| Story ID | 7-9-6 |
| Story type | infrastructure |
| Primary test level | Unit (interface mock) + Integration (file-scan) |
| Test file | `MuMain/tests/render/test_gl_migration_7_9_6.cpp` |
| Tests generated | 36 TEST_CASE sections (RED phase) |
| New IMuRenderer methods required | 20 |
| Pre-existing methods reused | 3 (`BindTexture`, `SetTexture2D`, `GetGPUDriverName`) |
| Methods with no new API needed | `glTexParameteri` (SDL GPU upload), `glTexEnvi` (shader state) |
| File-scan tests (AC-1, AC-2, AC-9) | 4 SECTION blocks, guarded `#ifndef _WIN32` |
| Visual-only ACs | AC-10 (manual) |
| AC-test mapping complete | ✅ |
| ATDD checklist path | `_bmad-output/stories/7-9-6-migrate-raw-gl-to-murenderer/atdd.md` |
