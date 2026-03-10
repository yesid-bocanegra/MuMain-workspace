# Story 4.2.3: Migrate Skeletal Mesh Rendering to RenderTriangles

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 4 - Rendering Pipeline Migration |
| Feature | 4.2 - MuRenderer Abstraction |
| Story ID | 4.2.3 |
| Story Points | 5 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-RENDER-MIGRATE-TRIANGLES |
| FRs Covered | FR12, FR13, FR14, FR15 |
| Prerequisites | Story 4.2.1 (MuRenderer Core API — done); Story 4.2.2 (RenderBitmap migration — done, sibling context) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Migrate `glDrawArrays(GL_TRIANGLES, ...)` and `glBegin(GL_TRIANGLES)` paths in `ZzzBMD.cpp` to `mu::GetRenderer().RenderTriangles()`; add Catch2 tests in `tests/render/` |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** the skeletal mesh rendering paths in `ZzzBMD.cpp` migrated to `mu::GetRenderer().RenderTriangles()`,
**so that** character models, monsters, and NPCs render through the MuRenderer abstraction instead of directly calling OpenGL vertex arrays and immediate mode.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** The `glVertexPointer` / `glColorPointer` / `glTexCoordPointer` / `glDrawArrays(GL_TRIANGLES, ...)` sequence in `BMD::RenderMesh()` is replaced with a `mu::Vertex3D` vector populated from `RenderArrayVertices`, `RenderArrayColors`, and `RenderArrayTexCoords`, followed by `mu::GetRenderer().RenderTriangles(vertices, textureId)` — the `glEnableClientState` / `glDisableClientState` calls are also removed from these paths
- [ ] **AC-2:** The same migration is applied to `BMD::EndRenderCoinHeap()` — the vertex-array + `glDrawArrays` path is replaced with `RenderTriangles()`
- [ ] **AC-3:** The `glBegin(GL_TRIANGLES)` / `glVertex3fv` / `glEnd` immediate-mode path in `BMD::RenderMeshAlternative()` (lines ~1682–1743) is migrated to build a `std::vector<mu::Vertex3D>` and call `RenderTriangles()`, preserving all existing per-vertex color, UV, and wave deformation logic
- [ ] **AC-4:** The same `glBegin(GL_TRIANGLES)` / `glEnd` immediate-mode path in `BMD::RenderMeshTranslate()` (lines ~2185–2234) is migrated equivalently
- [ ] **AC-5:** Shadow-only paths (`BMD::AddMeshShadowTriangles`, `BMD::AddClothesShadowTriangles`) that use `glVertexPointer` + `glDrawArrays` for position-only geometry are migrated to `RenderTriangles()` with dummy UV/normal/color fields (or a position-only Vertex3D with zeros) — these paths do NOT bind a texture, so `textureId = 0` is passed
- [ ] **AC-6:** No `glBegin(GL_TRIANGLES)` / `glEnd`, `glDrawArrays(GL_TRIANGLES, ...)`, `glVertexPointer`, `glColorPointer`, `glTexCoordPointer`, `glEnableClientState(GL_VERTEX_ARRAY)`, or `glDisableClientState(GL_VERTEX_ARRAY)` calls remain in any of the migrated functions in `ZzzBMD.cpp` — verified by grep
- [ ] **AC-7:** All pre-existing call sites of `RenderMesh`, `RenderMeshAlternative`, `RenderBody`, `RenderBodyAlternative`, `RenderMeshTranslate`, `RenderBodyTranslate`, `RenderBodyShadow`, `EndRenderCoinHeap`, and `AddMeshShadowTriangles` continue to compile and link unchanged — no public API signatures in `ZzzBMD.h` are modified

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance — `mu::` namespace for all new helpers, PascalCase functions, `m_` member prefix with Hungarian hints, `#pragma once`, no raw `new`/`delete` (use `std::vector`), `[[nodiscard]]` on new fallible functions, no `NULL` (use `nullptr`), no `wprintf`, no `#ifdef _WIN32` in `ZzzBMD.cpp`
- [ ] **AC-STD-2:** Catch2 tests in `tests/render/test_skeletalmesh_migration.cpp` verifying: (a) `Vertex3D` struct packing is correct (position, normal, UV, color fields at expected offsets); (b) `RenderTriangles` is called once per mesh render via an inline mock `IMuRenderer`; (c) vertex count passed to `RenderTriangles` equals `NumTriangles * 3` — tests must compile and pass on macOS/Linux (no `gl*` calls in tests)
- [ ] **AC-STD-3:** No `glBegin(GL_TRIANGLES)`, `glEnd`, `glDrawArrays(GL_TRIANGLES, ...)`, `glVertexPointer`, `glColorPointer`, `glTexCoordPointer`, `glEnableClientState(GL_VERTEX_ARRAY)`, or `glDisableClientState(GL_VERTEX_ARRAY)` remain in any of the 5 migrated functions in `ZzzBMD.cpp`
- [ ] **AC-STD-5:** Error logging via `g_ErrorReport.Write(L"RENDER: ...")` on failure paths (e.g., empty vertex buffer guard in `RenderTriangles` already exists in `MuRenderer.cpp`)
- [ ] **AC-STD-6:** Conventional commits per migrated function: `refactor(render): migrate {function} to MuRenderer::RenderTriangles`
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format check + cppcheck 0 errors); file count increases from 705 by +1 test file = 706 files
- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [ ] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/render/` directory pattern)

---

## Validation Artifacts

- [ ] **AC-VAL-1:** Catch2 tests pass for `Vertex3D` packing, call-through count, and vertex count correctness
- [ ] **AC-VAL-2:** `./ctl check` passes with 0 errors after all migrations applied
- [ ] **AC-VAL-3:** Windows build (MSVC or MinGW) renders characters and monsters identically before/after migration — verified manually or via ground truth comparison from story 4.1.1 baselines (SSIM > 0.99 on character model scenes)
- [ ] **AC-VAL-4:** Grep verification — no migrated GL calls remain: `grep -n "glDrawArrays\|glVertexPointer\|glColorPointer\|glTexCoordPointer\|glEnableClientState\|glDisableClientState\|glBegin.*GL_TRIANGLES" MuMain/src/source/RenderFX/ZzzBMD.cpp` — zero hits inside migrated functions

---

## Tasks / Subtasks

- [ ] Task 1: Understand the two rendering paths and define Vertex3D population strategy (AC: 1, 2, 3, 4, 5)
  - [ ] Subtask 1.1: Read `ZzzBMD.cpp` functions `RenderMesh` (lines ~980–1407), `RenderMeshAlternative` (lines ~1409–1744), `RenderMeshTranslate` (lines ~2003–2235), `EndRenderCoinHeap` (lines ~961–978), `AddMeshShadowTriangles` (lines ~2350–2393), `AddClothesShadowTriangles` (lines ~2291–2348) — catalog each function's vertex data source (array-based vs immediate-mode), color mode (RGB vs RGBA vs per-vertex), and UV source (TexCoords array, chrome map, wave offset)
  - [ ] Subtask 1.2: Verify that `MuRendererGL::RenderTriangles()` in `MuRenderer.cpp` already emits per-vertex color via `glColor4f` (added in story 4.2.1) — confirm it unpacks `Vertex3D::color` ABGR field; if not, update before migrating call sites
  - [ ] Subtask 1.3: Decide packing convention for `Vertex3D::color` from floating-point GL colors: `glColor3fv(rgb)` → pack as `0xFF000000 | (r8 << 16) | (g8 << 8) | b8` (ABGR, alpha=0xFF); `glColor4f(r,g,b,a)` → pack as `(a8 << 24) | (b8 << 16) | (g8 << 8) | r8` matching the ABGR layout in `MuRenderer.h` — document in Dev Agent Record

- [ ] Task 2: Migrate `BMD::RenderMesh()` array-based path (AC: 1, 6, 7)
  - [ ] Subtask 2.1: After the existing vertex-transform loop that fills `RenderArrayVertices`, `RenderArrayColors`, `RenderArrayTexCoords`, add: build `std::vector<mu::Vertex3D> vertices`; iterate `m->NumTriangles * 3` positions; pack position from `RenderArrayVertices[i]`, normal from `NormalTransform` (or zero if `enableColor` is false), UV from `RenderArrayTexCoords[i]`, color from `RenderArrayColors[i]` (float RGBA → pack ABGR)
  - [ ] Subtask 2.2: Replace the `glVertexPointer` / `glColorPointer` / `glTexCoordPointer` / `glDrawArrays` / `glDisableClientState` block with `mu::GetRenderer().RenderTriangles(vertices, static_cast<std::uint32_t>(texture->Texture))` (use the texture already bound by `BindTexture()` earlier — or pass the texture index); also remove `glEnableClientState` calls at the top of the function
  - [ ] Subtask 2.3: Commit: `refactor(render): migrate RenderMesh to MuRenderer::RenderTriangles`

- [ ] Task 3: Migrate `BMD::EndRenderCoinHeap()` array-based path (AC: 2, 6, 7)
  - [ ] Subtask 3.1: After the coin heap loop fills `RenderArrayVertices`, `RenderArrayColors`, `RenderArrayTexCoords`, build `std::vector<mu::Vertex3D>` with `m->NumTriangles * 3 * coinCount` entries by packing from the three render arrays; call `mu::GetRenderer().RenderTriangles(vertices, 0)` (coin heap uses its own texture already bound by the calling code via `BindTexture`)
  - [ ] Subtask 3.2: Remove `glVertexPointer`, `glColorPointer`, `glTexCoordPointer`, `glDrawArrays`, `glDisableClientState` calls
  - [ ] Subtask 3.3: Commit: `refactor(render): migrate EndRenderCoinHeap to MuRenderer::RenderTriangles`

- [ ] Task 4: Migrate `BMD::RenderMeshAlternative()` immediate-mode path (AC: 3, 6, 7)
  - [ ] Subtask 4.1: Allocate `std::vector<mu::Vertex3D> vertices`; `vertices.reserve(m->NumTriangles * 3)` to avoid reallocations; replace `glBegin(GL_TRIANGLES)` with the vector push loop
  - [ ] Subtask 4.2: For each triangle vertex `(j, k)`:
    - `vi = tp->VertexIndex[k]`, `ni = tp->NormalIndex[k]`
    - Position: `VertexTransform[i][vi]` — or the `vPos` wave-deformed position if `iRndExtFlag & RNDEXT_WAVE`
    - Normal: `NormalTransform[i][ni]`
    - UV: `texp->TexCoordU / TexCoordV` ± wave offset; or `g_chrome[ni]` for `RENDER_CHROME`
    - Color: from `glColor3fv(LightTransform[i][ni])` or `glColor4f(Light[0],Light[1],Light[2],Alpha)` or `glColor3fv(BodyLight)` / `glColor4f(BodyLight[0..2], Alpha)` — pack to ABGR
    - `vertices.push_back({x, y, z, nx, ny, nz, u, v, color})`
  - [ ] Subtask 4.3: After loop: `mu::GetRenderer().RenderTriangles(vertices, static_cast<std::uint32_t>(Texture))`; remove `glBegin` / `glEnd`
  - [ ] Subtask 4.4: Commit: `refactor(render): migrate RenderMeshAlternative to MuRenderer::RenderTriangles`

- [ ] Task 5: Migrate `BMD::RenderMeshTranslate()` immediate-mode path (AC: 4, 6, 7)
  - [ ] Subtask 5.1: Same approach as Task 4 — allocate vector, push `Vertex3D` per triangle vertex, replace `glBegin(GL_TRIANGLES)` / `glEnd` with `RenderTriangles()` call; position uses `VectorAdd(VertexTransform[i][vi], BodyOrigin, pos)` (already in the original code); preserve UV/color logic
  - [ ] Subtask 5.2: Commit: `refactor(render): migrate RenderMeshTranslate to MuRenderer::RenderTriangles`

- [ ] Task 6: Migrate shadow paths (AC: 5, 6, 7)
  - [ ] Subtask 6.1: `AddMeshShadowTriangles` and `AddClothesShadowTriangles` use position-only vertex arrays (no UV, no color). Build `std::vector<mu::Vertex3D>` with `{x, y, z, 0.f, 0.f, 0.f, 0.f, 0.f, 0xFFFFFFFFu}` per vertex; call `mu::GetRenderer().RenderTriangles(vertices, 0)` — texture ID 0 = no texture (shadow is rendered with `DisableTexture()` by the caller)
  - [ ] Subtask 6.2: Remove `glEnableClientState(GL_VERTEX_ARRAY)`, `glVertexPointer`, `glDrawArrays`, `glDisableClientState(GL_TEXTURE_COORD_ARRAY)` calls from both shadow functions
  - [ ] Subtask 6.3: Commit: `refactor(render): migrate shadow mesh paths to MuRenderer::RenderTriangles`

- [ ] Task 7: Update `MuRendererGL::RenderTriangles` for per-vertex color (prerequisite check) (AC: AC-STD-2)
  - [ ] Subtask 7.1: Read current `MuRenderer.cpp` `RenderTriangles` implementation — confirm it calls `glColor4f` / `glColor4ubv` per vertex using `Vertex3D::color`. If missing (the 4.2.1 implementation only emits `glTexCoord2f + glNormal3f + glVertex3f`), add the ABGR unpack + `glColor4f` emission before `glVertex3f` — matching the pattern added in `RenderQuad2D` in story 4.2.2
  - [ ] Subtask 7.2: If updated, commit: `feat(render): add per-vertex color to MuRendererGL::RenderTriangles`

- [ ] Task 8: Add Catch2 migration tests (AC: AC-STD-2, AC-VAL-1)
  - [ ] Subtask 8.1: Create `MuMain/tests/render/test_skeletalmesh_migration.cpp`
  - [ ] Subtask 8.2: Add `target_sources(MuTests PRIVATE render/test_skeletalmesh_migration.cpp)` in `MuMain/tests/CMakeLists.txt` under `BUILD_TESTING` guard
  - [ ] Subtask 8.3: `TEST_CASE("Vertex3D struct layout")`: construct a `mu::Vertex3D{1.f,2.f,3.f, 0.f,1.f,0.f, 0.5f,0.5f, 0xFFFFFFFFu}`, assert `v.x==1.f`, `v.ny==1.f`, `v.u==0.5f`, `v.color==0xFFFFFFFFu` — documents the field order contract
  - [ ] Subtask 8.4: `TEST_CASE("RenderTriangles call-through — single mesh")`: create an inline `MockRenderer : public mu::IMuRenderer` that captures `std::span<const mu::Vertex3D>` and `std::uint32_t textureId` from `RenderTriangles()`; simulate building a 2-triangle (6-vertex) `Vertex3D` array; call `mock.RenderTriangles(verts, 42u)`; assert `capturedCount == 6` and `capturedTextureId == 42u`
  - [ ] Subtask 8.5: `TEST_CASE("ABGR color packing — opaque white")`: verify `0xFFFFFFFFu` unpacks to r=255, g=255, b=255, a=255 using the same bit-shift logic as `MuRendererGL`

- [ ] Task 9: Quality gate + grep verification (AC: AC-STD-13, AC-VAL-2, AC-VAL-4)
  - [ ] Subtask 9.1: Run `./ctl check` — 0 errors
  - [ ] Subtask 9.2: Run `grep -n "glDrawArrays.*GL_TRIANGLES\|glVertexPointer\|glColorPointer\|glTexCoordPointer\|glEnableClientState\|glDisableClientState\|glBegin.*GL_TRIANGLES\|glEnd" MuMain/src/source/RenderFX/ZzzBMD.cpp` — confirm no hits in any of the 5 migrated functions (shadow bounding box debug visualizer in `RenderObjectBoundingBox` and bone rendering in `RenderBone` are out of scope for this story)

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A — C++ client, no HTTP error codes | — | — | — |

Logging pattern (already in `MuRenderer.cpp` from story 4.2.1):
- `g_ErrorReport.Write(L"RENDER: MuRenderer::RenderTriangles -- vertex buffer empty")` — triggered if migrated code passes an empty vertex vector

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
| Unit | Catch2 3.7.1 | Vertex3D struct layout, call-through correctness, color packing | Field order contract; 6-vertex call count; ABGR decode |
| Integration (manual) | Windows build | No regression on character/monster rendering | Characters (DK, DW, FE, MG, DL), monsters, NPCs render identically before/after |
| Ground truth (optional) | SSIM tool (story 4.1.1) | SSIM > 0.99 on character model scenes | Windows OpenGL baseline vs post-migration |

---

## Dev Notes

### Context: Why This Story Exists

`ZzzBMD.cpp` is the **skeletal mesh rendering engine** for MU Online — every character class (DK, DW, FE, MG, DL), monster, NPC, and coin heap model goes through its `RenderMesh` / `RenderMeshAlternative` / `RenderBody` / `RenderBodyAlternative` pipeline. This file has two distinct rendering paths that both need migration:

1. **Array-based path** (`RenderMesh`, `EndRenderCoinHeap`, shadow paths): Pre-builds vertex data into `RenderArrayVertices` / `RenderArrayColors` / `RenderArrayTexCoords` global arrays, then calls `glVertexPointer` + `glDrawArrays`. This is already a batch approach — migration is straightforward: pack the arrays into a `std::vector<mu::Vertex3D>` and call `RenderTriangles()`.

2. **Immediate-mode path** (`RenderMeshAlternative`, `RenderMeshTranslate`): Uses `glBegin(GL_TRIANGLES)` with per-vertex `glColor*` / `glTexCoord2f` / `glVertex3fv` inside a loop. Migration requires collecting each vertex into a `mu::Vertex3D` and building a vector before issuing a single `RenderTriangles()` call.

**Scope boundary (strict):** This story does NOT migrate:
- `RenderObjectBoundingBox()` (debug visualizer, GL_QUADS and GL_LINES) — out of scope
- `RenderBone()` (debug bone visualization, GL_LINES) — out of scope
- `glColor3fv` / `glColor4f` calls that set the per-mesh color BEFORE entering `RenderMesh` (these are callers setting OpenGL state, not inside the triangle draw calls themselves) — story 4.2.5 handles all remaining `glColor` + `glEnable`/`glDisable` state calls
- `DisableTexture()` / `EnableAlphaBlend()` / `BindTexture()` calls inside `RenderMesh` — story 4.2.5 scope

### Key Design Decisions

#### Vertex3D Color Packing (ABGR — same as Vertex2D)

`mu::Vertex3D::color` is packed ABGR matching `mu::Vertex2D::color` (established in stories 4.2.1 and 4.2.2):

| GL source | ABGR packed value |
|---|---|
| `glColor3fv(rgb)` | `0xFF000000u \| (uint8_t(b*255)<<16) \| (uint8_t(g*255)<<8) \| uint8_t(r*255)` |
| `glColor4f(r,g,b,a)` | `(uint8_t(a*255)<<24) \| (uint8_t(b*255)<<16) \| (uint8_t(g*255)<<8) \| uint8_t(r*255)` |
| `glColor3fv(BodyLight)` | same as `glColor3fv(rgb)` — alpha = 0xFF |
| Opaque white | `0xFFFFFFFFu` |

#### MuRendererGL::RenderTriangles — Per-Vertex Color (Prerequisite)

The `MuRendererGL::RenderTriangles` implementation in `MuRenderer.cpp` (story 4.2.1) currently emits `glTexCoord2f + glNormal3f + glVertex3f` only — it does **NOT** emit `glColor*`. Task 7 MUST check this and add per-vertex ABGR unpack + `glColor4f` emission before `glVertex3f`, matching the pattern added to `RenderQuad2D` in story 4.2.2. This is required for `RenderMeshAlternative` migration where per-vertex `LightTransform` colors are critical for correct lighting.

#### Array-Based Path: Vertex Packing from Float RGBA Arrays

`RenderArrayColors` is `vec4_t[]` (float RGBA). Packing to ABGR:
```cpp
const vec4_t& c = RenderArrayColors[i];
const std::uint32_t color =
    (static_cast<std::uint32_t>(c[3] * 255.f) << 24) | // A
    (static_cast<std::uint32_t>(c[2] * 255.f) << 16) | // B
    (static_cast<std::uint32_t>(c[1] * 255.f) << 8)  | // G
    (static_cast<std::uint32_t>(c[0] * 255.f));         // R
