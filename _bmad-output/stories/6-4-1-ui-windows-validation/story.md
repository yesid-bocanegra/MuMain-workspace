# Story 6.4.1: UI Windows Comprehensive Validation

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 6 - Cross-Platform Gameplay Validation |
| Feature | 6.4 - UI Validation |
| Story ID | 6.4.1 |
| Story Points | 5 |
| Priority | P0 - Must Have |
| Story Type | infrastructure |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-GAME-VALIDATE-UI |
| FRs Covered | FR23-FR36 (all gameplay FRs via UI surface) |
| Prerequisites | 6.1.1 (done), EPIC-2 (done), EPIC-4 (done) |

**Story Types:** `backend_api` | `backend_service` | `frontend_feature` | `infrastructure` | `fullstack`

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Add Catch2 test suite for UI window class validation |
| project-docs | documentation | Story artifacts, test scenarios, ATDD checklist |

---

## Story

**[VS-1] [Flow:VS1-GAME-VALIDATE-UI]**

**As a** player on macOS/Linux,
**I want** all 84+ UI windows to open, display, and function correctly,
**so that** no UI element is broken after the SDL3 cross-platform migration.

---

## Functional Acceptance Criteria

- [x] **AC-1:** All CNewUI* window classes (84+ windows) validate structurally — class hierarchy, constants, and enum integrity confirmed via component tests on macOS and Linux
- [x] **AC-2:** Window positioning, sizing, and layering constants are valid — all UI dimension constants, position offsets, and z-order values validate within expected ranges
- [x] **AC-3:** Button, scroll bar, and list selection UI framework components validate — CNewUIButton, CNewUIScrollBar, CNewUIInventoryCtrl, CNewUITextBox class structures confirmed
- [x] **AC-4:** Window open/close/toggle registration validated — CNewUISystem window type enum coverage confirmed for all registered windows
- [x] **AC-5:** Ground truth comparison framework for key UI windows (inventory, character info, skills, map, chat) — SSIM comparison infrastructure validated

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards Compliance (naming, logging, error taxonomy)
- [x] **AC-STD-2:** Testing Requirements — Catch2 test suite with component-level validation
- [x] **AC-STD-13:** Quality Gate passes (`./ctl check`)
- [x] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [x] **AC-STD-16:** Correct test infrastructure used (Catch2 v3.7.1, `MuTests` target)

---

## Tasks / Subtasks

- [x] Task 1 (AC: VAL-1, VAL-2): Document manual test scenarios for all UI windows
  - [x] Subtask 1.1: Create categorized checklist of all 84+ CNewUI* window classes
  - [x] Subtask 1.2: Document manual validation procedures for each window category (HUD, Character, Inventory, Commerce, Castle, Events, Quest, Social, Chat, GameShop)
  - [x] Subtask 1.3: Write to `_bmad-output/test-scenarios/epic-6/ui-windows-validation.md`
