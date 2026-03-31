# Story 7.9.6: Migrate All Raw OpenGL Calls to MuRenderer

Status: ready-for-dev

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.9 - macOS Game Loop & Win32 Render Path Migration |
| Story ID | 7.9.6 |
| Story Points | 34 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-RENDER-GL-MIGRATE |
| FRs Covered | Zero raw OpenGL calls outside MuRendererSDLGpu.cpp — all rendering goes through IMuRenderer |
| Prerequisites | 7-9-2 (done), 7-9-5 (in-progress) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Migrate 250+ raw GL calls across 35 files to MuRenderer API; extend IMuRenderer with matrix, state, and texture methods; delete GL stubs from stdafx.h |
| project-docs | documentation | Story artifacts |

---

## Background

Story 7-9-2 migrated 83 draw call sites (glBegin/glEnd/glVertex → RenderQuad2D/RenderTriangles). What remains is 250+ raw OpenGL calls for state management, matrix operations, texture binding, and scene setup. These currently resolve to no-op stubs in `stdafx.h` — the game compiles and partially runs but rendering state is lost (blend modes, depth testing, fog, transforms, clear color all silently do nothing).

### Current State

- **35 files** contain raw GL calls
- **250+ call sites** total
- **stdafx.h** contains ~70 inline no-op stubs that swallow GL calls silently
- **MuRendererSDLGpu.cpp** is the only file that should contain SDL_gpu calls
- Some state calls already migrated: `SetBlendMode`, `SetDepthTest`, `SetDepthMask`, `SetCullFace`, `SetAlphaTest`, `SetTexture2D`, `SetFogEnabled`, `BindTexture`

### Call Site Inventory

| Category | Calls | Files | Description |
|----------|-------|-------|-------------|
| State enable/disable | 42 | 20 | `glEnable/glDisable` (GL_BLEND, GL_FOG, GL_ALPHA_TEST, GL_TEXTURE_2D, GL_CULL_FACE, GL_DEPTH_TEST, GL_STENCIL_TEST, GL_SCISSOR_TEST, GL_LIGHTING, GL_NORMALIZE, GL_COLOR_MATERIAL) |
| Clear color | 19 | 5 | `glClearColor` — per-map background colors |
| Clear buffers | 2 | 2 | `glClear(GL_COLOR_BUFFER_BIT \| GL_DEPTH_BUFFER_BIT)` |
| Matrix stack | 82 | 15 | `glMatrixMode`, `glPushMatrix`, `glPopMatrix`, `glLoadIdentity`, `glTranslatef`, `glRotatef`, `glScalef`, `glMultMatrixf`, `glLoadMatrixf` |
| Texture params | 12 | 2 | `glTexParameteri` — filter/wrap during loading |
| Texture bind | 9 | 5 | `glBindTexture` — active texture selection |
| Texture lifecycle | 5 | 2 | `glGenTextures`, `glDeleteTextures`, `glTexImage2D` — already SDL3-guarded in GlobalBitmap.cpp |
| Depth/stencil | 17 | 6 | `glDepthFunc`, `glDepthMask`, `glAlphaFunc`, `glStencilFunc`, `glStencilOp`, `glFrontFace`, `glColorMask` |
| Texture environment | 4 | 3 | `glTexEnvi`, `glTexEnvf` — multitexture blend modes |
| Fog | 0 | 0 | Already migrated via `SetFog` |
| Scene rendering | 5 | 3 | `glPolygonMode`, `glScissor`, `glViewport` |
| Color state | 0 | 0 | `glColor4f/glColor4ub` — vertex colors, handled by RenderQuad2D vertex data |
| System info | 4 | 1 | `glGetString` (GL_VENDOR, GL_RENDERER, GL_VERSION) |
| Screen capture | 3 | 1 | `glReadPixels` — screenshot functionality |
| WGL/extensions | 13 | 2 | `wglGetProcAddress`, `glSwapIntervalEXT`, `glGetExtensionsString*`, `glChoosePixelFormatARB` — dead on SDL3 |
| Display lists | 0 | 0 | `glNewList/glEndList/glCallList` — stubs only |
| Material/lighting | 0 | 0 | `glMaterialfv/glLightfv` — stubs only, not called |
| Immediate mode | 3 | 2 | `glBegin/glEnd/glVertex` — remaining unmigrated draw calls |

