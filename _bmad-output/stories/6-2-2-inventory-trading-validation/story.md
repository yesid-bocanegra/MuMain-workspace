# Story 6.2.2: Inventory, Trading & Shops Validation

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 6 - Cross-Platform Gameplay Validation |
| Feature | 6.2 - Combat & Economy |
| Story ID | 6.2.2 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | infrastructure |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-GAME-VALIDATE-ECONOMY |
| FRs Covered | FR27, FR28, FR33 |
| Prerequisites | 6-1-1-auth-character-validation (done) |

**Story Types:** `backend_api` | `backend_service` | `frontend_feature` | `infrastructure` | `fullstack`

### Affected Components

<!-- Which components does this story modify? List ALL affected components from .pcc-config.yaml -->
<!-- The first backend/frontend listed becomes the primary target for quality gates -->

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Add Catch2 test suite for inventory, trading, and NPC shop data structure validation |
| project-docs | documentation | Story artifacts, test scenarios, validation documentation |

---

## Story

**[VS-1] [Flow:VS1-GAME-VALIDATE-ECONOMY]**

**As a** player on macOS/Linux,
**I want** inventory management, player trading, and NPC shops to work correctly,
**so that** the item economy functions on all platforms.

---

## Functional Acceptance Criteria

<!-- Functional ACs require live server + platform builds for full end-to-end validation.
     This infrastructure story provides: (a) Catch2 component-level tests for server-independent
     inventory/trading/shop logic, and (b) manual test scenario documentation for when server/platform builds are available.
     ACs are marked with component-level automated coverage status below.
     Full validation deferred to manual execution per Risk R17 (server dependency). -->

