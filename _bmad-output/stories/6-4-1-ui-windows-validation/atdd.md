# ATDD Implementation Checklist — Story 6.4.1: UI Windows Comprehensive Validation

**Story ID**: 6-4-1-ui-windows-validation
**Story Type**: infrastructure
**Date Generated**: 2026-03-23
**Workflow**: testarch-atdd v1.1
**Phase**: GREEN — all tests implemented and verified

---

## FSM Handoff Summary

| Field | Value |
|-------|-------|
| `story_file_path` | `_bmad-output/stories/6-4-1-ui-windows-validation/story.md` |
| `story_key` | `6-4-1-ui-windows-validation` |
| `story_type` | `infrastructure` |
| `backend_root` | `MuMain` (first component with `backend` tag) |
| `atdd_checklist_path` | `_bmad-output/stories/6-4-1-ui-windows-validation/atdd.md` |
| `implementation_checklist_complete` | `true` — all 31 items verified `[x]` |

---

## Existing Tests Mapped to ACs (Step 0.5 Result)

No existing test file found at `MuMain/tests/gameplay/test_ui_windows_validation.cpp`.
All ACs require new tests — none pre-mapped.

| AC | Description | Existing Test | Action |
|----|-------------|---------------|--------|
| AC-1 | UI class hierarchy validation | None | GENERATE NEW |
| AC-2 | Window dimension constants | None | GENERATE NEW |
| AC-3 | Button/scrollbar/list framework | None | GENERATE NEW |
| AC-4 | Window type enum coverage | None | GENERATE NEW |
| AC-5 | SSIM ground truth infrastructure | None | GENERATE NEW |

---

## Test Files Created (RED Phase)

| File | Status | ACs Covered |
|------|--------|-------------|
| `MuMain/tests/gameplay/test_ui_windows_validation.cpp` | CREATED | AC-1, AC-2, AC-3, AC-4, AC-5 |

**Note**: Bruno API test collection — **SKIPPED** (story type `infrastructure`, no API endpoints).

---

## AC-to-Test Mapping

| AC | Test Case Name | Tags | Gate |
|----|----------------|------|------|
| AC-1 | `AC-1 [6-4-1]: INewUIBase is a pure-virtual (abstract) interface` | `[ui][hierarchy][abstract]` | MU_GAME_AVAILABLE |
| AC-1 | `AC-1 [6-4-1]: CNewUIObj is an abstract base class derived from INewUIBase` | `[ui][hierarchy][base-class]` | MU_GAME_AVAILABLE |
| AC-1 | `AC-1 [6-4-1]: CNewUIObj default visibility and enabled state after construction` | `[ui][hierarchy][state]` | MU_GAME_AVAILABLE |
| AC-2 | `AC-2 [6-4-1]: Inventory grid cell dimensions define valid square cells` | `[ui][inventory][grid][constants]` | MU_GAME_AVAILABLE |
| AC-2 | `AC-2 [6-4-1]: CNewUIMiniMap MASTER_DATA skill icon geometry constants are valid` | `[ui][minimap][master-data]` | MU_GAME_AVAILABLE |
| AC-2 | `AC-2 [6-4-1]: TOOLTIP_TYPE enum covers all inventory tooltip display contexts` | `[ui][tooltip][enum]` | MU_GAME_AVAILABLE |
| AC-3 | `AC-3 [6-4-1]: BUTTON_STATE enum defines the 3 visual button interaction states` | `[ui][button][enum]` | MU_GAME_AVAILABLE |
| AC-3 | `AC-3 [6-4-1]: RADIOGROUPEVENT_NONE sentinel is -1` | `[ui][button][radio-group]` | MU_GAME_AVAILABLE |
| AC-3 | `AC-3 [6-4-1]: SQUARE_COLOR_STATE enum covers normal and warning inventory slot states` | `[ui][inventory][color-state]` | MU_GAME_AVAILABLE |
| AC-4 | `AC-4 [6-4-1]: INTERFACE_LIST boundary values and count validate 84+ window coverage` | `[ui][interface][enum]` | always |
| AC-4 | `AC-4 [6-4-1]: HUD and core UI window IDs are present and pairwise distinct` | `[ui][interface][hud]` | always |
| AC-4 | `AC-4 [6-4-1]: Inventory and commerce window IDs are pairwise distinct` | `[ui][interface][inventory]` | always |
| AC-4 | `AC-4 [6-4-1]: Social window IDs are pairwise distinct` | `[ui][interface][social]` | always |
| AC-4 | `AC-4 [6-4-1]: Castle window IDs are pairwise distinct` | `[ui][interface][castle]` | always |
| AC-4 | `AC-4 [6-4-1]: Event window IDs are pairwise distinct` | `[ui][interface][events]` | always |
| AC-4 | `AC-4 [6-4-1]: Quest and MuHelper window IDs are pairwise distinct` | `[ui][interface][quest]` | always |
| AC-5 | `AC-5 [6-4-1]: The 5 key UI window IDs for SSIM comparison are registered and distinct` | `[ui][ssim][key-windows]` | always |
| AC-5 | `AC-5 [6-4-1]: SSIM infrastructure validates identical inventory-sized buffers` | `[ui][ssim][inventory]` | always |
| AC-5 | `AC-5 [6-4-1]: SSIM infrastructure validates identical minimap-sized buffers` | `[ui][ssim][minimap]` | always |

