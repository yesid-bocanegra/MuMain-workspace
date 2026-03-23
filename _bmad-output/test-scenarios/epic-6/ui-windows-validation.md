# Test Scenarios: Story 6.4.1 — UI Windows Comprehensive Validation

**Story ID:** 6.4.1
**Epic:** 6 — Cross-Platform Gameplay Validation
**Flow Code:** VS1-GAME-VALIDATE-UI
**Date:** 2026-03-23
**Test Type:** Manual + Catch2 Component

---

## Overview

This document defines the complete test plan for validating that all 84+ CNewUI* UI windows
open, display, and function correctly on macOS, Linux, and Windows after the SDL3
cross-platform migration.

Automated Catch2 tests cover pure data structure and constant validation:
INTERFACE_LIST enum boundary/count/pairwise-distinctness (84+ window IDs), INTERFACE_3DRENDERING
camera range (25 slots), SSIM comparison infrastructure for 190x429 inventory and 320x240
minimap ground truth buffers, CNewUIObj class hierarchy (abstract base, Show/Enable state
transitions, GetKeyEventOrder=3.0f), INVENTORY_SQUARE_WIDTH/HEIGHT=20, CNewUIMiniMap::MASTER_DATA
skill icon geometry, TOOLTIP_TYPE enum (6 values distinct), BUTTON_STATE enum (UP=0/DOWN=1/OVER=2),
RADIOGROUPEVENT_NONE=-1, and SQUARE_COLOR_STATE enum (3 values distinct).

Platform rendering, server-interaction, and live UI behavior tests are manual-only.

**Prerequisites:**
- Running MU Online test server (required for all full-game AC validation)
- macOS build: `cmake --preset macos-arm64 && cmake --build --preset macos-arm64-debug`
- Linux build: MinGW cross-compile or `cmake --preset linux-x64 && cmake --build --preset linux-x64-debug`
- Windows build: `cmake --preset windows-x64 && cmake --build --preset windows-x64-debug`

> **Risk R17:** All full UI window scenarios require a running MU Online server for actual
> in-game validation. Catch2 tests cover server-independent component logic only.
> **Risk R18:** 84 windows scope — prioritize critical windows: inventory, character, skills,
> chat, minimap. Use the 10-category checklist approach for systematic coverage.

---

## Automated Test Coverage (Catch2)

Run: `cmake -S MuMain -B build -DBUILD_TESTING=ON && cmake --build build && ctest --test-dir build`

| Test Case | AC | Verifies |
|-----------|-----|----------|
| INTERFACE_BEGIN=0x00, INTERFACE_COUNT>=84, INTERFACE_END=COUNT+2 | AC-4 | Enum boundary values and 84+ window coverage |
| INTERFACE_3DRENDERING_CAMERA_END == BEGIN+24, BEGIN>0 | AC-4 | 3D camera range spans 25 slots |
| Core HUD 12 IDs (MAINFRAME, INVENTORY, CHARACTER, CHATINPUTBOX, CHATLOGWINDOW, MINI_MAP, SKILL_LIST, BUFF_WINDOW, OPTION, WINDOW_MENU, HELP, NAME_WINDOW) pairwise distinct | AC-4 | HUD and core window ID uniqueness |
| Inventory/Commerce 12 IDs pairwise distinct | AC-4 | Inventory and commerce ID uniqueness |
| Social 6 IDs pairwise distinct | AC-4 | Social window ID uniqueness |
| Castle 6 IDs pairwise distinct | AC-4 | Castle window ID uniqueness |
| Event 19 IDs pairwise distinct | AC-4 | Event window ID uniqueness |
| Quest 4 IDs pairwise distinct, MuHelper 3 IDs pairwise distinct | AC-4 | Quest and MuHelper ID uniqueness |
| 5 key SSIM window IDs pairwise distinct and in (BEGIN, END) range | AC-5 | SSIM key window ID validity |
| Identical 190x429 inventory buffers SSIM >= 0.99 | AC-5 | SSIM infrastructure sensitivity |
| Black vs white 190x429 buffers SSIM < 0.5 | AC-5 | SSIM perceptual difference detection |
| Identical 320x240 minimap buffers SSIM >= 0.99 | AC-5 | SSIM minimap infrastructure |
| INewUIBase is abstract (MU_GAME_AVAILABLE) | AC-1 | Interface is pure-virtual |
| CNewUIObj derives from INewUIBase, is abstract (MU_GAME_AVAILABLE) | AC-1 | Abstract base hierarchy |
| TestUIWindow defaults visible=true, enabled=true; Show/Enable transitions (MU_GAME_AVAILABLE) | AC-1 | Default state and mutators |
| INVENTORY_SQUARE_WIDTH=20, HEIGHT=20, WIDTH==HEIGHT (MU_GAME_AVAILABLE) | AC-2 | Inventory grid cell dimensions |
| SKILL_ICON_DATA_WDITH=4, DATA_HEIGHT=8, WIDTH=20, HEIGHT=28, STARTX1>0, STARTY1>0 (MU_GAME_AVAILABLE) | AC-2 | MiniMap MASTER_DATA constants |
| UNKNOWN_TOOLTIP_TYPE=0, 6 TOOLTIP_TYPE values pairwise distinct (MU_GAME_AVAILABLE) | AC-2 | Tooltip display context enum |
| BUTTON_STATE_UP=0, DOWN=1, OVER=2, all 3 pairwise distinct (MU_GAME_AVAILABLE) | AC-3 | Button visual state enum |
| RADIOGROUPEVENT_NONE=-1 (MU_GAME_AVAILABLE) | AC-3 | Radio group event sentinel |
| UNKNOWN_COLOR_STATE=0, NORMAL>UNKNOWN, WARNING>NORMAL, 3 pairwise distinct (MU_GAME_AVAILABLE) | AC-3 | Inventory slot color state enum |