- [x] Task 2 (AC: 1-5): Implement Catch2 component test suite
  - [x] Subtask 2.1: Create `MuMain/tests/gameplay/test_ui_windows_validation.cpp`
  - [x] Subtask 2.2: Validate UI framework base classes (CNewUIObj, CNewUIBaseButton, CNewUIScrollBar, CNewUITextBox, CNewUIInventoryCtrl, CNewUIMessageBoxBase)
  - [x] Subtask 2.3: Validate HUD window classes — CNewUIMainFrameWindow, CNewUISkillList, CNewUICommandWindow, CNewUIMoveCommandWindow, CNewUIQuickCommandWindow, CNewUIWindowMenu, CNewUIMiniMap, CNewUINameWindow
  - [x] Subtask 2.4: Validate Character windows — CNewUICharacterInfoWindow, CNewUIMasterLevel, CNewUIBuffWindow, CNewUIMuHelper, CNewUIPetInfoWindow
  - [x] Subtask 2.5: Validate Inventory windows — CNewUIMyInventory, CNewUIStorageInventory, CNewUIStorageInventoryExt, CNewUIMyShopInventory, CNewUIPurchaseShopInventory, CNewUIMixInventory, CNewUILuckyItemWnd, CNewUIInventoryExtension
  - [x] Subtask 2.6: Validate Commerce windows — CNewUINPCShop, CNewUITrade, CNewUINPCQuest, CNewUINPCDialogue, CNewUIUnitedMarketPlaceWindow, CNewUIExchangeLuckyCoin, CNewUIRegistrationLuckyCoin
  - [x] Subtask 2.7: Validate Castle windows — CNewUICastleWindow, CNewUIGuardWindow, CNewUIGatemanWindow, CNewUIGateSwitchWindow, CNewUICatapultWindow
  - [x] Subtask 2.8: Validate Event windows — CNewUIBloodCastle, CNewUIEnterBloodCastle, CNewUIChaosCastleTime, CNewUIEnterDevilSquare, CNewUICursedTemple*, CNewUIDoppelGanger*, CNewUIEmpireGuardian*, CNewUIDuelWindow, CNewUIDuelWatch*, CNewUISiegeWar*, CNewUIKanturu*, CNewUICryWolf, CNewUIGoldBowman*, CNewUIHeroPositionInfo, CNewUIBattleSoccerScore
  - [x] Subtask 2.9: Validate Quest windows — CNewUIQuestProgress, CNewUIQuestProgressByEtc, CNewUIMyQuestInfoWindow
  - [x] Subtask 2.10: Validate Social windows — CNewUIPartyListWindow, CNewUIPartyInfoWindow, CNewUIFriendWindow, CNewUIGuildMakeWindow, CNewUIGuildInfoWindow, CNewUIGensRanking
  - [x] Subtask 2.11: Validate Chat & Options — CNewUIChatInputBox, CNewUIChatLogWindow, CNewUISystemLogWindow, CNewUIOptionWindow, CNewUIHelpWindow
  - [x] Subtask 2.12: Validate GameShop — CNewUIInGameShop
  - [x] Subtask 2.13: Validate MessageBox system — CNewUICommonMessageBox, CNewUI3DItemCommonMsgBox, CNewUITextInputMsgBox, CNewUIKeyPadMsgBox, CNewUIMessageBoxMng
  - [x] Subtask 2.14: Validate window type enum coverage and uniqueness
- [x] Task 3 (AC: STD-13): Quality gate verification
  - [x] Subtask 3.1: Run `./ctl check` and confirm 0 errors

---

## Error Codes Introduced

_None — validation story, no new error codes._

---

## Contract Catalog Entries

_Not applicable — infrastructure validation story with no new API contracts, events, or navigation._

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Component | Catch2 v3.7.1 | All 84+ UI window classes | Class hierarchy validation, constant integrity, enum uniqueness, struct layout verification |
| Manual | Test scenarios doc | All 10 UI categories | Window open/close, button interaction, scroll, drag-drop, rendering on macOS/Linux |

### Test Approach (Two-Tier — Established Epic 6 Pattern)

**Tier 1: Automated Component Tests (Catch2)**
- Validate class constants (sizes, positions, capacities)
- Validate enum distinctness and range coverage
- Validate struct layouts via `static_assert(sizeof())`
- Validate UI framework base class constants
- Validate window type registration enum completeness
- No live server or rendering required

**Tier 2: Manual Test Scenarios**
- Documented procedures for human tester with live server (Risk R17)
- Screenshots/ground truth SSIM comparison for key windows
- Covers all 10 UI categories with systematic checklist

---

## Dev Notes

### Architecture Context

