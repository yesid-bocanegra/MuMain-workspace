# Test Scenarios: Story 6.2.2 — Inventory, Trading & Shops Validation

**Story ID:** 6.2.2
**Epic:** 6 — Cross-Platform Gameplay Validation
**Flow Code:** VS1-GAME-VALIDATE-ECONOMY
**Date:** 2026-03-21
**Test Type:** Manual + Catch2 Unit

---

## Overview

This document defines the complete test plan for validating that inventory management,
player-to-player trading, and NPC shops work correctly on macOS, Linux, and Windows.

Automated Catch2 tests cover pure data structure and constant validation:
inventory grid dimensions, item array sizes, equipment slot counts, storage type enums,
ITEM_ATTRIBUTE struct layouts, NPC shop state enums, and CSItemOption regression checks.

Platform rendering, server-interaction, and UI behavior tests are manual-only.

**Prerequisites:**
- Running MU Online test server (live game required for AC-1..6 full validation)
- macOS build: `cmake --preset macos-arm64 && cmake --build --preset macos-arm64-debug`
- Linux build: MinGW cross-compile or native Linux build
- Windows build: `cmake --preset windows-x64 && cmake --build --preset windows-x64-debug`

> **Risk R17:** All full AC-1..6 scenarios require a running MU Online server for actual
> in-game validation. Catch2 tests cover server-independent component logic only.

---

## Automated Test Coverage (Catch2)

Run: `cmake -S MuMain -B build -DBUILD_TESTING=ON && cmake --build build && ctest --test-dir build`

| Test Case | AC | Verifies |
|-----------|-----|----------|
| Inventory grid constants (COLUMN_INVENTORY=8, ROW_INVENTORY=8, MAX_INVENTORY=64) | AC-1 | Grid layout invariant |
| Extended inventory row (ROW_INVENTORY_EXT=4, MAX_INVENTORY_EXT_ONE=32) | AC-1 | Extended slot count |
| ITEM array dimensions (MAX_ITEM_SPECIAL=8, MAX_SOCKETS=5) | AC-1 | Struct array sizes |
| Equipment slot constants (MAX_EQUIPMENT=12, MAX_MY_INVENTORY_INDEX=76) | AC-2 | Slot count and total index range |
| CSItemOption set-equip derived constants (MAX_EQUIPPED_SET_ITEMS=10, MAX_EQUIPPED_SETS=5) | AC-2 | Set-bonus slot eligibility |
| EQUIPMENT_LENGTH_EXTENDED=25 (MU_GAME_AVAILABLE) | AC-2 | Packet struct sizing |
| STORAGE_TYPE enum (INVENTORY=0, TRADE=1, VAULT=2, MYSHOP=4, UNDEFINED=-1) | AC-3 | Drag-and-drop source resolution |
| STORAGE_TYPE pairwise distinctness (10 pairs) | AC-3 | No value aliasing in drag-drop |
| TOOLTIP_TYPE enum values 0-5 (MU_GAME_AVAILABLE) | AC-3 | Tooltip rendering mode selection |
| EVENT_PICKING=2 in EVENT_STATE (MU_GAME_AVAILABLE) | AC-3 | Item drag detection state |
| Trade grid invariant: static_assert 8×4=32 | AC-4 | Trade capacity architectural constraint |
| Trade grid col/row match inventory constants | AC-4 | Visual consistency with main inventory |
| PACKET_ITEM_LENGTH_EXTENDED_MIN=5, MAX=15 (MU_GAME_AVAILABLE) | AC-4 | Trade packet parsing bounds |
| MAX_SHOPTITLE=36 | AC-5 | Shop title buffer size |
| SHOP_STATE_BUYNSELL=1, SHOP_STATE_REPAIR=2 (MU_GAME_AVAILABLE) | AC-5 | NPC shop mode selection |
| PERSONALSHOPSALE=0, PERSONALSHOPPURCHASE=1 (MU_GAME_AVAILABLE) | AC-5 | Personal shop display mode |
| MAX_ITEM_NAME=50 | AC-6 | Item name buffer capacity |
| ITEM_ATTRIBUTE_FILE_LEGACY::Name = 30 bytes | AC-6 | S6E3 BMD backward compatibility |
| ITEM_ATTRIBUTE_FILE::Name = 50 bytes | AC-6 | Current BMD format parsing |
| ITEM_ATTRIBUTE::Name = MAX_ITEM_NAME × sizeof(wchar_t) | AC-6 | Runtime wide-char name buffer |
| Legacy Name < Current Name (size comparison) | AC-6 | Migration direction validation |
| CSItemOption constants regression (MAX_SET_OPTION=64, MASTERY_OPTION=24, EXT_A=1, EXT_B=2) | AC-6 | No regression from 6-2-1 |
| EXT_A_SET_OPTION != EXT_B_SET_OPTION | AC-6 | Set identifier uniqueness |

