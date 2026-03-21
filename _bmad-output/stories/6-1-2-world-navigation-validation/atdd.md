# ATDD Checklist: Story 6.1.2 — World Navigation Validation

**Story ID:** 6-1-2-world-navigation-validation
**Story Type:** infrastructure
**Date Generated:** 2026-03-21
**Workflow:** testarch-atdd v1.1

---

## FSM State

```
STATE_0_STORY_CREATED → [testarch-atdd] → STATE_1_ATDD_READY
```

**Status:** ATDD_READY

---

## Test Levels Selected

| Test Level | Include? | Rationale |
|------------|----------|-----------|
| Unit (Catch2) | YES | Infrastructure story — logic testable without server |
| Integration | NO | Server-dependent (Risk R17) |
| E2E (Playwright) | NO | Not a frontend_feature story |
| Bruno API | NO | Not a backend_api story; no REST endpoints |

---

## Step 0.5: Existing Test Mapping

**Existing test files searched:** `MuMain/tests/world/` — no files found (new directory).

**Result:** No pre-existing tests. All ACs require new tests.

| AC | Description | Existing Test | Action |
|----|-------------|---------------|--------|
| AC-1 | Character movement (pathfinding) | None | GENERATE NEW |
| AC-2 | Map transitions (portals, warps) | None | GENERATE NEW |
| AC-3 | Map rendering (terrain, objects, NPCs) | None | Manual only |
| AC-4 | Minimap display | None | Manual only |
| AC-5 | Key maps: Lorencia, Devias, Noria, Dungeon, Lost Tower, Atlans | None | GENERATE NEW |
| AC-STD-2 | Testing Requirements | None | GENERATE NEW |
| AC-VAL-6 | Test scenarios document | None | GENERATE NEW |

---

## AC-to-Test Mapping

| AC | Test Method(s) | Test File | Status |
|----|---------------|-----------|--------|
| AC-1 | `PATH CheckXYPos enforces map grid boundaries` | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-1 | `PATH GetIndex maps 2D coordinates to flat array index` | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-1 | `PATH EstimateCostToGoal heuristic properties` | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-1 | `MovePoint maps all 8 EPathDirection values to correct coordinate deltas` | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-1 | `PATH FindPath A* navigation` (SKIP — needs MUGame) | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-2 | `MOVEINFODATA index equality operator matches gate by index` | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-2 | `MOVEINFODATA _bCanMove flag is default-constructible and distinguishes gate states` | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-2 | `TW_* terrain attribute flags are distinct non-overlapping bitmasks` | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-2 | `CMapManager map range queries` (SKIP — needs MUGame) | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-2 | `CPortalMgr portal state save/restore` (SKIP — needs MUGame) | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-3 | Manual rendering validation | `_bmad-output/test-scenarios/epic-6/world-navigation-validation.md` | `[ ]` |
| AC-4 | Manual minimap validation | `_bmad-output/test-scenarios/epic-6/world-navigation-validation.md` | `[ ]` |
| AC-5 | `ENUM_WORLD defines correct IDs for the 6 key game maps` | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-5 | `ENUM_WORLD covers 82+ game world map slots` | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-5 | `ENUM_WORLD event map ranges use correct base IDs` | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-STD-2 | All Catch2 tests in test file | `tests/world/test_world_navigation_validation.cpp` | `[x]` |
| AC-VAL-6 | Test scenarios document created | `_bmad-output/test-scenarios/epic-6/world-navigation-validation.md` | `[x]` |

---

## Implementation Checklist

### Phase 1: Test Infrastructure

- [x] Test file created at `MuMain/tests/world/test_world_navigation_validation.cpp`
- [x] Test file registered in `MuMain/tests/CMakeLists.txt` via `target_sources(MuTests PRIVATE world/test_world_navigation_validation.cpp)`
- [x] Test scenarios document created at `_bmad-output/test-scenarios/epic-6/world-navigation-validation.md`
- [x] No additional `target_include_directories` needed (MUCommon INTERFACE provides `World/`, `Data/`, `Core/`)

### Phase 2: Catch2 Tests — AC-5 (ENUM_WORLD Map IDs)

- [x] `AC-5 [6-1-2]: ENUM_WORLD defines correct IDs for the 6 key game maps` — 6 SECTION blocks for Lorencia/Dungeon/Devias/Noria/Lost Tower/Atlans
- [x] `AC-5 [6-1-2]: ENUM_WORLD covers 82+ game world map slots` — `NUM_WD >= 82`
- [x] `AC-5 [6-1-2]: ENUM_WORLD event map ranges use correct base IDs` — Blood Castle, Chaos Castle, Karutan, Hellas ranges

### Phase 3: Catch2 Tests — AC-1 (PATH Grid Geometry)

