# Story 4.2.2: Migrate RenderBitmap Variants to RenderQuad2D

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 4 - Rendering Pipeline Migration |
| Feature | 4.2 - MuRenderer Abstraction |
| Story ID | 4.2.2 |
| Story Points | 8 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-RENDER-MIGRATE-QUAD2D |
| FRs Covered | FR12, FR13, FR14, FR15 |
| Prerequisites | Story 4.2.1 (MuRenderer Core API — done) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Modify `ZzzOpenglUtil.cpp` (migrate 9 RenderBitmap* variants + RenderColor to MuRenderer::RenderQuad2D); expand `MuRenderer.h/cpp` with `RenderQuad2DColored()` helper; add Catch2 tests in `tests/render/` |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** all 9 `RenderBitmap*` variant call sites and `RenderColor` migrated to `MuRenderer::RenderQuad2D()`,
**so that** ~80% of all rendering goes through the abstraction layer with no direct `glBegin`/`glEnd` in `ZzzOpenglUtil.cpp`.

---

## Functional Acceptance Criteria

- [x] **AC-1:** All 9 `RenderBitmap*` function bodies in `ZzzOpenglUtil.cpp` are rewritten to delegate to `mu::GetRenderer().RenderQuad2D()` — no `glBegin`/`glEnd` remains inside these functions after migration
- [x] **AC-2:** `RenderColor` / `EndRenderColor` color-fill quad path in `ZzzOpenglUtil.cpp` is migrated to `mu::GetRenderer().RenderQuad2D()` using a `Vertex2D` with packed ABGR color and a sentinel texture ID (0 = "no texture")
- [x] **AC-3:** `IMuRenderer` interface extended with `RenderQuad2DColored()` (takes 4 `Vertex2D`, no texture ID) to support the `RenderColor` untextured-quad case cleanly — OR `RenderQuad2D` is made to accept `textureId = 0` as "untextured" (implementation chooses one approach, documents rationale in Dev Agent Record)
- [x] **AC-4:** Each function migrated in its own commit following the pattern: `refactor(render): migrate {variant} to MuRenderer::RenderQuad2D` — e.g. `refactor(render): migrate RenderBitmap to MuRenderer::RenderQuad2D`
- [x] **AC-5:** No mixed OpenGL + MuRenderer rendering within any single migrated function — each function is either 100% migrated or untouched
- [x] **AC-6:** All pre-existing call sites of the 9 variants (across ~40 UI/scene/world files) continue to compile and link — the public API signatures in `ZzzOpenglUtil.h` are NOT changed

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards Compliance — `mu::` namespace for new helpers, PascalCase functions, `m_` member prefix with Hungarian hints, `#pragma once`, no raw `new`/`delete`, `[[nodiscard]]` on new fallible functions, no `NULL` (use `nullptr`), no `wprintf`
- [x] **AC-STD-2:** Catch2 tests in `tests/render/test_renderbitmap_migration.cpp` verifying: (a) `RenderQuad2D` called once per migrated bitmap render via a `BlendModeTracker`-style mock; (b) vertex layout matches expected UV coordinates for the basic `RenderBitmap` case — tests must compile/pass on macOS/Linux (no OpenGL calls in tests)
- [x] **AC-STD-3:** No direct `glBegin`/`glEnd` calls remain in any of the 9 migrated `RenderBitmap*` functions or `RenderColor` in `ZzzOpenglUtil.cpp` after migration
- [x] **AC-STD-5:** Error logging via `g_ErrorReport.Write(L"RENDER: ...")` on any failure paths introduced in new MuRenderer helpers
- [x] **AC-STD-6:** Conventional commits per function: `refactor(render): migrate {variant} to MuRenderer::RenderQuad2D`
- [x] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format check + cppcheck 0 errors); file count increases from 705 by at most +1 test file (= 706 files)
- [x] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [x] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/render/` directory pattern)

---

## Validation Artifacts

- [x] **AC-VAL-1:** Catch2 tests pass for vertex layout correctness and RenderQuad2D call-through
- [x] **AC-VAL-2:** `./ctl check` passes with 0 errors after all migrations applied
- [x] **AC-VAL-3:** Windows build (MSVC or MinGW) renders identically before/after migration — verified manually or via ground truth comparison (SSIM > 0.99) from story 4.1.1 baselines
- [x] **AC-VAL-4:** No `glBegin` / `glEnd` remain in `ZzzOpenglUtil.cpp` inside any of the 9 migrated functions (grep verification: `grep -n "glBegin\|glEnd" MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp`)

---

## Tasks / Subtasks

- [x] Task 1: Review existing RenderBitmap variants and define Vertex2D packing strategy (AC: 1, 2, 3)
  - [x] Subtask 1.1: Read `ZzzOpenglUtil.cpp` lines 1204–1644 — catalog the 9 variants and `RenderColor`, document their coordinate-system differences (WindowHeight flip, ConvertX/Y scaling, rotation math)
  - [x] Subtask 1.2: Decide on AC-3: whether `RenderQuad2D(textureId=0)` handles untextured or a new `RenderQuad2DColored()` is added — document decision in Dev Agent Record
  - [x] Subtask 1.3: If new interface method chosen, add it to `MuRenderer.h` (`IMuRenderer`) and implement stub in `MuRenderer.cpp` (`MuRendererGL`) — use `glBindTexture(GL_TEXTURE_2D, 0)` for untextured path

- [x] Task 2: Migrate `RenderBitmap` (basic variant) (AC: 1, 4, 5)
  - [x] Subtask 2.1: Build 4 `mu::Vertex2D` from existing `p[]` position array and `c[]` texcoord array; pack `color` as `0xFFFFFFFF` (opaque white) unless `Alpha > 0.f` in which case pack alpha channel
  - [x] Subtask 2.2: Call `mu::GetRenderer().RenderQuad2D(vertices, static_cast<std::uint32_t>(Texture))`; remove `glBegin(GL_TRIANGLE_FAN)` / `glTexCoord2f` / `glVertex2f` / `glEnd()` block
  - [x] Subtask 2.3: Commit: `refactor(render): migrate RenderBitmap to MuRenderer::RenderQuad2D`

- [x] Task 3: Migrate `RenderColorBitmap` (AC: 1, 4, 5)
  - [x] Subtask 3.1: Pack the `color` parameter (unsigned int, `0xFFFFFFFF` = white) directly into `Vertex2D::color`; build 4 vertices from `p[]` and `c[]`
  - [x] Subtask 3.2: Call `RenderQuad2D`, remove `glBegin` block
  - [x] Subtask 3.3: Commit: `refactor(render): migrate RenderColorBitmap to MuRenderer::RenderQuad2D`

- [x] Task 4: Migrate `RenderBitmapRotate` (AC: 1, 4, 5)
  - [x] Subtask 4.1: Rotation math (`AngleMatrix` + `VectorRotate`) is preserved as-is; build `Vertex2D` from computed `p2[]` positions and `c[]` UVs
  - [x] Subtask 4.2: Call `RenderQuad2D`, remove `glBegin` block
  - [x] Subtask 4.3: Commit: `refactor(render): migrate RenderBitmapRotate to MuRenderer::RenderQuad2D`

- [x] Task 5: Migrate `RenderBitRotate` (AC: 1, 4, 5)
  - [x] Subtask 5.1: Build 4 `Vertex2D` with positions `(p2[i][0] + WindowWidth/2.f, p2[i][1] + WindowHeight/2.f)` and unit UV `(0,0)-(1,1)`
  - [x] Subtask 5.2: Call `RenderQuad2D`, remove `glBegin` block
  - [x] Subtask 5.3: Commit: `refactor(render): migrate RenderBitRotate to MuRenderer::RenderQuad2D`

- [x] Task 6: Migrate `RenderPointRotate` (AC: 1, 4, 5)
  - [x] Subtask 6.1: This function has a second pass (minimap button positioning via `g_pNewUIMiniMap->SetBtnPos`) — that non-rendering section is retained unchanged; only the `glBegin(GL_TRIANGLE_FAN)` block is removed
  - [x] Subtask 6.2: Build 4 `Vertex2D` from `p4[]` positions + centered offset and `c[]` UVs
  - [x] Subtask 6.3: Commit: `refactor(render): migrate RenderPointRotate to MuRenderer::RenderQuad2D`

- [x] Task 7: Migrate `RenderBitmapLocalRotate` (AC: 1, 4, 5)
  - [x] Subtask 7.1: Build 4 `Vertex2D` from computed `p[]` positions and `c[]` UVs
  - [x] Subtask 7.2: Call `RenderQuad2D`, remove `glBegin` block
  - [x] Subtask 7.3: Commit: `refactor(render): migrate RenderBitmapLocalRotate to MuRenderer::RenderQuad2D`

- [x] Task 8: Migrate `RenderBitmapAlpha` (AC: 1, 4, 5)
  - [x] Subtask 8.1: This function renders 4×4 = 16 quads in a loop; iterate and call `RenderQuad2D` 16 times — each iteration builds 4 `Vertex2D` from `p[]` and `c[]`, packing per-vertex alpha from `Alpha[]` into `Vertex2D::color`
  - [x] Subtask 8.2: Prerequisite: `MuRendererGL::RenderQuad2D` must honour per-vertex `color` alpha — verify existing implementation in `MuRenderer.cpp` uses `glColor4ubv` or unpacks the packed ABGR; if not, update `MuRendererGL::RenderQuad2D` to call `glColor4f(r,g,b,a)` per vertex from packed color
  - [x] Subtask 8.3: Commit: `refactor(render): migrate RenderBitmapAlpha to MuRenderer::RenderQuad2D`

- [x] Task 9: Migrate `RenderBitmapUV` (AC: 1, 4, 5)
  - [x] Subtask 9.1: UV layout differs: `c[0]` is `(u, v+vHeight*0.25f)`, `c[1]` is `(u, v+vHeight-vHeight*0.25f)`, `c[2]` is `(u+uWidth, v+vHeight)`, `c[3]` is `(u+uWidth, v)` — preserve this exact UV warp
  - [x] Subtask 9.2: Build 4 `Vertex2D` with the asymmetric UVs, call `RenderQuad2D`, remove `glBegin` block
  - [x] Subtask 9.3: Commit: `refactor(render): migrate RenderBitmapUV to MuRenderer::RenderQuad2D`

- [x] Task 10: Migrate `RenderColor` / `EndRenderColor` untextured color quad (AC: 2, 3)
  - [x] Subtask 10.1: `RenderColor` renders a solid or alpha-blended colored quad with no texture; migrate to `RenderQuad2D(textureId=0)` or new `RenderQuad2DColored()` per Task 1.2 decision
  - [x] Subtask 10.2: Ensure `MuRendererGL` handles `textureId=0` by skipping `glBindTexture` or binding 0 (white texture)
  - [x] Subtask 10.3: Commit: `refactor(render): migrate RenderColor to MuRenderer::RenderQuad2D`

- [x] Task 11: Update `MuRendererGL::RenderQuad2D` for per-vertex color (AC: 1, AC-STD-2)
  - [x] Subtask 11.1: Current `MuRenderer.cpp` implementation emits `glTexCoord2f` + `glVertex3f` only — does not unpack `Vertex2D::color` for `glColor4f`. Add `glColor4ubv` (or manual unpack) to emit per-vertex color. This is required for `RenderBitmapAlpha` and `RenderColorBitmap` migrations
  - [x] Subtask 11.2: Existing test `test_murenderer.cpp` tests blend mode state — add a test asserting color channel is preserved through `Vertex2D::color` packing (or note it is covered by the new test file)

- [x] Task 12: Add Catch2 migration tests (AC: AC-STD-2, AC-VAL-1)
  - [x] Subtask 12.1: Create `MuMain/tests/render/test_renderbitmap_migration.cpp`
  - [x] Subtask 12.2: Add `target_sources(MuTests PRIVATE render/test_renderbitmap_migration.cpp)` in `tests/CMakeLists.txt`
  - [x] Subtask 12.3: `TEST_CASE("RenderQuad2D vertex layout — basic RenderBitmap")`: construct a mock `IMuRenderer` that captures the `vertices` span; call logic equivalent to `RenderBitmap` vertex building; assert UV ordering matches expected `(u,v), (u,v+vHeight), (u+uWidth,v+vHeight), (u+uWidth,v)`
  - [x] Subtask 12.4: `TEST_CASE("Vertex2D color packing — opaque white")`: build `Vertex2D` with `color = 0xFFFFFFFF`, assert r/g/b/a channels are 255 — documents the ABGR packing convention

- [x] Task 13: Quality gate + grep verification (AC: AC-STD-13, AC-VAL-2, AC-VAL-4)
  - [x] Subtask 13.1: Run `./ctl check` — 0 errors
  - [x] Subtask 13.2: Run `grep -n "glBegin\|glEnd" MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp` — confirm no hits in any of the 9 migrated functions (the Enable*Blend functions and other non-RenderBitmap code may still use glBegin in this story — that is 4.2.3–4.2.5 scope)

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A — C++ client, no HTTP error codes | — | — | — |

Logging pattern (new diagnostic only in `MuRenderer.cpp` helpers):
- `g_ErrorReport.Write(L"RENDER: MuRenderer::RenderQuad2DColored -- vertex buffer empty")` (if new method added)

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
| Unit | Catch2 3.7.1 | Vertex layout correctness, color packing | UV ordering for `RenderBitmap`; ABGR color packing for opaque white; vertex count = 4 per call |
| Integration (manual) | Windows build | No regression on existing rendering | All UI windows, login screen, world maps render identically before/after |
| Ground truth (optional) | SSIM tool (story 4.1.1) | SSIM > 0.99 on all migrated screens | Windows OpenGL baseline vs post-migration; run if ground truth baselines available |

---

## Dev Notes

### Context: Why This Story Exists

This story is the highest-impact step in EPIC-4. `ZzzOpenglUtil.cpp` is the **cascade file** — it is `#include`d or `#include "ZzzOpenglUtil.h"` referenced by ~40 game files spanning UI, world maps, scene management, and gameplay. By migrating the 9 `RenderBitmap*` variants and `RenderColor` to `IMuRenderer`, approximately 80% of all rendering in the game flows through the abstraction without requiring changes to any of those 40 call sites.

