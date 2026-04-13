# Rendering Architecture

The MuMain game client uses SDL_gpu (Metal on macOS, Vulkan on Linux, D3D12 on Windows) for all rendering via the `IMuRenderer` interface, implemented by `MuRendererSDLGpu` (~3,045 lines). The original OpenGL 1.x immediate-mode backend (`MuRendererGL` in `MuRenderer.cpp`) was deleted after story 7.9.3; the legacy `ZzzOpenglUtil.cpp` call sites still exist but are unused on SDL3 builds.

For the full migration history, see [CROSS_PLATFORM_PLAN.md](CROSS_PLATFORM_PLAN.md) Phase 2. For library decisions, see [CROSS_PLATFORM_DECISIONS.md](CROSS_PLATFORM_DECISIONS.md).

**Section navigation:**

| Section | Lines | Content |
|---------|-------|---------|
| [Legacy Pipeline](#legacy-pipeline-opengl-immediate-mode) | ~60 | 111 glBegin sites inventory, blend modes, duplication analysis |
| [Active Renderer: MuRendererSDLGpu](#active-renderer-murenderersdlgpu) | ~45 | Deferred command buffer, pipeline architecture, texture upload, SDL_ttf |
| [IMuRenderer Interface](#imurenderer-interface) | ~25 | Abstraction API surface |
| [SDL_gpu Concept Mapping](#sdl_gpu-concept-mapping) | ~25 | OpenGL→SDL_gpu translation table |
| [HLSL Shaders](#hlsl-shaders-session-28) | ~30 | 5 shader programs, ~150 lines total |
| [Texture Management](#texture-management) | ~10 | 30,000+ textures, CGlobalBitmap |

---

## Legacy Pipeline (OpenGL Immediate Mode)

> **Status (April 2026):** The OpenGL backend has been removed. The call sites below are retained in the codebase for Windows compatibility but are not compiled on SDL3 builds. All rendering goes through `MuRendererSDLGpu`.

### Call Site Inventory

111 `glBegin`/`glEnd` sites across 14 files:

| File | glBegin Sites | Primitives | Key Features |
|------|--------------|------------|-------------|
| `ZzzOpenglUtil.cpp` | 15 | QUADS, TRIANGLE_FAN | 9 `RenderBitmap*` variants, 7 blend functions, fog setup — cascades to 100+ files |
| `ZzzBMD.cpp` | 4 | TRIANGLES | Meshes, chrome UV, wave effects, bounding boxes. Largest rendering file |
| `ZzzLodTerrain.cpp` | 9 | TRIANGLE_FAN | Terrain strips with frustum culling |
| `ZzzObject.cpp` | 2 | QUADS, LINES | Heavy vertex color, debug lines |
| `ZzzEffectJoint.cpp` | 3 | QUADS | Trail effects |
| `ZzzEffectBlurSpark.cpp` | 2 | TRIANGLE_FAN, QUADS | Blur/spark effects |
| `ZzzEffectMagicSkill.cpp` | 2 | QUADS | Magic skill effects |
| `CSWaterTerrain.cpp` | 2 | TRIANGLES | Water surface |
| `ShadowVolume.cpp` | 2 | TRIANGLES | Two-pass stencil INCR/DECR + shadow apply |
| `SideHair.cpp` | 1 | QUADS | Hair rendering |
| `SceneManager.cpp` | 1 | QUADS | Scene fade overlays |
| `Sprite.cpp` | 1 | TRIANGLE_FAN | 2D sprites |
| `PhysicsManager.cpp` | 1 | QUADS | Debug visualization |
| `CameraMove.cpp` | 1 | LINE_STRIP | Debug camera path |

### What OpenGL IS and IS NOT Used For

**NOT used by OpenGL (already software-computed):**
- Lighting — `BMD::Lighting()` and `BMD::Chrome()` compute per-vertex colors in C++, passed via `glColor3f`/`glColor4f`. No `glLight*`, `glMaterial*`, or `GL_LIGHTING` calls exist.
- Clip planes, point/line smoothing, multitexturing — not used

**Handled as pipeline state (not shader code):**
- 6 blend modes → pipeline objects
- Depth test modes (LEQUAL, LESS, ALWAYS)
- Stencil ops (INCR/DECR/KEEP for shadow volumes)
- Face culling and winding order
- Color mask (shadow volume passes)

### Blend Modes

| Mode | GL Calls | Usage |
|------|----------|-------|
| Alpha | `GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA` | Default transparency |
| Additive | `GL_SRC_ALPHA, GL_ONE` | Glow, fire, magic effects |
| Subtract (Minus) | `GL_ZERO, GL_ONE_MINUS_SRC_COLOR` | Shadow, dark effects |
| InverseColor | `GL_ONE_MINUS_DST_COLOR, GL_ZERO` | Screen-space inversion |
| Mixed | `GL_ONE, GL_ONE_MINUS_SRC_ALPHA` | Pre-multiplied alpha |
| LightMap | `GL_ZERO, GL_SRC_COLOR` | Terrain lightmaps |

### Rendering Duplication

| Pattern | Files | Instances | Wasted LOC |
|---------|-------|-----------|------------|
| 9 `RenderBitmap*` variants (same quad, different params) | ZzzOpenglUtil.cpp | 9 functions | ~250 |
| 7 `Enable*Blend` functions (same structure, different enum) | ZzzOpenglUtil.cpp | 7 functions | ~140 |
| Effect quad rendering (95% identical) | ZzzEffectJoint, BlurSpark, MagicSkill | 10+ functions | ~120 |
| Terrain `RenderFace*` variants | ZzzLodTerrain.cpp | 4 functions | ~50 |
| Debug draw (colored quads/lines) | PhysicsManager, CameraMove, ZzzObject | 6 functions | ~50 |
| **Total** | **14 files** | **111 sites** | **~600 LOC** |

---

## Active Renderer: MuRendererSDLGpu

`MuRendererSDLGpu` (in `MuRendererSDLGpu.cpp`, ~3,045 lines) is the sole rendering backend on macOS and Linux. It implements the `IMuRenderer` interface defined in `MuRenderer.h`.

```
Game Code → IMuRenderer API → MuRendererSDLGpu → SDL_gpu (Metal / Vulkan / D3D12)
```

### Deferred Command Buffer Architecture

The renderer does **not** issue GPU draw calls inline. Instead:

1. **BeginFrame()** — acquires an `SDL_GPUCommandBuffer`, maps a 16 MB scratch vertex transfer buffer, resets per-frame state.
2. **Draw calls** (`RenderQuad2D`, `RenderTriangles`, `RenderQuadStrip`, `SubmitTextTriangles`) — copy vertex data into the mapped transfer buffer and append a `RenderCmd` struct to `s_renderCmds`. No render pass is open at this point.
3. **EndFrame()** — unmaps the transfer buffer, runs a **copy pass** (vertex upload + deferred texture uploads), then opens the render pass and **replays** all `RenderCmd` entries. Finally submits the command buffer and presents.

This eliminates a 1-frame vertex data delay that caused streak artifacts when vertex counts varied per frame.

#### RenderCmd Types

| Type | Geometry | Usage |
|------|----------|-------|
| `DrawIndexedQuads2D` | Indexed 2D (Vertex2D, static quad index buffer) | Sprites, UI, `RenderBitmap*` |
| `DrawTriangles` | Non-indexed 3D (Vertex3D) | Meshes, effects, terrain |
| `DrawIndexedStrip` | Indexed 3D (Vertex3D, per-frame strip indices) | Quad strips, terrain strips |
| `DrawTriangles2D` | Non-indexed 2D (Vertex2D) | SDL_ttf text atlas glyphs |
| `SetViewport` | — | Viewport changes mid-frame |

Each `RenderCmd` captures the pipeline, texture/sampler bindings, vertex offset/count, MVP uniform, and fog uniform at record time.

### Pipeline Architecture

45 GPU pipelines created at init: **9 blend modes** (8 named + disabled) × **5 depth/layout variants**:

| Pipeline Set | Vertex Layout | Depth Test | Depth Write | Purpose |
|-------------|---------------|------------|-------------|---------|
| `s_pipelines2D` | Vertex2D (20 B) | ON | ON | 2D with depth sorting |
| `s_pipelines2DDepthOff` | Vertex2D (20 B) | OFF | OFF | 2D overlay (UI) |
| `s_pipelines3D` | Vertex3D (40 B) | ON | ON | Opaque 3D geometry |
| `s_pipelines3DDepthOff` | Vertex3D (40 B) | OFF | OFF | Skybox, fullscreen effects |
| `s_pipelines3DDepthReadOnly` | Vertex3D (40 B) | ON | OFF | Transparent/additive particles |

Blend modes: Alpha, Additive, Subtract, InverseColor, Mixed, LightMap, Glow, Luminance, Disabled.

### Dynamic Texture Upload

`QueueTextureUpdate()` snapshots the CPU pixel buffer at queue time (`std::vector<uint8_t>` copy) into a `TextureUpdateCmd`. These are processed during EndFrame's copy pass **before** the render pass, so draw commands always see updated texture data. Used by GDI text rasterization (`CUIRenderTextOriginal`, `CUITextInputBox`) to upload modified bitmap fonts.

### SDL_ttf Integration

SDL_ttf 3.x is initialized via `TTF_CreateGPUTextEngine(s_device)` during `Init()`. Font accessors on `IMuRenderer` (`GetTtfFont`, `GetTtfFontBold`, `GetTtfFontBig`, `GetTtfFontFixed`) expose loaded `TTF_Font*` handles. Text glyphs are submitted via `SubmitTextTriangles()` which records a `DrawTriangles2D` command referencing the glyph atlas texture.

---

## IMuRenderer Interface

`IMuRenderer` (`MuRenderer.h`) is the pure abstract rendering interface. Game code calls `mu::GetRenderer()` to obtain the active backend.

### API Surface

| API | Purpose |
|-----|---------|
| `RenderQuad2D()` | Screen-space textured quads (4 vertices per quad) |
| `RenderTriangles()` / `RenderQuadStrip()` | World-space 3D geometry |
| `RenderLines()` | Debug line primitives |
| `SetBlendMode()` / `DisableBlend()` | Blend equation selection |
| `SetDepthTest()` / `SetDepthMask()` / `SetCullFace()` | Depth/rasterizer state |
| `BeginScene()` / `EndScene()` | 3D perspective projection setup |
| `Begin2DPass()` / `End2DPass()` | 2D orthographic projection |
| `BeginFrame()` / `EndFrame()` | Per-frame lifecycle (command buffer acquire/submit) |
| `SetFog()` | Fog uniform buffer update |
| `BindTexture()` | Bind by game bitmap index |
| `QueueTextureUpdate()` | Deferred CPU→GPU texture upload |
| `SubmitTextTriangles()` | SDL_ttf glyph triangle submission |
| `GetDevice()` | `SDL_GPUDevice*` accessor (for texture system) |
| Matrix stack | `PushMatrix`, `PopMatrix`, `Translate`, `Rotate`, `Scale`, `MultMatrix`, `LoadMatrix` |

---

## SDL_gpu Concept Mapping

The following table shows how each OpenGL pattern was replaced in `MuRendererSDLGpu`:

| OpenGL Pattern | SDL_gpu Implementation |
|---------------|---------------------|
| `glBegin`/`glEnd` | Deferred `RenderCmd` recording + `SDL_GPURenderPass` replay in EndFrame |
| `glVertex3f`/`glTexCoord2f` | `Vertex2D`/`Vertex3D` structs written to mapped transfer buffer, uploaded in copy pass |
| `glBindTexture` | `SDL_BindGPUFragmentSamplers` with texture registry lookup by bitmap index |
| `glMatrixMode`/`glTranslatef`/`glRotatef` | `MatrixStack` class + `VertexUniforms` pushed per-draw via `SDL_PushGPUVertexUniformData` |
| `glOrtho`/`glFrustum` | GLM matrix math (`glm::ortho`, `glm::perspective`) in uniform buffers |
| `glEnable(GL_BLEND)` | 9 `SDL_GPUColorTargetBlendState` variants baked into 45 pipelines |
| `glEnable(GL_DEPTH_TEST)` | 5 depth/layout pipeline sets with `SDL_GPUDepthStencilState` |
| `glTexImage2D` | `SDL_UploadToGPUTexture` via deferred `TextureUpdateCmd` in copy pass |
| `glClear` | `SDL_GPU_LOADOP_CLEAR` at render pass begin |

---

## HLSL Shaders (Session 2.8)

~100–150 lines total across 5 shader programs. Cross-compiled via SDL_shadercross to SPIR-V (Vulkan), MSL (Metal), and DXIL (D3D12).

### basic_colored
Flat colored geometry — UI lines, debug primitives, SceneManager scene fades.

```hlsl
// Vertex: transform position by MVP, pass through color
// Fragment: output vertex color directly
```

### basic_textured
Textured quads with vertex color multiply. Covers ~80% of rendering: sprites, UI, terrain, water, effects, hair.

```hlsl
// Fragment:
float4 color = tex.Sample(s, uv) * vertexColor;
if (alphaDiscardEnabled && color.a <= threshold) discard;  // thresholds: 0.25, 0.0
if (fogEnabled) color.rgb = lerp(color.rgb, fogColor, fogFactor);  // GL_LINEAR fog
return color;
```

### model_mesh
Identical to basic_textured but for `glDrawArrays` path in ZzzBMD.cpp. Shares fragment shader.

### shadow_volume
Transform-only vertex shader, no fragment output. Color mask disabled during stencil INCR/DECR passes.

### shadow_apply
Fullscreen quad with semi-transparent shadow color output.

---

## Texture Management

- ~30,000+ indexed textures managed by `CGlobalBitmap` (`GlobalBitmap.cpp`)
- Texture loading via `LoadImage()` — supports TGA (GL_NEAREST) and JPG (libjpeg-turbo, GL_LINEAR)
- OZJ/OZT are compressed/encrypted texture variants
- Texture IDs allocated from `_TextureIndex.h` constant ranges
- LRU cache with 15-minute aging cleanup
- Memory tracked via `dwUsedTextureMemory`

On SDL3 builds, textures are created via `SDL_CreateGPUTexture` and uploaded via `SDL_UploadToGPUTexture`. A `TextureRegistry` (`std::unordered_map`) maps game bitmap indices to `SDL_GPUTexture*` handles. Mid-frame texture updates go through `QueueTextureUpdate()` (see [Dynamic Texture Upload](#dynamic-texture-upload) above).