---

## Window Inventory: All 84+ CNewUI* Classes by Category

### Category 1: Framework / Base (~25 classes — not registered as windows, used by all)

| Class | Role | Notes |
|-------|------|-------|
| `CNewUIObj` | Abstract base — all windows derive from this | `NewUIBase.h` |
| `INewUIBase` | Pure-virtual interface | `NewUIBase.h` |
| `CNewUIBaseButton` | Button base | `NewUIButton.h` |
| `CNewUIButton` | Standard clickable button | `NewUIButton.h` |
| `CNewUIImageButton` | Image-mapped button | `NewUIButton.h` |
| `CNewUICheckBox` | Toggle checkbox button | `NewUIButton.h` |
| `CNewUIRadioGroup` | Mutually-exclusive radio group | `NewUIButton.h` |
| `CNewUIScrollBar` | Vertical/horizontal scroll bar | `NewUIScrollBar.h` |
| `CNewUITextBox` | Scrollable text display box | `NewUITextBox.h` |
| `CNewUIInventoryCtrl` | Drag-drop inventory grid control | `NewUIInventoryCtrl.h` |
| `CNewUIGroup` | Layout container / grouping panel | `NewUIGroup.h` |
| `CNewUIGaugebar` | HP/mana gauge progress bar | `NewUIGaugebar.h` |
| `CNewUIMessageBoxBase` | Abstract message box base | `NewUIMessageBox.h` |
| `INewUI3DRenderObj` | 3D render object interface | `NewUI3DRenderMng.h` |
| `CNewUI3DRenderMng` | 3D render object manager | `NewUI3DRenderMng.h` |
| `CNewUICommonMessageBox` | Standard OK/Cancel message box | `NewUICommonMessageBox.h` |
| `CNewUI3DItemCommonMsgBox` | Message box with 3D item preview | `NewUICommonMessageBox.h` |
| `CNewUITextInputMsgBox` | Message box with text input field | `NewUICommonMessageBox.h` |
| `CNewUIKeyPadMsgBox` | Numeric keypad message box | `NewUICommonMessageBox.h` |
| `CNewUIMessageBoxMng` | Message box lifecycle manager | `NewUIMessageBoxMng.h` |

### Category 2: HUD (8 windows)

