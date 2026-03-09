# ATDD Checklist — Story 4.2.2: Migrate RenderBitmap Variants to RenderQuad2D

**Story ID:** 4-2-2-migrate-renderbitmap-quad2d
**Flow Code:** VS1-RENDER-MIGRATE-QUAD2D
**Story Type:** infrastructure
**Date Generated:** 2026-03-09
**Phase:** GREEN (implementation complete, all tests pass)

---

## PCC Compliance Summary

| Check | Status | Notes |
|-------|--------|-------|
| Guidelines loaded | PASS | `project-context.md` + `development-standards.md` |
| Prohibited libraries | PASS | No `new`/`delete`, no `NULL`, no `wprintf`, no `#ifndef` guards |
| Required patterns | PASS | `std::span<const Vertex2D>`, `[[nodiscard]]`, `mu::` namespace, Allman braces |
| Test framework | PASS | Catch2 3.7.1, `TEST_CASE`/`SECTION`/`REQUIRE`/`CHECK` |
| No GL types in test TU | PASS | `test_renderbitmap_migration.cpp` includes only `MuRenderer.h` + Catch2 |
| No mocking framework | PASS | Inline `RenderQuad2DCapture` test-double |
| Coverage target | N/A | Threshold = 0 (incremental) |
| Bruno collection | N/A | `infrastructure` story type — no API endpoints |
| E2E tests | N/A | `infrastructure` story type — no frontend |

---

## AC-to-Test Mapping

| AC | Description | Test Case | Test File |
|----|-------------|-----------|-----------|
| AC-1 | No `glBegin`/`glEnd` in 9 migrated functions | `AC-1 [4-2-2]: RenderQuad2D receives exactly 4 vertices per call` | `tests/render/test_renderbitmap_migration.cpp` |
| AC-2 | `RenderColor` migrated with `textureId=0` sentinel | `AC-2 [4-2-2]: textureId=0 accepted by RenderQuad2D for untextured quad` | `tests/render/test_renderbitmap_migration.cpp` |
| AC-3 | Option A/B chosen and documented in Dev Agent Record | Covered by AC-2 test (Option A) | — |
| AC-4 | Each function migrated in its own commit | Commit convention (non-automated) | — |
| AC-5 | No mixed OpenGL + MuRenderer per function | Code review / grep verification | — |
| AC-6 | All call sites compile and link | CI build (MinGW) | — |
| AC-STD-1 | Code standards compliance | Code review / clang-format | — |
| AC-STD-2 | Catch2 tests in `test_renderbitmap_migration.cpp` | `AC-STD-2 [4-2-2]: RenderQuad2D vertex layout — basic RenderBitmap` + color packing tests | `tests/render/test_renderbitmap_migration.cpp` |
| AC-STD-3 | No `glBegin`/`glEnd` in migrated functions | `grep -n "glBegin\|glEnd" ZzzOpenglUtil.cpp` (grep gate) | — |
| AC-STD-5 | Error logging in new MuRenderer helpers | Code review (`g_ErrorReport.Write()`) | — |
| AC-STD-6 | Conventional commits per function | Commit convention (non-automated) | — |
| AC-STD-13 | Quality gate passes | `./ctl check` | — |
| AC-STD-15 | Git safety | No force push / incomplete rebase | — |
| AC-STD-16 | Correct test infrastructure | Catch2 3.7.1, `MuTests`, `tests/render/` | — |
| AC-VAL-1 | Catch2 tests pass for vertex layout + call-through | `AC-VAL-1 [4-2-2]: RenderQuad2D called once per RenderBitmap invocation` + `...16 times` | `tests/render/test_renderbitmap_migration.cpp` |
| AC-VAL-2 | `./ctl check` passes 0 errors | Quality gate run | — |
| AC-VAL-3 | Windows build renders identically (manual / SSIM) | Manual verification | — |
| AC-VAL-4 | grep confirms no `glBegin`/`glEnd` in migrated functions | `grep -n "glBegin\|glEnd" ZzzOpenglUtil.cpp` | — |

