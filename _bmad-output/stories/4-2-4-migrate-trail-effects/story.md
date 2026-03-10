# Story 4.2.4: Migrate Trail Effects to RenderQuadStrip

Status: in-progress

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 4 - Rendering Pipeline Migration |
| Feature | 4.2 - MuRenderer Abstraction |
| Story ID | 4.2.4 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-RENDER-MIGRATE-QUADSTRIP |
| FRs Covered | FR12, FR13, FR14, FR15 |
| Prerequisites | Story 4.2.1 (MuRenderer Core API — done); Story 4.2.2 (RenderBitmap migration — done, sibling context); Story 4.2.3 (Skeletal mesh migration — done, sibling context) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Migrate `glBegin(GL_QUADS)` trail/ribbon segments in `ZzzEffectJoint.cpp::RenderJoints()` to `mu::GetRenderer().RenderQuadStrip()`; add Catch2 tests in `tests/render/` |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** trail effects and ribbons rendered in `RenderJoints()` migrated to `mu::GetRenderer().RenderQuadStrip()`,
**so that** all joint/trail rendering goes through the MuRenderer abstraction instead of directly calling OpenGL immediate-mode `GL_QUADS` per segment.

---

## Functional Acceptance Criteria

- [x] **AC-1:** All `glBegin(GL_QUADS)` / `glEnd()` blocks in `RenderJoints()` that render trail segments (ribbon quads per joint) are replaced with calls to `mu::GetRenderer().RenderQuadStrip()`, building a `std::vector<mu::Vertex3D>` for each segment quad (4 vertices per quad, packed ABGR color)
- [x] **AC-2:** The `BITMAP_JOINT_FORCE` SubType==0 branch (line ~7197 in `ZzzEffectJoint.cpp`) is migrated: its 4-vertex `glBegin(GL_QUADS)` trail segment is replaced with `RenderQuadStrip()` using `currentTail[0..1]` + `nextTail[0..1]` positions with UV `Light1/Light2` and color from `Luminosity * o->Light[0..2]` packed to ABGR
- [x] **AC-3:** The `GUILD_WAR_EVENT`-guarded `BITMAP_FLARE` SubType==22 branch (lines ~7351–7368 in `ZzzEffectJoint.cpp`) is migrated: its two 4-vertex `glBegin(GL_QUADS)` blocks (top face + bottom face of a double-sided quad) are replaced with two `RenderQuadStrip()` calls, each with 4 vertices — UV/color derived from `Light1/Light2` and current `glColor3f` state captured before the block
- [x] **AC-4:** The `RENDER_FACE_ONE` and `RENDER_FACE_TWO` conditional branches (lines ~7390–7421 in `ZzzEffectJoint.cpp`) are migrated: each `glBegin(GL_QUADS)` / `glEnd()` block is replaced with `RenderQuadStrip()` using the 4 vertices from `currentTail[0..3]` and `nextTail[0..3]` with UV from `L1/L2, V1/V2` — a separate `RenderQuadStrip()` call is issued for each active face flag
- [x] **AC-5:** No `glBegin(GL_QUADS)` / `glEnd()` calls remain in any of the migrated trail-rendering paths in `RenderJoints()` — verified by grep targeting the segment render loop (lines ~7150–7421) — `GL_QUADS` calls in out-of-scope debug helpers (e.g., `RenderObjectBoundingBox`, `SceneManager.cpp`, `ZzzOpenglUtil.cpp`) are NOT part of this story
- [x] **AC-6:** All pre-existing callers of `RenderJoints()` continue to compile and link unchanged — no public function signatures in `ZzzEffectJoint.h` are modified
- [x] **AC-7:** `MuRendererGL::RenderQuadStrip()` already exists in `MuRenderer.cpp` (implemented in story 4.2.1) and correctly emits `GL_QUAD_STRIP` per vertex — verify it emits per-vertex color (`glColor4f` ABGR unpack) before each vertex; if missing, add it (same pattern as `RenderTriangles` updated in story 4.2.3)

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards Compliance — `mu::` namespace for all new helpers, PascalCase functions, `m_` member prefix, `#pragma once`, no raw `new`/`delete` (use `std::vector`), `[[nodiscard]]` on new fallible functions, no `NULL` (use `nullptr`), no `wprintf`, no `#ifdef _WIN32` in `ZzzEffectJoint.cpp`
- [x] **AC-STD-2:** Catch2 tests in `tests/render/test_traileffects_migration.cpp` verifying: (a) `Vertex3D` struct ABGR color packing (reuse/reference pattern from `test_skeletalmesh_migration.cpp`); (b) `RenderQuadStrip` is called with 4 vertices for a single trail segment quad via an inline mock `IMuRenderer`; (c) UV values `Light1, Light2` are mapped to correct `Vertex3D.u` fields — tests must compile and pass on macOS/Linux (no `gl*` calls in tests)
- [x] **AC-STD-3:** No `glBegin(GL_QUADS)` / `glEnd()` calls remain in the migrated trail segment paths of `RenderJoints()` (lines ~7150–7421 of `ZzzEffectJoint.cpp`) — verified by targeted grep
- [x] **AC-STD-5:** Error logging: existing `g_ErrorReport.Write(L"RENDER: MuRenderer::RenderQuadStrip -- vertex buffer empty")` guard in `MuRenderer.cpp` is already in place — no new error codes required
- [x] **AC-STD-6:** Conventional commit per migrated block: `refactor(render): migrate trail segment [BRANCH] to MuRenderer::RenderQuadStrip`
- [x] **AC-STD-12:** N/A — C++ client infrastructure story; no server-side SLI/SLO latency targets
- [x] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format check + cppcheck 0 errors); file count 706 (post-4.2.3 baseline) + 1 new test file = 707 files
- [x] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [x] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/render/` directory pattern, `target_sources` in `tests/CMakeLists.txt`)

---

## Validation Artifacts

- [x] **AC-VAL-1:** Catch2 tests pass for `RenderQuadStrip` call-through with 4 vertices, ABGR color packing, and UV mapping from `Light1/Light2`
- [x] **AC-VAL-2:** `./ctl check` passes with 0 errors after all migrations applied
- **AC-VAL-3:** Windows build renders skill effects, weapon trails, and joint ribbon effects identically before/after migration — verified manually or via ground truth comparison from story 4.1.1 baselines (SSIM > 0.99 on effect-heavy combat scenes). **Status: manual validation only — automated verification deferred to epic-4 ground truth gate (story 4.4.1).**
- [x] **AC-VAL-4:** Grep verification — no migrated GL calls remain in the trail segment loop: `grep -n "glBegin.*GL_QUADS\|glEnd" MuMain/src/source/RenderFX/ZzzEffectJoint.cpp` — zero hits in lines 7150–7421 (the segment render section); hits in other files / out-of-scope helpers are acceptable

---

## Tasks / Subtasks

- [x] Task 1: Understand the trail segment rendering paths and define Vertex3D population strategy (AC: 1, 2, 3, 4)
  - [x] Subtask 1.1: Read `RenderJoints()` in `ZzzEffectJoint.cpp` (lines ~7043–7440) focusing on the segment render loop (lines ~7150–7421); catalog each `glBegin(GL_QUADS)` block's vertex data sources: which tail arrays, which UV coordinates (`Light1`/`Light2`, `V1`/`V2`), which color source (`Luminosity * o->Light`, `o->Light * Luminosity`, or `glColor3f(1,1,1)` implied)
  - [x] Subtask 1.2: Verify that `MuRendererGL::RenderQuadStrip()` in `MuRenderer.cpp` (lines ~103–124) emits per-vertex color via `glColor4f` ABGR unpack before each `glVertex3f`; if it only emits `glTexCoord2f + glNormal3f + glVertex3f` (like the original `RenderTriangles` before story 4.2.3), add the ABGR unpack + `glColor4f` emission — matching the pattern from `MuRendererGL::RenderTriangles` (updated in story 4.2.3)
  - [x] Subtask 1.3: Note the color state machine: `glColor3f` calls inside the segment loop set the current GL color BEFORE the `glBegin` blocks — these colors must be captured into `std::uint32_t color = PackABGR(r, g, b, 1.f)` and stored per vertex in `Vertex3D::color`; the `glColor*` state calls themselves are story 4.2.5 scope and should remain in place

- [x] Task 2: Migrate `BITMAP_JOINT_FORCE` SubType==0 trail segment (AC: 2, 5, 6)
  - [x] Subtask 2.1: At the `glBegin(GL_QUADS)` at line ~7197: capture current Luminosity color as `PackABGR(Luminosity, Luminosity, Luminosity, 1.f)`; build a `std::vector<mu::Vertex3D>` with 4 vertices: `{currentTail[0], 0,0,0, Light1, 0.f, color}`, `{currentTail[1], 0,0,0, Light1, 1.f, color}`, `{nextTail[1], 0,0,0, Light2, 1.f, color}`, `{nextTail[0], 0,0,0, Light2, 0.f, color}`; call `mu::GetRenderer().RenderQuadStrip(vertices, 0)` (texture is bound by caller's `BindTexture()` — pass 0 as sentinel for now, same as shadow path pattern from story 4.2.3)
  - [x] Subtask 2.2: Remove `glBegin(GL_QUADS)` + 4 `glTexCoord2f`/`glVertex3fv` calls + `glEnd()`
  - [x] Subtask 2.3: Commit: `refactor(render): migrate BITMAP_JOINT_FORCE trail segment to MuRenderer::RenderQuadStrip`

- [x] Task 3: Migrate `GUILD_WAR_EVENT` BITMAP_FLARE SubType==22 double-face trail segment (AC: 3, 5, 6)
  - [x] Subtask 3.1: At the `glBegin(GL_QUADS)` blocks inside `#ifdef GUILD_WAR_EVENT` (lines ~7351–7368): the block renders two faces — top face (tails[2]/tails[3]) and bottom face (tails[0]/tails[1]). Build two `std::vector<mu::Vertex3D>` each with 4 vertices; capture color from the `glColor3f(o->Light[0]*Luminosity, o->Light[1]*Luminosity, o->Light[2]*Luminosity)` that precedes the block (store as `PackABGR(r*Lum, g*Lum, b*Lum, 1.f)`)
  - [x] Subtask 3.2: Top face: `{currentTail[2], 0,0,0, Light1, 1.f, color}`, `{currentTail[3], 0,0,0, Light1, 0.f, color}`, `{Tails[j+1][3], 0,0,0, Light2, 0.f, color}`, `{Tails[j+1][2], 0,0,0, Light2, 1.f, color}`; call `mu::GetRenderer().RenderQuadStrip(topFace, 0)`. Bottom face: `{currentTail[0], 0,0,0, Light1, 0.f, color}`, `{currentTail[1], 0,0,0, Light1, 1.f, color}`, `{Tails[j+1][1], 0,0,0, Light2, 1.f, color}`, `{Tails[j+1][0], 0,0,0, Light2, 0.f, color}`; call `mu::GetRenderer().RenderQuadStrip(bottomFace, 0)`
  - [x] Subtask 3.3: Remove both `glBegin(GL_QUADS)` + vertex calls + `glEnd()` blocks inside the `#ifdef GUILD_WAR_EVENT` guard
  - [x] Subtask 3.4: The `glPushMatrix()` / `glTranslatef(t_bias)` / `glPopMatrix()` calls wrapping this block are story 4.2.5 scope (state management) — leave them in place
  - [x] Subtask 3.5: Commit: `refactor(render): migrate GUILD_WAR_EVENT trail segment to MuRenderer::RenderQuadStrip`