| Class | INTERFACE_LIST ID | Open Trigger |
|-------|-------------------|--------------|
| `CNewUIMainFrameWindow` | `INTERFACE_MAINFRAME` | Always visible — game HUD frame |
| `CNewUISkillList` | `INTERFACE_SKILL_LIST` | Hotbar — always visible |
| `CNewUICommandWindow` | `INTERFACE_WINDOW_MENU` | Menu button (bottom-right) |
| `CNewUIMoveCommandWindow` | `INTERFACE_MOVE_COMMAND` | Movement command panel |
| `CNewUIQuickCommandWindow` | `INTERFACE_QUICK_COMMAND` | Quick command shortcuts |
| `CNewUIWindowMenu` | `INTERFACE_WINDOW_MENU` | Window toggle menu |
| `CNewUIMiniMap` | `INTERFACE_MINI_MAP` | `M` key or minimap button |
| `CNewUINameWindow` | `INTERFACE_NAME_WINDOW` | Character name / HP bar overlay |

### Category 3: Character (6 windows)

| Class | INTERFACE_LIST ID | Open Trigger |
|-------|-------------------|--------------|
| `CNewUICharacterInfoWindow` | `INTERFACE_CHARACTER` | `C` key |
| `CNewUIMasterLevel` | `INTERFACE_MASTER_LEVEL` | Master level tab in character |
| `CNewUIBuffWindow` | `INTERFACE_BUFF_WINDOW` | Auto-shown on buff receive |
| `CNewUIMuHelper` | `INTERFACE_MUHELPER` | MuHelper icon / hotkey |
| `CNewUIPetInfoWindow` | `INTERFACE_PETINFO` | Pet status icon |
| `CNewUIHeroPositionInfo` | `INTERFACE_HERO_POSITION_INFO` | Hero ranking info |

### Category 4: Inventory (8 windows)

| Class | INTERFACE_LIST ID | Open Trigger |
|-------|-------------------|--------------|
| `CNewUIMyInventory` | `INTERFACE_INVENTORY` | `I` key |
| `CNewUIStorageInventory` | `INTERFACE_STORAGE` | Talk to warehouse keeper NPC |
| `CNewUIStorageInventoryExt` | `INTERFACE_STORAGE_EXT` | Extended warehouse |
| `CNewUIMyShopInventory` | `INTERFACE_MYSHOP_INVENTORY` | Open personal shop |
| `CNewUIPurchaseShopInventory` | `INTERFACE_PURCHASESHOP_INVENTORY` | Browse another player's shop |
| `CNewUIMixInventory` | `INTERFACE_MIXINVENTORY` | Open mix/chaos window |
| `CNewUILuckyItemWnd` | `INTERFACE_LUCKYITEMWND` | Lucky item event window |
| `CNewUIInventoryExtension` | `INTERFACE_INVENTORY_EXT` | Inventory expansion panel |

### Category 5: Commerce (7 windows)

| Class | INTERFACE_LIST ID | Open Trigger |
|-------|-------------------|--------------|
| `CNewUINPCShop` | `INTERFACE_NPCSHOP` | Talk to shop NPC |
| `CNewUITrade` | `INTERFACE_TRADE` | Request trade with player |
| `CNewUINPCQuest` | `INTERFACE_NPCQUEST` | Talk to quest NPC |
| `CNewUINPCDialogue` | `INTERFACE_NPCBREEDER` | Talk to NPC (general dialogue) |
| `CNewUIUnitedMarketPlaceWindow` | `INTERFACE_UNITED_MARKET_PLACE` | Auction house / market |
| `CNewUIExchangeLuckyCoin` | `INTERFACE_EXCHANGE_LUCKYCOIN` | Lucky coin exchange NPC |
| `CNewUIRegistrationLuckyCoin` | `INTERFACE_LUCKYCOIN_REGISTRATION` | Lucky coin registration |

### Category 6: Castle (5 windows)

| Class | INTERFACE_LIST ID | Open Trigger |
|-------|-------------------|--------------|
| `CNewUICastleWindow` | `INTERFACE_SENATUS` | Castle siege management |
| `CNewUIGuardWindow` | `INTERFACE_GUARDSMAN` | Talk to castle guard NPC |
| `CNewUIGatemanWindow` | `INTERFACE_GATEKEEPER` | Talk to gateman NPC |
| `CNewUIGateSwitchWindow` | `INTERFACE_GATESWITCH` | Castle gate control |
| `CNewUICatapultWindow` | `INTERFACE_CATAPULT` | Catapult usage UI |
| `CNewUISiegeWarfareWindow` | `INTERFACE_SIEGEWARFARE` | Siege war info overlay |

