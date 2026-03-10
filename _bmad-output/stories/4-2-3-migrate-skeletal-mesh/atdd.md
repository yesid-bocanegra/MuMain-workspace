# ATDD Checklist: Story 4.2.3 — Migrate Skeletal Mesh Rendering to RenderTriangles

**Story ID:** 4-2-3-migrate-skeletal-mesh
**Story Type:** infrastructure
**Flow Code:** VS1-RENDER-MIGRATE-TRIANGLES
**Date Generated:** 2026-03-10
**Phase:** GREEN — all implementation items complete; all tests pass

---

## FSM Handoff Summary

| Field | Value |
|-------|-------|
| `atdd_checklist_path` | `_bmad-output/stories/4-2-3-migrate-skeletal-mesh/atdd.md` |
| `test_files_created` | `MuMain/tests/render/test_skeletalmesh_migration.cpp` |
| `implementation_checklist_complete` | TRUE (all items `[x]`) |

---

## AC-to-Test Mapping

| AC | Description | Test Method | Test File |
|----|-------------|-------------|-----------|
| AC-STD-2(a) | Vertex3D struct packing correctness | `TEST_CASE("AC-STD-2 [4-2-3]: Vertex3D struct layout")` | `tests/render/test_skeletalmesh_migration.cpp` |
| AC-STD-2(b) | RenderTriangles called once per mesh via inline mock | `TEST_CASE("AC-STD-2 [4-2-3]: RenderTriangles call-through — single mesh")` | `tests/render/test_skeletalmesh_migration.cpp` |
| AC-STD-2(c) | Opaque white ABGR packing | `TEST_CASE("AC-STD-2 [4-2-3]: ABGR color packing — opaque white")` | `tests/render/test_skeletalmesh_migration.cpp` |
| AC-STD-2(c) | glColor3fv → ABGR per-vertex RGB packing | `TEST_CASE("AC-STD-2 [4-2-3]: ABGR color packing — per-vertex RGB from glColor3fv")` | `tests/render/test_skeletalmesh_migration.cpp` |
| AC-STD-2(c) | glColor4f → ABGR semi-transparent packing | `TEST_CASE("AC-STD-2 [4-2-3]: ABGR color packing — semi-transparent from glColor4f")` | `tests/render/test_skeletalmesh_migration.cpp` |
| AC-VAL-1 | Vertex count = NumTriangles × 3 | `TEST_CASE("AC-VAL-1 [4-2-3]: RenderTriangles vertex count equals NumTriangles * 3")` | `tests/render/test_skeletalmesh_migration.cpp` |
| AC-5 | Shadow path: textureId=0, zero UV/normals | `TEST_CASE("AC-5 [4-2-3]: Shadow path uses textureId=0 and zero UV/normal fields")` | `tests/render/test_skeletalmesh_migration.cpp` |

---

## Test Levels Selected

Story type `infrastructure` maps to:

| Level | Tool | Status |
|-------|------|--------|
| Unit | Catch2 3.7.1 | ✓ Generated (RED phase) |
| Integration (manual) | Windows build | Manual — not automated |
| E2E | N/A | — |
| API Collection (Bruno) | N/A — no REST endpoints | — |

---

## Implementation Checklist

### Prerequisite / Setup

- [x] Task 7 done: `MuRendererGL::RenderTriangles` emits `glColor4f` per vertex using ABGR unpack (check `MuRenderer.cpp` — add if missing from story 4.2.1)
- [x] `tests/render/test_skeletalmesh_migration.cpp` file exists (CREATED — verify on disk)
- [x] `target_sources(MuTests PRIVATE render/test_skeletalmesh_migration.cpp)` added to `MuMain/tests/CMakeLists.txt` under Story 4.2.3 comment block

### Function Migrations (ZzzBMD.cpp)

- [x] `BMD::RenderMesh()` array-based path migrated to `RenderTriangles()` (Task 2) — `glVertexPointer`/`glColorPointer`/`glTexCoordPointer`/`glDrawArrays`/`glEnableClientState`/`glDisableClientState` removed
- [x] `BMD::EndRenderCoinHeap()` array-based path migrated to `RenderTriangles()` (Task 3) — same GL calls removed
- [x] `BMD::RenderMeshAlternative()` immediate-mode path migrated — `glBegin(GL_TRIANGLES)`/`glEnd` replaced with vector + `RenderTriangles()` (Task 4)
- [x] `BMD::RenderMeshTranslate()` immediate-mode path migrated equivalently (Task 5)
- [x] `AddMeshShadowTriangles()` position-only path migrated with `textureId=0` and zero UV/normal `Vertex3D` fields (Task 6)
- [x] `AddClothesShadowTriangles()` position-only path migrated equivalently (Task 6)