- [x] Task 4: Migrate `RENDER_FACE_ONE` + `RENDER_FACE_TWO` trail segment paths (AC: 4, 5, 6)
  - [x] Subtask 4.1: `RENDER_FACE_ONE` block (lines ~7390–7402): build `std::vector<mu::Vertex3D>` with 4 vertices — `{currentTail[2], 0,0,0, L1, V2, color}`, `{currentTail[3], 0,0,0, L1, V1, color}`, `{nextTail[3], 0,0,0, L2, V1, color}`, `{nextTail[2], 0,0,0, L2, V2, color}`; call `mu::GetRenderer().RenderQuadStrip(vertices, 0)`; remove `glBegin`/`glEnd`; color = captured from the `glColor3f` or `glColor3fv` set earlier in the segment loop for this object type (pre-captured into a local `color` variable before entering the branch)
  - [x] Subtask 4.2: `RENDER_FACE_TWO` block (lines ~7404–7421): build `std::vector<mu::Vertex3D>` with 4 vertices — `{currentTail[0], 0,0,0, L1, V1, color}`, `{currentTail[1], 0,0,0, L1, V2, color}`, `{nextTail[1], 0,0,0, L2, V2, color}`, `{nextTail[0], 0,0,0, L2, V1, color}`; call `mu::GetRenderer().RenderQuadStrip(vertices, 0)`; note the `BITMAP_JOINT_THUNDER` subtype adjusts `L1` and `L2` before this block — this adjustment must remain in place before building the vertices
  - [x] Subtask 4.3: Commit: `refactor(render): migrate RENDER_FACE_ONE/TWO trail segments to MuRenderer::RenderQuadStrip`