### Files by Call Count

| File | Calls | Category |
|------|-------|----------|
| `RenderFX/ZzzOpenglUtil.cpp` | 26 | Core rendering utilities |
| `UI/Legacy/UIWindows.cpp` | 20 | UI window rendering |
| `RenderFX/ShadowVolume.cpp` | 19 | Shadow volume stencil rendering |
| `ThirdParty/UIControls.cpp` | 17 | Text input, gauges, UI controls |
| `RenderFX/ZzzBMD.cpp` | 17 | 3D model rendering |
| `Data/GlobalBitmap.cpp` | 14 | Texture loading (already SDL3-guarded) |
| `Scenes/SceneManager.cpp` | 11 | Scene management |
| `Scenes/SceneCommon.cpp` | 10 | Shared scene code |
| `UI/Windows/.../NewUIRegistrationLuckyCoin.cpp` | 10 | Lottery UI |
| `UI/Framework/NewUI3DRenderMng.cpp` | 10 | 3D item preview in UI |
| `UI/Events/NewUIGoldBowmanLena.cpp` | 10 | Mini-game UI |
| `GameShop/NewUIInGameShop.cpp` | 10 | Cash shop UI |
| `Scenes/MainScene.cpp` | 8 | Main scene rendering |
| Remaining 22 files | 1-5 each | Various |

---

## Story

**[VS-0] [Flow:E]**