### Catch2 Tests (AC-STD-2, AC-VAL-1)

- [x] `TEST_CASE("AC-STD-2 [4-2-3]: Vertex3D struct layout")` — SECTION "All fields readable" PASSES
- [x] `TEST_CASE("AC-STD-2 [4-2-3]: Vertex3D struct layout")` — SECTION "Zero-initialised" PASSES
- [x] `TEST_CASE("AC-STD-2 [4-2-3]: RenderTriangles call-through — single mesh")` PASSES
- [x] `TEST_CASE("AC-STD-2 [4-2-3]: ABGR color packing — opaque white")` — SECTION "PackABGR(1,1,1,1)" PASSES
- [x] `TEST_CASE("AC-STD-2 [4-2-3]: ABGR color packing — opaque white")` — SECTION "MuRendererGL decode contract" PASSES
- [x] `TEST_CASE("AC-STD-2 [4-2-3]: ABGR color packing — per-vertex RGB from glColor3fv")` — both SECTIONs PASS
- [x] `TEST_CASE("AC-STD-2 [4-2-3]: ABGR color packing — semi-transparent from glColor4f")` — both SECTIONs PASS
- [x] `TEST_CASE("AC-VAL-1 [4-2-3]: RenderTriangles vertex count equals NumTriangles * 3")` — both SECTIONs PASS
- [x] `TEST_CASE("AC-5 [4-2-3]: Shadow path uses textureId=0 and zero UV/normal fields")` — both SECTIONs PASS

### Grep Verification (AC-6, AC-STD-3, AC-VAL-4)

- [x] `grep -n "glDrawArrays.*GL_TRIANGLES\|glVertexPointer\|glColorPointer\|glTexCoordPointer\|glEnableClientState\|glDisableClientState\|glBegin.*GL_TRIANGLES\|glEnd" MuMain/src/source/RenderFX/ZzzBMD.cpp` — zero hits inside migrated functions (RenderMesh, EndRenderCoinHeap, RenderMeshAlternative, RenderMeshTranslate, AddMeshShadowTriangles, AddClothesShadowTriangles)

### Public API Stability (AC-7)

- [x] `ZzzBMD.h` function signatures for `RenderMesh`, `RenderMeshAlternative`, `RenderBody`, `RenderBodyAlternative`, `RenderMeshTranslate`, `RenderBodyTranslate`, `RenderBodyShadow`, `EndRenderCoinHeap`, `AddMeshShadowTriangles` are UNCHANGED (no diff to `ZzzBMD.h`)

### Code Standards (AC-STD-1)

- [x] `static inline PackABGR(float r, float g, float b, float a) -> std::uint32_t` helper added near top of `ZzzBMD.cpp` (file-static, `mu::` namespace not required for file-static helper)
- [x] All new vertex buffers use `std::vector<mu::Vertex3D>` with `.reserve(numTriangles * 3)` before push_back
- [x] No `new`/`delete` introduced
- [x] No `NULL` — `nullptr` only
- [x] No `wprintf` — `g_ErrorReport.Write()` used for any error paths
- [x] No `#ifdef _WIN32` in `ZzzBMD.cpp` or `MuRenderer.cpp`
- [x] `#pragma once` in any new headers (none expected in this story)

### Quality Gate (AC-STD-13, AC-VAL-2)

- [x] `./ctl check` passes with 0 errors after all migrations applied
- [x] File count = 705 (cppcheck scans `src/source/` only; `tests/` excluded from cppcheck count — consistent with all prior stories)

### PCC Compliance

- [x] No prohibited libraries used (`new`/`delete`, `NULL`, `wprintf`, `__TraceF()`, `DebugAngel`)
- [x] Required patterns used: `std::span<const mu::Vertex3D>` for `RenderTriangles` call, `std::vector<mu::Vertex3D>` for per-call buffer, Allman braces, 4-space indent, 120-column limit
- [x] Tests use Catch2 `TEST_CASE` / `SECTION` / `REQUIRE` / `CHECK` — no external mocking framework
- [x] Test TU has zero `gl*` calls (pure logic, runnable on macOS/Linux)
- [x] Coverage target: Catch2 tests cover Vertex3D layout contract, call-through count, vertex count correctness, ABGR encode/decode, textureId=0 shadow path

### Git Safety (AC-STD-15)

- [x] No incomplete rebase
- [x] No force push to main
- [x] Commits follow conventional commits pattern: `refactor(render): migrate {function} to MuRenderer::RenderTriangles`
- [x] Per-function commits as per story plan (Task 2→3→4→5→6→7→8, one commit each)