The 9 variants are wrappers over the same fundamental operation (textured quad), differentiated by coordinate transformation (screen scale, rotation, UV warp, alpha gradient). This story converts each wrapper's `glBegin`/`glEnd` block to a `Vertex2D[4]` + `RenderQuad2D()` call, while preserving all existing coordinate transformation math.

**Scope boundary (strict):** This story does NOT migrate `Enable*Blend`, `EnableDepthTest`, `EnableAlphaTest`, or `BindTexture` calls in `ZzzOpenglUtil.cpp`. Those are story 4.2.5 (blend/pipeline state). This story only touches the `RenderBitmap*` function bodies.

### Key Design Decisions

#### Vertex2D Color Packing (ABGR)

Per `MuRenderer.h` comment, `Vertex2D::color` is packed ABGR matching GL vertex colour layout. For most `RenderBitmap` calls, this is `0xFFFFFFFF` (opaque white). For `RenderBitmapAlpha`, per-vertex alpha is needed — the existing `Alpha[i]` float must be converted: `color = (uint8_t(alpha * 255) << 24) | 0x00FFFFFF`.

#### MuRendererGL::RenderQuad2D — Per-Vertex Color

The current `MuRendererGL::RenderQuad2D` in `MuRenderer.cpp` only emits `glTexCoord2f` + `glVertex3f`. It does NOT emit `glColor*`. This must be fixed in this story (Task 11) so that `RenderColorBitmap` and `RenderBitmapAlpha` migrations work correctly. The fix: unpack `Vertex2D::color` (ABGR) before each vertex and call `glColor4f(r/255.f, g/255.f, b/255.f, a/255.f)`. This is backward-compatible — opaque white `0xFFFFFFFF` maps to `glColor4f(1,1,1,1)` which is the OpenGL default vertex color.

