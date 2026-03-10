# ATDD Checklist — Story 4.2.5: Migrate Blend & Pipeline State to MuRenderer

**Story Key:** 4-2-5-migrate-blend-pipeline-state
**Story Type:** infrastructure
**Flow Code:** VS1-RENDER-MIGRATE-STATE
**Date Generated:** 2026-03-10
**ATDD Phase:** RED — tests created, awaiting implementation

---

## AC-to-Test Mapping

| AC | Description | Test Method | File | Status |
|----|-------------|-------------|------|--------|
| AC-STD-2(a) | SetBlendMode routing — all 7 blend helper mappings | `TEST_CASE("AC-STD-2 [4-2-5]: SetBlendMode — blend helper mapping to BlendMode enum")` | `tests/render/test_blendpipelinestate_migration.cpp` | `[ ]` |
| AC-STD-2(a) | EnableLightMap → BlendMode::LightMap | SECTION "EnableLightMap maps to BlendMode::LightMap" | same | `[ ]` |
| AC-STD-2(a) | EnableAlphaTest → BlendMode::Alpha | SECTION "EnableAlphaTest maps to BlendMode::Alpha" | same | `[ ]` |
| AC-STD-2(a) | EnableAlphaBlend → BlendMode::Glow (NEW) | SECTION "EnableAlphaBlend maps to BlendMode::Glow" | same | `[ ]` |
| AC-STD-2(a) | EnableAlphaBlendMinus → BlendMode::Subtract | SECTION "EnableAlphaBlendMinus maps to BlendMode::Subtract" | same | `[ ]` |
| AC-STD-2(a) | EnableAlphaBlend2 → BlendMode::Luminance (NEW) | SECTION "EnableAlphaBlend2 maps to BlendMode::Luminance" | same | `[ ]` |
| AC-STD-2(a) | EnableAlphaBlend3 → BlendMode::Alpha | SECTION "EnableAlphaBlend3 maps to BlendMode::Alpha" | same | `[ ]` |
| AC-STD-2(a) | EnableAlphaBlend4 → BlendMode::Mixed | SECTION "EnableAlphaBlend4 maps to BlendMode::Mixed" | same | `[ ]` |
| AC-STD-2(a) | DisableAlphaBlend → DisableBlend() (NEW) | SECTION "DisableAlphaBlend maps to DisableBlend()" | same | `[ ]` |
| AC-STD-2(a) | All 7 modes round-trip without bleed | SECTION "All 7 blend modes can be round-tripped" | same | `[ ]` |
| AC-STD-2(b) | SetDepthTest — enable path | `TEST_CASE("AC-STD-2 [4-2-5]: SetDepthTest — enable and disable paths")` SECTION enable | same | `[ ]` |
| AC-STD-2(b) | SetDepthTest — disable path | SECTION disable | same | `[ ]` |
| AC-STD-2(b) | Enable then disable transitions | SECTION "Enable then disable" | same | `[ ]` |
| AC-STD-2(b) | Independent of blend mode state | SECTION "does not affect blend mode state" | same | `[ ]` |
| AC-STD-2(c) | SetFog — GL_LINEAR params (GMBattleCastle) | `TEST_CASE("AC-STD-2 [4-2-5]: SetFog — GL_LINEAR params population")` | same | `[ ]` |
| AC-STD-2(c) | FogParams zero-initialization | SECTION "FogParams zero-initialization" | same | `[ ]` |
| AC-STD-2(c) | SetFog independent of blend/depth state | SECTION "does not affect blend mode or depth test state" | same | `[ ]` |
| AC-VAL-1 | Full blend sequence: all 7 helpers + DisableBlend | `TEST_CASE("AC-VAL-1 [4-2-5]: Full blend state sequence")` | same | `[ ]` |
| AC-VAL-1 | DisableBlend separate from SetBlendMode | SECTION "DisableBlend is separate from SetBlendMode" | same | `[ ]` |

---

## Implementation Checklist

### Task 2: Extend BlendMode Enum + DisableBlend (MuRenderer.h / MuRenderer.cpp)