```

#### Shadow Paths: Position-Only Vertices

`AddMeshShadowTriangles` and `AddClothesShadowTriangles` build position-only vertex arrays (no normals, no UVs, no colors). Shadows are rendered with:
- `DisableTexture()` called by `RenderBodyShadow` (caller) before invoking shadow helpers
- `glColor4f(0.0f, 0.0f, 0.0f, 0.5f)` set once before the shadow render (also in caller)

For migration, construct `mu::Vertex3D` with `{x, y, z, 0.f, 0.f, 0.f, 0.f, 0.f, 0xFF000000u}` (black, 50% alpha will need to be set via the blend state system — but that is story 4.2.5 scope). For now, pass `0xFF000000u` (black opaque) as color — the actual shadow transparency comes from `glColor4f` set by the caller before invoking these helpers (story 4.2.5 will eventually migrate that too). Pass `textureId = 0` (no texture).

#### Texture ID for Array-Based Paths

`RenderMesh` already calls `BindTexture(textureIndex)` before building vertex arrays. The `textureIndex` is available as a local variable. Pass it as `static_cast<std::uint32_t>(textureIndex)` to `RenderTriangles()`. Note: `MuRendererGL::RenderTriangles` currently calls `glBindTexture` — this will double-bind (caller also called `BindTexture()`). This is harmless and acceptable for the transitional OpenGL phase. Story 4.3.1 (SDL_gpu backend) will use the `textureId` parameter exclusively.

#### Wave Deformation in Immediate-Mode Path

`RenderMeshAlternative` has a `RNDEXT_WAVE` flag that applies sine-wave deformation per vertex:
```cpp
float vPos[3];
float fParam = (float)((int)WorldTime + vi * 931) * 0.007f;
float fSin = sinf(fParam);
int ni = tp->NormalIndex[k];
float* Normal = NormalTransform[i][ni];
for (int iCoord = 0; iCoord < 3; ++iCoord)
{
    vPos[iCoord] = VertexTransform[i][vi][iCoord] + Normal[iCoord] * fSin * 28.0f;
}
// glVertex3fv(vPos);
```
When building `mu::Vertex3D`, use `vPos[0..2]` for position when wave is active, `VertexTransform[i][vi][0..2]` otherwise — same branching logic, just stored into the struct instead of emitted immediately.

### Project Structure Notes

**Files to Modify:**

| File | Action | Notes |
|------|--------|-------|
| `MuMain/src/source/RenderFX/ZzzBMD.cpp` | MODIFY | Migrate 5 functions: `RenderMesh`, `EndRenderCoinHeap`, `RenderMeshAlternative`, `RenderMeshTranslate`, `AddMeshShadowTriangles`, `AddClothesShadowTriangles`; add `#include "MuRenderer.h"` if not already present |
| `MuMain/src/source/RenderFX/MuRenderer.cpp` | MODIFY (if needed) | Task 7: Add per-vertex color emission (`glColor4f`) to `MuRendererGL::RenderTriangles` if missing |

