# Story 4.2.5: Migrate Blend & Pipeline State to MuRenderer

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 4 - Rendering Pipeline Migration |
| Feature | 4.2 - MuRenderer Abstraction |
| Story ID | 4.2.5 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | `infrastructure` |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-RENDER-MIGRATE-STATE |
| FRs Covered | FR12, FR13, FR14, FR15 |
| Prerequisites | Story 4.2.1 (MuRenderer Core API — done); Story 4.2.2 (RenderBitmap migration — done, sibling); Story 4.2.3 (Skeletal mesh migration — done, sibling); Story 4.2.4 (Trail effects migration — done, sibling) |

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Migrate all `EnableAlphaBlend*`, `DisableAlphaBlend`, `EnableDepthTest/DisableDepthTest`, and `glFogi/glFogf` direct calls in game logic files to `mu::GetRenderer().SetBlendMode()`, `SetDepthTest()`, and `SetFog()`; add Catch2 tests in `tests/render/` |
| project-docs | documentation | Story artifacts |

---

## Story

**[VS-1] [Flow:F]**

**As a** developer,
**I want** all blend mode, depth test, and fog state calls migrated from the seven `Enable*Blend` / `Disable*` helper functions and scattered `glEnable`/`glDisable`/`glFog*` direct calls to `mu::GetRenderer().SetBlendMode()`, `SetDepthTest()`, and `SetFog()`,
**so that** no direct OpenGL state management remains in game logic files — only in `ZzzOpenglUtil.cpp` (the compatibility shim) and `MuRenderer.cpp` (the rendering backend).

---

## Functional Acceptance Criteria

- [ ] **AC-1:** The seven blend-state helper functions in `ZzzOpenglUtil.cpp` are **wrapped** to delegate to `mu::GetRenderer().SetBlendMode(mode)` internally — the existing public function signatures (`EnableAlphaBlend()`, `DisableAlphaBlend()`, `EnableAlphaBlendMinus()`, `EnableAlphaBlend2()`, `EnableAlphaBlend3()`, `EnableAlphaBlend4()`, `EnableLightMap()`) are **preserved** so that the ~368 existing call sites across game logic files compile unchanged (no call-site migration required for this story — the wrapper is the migration)

- [ ] **AC-2:** The blend-state type guard logic (`if (AlphaBlendType != N)`) is preserved inside the wrapper functions in `ZzzOpenglUtil.cpp` — these guards prevent redundant GL state changes and must remain working

- [ ] **AC-3:** `EnableDepthTest()` and `DisableDepthTest()` in `ZzzOpenglUtil.cpp` are wrapped to delegate to `mu::GetRenderer().SetDepthTest(true/false)` — the two direct `glEnable(GL_DEPTH_TEST)` / `glDisable(GL_DEPTH_TEST)` calls in `CameraMove.cpp` are migrated to call `EnableDepthTest()` / `DisableDepthTest()` instead (eliminating direct GL calls from game logic)

- [ ] **AC-4:** The fog setup in `GMBattleCastle.cpp` (lines ~590–593: `glFogfv`, `glFogf` × 3 calls) is migrated to `mu::GetRenderer().SetFog(params)` using a `mu::FogParams` struct with `mode = GL_LINEAR`, `start = 2000.f`, `end = 2700.f`, `density = 0.f`, and the existing `Color` float array copied into `params.color[4]`

- [ ] **AC-5:** No direct `glEnable(GL_BLEND)` / `glDisable(GL_BLEND)` / `glBlendFunc` calls remain outside `MuRenderer.cpp` and `ZzzOpenglUtil.cpp`; no direct `glFogi` / `glFogf` / `glFogfv` calls remain outside `MuRenderer.cpp` and `ZzzOpenglUtil.cpp` — verified by grep