- [ ] `BlendMode::Glow` added to `enum class BlendMode` in `MuMain/src/source/RenderFX/MuRenderer.h` (GL_ONE, GL_ONE)
- [ ] `BlendMode::Luminance` added to `enum class BlendMode` in `MuMain/src/source/RenderFX/MuRenderer.h` (GL_ONE_MINUS_SRC_COLOR, GL_ONE)
- [ ] `virtual void DisableBlend() = 0;` added to `IMuRenderer` interface in `MuRenderer.h`
- [ ] `case BlendMode::Glow:` added to `MuRendererGL::SetBlendMode()` in `MuRenderer.cpp`
- [ ] `case BlendMode::Luminance:` added to `MuRendererGL::SetBlendMode()` in `MuRenderer.cpp`
- [ ] `MuRendererGL::DisableBlend()` implemented as `glDisable(GL_BLEND)` in `MuRenderer.cpp`
- [ ] Commit: `feat(render): extend BlendMode enum with Glow/Luminance/DisableBlend for full state coverage`

### Task 3: Wrap Blend Helpers in ZzzOpenglUtil.cpp

- [ ] `EnableLightMap()` modified to call `mu::GetRenderer().SetBlendMode(mu::BlendMode::LightMap)` — guard preserved
- [ ] `DisableAlphaBlend()` modified to call `mu::GetRenderer().DisableBlend()` — guard preserved
- [ ] `EnableAlphaBlend()` modified to call `mu::GetRenderer().SetBlendMode(mu::BlendMode::Glow)`
- [ ] `EnableAlphaBlendMinus()` modified to call `mu::GetRenderer().SetBlendMode(mu::BlendMode::Subtract)`
- [ ] `EnableAlphaBlend2()` modified to call `mu::GetRenderer().SetBlendMode(mu::BlendMode::Luminance)`
- [ ] `EnableAlphaBlend3()` modified to call `mu::GetRenderer().SetBlendMode(mu::BlendMode::Alpha)`
- [ ] `EnableAlphaBlend4()` modified to call `mu::GetRenderer().SetBlendMode(mu::BlendMode::Mixed)`
- [ ] `#include "MuRenderer.h"` added to `ZzzOpenglUtil.cpp` (after stdafx.h, before other local headers)
- [ ] Commit: `refactor(render): wrap blend-state helpers to delegate to MuRenderer::SetBlendMode`

### Task 4: Wrap Depth Test Helpers + Fix CameraMove.cpp

- [ ] `EnableDepthTest()` in `ZzzOpenglUtil.cpp` calls `mu::GetRenderer().SetDepthTest(true)` — guard preserved
- [ ] `DisableDepthTest()` in `ZzzOpenglUtil.cpp` calls `mu::GetRenderer().SetDepthTest(false)` — guard preserved
- [ ] `CameraMove.cpp` line ~486: `glDisable(GL_DEPTH_TEST)` replaced with `DisableDepthTest()`
- [ ] `CameraMove.cpp` line ~517: `glEnable(GL_DEPTH_TEST)` replaced with `EnableDepthTest()`
- [ ] `CameraMove.cpp` include of `ZzzOpenglUtil.h` verified (via stdafx.h or direct)
- [ ] Commit: `refactor(render): wrap depth test helpers to delegate to MuRenderer::SetDepthTest`

### Task 5: Migrate Fog Setup in GMBattleCastle.cpp

- [ ] `GMBattleCastle.cpp` lines ~590–593: four `glFog*` calls replaced with `mu::FogParams` + `mu::GetRenderer().SetFog(fogParams)` exactly as specified in story dev notes
- [ ] `#include "MuRenderer.h"` added to `GMBattleCastle.cpp` if not already present
- [ ] Preceding `glEnable(GL_FOG)` removed if it existed (MuRendererGL::SetFog calls glEnable internally)
- [ ] Commit: `refactor(render): migrate fog setup in GMBattleCastle to MuRenderer::SetFog`

### Task 6: Catch2 Test File

- [ ] `MuMain/tests/render/test_blendpipelinestate_migration.cpp` created (RED phase — done)
- [ ] `target_sources(MuTests PRIVATE render/test_blendpipelinestate_migration.cpp)` added in `MuMain/tests/CMakeLists.txt` (done)
- [ ] Tests compile on macOS/Linux (no gl* calls in test TU)
- [ ] Tests fail (RED) until Tasks 2–5 are implemented
- [ ] Tests pass (GREEN) after Tasks 2–5 are implemented