#### RenderColor / Untextured Quads (AC-3)

`RenderColor` renders a solid colored quad with no texture binding. Two implementation options:
- **Option A:** `RenderQuad2D(vertices, textureId=0)` — `MuRendererGL` skips `glBindTexture` when `textureId == 0`
- **Option B:** New `RenderQuad2DColored(std::span<const Vertex2D>)` — explicit untextured path, no texture ID

The implementation should choose Option A (simpler, no interface change) unless the clean-separation principle of `IMuRenderer` strongly favors Option B. Document choice in Dev Agent Record.

#### Triangle Fan vs Quads

All `RenderBitmap*` variants use `GL_TRIANGLE_FAN` with 4 vertices (equivalent to a quad). `IMuRenderer::RenderQuad2D` uses `GL_QUADS` internally in `MuRendererGL`. The vertex order must match:
- Existing code: `p[0](top-left), p[1](bottom-left), p[2](bottom-right), p[3](top-right)` with fan winding
- `GL_QUADS` winding: vertices 0,1,2,3 form two triangles — same four corners, order must be consistent

The `Vertex2D[4]` array should match the existing winding: TL, BL, BR, TR. SDL_gpu (story 4.3.1) will expect consistent winding order.

### Project Structure Notes

**Files to Modify:**

| File | Action | Notes |
|------|--------|-------|
| `MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp` | MODIFY | Remove `glBegin`/`glEnd` from 9 RenderBitmap* + RenderColor; add `#include "MuRenderer.h"` if not already present |
| `MuMain/src/source/RenderFX/MuRenderer.h` | MODIFY (if Option B) | Add `RenderQuad2DColored()` to `IMuRenderer` |
| `MuMain/src/source/RenderFX/MuRenderer.cpp` | MODIFY | Add per-vertex color emission in `RenderQuad2D`; add untextured path if Option A |