**Files to Create:**

| File | CMake Target |
|------|-------------|
| `MuMain/tests/render/test_skeletalmesh_migration.cpp` | `MuTests` (explicit add in `tests/CMakeLists.txt`) |

**DO NOT MODIFY:** `ZzzBMD.h` — all function signatures stay exactly the same. Call sites throughout the game (character rendering, world rendering, effect systems) are untouched.

**CMake:** `MURenderFX` auto-globs `RenderFX/*.cpp` — no CMakeLists change needed for source changes. Only `tests/CMakeLists.txt` needs the new test file entry.

**Relevant existing code:**
- `MuMain/src/source/RenderFX/ZzzBMD.cpp` — Primary migration target; functions at lines ~961, ~980, ~1409, ~2003, ~2291, ~2350
- `MuMain/src/source/RenderFX/MuRenderer.h` — `IMuRenderer` interface, `Vertex3D` struct (position, normal, UV, color ABGR)
- `MuMain/src/source/RenderFX/MuRenderer.cpp` — `MuRendererGL::RenderTriangles` (verify/add per-vertex color)
- `MuMain/src/source/Main/stdafx.h` — OpenGL stubs for non-Windows compile (`glNormal3f`, `glVertex3fv`, `glDrawArrays`, `glVertexPointer`, `glColorPointer`, `glTexCoordPointer`, `glEnableClientState`, `glDisableClientState` stubs must exist)
- `MuMain/tests/render/test_murenderer.cpp` — Reference for mock `IMuRenderer` inline test-double pattern
- `MuMain/tests/render/test_renderbitmap_migration.cpp` — Reference for vertex layout and call-count test pattern (story 4.2.2)