- [ ] **AC-1:** Inventory opens, displays items correctly (all 120 slots) — *Component tests: `ITEM` struct layout validation, `ITEM_ATTRIBUTE` field sizes, inventory grid constants (`MAX_ITEM_SPECIAL`, `MAX_SOCKETS`), equipment slot count. Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-2:** Equip/unequip items to character model — *Component tests: equipment slot enum values, `EQUIPMENT_LENGTH_EXTENDED` constant, equipment item packet struct layout. Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-3:** Drag-and-drop item movement within inventory — *Component tests: `CNewUIPickedItem` event states (`EVENT_PICKING`), tooltip type enums (`TOOLTIP_TYPE_INVENTORY`, etc.), inventory control storage types. Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-4:** Player-to-player trade window works — *Component tests: trade inventory dimensions (8×4=32 slots), `MAX_TRADE_INVEN` constant, trade packet structs. Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-5:** NPC shop buy/sell works — *Component tests: shop state enums (`SHOP_STATE_BUYNSELL`, `SHOP_STATE_REPAIR`), tooltip type for NPC shop, tax rate handling. Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-6:** Item tooltips display correctly — *Component tests: tooltip type enum completeness and uniqueness, `ITEM_ATTRIBUTE` struct field validation, item special/option data structures. Full end-to-end: deferred to manual validation (Risk R17)*

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance (naming, logging, error taxonomy per project-context.md)
- [ ] **AC-STD-2:** Testing Requirements — Catch2 test suite validates inventory/trading/shop logic where testable without live server
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format + cppcheck 0 errors)
- [ ] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [ ] **AC-STD-16:** Correct test infrastructure used (Catch2 v3.7.1, `tests/` directory)

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check`)

---

## Validation Artifacts

- [ ] **AC-VAL-6:** Test scenarios documented in `_bmad-output/test-scenarios/epic-6/`

<!-- AC-VAL-1..2 removed: require running test server + multiple platforms (macOS/Linux/Windows).
     Manual validation is tracked separately outside PCC automation scope.
     See Risk R17 in Dev Notes. -->

---

## Tasks / Subtasks

- [ ] Task 1: Create test scenario documentation for inventory, trading, and shop validation (AC: VAL-6)
  - [ ] Subtask 1.1: Document manual test plan for inventory display (open inventory, verify 120 slots, item icons)
  - [ ] Subtask 1.2: Document manual test plan for equip/unequip (drag item to equipment slot, verify character model update)
  - [ ] Subtask 1.3: Document manual test plan for drag-and-drop item movement (move items between slots, verify positioning)
  - [ ] Subtask 1.4: Document manual test plan for player-to-player trading (open trade, add items, confirm/cancel)
  - [ ] Subtask 1.5: Document manual test plan for NPC shop buy/sell (open shop, buy item, sell item, verify zen deduction)
  - [ ] Subtask 1.6: Document manual test plan for item tooltips (hover items, verify stats, set bonuses, socket info)
- [ ] Task 2: Create Catch2 test suite for inventory/trading/shop data structure validation (AC: 1-6, STD-2)
  - [ ] Subtask 2.1: Test `ITEM` struct layout — field sizes, `MAX_ITEM_SPECIAL`, `MAX_SOCKETS`, socket array dimensions
  - [ ] Subtask 2.2: Test `ITEM_ATTRIBUTE` struct — field validation, `ITEM_ATTRIBUTE_FILE` vs `ITEM_ATTRIBUTE_FILE_LEGACY` layout compatibility
  - [ ] Subtask 2.3: Test inventory control enums — `EVENT_PICKING` states, `TOOLTIP_TYPE_*` enum completeness and uniqueness
  - [ ] Subtask 2.4: Test trade system constants — `MAX_TRADE_INVEN` capacity, trade inventory grid dimensions (8 cols × 4 rows)
  - [ ] Subtask 2.5: Test NPC shop enums — `SHOP_STATE_BUYNSELL`/`SHOP_STATE_REPAIR` values, shop mode validation
  - [ ] Subtask 2.6: Test equipment slot constants — slot count, `EQUIPMENT_LENGTH_EXTENDED`, personal shop packet structs
  - [ ] Subtask 2.7: Test item option data structures — `CSItemOption` constants reuse from 6-2-1 (verify no regression), `ItemAddOption` types
- [ ] Task 3: Run quality gate and fix any violations (AC: STD-1, STD-13)
  - [ ] Subtask 3.1: Run `./ctl check` — fix clang-format violations
  - [ ] Subtask 3.2: Run `./ctl check` — fix cppcheck warnings
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
| Unit | Catch2 v3.7.1 | Logic coverage for inventory/trading/shop systems | ITEM struct layout, inventory enums, trade constants, shop states, tooltip types, equipment slots |
| Manual | Screenshots + checklist | All 6 ACs on 3 platforms | Inventory display, equip/unequip, drag-drop, trading, NPC shop, tooltips |
| Regression | Manual comparison | No regression on Windows | Same inventory/trading flows verified on Windows baseline |

---

## Dev Notes

### Architecture Context

- **Inventory core:** `CNewUIInventoryCtrl` (`UI/Framework/NewUIInventoryCtrl.h/.cpp`) is the grid-based inventory controller shared by ALL inventory types (player inventory, trade, NPC shop, storage vault, personal shop). `CNewUIPickedItem` handles drag-and-drop with 3D item rendering on cursor.
- **Player inventory window:** `CNewUIMyInventory` (`UI/Windows/Inventory/NewUIMyInventory.h/.cpp`) — main inventory UI with 12 equipment slots (helm, armor, gloves, pants, boots, fairy, wing, rings ×2, necklace, weapons ×2), repair button, personal shop toggle, and inventory expansion.
- **Item data structures:** `ITEM` struct in `Core/mu_struct.h` — comprehensive item representation with Type, Level, Durability, Options, Sockets (up to `MAX_SOCKETS`), Harmony, Set bonuses, Period items. `ITEM_ATTRIBUTE` in `Data/Items/ItemStructs.h` with runtime wide-char names, plus `ITEM_ATTRIBUTE_FILE` (50-byte) and `ITEM_ATTRIBUTE_FILE_LEGACY` (30-byte, S6E3 compat) for file I/O.
- **Item management:** `CNewUIItemMng` (`UI/Framework/NewUIItemMng.h/.cpp`) creates items from network packets via `CreateItem()`, `CreateItemExtended()`, with `ItemCreationParams` config struct.
- **Trading system:** `CNewUITrade` (`UI/Windows/Commerce/NewUITrade.h/.cpp`) — dual inventory display (my items + their items), trade confirmation flags (`m_bMyConfirm`, `m_bYourConfirm`), gold/zen input, 8×4=32 slot trade grid, backup array `m_aYourInvenBackUp[MAX_TRADE_INVEN]`.
- **NPC shop:** `CNewUINPCShop` (`UI/Windows/Commerce/NewUINPCShop.h/.cpp`) — dual-mode (`SHOP_STATE_BUYNSELL`, `SHOP_STATE_REPAIR`), tax rate handling, repair all button, grid-based item display.
- **Personal shop:** `CNewUIMyShopInventory` (`UI/Windows/Inventory/NewUIMyShopInventory.h/.cpp`) — player vendor with sale/purchase modes (`PERSONALSHOPSALE`, `PERSONALSHOPPURCHASE`), title editing. `PersonalShopTitleImp.h/.cpp` in `Gameplay/Items/` for title storage.
- **Storage vault:** `CNewUIStorageInventory` (`UI/Windows/Inventory/NewUIStorageInventory.h/.cpp`) — vault with deposit/withdraw zen, lock/password system, auto-move.
- **Purchase shop:** `CNewUIPurchaseShopInventory` (`UI/Windows/Inventory/NewUIPurchaseShopInventory.h/.cpp`) — browsing another player's personal shop.
- **Item tooltips:** `CNewUIItemExplanationWindow` (`UI/Framework/NewUIItemExplanationWindow.h/.cpp`) — item detail popup. `NewUISetItemExplanation.h/.cpp` for set bonuses. `NewUIItemEnduranceInfo.h/.cpp` for durability info.
- **Item mix/crafting:** `CNewUIMixInventory` (`UI/Windows/Inventory/NewUIMixInventory.h/.cpp`) — crafting with `MIX_READY`/`MIX_REQUESTED`/`MIX_FINISHED` states.
- **Item options:** `CSItemOption` (`Gameplay/Items/CSItemOption.h/.cpp`) — item combat bonuses, set options. Already tested in 6-2-1 (reuse constants, verify no regression).
- **Network packets:** `WSclient.h` defines `MAX_CHAT_SIZE=90`, `PACKET_ITEM_LENGTH_EXTENDED_MIN/MAX`, personal shop packet structs (`tagGETPSHOPITEMLIST_HEADER`, `tagGETPSHOPITEM_DATA`, `tagPURCHASEITEM_RESULT`, `tagSOLDITEM_RESULT`).

### Key Source Files

| File | Purpose |
|------|---------|
| `src/source/UI/Framework/NewUIInventoryCtrl.h/.cpp` | Grid-based inventory controller, drag-and-drop, tooltip types |
| `src/source/UI/Framework/NewUIItemMng.h/.cpp` | Item instance creation from packets |
| `src/source/UI/Framework/NewUIItemExplanationWindow.h/.cpp` | Item tooltip/explanation display |
| `src/source/UI/Windows/Inventory/NewUIMyInventory.h/.cpp` | Player inventory window with equipment slots |
| `src/source/UI/Windows/Commerce/NewUITrade.h/.cpp` | Player-to-player trade window |
| `src/source/UI/Windows/Commerce/NewUINPCShop.h/.cpp` | NPC shop (buy/sell/repair) |
| `src/source/UI/Windows/Inventory/NewUIMyShopInventory.h/.cpp` | Personal shop (vendor) |
| `src/source/UI/Windows/Inventory/NewUIStorageInventory.h/.cpp` | Storage vault |
| `src/source/UI/Windows/Inventory/NewUIPurchaseShopInventory.h/.cpp` | Browse other player's shop |
| `src/source/UI/Windows/Inventory/NewUIMixInventory.h/.cpp` | Item crafting/mixing |
| `src/source/Core/mu_struct.h` | `ITEM` struct, item data structures |
| `src/source/Data/Items/ItemStructs.h` | `ITEM_ATTRIBUTE`, `ITEM_ATTRIBUTE_FILE`, `ITEM_ATTRIBUTE_FILE_LEGACY` |
| `src/source/Gameplay/Items/CSItemOption.h/.cpp` | Item set/combat bonus options |
| `src/source/Gameplay/Items/PersonalShopTitleImp.h/.cpp` | Personal shop title management |
| `src/source/Gameplay/Items/ZzzInventory.h` | `GetAttackDamage()`, inventory utility functions |
| `src/source/Network/WSclient.h` | Packet constants, personal shop packet structs |
| `src/source/Dotnet/PacketFunctions_ClientToServer.h` | Item/trade network packets (NEVER EDIT — generated) |

### Risk Items

- **R17 (from sprint-status):** All EPIC-6 stories require a running MU Online server for manual validation. Ensure test server is available before starting manual test tasks.
- **R17 Mitigation Strategy:** Same two-tier strategy as 6-2-1: (1) Automated Catch2 component tests validate data structures, enum integrity, constant correctness without server dependency; (2) Manual test scenarios document full end-to-end validation for when server + platform builds are available.
- **Inventory system complexity:** The inventory system spans many windows (MyInventory, Trade, NPCShop, PersonalShop, Storage, PurchaseShop, MixInventory) all sharing `CNewUIInventoryCtrl` as the base grid control. Component tests should focus on shared data structures and enums rather than attempting to test tightly-coupled UI rendering behavior.
- **Generated packet files:** `PacketFunctions_ClientToServer.h/.cpp` and `PacketBindings_*.h` are XSLT-generated — NEVER edit these files.
- **CSItemOption reuse:** Constants like `MAX_SET_OPTION`, `MASTERY_OPTION`, `MAX_EQUIPPED_SETS` were tested in 6-2-1. This story should verify no regression and extend coverage to item inventory-specific option types.

### PCC Project Constraints

- **Prohibited:** No raw `new`/`delete`, no `NULL`, no `timeGetTime()`, no `#ifdef _WIN32` in game logic, no `wchar_t` in new serialization
- **Required:** `std::unique_ptr`, `nullptr`, `std::chrono::steady_clock`, `std::filesystem::path`, `#pragma once`, Allman braces, 4-space indent
- **Quality gate:** `./ctl check` (clang-format 21.1.8 + cppcheck) — must pass 0 errors
- **Test organization:** `tests/{module}/test_{name}.cpp` mirroring `src/source/{Module}/`
- **References:** `_bmad-output/project-context.md`, `docs/development-standards.md`