---

## Manual Test Scenarios

### Prerequisites for Manual Tests

All manual scenarios require:
1. Running MU Online test server (local or remote)
2. Valid game client build (macOS, Linux, or Windows)
3. Test character at sufficient level to access all inventory/trading/shop features
4. At least one NPC shop vendor available in the test map

---

### AC-1: Inventory Opens and Displays Items Correctly (120 Slots)

**Objective:** Verify the inventory window renders all slots correctly and displays equipped
and stored items with correct icons and stats on all three platforms.

**Steps:**
1. Log in with test character
2. Press `I` (or inventory hotkey) to open inventory window
3. Verify inventory window opens without visual artifacts
4. Verify the item grid shows 8 columns and multiple rows (base: 8 rows = 64 slots)
5. Pick up items of various types (weapon, armor, consumable)
6. Verify items appear in the correct grid positions with correct icons
7. Hover over each item and verify the tooltip opens with correct item name and stats
8. Verify items occupying multiple grid squares (e.g., 1×2, 2×2) display correctly

**Expected Results:**
- Inventory opens within 500ms
- All 64 base slots (8×8) are visible and clickable
- Item icons render at correct grid positions
- No visual corruption or missing icons
- Tooltips display correct item type, level, stats, and socket info

**Platforms:** macOS, Linux, Windows
**Risk R17:** Requires live server

---

### AC-2: Equip/Unequip Items to Character Model

**Objective:** Verify that equipping an item updates the character model visually and
correctly reflects the item in the equipment slot panel.

**Steps:**
1. Open inventory (from AC-1 pass)
2. Left-click a weapon in inventory to pick it up
3. Drag to the right-hand weapon slot in the equipment panel and drop
4. Verify the weapon appears in the equipment slot with correct icon
5. Verify the character model updates to display the equipped weapon
6. Unequip by dragging the weapon back to inventory
7. Verify the equipment slot is now empty and character model updates
8. Repeat for armor, helm, gloves, pants, boots, ring, necklace

**Expected Results:**
- Equipment slots (12 total) each accept correct item types
- Character model updates immediately on equip/unequip
- Stat panel reflects bonus from equipped items (attack power, defense, etc.)
- No crash or freeze on equip/unequip

**Platforms:** macOS, Linux, Windows
**Risk R17:** Requires live server

---

### AC-3: Drag-and-Drop Item Movement Within Inventory

**Objective:** Verify that items can be freely moved between inventory slots using
drag-and-drop without data loss or visual glitches.

**Steps:**
1. Open inventory
2. Left-click and hold on an item to enter drag state (EVENT_PICKING)
3. Drag to an empty slot and release
4. Verify item appears in the new slot and the source slot is empty
5. Drag a 2×2 item to verify multi-slot occupancy updates correctly
6. Drag an item over an occupied slot
7. Verify item swap occurs (target moves to source position)
8. Drag an item to an invalid position (out of bounds)
9. Verify item returns to original position gracefully

**Expected Results:**
- Item drag visual follows cursor position
- Drop on empty slot: item moves, source clears
- Drop on occupied slot: items swap positions
- Drop on invalid position: item returns to source, no data loss
- No item duplication or disappearance

**Platforms:** macOS, Linux, Windows
**Risk R17:** Requires live server

---

### AC-4: Player-to-Player Trade Window Works

**Objective:** Verify that two players can open a trade session, add items and zen,
confirm the trade, and receive the correct items.

**Steps:**
1. Position two test accounts near each other
2. Right-click the other player → select "Request Trade"
3. Verify trade window opens for both players (dual 8×4 grid layout = 32 slots each)
4. Player A: drag 3 items into the trade grid
5. Verify Player B sees Player A's items appear in the upper trade panel
6. Player B: add zen amount in the zen input field
7. Player A: click the confirmation button
8. Verify both players' confirmation checkmarks appear
9. Player B: click confirmation
10. Verify trade completes: Player A receives zen, Player B receives items
11. Test trade cancel: Player A presses close button mid-trade
12. Verify both players' trade windows close and all items return to owners

