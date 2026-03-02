# Milestone M3 — Rendering Migration
# Planning Brief — 2026-03-02

## Scope Summary

**Contributing Epics:** EPIC-4 (Rendering Pipeline Migration)
**Total Story Points:** 48
**Total Stories:** 9
**Target Sprint:** TBD (insufficient velocity data)
**Planned At:** 2026-03-02
**Depends On:** M1 (SDL3 dependency), M2 (EPIC-2.1 windowing for render target)

## Contributing Epic Status

| Epic | Title | Stories Done | Validation |
|------|-------|-------------|------------|
| EPIC-4 | Rendering Pipeline Migration | 0/9 | NOT_VALIDATED |

## Epic Sequence

This is the **heaviest milestone** — a single epic with 48 story points across 9 stories representing the most complex technical transformation in the project.

### Sequence (strict dependency chain):

**Gate 0: Ground Truth Capture (BLOCKER)**
- 4.1 (Ground Truth Capture, 5pts) — MUST complete before any rendering changes
- Captures Windows OpenGL baseline screenshots for SSIM comparison

**Phase 3: MuRenderer Abstraction (parallel after 4.2)**
- 4.2 (MuRenderer Core API, 8pts) — creates abstraction layer over existing OpenGL
- Then parallel:
  - Track A: 4.3 (RenderQuad2D migration, 8pts) — ~80% of all rendering
  - Track B: 4.4 (Skeletal Mesh / RenderTriangles, 5pts) — characters, monsters, NPCs
  - Track C: 4.5 (Trail Effects / RenderQuadStrip, 3pts) — skill effects, ribbons
  - Track D: 4.6 (Blend & Pipeline State, 3pts) — state management

**Phase 4: SDL_gpu Backend (after all Phase 3 complete)**
- 4.7 (SDL_gpu Backend, 8pts) — replaces OpenGL with SDL_gpu (Metal/Vulkan/D3D)
- 4.8 (Shader Programs, 5pts) — HLSL → SPIR-V/MSL/DXIL via SDL_shadercross

**Phase 5: Texture System**
- 4.9 (Texture System Migration, 8pts) — CGlobalBitmap → SDL_gpu textures (~30,000 textures)

**Critical Path:** 4.1 → 4.2 → 4.3 → 4.7 → 4.9 (37 pts)

### Milestone target: TBD (run sprint-complete for velocity data)

## E2E User Journeys

**TODO — non-blocking stubs for milestone-validation:**

1. **M3-J1: Visual Parity on macOS (Metal)** — Player enters Lorencia → terrain, buildings, NPCs render → character model with equipment visible → skill effects render → SSIM > 0.99 vs Windows OpenGL baseline
2. **M3-J2: Visual Parity on Linux (Vulkan)** — Same journey on Linux → all visual elements render correctly → ground truth comparison passes
3. **M3-J3: Performance Parity** — Player in combat-heavy scene → FPS within 10% of OpenGL baseline → no >50ms frame hitches → frame timer confirms 30+ FPS sustained
4. **M3-J4: Texture Completeness** — Player traverses 3+ maps → all terrain textures load → character equipment renders → UI elements textured correctly → no missing/black textures

## Success Criteria

| # | Criterion | Source |
|---|-----------|--------|
| 1 | All OpenGL calls removed from codebase | EPIC-4 Validation |
| 2 | GLEW dependency removed | EPIC-4 Validation |
| 3 | Game renders on macOS (Metal), Linux (Vulkan), Windows (D3D) | EPIC-4 Validation / FR12-FR14 |
| 4 | Ground truth SSIM > 0.99 for all baselines on all platforms | EPIC-4 Validation / FR15 |
| 5 | No frame time regression (FPS within 10% of OpenGL baseline) | EPIC-4 Validation / NFR1 |
| 6 | All ~30,000 textures load correctly | EPIC-4 Validation |

## Risks

- **R1: Scope of OpenGL migration (111 glBegin sites, 14 files)** — This is the highest-volume code change in the entire MVP. Mitigation: phased approach through MuRenderer abstraction (Phase 3) before backend swap (Phase 4). Ground truth comparison validates each step.
- **R2: SDL_gpu maturity** — SDL_gpu is relatively new in SDL3. Edge cases in Metal/Vulkan backends may surface. Mitigation: validate on all three platforms at story 4.7, before texture migration.
- **R3: SDL_shadercross cross-compilation** — Shader cross-compilation from HLSL to SPIR-V/MSL/DXIL may have platform-specific issues. Mitigation: only 5 simple shaders (~150 total lines), can debug per-platform.
- **R4: Texture format compatibility** — ~30,000 textures in JPEG/BMP/TGA formats must all load via SDL_gpu. Mitigation: CGlobalBitmap LRU cache pattern preserved, only GPU upload changes.
- **R5: Anti-pattern: mixed OpenGL + MuRenderer** — During migration, mixing old and new render paths in the same pass causes visual corruption. Mitigation: story 4.3 enforces one-function-at-a-time migration with ground truth validation per commit.
- **R6: Multi-sprint duration** — At 48 points, this epic will likely span multiple sprints. Context continuity and regression risk increase. Mitigation: ground truth comparison at every step prevents silent regression.

## Next Steps

1. Complete M1 and M2 — prerequisites for rendering work
2. **CRITICAL: Capture ground truth baselines (story 4.1) before any rendering code changes**
3. Run `sprint-planning` to distribute EPIC-4 stories across sprints
4. Execute Phase 3 migration (abstraction layer) with parallel tracks
5. Execute Phase 4 (SDL_gpu backend swap) only after all Phase 3 stories complete
6. Execute Phase 5 (texture system) after backend is stable
7. Run `epic-validation` for EPIC-4
8. Run `milestone-validation` to verify all 6 success criteria
9. After `milestone-validation`, run `milestone-review` for go/no-go on M4