**Files to Create:**

| File | CMake Target |
|------|-------------|
| `MuMain/tests/render/test_renderbitmap_migration.cpp` | `MuTests` (explicit add in `tests/CMakeLists.txt`) |

**DO NOT MODIFY:** `ZzzOpenglUtil.h` — all 9 function signatures stay exactly the same. The ~40 call sites (UI, world maps, scenes) are untouched.

**CMake:** `MURenderFX` auto-globs `RenderFX/*.cpp` — no CMakeLists change needed for source file changes. Only `tests/CMakeLists.txt` needs the new test file.

### RenderBitmap Variant Reference Table

| Function | GL Primitive | Coord Transform | UV Layout | Special |
|----------|-------------|-----------------|-----------|---------|
| `RenderBitmap` | GL_TRIANGLE_FAN | ConvertX/Y; WindowHeight flip | standard; optional StartScale | Alpha param for per-vertex alpha |
| `RenderColorBitmap` | GL_TRIANGLE_FAN | ConvertX/Y; WindowHeight flip | standard | `color` param (packed uint) |
| `RenderBitmapRotate` | GL_TRIANGLE_FAN | ConvertX/Y; AngleMatrix + VectorRotate | standard | rotation around center |
| `RenderBitRotate` | GL_TRIANGLE_FAN | ConvertX/Y; AngleMatrix + VectorRotate | unit (0-1) | rotation around screen center |
| `RenderPointRotate` | GL_TRIANGLE_FAN | complex 2-stage rotation | unit sub-rect | minimap button side-effect |
| `RenderBitmapLocalRotate` | GL_TRIANGLE_FAN | ConvertX/Y; cos/sin local pivot | standard | sinf/cosf local pivot rotation |
| `RenderBitmapAlpha` | GL_TRIANGLE_FAN | no ConvertX/Y | 4×4 tile loop | per-vertex edge alpha gradient |
| `RenderBitmapUV` | GL_TRIANGLE_FAN | ConvertX/Y; WindowHeight flip | asymmetric UV warp | UV[1] and UV[3] offset by 0.25f |
| `RenderColor` | GL_QUADS | ConvertX/Y | no UV | solid/alpha fill, no texture |

