# Story 7.9.2: OpenGL Immediate-Mode → MuRenderer Abstraction Migration

Status: validation-complete

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 7 - Stability, Diagnostics & Quality Gates |
| Feature | 7.9 - macOS Game Loop & Win32 Render Path Migration |
| Story ID | 7.9.2 |
| Story Points | 21 |
| Priority | P0 |
| Story Type | infrastructure |
| Value Stream | VS-0 |
| Flow Code | VS0-QUAL-RENDER-GLMIGRATE |
| FRs Covered | Game client must render ALL content (2D scenes, 3D world, effects) on macOS arm64 via the MuRenderer abstraction — no raw OpenGL in game code |
| Prerequisites | 7-9-1-macos-gameloop-render (done), 4-2-2-migrate-renderbitmap-quad2d (done), 4-3-1-sdlgpu-backend (done), 4-3-2-shader-programs (done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Route all 83 glBegin/glEnd sites (13 files) through IMuRenderer; route BeginOpengl/EndOpengl + BeginBitmap/EndBitmap through renderer; add IsFrameActive/Begin2DPass/End2DPass to IMuRenderer; port CSprite::Render to RenderQuad2D |
| project-docs | documentation | Story artifacts |

---

## Background

Story 7-9-1 wired `RenderScene()` into the SDL3 game loop, but every scene immediately crashes
on macOS because all rendering goes through raw OpenGL immediate-mode calls (`glBegin`/`glEnd`,
`glVertex*`, `glMatrixMode`, `glPushMatrix`, etc.) which are null function pointers on the
SDL3/Metal path.

### Scale of the Problem

| Category | Files | GL Sites | Impact |
|----------|-------|----------|--------|
| 2D Sprite/UI | Sprite.cpp, ZzzEffectMagicSkill.cpp | 3 | Title, loading, login screens broken |
| 2D Scene scaffolding | 8 scene files + SceneManager.cpp | 56 | Every scene crashes at entry |
| 3D Terrain/World | ZzzLodTerrain.cpp, CSWaterTerrain.cpp | 14 | Game world invisible |
| 3D Effects | ShadowVolume, SideHair, BlurSpark, MagicSkill, PhysicsManager | 12 | Combat effects missing |
| 3D Debug viz | CameraMove, ZzzObject, ZzzBMD | 4 | Debug tools only (low priority) |
| **Total** | **13 files** | **83 sites, 677 vertex calls** | **Game completely non-functional** |

### Design Principle: True Cross-Platform

**NO `#ifdef` in game code.** All rendering goes through `IMuRenderer` methods. The renderer
implementation (`MuRendererSDLGpu` or `MuRendererOpenGL`) handles the backend difference.
Game code calls the same API on all platforms.

The infrastructure already exists:
- `RenderQuad2D(Vertex2D[], textureId)` — for 2D screen-space quads
- `RenderTriangles(Vertex3D[], textureId)` — for 3D triangle lists
- `RenderQuadStrip(Vertex3D[], textureId)` — for 3D quad strips
- `SetBlendMode()`, `SetDepthTest()`, `SetFog()` — render state

What's missing:
1. **`BeginOpengl()`/`EndOpengl()`** call `glMatrixMode`/`glPushMatrix` directly → must route through renderer
2. **`BeginBitmap()`/`EndBitmap()`** call `gluOrtho2D` directly → must route through renderer
3. **`CSprite::Render()`** calls `glBegin(GL_TRIANGLE_FAN)` → must call `RenderQuad2D`
4. **All 83 `glBegin`/`glEnd` blocks** in 13 files → must call `RenderQuad2D`/`RenderTriangles`/`RenderQuadStrip`
5. **Frame lifecycle** — `RenderTitleSceneUI` is called outside the game loop (during `OpenBasicData`) and needs `IsFrameActive()` to manage `BeginFrame`/`EndFrame`
6. **`glClear()`** — handled by `BeginFrame()` in SDL_gpu; `glFlush()`/`SwapBuffers()` → handled by `EndFrame()`

> **Rule:** No `#ifdef _WIN32` or `#ifdef MU_ENABLE_SDL3` at call sites. Game code calls
> `IMuRenderer` methods unconditionally. `BeginOpengl()`, `BeginBitmap()`, `CSprite::Render()`,
> and all `glBegin`/`glEnd` blocks are rewritten to use the renderer API. The OpenGL backend
> (`MuRendererOpenGL` in `MuRenderer.cpp`) implements these as the current GL calls. The SDL_gpu
> backend (`MuRendererSDLGpu.cpp`) implements them as the SDL3 equivalents.

---

## Story

**[VS-0] [Flow:E]**

**As a** developer running the game client on macOS arm64,
**I want** all rendering (2D sprites, 3D terrain, effects, scenes) to go through the MuRenderer abstraction,
**so that** the game renders identically on all platforms without any platform-specific code in game logic.

---

## Functional Acceptance Criteria

- [ ] **AC-1: Route `BeginOpengl`/`EndOpengl` through IMuRenderer**
  Add `virtual void BeginScene(int x, int y, int w, int h)` and `virtual void EndScene()` to `IMuRenderer`.
  `BeginOpengl()` in `ZzzOpenglUtil.cpp` calls `mu::GetRenderer().BeginScene(x, y, w, h)`.
  `EndOpengl()` calls `mu::GetRenderer().EndScene()`.
  The OpenGL backend sets up projection/viewport/modelview matrices (current behavior).
  The SDL_gpu backend sets viewport and updates uniform buffers.

- [ ] **AC-2: Route `BeginBitmap`/`EndBitmap` through IMuRenderer**
  Add `virtual void Begin2DPass()` and `virtual void End2DPass()` to `IMuRenderer`.
  `BeginBitmap()` in `ZzzOpenglUtil.cpp` calls `mu::GetRenderer().Begin2DPass()`.
  `EndBitmap()` calls `mu::GetRenderer().End2DPass()`.
  The OpenGL backend sets up orthographic projection (current behavior).
  The SDL_gpu backend marks 2D mode (pipeline selection already handles ortho).

- [ ] **AC-3: Port `CSprite::Render()` to RenderQuad2D**
  `CSprite::Render()` builds `Vertex2D[4]` from sprite coordinates and calls
  `mu::GetRenderer().RenderQuad2D(vertices, textureId)` unconditionally. No `#ifdef`.
  Coordinate conversion: OpenGL bottom-up 640×480 → screen pixels via
  `x * (WindowWidth/640)`, `y = WindowHeight - y * (WindowHeight/480)`.
  Color packed as ABGR: `(alpha << 24) | (blue << 16) | (green << 8) | red`.
  The `glBegin`/`glEnd`/`glVertex2f` block is removed entirely.

- [ ] **AC-4: Port all 2D `glBegin`/`glEnd` blocks to RenderQuad2D**
  Every `glBegin(GL_TRIANGLE_FAN)`/`glBegin(GL_QUADS)` block that renders 2D screen-space
  geometry is replaced with `mu::GetRenderer().RenderQuad2D()`:
  - `ShadowVolume.cpp:96` — full-screen shadow overlay quad
  - `ZzzEffectMagicSkill.cpp:124` — `RenderCircle2D()` magic skill UI overlay
  - `SceneManager.cpp:436–478` — `RenderFrameGraph()` debug overlay bars
  All raw GL calls (`glVertex2f`, `glColor4ub`, `glTexCoord2f`) are removed from these sites.

- [ ] **AC-5: Port all 3D `glBegin`/`glEnd` blocks to RenderTriangles/RenderQuadStrip**
  Every `glBegin` block that renders 3D world-space geometry is replaced with
  `mu::GetRenderer().RenderTriangles()` or `RenderQuadStrip()`:
  - `ZzzLodTerrain.cpp` — 9 terrain rendering functions (`RenderFace`, `RenderFaceAlpha`, etc.)
  - `CSWaterTerrain.cpp` — 3 water rendering paths (base layer, overlay, face)
  - `ShadowVolume.cpp:314` — shadow volume mesh (`GL_TRIANGLES`)
  - `SideHair.cpp:142` — hair outline quads
  - `ZzzEffectBlurSpark.cpp` — 4 sites (motion blur fans, cloth flag quads)
  - `ZzzEffectMagicSkill.cpp:65` — `RenderCircle()` 3D magic circles
  - `PhysicsManager.cpp:833` — cloth simulation quads
  - `CameraMove.cpp:490` — waypoint gizmo quads + line strip
  - `ZzzObject.cpp:12240` — collision debug lines
  - `ZzzBMD.cpp:2480` — bounding box quads + skeleton debug lines
  - `ZzzOpenglUtil.cpp:915–1108` — `RenderBox3D`, `RenderPlane3D`, utility quads
  For `GL_LINES`/`GL_LINE_STRIP`, add `virtual void RenderLines(Vertex3D[], count)` to `IMuRenderer`.

- [ ] **AC-6: Add `IsFrameActive()` to IMuRenderer**
  `IMuRenderer` gains `virtual bool IsFrameActive() const { return false; }`.
  `MuRendererSDLGpu` overrides: returns `true` when `s_renderPass != nullptr`.
  `RenderTitleSceneUI()` uses this to self-manage `BeginFrame()`/`EndFrame()` when called
  from `OpenBasicData()` (outside the game loop).

- [ ] **AC-7: All scene entry points work without raw GL**
  These scenes render correctly on both OpenGL and SDL3 paths:
  - `WebzenScene()` — title/intro
  - `LoadingScene()` — map loading
  - `LoginScene()` — login screen
  - `CharacterScene()` — character creation
  - `MainScene()` — gameplay (terrain, effects, characters visible)
  - `RenderTitleSceneUI()` — loading progress during `OpenBasicData()`
  `glClear()` calls route through `BeginFrame()` (already handled).
  `glFlush()`/`SwapBuffers()` calls are removed (handled by `EndFrame()`).

- [ ] **AC-8: Zero raw GL calls remain in game code**
  After migration, `grep -rn "glBegin\|glEnd()\|glVertex\|glTexCoord\|glColor4\|glMatrixMode\|glPushMatrix\|glPopMatrix" src/source/` returns ONLY:
  - `MuRenderer.cpp` (OpenGL backend implementation)
  - `ZzzOpenglUtil.cpp` ONLY inside `BeginScene()`/`EndScene()`/`Begin2DPass()`/`End2DPass()` implementations
  - `stdafx.h` stubs (no-op shims)
  Zero raw GL calls in any scene, UI, effect, terrain, or model file.

- [ ] **AC-9: Quality gate passes**
  `./ctl check` exits 0 (build + tests + format-check + lint + tidy-gate).
  `python3 MuMain/scripts/check-win32-guards.py` reports 0 violations.

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards — clang-format clean; zero `#ifdef` rendering guards in game code; all rendering through `IMuRenderer`.
- [ ] **AC-STD-2:** Testing Requirements — Existing Catch2 test suite passes; no regressions.
- [ ] **AC-STD-12:** SLI/SLO targets — Game renders all 2D/3D content on macOS arm64: title screen (< 100ms), loading UI (< 50ms), all scenes render without crashes.
- [ ] **AC-STD-13:** Quality Gate — `./ctl check` exits 0.
- [ ] **AC-STD-14:** Observability — Post-migration: render time logged via `g_ErrorReport.Write()` at scene transitions; no raw GL performance issues logged.
- [ ] **AC-STD-15:** Git Safety — no force push, no incomplete rebase.
- [ ] **AC-STD-16:** Error codes — OpenGL backend render errors (allocation failures, context loss) use `ERRCODE_RENDER_*` family from error-catalog.md (if applicable, or document as N/A for stable GL context).

---

## Tasks / Subtasks

### Phase 1: Renderer Abstraction (AC-1, AC-2, AC-6)

- [ ] **Task 1: Extend IMuRenderer interface**
  - [ ] 1.1: Add `BeginScene(int x, int y, int w, int h)` / `EndScene()` — 3D projection setup
  - [ ] 1.2: Add `Begin2DPass()` / `End2DPass()` — 2D orthographic setup
  - [ ] 1.3: Add `IsFrameActive()` — frame lifecycle query
  - [ ] 1.4: Add `RenderLines(Vertex3D[], count)` — line rendering for debug viz
  - [ ] 1.5: Add `ClearScreen()` — wraps `glClear` / SDL_gpu clear

- [ ] **Task 2: Implement in OpenGL backend (`MuRenderer.cpp`)**
  - [ ] 2.1: `BeginScene()` → current `BeginOpengl()` body (glMatrixMode, glPushMatrix, gluPerspective, etc.)
  - [ ] 2.2: `EndScene()` → current `EndOpengl()` body
  - [ ] 2.3: `Begin2DPass()` → current `BeginBitmap()` body (gluOrtho2D, glDisable depth)
  - [ ] 2.4: `End2DPass()` → current `EndBitmap()` body
  - [ ] 2.5: `RenderLines()` → `glBegin(GL_LINES)` + vertex loop + `glEnd()`
  - [ ] 2.6: `ClearScreen()` → `glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)`

- [ ] **Task 3: Implement in SDL_gpu backend (`MuRendererSDLGpu.cpp`)**
  - [ ] 3.1: `BeginScene()` → set viewport, update projection uniform buffer
  - [ ] 3.2: `EndScene()` → restore state
  - [ ] 3.3: `Begin2DPass()` → mark 2D mode for pipeline selection
  - [ ] 3.4: `End2DPass()` → restore 3D mode
  - [ ] 3.5: `RenderLines()` → emit line primitives via SDL_gpu
  - [ ] 3.6: `ClearScreen()` → no-op (SDL_gpu clears in BeginFrame)
  - [ ] 3.7: `IsFrameActive()` → return `s_renderPass != nullptr`

- [ ] **Task 4: Rewrite `BeginOpengl`/`EndOpengl`/`BeginBitmap`/`EndBitmap` as thin wrappers**
  - [ ] 4.1: `BeginOpengl()` → `mu::GetRenderer().BeginScene(x, y, w, h)`
  - [ ] 4.2: `EndOpengl()` → `mu::GetRenderer().EndScene()`
  - [ ] 4.3: `BeginBitmap()` → `mu::GetRenderer().Begin2DPass()`
  - [ ] 4.4: `EndBitmap()` → `mu::GetRenderer().End2DPass()`

### Phase 2: 2D Rendering Migration (AC-3, AC-4)

- [ ] **Task 5: Port `CSprite::Render()` to RenderQuad2D** (AC-3)
  - [ ] 5.1: Build `Vertex2D[4]` from `m_aScrCoord` / `m_aTexCoord` with coordinate conversion
  - [ ] 5.2: Pack ABGR color, call `RenderQuad2D(vertices, textureId)`
  - [ ] 5.3: Handle untextured sprites (`m_nTexID == -1`, textureId = 0)
  - [ ] 5.4: Remove all `glBegin`/`glEnd`/`glVertex2f`/`glColor4ub`/`glTexCoord2f` from Sprite.cpp

- [ ] **Task 6: Port remaining 2D GL sites** (AC-4)
  - [ ] 6.1: `ShadowVolume.cpp:96` — full-screen shadow overlay → `RenderQuad2D`
  - [ ] 6.2: `ZzzEffectMagicSkill.cpp:124` — `RenderCircle2D()` → `RenderQuad2D` loop
  - [ ] 6.3: `SceneManager.cpp:436–478` — frame graph debug overlay → `RenderQuad2D`

### Phase 3: 3D Rendering Migration (AC-5)

- [ ] **Task 7: Port terrain rendering** (highest volume)
  - [ ] 7.1: `ZzzLodTerrain.cpp` — all 9 `GL_TRIANGLE_FAN` terrain functions → `RenderTriangles`
  - [ ] 7.2: `CSWaterTerrain.cpp` — 3 water rendering paths → `RenderTriangles`

- [ ] **Task 8: Port 3D effects**
  - [ ] 8.1: `ShadowVolume.cpp:314` — shadow volume mesh → `RenderTriangles`
  - [ ] 8.2: `SideHair.cpp:142` — hair outline quads → `RenderQuad2D` or `RenderTriangles`
  - [ ] 8.3: `ZzzEffectBlurSpark.cpp` — 4 sites (blur fans, cloth flags) → `RenderTriangles`
  - [ ] 8.4: `ZzzEffectMagicSkill.cpp:65` — `RenderCircle()` 3D → `RenderTriangles`
  - [ ] 8.5: `PhysicsManager.cpp:833` — cloth quads → `RenderTriangles`

- [ ] **Task 9: Port 3D utility/debug rendering**
  - [ ] 9.1: `ZzzOpenglUtil.cpp:915–1108` — `RenderBox3D`, `RenderPlane3D` → `RenderTriangles`
  - [ ] 9.2: `CameraMove.cpp:490` — waypoint gizmo → `RenderTriangles` + `RenderLines`
  - [ ] 9.3: `ZzzObject.cpp:12240` — collision debug → `RenderLines`
  - [ ] 9.4: `ZzzBMD.cpp:2480` — bounding box + skeleton debug → `RenderTriangles` + `RenderLines`

### Phase 4: Scene Cleanup & Validation (AC-7, AC-8, AC-9)

- [ ] **Task 10: Clean scene entry points**
  - [ ] 10.1: Remove raw `glClear()` from all scenes (handled by `ClearScreen()` or `BeginFrame()`)
  - [ ] 10.2: Remove raw `glFlush()` from all scenes (handled by `EndFrame()`)
  - [ ] 10.3: Remove `SwapBuffers(hDC)` calls that survived AC-1 of 7-9-1
  - [ ] 10.4: `RenderTitleSceneUI()` — use `IsFrameActive()` for frame lifecycle during `OpenBasicData()`

- [ ] **Task 11: Verification**
  - [ ] 11.1: `grep` audit confirms zero raw GL calls outside renderer backends
  - [ ] 11.2: `./ctl check` passes
  - [ ] 11.3: `check-win32-guards.py` reports 0 violations
  - [ ] 11.4: Run game on macOS — all scenes render: title, loading, login, character, main world

---

## Dev Notes

### IMuRenderer New Methods

```cpp
// MuRenderer.h additions:
virtual void BeginScene(int x, int y, int w, int h) = 0;  // 3D projection
virtual void EndScene() = 0;
virtual void Begin2DPass() = 0;                             // 2D orthographic
virtual void End2DPass() = 0;
virtual void ClearScreen() = 0;
virtual void RenderLines(std::span<const Vertex3D> vertices, std::uint32_t textureId) = 0;
virtual bool IsFrameActive() const { return false; }
```

### Coordinate Conversion (2D Sprites)

`CSprite` stores coords in OpenGL bottom-up 640×480 space. For `RenderQuad2D`:
```
screenX = m_aScrCoord[i].fX * m_fScaleX * (WindowWidth / 640.0f)
screenY = WindowHeight - (m_aScrCoord[i].fY * m_fScaleY * (WindowHeight / 480.0f))
```
Winding: TL, BL, BR, TR — matches existing `RenderBitmap` pattern at `ZzzOpenglUtil.cpp:1268`.

### Vertex Conversion (3D)

3D sites use `glVertex3f(x, y, z)` + `glTexCoord2f(u, v)` + `glColor4f/glColor4ub`.
Map to `Vertex3D{x, y, z, nx, ny, nz, u, v, color}` where normals default to `{0,0,1}` for
flat-shaded geometry (terrain, effects). Color is packed ABGR.

### Terrain (Highest Volume — ZzzLodTerrain.cpp)

9 rendering functions, each a `GL_TRIANGLE_FAN` with 4 vertices per tile face. These run for
every visible tile every frame. The pattern is identical across all 9:
```cpp
glBegin(GL_TRIANGLE_FAN);
for (int i = 0; i < 4; i++) {
    glTexCoord2f(u[i], v[i]);
    glVertex3f(x[i], y[i], z[i]);
}
glEnd();
```
Convert each to: `Vertex3D verts[4] = {...}; mu::GetRenderer().RenderQuad2D(verts, textureId);`
Or use `RenderTriangles` with 6 vertices (two triangles per quad) for simplicity.

### Files with raw GL that MUST be cleaned (AC-8 verification)

After migration, only these files may contain raw GL calls:
- `MuRenderer.cpp` — OpenGL backend implementation
- `MuRendererSDLGpu.cpp` — SDL_gpu backend implementation
- `ZzzOpenglUtil.cpp` — ONLY inside `BeginScene`/`EndScene`/`Begin2DPass`/`End2DPass` bodies (which delegate to the renderer)
- `stdafx.h` — no-op stubs for macOS

Everything else: zero raw GL. Enforced by AC-8 grep check.

### Existing Infrastructure (DO NOT reinvent)

- `mu::Vertex2D`: `{float x, y, u, v; uint32_t color}` — `MuRenderer.h:62`
- `mu::Vertex3D`: `{float x, y, z, nx, ny, nz, u, v; uint32_t color}` — `MuRenderer.h:72`
- `mu::GetRenderer().RenderQuad2D()` — `MuRendererSDLGpu.cpp:838`
- `mu::GetRenderer().RenderTriangles()` — `MuRendererSDLGpu.cpp` (already implemented)
- `mu::GetRenderer().RenderQuadStrip()` — `MuRendererSDLGpu.cpp` (already implemented)
- `mu::GetRenderer().SetBlendMode()` — blend state management
- `mu::GetRenderer().SetDepthTest()` — depth state management
- `RenderBitmap` coord pattern: `ZzzOpenglUtil.cpp:1257–1274`
- ABGR packing: `(a << 24) | (b << 16) | (g << 8) | r`

### References

- [Source: MuRenderer.h:62–97] — Vertex2D/Vertex3D structs and IMuRenderer interface
- [Source: MuRendererSDLGpu.cpp:619–809] — BeginFrame/EndFrame implementation
- [Source: MuRendererSDLGpu.cpp:838–925] — RenderQuad2D implementation
- [Source: MuRenderer.cpp:34–75] — OpenGL backend (RenderQuad2D, RenderTriangles)
- [Source: ZzzOpenglUtil.cpp:581–610] — BeginOpengl (current GL implementation)
- [Source: ZzzOpenglUtil.cpp:1172–1197] — BeginBitmap (current GL implementation)
- [Source: ZzzOpenglUtil.cpp:1254–1274] — RenderBitmap/RenderColorBitmap coord pattern
- [Source: Sprite.cpp:280–323] — CSprite::Render (current GL immediate mode)
- [Source: ZzzLodTerrain.cpp:1486–1534] — Terrain rendering (highest volume GL site)
- [Source: Story 7-9-1] — Predecessor: game loop + RenderScene wiring
- [Source: Story 4-2-2] — RenderBitmap/Quad2D migration (established RenderQuad2D)
- [Source: Story 4-3-1] — SDL_gpu backend (established pipeline infrastructure)

---

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