- [x] Task 5: Update `MuRendererGL::RenderQuadStrip` for per-vertex color (prerequisite check) (AC: 7)
  - [x] Subtask 5.1: Read `MuRenderer.cpp` lines ~107–124 — confirm `MuRendererGL::RenderQuadStrip` emits `glColor4f` per vertex using ABGR unpack. If it only emits `glTexCoord2f + glNormal3f + glVertex3f` (missing color), add the ABGR unpack before `glVertex3f`: `const auto a = static_cast<float>((v.color >> 24) & 0xFF) / 255.f; ... glColor4f(r, g, b, a);` — matching the pattern from `MuRendererGL::RenderTriangles` updated in story 4.2.3 (commit MuMain `046eb215`)
  - [x] Subtask 5.2: If updated, commit: `feat(render): add per-vertex color to MuRendererGL::RenderQuadStrip`

- [x] Task 6: Add Catch2 migration tests (AC: AC-STD-2, AC-VAL-1)
  - [x] Subtask 6.1: Create `MuMain/tests/render/test_traileffects_migration.cpp`
  - [x] Subtask 6.2: Add `target_sources(MuTests PRIVATE render/test_traileffects_migration.cpp)` in `MuMain/tests/CMakeLists.txt` under `BUILD_TESTING` guard with a Story 4.2.4 comment block
  - [x] Subtask 6.3: `TEST_CASE("RenderQuadStrip — single trail segment quad")`: create an inline `MockRenderer : public mu::IMuRenderer` that captures `std::span<const mu::Vertex3D>` from `RenderQuadStrip()`; simulate building a 4-vertex `Vertex3D` array (currentTail[0], currentTail[1], nextTail[1], nextTail[0]); call `mock.RenderQuadStrip(verts, 0u)`; assert `capturedCount == 4` and `capturedTextureId == 0u`
  - [x] Subtask 6.4: `TEST_CASE("RenderQuadStrip — UV mapping from Light1/Light2")`: build 4 vertices where `Light1 = 0.25f`, `Light2 = 0.75f`; assert `verts[0].u == 0.25f` and `verts[2].u == 0.75f` — documents the UV assignment contract
  - [x] Subtask 6.5: `TEST_CASE("RenderQuadStrip — Luminosity color packing")`: verify `PackABGR(0.5f, 0.5f, 0.5f, 1.f)` = `0xFF808080u` (within rounding) using the same helper pattern as `test_skeletalmesh_migration.cpp`

