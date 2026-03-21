# Story 6.1.2: World Navigation Validation

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 6 - Cross-Platform Gameplay Validation |
| Feature | 6.1 - Core Loop |
| Story ID | 6.1.2 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | infrastructure |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-GAME-VALIDATE-NAVIGATION |
| FRs Covered | FR23, FR24, FR25 |
| Prerequisites | 6-1-1-auth-character-validation (done) |

**Story Types:** `backend_api` | `backend_service` | `frontend_feature` | `infrastructure` | `fullstack`

### Affected Components

<!-- Which components does this story modify? List ALL affected components from .pcc-config.yaml -->
<!-- The first backend/frontend listed becomes the primary target for quality gates -->

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Add Catch2 test suite for world navigation, map loading, and movement validation |
| project-docs | documentation | Story artifacts, test scenarios, validation documentation |

---

## Story

**[VS-1] [Flow:VS1-GAME-VALIDATE-NAVIGATION]**

**As a** player on macOS/Linux,
**I want** to navigate across all 82 game maps without issues,
**so that** the full game world is accessible on any platform.

---

## Functional Acceptance Criteria

- [ ] **AC-1:** Character movement (click-to-move via A* pathfinding, keyboard) works on macOS/Linux
- [ ] **AC-2:** Map transitions (portals, warps, gate system) load correctly on all platforms
- [ ] **AC-3:** Map rendering: terrain (LOD terrain system), objects, NPCs visible on macOS/Linux
- [ ] **AC-4:** Minimap (`CNewUIMiniMap`) displays correctly with location buttons and scroll
- [ ] **AC-5:** Sample of key maps tested: Lorencia, Devias, Noria, Dungeon, Lost Tower, Atlans (from `ENUM_WORLD`)

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards Compliance (naming, logging, error taxonomy per project-context.md)
- [x] **AC-STD-2:** Testing Requirements — Catch2 test suite validates navigation logic where testable without live server
- [x] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format + cppcheck 0 errors)
- [x] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [x] **AC-STD-16:** Correct test infrastructure used (Catch2 v3.7.1, `tests/` directory)

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [x] **AC-STD-13:** Quality Gate passes (`./ctl check`)

---

## Validation Artifacts

- [x] **AC-VAL-6:** Test scenarios documented in `_bmad-output/test-scenarios/epic-6/`

<!-- AC-VAL-1..2 removed: require running test server + multiple platforms (macOS/Linux/Windows).
     Manual validation is tracked separately outside PCC automation scope.
     See Risk R17 in Dev Notes. -->

---

## Tasks / Subtasks

- [x] Task 1: Create test scenario documentation for world navigation validation (AC: VAL-6)
  - [x] Subtask 1.1: Document manual test plan for character movement (click-to-move, keyboard, pathfinding)
  - [x] Subtask 1.2: Document manual test plan for map transitions (portals, warps, gate system)
  - [x] Subtask 1.3: Document manual test plan for map rendering (terrain, objects, NPCs) across key maps
  - [x] Subtask 1.4: Document manual test plan for minimap functionality
- [x] Task 2: Create Catch2 test suite for world navigation validation logic (AC: 1-5, STD-2)
  - [x] Subtask 2.1: Test map loading and ENUM_WORLD constants validation
  - [x] Subtask 2.2: Test pathfinding (PATH class A* algorithm) with grid dimensions and wall detection
  - [x] Subtask 2.3: Test portal/warp gate data validation (CMoveCommandData level/zen requirements)
  - [x] Subtask 2.4: Test map transition state management (PortalMgr save/restore positions)
- [x] Task 3: Run quality gate and fix any violations (AC: STD-1, STD-13)
  - [x] Subtask 3.1: Run `./ctl check` — fix clang-format violations
  - [x] Subtask 3.2: Run `./ctl check` — fix cppcheck warnings
<!-- Tasks 4+ removed: manual platform validation requires running test server + multiple platforms.
     Tracked separately outside PCC automation scope. See Risk R17 in Dev Notes. -->

---

## Error Codes Introduced

N/A — This is a validation story; no new error codes are introduced.

---

## Contract Catalog Entries

N/A — This is a C++ game client validation story. No API, event, or navigation catalog entries apply.

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 v3.7.1 | Logic coverage for map/navigation systems | Map enum validation, pathfinding algorithm, portal state, move command data |
| Manual | Screenshots + checklist | All 5 ACs on 3 platforms | Movement, map transitions, rendering, minimap, key maps |
| Regression | Manual comparison | No regression on Windows | Same flows verified on Windows baseline |