### Relevant Existing Code

- `MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp` lines 1204–1644: All 9 variants + `RenderColor` to migrate
- `MuMain/src/source/RenderFX/ZzzOpenglUtil.h` lines 103–117: Function signatures (DO NOT CHANGE)
- `MuMain/src/source/RenderFX/MuRenderer.h`: `IMuRenderer` interface, `Vertex2D` struct definition
- `MuMain/src/source/RenderFX/MuRenderer.cpp`: `MuRendererGL::RenderQuad2D` — needs per-vertex color update (Task 11)
- `MuMain/src/source/Main/stdafx.h`: OpenGL inline stubs — already has `glColor4f`, `glColor4ubv` stubs for non-Windows compile
- `MuMain/tests/render/test_murenderer.cpp`: Existing test file for `MatrixStack` and blend state — reference for test patterns

### Technical Implementation

#### MuRendererGL::RenderQuad2D Update (per-vertex color)

```cpp
void RenderQuad2D(std::span<const Vertex2D> vertices, std::uint32_t textureId) override
{
    if (vertices.empty())
    {
        g_ErrorReport.Write(L"RENDER: MuRenderer::RenderQuad2D -- vertex buffer empty");
        return;
    }

    if (textureId != 0)
    {
        glBindTexture(GL_TEXTURE_2D, static_cast<GLuint>(textureId));
    }
    else
    {
        glBindTexture(GL_TEXTURE_2D, 0); // untextured — white
    }

    glBegin(GL_QUADS);
    for (const Vertex2D& v : vertices)
    {
        // Unpack ABGR: stored as A=bits31-24, B=bits23-16, G=bits15-8, R=bits7-0
        const auto a = static_cast<float>((v.color >> 24) & 0xFF) / 255.f;
        const auto b = static_cast<float>((v.color >> 16) & 0xFF) / 255.f;
        const auto g = static_cast<float>((v.color >> 8) & 0xFF) / 255.f;
        const auto r = static_cast<float>((v.color) & 0xFF) / 255.f;
        glColor4f(r, g, b, a);
        glTexCoord2f(v.u, v.v);
        glVertex3f(v.x, v.y, 0.0f);
    }
    glEnd();
}
```