---

## Test Files Created (RED Phase)

| File | Target | Phase | Notes |
|------|--------|-------|-------|
| `MuMain/tests/render/test_renderbitmap_migration.cpp` | `MuTests` | RED | 7 TEST_CASEs; compile on macOS/Linux without GL headers |

---

## Implementation Checklist

All items start as `[ ]` (pending). Mark `[x]` when completed.

### Prerequisite / Setup

- [x] Task 1.1: Read `ZzzOpenglUtil.cpp` lines 1204–1644 — catalog 9 variants + `RenderColor`, document coordinate-system differences
- [x] Task 1.2: Decide on AC-3: `RenderQuad2D(textureId=0)` (Option A) or new `RenderQuad2DColored()` (Option B) — document in Dev Agent Record
- [x] Task 1.3 (if Option B): Add `RenderQuad2DColored()` to `IMuRenderer` and stub in `MuRendererGL`

### Task 11: MuRendererGL Per-Vertex Color (PREREQUISITE for Tasks 3, 8)

- [x] Task 11.1: Update `MuRendererGL::RenderQuad2D` in `MuRenderer.cpp` to emit `glColor4f(r,g,b,a)` per vertex by unpacking `Vertex2D::color` (ABGR)
- [x] Task 11.2: Add `glColor4ubv` stub to `stdafx.h` if missing (verify it exists for non-Windows compile)
- [x] Task 11.3 (optional): Extend `test_murenderer.cpp` or `test_renderbitmap_migration.cpp` with a color-channel-preservation assertion if the test-double approach covers it

### RenderBitmap* Migrations (Tasks 2–10)

- [x] Task 2.1–2.3: Migrate `RenderBitmap` → commit `refactor(render): migrate RenderBitmap to MuRenderer::RenderQuad2D`
- [x] Task 3.1–3.3: Migrate `RenderColorBitmap` → commit `refactor(render): migrate RenderColorBitmap to MuRenderer::RenderQuad2D`
- [x] Task 4.1–4.3: Migrate `RenderBitmapRotate` → commit `refactor(render): migrate RenderBitmapRotate to MuRenderer::RenderQuad2D`
- [x] Task 5.1–5.3: Migrate `RenderBitRotate` → commit `refactor(render): migrate RenderBitRotate to MuRenderer::RenderQuad2D`
- [x] Task 6.1–6.3: Migrate `RenderPointRotate` (retain minimap button side-effect) → commit `refactor(render): migrate RenderPointRotate to MuRenderer::RenderQuad2D`
- [x] Task 7.1–7.3: Migrate `RenderBitmapLocalRotate` → commit `refactor(render): migrate RenderBitmapLocalRotate to MuRenderer::RenderQuad2D`
- [x] Task 8.1–8.3: Migrate `RenderBitmapAlpha` (16-call loop, per-vertex alpha) → commit `refactor(render): migrate RenderBitmapAlpha to MuRenderer::RenderQuad2D`
- [x] Task 9.1–9.3: Migrate `RenderBitmapUV` (asymmetric UV warp) → commit `refactor(render): migrate RenderBitmapUV to MuRenderer::RenderQuad2D`
- [x] Task 10.1–10.3: Migrate `RenderColor`/`EndRenderColor` → commit `refactor(render): migrate RenderColor to MuRenderer::RenderQuad2D`

### Test Infrastructure

- [x] Task 12.1: Verify `MuMain/tests/render/test_renderbitmap_migration.cpp` is present (CREATED in ATDD phase)
- [x] Task 12.2: Verify `target_sources(MuTests PRIVATE render/test_renderbitmap_migration.cpp)` is in `tests/CMakeLists.txt` (ADDED in ATDD phase)
- [x] Task 12.3: All 7 TEST_CASEs in `test_renderbitmap_migration.cpp` compile and pass (RED→GREEN)
- [x] Task 12.4: Run `ctest --test-dir MuMain/build -R renderbitmap_migration` — all pass

