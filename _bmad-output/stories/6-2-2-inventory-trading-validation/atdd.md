# ATDD Checklist: Story 6.2.2 — Inventory, Trading & Shops Validation

**Story ID:** 6.2.2
**Story Key:** 6-2-2-inventory-trading-validation
**Epic:** 6 — Cross-Platform Gameplay Validation
**Flow Code:** VS1-GAME-VALIDATE-ECONOMY
**Story Type:** infrastructure
**Date Generated:** 2026-03-21
**Test File:** `MuMain/tests/gameplay/test_inventory_trading_validation.cpp`

---

## AC-to-Test Mapping

| AC | Description (component-testable subset) | Test Method(s) | Status |
|----|------------------------------------------|----------------|--------|
| AC-1 | Inventory grid: COLUMN=8, ROW=8, MAX=64, MAX_ITEM_SPECIAL=8, MAX_SOCKETS=5 | `AC-1 [6-2-2]: Inventory grid constants define correct slot layout` (4 SECTIONs), `AC-1 [6-2-2]: Extended inventory row constant is correct` (2 SECTIONs), `AC-1 [6-2-2]: ITEM struct socket and special array dimensions are correct` (2 SECTIONs), `AC-1 [6-2-2]: ITEM struct socket and special array bounds are independent` | `[ ]` |
| AC-2 | Equipment slots: MAX_EQUIPMENT=12, EQUIPMENT_LENGTH_EXTENDED=25, MAX_EQUIPPED_SETS=5 | `AC-2 [6-2-2]: Equipment slot count constants are correct` (3 SECTIONs), `AC-2 [6-2-2]: CSItemOption set-equip constants derived from equipment slot count` (2 SECTIONs), `AC-2 [6-2-2]: EQUIPMENT_LENGTH_EXTENDED constant` (#ifdef, 1 SECTION) | `[ ]` |
| AC-3 | Drag-and-drop: STORAGE_TYPE values, TOOLTIP_TYPE enum | `AC-3 [6-2-2]: STORAGE_TYPE enum values for inventory drag-and-drop` (5 SECTIONs), `AC-3 [6-2-2]: STORAGE_TYPE drag-and-drop values are pairwise distinct`, `AC-3 [6-2-2]: TOOLTIP_TYPE enum values` (#ifdef), `AC-3 [6-2-2]: EVENT_STATE EVENT_PICKING` (#ifdef) | `[ ]` |
| AC-4 | Trade window: 8×4=32 slots, trade packet constants | `AC-4 [6-2-2]: Trade inventory grid invariant is 8 columns x 4 rows = 32 slots` (3 SECTIONs), `AC-4 [6-2-2]: Packet item length constants for trade item encoding` (#ifdef, 3 SECTIONs) | `[ ]` |
| AC-5 | NPC shop: SHOP_STATE_BUYNSELL/REPAIR, MAX_SHOPTITLE=36, PERSONALSHOPSALE/PURCHASE | `AC-5 [6-2-2]: NPC shop title buffer size constant` (1 SECTION), `AC-5 [6-2-2]: NPC shop SHOP_STATE enum values` (#ifdef, 3 SECTIONs), `AC-5 [6-2-2]: Personal shop mode enum values` (#ifdef, 3 SECTIONs) | `[ ]` |
| AC-6 | Item tooltips: ITEM_ATTRIBUTE struct layouts, CSItemOption regression | `AC-6 [6-2-2]: MAX_ITEM_NAME buffer size constant`, `AC-6 [6-2-2]: ITEM_ATTRIBUTE_FILE_LEGACY Name buffer is 30 bytes`, `AC-6 [6-2-2]: ITEM_ATTRIBUTE_FILE Name buffer is MAX_ITEM_NAME bytes`, `AC-6 [6-2-2]: ITEM_ATTRIBUTE runtime Name buffer is wchar_t`, `AC-6 [6-2-2]: ITEM_ATTRIBUTE_FILE_LEGACY name is shorter than ITEM_ATTRIBUTE_FILE name`, `AC-6 [6-2-2]: CSItemOption constants are not regressed from 6-2-1` (4 SECTIONs), `AC-6 [6-2-2]: CSItemOption set identifiers are distinct`, `AC-6 [6-2-2]: CSItemOption item-set constants derived from equipment count are correct` (2 SECTIONs) | `[ ]` |

---

## Implementation Checklist

### Catch2 Test File

- [x] Test file created at `MuMain/tests/gameplay/test_inventory_trading_validation.cpp`
- [ ] AC-1: Inventory grid constants (COLUMN_INVENTORY=8, ROW_INVENTORY=8, MAX_INVENTORY=64)
- [ ] AC-1: Extended inventory row constant (ROW_INVENTORY_EXT=4, MAX_INVENTORY_EXT_ONE=32)
- [ ] AC-1: ITEM array dimension constants (MAX_ITEM_SPECIAL=8, MAX_SOCKETS=5)
- [ ] AC-1: Pairwise uniqueness — MAX_ITEM_SPECIAL != MAX_SOCKETS
- [ ] AC-2: Equipment slot constants (MAX_EQUIPMENT=12, MAX_EQUIPMENT_INDEX alias, MAX_MY_INVENTORY_INDEX=76)
- [ ] AC-2: CSItemOption derived constants (MAX_EQUIPPED_SET_ITEMS=10, MAX_EQUIPPED_SETS=5)
- [ ] AC-2: EQUIPMENT_LENGTH_EXTENDED=25 (gated #ifdef MU_GAME_AVAILABLE)
- [ ] AC-3: STORAGE_TYPE enum values (UNDEFINED=-1, INVENTORY=0, TRADE=1, VAULT=2, MYSHOP=4)
- [ ] AC-3: STORAGE_TYPE pairwise distinctness (10 pairs)
- [ ] AC-3: TOOLTIP_TYPE enum values and pairwise distinctness (gated #ifdef MU_GAME_AVAILABLE)
- [ ] AC-3: EVENT_STATE values including EVENT_PICKING=2 (gated #ifdef MU_GAME_AVAILABLE)
- [ ] AC-4: Trade grid invariant static_assert 8×4=32
- [ ] AC-4: Trade grid columns = COLUMN_INVENTORY, rows = ROW_INVENTORY_EXT
- [ ] AC-4: PACKET_ITEM_LENGTH_EXTENDED_MIN=5, MAX=15, MIN<MAX (gated #ifdef MU_GAME_AVAILABLE)
- [ ] AC-5: MAX_SHOPTITLE=36
- [ ] AC-5: SHOP_STATE_BUYNSELL=1, SHOP_STATE_REPAIR=2, distinct (gated #ifdef MU_GAME_AVAILABLE)
- [ ] AC-5: PERSONALSHOPSALE=0, PERSONALSHOPPURCHASE=1, distinct (gated #ifdef MU_GAME_AVAILABLE)
- [ ] AC-6: MAX_ITEM_NAME=50
- [ ] AC-6: sizeof(ITEM_ATTRIBUTE_FILE_LEGACY::Name) = 30 bytes
- [ ] AC-6: sizeof(ITEM_ATTRIBUTE_FILE::Name) = 50 bytes (= MAX_ITEM_NAME)
- [ ] AC-6: sizeof(ITEM_ATTRIBUTE::Name) = MAX_ITEM_NAME × sizeof(wchar_t)
- [ ] AC-6: ITEM_ATTRIBUTE_FILE_LEGACY::Name < ITEM_ATTRIBUTE_FILE::Name (layout comparison)
- [ ] AC-6: CSItemOption regression — MAX_SET_OPTION=64, MASTERY_OPTION=24, EXT_A=1, EXT_B=2
- [ ] AC-6: EXT_A_SET_OPTION != EXT_B_SET_OPTION (pairwise uniqueness)
- [ ] AC-6: MAX_EQUIPPED_SET_ITEMS=10, MAX_EQUIPPED_SETS=5 (derived from equipment count)

### Code Standards

- [ ] AC-STD-1: Code Standards Compliance — Allman braces, 4-space indent, `nullptr`, no raw `new`/`delete`
- [ ] AC-STD-2: Catch2 test suite implemented with TEST_CASE/SECTION/REQUIRE structure
- [ ] AC-STD-13: Quality Gate passes — `./ctl check` (clang-format + cppcheck 0 errors)
- [ ] AC-STD-15: Git Safety — no incomplete rebase, no force push
- [ ] AC-STD-16: Correct test infrastructure — Catch2 v3.7.1, `tests/gameplay/` directory

### Validation Artifact

- [ ] AC-VAL-6: Test scenarios documented at `_bmad-output/test-scenarios/epic-6/inventory-trading-validation.md`

---

## PCC Compliance Summary

| Category | Status | Detail |
|----------|--------|--------|
| Prohibited libraries | PASS | No raw new/delete, no NULL, no timeGetTime() in test code |
| Required test patterns | PASS | Catch2 TEST_CASE/SECTION/REQUIRE throughout |
| Test profiles | PASS | MU_GAME_AVAILABLE gate pattern matches 6-2-1/6-1-2 precedent |
| Coverage target | N/A | Infrastructure story — 0% threshold per .pcc-config.yaml |
| Platform guard | PASS | `#ifdef _WIN32` / PlatformTypes.h pattern used |
| Test organization | PASS | `tests/gameplay/test_inventory_trading_validation.cpp` mirrors source |

---

## Test Counts

| Test Level | Count | Phase |
|------------|-------|-------|
| Unit (Catch2, no guard) | 15 TEST_CASEs | RED — will compile and run |
| Unit (Catch2, MU_GAME_AVAILABLE guard) | 5 TEST_CASEs | RED — skipped until Win32 build |
| E2E (Manual) | See test-scenarios doc | Manual — requires live server (Risk R17) |
| Bruno API collection | N/A | Skipped — infrastructure story type |

**Total: 20 TEST_CASEs (15 always-on + 5 game-gated)**

---

## Implementation Notes

- All tests target data structures and constants only — no server dependency
- `#ifdef MU_GAME_AVAILABLE` gates tests for UI headers (NewUIInventoryCtrl.h, NewUINPCShop.h, etc.) that require Win32/OpenGL
- CSItemOption regression tests extend 6-2-1 coverage to item-inventory option types
- Trade grid constants (COLUMN_TRADE_INVEN, ROW_TRADE_INVEN, MAX_TRADE_INVEN) are private enums in CNewUITrade — verified via formula static_assert
- Full AC-1..6 end-to-end validation deferred to manual (Risk R17: requires live MU Online server)