---

## Implementation Checklist

### Functional Acceptance Criteria

- [x] **AC-1: Class Hierarchy Validation (MU_GAME_AVAILABLE)**
  - [x] `INewUIBase is a pure-virtual (abstract) interface` — `std::is_abstract_v<INewUIBase>` passes
  - [x] `CNewUIObj derives from INewUIBase` — `std::is_base_of_v` passes
  - [x] `CNewUIObj is abstract` — `std::is_abstract_v<CNewUIObj>` passes
  - [x] `TestUIWindow default state: visible=true, enabled=true` passes
  - [x] `Show(false)/Show(true) state transitions` pass
  - [x] `Enable(false)/Enable(true) state transitions` pass
  - [x] `GetKeyEventOrder() == 3.0f` passes

- [x] **AC-2: Window Dimension Constants (MU_GAME_AVAILABLE)**
  - [x] `INVENTORY_SQUARE_WIDTH == 20` passes
  - [x] `INVENTORY_SQUARE_HEIGHT == 20` passes
  - [x] `INVENTORY_SQUARE_WIDTH == INVENTORY_SQUARE_HEIGHT` passes
  - [x] `CNewUIMiniMap::SKILL_ICON_DATA_WDITH == 4` passes
  - [x] `CNewUIMiniMap::SKILL_ICON_DATA_HEIGHT == 8` passes
  - [x] `CNewUIMiniMap::SKILL_ICON_WIDTH == 20` passes
  - [x] `CNewUIMiniMap::SKILL_ICON_HEIGHT == 28` passes
  - [x] `CNewUIMiniMap::SKILL_ICON_STARTX1 > 0`, `SKILL_ICON_STARTY1 > 0` pass
  - [x] `UNKNOWN_TOOLTIP_TYPE == 0` passes
  - [x] All 6 TOOLTIP_TYPE values pairwise distinct passes

- [x] **AC-3: Button and Framework Component Enums (MU_GAME_AVAILABLE)**
  - [x] `BUTTON_STATE_UP == 0` passes
  - [x] `BUTTON_STATE_DOWN == 1` passes
  - [x] `BUTTON_STATE_OVER == 2` passes
  - [x] All 3 BUTTON_STATE values pairwise distinct passes
  - [x] `RADIOGROUPEVENT_NONE == -1` passes
  - [x] `UNKNOWN_COLOR_STATE == 0` passes
  - [x] `COLOR_STATE_NORMAL > UNKNOWN_COLOR_STATE` passes
  - [x] `COLOR_STATE_WARNING > COLOR_STATE_NORMAL` passes
  - [x] All 3 SQUARE_COLOR_STATE values pairwise distinct passes

- [x] **AC-4: INTERFACE_LIST Enum Coverage (standalone — always compiled)**
  - [x] `INTERFACE_BEGIN == 0x00` passes
  - [x] `INTERFACE_COUNT >= 84` passes
  - [x] `INTERFACE_END == INTERFACE_COUNT + 2` passes
  - [x] `INTERFACE_3DRENDERING_CAMERA_END == INTERFACE_3DRENDERING_CAMERA_BEGIN + 24` passes
  - [x] Core HUD windows (12 IDs) pairwise distinct passes
  - [x] Inventory/commerce windows (12 IDs) pairwise distinct passes
  - [x] Social windows (6 IDs) pairwise distinct passes
  - [x] Castle windows (6 IDs) pairwise distinct passes
  - [x] Event windows (19 IDs) pairwise distinct passes
  - [x] Quest windows (4 IDs) pairwise distinct passes
  - [x] MuHelper windows (3 IDs) pairwise distinct passes

