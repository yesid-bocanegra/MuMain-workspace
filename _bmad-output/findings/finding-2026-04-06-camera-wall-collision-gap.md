# Camera Wall Collision Gap: No Geometry Intersection Prevention

**Date:** 2026-04-06
**Discovered during:** SDL3 renderer streak artifact investigation (post-7-9-7)
**Context:** Sprint 7, EPIC-4 (Rendering Pipeline Migration), Feature 7.9
**Discovery type:** feature-gap
**Urgency:** backlog
**Urgency justification:** Camera wall penetration existed in the original OpenGL build. Not a regression — but a quality-of-life gap that becomes more noticeable now that rendering artifacts are resolved.

---

## Summary

The camera system computes its position purely from the hero's world position, `CameraDistance`, and `CameraAngle` — with **no wall or geometry collision detection**. When the camera angle places it inside or behind terrain/buildings, it clips through geometry, showing interior faces or the world from behind walls.

This behavior is inherited from the original game code and is not a regression introduced by the SDL3 migration. However, it is more visible now that streak artifacts have been eliminated by the deferred draw command system.

---

## Camera System Architecture

The camera position is computed in `CameraUtility.cpp:120-189`:

```
1. CameraDistance (default 1000, per-scene) → offset vector (0, -CameraDistance, 0)
2. CameraAngle (pitch/yaw/roll) → rotation matrix via AngleMatrix()
3. Rotated offset + hero position → camera world position
4. Z adjustment: hero Z + CameraDistance - 150
5. Special terrain override: TW_HEIGHT → Z=1201
6. Custom distance override: g_fCameraCustomDistance
```

**No step performs ray-cast or intersection testing against terrain or building geometry.**

---

## Affected Code

| File | Lines | Description |
|------|-------|-------------|
| `Core/CameraUtility.cpp` | 120-189 | `CalculateCameraPosition()` — no collision check |
| `Core/CameraUtility.cpp` | 225-257 | `UpdateCustomCameraDistance()` / `UpdateCameraDistance()` — distance only |
| `Core/CameraMove.cpp` | 1-400 | Waypoint system — blends distance levels, no geometry awareness |
| `Scenes/SceneCore.cpp` | 107-108 | `CameraDistance=1000`, `CameraDistanceTarget=1000` |
| `RenderFX/ZzzOpenglUtil.cpp` | 580-616 | `BeginOpengl()` — applies camera transform to modelview matrix |

## Related (working correctly)

| File | Lines | Description |
|------|-------|-------------|
| `RenderFX/ZzzOpenglUtil.cpp` | 25-30 | `gluPerspective()` — GLM perspective with CameraViewNear=20 |
| `shaders/basic_textured.vert.hlsl` | 29 | `SV_ClipDistance0 = pos.w - 1.0` — near-plane safety net (correct) |

---

## SV_ClipDistance Threshold Analysis

The vertex shader clips at `pos.w - 1.0` (eye-space distance < 1 unit). This is correct:
- **Cannot use CameraViewNear (20.0):** 2D ortho geometry has `w=1.0` — threshold of 20.0 would clip all 2D rendering.
- **Perspective near plane (20 units)** already clips 3D geometry via the standard clip volume (`0 <= z_clip <= w`).
- The `SV_ClipDistance` at 1.0 is a safety net for degenerate behind-camera triangles only.

---

## Proposed Story Scope

**Title:** Camera wall collision — prevent camera from penetrating terrain and buildings

**Goal:** When the computed camera position is inside or behind geometry, clamp the camera distance to keep it outside.

**Approach options:**
1. **Ray-cast from hero to camera:** Cast a ray from hero position to computed camera position. If it intersects terrain/building geometry, move camera to intersection point minus a small margin.
2. **Terrain height check:** Simpler — ensure camera Z is always above terrain height at camera XY. Doesn't handle walls/buildings but prevents underground clipping.
3. **Sphere sweep:** Sweep a small sphere along the hero→camera vector, stopping at first collision. More robust than ray-cast for camera volume.

**Key considerations:**
- MU Online terrain is heightmap-based (`TerrainWall[]`, `TerrainHeight[]`) — heightmap query is O(1)
- Buildings/structures are BMD meshes — ray-cast against these is more expensive
- Original game (all seasons) never had camera collision — this is a new feature, not a fix
- Performance budget: must complete within 1ms per frame

**Estimated effort:** 8-13 points depending on approach (terrain-only vs. full geometry)

**Dependencies:** Terrain data structures in `ZzzLodTerrain.cpp`, heightmap access in `TerrainWall[]`/`TerrainHeight[]`