**As a** game client developer,
**I want** every raw OpenGL call migrated through MuRenderer,
**so that** all rendering works correctly on SDL3 GPU (Metal/Vulkan/D3D12) with no silent no-ops and no stubs — rendering state is actually applied.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** Zero `gl*` function calls exist outside `stdafx.h` stubs — `grep -rn 'gl[A-Z]' src/source/ --include='*.cpp' | grep -v stdafx.h | grep -v MuRendererSDLGpu.cpp` returns zero results.
- [ ] **AC-2:** `stdafx.h` GL stubs section deleted entirely — no inline GL function stubs remain.
- [ ] **AC-3:** All `glClearColor` calls replaced with `mu::GetRenderer().SetClearColor(r, g, b, a)`. SDL GPU backend applies clear color in `BeginFrame()`.
- [ ] **AC-4:** All matrix operations (`glPushMatrix/glPopMatrix/glTranslatef/glRotatef/glScalef/glLoadIdentity/glMatrixMode`) replaced with MuRenderer matrix stack API. SDL GPU backend passes transform matrices to shader uniforms.
- [ ] **AC-5:** All texture state calls (`glBindTexture/glTexParameteri/glTexEnvi`) replaced with MuRenderer texture API. SDL GPU backend manages samplers and texture binding per-draw.
- [ ] **AC-6:** All stencil/depth calls (`glDepthFunc/glStencilFunc/glStencilOp`) replaced with MuRenderer depth/stencil API.
- [ ] **AC-7:** `glReadPixels` replaced with SDL3 `SDL_RenderReadPixels` or `SDL_GPUDownloadFromGPUTexture` for screenshot functionality.
- [ ] **AC-8:** `glGetString` calls replaced with SDL3 `SDL_GetGPUDeviceDriver()` for system info logging.
- [ ] **AC-9:** Dead WGL/extension calls (13 sites) deleted.
- [ ] **AC-10:** Game renders correctly on SDL3 — login scene, character scene, and main scene display properly with correct blend modes, depth testing, fog, and transforms.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check`)

---

## Tasks / Subtasks

### Task 1: GL State Management Migration (AC: 1, 2)
- [ ] 1.1: Migrate remaining `glEnable/glDisable` calls (GL_LIGHTING, GL_NORMALIZE, GL_COLOR_MATERIAL, GL_STENCIL_TEST, GL_SCISSOR_TEST) to MuRenderer
- [ ] 1.2: Migrate `glAlphaFunc` → `mu::GetRenderer().SetAlphaFunc(func, ref)`
- [ ] 1.3: Migrate `glDepthFunc` → `mu::GetRenderer().SetDepthFunc(func)`
- [ ] 1.4: Migrate `glStencilFunc/glStencilOp/glFrontFace` → MuRenderer stencil API
- [ ] 1.5: Migrate `glColorMask` → `mu::GetRenderer().SetColorMask(r, g, b, a)`
- [ ] 1.6: Migrate `glPolygonMode` → `mu::GetRenderer().SetPolygonMode(mode)`
- [ ] 1.7: Migrate `glScissor` → `mu::GetRenderer().SetScissor(x, y, w, h)`
- [ ] 1.8: Migrate `glPointSize/glLineWidth` → MuRenderer line/point API

### Task 2: Clear Color Migration (AC: 3)
- [ ] 2.1: Add `SetClearColor(float r, float g, float b, float a)` to IMuRenderer
- [ ] 2.2: Implement in SDL GPU backend — store and apply in render pass begin
- [ ] 2.3: Replace all 19 `glClearColor` call sites in SceneManager.cpp, MainScene.cpp, LoginScene.cpp, CharacterScene.cpp, GMHellas.cpp

### Task 3: Matrix Stack Migration (AC: 4)
- [ ] 3.1: Add matrix stack API to IMuRenderer: `PushMatrix()`, `PopMatrix()`, `LoadIdentity()`, `Translate(x,y,z)`, `Rotate(angle,x,y,z)`, `Scale(x,y,z)`, `SetMatrixMode(mode)`
- [ ] 3.2: Implement matrix stack in SDL GPU backend — build transforms and upload to GPU via shader uniform buffer
- [ ] 3.3: Migrate 82 matrix call sites across 15 files

### Task 4: Texture State Migration (AC: 5)
- [ ] 4.1: Migrate remaining `glBindTexture` sites (9) — some already done
- [ ] 4.2: Migrate `glTexParameteri` — filter/wrap are set at upload time in SDL GPU
- [ ] 4.3: Migrate `glTexEnvi/glTexEnvf` — texture environment modes → shader state

### Task 5: Scene-Specific GL (AC: 6, 7, 8)
- [ ] 5.1: Migrate `ShadowVolume.cpp` (19 calls) — stencil shadow rendering via SDL GPU
- [ ] 5.2: Replace `glReadPixels` with SDL3 screenshot API
- [ ] 5.3: Replace `glGetString` with `SDL_GetGPUDeviceDriver()` in ErrorReport
- [ ] 5.4: Migrate `glViewport` → `mu::GetRenderer().SetViewport(x, y, w, h)`

### Task 6: Delete Dead Code (AC: 9)
- [ ] 6.1: Delete WGL calls: `wglGetProcAddress`, `glSwapIntervalEXT`, `glGetExtensionsString*`, `glChoosePixelFormatARB`, `glGetCurrentDC`, `glGetSwapIntervalEXT` (13 call sites)
- [ ] 6.2: Delete display list calls if unused
- [ ] 6.3: Delete remaining `glBegin/glEnd` sites (should have been migrated in 7-9-2)

### Task 7: UI GL Calls (AC: 1)
- [ ] 7.1: Migrate `UIWindows.cpp` (20 calls) — matrix push/pop for UI scaling
- [ ] 7.2: Migrate `UIControls.cpp` (17 calls) — text rendering GL state
- [ ] 7.3: Migrate `NewUI3DRenderMng.cpp` (10 calls) — 3D preview in UI panels
- [ ] 7.4: Migrate `NewUIGoldBowmanLena.cpp` (10 calls) — mini-game rendering
- [ ] 7.5: Migrate `NewUIInGameShop.cpp` (10 calls) — shop UI rendering
- [ ] 7.6: Migrate `NewUIRegistrationLuckyCoin.cpp` (10 calls) — lottery UI

### Task 8: Delete stdafx.h Stubs (AC: 2)
- [ ] 8.1: After all GL calls are migrated, delete the entire "OpenGL Constants" and "OpenGL Function stubs" sections from stdafx.h
- [ ] 8.2: Verify build with no GL stubs — all calls route through MuRenderer

### Task 9: Visual Verification (AC: 10)
- [ ] 9.1: Run game, verify login scene renders (background, UI elements)
- [ ] 9.2: Verify character scene renders (3D character model)
- [ ] 9.3: Verify main game scene renders (terrain, objects, effects)
- [ ] 9.4: Verify blend modes work (transparency, glow effects)
- [ ] 9.5: Verify fog renders correctly

---

## Dev Notes

### Migration Strategy

Each raw GL call falls into one of these patterns:

**Pattern A — State Flag (simple):** `glEnable(GL_FOG)` → `mu::GetRenderer().SetFogEnabled(true)`. The SDL GPU backend stores the flag and applies it when building the pipeline descriptor for the next draw call. Most enable/disable calls follow this pattern.

**Pattern B — Parametric State:** `glClearColor(r, g, b, a)` → `mu::GetRenderer().SetClearColor(r, g, b, a)`. The SDL GPU backend stores the color and uses it in `SDL_BeginGPURenderPass` as the clear color.

**Pattern C — Matrix Transform:** `glPushMatrix(); glTranslatef(x, y, z); ... glPopMatrix();` → `mu::GetRenderer().PushMatrix(); mu::GetRenderer().Translate(x, y, z); ... mu::GetRenderer().PopMatrix();`. MuRenderer builds the transform matrix and uploads it to the GPU as a shader uniform buffer — the GPU applies it per-vertex in the vertex shader, same as any modern renderer.

**Pattern D — Dead Code:** WGL extension functions, display lists — delete them.

**Pattern E — System API:** `glGetString`, `glReadPixels` — replace with SDL3 equivalents.

### MuRenderer API Extensions Needed

```cpp
// Clear color
virtual void SetClearColor(float r, float g, float b, float a) {}

