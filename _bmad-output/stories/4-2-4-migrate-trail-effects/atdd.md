# ATDD Checklist — Story 4.2.4: Migrate Trail Effects to RenderQuadStrip

**Story Key:** `4-2-4-migrate-trail-effects`
**Flow Code:** VS1-RENDER-MIGRATE-QUADSTRIP
**Story Type:** `infrastructure`
**ATDD Phase:** RED (tests written, implementation pending)
**Date Generated:** 2026-03-10

---

## FSM Handoff Summary

| Field | Value |
|-------|-------|
| `atdd_checklist_path` | `_bmad-output/stories/4-2-4-migrate-trail-effects/atdd.md` |
| `test_files_created` | `MuMain/tests/render/test_traileffects_migration.cpp` |
| `implementation_checklist_complete` | FALSE (all items `[ ]` — pending implementation) |
| `ac_test_mapping` | See table below |

---

## AC-to-Test Mapping

| AC | Description (brief) | Test Case | Phase |
|----|---------------------|-----------|-------|
| AC-STD-2(b) | RenderQuadStrip call-through, 4 vertices, textureId=0 | `AC-STD-2 [4-2-4]: RenderQuadStrip call-through — single trail segment quad` | RED |
| AC-STD-2(c) | UV mapping Light1→currentTail, Light2→nextTail | `AC-STD-2 [4-2-4]: UV mapping from Light1/Light2` | RED |
| AC-VAL-1 | Luminosity PackABGR → 0xFF808080u, clamping, round-trip | `AC-VAL-1 [4-2-4]: Luminosity color packing — RenderQuadStrip sentinel` | RED |
| AC-2 | BITMAP_JOINT_FORCE: 4 verts, textureId=0, Lum color, Light1/2 UV | `AC-2 [4-2-4]: BITMAP_JOINT_FORCE trail — 4 vertices, textureId=0` | RED |
| AC-3 | GUILD_WAR_EVENT double-face: 2 independent calls, 4 verts each | `AC-3 [4-2-4]: GUILD_WAR_EVENT double-face — two separate RenderQuadStrip calls` | RED |
| AC-4 | RENDER_FACE_ONE + RENDER_FACE_TWO: independent flag-conditional calls | `AC-4 [4-2-4]: RENDER_FACE_ONE and RENDER_FACE_TWO — independent calls` | RED |
| AC-7 | textureId=0 sentinel accepted; zero normals for trail vertices | `AC-7 [4-2-4]: RenderQuadStrip textureId=0 sentinel accepted` | RED |

**ACs covered by existing tests (mapped from 4.2.3):**
- AC-STD-2(a) — Vertex3D struct layout: covered by `test_skeletalmesh_migration.cpp::AC-STD-2 [4-2-3]: Vertex3D struct layout`. No new test needed (same struct, same contract).

**ACs with no automated test (manual/grep only):**
- AC-1, AC-5, AC-6 — Structural migration of 4 `glBegin(GL_QUADS)` blocks and public API preservation → verified by grep (AC-VAL-4) and build (AC-6).
- AC-STD-3 — Grep verification: `grep -n "glBegin.*GL_QUADS\|glEnd" MuMain/src/source/RenderFX/ZzzEffectJoint.cpp` in lines 7150–7421 → zero hits.
- AC-VAL-3 — Windows manual visual validation (out of scope for automated tests; deferred to story 4.4.1 ground truth gate).

---

## Implementation Checklist

### Test Infrastructure

- [ ] `MuMain/tests/render/test_traileffects_migration.cpp` exists and is compiled (file created in RED phase)
- [ ] `target_sources(MuTests PRIVATE render/test_traileffects_migration.cpp)` is in `MuMain/tests/CMakeLists.txt` under Story 4.2.4 comment block (added in RED phase)
- [ ] Test file includes `<catch2/catch_approx.hpp>` and `<catch2/catch_test_macros.hpp>` — no gl* headers
- [ ] Test file includes `"MuRenderer.h"` for `mu::IMuRenderer`, `mu::Vertex3D`, `mu::Vertex2D`
- [ ] `RenderQuadStripCapture` inline test-double implements all `IMuRenderer` pure virtuals
- [ ] `PackABGR` local helper in test file matches production `ZzzEffectJoint.cpp::PackABGR` (clamped)

### AC-STD-2(b) — RenderQuadStrip Call-Through (4 vertices, textureId=0)