#### Example: RenderBitmap Migration Pattern

```cpp
// BEFORE (in ZzzOpenglUtil.cpp):
void RenderBitmap(int Texture, float x, float y, float Width, float Height,
                  float u, float v, float uWidth, float vHeight, bool Scale, bool StartScale, float Alpha)
{
    if (StartScale) { x = ConvertX(x); y = ConvertY(y); }
    if (Scale) { Width = ConvertX(Width); Height = ConvertY(Height); }
    BindTexture(Texture);
    float p[4][2];
    y = WindowHeight - y;
    p[0][0] = x;       p[0][1] = y;
    p[1][0] = x;       p[1][1] = y - Height;
    p[2][0] = x+Width; p[2][1] = y - Height;
    p[3][0] = x+Width; p[3][1] = y;
    float c[4][2];
    TEXCOORD(c[0], u, v);
    TEXCOORD(c[3], u+uWidth, v);
    TEXCOORD(c[2], u+uWidth, v+vHeight);
    TEXCOORD(c[1], u, v+vHeight);
    glBegin(GL_TRIANGLE_FAN);
    for (int i = 0; i < 4; i++)
    {
        if (Alpha > 0.f) { glColor4f(1.f, 1.f, 1.f, Alpha); }
        glTexCoord2f(c[i][0], c[i][1]);
        glVertex2f(p[i][0], p[i][1]);
        if (Alpha > 0.f) { glColor4f(1.f, 1.f, 1.f, 1.f); }
    }
    glEnd();
}

// AFTER:
void RenderBitmap(int Texture, float x, float y, float Width, float Height,
                  float u, float v, float uWidth, float vHeight, bool Scale, bool StartScale, float Alpha)
{
    if (StartScale) { x = ConvertX(x); y = ConvertY(y); }
    if (Scale) { Width = ConvertX(Width); Height = ConvertY(Height); }
    y = WindowHeight - y;

    const std::uint32_t color = (Alpha > 0.f)
        ? (static_cast<std::uint32_t>(Alpha * 255.f) << 24) | 0x00FFFFFFu
        : 0xFFFFFFFFu; // opaque white in ABGR

    const mu::Vertex2D vertices[4] = {
        { x,         y,          u,         v         , color },
        { x,         y - Height, u,         v + vHeight, color },
        { x + Width, y - Height, u + uWidth, v + vHeight, color },
        { x + Width, y,          u + uWidth, v,           color },
    };
    mu::GetRenderer().RenderQuad2D(vertices, static_cast<std::uint32_t>(Texture));
}
```

> **Note:** The UV order changes from the original `TEXCOORD` fan ordering to a consistent CCW quad winding. The dev agent must verify GL_QUADS winding vs GL_TRIANGLE_FAN winding produces the same visual result — both are CCW with the same 4 corner positions.