---

## Dev Notes

### Architecture Context

- **Map system:** `MapManager` (`World/MapManager.h/.cpp`) is the central world manager. `ENUM_WORLD` defines all 82+ map IDs (Lorencia=0, Dungeon=1, Devias=2, Noria=3, Lost Tower=4, Atlans=7, etc.). `LoadWorld(int Map)` loads specific maps.
- **Character movement:** `ZzzCharacter.h/.cpp` handles `MoveCharacterClient()`, `MoveCharacterPosition()`, and `SetPlayerWalk()`. Click-to-move uses the A* pathfinding in `ZzzPath.h/.cpp` (`PATH::FindPath()`).
- **Pathfinding:** `PATH` class implements A* with binary tree for open nodes, wall detection, and distance constraints. `SetMapDimensions()` initializes the pathfinding grid per map.
- **Map transitions:** `PortalMgr` singleton manages teleportation state (`SavePortalPosition()`, `SaveRevivePosition()`, `IsPortalUsable()`). `CMoveCommandData` defines gate movement requirements (level, zen, gate numbers).
- **Map rendering:** `MapProcess` singleton (`w_MapProcess.h/.cpp`) orchestrates per-map rendering including `CreateObject()`, `MoveObject()`, `RenderObjectVisual()`, `CreateMonster()`, `MoveMonsterVisual()`, `RenderMonsterVisual()`. LOD terrain via `ZzzLodTerrain`.
- **Minimap:** `CNewUIMiniMap` extends `CNewUIObj` with `Create()`, `Update()`, `Render()`, `UpdateMouseEvent()`, `UpdateKeyEvent()`. Renders location buttons and scroll.
- **Map-specific logic:** 26+ `GM*.cpp` files in `World/Maps/` implement per-map behavior (spawn logic, terrain specifics, event zones).
- **Scene flow:** After login (6-1-1), the `MainScene` drives the game world loop via `MoveMainScene()` / `RenderMainScene()`. Scene state tracked in `SceneCore.h` with `EGameScene` enum.
- **Camera:** `CCameraMove` handles camera path scripting with waypoints.

### Key Source Files

| File | Purpose |
|------|---------|
| `src/source/World/MapManager.h/.cpp` | Central map/world manager, `ENUM_WORLD`, `LoadWorld()` |
| `src/source/World/w_MapProcess.h/.cpp` | Map rendering orchestration, object/monster processing |
| `src/source/World/ZzzPath.h/.cpp` | A* pathfinding algorithm |
| `src/source/World/ZzzLodTerrain.h/.cpp` | LOD terrain rendering |
| `src/source/World/PortalMgr.h/.cpp` | Portal/warp state management |
| `src/source/Data/MoveCommandData.h/.cpp` | Gate movement data (level/zen requirements) |
| `src/source/Gameplay/Characters/ZzzCharacter.h/.cpp` | Character movement, animation, skills |
| `src/source/Gameplay/Characters/ZzzObject.h/.cpp` | World object rendering and collision |
| `src/source/UI/Windows/HUD/NewUIMiniMap.h/.cpp` | Minimap UI |
| `src/source/Scenes/MainScene.h/.cpp` | Main game scene loop |
| `src/source/Scenes/SceneCore.h/.cpp` | Scene state machine, `EGameScene` |
| `src/source/World/Maps/GM*.cpp` | Per-map specific logic (26+ files) |
| `src/source/World/CSWaterTerrain.h/.cpp` | Water terrain system |
| `src/source/World/PhysicsManager.h/.cpp` | Physics simulation, collision detection |
| `src/source/Core/CameraMove.h/.cpp` | Camera waypoint scripting |

### Risk Items

- **R17 (from sprint-status):** All EPIC-6 stories require a running MU Online server for manual validation. Ensure test server is available before starting manual test tasks.
- **Server dependency:** Catch2 tests should validate logic that can be tested WITHOUT a live server (map enum constants, pathfinding algorithm, portal state management, move command data validation). Manual validation requires server.
- **Map count:** 82+ maps defined in `ENUM_WORLD` — validation focuses on 6 representative maps (Lorencia, Devias, Noria, Dungeon, Lost Tower, Atlans) as specified in AC-5.

### PCC Project Constraints