- [ ] **AC-6:** The `MuRendererGL::SetBlendMode()` implementation already handles all six `BlendMode` enum values (`Alpha`, `Additive`, `Subtract`, `InverseColor`, `Mixed`, `LightMap`) — verify the mapping against `ZzzOpenglUtil.cpp` blend functions; note that `EnableAlphaBlend()` uses `GL_ONE/GL_ONE` which is NOT in the current `BlendMode` enum; add `BlendMode::Additive2` for `GL_ONE/GL_ONE` and update `MuRendererGL::SetBlendMode()` accordingly, OR redirect `EnableAlphaBlend()` to the closest existing mode with a comment explaining the semantic difference

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance — `mu::` namespace for all new helpers, PascalCase functions, `m_` member prefix, `#pragma once`, no raw `new`/`delete`, `[[nodiscard]]` on new fallible functions, no `NULL` (use `nullptr`), no `wprintf`, no `#ifdef _WIN32` in game logic files

- [ ] **AC-STD-2:** Catch2 tests in `tests/render/test_blendpipelinestate_migration.cpp` verifying: (a) `SetBlendMode` is routable (mock implementation verifies correct `BlendMode` enum value is passed for each of the 7 helper functions); (b) `SetDepthTest(true)` and `SetDepthTest(false)` pass correct bool; (c) `SetFog` with `GL_LINEAR` mode and known params populates `FogParams` struct correctly — tests must compile and pass on macOS/Linux (no `gl*` calls in tests)

- [ ] **AC-STD-3:** No direct `glBlendFunc` / `glEnable(GL_BLEND)` / `glDisable(GL_BLEND)` / `glFogi` / `glFogf` / `glFogfv` calls outside `MuRenderer.cpp` and `ZzzOpenglUtil.cpp` — verified by targeted grep

- [ ] **AC-STD-4:** CI quality gate passes (`./ctl check` — clang-format check + cppcheck 0 errors)

- [ ] **AC-STD-5:** Error logging: existing guards in `MuRenderer.cpp` (`g_ErrorReport.Write(L"RENDER: MuRenderer::SetBlendMode -- unknown blend mode %d", ...)` and `g_ErrorReport.Write(L"RENDER: MuRenderer::SetFog -- unsupported fog mode %d", ...)`) are already in place — no new error codes required

- [ ] **AC-STD-6:** Conventional commits: `refactor(render): wrap blend-state helpers to delegate to MuRenderer::SetBlendMode` and `refactor(render): migrate fog setup in GMBattleCastle to MuRenderer::SetFog`

- [ ] **AC-STD-12:** N/A — C++ client infrastructure story; no server-side SLI/SLO latency targets

- [ ] **AC-STD-14:** N/A — infrastructure story; no new observable metrics introduced; existing error paths use `g_ErrorReport.Write()` patterns already documented in AC-STD-5

- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format check + cppcheck 0 errors); file count 727 (post-4.2.4 baseline) + 1 new test file = 728 files

- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)