### Category 7: Events (19 windows)

| Class | INTERFACE_LIST ID | Open Trigger |
|-------|-------------------|--------------|
| `CNewUIBloodCastle` | `INTERFACE_BLOODCASTLE` | Enter Blood Castle event |
| `CNewUIEnterBloodCastle` | `INTERFACE_BLOODCASTLE_TIME` | Blood Castle entry timer |
| `CNewUIChaosCastleTime` | `INTERFACE_CHAOSCASTLE_TIME` | Chaos Castle countdown |
| `CNewUIEnterDevilSquare` | `INTERFACE_DEVILSQUARE` | Devil Square entry |
| `CNewUICursedTempleNPC` | `INTERFACE_CURSEDTEMPLE_NPC` | Cursed Temple NPC |
| `CNewUICursedTempleSystem` | `INTERFACE_CURSEDTEMPLE_GAMESYSTEM` | Cursed Temple game system |
| `CNewUICursedTempleResult` | `INTERFACE_CURSEDTEMPLE_RESULT` | Cursed Temple result |
| `CNewUIDoppelGangerNPC` | `INTERFACE_DOPPELGANGER_NPC` | Doppelganger NPC |
| `CNewUIDoppelGangerFrame` | `INTERFACE_DOPPELGANGER_FRAME` | Doppelganger frame UI |
| `CNewUIEmpireGuardianNPC` | `INTERFACE_EMPIREGUARDIAN_NPC` | Empire Guardian NPC |
| `CNewUIEmpireGuardianTimer` | `INTERFACE_EMPIREGUARDIAN_TIMER` | Empire Guardian countdown |
| `CNewUIDuelWindow` | `INTERFACE_DUEL_WINDOW` | PvP duel challenge/status |
| `CNewUIDuelWatchWindow` | `INTERFACE_DUELWATCH` | Duel spectate main frame |
| `CNewUIDuelWatchMainFrame` | `INTERFACE_DUELWATCH_MAINFRAME` | Duel spectate frame |
| `CNewUIDuelWatchUserList` | `INTERFACE_DUELWATCH_USERLIST` | Duel spectate user list |
| `CNewUISiegeWarWindow` | `INTERFACE_SIEGEWARFARE` | Siege war participation |
| `CNewUIKanturu2ndEnterNPC` | `INTERFACE_KANTURU2ND_ENTERNPC` | Kanturu 2nd NPC entry |
| `CNewUIKanturuInfo` | `INTERFACE_KANTURU_INFO` | Kanturu event info |
| `CNewUICryWolf` | `INTERFACE_CRYWOLF` | Crywolf event UI |
| `CNewUIBattleSoccerScore` | `INTERFACE_BATTLE_SOCCER_SCORE` | Battle soccer scoreboard |

### Category 8: Quest (3 windows)

| Class | INTERFACE_LIST ID | Open Trigger |
|-------|-------------------|--------------|
| `CNewUIQuestProgress` | `INTERFACE_QUEST_PROGRESS` | Active quest tracker |
| `CNewUIQuestProgressByEtc` | `INTERFACE_QUEST_PROGRESS_ETC` | Secondary quest progress |
| `CNewUIMyQuestInfoWindow` | `INTERFACE_MYQUEST` | Quest log / history |
| `CNewUINPCQuestWindow` | `INTERFACE_NPCQUEST` | NPC quest dialogue |

### Category 9: Social (6 windows)

| Class | INTERFACE_LIST ID | Open Trigger |
|-------|-------------------|--------------|
| `CNewUIPartyListWindow` | `INTERFACE_PARTY` | `P` key or party button |
| `CNewUIPartyInfoWindow` | `INTERFACE_PARTY_INFO_WINDOW` | Party member details |
| `CNewUIFriendWindow` | `INTERFACE_FRIEND` | Friend list icon |
| `CNewUIGuildMakeWindow` | `INTERFACE_NPCGUILDMASTER` | Talk to guild master NPC |
| `CNewUIGuildInfoWindow` | `INTERFACE_GUILDINFO` | Guild info panel |
| `CNewUIGensRanking` | `INTERFACE_GENSRANKING` | Gens faction ranking |