- [x] **AC-5: SSIM Infrastructure (standalone — always compiled)**
  - [x] 5 key window IDs pairwise distinct passes
  - [x] All 5 key window IDs within `(INTERFACE_BEGIN, INTERFACE_END)` range passes
  - [x] Identical 190x429 inventory buffers SSIM >= 0.99 passes
  - [x] Perceptibly different 190x429 buffers SSIM < 0.5 passes
  - [x] Identical 320x240 minimap buffers SSIM >= 0.99 passes

### Standard Acceptance Criteria

- [x] **AC-STD-1:** Code follows naming, logging, and error taxonomy conventions
- [x] **AC-STD-2:** Catch2 test suite present at `MuMain/tests/gameplay/test_ui_windows_validation.cpp`
  - [x] All standalone tests (AC-4, AC-5) compile and run on macOS/Linux without Win32
  - [x] MU_GAME_AVAILABLE tests compile without errors when game headers available
- [x] **AC-STD-13:** Quality gate passes — `./ctl check` returns 0 errors
- [x] **AC-STD-15:** Git safety — no incomplete rebase, no force push to main
- [x] **AC-STD-16:** Correct test infrastructure — Catch2 v3.7.1, `MuTests` target

### PCC Compliance Items

- [x] No prohibited libraries used (no mocking framework — project-context.md §Testing Rules)
- [x] Catch2 v3.7.1 used exclusively (FetchContent, `MuTests` target)
- [x] `#pragma once` not used in `.cpp` test file (correct — test files use no header guards)
- [x] `#ifdef _WIN32` / `PlatformTypes.h` guard applied for Win32 type dependencies
- [x] `#ifdef MU_GAME_AVAILABLE` gates all NewUI class header includes
- [x] Allman braces, 4-space indent, 120-column limit enforced throughout
- [x] No raw `new`/`delete` in test code
- [x] `static_assert` placed at file scope (not inside SECTION blocks) — N/A for this file
- [x] AC-N: prefixes used in all TEST_CASE names for AC compliance tracking
- [x] CMakeLists.txt updated with `target_sources(MuTests PRIVATE gameplay/test_ui_windows_validation.cpp)`

---

## Manual Test Scenarios

- [x] **Task 1: Manual test scenarios documented**
  - [x] `_bmad-output/test-scenarios/epic-6/ui-windows-validation.md` created with all 10 UI categories
  - [x] All 84+ CNewUI* window classes enumerated with open/close/toggle procedures
  - [x] Manual validation procedures documented for HUD, Character, Inventory, Commerce, Castle, Events, Quest, Social, Chat, GameShop
  - [x] Screenshots / ground truth SSIM comparison procedures documented for 5 key windows

---

## Output Summary

| Item | Value |
|------|-------|
| Story ID | 6-4-1-ui-windows-validation |
| Primary Test Level | Component (Catch2 v3.7.1) |
| Test File | `MuMain/tests/gameplay/test_ui_windows_validation.cpp` |
| Standalone Tests (AC-4, AC-5) | 10 TEST_CASEs (always compiled, no Win32 required) |
| MU_GAME_AVAILABLE Tests (AC-1..3) | 9 TEST_CASEs (require full game headers) |
| Total TEST_CASEs | 19 |
| Bruno Collection | N/A (infrastructure story, no API endpoints) |
| Prohibited Libraries Violated | None |
| PCC Patterns Used | Catch2 REQUIRE/CHECK, pairwise distinct loops, state transition tests |
| Coverage Target | All 84+ CNewUI* window types via INTERFACE_LIST enum |
| ATDD Checklist Path | `_bmad-output/stories/6-4-1-ui-windows-validation/atdd.md` |

---

## Final Validation

- [x] PCC guidelines loaded (project-context.md + development-standards.md)
- [x] Existing tests mapped — none found, all ACs generate new tests
- [x] AC-N: prefixes added to all TEST_CASE names
- [x] All tests use PCC-approved patterns (Catch2 REQUIRE, pairwise loops, `std::is_abstract_v`)
- [x] No prohibited libraries referenced
- [x] Implementation checklist includes PCC compliance items
- [x] CMakeLists.txt entry added for new test file
- [x] ATDD checklist includes AC-to-test mapping table
- [x] Standalone tests (AC-4, AC-5) compile without Win32 or OpenGL
- [x] All checklist items verified GREEN (dev-story implementation complete 2026-03-23)