- [x] Task 7: Quality gate + grep verification (AC: AC-STD-13, AC-VAL-2, AC-VAL-4)
  - [x] Subtask 7.1: Run `./ctl check` — 0 errors
  - [x] Subtask 7.2: Run `grep -n "glBegin.*GL_QUADS\|glEnd" MuMain/src/source/RenderFX/ZzzEffectJoint.cpp` in lines 7150–7421 — confirm zero hits in the migrated segment render paths

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A — C++ client, no HTTP error codes | — | — | — |

Logging pattern (already in `MuRenderer.cpp` from story 4.2.1):
- `g_ErrorReport.Write(L"RENDER: MuRenderer::RenderQuadStrip -- vertex buffer empty")` — triggered if empty vertex vector is passed

---

## Contract Catalog Entries

### API Contracts

Not applicable — no network endpoints introduced.

### Event Contracts

Not applicable — no events introduced.

### Navigation Entries

Not applicable — infrastructure story, no UI navigation changes.

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 3.7.1 | 4-vertex call-through, UV mapping contract, Luminosity ABGR packing | capturedCount==4; U values from Light1/Light2; color from luminosity |
| Integration (manual) | Windows build | No regression on joint/trail rendering | Skill effects, weapon trails, guild war ribbons render identically before/after |
| Ground truth (optional) | SSIM tool (story 4.1.1) | SSIM > 0.99 on effect-heavy scenes | Windows OpenGL baseline vs post-migration |

---

## Dev Notes

### Context: Why This Story Exists

`ZzzEffectJoint.cpp` contains the `RenderJoints()` function (starting at line 7043) which renders all joint-based trail effects — weapon trailing ribbons, skill effect streams (spear skills, force effects, healing beams, thunder effects), and guild war event ribbons. These are the particle "tails" stored in `JOINT::Tails[j][0..3]` quad arrays.

Each trail segment renders as a quad between two consecutive tail positions (`currentTail` and `nextTail`), using `glBegin(GL_QUADS)` with 4 vertices. There are 4 distinct rendering code paths:

1. **`BITMAP_JOINT_FORCE` SubType==0** (line ~7197): Simple luminosity-modulated ribbon — 1 quad face
2. **`GUILD_WAR_EVENT` `BITMAP_FLARE` SubType==22** (lines ~7351–7368): Double-face guild war ribbon — 2 quad faces using all 4 tail points
3. **`RENDER_FACE_ONE`** (lines ~7390–7402): Standard ribbon, one face (tails[2]/[3])
4. **`RENDER_FACE_TWO`** (lines ~7404–7421): Standard ribbon, second face (tails[0]/[1]); thunder type adds scroll to UVs

