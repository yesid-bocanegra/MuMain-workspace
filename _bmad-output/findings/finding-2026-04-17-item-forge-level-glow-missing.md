# Item Forge-Level Glow: Missing Additive Sprite Effects

**Date:** 2026-04-17 (diagnosed), 2026-04-18 (fixed)
**Discovered during:** Visual QA on SDL3 GPU renderer — items with forge level ≥ 3 show no glow at all, including +7/+9/+11/+13 weapons that should glow orange, and excellent/ancient armor pieces that should show animated chrome sheen.
**Context:** Sprint 7, EPIC-4 (Rendering Pipeline Migration), Feature 7.9
**Discovery type:** regression (visual fidelity)
**Status:** **RESOLVED** 2026-04-18
**Urgency:** backlog (cosmetic, but affects gameplay feedback)

---

## Summary

MU Online's "item glow" is actually three visual layers, each using a distinct code path:

1. **Forge-level glow** — world-space additive `BITMAP_LIGHT` billboard at the weapon's `LinkBone`, color per forge tier (red +3/+4, blue +5/+6, orange +7+).
2. **Excellent/chrome sheen** — mesh-level `RENDER_CHROME | RENDER_BRIGHT` overlay pass that re-draws each mesh with an animated chrome texture tinted by material (red, silver, gold).
3. **Ancient +15 effects** — elaborate multi-sprite effects (flares, lightning joints, magic runes). Unaffected by this bug.

On SDL3, layers (1) and (2) were both broken — sprites and chrome overlays produced only faint edge halos instead of the full tinted effect. Layer (3) worked because its sprites are drawn at positions offset from the mesh depth.

---

## Root Cause

The SDL3 GPU 3D pipelines were built with `SDL_GPU_COMPAREOP_LESS` as the depth compare for all three depth variants (full depth, depth-read-only, depth-off). `LESS` rejects every fragment at equal depth to what's already in the depth buffer.

Both the forge-glow sprite and the chrome/bright mesh overlay draw at the *same* view-space Z as the mesh they decorate:
- Forge glow: `BITMAP_LIGHT` billboard centered at the weapon's bone transform position
- Chrome sheen: re-rasterization of the same mesh geometry with a different texture

After the base opaque mesh writes depth, every subsequent overlay fragment fails `z < z` and gets rejected before the blend stage. What the user saw as "slight gold tint" was only the halo edge where perspective nudged fragments slightly closer than the mesh.

Classic OpenGL MU ran these passes with `GL_LEQUAL` effectively — `ZzzBMD.cpp:2539` calls `SetDepthFunc(GL_LEQUAL)` before chrome rendering. The SDL3 `SetDepthFunc` override is a no-op stub (`MuRenderer.h:267`), so the depth-function change never propagated to the pipeline.

### Hypotheses eliminated during investigation (kept for context)