// Matrix stack (builds transforms, uploads to GPU via uniform buffer)
virtual void SetMatrixMode(int mode) {}
virtual void PushMatrix() {}
virtual void PopMatrix() {}
virtual void LoadIdentity() {}
virtual void Translate(float x, float y, float z) {}
virtual void Rotate(float angle, float x, float y, float z) {}
virtual void Scale(float x, float y, float z) {}
virtual void MultMatrix(const float* m) {}
virtual void LoadMatrix(const float* m) {}
virtual void GetMatrix(int mode, float* m) {}

// Depth/stencil
virtual void SetDepthFunc(int func) {}
virtual void SetAlphaFunc(int func, float ref) {}
virtual void SetStencilFunc(int func, int ref, unsigned int mask) {}
virtual void SetStencilOp(int sfail, int dpfail, int dppass) {}
virtual void SetColorMask(bool r, bool g, bool b, bool a) {}

// Viewport/scissor
virtual void SetViewport(int x, int y, int w, int h) {}
virtual void SetScissor(int x, int y, int w, int h) {}
virtual void SetScissorEnabled(bool enabled) {}

// System
virtual void ReadPixels(int x, int y, int w, int h, void* data) {}
```

### References

- [Source: MuMain/src/source/Main/stdafx.h — GL stubs section]
- [Source: MuMain/src/source/RenderFX/MuRenderer.h — IMuRenderer interface]
- [Source: MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp — SDL GPU backend]
- [Source: docs/CROSS_PLATFORM_PLAN.md — Phase 2 sessions 2.3-2.9]

---

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