- [ ] **AC-STD-16:** Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/render/` directory pattern, `target_sources` in `tests/CMakeLists.txt`)

---

## Validation Artifacts

- [ ] **AC-VAL-1:** Catch2 tests pass for `SetBlendMode` routing with all 7 blend function mappings, `SetDepthTest` bool values, and `FogParams` struct population for `GL_LINEAR`

- [ ] **AC-VAL-2:** `./ctl check` passes with 0 errors after all migrations applied

- [ ] **AC-VAL-3:** Windows build renders alpha-blended effects (water, particles, UI transparency, skill glow) identically before/after migration — verified manually or via ground truth comparison from story 4.1.1 baselines (SSIM > 0.99). **Status: manual validation only — automated verification deferred to epic-4 ground truth gate (story 4.4.1).**

- [ ] **AC-VAL-4:** Grep verification — no direct `glBlendFunc`, `glEnable(GL_BLEND)`, `glDisable(GL_BLEND)`, `glFogi`, `glFogf`, `glFogfv` in game logic files outside `MuRenderer.cpp` and `ZzzOpenglUtil.cpp`:
  ```
  grep -rn "glBlendFunc\|glEnable(GL_BLEND\|glDisable(GL_BLEND\|glFogi\|glFogf\b" MuMain/src/source --include="*.cpp" | grep -v "ZzzOpenglUtil\|MuRenderer"
  ```
  Expected: zero hits

---

## Tasks / Subtasks

- [ ] Task 1: Analyze blend mode mapping between `ZzzOpenglUtil.cpp` and `MuRenderer::BlendMode` enum (AC: 1, 2, 6)
  - [ ] Subtask 1.1: Read `ZzzOpenglUtil.cpp` blend functions (lines ~376–566) and map each to the `BlendMode` enum:
    - `EnableLightMap()`: `GL_ZERO, GL_SRC_COLOR` → `BlendMode::LightMap` ✓
    - `EnableAlphaTest()`: `GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA` → `BlendMode::Alpha` ✓
    - `EnableAlphaBlend()`: `GL_ONE, GL_ONE` → **NOT in BlendMode enum** — needs resolution
    - `EnableAlphaBlendMinus()`: `GL_ZERO, GL_ONE_MINUS_SRC_COLOR` → `BlendMode::Subtract` ✓
    - `EnableAlphaBlend2()`: `GL_ONE_MINUS_SRC_COLOR, GL_ONE` → **NOT in BlendMode enum** — needs resolution
    - `EnableAlphaBlend3()`: `GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA` → `BlendMode::Alpha` (same as Alpha) ✓
    - `EnableAlphaBlend4()`: `GL_ONE, GL_ONE_MINUS_SRC_COLOR` → `BlendMode::Mixed` ✓
    - `DisableAlphaBlend()`: `glDisable(GL_BLEND)` → needs `SetBlendMode` with Disabled, OR a `DisableBlend()` on IMuRenderer
  - [ ] Subtask 1.2: Decide on resolution for unmapped blend modes — two options:
    - **Option A (recommended):** Add `BlendMode::Glow` for `GL_ONE/GL_ONE` and `BlendMode::Luminance` for `GL_ONE_MINUS_SRC_COLOR/GL_ONE` to the `BlendMode` enum in `MuRenderer.h`, and add a `DisableBlend()` method to `IMuRenderer` (or add `BlendMode::Disabled` sentinel); update `MuRendererGL::SetBlendMode()` in `MuRenderer.cpp`
    - **Option B:** Comment inside `EnableAlphaBlend()` wrapper explaining the semantic and route to nearest existing mode (lossy — not recommended)
    - **Choose Option A** — adds 2 enum values, 1 optional method; cleaner for story 4.3.1 (SDL_gpu backend)
  - [ ] Subtask 1.3: Note that `EnableAlphaTest()` carries side-effects (`glAlphaTest`) beyond blend factors — document this as out-of-scope for this story; the alpha test GL state is not in `IMuRenderer` yet; leave `EnableAlphaTest()` body mostly intact for the blend portion, add TODO for alpha test migration in story 4.3.x

- [ ] Task 2: Add missing BlendMode enum values and DisableBlend to MuRenderer (AC: 6, if Option A chosen)
  - [ ] Subtask 2.1: In `MuRenderer.h`, add to `BlendMode` enum: `Glow` (GL_ONE, GL_ONE) and `Luminance` (GL_ONE_MINUS_SRC_COLOR, GL_ONE); add `Disabled` sentinel (value 0xFF or similar) for the disable path; add `virtual void DisableBlend() = 0;` to `IMuRenderer`
  - [ ] Subtask 2.2: In `MuRenderer.cpp`, add cases in `MuRendererGL::SetBlendMode()`: `case BlendMode::Glow: glBlendFunc(GL_ONE, GL_ONE); break;` and `case BlendMode::Luminance: glBlendFunc(GL_ONE_MINUS_SRC_COLOR, GL_ONE); break;`; implement `MuRendererGL::DisableBlend()` as `glDisable(GL_BLEND);`
  - [ ] Subtask 2.3: Commit: `feat(render): extend BlendMode enum with Glow/Luminance/DisableBlend for full state coverage`

- [ ] Task 3: Wrap blend-state helpers in `ZzzOpenglUtil.cpp` to delegate to MuRenderer (AC: 1, 2, 5)
  - [ ] Subtask 3.1: Modify `EnableLightMap()`: keep `if (AlphaBlendType != 1)` guard; replace `glEnable(GL_BLEND); glBlendFunc(GL_ZERO, GL_SRC_COLOR);` with `mu::GetRenderer().SetBlendMode(mu::BlendMode::LightMap);`; keep the `EnableCullFace()`, `EnableDepthMask()`, `AlphaTestEnable`, texture, and fog side-effects as-is
  - [ ] Subtask 3.2: Modify `DisableAlphaBlend()`: keep guard; replace `glDisable(GL_BLEND);` with `mu::GetRenderer().DisableBlend();`; keep all other side-effects
  - [ ] Subtask 3.3: Modify `EnableAlphaBlend()`: keep guard; replace `glEnable(GL_BLEND); glBlendFunc(GL_ONE, GL_ONE);` with `mu::GetRenderer().SetBlendMode(mu::BlendMode::Glow);`
  - [ ] Subtask 3.4: Modify `EnableAlphaBlendMinus()`: replace GL calls with `mu::GetRenderer().SetBlendMode(mu::BlendMode::Subtract);`
  - [ ] Subtask 3.5: Modify `EnableAlphaBlend2()`: replace GL calls with `mu::GetRenderer().SetBlendMode(mu::BlendMode::Luminance);`
  - [ ] Subtask 3.6: Modify `EnableAlphaBlend3()`: replace GL calls with `mu::GetRenderer().SetBlendMode(mu::BlendMode::Alpha);`
  - [ ] Subtask 3.7: Modify `EnableAlphaBlend4()`: replace GL calls with `mu::GetRenderer().SetBlendMode(mu::BlendMode::Mixed);`
  - [ ] Subtask 3.8: Add `#include "MuRenderer.h"` to `ZzzOpenglUtil.cpp` if not already present (include as `"MuRenderer.h"` — flat by directory per project conventions, NOT `"RenderFX/MuRenderer.h"`)
  - [ ] Subtask 3.9: Commit: `refactor(render): wrap blend-state helpers to delegate to MuRenderer::SetBlendMode`