**Expected Results:**
- Trade window opens within 2 seconds of request acceptance
- 8×4 grid (32 slots) visible for both my items and partner's items
- Real-time sync: item additions visible to both players within 1 second
- Trade confirmation requires both players to confirm
- Successful trade: correct items and zen transferred
- Cancelled trade: all items and zen returned to original owners

**Platforms:** macOS, Linux, Windows
**Risk R17:** Requires live server with two connected clients

---

### AC-5: NPC Shop Buy/Sell Works

**Objective:** Verify that the NPC shop opens in buy/sell mode, allows purchasing and
selling items, and applies correct tax rates. Also verify repair mode functions.

**Steps (Buy/Sell Mode):**
1. Walk to an NPC shop vendor
2. Click NPC → select "Open Shop"
3. Verify shop opens in BUYNSELL mode (item grid visible)
4. Click an item in the shop grid
5. Verify tooltip shows item stats and price (with tax)
6. Click "Buy" button
7. Verify item appears in player inventory, zen deducted
8. Drag an item from player inventory to the sell panel
9. Verify zen added to player account
10. Verify sold item removed from inventory

**Steps (Repair Mode):**
1. Damage some equipped items (fight monsters)
2. Open NPC shop → click "Repair" tab
3. Verify shop switches to SHOP_STATE_REPAIR mode (repair grid visible)
4. Click "Repair All" button
5. Verify all items restored to full durability, zen deducted

**Expected Results:**
- Shop opens in buy/sell mode by default
- Items display with correct prices (base price + tax rate)
- Purchase: zen deducted, item added to inventory
- Sell: zen added, item removed from inventory
- Repair mode switch: UI changes correctly, no visual corruption
- Repair all: all durability bars full after operation

**Platforms:** macOS, Linux, Windows
**Risk R17:** Requires live server with NPC shop vendor

---

### AC-6: Item Tooltips Display Correctly

**Objective:** Verify that item tooltips display correct stats, set bonuses, socket
information, and period item expiry for various item types.

**Steps:**
1. Open inventory
2. Hover over a basic weapon → verify tooltip shows name, type, damage min/max, required stats
3. Hover over an ancient set item → verify set bonus information appears
4. Hover over a socketed item (sockets filled) → verify socket options listed
5. Hover over a period item → verify expiry time displayed
6. Hover over an NPC shop item → verify price and "NPC shop" tooltip style
7. Open personal shop → hover over listed items → verify price and stats
8. In trade window → hover over partner's item → verify stats visible

**Expected Results:**
- All tooltip types (INVENTORY, NPC_SHOP, MY_SHOP, PURCHASE_SHOP) display correctly
- Stat values match actual item data (no truncation or corruption)
- Set bonus text appears only for ancient items with matching set equipped
- Socket options listed correctly (up to 5 socket slots)
- Period item expiry time formatted correctly
- No tooltip flickering or z-order issues

**Platforms:** macOS, Linux, Windows
**Risk R17:** Requires live server to load item data from server

---

## Test Coverage Summary

| AC | Component Tests (Automated) | Manual Tests |
|----|----------------------------|--------------|
| AC-1 | Inventory grid constants, ITEM array dimensions | Visual rendering, 120-slot display |
| AC-2 | MAX_EQUIPMENT=12, EQUIPMENT_LENGTH_EXTENDED=25 | Equip/unequip UX, model update |
| AC-3 | STORAGE_TYPE values, TOOLTIP_TYPE, EVENT_PICKING | Drag-and-drop flow, swap behavior |
| AC-4 | Trade grid 8×4=32, packet length constants | Two-player trade session end-to-end |
| AC-5 | MAX_SHOPTITLE=36, SHOP_STATE enums, personal shop modes | Buy/sell/repair with live NPC |
| AC-6 | ITEM_ATTRIBUTE struct layouts, CSItemOption regression | Tooltip rendering with all item types |

---

## Regression Checklist

After completing all manual tests, verify no regression on Windows (baseline platform):

- [ ] Inventory opens and closes without crash on Windows
- [ ] Trade session completes successfully on Windows (same as Linux/macOS)
- [ ] NPC shop buy/sell behaves identically across all three platforms
- [ ] Tooltip content matches between Windows and macOS/Linux (no locale differences)
- [ ] CSItemOption set bonuses display identically on all platforms
