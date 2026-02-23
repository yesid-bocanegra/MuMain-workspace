# Rendering Architecture

The MuMain game client uses OpenGL 1.x immediate mode for all rendering. The cross-platform migration replaces this with SDL_gpu (Vulkan/Metal/D3D12) via a `MuRenderer` abstraction layer. This document covers the current rendering pipeline, the migration path, and shader specifications.

For the full migration plan, see [CROSS_PLATFORM_PLAN.md](CROSS_PLATFORM_PLAN.md) Phase 2. For library decisions, see [CROSS_PLATFORM_DECISIONS.md](CROSS_PLATFORM_DECISIONS.md).

**Section navigation:**

| Section | Lines | Content |
|---------|-------|---------|
| [Current Pipeline](#current-pipeline-opengl-immediate-mode) | ~60 | 111 glBegin sites inventory, blend modes, duplication analysis |
| [Migration Path: MuRenderer](#migration-path-murenderer-abstraction) | ~35 | Abstraction API, migration order |
| [SDL_gpu Concept Mapping](#sdl_gpu-concept-mapping) | ~25 | OpenGL→SDL_gpu translation table |
| [HLSL Shaders](#hlsl-shaders-session-28) | ~30 | 5 shader programs, ~150 lines total |
| [Effort Estimate](#effort-estimate) | ~20 | 10–16 week breakdown |
| [Texture Management](#texture-management) | ~10 | 30,000+ textures, CGlobalBitmap |

---

## Current Pipeline (OpenGL Immediate Mode)

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

## Migration Path: MuRenderer Abstraction

### Phase 2 Architecture

```
Current:
  Game Code → glBegin/glEnd (111 sites, 14 files)

After MuRenderer (Sessions 2.1–2.7):
  Game Code → MuRenderer API (~5 functions) → OpenGL backend (temporary)

After SDL_gpu swap (Sessions 2.8–2.10):
  Game Code → MuRenderer API → SDL_gpu backend (Vulkan/Metal/D3D12)
```

### MuRenderer API Surface (Session 2.1)

| API | Replaces | Purpose |
|-----|----------|---------|
| `BlendMode` enum | 7 `Enable*Blend` functions | Consolidate blend state |
| `RenderQuad2D()` | 9 `RenderBitmap*` variants | 2D textured quads |
| `RenderTriangles()` / `RenderQuadStrip()` | Raw `glBegin` geometry | 3D mesh rendering |
| `SetBlendMode()` / `SetDepthTest()` / `SetAlphaTest()` / `SetFog()` | Scattered `glEnable` calls | Pipeline state |
| `MatrixStack` class | `glPushMatrix`/`glPopMatrix`/`glTranslatef` | Matrix management |
| `DebugDrawLine()` / `DebugDrawQuad()` | Debug rendering | Debug visualization |

### Migration Order

1. **Session 2.3: ZzzOpenglUtil.cpp** — 15 sites, cascades to ~80% of rendering
2. **Session 2.5: Terrain + Water** — ZzzLodTerrain (9 sites) + CSWaterTerrain (2 sites)
3. **Session 2.6: Models + Objects** — ZzzBMD (4 sites, most complex) + ZzzObject (2 sites)
4. **Session 2.7: Effects + Remaining** — 8 files, effects and debug rendering

---

## SDL_gpu Concept Mapping

| OpenGL Pattern | SDL_gpu Replacement |
|---------------|---------------------|
| `glBegin`/`glEnd` | `SDL_GPUCommandBuffer` + `SDL_GPURenderPass` with vertex buffers |
| `glVertex3f`/`glTexCoord2f` | Vertex buffer data uploaded via `SDL_UploadToGPUBuffer` |
| `glBindTexture` | `SDL_BindGPUFragmentSamplers` |
| `glMatrixMode`/`glTranslatef`/`glRotatef` | Uniform buffer with projection/view/model matrices |
| `glOrtho`/`glFrustum` | Manual matrix math in uniform buffers |
| `glEnable(GL_BLEND)` | `SDL_GPUColorTargetBlendState` in pipeline creation |
| `glEnable(GL_DEPTH_TEST)` | `SDL_GPUDepthStencilState` in pipeline creation |
| Stencil operations (shadow volumes) | `SDL_GPUStencilOpState` in pipeline |

### SDL_gpu Pipeline Objects

- **6 blend mode pipelines** mapping to `SDL_GPUColorTargetBlendState`
- **Depth/stencil state variants** mapping to `SDL_GPUDepthStencilState`
- **Shadow volume stencil pipeline** with INCR/DECR passes via `SDL_GPUStencilOpState`
- **Rasterizer state** for face culling and winding order via `SDL_GPURasterizerState`

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

## Effort Estimate

| Work Item | Scope | Effort |
|-----------|-------|--------|
| MuRenderer abstraction (OpenGL backend) | Consolidate 111 sites → ~5 functions | 2–3 weeks |
| HLSL shaders + SDL_shadercross build | ~150 lines HLSL, CMake pipeline | 1 week |
| Matrix math utility | ~300 lines C++, 200+ call sites | 2–3 weeks |
| Swap MuRenderer backend to SDL_gpu | ~5 functions to reimplement | 2–3 weeks |
| Pipeline state objects | 6 blend + depth/stencil variants | 1 week |
| Shadow volume stencil rewrite | ShadowVolume.cpp + ZzzBMD.cpp | 1 week |
| SDL_gpu device init + swap chain | Replace SDL_GL_CreateContext | 1 week |
| ImGui backend swap | `imgui_impl_sdlgpu3.cpp` drop-in | 1 day |
| Testing and visual parity | Screenshot comparison | 1–2 weeks |
| **Total** | | **10–16 weeks** |

The abstraction layer adds 2–3 weeks upfront but reduces SDL_gpu backend work from 3–5 weeks (111 sites) to 2–3 weeks (~5 functions). Net cost is ~0, with better code quality.

---

## Texture Management

- ~30,000+ indexed textures managed by `CGlobalBitmap` (`GlobalBitmap.cpp`)
- Texture loading via `LoadImage()` — supports TGA (GL_NEAREST) and JPG (libjpeg-turbo, GL_LINEAR)
- OZJ/OZT are compressed/encrypted texture variants
- Texture IDs allocated from `_TextureIndex.h` constant ranges
- LRU cache with 15-minute aging cleanup
- Memory tracked via `dwUsedTextureMemory`

Post SDL_gpu migration, `glGenTextures`/`glTexImage2D` calls become `SDL_CreateGPUTexture`/`SDL_UploadToGPUTexture`.
