# Terrain Texture Blending: Hard Square Edges Between Tiles

**Date:** 2026-04-17 (diagnosed), 2026-04-18 (fixed + follow-up regression resolved)
**Discovered during:** Visual QA on SDL3 GPU renderer — noticed lack of gradient transitions between adjacent terrain tile textures.
**Context:** Sprint 7, EPIC-4 (Rendering Pipeline Migration), Feature 7.9
**Discovery type:** regression (visual fidelity)
**Status:** **RESOLVED** 2026-04-18
**Urgency:** backlog (cosmetic but highly visible)
**Urgency justification:** Terrain overlay layer renders as hard-edged 64×64 squares instead of the soft gradient blends the art was authored for. Not a crash, not a playability blocker — but every map is visually degraded compared to the original client.

---

## Summary

MU terrain is a two-layer texture system: a base layer (`TerrainMappingLayer1[]`) plus an overlay layer (`TerrainMappingLayer2[]`) mixed by a per-vertex alpha mask (`TerrainMappingAlpha[]`, range 0.0–1.0). The mask is smoothly interpolated across the quad, and was intended to produce gradient transitions (grass fading into dirt, sand into rock, etc.).

In the current SDL3 GPU build, the overlay pass is drawn with **alpha test** (binary keep/discard) rather than **alpha blending** (fractional compositing). As a result, the interpolated vertex alpha is clamped per fragment to either fully opaque or fully discarded — collapsing the gradient onto the underlying 64×64 tile quad and producing the squared-off edges observed in-game.

---

## Root Cause (corrected after investigation)

The initial hypothesis — that `EnableAlphaTest()` was discarding fractional alpha — turned out to be a **red herring**. The `alphaThreshold` uniform defaults to 0.0f, so the alpha-test stage only discarded fully-transparent fragments. Alpha blending had actually been running correctly (`SRC_ALPHA / ONE_MINUS_SRC_ALPHA`) all along. Swapping `EnableAlphaTest()` for `EnableAlphaBlend3()` was a no-op visually.

**The actual root cause is the 3D pipeline's depth compare operator.**

`MuRendererSDLGpu.cpp:2474` sets the 3D pipeline's depth comparison to `SDL_GPU_COMPAREOP_LESS`:

```cpp
// LESS for 3D: rejects same-depth glow fragments from overlaying their own opaque pass.
// LESS_OR_EQUAL for 2D: allows overlapping UI elements at the same Z to draw correctly.
depthState.compare_op = bUse3DLayout ? SDL_GPU_COMPAREOP_LESS : SDL_GPU_COMPAREOP_LESS_OR_EQUAL;
```

The terrain overlay pass draws the same quad as the base layer at **identical world-space Z**. With `LESS` (strict), the test `z < z` is false for every overlay fragment, so the GPU rejects them before the blend stage. The per-vertex alpha never reaches the framebuffer. Result: hard 64×64 square edges because only the base layer contributes visible color.

The choice of `LESS` was intentional — the comment cites avoiding self-overlay z-fighting on additive glow meshes. But it unintentionally also rejects legitimate coplanar terrain overlays, which classic OpenGL MU rendered fine under default `GL_LESS_OR_EQUAL`.

Verified with a one-shot histogram log added during diagnosis: Devias (World3) has **7,383 fractional alpha values out of 65,536** (11.3%). The mask data is correct; the pipeline was silently dropping the draw.

### Secondary regression (caught and fixed on 2026-04-18)

The initial fix — `DisableDepthTest()` before the overlay draw — left depth test disabled for the rest of the frame because this renderer's state is sticky. After any terrain tile with an overlay drew, every subsequent draw (next tile's base layer, objects, shadows, monsters) ran without depth culling. Visible on Lorencia bridge (low-res texture patches) and Tarkan (character shadows bleeding through terrain).

Fix: pair the `DisableDepthTest()` with `EnableDepthTest()` at the end of `RenderFaceAlpha` so the state change is scoped to the one overlay draw.

---

## Affected Code