- [x] `AC-1 [6-1-2]: PATH CheckXYPos enforces map grid boundaries` — 7 SECTION blocks (in-bounds, out-of-bounds)
- [x] `AC-1 [6-1-2]: PATH GetIndex maps 2D coordinates to flat array index` — 4 SECTION blocks (origin, row, column, general)
- [x] `AC-1 [6-1-2]: PATH EstimateCostToGoal heuristic properties` — 4 SECTION blocks (zero, positive, monotone, symmetric)
- [x] `AC-1 [6-1-2]: MovePoint maps all 8 EPathDirection values to correct coordinate deltas` — 8 SECTION blocks (all directions)

### Phase 4: Catch2 Tests — AC-2 (Map Transitions, Terrain Flags)

- [x] `AC-2 [6-1-2]: MOVEINFODATA index equality operator matches gate by index` — 3 SECTION blocks
- [x] `AC-2 [6-1-2]: MOVEINFODATA _bCanMove flag is default-constructible and distinguishes gate states` — 3 SECTION blocks (default false, distinguishable, independent of index)
- [x] `AC-2 [6-1-2]: TW_* terrain attribute flags are distinct non-overlapping bitmasks` — 6 SECTION blocks

### Phase 5: SKIP Stubs (MUGame-linked tests)

- [x] SKIP stub: `AC-2 [6-1-2]: CMapManager map range queries` — documents MUGame linkage requirement
- [x] SKIP stub: `AC-2 [6-1-2]: CPortalMgr portal state save/restore` — documents MUGame linkage requirement
- [x] SKIP stub: `AC-1 [6-1-2]: PATH FindPath A* navigation` — documents s_iDir/MUGame linkage requirement

### Phase 6: Quality Gate

- [x] `./ctl check` passes with 0 clang-format violations on `test_world_navigation_validation.cpp`
- [x] `./ctl check` passes with 0 cppcheck errors on `test_world_navigation_validation.cpp`
- [x] No prohibited libraries used (no Win32 API calls, no mocking frameworks)
- [x] All new code follows PCC naming conventions (Allman braces, 4-space indent, 120-col limit)

### Phase 7: PCC Compliance

- [x] No prohibited libraries from project-context.md
- [x] Required testing patterns used: Catch2 v3.7.1, `TEST_CASE`/`SECTION`/`REQUIRE`/`CHECK`
- [x] No mocking framework used (PCC prohibits mocking)
- [x] Platform-compatible includes: `#ifdef _WIN32 / PlatformTypes.h` pattern used
- [x] No Win32 API calls in test logic
- [x] Test organization follows `tests/{module}/test_{name}.cpp` pattern

### Phase 8: Manual Validation Documentation

- [x] AC-VAL-6: Test scenarios documented in `_bmad-output/test-scenarios/epic-6/world-navigation-validation.md`
- [x] Scenarios cover all 5 ACs (movement, portals, rendering, minimap, key maps)
- [x] Risk R17 (server dependency) noted and manual validation paths defined
- [x] Evidence requirements specified per scenario

---

## Test Files Created

| File | Type | Phase |
|------|------|-------|
| `MuMain/tests/world/test_world_navigation_validation.cpp` | Catch2 unit tests | RED |
| `_bmad-output/test-scenarios/epic-6/world-navigation-validation.md` | Manual test scenarios | Documentation |

---

## Data Infrastructure

**Fixtures required:** None — tests use stack-allocated WORD arrays for PATH grid setup.

**External data required:**
- `ENUM_WORLD` enum values (from `MapManager.h` — already in repository)
- `TW_*` terrain flags (from `mu_define.h` — already in repository)
- `MOVEINFODATA` struct (from `MoveCommandData.h` — already in repository)

---

## PCC Compliance Summary

| Category | Status | Details |
|----------|--------|---------|
| Prohibited libraries | PASS | No mocking, no Cypress, no banned Win32 |
| Required patterns | PASS | Catch2 v3.7.1, TEST_CASE/SECTION/REQUIRE |
| Test profiles | N/A | No database/server required for automated tests |
| Coverage target | Baseline | Coverage threshold = 0 (growing incrementally per project-context.md) |
| Platform compatibility | PASS | #ifdef _WIN32 / PlatformTypes.h pattern used |
| Quality gate | PASS | `./ctl check` passed — 0 clang-format violations, 0 cppcheck errors |

---

## Output Summary

| Field | Value |
|-------|-------|
| Story ID | 6-1-2-world-navigation-validation |
| Story Type | infrastructure |
| Primary test level | Unit (Catch2) |
| Automated tests created | 13 TEST_CASEs (10 always-compiled, 3 SKIP stubs) |
| Manual test scenarios | 5 scenarios in test-scenarios doc |
| Bruno API tests | N/A (not an API story) |
| E2E tests | N/A (not a frontend_feature story) |
| Output file | `_bmad-output/stories/6-1-2-world-navigation-validation/atdd.md` |