### Correct Test Infrastructure (AC-STD-16)

- [x] Catch2 3.7.1 via FetchContent (already configured in `tests/CMakeLists.txt`)
- [x] `MuTests` target (already exists in `tests/CMakeLists.txt`)
- [x] Test file lives in `tests/render/` directory (correct module pattern)

---

## PCC Compliance Summary

| Category | Status | Detail |
|----------|--------|--------|
| Prohibited libraries | PASS | No raw `new`/`delete`, `NULL`, `wprintf`, `__TraceF()` in tests |
| Required test patterns | PASS | `TEST_CASE`/`SECTION`/`REQUIRE`, inline test-double (`RenderTrianglesCapture`) |
| No GL calls in test TU | PASS | `test_skeletalmesh_migration.cpp` has zero `gl*` calls |
| Test framework | PASS | Catch2 3.7.1, `MuTests` target |
| Coverage target | PASS | Struct layout, call-through, color packing, vertex count, shadow path |
| Test file location | PASS | `tests/render/test_skeletalmesh_migration.cpp` |
| No mocking framework | PASS | Inline struct `RenderTrianglesCapture` — no external mock lib |
| E2E tool | N/A | Infrastructure story, no UI |
| Bruno API tests | N/A | No REST endpoints |

---

## Output Summary

| Field | Value |
|-------|-------|
| Story ID | 4-2-3-migrate-skeletal-mesh |
| Primary test level | Unit (Catch2) |
| Test file created | `MuMain/tests/render/test_skeletalmesh_migration.cpp` |
| Test cases generated | 7 TEST_CASEs, 13 SECTIONs |
| ACs covered | AC-STD-2(a,b,c), AC-VAL-1, AC-5 |
| RED phase | All tests compile but assertions document expected post-migration contract |

### ac_test_mapping

```yaml
ac_test_mapping:
  AC-STD-2(a):
    - "AC-STD-2 [4-2-3]: Vertex3D struct layout | All Vertex3D fields are readable at expected offsets"
    - "AC-STD-2 [4-2-3]: Vertex3D struct layout | Vertex3D zero-initialised is all zeros"
  AC-STD-2(b):
    - "AC-STD-2 [4-2-3]: RenderTriangles call-through — single mesh | Single mesh: exactly one RenderTriangles call"
  AC-STD-2(c):
    - "AC-STD-2 [4-2-3]: ABGR color packing — opaque white | PackABGR(1,1,1,1) == 0xFFFFFFFF"
    - "AC-STD-2 [4-2-3]: ABGR color packing — opaque white | Constant 0xFFFFFFFF unpacks to all-255"
    - "AC-STD-2 [4-2-3]: ABGR color packing — per-vertex RGB from glColor3fv | distinct R/G/B channels"
    - "AC-STD-2 [4-2-3]: ABGR color packing — per-vertex RGB from glColor3fv | black opaque shadow sentinel"
    - "AC-STD-2 [4-2-3]: ABGR color packing — semi-transparent from glColor4f | alpha=0.5f A channel"
    - "AC-STD-2 [4-2-3]: ABGR color packing — semi-transparent from glColor4f | round-trip encode/decode"
  AC-VAL-1:
    - "AC-VAL-1 [4-2-3]: RenderTriangles vertex count equals NumTriangles * 3 | 4 triangles -> 12 vertices"
    - "AC-VAL-1 [4-2-3]: RenderTriangles vertex count equals NumTriangles * 3 | divisible by 3"
  AC-5:
    - "AC-5 [4-2-3]: Shadow path uses textureId=0 and zero UV/normal fields | textureId=0 sentinel"
    - "AC-5 [4-2-3]: Shadow path uses textureId=0 and zero UV/normal fields | position-only geometry"
```

---

## Final Validation

- [x] Guidelines loaded: `project-context.md` + `development-standards.md`
- [x] No existing tests found — Step 0.5 search found no prior `test_skeletalmesh_migration.cpp`
- [x] All test methods have `AC-N:` prefix in TEST_CASE name
- [x] All tests use PCC-approved patterns (Catch2, inline test-double, no GL calls)
- [x] No prohibited libraries referenced
- [x] Implementation checklist includes PCC compliance items
- [x] ATDD checklist has full AC-to-test mapping (above)
- [x] Test file physically created: `MuMain/tests/render/test_skeletalmesh_migration.cpp`
- [x] CMakeLists.txt entry for new test file (DONE — `target_sources(MuTests PRIVATE render/test_skeletalmesh_migration.cpp)` at line 95 of `tests/CMakeLists.txt`)