### Category 10: Chat & Options (5 windows)

| Class | INTERFACE_LIST ID | Open Trigger |
|-------|-------------------|--------------|
| `CNewUIChatInputBox` | `INTERFACE_CHATINPUTBOX` | Enter key / chat area click |
| `CNewUIChatLogWindow` | `INTERFACE_CHATLOGWINDOW` | Chat log scroll area |
| `CNewUISystemLogWindow` | `INTERFACE_SYSTEM_LOG` | System message log |
| `CNewUIOptionWindow` | `INTERFACE_OPTION` | `O` key or Options menu |
| `CNewUIHelpWindow` | `INTERFACE_HELP` | Help/F1 key |

### Category 11: GameShop (1 window)

| Class | INTERFACE_LIST ID | Open Trigger |
|-------|-------------------|--------------|
| `CNewUIInGameShop` | `INTERFACE_INGAMESHOP` | Shop button in main frame |

---

## Manual Validation Procedures

### Prerequisites Checklist

- [ ] MU Online test server running and accessible
- [ ] Client built for target platform (macOS/Linux/Windows)
- [ ] Character logged in and in-game (not at character selection)
- [ ] Character has items in inventory for inventory tests
- [ ] Character has a party for party tests (or recruit test partner)
- [ ] Character has guild membership for guild tests (or create test guild)

---

### HUD Windows (Category 2)

**Goal:** Verify HUD elements display correctly and respond to interactions.

| # | Test | Steps | Expected Result | Platform |
|---|------|-------|-----------------|----------|
| H-1 | Main frame renders | Launch game, enter world | Bottom main frame visible with HP/MP/EXP bars and action buttons | All |
| H-2 | Skill list populates | Enter world with skills learned | Skills appear in hotbar slots with correct icons and key labels | All |
| H-3 | MiniMap opens | Press `M` | Minimap overlay opens at correct position; map texture loads | All |
| H-4 | MiniMap skill icons | Open minimap while in combat | Skill icons appear at correct positions on minimap overlay | All |
| H-5 | Name window hover | Hover over another player | Name/HP bar appears above character | All |
| H-6 | Window menu toggle | Click menu button | Window toggle menu opens with all window buttons | All |
| H-7 | HP/MP bar updates | Take damage / use mana skill | HP/MP bars animate and update in real-time | All |
| H-8 | EXP bar updates | Kill a monster | EXP bar fills; level-up animation on 100% | All |

---

### Character Windows (Category 3)

| # | Test | Steps | Expected Result | Platform |
|---|------|-------|-----------------|----------|
| C-1 | Character info opens | Press `C` | Character window opens with stats, equipment slots, avatar model | All |
| C-2 | Character stats display | Open character window | STR/AGI/VIT/ENE/CMD values display correctly | All |
| C-3 | Equipment preview | Equip/unequip an item | Avatar model updates to show equipped item | All |
| C-4 | Buff window appears | Receive a buff | Buff icon appears in buff window; duration timer counts down | All |
| C-5 | MuHelper opens | Open MuHelper | MuHelper panel opens with automation controls | All |
| C-6 | Pet info shows | Have an active pet | Pet status panel shows pet HP and level | All |

---

### Inventory Windows (Category 4)

| # | Test | Steps | Expected Result | Platform |
|---|------|-------|-----------------|----------|
| I-1 | Inventory opens | Press `I` | Inventory grid (4 columns) opens; items render with correct icons | All |
| I-2 | Item drag-drop | Drag item to new slot | Item moves to target slot; source slot clears | All |
| I-3 | Item tooltip | Hover over item | Tooltip shows item name, stats, and description | All |
| I-4 | Storage opens | Talk to warehouse NPC | Storage inventory grid opens showing stored items | All |
| I-5 | Mix window opens | Open chaos machine window | Mix/chaos inventory grid opens | All |
| I-6 | Personal shop | Open personal shop | Shop inventory panel shows items for sale | All |
| I-7 | Inventory scroll | Have >8 rows of items | Scroll bar appears and scrolls correctly through items | All |