### Technical Implementation

#### Vertex3D ABGR Color Helper (inline in ZzzBMD.cpp)

```cpp
// Place near top of file or as a file-static inline function:
static inline std::uint32_t PackABGR(float r, float g, float b, float a)
{
    return (static_cast<std::uint32_t>(a * 255.f) << 24) |
           (static_cast<std::uint32_t>(b * 255.f) << 16) |
           (static_cast<std::uint32_t>(g * 255.f) << 8)  |
           (static_cast<std::uint32_t>(r * 255.f));
}
```

#### Array-Based Path Example (RenderMesh)

```cpp
// BEFORE:
glVertexPointer(3, GL_FLOAT, 0, vertices);
if (enableColor)
    glColorPointer(4, GL_FLOAT, 0, colors);
glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
glDrawArrays(GL_TRIANGLES, 0, m->NumTriangles * 3);
glDisableClientState(GL_TEXTURE_COORD_ARRAY);
if (enableColor)
    glDisableClientState(GL_COLOR_ARRAY);
glDisableClientState(GL_VERTEX_ARRAY);

// AFTER:
{
    const int numVerts = m->NumTriangles * 3;
    std::vector<mu::Vertex3D> muVerts;
    muVerts.reserve(numVerts);
    for (int i = 0; i < numVerts; ++i)
    {
        const vec4_t& c = colors[i];
        const std::uint32_t color = enableColor
            ? PackABGR(c[0], c[1], c[2], c[3])
            : 0xFFFFFFFFu;
        muVerts.push_back({
            vertices[i][0], vertices[i][1], vertices[i][2],
            0.f, 0.f, 0.f,           // normals not available in array path
            texCoords[i][0], texCoords[i][1],
            color
        });
    }
    mu::GetRenderer().RenderTriangles(muVerts, static_cast<std::uint32_t>(textureIndex));
}
```