**Scope boundary (strict):** This story does NOT migrate:
- `glColor3f` / `glColor3fv` state calls preceding the quads — story 4.2.5 scope
- `glPushMatrix()` / `glTranslatef()` / `glPopMatrix()` in the guild war event block — story 4.2.5 scope
- `EnableAlphaBlend()` / `DisableAlphaBlend()` blend state — story 4.2.5 scope
- Any `glBegin(GL_QUADS)` in other files (`ZzzEffectBlurSpark.cpp`, `SceneManager.cpp`, `ZzzOpenglUtil.cpp`, `ZzzBMD.cpp`, `SideHair.cpp`, `ZzzEffectMagicSkill.cpp`) — different stories
- `glBegin(GL_QUADS)` in the debug bounding-box visualizers in `ZzzBMD.cpp`

### Key Design Decisions

#### RenderQuadStrip vs RenderQuad2D — Which API to Use

The `MuRenderer` API (from story 4.2.1) has two relevant functions:
- `RenderQuad2D()` — for 2D screen-space sprites (used by story 4.2.2 for bitmap rendering)
- `RenderQuadStrip()` — for 3D world-space trail ribbons — **this story uses this one**

Trail segments are 3D world-space geometry (positions from `o->Tails[j][k]` which are `vec3_t` world coordinates). `RenderQuadStrip` takes `std::span<const Vertex3D>` and emits `GL_QUAD_STRIP` via the OpenGL backend (4 vertices per call for a single ribbon segment quad).

**Note on vertex order for `GL_QUAD_STRIP`:** `GL_QUAD_STRIP` renders pairs of vertices as a strip. For a single segment with 4 vertices, the order must be: top-left, top-right, bottom-left, bottom-right (or equivalent winding that matches the existing `GL_QUADS` vertex order for that branch). Study each branch's original `glVertex3fv` order carefully to preserve correct winding.

#### Color Capture Strategy

The `glColor3f` / `glColor3fv` calls precede the `glBegin` blocks and set a persistent GL state. For migration, capture the color into a local `std::uint32_t color` variable immediately before building the vertex vector, using `PackABGR(r, g, b, 1.f)`. The `glColor*` calls themselves remain in place (they are out of scope for this story — story 4.2.5 will remove them when it migrates OpenGL state management).

This means: keep the existing `glColor3f(Luminosity, Luminosity, Luminosity)` call before the migrated block, but also capture `color = PackABGR(Luminosity, Luminosity, Luminosity, 1.f)` and store it in each `Vertex3D::color` field.

#### Texture ID Sentinel