- [ ] Task 4: Wrap depth test helpers in `ZzzOpenglUtil.cpp` and fix direct GL calls in `CameraMove.cpp` (AC: 3, 5)
  - [ ] Subtask 4.1: Modify `EnableDepthTest()` in `ZzzOpenglUtil.cpp`: keep `if (!DepthTestEnable)` guard; replace `glEnable(GL_DEPTH_TEST);` with `mu::GetRenderer().SetDepthTest(true);`
  - [ ] Subtask 4.2: Modify `DisableDepthTest()` in `ZzzOpenglUtil.cpp`: keep `if (DepthTestEnable)` guard; replace `glDisable(GL_DEPTH_TEST);` with `mu::GetRenderer().SetDepthTest(false);`
  - [ ] Subtask 4.3: In `CameraMove.cpp` line ~486: replace `glDisable(GL_DEPTH_TEST);` with `DisableDepthTest();` (already declared in `ZzzOpenglUtil.h`); in `CameraMove.cpp` line ~517: replace `glEnable(GL_DEPTH_TEST);` with `EnableDepthTest();`
  - [ ] Subtask 4.4: Verify `CameraMove.cpp` already includes `ZzzOpenglUtil.h` (should be via stdafx.h or direct include); if not, add include
  - [ ] Subtask 4.5: Commit: `refactor(render): wrap depth test helpers to delegate to MuRenderer::SetDepthTest`