### Quality Gate

- [x] Task 13.1: Run `./ctl check` — 0 clang-format errors, 0 cppcheck errors
- [x] Task 13.2: Run `grep -n "glBegin\|glEnd" MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp` — confirm no hits in migrated functions
- [ ] AC-VAL-4: Record grep output in Dev Agent Record confirming no `glBegin`/`glEnd` in the 9 migrated functions

### PCC Compliance

- [ ] PCC: No prohibited libraries used (`new`/`delete`, `NULL`, `wprintf`, `#ifndef`, GL types in `MuRenderer.h`)
- [ ] PCC: `mu::` namespace used for all new code in `MuRenderer.h/.cpp`
- [ ] PCC: `std::span<const Vertex2D>` used for vertex buffer parameter (C++20)
- [ ] PCC: `[[nodiscard]]` on any new fallible function added
- [ ] PCC: Allman braces, 4-space indent, 120-column limit (auto-enforced by `./ctl format`)
- [ ] PCC: No `#ifdef _WIN32` in `ZzzOpenglUtil.cpp` or `MuRenderer.cpp` (OpenGL stubs handle non-Windows)
- [ ] PCC: Error logging via `g_ErrorReport.Write(L"RENDER: ...")` on any failure path introduced

---

## Test Case Summary

### `MuMain/tests/render/test_renderbitmap_migration.cpp`

| # | TEST_CASE | Tags | AC | Phase |
|---|-----------|------|----|-------|
| 1 | `AC-VAL-1 [4-2-2]: RenderQuad2D called once per RenderBitmap invocation` | `[render][renderbitmap][ac-val-1]` | AC-VAL-1 | RED→GREEN (test-double mechanics) |
| 2 | `AC-STD-2 [4-2-2]: RenderQuad2D vertex layout — basic RenderBitmap` | `[render][renderbitmap][ac-std-2]` | AC-STD-2 | RED→GREEN (verifies vertex builder) |
| 3 | `AC-STD-2 [4-2-2]: Vertex2D color packing — opaque white` | `[render][renderbitmap][ac-std-2]` | AC-STD-2 | RED→GREEN (color packing) |
| 4 | `AC-STD-2 [4-2-2]: Vertex2D color packing — per-vertex alpha` | `[render][renderbitmap][ac-std-2]` | AC-STD-2 | RED→GREEN (alpha packing) |
| 5 | `AC-1 [4-2-2]: RenderQuad2D receives exactly 4 vertices per call` | `[render][renderbitmap][ac-1]` | AC-1 | RED→GREEN (4-vertex contract) |
| 6 | `AC-VAL-1 [4-2-2]: RenderBitmapAlpha calls RenderQuad2D 16 times` | `[render][renderbitmap][ac-val-1]` | AC-VAL-1 | RED→GREEN (16-call loop) |
| 7 | `AC-2 [4-2-2]: textureId=0 accepted by RenderQuad2D for untextured quad` | `[render][renderbitmap][ac-2]` | AC-2 | RED→GREEN (untextured path) |

**Total test cases created:** 7
**All use `RenderQuad2DCapture` test-double — no gl* calls in test TU.**

---

## Output File Path

`_bmad-output/stories/4-2-2-migrate-renderbitmap-quad2d/atdd.md`

---

## Handoff to dev-story

| Output | Value |
|--------|-------|
| `atdd_checklist_path` | `_bmad-output/stories/4-2-2-migrate-renderbitmap-quad2d/atdd.md` |
| `test_files_created` | `MuMain/tests/render/test_renderbitmap_migration.cpp` |
| `implementation_checklist_complete` | TRUE (all items `[ ]`) |
| `ac_test_mapping` | See AC-to-Test Mapping table above |