> **Note:** The array path does not store normals in `RenderArrayNormals` — the normal data is used to derive colors during the transform phase but not stored back. Use `{0.f, 0.f, 0.f}` for normals in this path. SDL_gpu backend (4.3.1) will address lighting once normals are available.

#### Immediate-Mode Path Example (RenderMeshAlternative — RENDER_TEXTURE case)

```cpp
// BEFORE:
glBegin(GL_TRIANGLES);
for (int j = 0; j < m->NumTriangles; j++)
{
    Triangle_t* tp = &m->Triangles[j];
    for (int k = 0; k < tp->Polygon; k++)
    {
        int vi = tp->VertexIndex[k];
        // ... color/UV logic ...
        glVertex3fv(VertexTransform[i][vi]);  // or vPos for wave
    }
}
glEnd();

// AFTER:
{
    std::vector<mu::Vertex3D> muVerts;
    muVerts.reserve(m->NumTriangles * 3);
    for (int j = 0; j < m->NumTriangles; j++)
    {
        Triangle_t* tp = &m->Triangles[j];
        for (int k = 0; k < tp->Polygon; k++)
        {
            int vi = tp->VertexIndex[k];
            int ni = tp->NormalIndex[k];

            // UV
            float u = 0.f, v = 0.f;
            if (Render == RENDER_TEXTURE)
            {
                TexCoord_t* texp = &m->TexCoords[tp->TexCoordIndex[k]];
                u = EnableWave ? texp->TexCoordU + BlendMeshTexCoordU : texp->TexCoordU;
                v = EnableWave ? texp->TexCoordV + BlendMeshTexCoordV : texp->TexCoordV;
            }
            else if (Render == RENDER_CHROME)
            {
                u = g_chrome[ni][0];
                v = g_chrome[ni][1];
            }

            // Color
            std::uint32_t color = 0xFFFFFFFFu;
            if (Render == RENDER_TEXTURE && EnableLight)
            {
                float* Light = LightTransform[i][ni];
                color = (Alpha >= 0.99f)
                    ? PackABGR(Light[0], Light[1], Light[2], 1.f)
                    : PackABGR(Light[0], Light[1], Light[2], Alpha);
            }
            else if (Render == RENDER_CHROME)
            {
                color = (Alpha >= 0.99f)
                    ? PackABGR(BodyLight[0], BodyLight[1], BodyLight[2], 1.f)
                    : PackABGR(BodyLight[0], BodyLight[1], BodyLight[2], Alpha);
            }

            // Position (wave deformation)
            float px, py, pz;
            if (iRndExtFlag & RNDEXT_WAVE)
            {
                float fParam = static_cast<float>((static_cast<int>(WorldTime) + vi * 931)) * 0.007f;
                float fSin = sinf(fParam);
                float* Normal = NormalTransform[i][ni];
                px = VertexTransform[i][vi][0] + Normal[0] * fSin * 28.0f;
                py = VertexTransform[i][vi][1] + Normal[1] * fSin * 28.0f;
                pz = VertexTransform[i][vi][2] + Normal[2] * fSin * 28.0f;
            }
            else
            {
                px = VertexTransform[i][vi][0];
                py = VertexTransform[i][vi][1];
                pz = VertexTransform[i][vi][2];
            }

            // Normal
            float* n = NormalTransform[i][ni];
            muVerts.push_back({px, py, pz, n[0], n[1], n[2], u, v, color});
        }
    }
    mu::GetRenderer().RenderTriangles(muVerts, static_cast<std::uint32_t>(Texture));
}
```