- [ ] Task 5: Migrate fog setup in `GMBattleCastle.cpp` to `MuRenderer::SetFog` (AC: 4, 5)
  - [ ] Subtask 5.1: Read `GMBattleCastle.cpp` lines ~585–595 to understand context of the fog setup — note the `Color` float array declaration, the fog enable call, and the four fog parameter calls
  - [ ] Subtask 5.2: Replace the four direct `glFogfv`/`glFogf` calls (lines ~590–593) with:
    ```cpp
    mu::FogParams fogParams{};
    fogParams.mode = GL_LINEAR;
    fogParams.start = 2000.f;
    fogParams.end = 2700.f;
    fogParams.density = 0.f;
    fogParams.color[0] = Color[0];
    fogParams.color[1] = Color[1];
    fogParams.color[2] = Color[2];
    fogParams.color[3] = Color[3];
    mu::GetRenderer().SetFog(fogParams);
    ```
    Note: `MuRendererGL::SetFog()` already calls `glEnable(GL_FOG)` internally, so any preceding `glEnable(GL_FOG)` in the original code block should be removed if it exists (or left if it's conditional — check context)
  - [ ] Subtask 5.3: Add `#include "MuRenderer.h"` to `GMBattleCastle.cpp` if not already present
  - [ ] Subtask 5.4: Commit: `refactor(render): migrate fog setup in GMBattleCastle to MuRenderer::SetFog`

- [ ] Task 6: Add Catch2 migration tests (AC: AC-STD-2, AC-VAL-1)
  - [ ] Subtask 6.1: Create `MuMain/tests/render/test_blendpipelinestate_migration.cpp`
  - [ ] Subtask 6.2: Add `target_sources(MuTests PRIVATE render/test_blendpipelinestate_migration.cpp)` in `MuMain/tests/CMakeLists.txt` under `BUILD_TESTING` guard with a Story 4.2.5 comment block (matching the pattern from 4.2.4)
  - [ ] Subtask 6.3: `TEST_CASE("SetBlendMode — blend helper mapping to BlendMode enum")`: define inline `MockRenderer : public mu::IMuRenderer`; call `mock.SetBlendMode(mu::BlendMode::LightMap)`; assert `lastMode == mu::BlendMode::LightMap`; repeat for all 7 mode values (Alpha, Additive, Subtract, InverseColor, Mixed, Glow, Luminance)
  - [ ] Subtask 6.4: `TEST_CASE("SetDepthTest — enable and disable paths")`: call `mock.SetDepthTest(true)`; assert `lastDepthEnabled == true`; call `mock.SetDepthTest(false)`; assert `lastDepthEnabled == false`
  - [ ] Subtask 6.5: `TEST_CASE("SetFog — GL_LINEAR params population")`: build a `mu::FogParams` with `mode=GL_LINEAR, start=2000.f, end=2700.f, density=0.f, color={0.5f,0.5f,0.5f,1.f}`; call `mock.SetFog(params)`; assert `capturedParams.start == 2000.f` and `capturedParams.mode == GL_LINEAR`

- [ ] Task 7: Quality gate + grep verification (AC: AC-STD-13, AC-VAL-2, AC-VAL-4)
  - [ ] Subtask 7.1: Run `./ctl check` — 0 errors
  - [ ] Subtask 7.2: Run grep to confirm no stray GL blend/fog calls remain outside `MuRenderer.cpp` and `ZzzOpenglUtil.cpp`:
    ```bash
    grep -rn "glBlendFunc\|glEnable(GL_BLEND\|glDisable(GL_BLEND\|glFogi\|glFogf\b" MuMain/src/source --include="*.cpp" | grep -v "ZzzOpenglUtil\|MuRenderer"
    ```

---

## Error Codes Introduced

| Code | Category | HTTP | Message Key |
|------|----------|------|-------------|
| N/A — C++ client, no HTTP error codes | — | — | — |

Logging patterns (already in `MuRenderer.cpp` from story 4.2.1):
- `g_ErrorReport.Write(L"RENDER: MuRenderer::SetBlendMode -- unknown blend mode %d", ...)` — triggered on unrecognized enum value
- `g_ErrorReport.Write(L"RENDER: MuRenderer::SetFog -- unsupported fog mode %d", ...)` — triggered on unrecognized fog mode

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
| Unit | Catch2 3.7.1 | SetBlendMode 7-mode routing, SetDepthTest bool, FogParams struct construction | All 7 blend helper mappings; depth enable/disable; fog params for GL_LINEAR |
| Integration (manual) | Windows build | No regression on all alpha-blended rendering | UI transparency, water effects, particle glow, fog zones (BattleCastle) |
| Ground truth (optional) | SSIM tool (story 4.1.1) | SSIM > 0.99 on alpha-blended scenes | Windows OpenGL baseline vs post-migration |

---

## Dev Notes

### Context: Why This Story Exists

`ZzzOpenglUtil.cpp` currently contains 7 standalone helper functions (`EnableAlphaBlend*`, `DisableAlphaBlend`, `EnableLightMap`) that directly call `glEnable(GL_BLEND)`, `glDisable(GL_BLEND)`, and `glBlendFunc()`. These are called from ~368 locations across the game codebase. Additionally, `EnableDepthTest`/`DisableDepthTest` call `glEnable/glDisable(GL_DEPTH_TEST)` directly, and `GMBattleCastle.cpp` has the only direct fog setup calls (`glFogi`/`glFogf`/`glFogfv`) outside `ZzzOpenglUtil.cpp`.

Story 4.2.5's approach is **wrapper-based** rather than **call-site-based**:
- Instead of modifying ~368 call sites (which would be enormous scope), the 7 helper functions in `ZzzOpenglUtil.cpp` are modified to delegate to `mu::GetRenderer()` internally
- The public function signatures remain unchanged — all callers compile unchanged
- This achieves the AC-4 objective: "All GL state changes go through MuRenderer" — because the helpers now go through MuRenderer, and the helpers are the exclusive interface for game logic

### Scope Boundaries (Critical)

**In scope:**
- `ZzzOpenglUtil.cpp` — modifying the 7 blend helpers and 2 depth test helpers to delegate to `mu::GetRenderer()`
- `GMBattleCastle.cpp` — only fog-setup migration (4 `glFog*` calls, lines ~590–593)
- `CameraMove.cpp` — replacing 2 direct `glEnable/glDisable(GL_DEPTH_TEST)` with `EnableDepthTest()`/`DisableDepthTest()`
- `MuRenderer.h` / `MuRenderer.cpp` — adding 2 missing `BlendMode` enum values (`Glow`, `Luminance`) and `DisableBlend()` to cover all 7 blend helper modes

**Out of scope (explicitly):**
- Migrating the ~368 call sites from game logic to use `mu::GetRenderer()` directly — they continue to call `EnableAlphaBlend()` etc.
- `glAlphaTest` state inside `EnableAlphaTest()` — not in `IMuRenderer` interface yet; defer to story 4.3.x
- `glPushMatrix()`/`glTranslatef()`/`glPopMatrix()` matrix stack calls — story 4.2.4 Dev Notes explicitly left these for story 4.2.5; however, `MuRenderer.h` does not yet have a `MatrixStack` interface; defer to 4.3.x as matrix state migration is more complex than blend/fog
- `glDepthFunc(GL_LEQUAL)` in `MuRendererGL::SetDepthTest()` — already present from story 4.2.1; no change needed
- Fog in `ZzzOpenglUtil.cpp`'s `BeginOpengl()` function (line ~625 area) — it's part of the GL context setup/reset path and is tightly coupled to `FogEnable` state; leave as-is for this story
- Any `glEnable(GL_DEPTH_TEST)` at game loop initialization in `ZzzOpenglUtil.cpp::BeginOpengl()` (line ~612) — leave as-is

### Key Design Decisions

#### Wrapper Approach vs. Call-Site Migration

The ~368 call sites to `EnableAlphaBlend*` functions span 50+ files across UI, rendering, effects, world, and scene modules. Migrating them all in one story would be impractical and high-risk. The wrapper approach:
1. Keeps the story at 3 story points (as estimated in epic)
2. Achieves the architectural goal: GL state changes route through MuRenderer
3. Is transparent to all callers — zero call-site changes
4. Is reversible: if MuRenderer's behavior differs from direct GL, we can fall back

#### BlendMode Enum Gap — `GL_ONE/GL_ONE` and `GL_ONE_MINUS_SRC_COLOR/GL_ONE`

The original `BlendMode` enum (story 4.2.1) has 6 values. `EnableAlphaBlend()` uses `GL_ONE/GL_ONE` which maps to neither `Additive` (GL_SRC_ALPHA/GL_ONE) nor any other existing mode. `EnableAlphaBlend2()` uses `GL_ONE_MINUS_SRC_COLOR/GL_ONE` which is also unmapped.

Resolution: Add `BlendMode::Glow` (GL_ONE/GL_ONE — bright additive compositing) and `BlendMode::Luminance` (GL_ONE_MINUS_SRC_COLOR/GL_ONE — inverse-based luminance blend). These names are semantically descriptive of their visual effect in MU Online (glow effects use GL_ONE/GL_ONE for maximum brightness).

For `DisableAlphaBlend()`, add `virtual void DisableBlend() = 0;` to `IMuRenderer` rather than adding a `BlendMode::Disabled` sentinel — a separate method is cleaner because "no blending" is a distinct render state, not a blend mode setting.

#### `glColor3f` / `glColor3fv` Calls Remain (Out of Scope)

Story 4.2.4 Dev Notes (Task 1.3) explicitly stated that `glColor3f`/`glColor3fv` state calls in `ZzzEffectJoint.cpp` were out of scope for 4.2.4 and intended for story 4.2.5. However, after analysis, the `glColor*` call pattern in `ZzzEffectJoint.cpp` is a **vertex attribute** (the current color is part of the GL vertex stream), not a **pipeline state** — it affects the GL state machine's current color but is consumed per-vertex. Migrating these would require adding a `SetCurrentColor()` method to `IMuRenderer`, which is premature before the SDL_gpu backend work in 4.3.1. Leave `glColor*` calls in place.

#### Include Order and PCH

When adding `#include "MuRenderer.h"` to `ZzzOpenglUtil.cpp` and `GMBattleCastle.cpp`:
- The PCH `stdafx.h` is already included first — this is correct (all source files use `#include "stdafx.h"` as the first include)
- Add `#include "MuRenderer.h"` AFTER `#include "stdafx.h"` and before other local headers
- `SortIncludes: Never` is in effect — do NOT reorder existing includes

#### `CameraMove.cpp` Direct GL Calls

`CameraMove.cpp` contains:
- Line ~486: `glDisable(GL_DEPTH_TEST);` — inside the skybox rendering path
- Line ~517: `glEnable(GL_DEPTH_TEST);` — restoring depth test after skybox

These two calls bypass the `ZzzOpenglUtil.cpp` depth test state machine entirely (they don't update `DepthTestEnable`). After migration, replacing with `DisableDepthTest()`/`EnableDepthTest()` brings them into the state machine — which is the correct behavior and may even fix a latent bug where the `DepthTestEnable` flag was out of sync after skybox rendering.

### Project Structure Notes

- `ZzzOpenglUtil.h` is already included widely via `stdafx.h` — no include chain changes needed for callers
- `MuRenderer.h` must be included in `ZzzOpenglUtil.cpp` and `GMBattleCastle.cpp` explicitly
- `MuRenderer.h` uses `#include <cstdint>` and `#include <span>` — both available in C++20; no new dependencies
- Test file pattern: `tests/render/test_blendpipelinestate_migration.cpp` — matches the established pattern from stories 4.2.2–4.2.4
- File count baseline: 727 files (post-4.2.4) + 1 new test file = 728 files expected after this story

### Previous Story Intelligence (from Story 4.2.4)

- `PackABGR` static inline helper established in `ZzzBMD.cpp` (story 4.2.3) — not needed here (no vertex data migration)
- `mu::GetRenderer()` accessor pattern: use `mu::GetRenderer().MethodName(args)` — established across 4.2.2–4.2.4
- Test mock pattern: define `MockRenderer : public mu::IMuRenderer` inline in the test file; implement all pure virtuals; verify by capturing call args into member fields
- `tests/CMakeLists.txt` pattern: `target_sources(MuTests PRIVATE render/test_NAME.cpp)` — add within `BUILD_TESTING` guard block with story comment
- `RenderQuadStrip` already emits per-vertex color via ABGR unpack (confirmed in story 4.2.4 — see `MuRenderer.cpp` lines ~124–138)

### Technical Implementation

**Blend mode mapping table (for implementation reference):**

| ZzzOpenglUtil function | AlphaBlendType | GL Factors | BlendMode enum |
|---|---|---|---|
| `EnableLightMap()` | 1 | GL_ZERO, GL_SRC_COLOR | `BlendMode::LightMap` |
| `EnableAlphaTest()` | 2 | GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA | `BlendMode::Alpha` |
| `EnableAlphaBlend()` | 3 | GL_ONE, GL_ONE | `BlendMode::Glow` (NEW) |
| `EnableAlphaBlendMinus()` | 4 | GL_ZERO, GL_ONE_MINUS_SRC_COLOR | `BlendMode::Subtract` |
| `EnableAlphaBlend2()` | 5 | GL_ONE_MINUS_SRC_COLOR, GL_ONE | `BlendMode::Luminance` (NEW) |
| `EnableAlphaBlend3()` | 6 | GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA | `BlendMode::Alpha` (same as Alpha) |
| `EnableAlphaBlend4()` | 7 | GL_ONE, GL_ONE_MINUS_SRC_COLOR | `BlendMode::Mixed` |
| `DisableAlphaBlend()` | 0 | (disable blend) | `DisableBlend()` (NEW method) |

**FogParams population for GMBattleCastle (for reference):**
```cpp
// GMBattleCastle.cpp — before (lines ~590–593):
glFogfv(GL_FOG_COLOR, Color);
glFogf(GL_FOG_MODE, GL_LINEAR);
glFogf(GL_FOG_START, 2000.f);
glFogf(GL_FOG_END, 2700.f);

// After:
mu::FogParams fogParams{};
fogParams.mode    = GL_LINEAR;
fogParams.start   = 2000.f;
fogParams.end     = 2700.f;
fogParams.density = 0.f;
fogParams.color[0] = Color[0];
fogParams.color[1] = Color[1];
fogParams.color[2] = Color[2];
fogParams.color[3] = Color[3];
mu::GetRenderer().SetFog(fogParams);
```

**MuRenderer.h BlendMode extension (for reference):**
```cpp
enum class BlendMode : std::uint8_t
{
    Alpha,        // GL_SRC_ALPHA,          GL_ONE_MINUS_SRC_ALPHA
    Additive,     // GL_SRC_ALPHA,          GL_ONE
    Subtract,     // GL_ZERO,               GL_ONE_MINUS_SRC_COLOR
    InverseColor, // GL_ONE_MINUS_DST_COLOR, GL_ZERO
    Mixed,        // GL_ONE,                GL_ONE_MINUS_SRC_ALPHA
    LightMap,     // GL_ZERO,               GL_SRC_COLOR
    Glow,         // GL_ONE,                GL_ONE             (NEW — Story 4.2.5)
    Luminance,    // GL_ONE_MINUS_SRC_COLOR, GL_ONE            (NEW — Story 4.2.5)
};
```

**IMuRenderer DisableBlend addition (for reference):**
```cpp
// Disable alpha blending entirely (glDisable(GL_BLEND) path).
virtual void DisableBlend() = 0;
```

### PCC Project Constraints

- **Prohibited libraries:** None specifically prohibited beyond Win32 APIs — see banned API table in `docs/development-standards.md`
- **Required patterns:** `mu::` namespace for new renderer helpers; `#pragma once` headers; `std::unique_ptr` for owned resources (not applicable here); `[[nodiscard]]` on new fallible functions; `g_ErrorReport.Write()` for diagnostics
- **No `#ifdef _WIN32`** in game logic files — platform guards belong only in `PlatformCompat.h` and `PlatformTypes.h`
- **No exceptions in game loop** — the blend/fog migration does not introduce exception-throwing code
- **Logging:** Any new error paths use `g_ErrorReport.Write(L"RENDER: MuRenderer::{function} -- {context}")`
- **References:** `docs/project-context.md`, `docs/development-standards.md`, `docs/architecture-rendering.md`

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

PCC create-story workflow completed — SAFe metadata and AC-STD-* sections included. Story type: infrastructure. No frontend/UI work. No API contracts. Corpus not available (no specification-index.yaml). Story partials not available. Blend mode mapping table derived from direct analysis of `ZzzOpenglUtil.cpp` lines 376–566 vs. `MuRenderer.h` BlendMode enum.

### File List

Files to CREATE:
- `MuMain/tests/render/test_blendpipelinestate_migration.cpp` (new Catch2 test file)

Files to MODIFY:
- `MuMain/src/source/RenderFX/MuRenderer.h` (add `Glow`, `Luminance` to BlendMode enum; add `DisableBlend()` to IMuRenderer)
- `MuMain/src/source/RenderFX/MuRenderer.cpp` (add `Glow`, `Luminance` cases to SetBlendMode; implement `DisableBlend()`)
- `MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp` (wrap 7 blend helpers + 2 depth helpers to delegate to `mu::GetRenderer()`)
- `MuMain/src/source/World/Maps/GMBattleCastle.cpp` (migrate 4 glFog* calls to `mu::GetRenderer().SetFog()`)
- `MuMain/src/source/Core/CameraMove.cpp` (replace 2 direct `glEnable/glDisable(GL_DEPTH_TEST)` with `EnableDepthTest()`/`DisableDepthTest()`)
- `MuMain/tests/CMakeLists.txt` (add `target_sources` for new test file)