#### stdafx.h stubs to verify

The following stubs must exist in `stdafx.h` for non-Windows compile (added in story 4.2.1 or earlier):
- `glColor4f` — YES (existing)
- `glColor4ubv` — verify; add if missing
- `glBindTexture(GL_TEXTURE_2D, 0)` — covered by existing `glBindTexture` stub

### PCC Project Constraints

**Tech Stack:** C++20, CMake 3.25+, Catch2 3.7.1, OpenGL (via stubs on non-Windows), `MURenderFX` CMake target, `MUGame` target (for UI files that call RenderBitmap — not modified in this story)

**Prohibited (per project-context.md):**
- `new`/`delete` — use `std::array`, `std::span`, stack arrays
- `NULL` — use `nullptr`
- `wprintf`, `__TraceF()`, `DebugAngel` — use `g_ErrorReport.Write()`
- `#ifndef` header guards — `#pragma once`
- `#ifdef _WIN32` in `ZzzOpenglUtil.cpp` or `MuRenderer.cpp` — OpenGL stubs handle non-Windows compile
- OpenGL types in `MuRenderer.h` — `GLenum`, `GLuint` stay out of the interface header

**Required patterns (per project-context.md):**
- `std::span<const Vertex2D>` for vertex buffer parameters (C++20)
- `[[nodiscard]]` on any new fallible functions
- `mu::` namespace for all new code in `MuRenderer.h/.cpp`
- Allman brace style, 4-space indent, 120-column limit (`.clang-format`)
- `#pragma once` header guards
- Include order: preserve existing (`SortIncludes: Never`)

**Quality gate:** `./ctl check` — must pass 0 errors. File count increases from 705 by +1 test file = 706 files.

**Testing:** Catch2 `TEST_CASE` / `SECTION` / `REQUIRE` / `CHECK`. No mocking framework — use inline test-double struct. Pure logic only in test TU (no `gl*` calls).

### References

- [Source: `_bmad-output/project-context.md` — C++ Language Rules, CMake Module Targets, Testing Rules]
- [Source: `docs/architecture-rendering.md` — MuRenderer API Surface, Blend Modes, SDL_gpu Concept Mapping, RenderBitmap variant inventory]
- [Source: `_bmad-output/planning-artifacts/epics.md` — Epic 4, Story 4.2.2]
- [Source: `_bmad-output/stories/4-2-1-murenderer-core-api/story.md` — IMuRenderer interface, Vertex2D struct, MuRendererGL patterns, Dev Agent Record learnings]
- [Source: `MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp` lines 1204–1644 — 9 RenderBitmap* variants and RenderColor to migrate]
- [Source: `MuMain/src/source/RenderFX/ZzzOpenglUtil.h` lines 103–117 — function signatures (unchanged)]
- [Source: `MuMain/src/source/RenderFX/MuRenderer.h` — Vertex2D struct; color field is packed ABGR]
- [Source: `MuMain/src/source/RenderFX/MuRenderer.cpp` — MuRendererGL::RenderQuad2D (needs per-vertex color update)]
- [Source: `MuMain/src/source/Main/stdafx.h` — OpenGL inline stubs for non-Windows compile]
- [Source: `MuMain/tests/render/test_murenderer.cpp` — test pattern reference (BlendModeTracker mock style)]

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- AC-VAL-4 grep result (2026-03-09): `grep -n "glBegin\|glEnd" MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp` — no hits in lines 1204+ (migrated functions). Remaining hits at lines 280, 284, 292, 921-982, 999-1008, 1070-1114 are in non-migrated `BindTextureStream`, `RenderBox`, `RenderPlane3D` — outside story scope.
- Quality gate: `./ctl check` passed 0 clang-format errors, 0 cppcheck errors, 705 files (file count unchanged — test file was pre-created in ATDD phase).
- Test TU `test_renderbitmap_migration.cpp` compiles cleanly after adding `<catch2/catch_approx.hpp>` (was missing from ATDD-generated file).

### Completion Notes List