---

### Commerce Windows (Category 5)

| # | Test | Steps | Expected Result | Platform |
|---|------|-------|-----------------|----------|
| M-1 | NPC shop opens | Talk to shop NPC | NPC shop opens with items and prices | All |
| M-2 | Trade request | Request trade with player | Trade window opens with both trade grids | All |
| M-3 | Trade confirm | Place items and confirm | Trade completes; items exchanged between players | All |
| M-4 | NPC dialogue | Talk to any NPC | Dialogue window opens with NPC text and response options | All |
| M-5 | Lucky coin exchange | Talk to lucky coin NPC | Exchange window opens with coin balance | All |

---

### Castle Windows (Category 6)

| # | Test | Steps | Expected Result | Platform |
|---|------|-------|-----------------|----------|
| K-1 | Castle senatus | Enter castle, open senatus | Castle management window opens with alliance info | All |
| K-2 | Guard NPC | Talk to castle guard | Guard management window shows guard list | All |
| K-3 | Gate control | Access gate switch | Gate switch UI shows gate status and toggle button | All |
| K-4 | Catapult UI | Mount catapult | Catapult targeting UI appears with angle/distance controls | All |

---

### Event Windows (Category 7)

| # | Test | Steps | Expected Result | Platform |
|---|------|-------|-----------------|----------|
| E-1 | Blood Castle entry | Talk to BC entry NPC | Entry window shows current BC level/time remaining | All |
| E-2 | Devil Square entry | Talk to DS NPC | Entry window shows current DS level/time | All |
| E-3 | Duel window | Challenge player to duel | Duel challenge/status window opens with player names and scores | All |
| E-4 | Duel spectate | Watch an ongoing duel | Duel watch frame shows both players' HP/SD rates | All |
| E-5 | CryWolf event | Participate in CryWolf event | CryWolf UI shows event status and objectives | All |
| E-6 | Battle Soccer | Enter battle soccer match | Score board appears with team scores | All |
| E-7 | Chaos Castle countdown | Enter Chaos Castle | Countdown timer displays before map transition | All |

---

### Quest Windows (Category 8)

| # | Test | Steps | Expected Result | Platform |
|---|------|-------|-----------------|----------|
| Q-1 | Quest log opens | Open quest log | Quest log shows active/completed quests with progress bars | All |
| Q-2 | NPC quest | Talk to quest NPC | Quest dialogue opens with objectives and rewards listed | All |
| Q-3 | Quest progress | Complete a quest objective | Progress bar increments; quest marker updates | All |

---

### Social Windows (Category 9)

| # | Test | Steps | Expected Result | Platform |
|---|------|-------|-----------------|----------|
| S-1 | Party list opens | Press `P` | Party list shows party members with HP bars | All |
| S-2 | Party member info | Click party member | Party info window shows member's detailed stats | All |
| S-3 | Friend list opens | Open friend list | Friend list shows online/offline friends with status icons | All |
| S-4 | Guild info opens | Open guild panel | Guild info shows member list, rankings, guild logo | All |
| S-5 | Gens ranking | Open Gens faction panel | Gens ranking shows top players/guilds by faction | All |

---

### Chat & Options (Category 10)

| # | Test | Steps | Expected Result | Platform |
|---|------|-------|-----------------|----------|
| CH-1 | Chat input | Press Enter | Chat input box opens; text cursor appears | All |
| CH-2 | Chat message | Type and send message | Message appears in chat log with correct name/colour | All |
| CH-3 | Chat log scroll | Scroll chat history | Chat log scrolls smoothly through message history | All |
| CH-4 | System log | Check system log | System messages (item drops, kills, server notices) appear | All |
| CH-5 | Options window | Press `O` | Options window opens with graphics/audio/key binding tabs | All |
| CH-6 | Options save | Change a setting and save | Setting persists after window close and game restart | All |
| CH-7 | Help window | Press F1 | Help window opens with game help content | All |

---

### GameShop (Category 11)