#### MuRendererGL::RenderTriangles Update (per-vertex color — if not already present)

```cpp
void RenderTriangles(std::span<const Vertex3D> vertices, std::uint32_t textureId) override
{
    if (vertices.empty())
    {
        g_ErrorReport.Write(L"RENDER: MuRenderer::RenderTriangles -- vertex buffer empty");
        return;
    }

    glBindTexture(GL_TEXTURE_2D, static_cast<GLuint>(textureId));
    glBegin(GL_TRIANGLES);
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

The following stubs must exist in `stdafx.h` for non-Windows compile. Story 4.2.1 added some; verify the following are present:
- `glDrawArrays` — verify; likely present (added for ZzzBMD reference)
- `glVertexPointer` — verify; add if missing
- `glColorPointer` — verify; add if missing
- `glTexCoordPointer` — verify; add if missing
- `glEnableClientState(GL_VERTEX_ARRAY)` / `glDisableClientState(GL_VERTEX_ARRAY)` — verify; add if missing
- `GL_VERTEX_ARRAY`, `GL_COLOR_ARRAY`, `GL_TEXTURE_COORD_ARRAY` constants — verify; add if missing

After migration, these stubs become dead code in `ZzzBMD.cpp` (migrated paths no longer call them) — leave stubs in `stdafx.h` for remaining call sites elsewhere.

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, Catch2 3.7.1, OpenGL (via stubs on non-Windows), `MURenderFX` CMake target, `MUGame` CMake target (ZzzBMD.cpp is in MUGame)

**Prohibited (per project-context.md):**
- `new`/`delete` — use `std::vector` (stack allocation, RAII)
- `NULL` — use `nullptr`
- `wprintf`, `__TraceF()`, `DebugAngel` — use `g_ErrorReport.Write()`
- `#ifndef` header guards — `#pragma once`
- `#ifdef _WIN32` in `ZzzBMD.cpp` or `MuRenderer.cpp` — OpenGL stubs handle non-Windows compile
- OpenGL types in `MuRenderer.h` — `GLenum`, `GLuint` stay out of the interface header