1. **Deferred RenderCmd drain** — ruled out: probes at `CreateSprite`, `RenderSprites`, and `RenderSprite(int, vec3_t,…)` confirmed sprites reach GPU submission.
2. **BITMAP_LIGHT texture binding failure** — ruled out: probe at `RenderTriangles` showed `LookupTexture(32002)` returning a valid GPU texture (not the s_whiteTexture fallback).
3. **Blend state leak** — ruled out: probe confirmed `blend=Glow`, `depthTest=1`, `depthWrite=0`, `alphaTest=0` — exactly the expected state.
4. **Fog uniform not propagated** — noted as a separate dead-code issue (`SetFogEnabled` doesn't update `m_fogUniform.fogEnabled`), but not causative here since Lorencia fog range is 0.

---

## Applied Fix

**File:** `MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp` (~line 2498, inside `BuildBlendPipeline`)

```cpp
// Depth compare selection:
//   LESS for opaque 3D (depth write ON): strict layering, normal opaque z-sort.
//   LESS_OR_EQUAL for depth-read-only 3D (write OFF) and all 2D: these are additive/
//   glow overlays drawn on top of geometry at the same depth (forge-level sprites,
//   weapon chrome/bright mesh passes, terrain texture layering). LESS would reject
//   every equal-depth fragment before the blend stage — the classic MU OpenGL client
//   ran these passes with GL_LEQUAL effectively by calling SetDepthFunc(GL_LEQUAL)
//   before them, which the SDL3 backend doesn't propagate. Using LESS_OR_EQUAL on
//   read-only variants recovers the intended behavior uniformly.
const bool strictLayering = bUse3DLayout && depthWriteEnabled;
depthState.compare_op = strictLayering ? SDL_GPU_COMPAREOP_LESS : SDL_GPU_COMPAREOP_LESS_OR_EQUAL;
```

Single-line semantic change: depth compare is now derived from the pipeline's semantic (strict layering vs. overlay) rather than the layout dimension (3D vs. 2D). This affects:
- `s_pipelines3D[]` (test+write, opaque): still `LESS` — no change
- `s_pipelines3DDepthReadOnly[]` (test only, glow/transparent): now `LESS_OR_EQUAL` — **fix applied here**
- `s_pipelines3DDepthOff[]` (no test): now `LESS_OR_EQUAL` — has no effect (test is off anyway)
- `s_pipelines2D[]`, `s_pipelines2DDepthOff[]`: still `LESS_OR_EQUAL` — no change

## Systems Fixed by This Single Change

| System | Path | Mechanism |
|---|---|---|
| Forge-level sprite glow | `CreateSprite(BITMAP_LIGHT, …)` → `RenderSprites` → `EnableAlphaBlend` (Glow, depth write off) | Uses depth-read-only pipeline → now LEQUAL |
| Excellent/chrome sheen | `RenderPartObjectEffect` → `BMD::RenderMesh` with `RENDER_CHROME \| RENDER_BRIGHT` → `EnableAlphaBlend` | Uses depth-read-only pipeline → now LEQUAL |
| Terrain overlay blend | `ZzzLodTerrain::RenderFaceAlpha` → `EnableAlphaBlend3` | Already defensively wrapped with `DisableDepthTest` on 2026-04-18; fix is now redundant for that site but harmless (depth-off pipeline is also LEQUAL) |
| Blur attack trails, particles, etc. | Any `EnableAlphaBlend*` path | Same benefit — no more co-planar rejection |

## Validation (completed 2026-04-18)

- **+7+ weapons**: orange halo now visible at weapon tip as intended
- **Excellent armor (red/silver/gold tiers)**: animated chrome sheen now renders on armor pieces (fire-armor red, metal-armor silver, gold-armor gold)
- **Terrain**: no regression — existing `DisableDepthTest` wrapper in `RenderFaceAlpha` is now redundant but harmless
- **Opaque geometry z-sort**: no regression — `s_pipelines3D` (full-depth) still uses strict `LESS`
- **Build**: compiles; `./ctl check` passes

---

## Related Memory

- `project_sdl3_renderer_gotchas.md` — SDL3 GPU pipeline state, deferred draw commands, and the recurring co-planar depth-reject pattern
- Finding `finding-2026-04-17-terrain-hard-square-edges.md` — terrain instance of the same bug, fixed with `DisableDepthTest` wrap; this architectural fix supersedes the need for that pattern

---

## References

- `RenderFX/MuRendererSDLGpu.cpp:2494-2506` — depth compare selection (fix site)
- `RenderFX/MuRendererSDLGpu.cpp:1790-1797` — pipeline dispatch based on `m_depthTestEnabled`/`m_depthMaskEnabled`
- `RenderFX/MuRendererSDLGpu.cpp:2612-2630` — pipeline creation loop (depth-on/read-only/off variants)
- `RenderFX/ZzzOpenglUtil.cpp:420` — `EnableAlphaBlend` (glow) disables depth write, selecting the read-only pipeline
- `RenderFX/ZzzBMD.cpp:2539` — `SetDepthFunc(GL_LEQUAL)` call in classic MU — now a no-op on SDL3, recovered by the pipeline change
- `RenderFX/MuRenderer.h:267` — `SetDepthFunc` base-class no-op stub

---

## Distinguishing the Glow Systems

MU's item "glow" is three separate visual systems. Documenting so future investigation doesn't conflate them:

1. **Forge-level glow:** additive `BITMAP_LIGHT` sprite at weapon tip, color per +3/+5/+7 tier. Sprite-based, world-space billboard.
2. **Excellent-item chrome sheen:** `RENDER_CHROME | RENDER_BRIGHT` pass overlays the mesh with an animated chrome texture. Mesh-based, not sprite-based. Different code path in `RenderPartObjectEffect()` and `BMD::RenderMesh`.
3. **Ancient / +15 effects:** elaborate multi-sprite effects (flares, lightning joints, magic runes). Uses `CreateSprite`, `CreateJoint`, `CreateParticle` en masse. Handled by `NextGradeObjectRender()`.

This fix addresses (1) and (2) with a single pipeline-level change. (3) was never broken.