- **Prohibited:** No raw `new`/`delete`, no `NULL`, no `timeGetTime()`, no `#ifdef _WIN32` in game logic, no `wchar_t` in new serialization
- **Required:** `std::unique_ptr`, `nullptr`, `std::chrono::steady_clock`, `std::filesystem::path`, `#pragma once`, Allman braces, 4-space indent
- **Quality gate:** `./ctl check` (clang-format 21.1.8 + cppcheck) — must pass 0 errors
- **Test organization:** `tests/{module}/test_{name}.cpp` mirroring `src/source/{Module}/`
- **References:** `_bmad-output/project-context.md`, `docs/development-standards.md`

### Project Structure Notes

- Tests go in `MuMain/tests/` — e.g., `tests/world/test_world_navigation_validation.cpp`
- Test binary: `MuTests` target, linked against `MUCore` (and potentially `MUGame` for world logic)
- `MUCore` uses `file(GLOB)` — new `.cpp` files auto-discovered
- For world-level tests, may need to link against `MUGame` or extract testable logic into `MUCore`
- Previous story (6-1-1) established pattern: tests in `tests/scenes/` for scene state validation

### Dependency Context

This story sits on the **critical path** for EPIC-6:
- **Depends on:** 6-1-1-auth-character-validation (done) — player can log in and enter game world
- **Unblocks:** 6-2-1-combat-system-validation — combat validation requires navigating to monster areas

Previous story (6-1-1) established:
- Catch2 test patterns for scene state validation
- `SceneCommon.h` encapsulation fixes (const getters + setters)
- `SceneManager.h` `FrameTimingState` accessor pattern
- Quality gate workflow (711 files, 0 errors)
- Test file placement in `tests/scenes/`

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 6, Story 6.1.2]
- [Source: _bmad-output/project-context.md — C++ Language Rules, Testing Rules]
- [Source: sprint-status.yaml — Sprint 6 critical path analysis]
- [Source: CLAUDE.md — Build Commands, Conventions]
- [Source: _bmad-output/stories/6-1-1-auth-character-validation/story.md — Previous story patterns]

---

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

- Quality gate: `./ctl check` passed 711/711 files, 0 format violations, 0 cppcheck errors (2026-03-21)

### Completion Notes List

- PCC create-story workflow completed — SAFe metadata and AC-STD sections included
- Story type: infrastructure (cross-platform validation, not frontend/backend feature)
- No API/event/navigation contracts (C++ game client, no REST endpoints)
- Schema alignment: N/A (C++ game client)
- Visual design specification: N/A (not a frontend_feature story)
- Key navigation systems identified: MapManager (82+ maps), PATH (A* pathfinding), PortalMgr (teleportation), CMoveCommandData (gate system), CNewUIMiniMap (minimap), MapProcess (rendering), 26+ GM*.cpp map implementations
- Prerequisite story 6-1-1 done — patterns established for Catch2 test suites and quality gate workflow
- Critical path story: unblocks 6-2-1-combat-system-validation
- dev-story: All 3 tasks complete (10 subtasks). Test scenarios document covers 5 manual validation scenarios. Catch2 test suite has 13 TEST_CASEs (10 compiled, 3 SKIP stubs for MUGame-linked tests). ATDD checklist 100% (31/31 items). Quality gate passed 711 files with 0 violations.
- Functional ACs 1-5 remain unchecked: require live server manual validation per Risk R17 (manual platform validation tasks explicitly removed from PCC automation scope)

### Change Log

- 2026-03-21: dev-story workflow — all 3 tasks (10 subtasks) completed. Test scenarios, Catch2 test suite (13 TEST_CASEs), and quality gate (711 files, 0 errors) verified. ATDD 31/31 items. Status → review.

### File List

- [CREATE] `MuMain/tests/world/test_world_navigation_validation.cpp` — Catch2 test suite for world navigation logic (13 TEST_CASEs)
- [CREATE] `_bmad-output/test-scenarios/epic-6/world-navigation-validation.md` — Manual test scenarios (5 scenarios)
- [CREATE] `_bmad-output/stories/6-1-2-world-navigation-validation/story.md` — This story file
- [CREATE] `_bmad-output/stories/6-1-2-world-navigation-validation/atdd.md` — ATDD checklist
- [CREATE] `_bmad-output/stories/6-1-2-world-navigation-validation/progress.md` — Progress tracking file