**Required patterns (per project-context.md):**
- `std::span<const mu::Vertex3D>` for `RenderTriangles` parameter (C++20, already in interface)
- `std::vector<mu::Vertex3D>` for per-call vertex buffer (avoids static/global mutation)
- `[[nodiscard]]` on any new fallible functions added
- `mu::` namespace for all new helpers
- Allman brace style, 4-space indent, 120-column limit (`.clang-format`)
- `#pragma once` header guards
- Include order: preserve existing (`SortIncludes: Never`)

**Quality gate:** `./ctl check` — must pass 0 errors. File count increases from 705 (post-4.2.2) by +1 test file = 706 files.

**Testing:** Catch2 `TEST_CASE` / `SECTION` / `REQUIRE` / `CHECK`. No mocking framework — use an inline test-double struct for `IMuRenderer`. Pure logic only in test TU (no `gl*` calls).

### Previous Story Intelligence (from 4.2.2)

- **ABGR color packing** established in story 4.2.2 for `Vertex2D::color` — same convention applies to `Vertex3D::color`
- **AC-3 Decision (Option A):** `textureId=0` sentinel for untextured paths (shadow paths) — already the pattern
- **Catch2 header fix:** Include `<catch2/catch_approx.hpp>` when using `Catch::Approx()` — the test file generated in ATDD may be missing this
- **Pre-existing compilation blocker on macOS:** `muConsoleDebug.cpp: 'SetMaxMessagePerCycle'` blocks `MUCore` → `MuTests` on macOS. This is pre-existing and unrelated to this story. Tests verified via object file build; full test run requires MinGW/Windows.
- **File count:** Post-4.2.2 quality gate passes at 705 files — new test file brings it to 706