| File | Lines | Description |
|------|-------|-------------|
| `World/ZzzLodTerrain.cpp` | 1369-1403 | `RenderFaceAlpha()` — overlay draw (fixed: `DisableDepthTest()` + `EnableAlphaBlend3()` + `EnableDepthTest()` pair) |
| `World/ZzzLodTerrain.cpp` | 1476-1527 | `RenderTerrainFace()` — dispatches to `RenderFaceAlpha()` for partial overlays |
| `World/ZzzLodTerrain.cpp` | 46-48 | Layer1, Layer2, and Alpha arrays (data is correct, stored per terrain cell) |
| `World/ZzzLodTerrain.cpp` | 326-343 | Alpha values loaded from map data + diagnostic histogram log |
| `RenderFX/ZzzOpenglUtil.cpp` | 293-307 | `EnableDepthTest()` / `DisableDepthTest()` — sticky global state |
| `RenderFX/ZzzOpenglUtil.cpp` | 489-510 | `EnableAlphaBlend3()` — `BlendMode::Alpha` without alpha test |
| `RenderFX/MuRendererSDLGpu.cpp` | 2474 | **Root cause**: 3D pipeline depth compare is `LESS` (strict), rejecting coplanar overlays |
| `RenderFX/MuRendererSDLGpu.cpp` | 1790-1797 | Pipeline dispatch: depth-off variant used when depth test is disabled |

## Comparison: the three terrain face draw paths

| Function | Location | State setup | Use case |
|----------|----------|-------------|----------|
| `RenderFace()` | ZzzLodTerrain.cpp:1335 | default (opaque, depth test + write on) | Solid tile, no overlay |
| **`RenderFaceAlpha()`** | ZzzLodTerrain.cpp:1369 | depth test off + `EnableAlphaBlend3()` (fixed) | Overlay layer with partial alpha |
| `RenderFaceBlend()` | ZzzLodTerrain.cpp:1392 | `EnableAlphaBlend()` (`BlendMode::Glow`, additive) | Water reflection / special effects |

---

## Applied Fix

```cpp
void RenderFaceAlpha(int Texture, int mx, int my)
{
    // Terrain overlay uses per-vertex alpha (TerrainMappingAlpha) to feather Layer2 over
    // Layer1. Two constraints: (1) fractional alpha must reach the blend stage, so use
    // alpha blend, not alpha test; (2) overlay is coplanar with the base layer, and the
    // 3D pipeline's depth compare is GL_LESS — with depth test on, every overlay fragment
    // fails z<z and gets rejected before blending. Disable depth test for this pass so
    // the interpolated alpha actually renders.
    DisableDepthTest();
    EnableAlphaBlend3();
    BindTexture(BITMAP_MAPTILE + Texture);
    // ... draw quad with per-vertex alpha ...
    // Restore depth test so subsequent draws (next tile's base layer, objects,
    // shadows, monsters) are correctly z-occluded. Render*State here is sticky
    // global state; leaving depth off leaks into every draw for the rest of the frame.
    EnableDepthTest();
}
```

Two key changes:

1. **`DisableDepthTest()` before the overlay draw** — bypasses the 3D pipeline's strict `LESS` depth compare so coplanar overlay fragments reach the blend stage.
2. **`EnableDepthTest()` at function exit** — required to prevent the disable from leaking into every subsequent draw in the frame. Without this, object shadows bleed through terrain and texture Z-ordering breaks on elevated geometry (Lorencia bridge, Tarkan cliffs).

## Validation (completed 2026-04-18)

- **Devias (World3)**: soft feathered transitions now visible between snow/ice/rock tiles. Matches classic MU visual.
- **Lorencia bridge (World0)**: wooden planks render correctly, no low-res texture patches, no ghost geometry through the bridge.
- **Tarkan (World8)**: desert terrain renders correctly, character shadows correctly z-occluded by rocks and terrain.
- **Performance**: negligible — two extra pipeline state transitions per overlay tile draw, vs. one previously. Frame times unchanged at 60 FPS on M2 (measured).
- **Build**: passes `./ctl check` quality gate.

## Diagnostic Instrumentation Retained

The histogram log added during diagnosis is kept in place:

```
TerrainMappingAlpha histogram for {map}: zero=N full=N fractional=N
```

Fires once per map load, costs nothing, and instantly reveals whether a map's blend data is degenerate. Useful for any future "terrain looks wrong on map X" investigation. Remove only if it becomes noisy.

---

## Related Memory

- `project_sdl3_renderer_gotchas.md` — SDL3 GPU pipeline state and deferred draw command pattern
- Terrain data files (`.att` + `.map`) are unchanged; this is purely a rendering-stage fix

---

## References

- `World/ZzzLodTerrain.cpp:1463-1514` — `RenderTerrainFace()` dispatch logic
- `World/ZzzLodTerrain.cpp:1357-1378` — `RenderFaceAlpha()` (fix site)
- `RenderFX/ZzzOpenglUtil.cpp:396-418` — `EnableAlphaTest()` definition
- `RenderFX/ZzzOpenglUtil.cpp:489-510` — `EnableAlphaBlend3()` definition (replacement)
- `RenderFX/MuRendererSDLGpu.cpp:540-569` — `GetBlendFactors()` mapping SDL3 GPU blend factors