| # | Test | Steps | Expected Result | Platform |
|---|------|-------|-----------------|----------|
| GS-1 | GameShop opens | Click shop button | In-game shop opens with item categories | All |
| GS-2 | Item browse | Browse shop categories | Items display with names, prices, and preview images | All |

---

## SSIM Ground Truth Comparison Procedures (AC-5)

The 5 key windows for SSIM comparison are:

| Window | INTERFACE_LIST ID | Buffer Dimensions |
|--------|-------------------|-------------------|
| Inventory | `INTERFACE_INVENTORY` | 190×429 px |
| Character | `INTERFACE_CHARACTER` | ~240×480 px |
| Skills | `INTERFACE_SKILL_LIST` | Hotbar region |
| MiniMap | `INTERFACE_MINI_MAP` | 320×240 px |
| Chat | `INTERFACE_CHATINPUTBOX` | Chat area region |

### SSIM Baseline Capture Procedure

1. Start the game on the **reference platform** (Windows release build)
2. Open each of the 5 key windows using their normal triggers
3. Allow window to fully render (1 frame minimum)
4. Use `mu::GroundTruthCapture::CaptureWindow()` to capture the framebuffer region
5. Save as `ground_truth/{window_name}_baseline.raw` (RGB 3-channel raw buffer)
6. Record dimensions in `ground_truth/manifest.json`

### SSIM Comparison Procedure (Cross-Platform Validation)

1. On target platform (macOS/Linux), open the same 5 windows
2. Capture the same framebuffer regions using `GroundTruthCapture::CaptureWindow()`
3. Call `mu::GroundTruthCapture::ComputeSSIM(baseline, captured, width, height, 3)`
4. Verify SSIM score is >= 0.99 for each window
5. If SSIM < 0.99: investigate rendering differences (font rendering, alpha blending, coordinate offsets)

### SSIM Acceptance Criteria

| Window | Minimum SSIM | Notes |
|--------|-------------|-------|
| Inventory | 0.99 | 190×429 buffer, RGB |
| Character | 0.99 | Dimensions per capture |
| Skills | 0.99 | Hotbar layout must match |
| MiniMap | 0.99 | 320×240 buffer, RGB |
| Chat | 0.99 | Text rendering most sensitive |

---

## Platform-Specific Notes

### macOS

- UI fonts may differ due to CoreText vs FreeType rendering — expect minor SSIM variation (0.97–0.99)
- Metal GPU backend renders alpha differently than DirectX — check translucent windows
- HiDPI (Retina) displays: verify UI scales correctly at 2x and 1x logical resolution

### Linux

- Vulkan backend used — shader-based UI rendering may differ from OpenGL/DirectX
- Wayland vs X11: verify clipboard paste in chat input works on both display servers
- Font rendering via FreeType: character spacing may vary vs Windows GDI

### Windows

- Reference baseline platform — all SSIM comparisons are vs Windows captures
- DirectX 11/12 backend; verify no regression from OpenGL migration
- Win32 message box fallback via `SDL_ShowSimpleMessageBox` — verify dialog appearance

---

## Summary Statistics

| Category | Windows | Manual Tests | Automated Tests |
|----------|---------|--------------|-----------------|
| HUD | 8 | 8 (H-1..H-8) | 1 (pairwise distinct) |
| Character | 6 | 6 (C-1..C-6) | 1 (pairwise distinct) |
| Inventory | 8 | 7 (I-1..I-7) | 1 (pairwise distinct) |
| Commerce | 7 | 5 (M-1..M-5) | 1 (pairwise distinct) |
| Castle | 5 | 4 (K-1..K-4) | 1 (pairwise distinct) |
| Events | 19 | 7 (E-1..E-7) | 1 (19 IDs pairwise distinct) |
| Quest | 4 | 3 (Q-1..Q-3) | 1 (pairwise distinct) |
| Social | 6 | 5 (S-1..S-5) | 1 (pairwise distinct) |
| Chat/Options | 5 | 7 (CH-1..CH-7) | 1 (pairwise distinct) |
| GameShop | 1 | 2 (GS-1..GS-2) | — |
| SSIM 5 key windows | 5 | 5 (SSIM procedure) | 4 (SSIM Catch2) |
| **Total** | **84+** | **59 scenarios** | **19 TEST_CASEs** |