### Task 7: Quality Gate + Grep Verification

- [ ] `./ctl check` passes with 0 errors after all tasks applied
- [ ] Grep confirms no direct `glBlendFunc`, `glEnable(GL_BLEND)`, `glDisable(GL_BLEND)`, `glFogi`, `glFogf\b` calls outside `MuRenderer.cpp` and `ZzzOpenglUtil.cpp`
- [ ] File count: 727 (post-4.2.4 baseline) + 1 new test file = 728 files

### PCC Compliance Verification

- [ ] No prohibited libraries used — Catch2 3.7.1 is the approved testing framework
- [ ] All new code uses `mu::` namespace for renderer helpers
- [ ] `#pragma once` in all new/modified headers (no `#ifndef` guards)
- [ ] No raw `new`/`delete` — no heap allocations introduced
- [ ] `[[nodiscard]]` not applicable (no new fallible functions with return values)
- [ ] No `#ifdef _WIN32` in game logic files — changes in `ZzzOpenglUtil.cpp`, `GMBattleCastle.cpp`, `CameraMove.cpp` only
- [ ] No `NULL` (use `nullptr`) — not applicable (no pointer changes)
- [ ] No `wprintf` — not applicable
- [ ] Error logging: existing `g_ErrorReport.Write()` guards already in `MuRenderer.cpp` from story 4.2.1
- [ ] Conventional commits: `refactor(render):` and `feat(render):` prefixes used per AC-STD-6

### Standard AC Compliance

- [ ] AC-STD-1: Code Standards Compliance — `mu::` namespace, PascalCase, `m_` prefix, `#pragma once`, no raw `new`/`delete`, `[[nodiscard]]` on new fallible functions, no `NULL`, no `wprintf`, no `#ifdef _WIN32` in game logic
- [ ] AC-STD-4: CI quality gate passes (`./ctl check` — 0 errors)
- [ ] AC-STD-13: Quality gate passes; file count = 728 (727 + 1 new test file)
- [ ] AC-STD-15: Git safety (no incomplete rebase, no force push)
- [ ] AC-STD-16: Correct test infrastructure used (Catch2 3.7.1, `MuTests` target, `tests/render/` directory, `target_sources` in `tests/CMakeLists.txt`)

---

## Validation ACs Deferred

- [ ] **AC-VAL-3:** Windows render validation (SSIM > 0.99) — manual validation only; automated SSIM deferred to story 4.4.1 ground truth gate (explicitly stated in story)
- [ ] **AC-VAL-4:** Grep verification — to be run as part of Task 7

---

## Test File Locations

| File | Status |
|------|--------|
| `MuMain/tests/render/test_blendpipelinestate_migration.cpp` | Created (RED phase) |

---

## PCC Compliance Summary

| Check | Status |
|-------|--------|
| Prohibited libraries | None used |
| Required testing framework | Catch2 3.7.1 (MuTests target) |
| Test profiles | No special profiles needed (pure logic tests) |
| Playwright (E2E) | N/A — infrastructure story |
| Bruno (API) | N/A — infrastructure story |
| Coverage target | Incremental (0 threshold, growing) |
| No gl* calls in test TU | Verified |
| macOS/Linux runnable | Verified |

---

## Handoff to dev-story

- **atdd_checklist_path:** `_bmad-output/stories/4-2-5-migrate-blend-pipeline-state/atdd.md`
- **test_files_created:** `MuMain/tests/render/test_blendpipelinestate_migration.cpp`
- **implementation_checklist_complete:** TRUE (all items `[ ]` — ready for implementation)
- **ac_test_mapping:**
  - AC-STD-2(a) → `TEST_CASE("AC-STD-2 [4-2-5]: SetBlendMode — blend helper mapping to BlendMode enum")`
  - AC-STD-2(b) → `TEST_CASE("AC-STD-2 [4-2-5]: SetDepthTest — enable and disable paths")`
  - AC-STD-2(c) → `TEST_CASE("AC-STD-2 [4-2-5]: SetFog — GL_LINEAR params population")`
  - AC-VAL-1 → `TEST_CASE("AC-VAL-1 [4-2-5]: Full blend state sequence — all 7 helper mappings verified")`