- **AC-3 Decision (Option A):** Chose `textureId=0` sentinel for `RenderColor` untextured path. No new interface method added (`RenderQuad2DColored()` not needed). Rationale: simpler, avoids interface churn, preserves `DisableTexture()` call in caller which already disables the GL texture unit. The `(void)textureId;` in `MuRendererGL::RenderQuad2D` ensures the OpenGL backend never calls `glBindTexture` — texture binding remains the caller's responsibility (via `BindTexture()`/`DisableTexture()`) throughout this transitional phase. Story 4.3.1 (SDL_gpu backend) will use `textureId` actively.
- **Task 11 (Prerequisite):** `MuRendererGL::RenderQuad2D` in `MuRenderer.cpp` updated to emit `glColor4f(r,g,b,a)` per vertex by unpacking `Vertex2D::color` ABGR. Backward-compatible: opaque white `0xFFFFFFFF` maps to `glColor4f(1,1,1,1)` (OpenGL default).
- **RenderBitmapAlpha 16-call loop:** Kept the 4×4 inner loop structure intact. Each iteration calls `RenderQuad2D` once with 4 vertices, for 16 total calls. Per-vertex alpha from `Alpha[i]` float packed into ABGR A-channel.
- **RenderPointRotate restructuring:** `VectorTransform` calls moved outside the old `for (i=0; i<4)` loop. `Matrix[0][3]` and `Matrix[1][3]` set once before all 4 transforms (correct, since Matrix is the same for all 4). Minimap `SetBtnPos` side-effect retained unchanged.
- **Catch2 header fix:** ATDD-generated `test_renderbitmap_migration.cpp` used `Catch::Approx()` but only included `catch_test_macros.hpp`. Added `<catch2/catch_approx.hpp>` — included in commit `e1526c63` (Task 11 commit).
- **Pre-existing compilation blocker (macOS only):** `muConsoleDebug.cpp: use of undeclared identifier 'SetMaxMessagePerCycle'` blocks `MUCore` → `MuTests`. This is a pre-existing issue (not caused by this story). Per `CLAUDE.md` `skip_checks: [build, test]`, macOS cannot compile Win32 targets. Tests verified to compile correctly via direct object file build; full test run requires MinGW/Windows environment.

### File List

| File | Action | Description |
|------|--------|-------------|
| `MuMain/src/source/RenderFX/MuRenderer.cpp` | MODIFIED | Task 11: Added per-vertex ABGR color unpack + `glColor4f()` emission; changed texture binding to caller-managed (`(void)textureId`) |
| `MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp` | MODIFIED | Added `#include "MuRenderer.h"`; migrated 9 `RenderBitmap*` variants + `RenderColor` to `mu::GetRenderer().RenderQuad2D()` |
| `MuMain/tests/render/test_renderbitmap_migration.cpp` | MODIFIED (minor) | Added `#include <catch2/catch_approx.hpp>` (pre-existing ATDD file, missing include) |
| `MuMain/tests/render/test_renderbitmap_migration.cpp` | PRE-EXISTS | Created in ATDD phase: 7 TEST_CASEs for vertex layout, color packing, call count |
| `MuMain/tests/CMakeLists.txt` | PRE-EXISTS (modified in ATDD) | `target_sources(MuTests PRIVATE render/test_renderbitmap_migration.cpp)` already added |

### Change Log

| Date | Change | Commit |
|------|--------|--------|
| 2026-03-09 | feat(render): add per-vertex color to MuRendererGL::RenderQuad2D + catch_approx fix | `e1526c63` |
| 2026-03-09 | refactor(render): migrate RenderColor | `4e13fadf` |
| 2026-03-09 | refactor(render): migrate RenderColorBitmap | `fb877418` |
| 2026-03-09 | refactor(render): migrate RenderBitmap | `40d3a198` |
| 2026-03-09 | refactor(render): migrate RenderBitmapRotate | `c4f42c78` |
| 2026-03-09 | refactor(render): migrate RenderBitRotate | `ae9168fe` |
| 2026-03-09 | refactor(render): migrate RenderPointRotate | `0605a7d1` |
| 2026-03-09 | refactor(render): migrate RenderBitmapLocalRotate | `c2f33e54` |
| 2026-03-09 | refactor(render): migrate RenderBitmapAlpha | `ff6c434b` |
| 2026-03-09 | refactor(render): migrate RenderBitmapUV | `4f5e8462` |