### Git Intelligence (recent commits)

Recent pattern from 4.2.2: Each function migrated in its own commit — `refactor(render): migrate {Function} to MuRenderer::RenderQuad2D`. Follow the same pattern here: one commit per migrated function, then one final commit for the test file addition.

### References

- [Source: `_bmad-output/project-context.md` — C++ Language Rules, CMake Module Targets, Testing Rules]
- [Source: `docs/development-standards.md` — §1 Banned Win32 API table, §2 Error Handling & Logging]
- [Source: `_bmad-output/planning-artifacts/epics.md` lines 1145–1176 — Epic 4, Story 4.2.3]
- [Source: `_bmad-output/stories/4-2-1-murenderer-core-api/story.md` — IMuRenderer interface, Vertex3D struct, MuRendererGL patterns, OpenGL stubs note]
- [Source: `_bmad-output/stories/4-2-2-migrate-renderbitmap-quad2d/story.md` — ABGR packing convention, textureId=0 decision, test pattern, file count baseline]
- [Source: `MuMain/src/source/RenderFX/ZzzBMD.cpp` lines ~961–978, ~980–1407, ~1409–1744, ~2003–2235, ~2291–2393 — functions to migrate]
- [Source: `MuMain/src/source/RenderFX/MuRenderer.h` — Vertex3D struct definition]
- [Source: `MuMain/src/source/RenderFX/MuRenderer.cpp` — MuRendererGL::RenderTriangles (verify per-vertex color)]
- [Source: `MuMain/src/source/Main/stdafx.h` — OpenGL inline stubs for non-Windows compile]
- [Source: `MuMain/tests/render/test_murenderer.cpp` — inline mock IMuRenderer test-double pattern]
- [Source: `MuMain/tests/render/test_renderbitmap_migration.cpp` — vertex layout and call-count test pattern]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