- [ ] `TEST_CASE("AC-STD-2 [4-2-4]: RenderQuadStrip call-through — single trail segment quad")` — SECTION "Single trail segment: exactly one RenderQuadStrip call with 4 vertices and textureId=0": passes after Task 2 migrates BITMAP_JOINT_FORCE
- [ ] `SECTION "RenderQuadStrip accepts exactly 4 vertices"`: passes once `IMuRenderer::RenderQuadStrip` interface is stable (already passes against test-double)

### AC-STD-2(c) — UV Mapping Contract

- [ ] `TEST_CASE("AC-STD-2 [4-2-4]: UV mapping from Light1/Light2")` — all 3 SECTION blocks pass
- [ ] SECTION "Light1 maps to u for currentTail vertices, Light2 maps to u for nextTail vertices": `verts[0].u == Light1`, `verts[2].u == Light2`
- [ ] SECTION "V-coordinate assignment": correct V at each vertex position in the 4-vertex layout
- [ ] SECTION "Light values at loop boundaries": first segment UV (Light1=0, Light2=step) correct

### AC-VAL-1 — Luminosity Color Packing

- [ ] `TEST_CASE("AC-VAL-1 [4-2-4]: Luminosity color packing — RenderQuadStrip sentinel")` — all 4 SECTION blocks pass:
  - [ ] `PackABGR(0.5, 0.5, 0.5, 1.0)` → R,G,B in [127, 128]; A == 0xFF
  - [ ] `PackABGR(1, 1, 1, 1)` → `0xFFFFFFFFu`
  - [ ] Overbright (>1.0) clamped to 0xFFFFFFFF — no wrap
  - [ ] Round-trip encode/decode for 5 luminosity values within margin 1/255

### AC-2 — BITMAP_JOINT_FORCE Trail Segment

- [ ] `TEST_CASE("AC-2 [4-2-4]: BITMAP_JOINT_FORCE trail — 4 vertices, textureId=0")` — SECTION passes after Task 2 complete:
  - [ ] 1 call recorded; 4 vertices; textureId == 0
  - [ ] `vertices[0].u == Light1`, `vertices[2].u == Light2`
  - [ ] All 4 vertices carry `lumColor`; all nx/ny/nz == 0
- [ ] Production code: `glBegin(GL_QUADS)` at line ~7197 in `ZzzEffectJoint.cpp` replaced with `mu::GetRenderer().RenderQuadStrip(forceVerts, 0u)`
- [ ] `PackABGR` helper added near top of `ZzzEffectJoint.cpp` (file-static inline)
- [ ] Commit: `refactor(render): migrate BITMAP_JOINT_FORCE trail segment to MuRenderer::RenderQuadStrip`

### AC-3 — GUILD_WAR_EVENT Double-Face Trail Segment

- [ ] `TEST_CASE("AC-3 [4-2-4]: GUILD_WAR_EVENT double-face — two separate RenderQuadStrip calls")` — both SECTION blocks pass after Task 3 complete:
  - [ ] 2 calls recorded; each 4 vertices; each textureId == 0
  - [ ] Both calls carry same packed color (`r*lum, g*lum, b*lum, 1.f`)
- [ ] Production code: both `glBegin(GL_QUADS)` blocks inside `#ifdef GUILD_WAR_EVENT` (lines ~7351–7368) replaced with two `RenderQuadStrip()` calls
- [ ] `glPushMatrix()` / `glTranslatef(t_bias)` / `glPopMatrix()` calls left in place (story 4.2.5 scope)
- [ ] Commit: `refactor(render): migrate GUILD_WAR_EVENT trail segment to MuRenderer::RenderQuadStrip`

### AC-4 — RENDER_FACE_ONE + RENDER_FACE_TWO Trail Segments

- [ ] `TEST_CASE("AC-4 [4-2-4]: RENDER_FACE_ONE and RENDER_FACE_TWO — independent calls")` — all 4 SECTION blocks pass after Task 4 complete:
  - [ ] Both flags → 2 calls, 4 verts each
  - [ ] FACE_ONE only → 1 call, 4 verts
  - [ ] FACE_TWO only → 1 call, 4 verts
  - [ ] Neither flag → 0 calls
- [ ] Production: `RENDER_FACE_ONE` block (lines ~7390–7402) `glBegin(GL_QUADS)` replaced with `RenderQuadStrip(faceOneVerts, 0u)`
- [ ] Production: `RENDER_FACE_TWO` block (lines ~7404–7421) `glBegin(GL_QUADS)` replaced with `RenderQuadStrip(faceTwoVerts, 0u)`
- [ ] BITMAP_JOINT_THUNDER UV scroll (`L1`/`L2` adjustment) preserved before vertex build
- [ ] Commit: `refactor(render): migrate RENDER_FACE_ONE/TWO trail segments to MuRenderer::RenderQuadStrip`