### Project Structure Notes

- Tests go in `MuMain/tests/` — e.g., `tests/gameplay/test_inventory_trading_validation.cpp`
- Test binary: `MuTests` target, linked against `MUCore` (and potentially `MUGame` for gameplay logic)
- `MUCore` uses `file(GLOB)` — new `.cpp` files auto-discovered
- For UI-level tests involving inventory controls, may need `#ifdef MU_GAME_AVAILABLE` compile-time guard (consistent with 6-1-2, 6-2-1 patterns)
- Previous stories (6-1-1, 6-1-2, 6-2-1) established pattern: Catch2 `TEST_CASE` / `SECTION` structure, component-level testing of data structures and enums without server dependency

### Dependency Context

This story depends on **6-1-1-auth-character-validation** (done) — player must be logged in and have a character to use inventory/trading/shops. It is a **parallel track** (Track C) that does NOT block other stories.

Previous stories established:
- 6-1-1: Catch2 test patterns for scene state validation, quality gate workflow
- 6-1-2: `#ifdef MU_GAME_AVAILABLE` compile-time guard pattern, boundary condition testing
- 6-2-1: Combat data structure validation (34 TEST_CASEs), `CSItemOption` constants testing, non-aliasing proof pattern, pairwise uniqueness checks

### Previous Story Intelligence

From 6-2-1 code review learnings:
- Use `#ifdef MU_GAME_AVAILABLE` compile-time guard when test code references MUGame-only types
- Avoid parameter documentation mismatches in test comments
- Add boundary condition tests (not just happy-path)
- Clearly distinguish component tests (automated, no server) from end-to-end tests (manual, server required)
- Keep ATDD checklist synchronized with actual test implementation
- Use `static_assert` for struct layout validation where possible
- Pairwise uniqueness checks for enum values (established in 6-2-1 DemendConditionInfo tests)

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
