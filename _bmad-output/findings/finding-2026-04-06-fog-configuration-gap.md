# Fog Configuration Gap: Per-Scene Fog Never Enabled

**Date:** 2026-04-06
**Discovered during:** SDL3 renderer streak artifact investigation (post-7-9-7)
**Context:** Sprint 7, EPIC-4 (Rendering Pipeline Migration), Feature 7.9
**Discovery type:** feature-gap
**Urgency:** backlog
**Urgency justification:** Fog was disabled in the original OpenGL build for all non-Battle Castle scenes. Not a regression — but a missing atmospheric feature that affects visual fidelity.

---

## Summary

The global `FogEnable` flag (`ZzzOpenglUtil.cpp:46`) is initialized to `false` and **never set to `true`** anywhere in the codebase. This means the per-blend-mode fog enable/disable calls in `ZzzOpenglUtil.cpp:395-558` are all dead code paths — the `if (FogEnable)` guard prevents them from ever executing.

The only scene with working fog is **Battle Castle**, which bypasses `FogEnable` entirely by calling `SetFog()` directly (`GMBattleCastle.cpp:600`) with hardcoded values (start=2000, end=2700, mode=GL_LINEAR).

The SDL3 renderer's fog pipeline is fully functional — vertex shader computes linear fog, fragment shader blends fog color — but no scene except Battle Castle ever provides fog parameters.

---

## Root Cause

This is not a regression. The original OpenGL game code also had `FogEnable = false` and the same dead code paths. The fog infrastructure exists but was never wired up for most maps.

---

## Affected Code

| File | Lines | Description |
|------|-------|-------------|
| `RenderFX/ZzzOpenglUtil.cpp` | 46 | `FogEnable = false` — never set to `true` |
| `RenderFX/ZzzOpenglUtil.cpp` | 395-558 | Dead `if (FogEnable)` branches in blend mode functions |
| `Scenes/MainScene.cpp` | 350-362 | Only Battle Castle branch calls `SetFog()` |
| `World/Maps/GMBattleCastle.cpp` | 587-606 | Only location that calls `SetFog()` with real values |
| `Scenes/LoginScene.cpp` | 373 | Explicitly sets `FogEnable = false` |
| `Scenes/CharacterScene.cpp` | 404 | Explicitly sets `FogEnable = false` |
| `Scenes/MainScene.cpp` | 533 | Explicitly sets `FogEnable = false` |

## Renderer Infrastructure (already working)

| File | Lines | Description |
|------|-------|-------------|
| `RenderFX/MuRendererSDLGpu.cpp` | 90-111 | `FogUniform` struct (fogEnabled, fogStart, fogEnd, fogColor) |
| `RenderFX/MuRendererSDLGpu.cpp` | 1592-1614 | `SetFog()` — maps FogParams to FogUniform, marks dirty |
| `shaders/basic_textured.vert.hlsl` | 31-34 | Linear fog: `fogFactor = saturate((fogEnd - dist) / range)` |
| `shaders/basic_textured.frag.hlsl` | — | `lerp(fogColor, texColor, fogFactor)` in fragment output |

---

## Proposed Story Scope

**Title:** Per-scene fog configuration for atmospheric rendering

**Goal:** Enable fog for maps that should have atmospheric depth cueing (dungeons, outdoor zones, events).

**Approach options:**
1. **Data-driven:** Add fog parameters to map metadata (start, end, color per map ID). Read in `MainScene.cpp` scene init and call `SetFog()`.
2. **Hardcoded per-map:** Similar to Battle Castle's `StartFog()` — add `StartFog()`/`EndFog()` pairs for each map type that should have fog.
3. **Global default:** Set `FogEnable = true` and provide sensible defaults (e.g., start=1500, end=2500). Per-map overrides via `SetFog()`.

**Estimated effort:** 3-5 points (infrastructure exists, only configuration needed)

**Dependencies:** None — fog pipeline is fully functional.

---

## Verification

Fog disabled is correct behavior for now:
- Vertex shader guard: `(range > 0.001) ? saturate(...) : 1.0` — fogFactor=1.0 when range=0 (no fog)
- No visual artifacts from fog being disabled
- Battle Castle fog works via direct `SetFog()` call