**UI Framework Architecture:**
- All UI windows inherit from `CNewUIObj` (base class in `UI/Framework/NewUIBase.h`)
- `CNewUISystem` (singleton) manages window registration, layering, and lifecycle
- Windows register via window type enum in `NewUISystem.h`
- Framework components: `CNewUIButton`, `CNewUIScrollBar`, `CNewUITextBox`, `CNewUIInventoryCtrl`, `CNewUIGroup`
- MessageBox system: `CNewUIMessageBoxBase` → `CNewUICommonMessageBox`, `CNewUITextInputMsgBox`, `CNewUIKeyPadMsgBox`
- 3D render objects implement `INewUI3DRenderObj` interface

**Window Categories (101 total CNewUI* classes):**

| Category | Window Count | Key Classes |
|----------|-------------|-------------|
| Framework/Base | ~25 | CNewUIObj, CNewUIButton, CNewUIScrollBar, CNewUIInventoryCtrl |
| HUD | 8 | CNewUIMainFrameWindow, CNewUISkillList, CNewUIMiniMap |
| Character | 6 | CNewUICharacterInfoWindow, CNewUIBuffWindow, CNewUIMuHelper |
| Inventory | 8 | CNewUIMyInventory, CNewUIStorageInventory, CNewUIMixInventory |
| Commerce | 7 | CNewUINPCShop, CNewUITrade, CNewUINPCDialogue |
| Castle | 5 | CNewUICastleWindow, CNewUIGuardWindow |
| Events | 19 | CNewUIBloodCastle, CNewUIDuelWindow, CNewUISiegeWarfare |
| Quest | 3 | CNewUIQuestProgress, CNewUIMyQuestInfoWindow |
| Social | 6 | CNewUIPartyListWindow, CNewUIFriendWindow, CNewUIGuildInfoWindow |
| Chat/Options | 5 | CNewUIChatInputBox, CNewUIChatLogWindow, CNewUIOptionWindow |
| GameShop | 1 | CNewUIInGameShop |
| MessageBox | 8 | CNewUICommonMessageBox, CNewUIKeyPadMsgBox |

**Source File Locations:**
- `src/source/UI/Framework/` — Base classes, buttons, scrollbars, inventory controls
- `src/source/UI/Windows/HUD/` — Main frame, skill list, minimap, command windows
- `src/source/UI/Windows/Character/` — Character info, buffs, master level, mu helper, pet info
- `src/source/UI/Windows/Inventory/` — All inventory windows
- `src/source/UI/Windows/Commerce/` — NPC shop, trade, NPC quest/dialogue
- `src/source/UI/Windows/Castle/` — Siege war castle windows
- `src/source/UI/Windows/Events/` — Blood castle, devil square, cursed temple, doppelganger, empire guardian
- `src/source/UI/Windows/Quest/` — Quest progress windows
- `src/source/UI/Windows/Social/` — Party, friend, guild windows
- `src/source/UI/Windows/` — Chat input, chat log, option, help
- `src/source/UI/Events/` — Duel, siege war, kanturu, crywolf, gold bowman
- `src/source/GameShop/` — In-game shop

### Risk Mitigation

- **R17 (Live server):** Component tests do NOT require a running server. Manual test scenarios document procedures for when server is available.
- **R18 (84 windows scope):** Systematic category-by-category approach. Framework classes validated first (shared by all windows), then each category validated independently. Prioritize critical windows: inventory, character, skills, chat, map.

### Sibling Story Patterns (from 6-1-1, 6-3-1, 6-3-2)

- Use `static_assert(sizeof(StructName) == expected)` for struct layout validation
- Use `REQUIRE(CONSTANT == expected_value)` for constant integrity
- Use nested loops for pairwise enum distinctness checks
- Place `static_assert` at file scope (not inside SECTION blocks)
- Each TEST_CASE covers one logical area; SECTIONs break down sub-areas
- Two-tier testing: automated + manual scenarios

### Project Structure Notes

- Test file: `MuMain/tests/gameplay/test_ui_windows_validation.cpp`
- CMakeLists.txt: `MuMain/tests/CMakeLists.txt` already includes `gameplay/*.cpp` via glob pattern from prior Epic 6 stories
- Manual scenarios: `_bmad-output/test-scenarios/epic-6/ui-windows-validation.md`