### AC-7 — RenderQuadStrip Per-Vertex Color (Prerequisite)

- [ ] `TEST_CASE("AC-7 [4-2-4]: RenderQuadStrip textureId=0 sentinel accepted")` — both SECTION blocks pass (already pass against test-double in RED phase)
- [ ] Production: `MuRenderer.cpp` `MuRendererGL::RenderQuadStrip` (lines ~103–124) verified to emit `glColor4f` ABGR unpack per vertex before `glVertex3f`
- [ ] If per-vertex color was missing: added with pattern from `MuRendererGL::RenderTriangles` (story 4.2.3, commit `046eb215`)
- [ ] If updated: commit `feat(render): add per-vertex color to MuRendererGL::RenderQuadStrip`

### AC-5 — No Remaining GL_QUADS in Migrated Paths (Grep Verification)

- [ ] `grep -n "glBegin.*GL_QUADS\|glEnd" MuMain/src/source/RenderFX/ZzzEffectJoint.cpp` — zero hits in lines 7150–7421 after all Tasks 2–4 complete
- [ ] Hits in out-of-scope files (`ZzzBMD.cpp`, `SceneManager.cpp`, `ZzzOpenglUtil.cpp`, `ZzzEffectBlurSpark.cpp`, `SideHair.cpp`, `ZzzEffectMagicSkill.cpp`) are acceptable

### AC-6 — Public API Unchanged

- [ ] `ZzzEffectJoint.h` — no function signatures modified (do NOT modify this file)
- [ ] All pre-existing callers of `RenderJoints()` compile and link unchanged

### AC-STD-1 — Code Standards Compliance

- [ ] `mu::` namespace used for all new calls (`mu::GetRenderer()`, `mu::Vertex3D`)
- [ ] `std::vector<mu::Vertex3D>` used for per-segment vertex buffers (no raw `new`/`delete`)
- [ ] `nullptr` used (no `NULL`)
- [ ] No `#ifdef _WIN32` in `ZzzEffectJoint.cpp` or `MuRenderer.cpp`
- [ ] `#pragma once` in all modified headers
- [ ] `PackABGR` helper is `static inline` (file-static, not exported)

### AC-STD-13 — Quality Gate

- [ ] `./ctl check` passes with 0 errors after all migrations applied
- [ ] cppcheck file count: 705 (post-4.2.3 baseline, `src/source/` only; test files not counted)
- [ ] clang-format: no changes to formatted output

### AC-STD-15 — Git Safety

- [ ] No incomplete rebase in working tree
- [ ] No force push to main

### AC-STD-16 — Test Infrastructure

- [ ] Catch2 3.7.1 used (`FetchContent`, `MuTests` target)
- [ ] Tests placed in `MuMain/tests/render/test_traileffects_migration.cpp`
- [ ] `target_sources` in `tests/CMakeLists.txt` under Story 4.2.4 comment block ✓ (done in ATDD phase)
- [ ] No `Catch::Approx` float comparisons without `#include <catch2/catch_approx.hpp>` ✓

### AC-VAL-2 — Quality Gate After Migration

- [ ] `./ctl check` passes 0 errors post-implementation

### AC-VAL-4 — Grep Verification

- [ ] `grep -n "glBegin.*GL_QUADS\|glEnd" MuMain/src/source/RenderFX/ZzzEffectJoint.cpp` — zero hits in lines 7150–7421

---

## PCC Compliance Summary

| Check | Status |
|-------|--------|
| Prohibited libraries used? | No — Catch2 only, no mocking framework |
| Required patterns followed? | Yes — `TEST_CASE`/`SECTION`/`REQUIRE`/`CHECK`, Allman braces, 4-space indent |
| Correct test profiles? | N/A — infrastructure story, no server profiles |
| Playwright used for frontend E2E? | N/A — no frontend component |
| Coverage target met? | N/A — threshold=0 for C++; new test adds coverage incrementally |
| No `gl*` calls in test TU? | Yes — confirmed, test-double only |
| No `new`/`delete` in test TU? | Yes — `std::vector` throughout |
| No `NULL` in test TU? | Yes — `nullptr` / no pointer operations |

---

## Output Files

| File | Status |
|------|--------|
| `MuMain/tests/render/test_traileffects_migration.cpp` | CREATED (RED phase) |
| `MuMain/tests/CMakeLists.txt` | MODIFIED — Story 4.2.4 `target_sources` block added |
| `_bmad-output/stories/4-2-4-migrate-trail-effects/atdd.md` | THIS FILE |