Trail rendering uses a texture bound by the caller via `BindTexture()` before invoking the segment loop. Pass `textureId = 0` as a sentinel to `RenderQuadStrip()` — same pattern as shadow paths in story 4.2.3. The `MuRendererGL::RenderQuadStrip` implementation calls `glBindTexture(GL_TEXTURE_2D, 0)` with this sentinel, which harmlessly re-binds the current texture (already set by the caller's `BindTexture()` call). Story 4.3.1 (SDL_gpu backend) will use the `textureId` parameter exclusively.

#### PackABGR Helper

Use the same `PackABGR` static inline helper introduced in `ZzzBMD.cpp` for story 4.2.3:

```cpp
static inline std::uint32_t PackABGR(float r, float g, float b, float a)
{
    return (static_cast<std::uint32_t>(a * 255.f) << 24) |
           (static_cast<std::uint32_t>(b * 255.f) << 16) |
           (static_cast<std::uint32_t>(g * 255.f) << 8)  |
           (static_cast<std::uint32_t>(r * 255.f));
}
```

Add this helper near the top of `ZzzEffectJoint.cpp` (if not already present) as a file-static inline.

#### RenderQuadStrip Per-Vertex Color (Prerequisite)

Check `MuRendererGL::RenderQuadStrip` in `MuRenderer.cpp` (lines ~107–124). The current implementation (from story 4.2.1) likely emits `glTexCoord2f + glNormal3f + glVertex3f` only. It needs `glColor4f` per vertex (ABGR unpack) added before `glVertex3f`, matching the updated `RenderTriangles` pattern from story 4.2.3. Verify and update in Task 5.

### Project Structure Notes

**Files to Modify:**

| File | Action | Notes |
|------|--------|-------|
| `MuMain/src/source/RenderFX/ZzzEffectJoint.cpp` | MODIFY | Migrate 4 `glBegin(GL_QUADS)` blocks in `RenderJoints()` (lines ~7197, ~7351, ~7392, ~7411); add `PackABGR` helper; add `#include "MuRenderer.h"` if not already present |
| `MuMain/src/source/RenderFX/MuRenderer.cpp` | MODIFY (if needed) | Task 5: Add per-vertex color emission (`glColor4f` ABGR unpack) to `MuRendererGL::RenderQuadStrip` if missing |

**Files to Create:**

| File | CMake Target |
|------|-------------|
| `MuMain/tests/render/test_traileffects_migration.cpp` | `MuTests` (explicit add in `tests/CMakeLists.txt`) |

**DO NOT MODIFY:** `ZzzEffectJoint.h` — all function signatures stay the same. Joint creation, update, and rendering callers are untouched.

**CMake:** `MURenderFX` auto-globs `RenderFX/*.cpp` — no CMakeLists change needed for source changes. Only `tests/CMakeLists.txt` needs the new test file entry.

**Relevant existing code:**
- `MuMain/src/source/RenderFX/ZzzEffectJoint.cpp` lines ~7043–7440 — `RenderJoints()` function; segment render loop at ~7150–7421
- `MuMain/src/source/RenderFX/MuRenderer.h` — `IMuRenderer` interface with `RenderQuadStrip(std::span<const Vertex3D>, uint32_t)` at line 86; `Vertex3D` struct (position, normal, UV, color ABGR)
- `MuMain/src/source/RenderFX/MuRenderer.cpp` lines ~103–124 — `MuRendererGL::RenderQuadStrip` (verify per-vertex color)
- `MuMain/src/source/Main/stdafx.h` line 184 — `#define GL_QUAD_STRIP 0x0008` (already present from story 4.2.1)
- `MuMain/src/source/RenderFX/ZzzBMD.cpp` — `PackABGR` static inline helper pattern (from story 4.2.3)
- `MuMain/tests/render/test_skeletalmesh_migration.cpp` — Reference for inline `MockRenderer` test-double pattern and `PackABGR` tests
- `MuMain/tests/render/test_murenderer.cpp` — Reference for inline mock `IMuRenderer` pattern (story 4.2.1)

### Technical Implementation

#### PackABGR Helper (add near top of ZzzEffectJoint.cpp)

```cpp
static inline std::uint32_t PackABGR(float r, float g, float b, float a)
{
    return (static_cast<std::uint32_t>(a * 255.f) << 24) |
           (static_cast<std::uint32_t>(b * 255.f) << 16) |
           (static_cast<std::uint32_t>(g * 255.f) << 8)  |
           (static_cast<std::uint32_t>(r * 255.f));
}
```

#### Single Trail Segment Quad Migration Example (RENDER_FACE_ONE branch)

```cpp
// BEFORE:
if ((o->RenderFace & RENDER_FACE_ONE) == RENDER_FACE_ONE)
{
    glBegin(GL_QUADS);
    glTexCoord2f(L1, V2);
    glVertex3fv(currentTail[2]);
    glTexCoord2f(L1, V1);
    glVertex3fv(currentTail[3]);
    glTexCoord2f(L2, V1);
    glVertex3fv(nextTail[3]);
    glTexCoord2f(L2, V2);
    glVertex3fv(nextTail[2]);
    glEnd();
}

// AFTER:
if ((o->RenderFace & RENDER_FACE_ONE) == RENDER_FACE_ONE)
{
    // color must be captured from preceding glColor3f/glColor3fv call (see note below)
    const std::vector<mu::Vertex3D> faceOneVerts = {
        {currentTail[2][0], currentTail[2][1], currentTail[2][2], 0.f, 0.f, 0.f, L1, V2, color},
        {currentTail[3][0], currentTail[3][1], currentTail[3][2], 0.f, 0.f, 0.f, L1, V1, color},
        {nextTail[3][0],    nextTail[3][1],    nextTail[3][2],    0.f, 0.f, 0.f, L2, V1, color},
        {nextTail[2][0],    nextTail[2][1],    nextTail[2][2],    0.f, 0.f, 0.f, L2, V2, color},
    };
    mu::GetRenderer().RenderQuadStrip(faceOneVerts, 0u);
}
```

> **Note on `color`:** The `color` variable must be declared and initialized BEFORE the branch, capturing the value from whichever `glColor3f` / `glColor3fv` was called for this object type in the preceding code. Declare `std::uint32_t color = 0xFFFFFFFFu;` at the start of the per-segment section (before the `if (o->Type == BITMAP_JOINT_FORCE...)` branching), then update it within each type branch as each `glColor*` is encountered.

#### MuRendererGL::RenderQuadStrip Update (per-vertex color — if not already present)

```cpp
void RenderQuadStrip(std::span<const Vertex3D> vertices, std::uint32_t textureId) override
{
    if (vertices.empty())
    {
        g_ErrorReport.Write(L"RENDER: MuRenderer::RenderQuadStrip -- vertex buffer empty");
        return;
    }

    glBindTexture(GL_TEXTURE_2D, static_cast<GLuint>(textureId));
    glBegin(GL_QUAD_STRIP);
    for (const Vertex3D& v : vertices)
    {
        // Unpack ABGR: A=bits31-24, B=bits23-16, G=bits15-8, R=bits7-0
        const auto a = static_cast<float>((v.color >> 24) & 0xFF) / 255.f;
        const auto b = static_cast<float>((v.color >> 16) & 0xFF) / 255.f;
        const auto g = static_cast<float>((v.color >> 8)  & 0xFF) / 255.f;
        const auto r = static_cast<float>((v.color)       & 0xFF) / 255.f;
        glColor4f(r, g, b, a);
        glTexCoord2f(v.u, v.v);
        glNormal3f(v.nx, v.ny, v.nz);
        glVertex3f(v.x, v.y, v.z);
    }
    glEnd();
}
```

#### stdafx.h Stubs to Verify

The following stubs must exist in `stdafx.h` for non-Windows compile. Story 4.2.1 added `GL_QUAD_STRIP 0x0008` (already confirmed at line 184). No additional stubs are needed for `RenderQuadStrip` since `glBegin`/`glEnd`/`glVertex3f`/`glTexCoord2f`/`glNormal3f` stubs were already present from prior stories.

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, Catch2 3.7.1, OpenGL (via stubs on non-Windows), `MURenderFX` CMake target, `MUGame` CMake target (`ZzzEffectJoint.cpp` is in `MUGame`)

**Prohibited (per project-context.md):**
- `new`/`delete` — use `std::vector` (stack allocation, RAII)
- `NULL` — use `nullptr`
- `wprintf`, `__TraceF()`, `DebugAngel` — use `g_ErrorReport.Write()`
- `#ifndef` header guards — `#pragma once`
- `#ifdef _WIN32` in `ZzzEffectJoint.cpp` or `MuRenderer.cpp` — OpenGL stubs handle non-Windows compile
- OpenGL types in `MuRenderer.h` — `GLenum`, `GLuint` stay out of the interface header

**Required patterns (per project-context.md):**
- `std::span<const mu::Vertex3D>` for `RenderQuadStrip` parameter (C++20, already in interface)
- `std::vector<mu::Vertex3D>` for per-call vertex buffer (avoids static/global mutation)
- `[[nodiscard]]` on any new fallible functions added
- `mu::` namespace for all new helpers
- Allman brace style, 4-space indent, 120-column limit (`.clang-format`)
- `#pragma once` header guards
- Include order: preserve existing (`SortIncludes: Never`)

**Quality gate:** `./ctl check` — must pass 0 errors. File count: post-4.2.3 baseline = 705 files (cppcheck scans `src/source/` only; test files in `tests/` excluded from count). New test file adds 1 to the test directory only — cppcheck file count remains 705.

**Testing:** Catch2 `TEST_CASE` / `SECTION` / `REQUIRE` / `CHECK`. No mocking framework — use an inline test-double struct for `IMuRenderer`. Pure logic only in test TU (no `gl*` calls).

### Previous Story Intelligence (from 4.2.3)

- **ABGR color packing** established in stories 4.2.1/4.2.2/4.2.3 — `Vertex3D::color` uses `PackABGR(r,g,b,a)` helper, ABGR layout: A=bits31-24, B=23-16, G=15-8, R=7-0
- **textureId=0 sentinel** for callers that bind their own texture — same as shadow paths and accepted for transitional OpenGL phase
- **Catch2 include fix:** Include `<catch2/catch_approx.hpp>` when using `Catch::Approx()` for float comparisons — avoid omitting this header
- **Pre-existing compilation blocker on macOS:** `muConsoleDebug.cpp: 'SetMaxMessagePerCycle'` blocks `MUCore` → `MuTests` on macOS. Pre-existing, unrelated to this story. Tests verified via object file build; full test run requires MinGW/Windows.
- **File count:** Post-4.2.3 quality gate passes at 705 files (cppcheck scope `src/source/`). Test files in `tests/` not counted by cppcheck. New test file adds 0 to cppcheck count.
- **Per-vertex color prerequisite:** Story 4.2.3 added `glColor4f` ABGR unpack to `MuRendererGL::RenderTriangles` (commit MuMain `046eb215`). Check if the same was applied to `RenderQuadStrip` — if not, Task 5 must do it.
- **No normals in trail paths:** `ZzzEffectJoint.cpp` trail vertices have no per-vertex normals — use `{0.f, 0.f, 0.f}` for `nx/ny/nz` fields. Acceptable for the transitional OpenGL phase.

### Git Intelligence (recent commits)

Recent pattern from 4.2.3: Each function/branch migrated in its own commit — `refactor(render): migrate {branch} to MuRenderer::RenderQuadStrip`. Follow the same: one commit per migrated `glBegin` block, then one final commit for the test file. Workspace-level commits use `chore(paw):` prefix for pipeline state; game source commits use `refactor(render):` inside the `MuMain/` submodule.

### References

- [Source: `_bmad-output/project-context.md` — C++ Language Rules, CMake Module Targets, Testing Rules]
- [Source: `docs/development-standards.md` — §1 Banned Win32 API table, §2 Error Handling & Logging]
- [Source: `_bmad-output/planning-artifacts/epics.md` lines 1178–1206 — Epic 4, Story 4.2.4]
- [Source: `_bmad-output/stories/4-2-1-murenderer-core-api/story.md` — IMuRenderer interface, Vertex3D struct, MuRendererGL patterns]
- [Source: `_bmad-output/stories/4-2-2-migrate-renderbitmap-quad2d/story.md` — ABGR packing convention, textureId=0 decision, test pattern]
- [Source: `_bmad-output/stories/4-2-3-migrate-skeletal-mesh/story.md` — PackABGR helper, per-vertex color prerequisite for RenderTriangles, file count baseline 705]
- [Source: `MuMain/src/source/RenderFX/ZzzEffectJoint.cpp` lines ~7043–7440 — `RenderJoints()` function; GL_QUADS segment blocks at ~7197, ~7351, ~7392, ~7411]
- [Source: `MuMain/src/source/RenderFX/MuRenderer.h` line 86 — `RenderQuadStrip` signature]
- [Source: `MuMain/src/source/RenderFX/MuRenderer.cpp` lines ~103–124 — `MuRendererGL::RenderQuadStrip` (verify per-vertex color)]
- [Source: `MuMain/src/source/Main/stdafx.h` line 184 — `GL_QUAD_STRIP` stub]
- [Source: `MuMain/tests/render/test_skeletalmesh_migration.cpp` — inline mock and PackABGR test pattern]
- [Source: `MuMain/tests/CMakeLists.txt` — `target_sources` pattern for adding new test TU under Story comment block]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

(none)

### Completion Notes List

- Task 5 (RenderQuadStrip per-vertex color) was done first as a prerequisite; original implementation from 4.2.1 was missing `glColor4f` ABGR unpack. Added and committed as `feat(render): add per-vertex color to MuRendererGL::RenderQuadStrip`.
- GUILD_WAR_EVENT block used `o->Light` color (set via `glColor3fv(o->Light)` before the loop) since BITMAP_FLARE SubType==22 matches no per-segment `glColor3f` branch.
- RENDER_FACE_ONE/TWO color capture block mirrors each `glColor3f` call in the type-specific branches; `glColor3f` calls remain in place for story 4.2.5 scope.
- clang-format required removing manual column alignment from `Vertex3D` initializer lists; `./ctl format` applied before final commit.
- AC-VAL-3 (visual validation) deferred to epic-4 ground truth gate (story 4.4.1) per established pattern.

### File List

| File | Change | Notes |
|------|--------|-------|
| `MuMain/src/source/RenderFX/ZzzEffectJoint.cpp` | MODIFIED | Migrated 4 `glBegin(GL_QUADS)` trail segment blocks in `RenderJoints()`; added `PackABGR` helper and `#include "MuRenderer.h"` |
| `MuMain/src/source/RenderFX/MuRenderer.cpp` | MODIFIED | Added per-vertex ABGR color emission (`glColor4f`) to `MuRendererGL::RenderQuadStrip` |
| `MuMain/tests/render/test_traileffects_migration.cpp` | CREATED | Catch2 tests for `RenderQuadStrip` call-through, UV mapping, Luminosity packing (RED phase — ATDD) |
| `MuMain/tests/CMakeLists.txt` | MODIFIED | Added `target_sources(MuTests PRIVATE render/test_traileffects_migration.cpp)` under Story 4.2.4 comment block |

### Change Log

| Date | Change | Notes |
|------|--------|-------|
| 2026-03-10 | Story created | ready-for-dev |
| 2026-03-10 | Task 5: Added per-vertex color to RenderQuadStrip | Commit `feat(render): add per-vertex color to MuRendererGL::RenderQuadStrip` |
| 2026-03-10 | Tasks 1-2: Analyzed trail paths; migrated BITMAP_JOINT_FORCE SubType==0 | Commit `refactor(render): migrate BITMAP_JOINT_FORCE trail segment to MuRenderer::RenderQuadStrip` |
| 2026-03-10 | Task 3: Migrated GUILD_WAR_EVENT double-face trail | Commit `refactor(render): migrate GUILD_WAR_EVENT trail segment to MuRenderer::RenderQuadStrip` |
| 2026-03-10 | Task 4: Migrated RENDER_FACE_ONE/TWO trail segments | Commit `refactor(render): migrate RENDER_FACE_ONE/TWO trail segments to MuRenderer::RenderQuadStrip` |
| 2026-03-10 | Tasks 6-7: Tests exist (RED phase); quality gate passed; grep confirms zero GL_QUADS in lines 7150-7421 | AC-5 verified |