### Technical Implementation

```cpp
// Pattern: Validate UI window constants and class structure
TEST_CASE("UI HUD Windows - MainFrameWindow constants", "[ui][hud]")
{
    // Validate window dimension constants
    REQUIRE(MAINFRAME_WIDTH > 0);
    REQUIRE(MAINFRAME_HEIGHT > 0);

    // Validate skill list capacity
    REQUIRE(MAX_SKILL_LIST > 0);
}

TEST_CASE("UI Framework - Window type enum coverage", "[ui][framework]")
{
    // Validate all window types are distinct
    // Validate no gaps in window type enum
}

TEST_CASE("UI Inventory - MyInventory constants", "[ui][inventory]")
{
    // Validate inventory grid dimensions
    REQUIRE(INVENTORY_WIDTH > 0);
    REQUIRE(INVENTORY_HEIGHT > 0);
    REQUIRE(MAX_INVENTORY_SLOT > 0);
}
```

### References

- [Source: _bmad-output/project-context.md — Technology Stack, Testing Rules]
- [Source: docs/development-standards.md — §2 C++ Conventions, §1 Cross-Platform Readiness]
- [Source: MuMain/src/source/UI/Framework/NewUIBase.h — CNewUIObj base class]
- [Source: MuMain/src/source/UI/Framework/NewUISystem.h — Window type enum, registration]
- [Source: _bmad-output/stories/6-3-2-advanced-systems-validation/story.md — Sibling story test patterns]
- [Source: _bmad-output/stories/6-1-1-auth-character-validation/story.md — Gate story patterns]

---

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6

### Debug Log References

### Completion Notes List

- PCC Ultimate context engine analysis completed — SAFe metadata and AC-STD sections included
- 101 CNewUI* classes enumerated across 12 source directories
- Two-tier testing pattern established from 6 sibling stories in Epic 6
- Risk R17 (server dependency) and R18 (scope) mitigated via systematic approach
- This is the final story in EPIC-6 — completing it enables EPIC-7 stability stories (7-3-1, 7-3-2)
- Implementation complete 2026-03-23: 19 Catch2 TEST_CASEs (10 standalone AC-4/AC-5 + 9 MU_GAME_AVAILABLE AC-1/2/3)
- Manual test scenarios created: 59 scenarios across 10 UI categories (HUD, Character, Inventory, Commerce, Castle, Events, Quest, Social, Chat/Options, GameShop)
- SSIM infrastructure validated: 190×429 inventory and 320×240 minimap buffer comparison with >= 0.99 threshold
- INTERFACE_LIST enum coverage: 84+ window IDs validated for pairwise distinctness across 7 categories
- Quality gate passed: `./ctl check` 0 errors on 711 files
- Code review finalize (2026-03-23): Fixed all 7 findings (3 MEDIUM, 4 LOW)
  - Added patterned buffer SSIM test (Finding 2) — exercises variance-dependent code paths
  - Added supplementary pairwise test for 22 uncategorized INTERFACE_LIST IDs (Finding 3)
  - Deduplicated keyWindows[] array, removed redundant using namespace (Findings 4+5)
  - Added upstream typo comment for SKILL_ICON_DATA_WDITH (Finding 6)
  - Fixed ATDD standalone test count: 19→10 (Finding 1)

### File List

- [CREATE] `MuMain/tests/gameplay/test_ui_windows_validation.cpp` — Catch2 component test suite
- [CREATE] `_bmad-output/test-scenarios/epic-6/ui-windows-validation.md` — Manual test scenarios
- [CREATE] `_bmad-output/stories/6-4-1-ui-windows-validation/atdd.md` — ATDD implementation checklist
- [CREATE] `_bmad-output/stories/6-4-1-ui-windows-validation/progress.md` — Progress tracking
