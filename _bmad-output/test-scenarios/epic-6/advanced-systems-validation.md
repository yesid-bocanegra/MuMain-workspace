# Test Scenarios: Story 6.3.2 — Advanced Game Systems Validation

**Story ID:** 6.3.2
**Epic:** 6 — Cross-Platform Gameplay Validation
**Flow Code:** VS1-GAME-VALIDATE-SYSTEMS
**Date:** 2026-03-23
**Test Type:** Manual + Catch2 Unit

---

## Overview

This document defines the complete test plan for validating that quest UI, pet companion
management, PvP targeting/combat, and duel systems work correctly on macOS, Linux,
and Windows.

Automated Catch2 tests cover pure data structure and constant validation:
quest constants (MAX_QUESTS=200, state packing), quest type/view enums, QUEST_CLASS_ACT/
QUEST_CLASS_REQUEST/QUEST_ATTRIBUTE struct layouts, PET_TYPE/PET_COMMAND/pet state enums,
PET_INFO struct layout, PetObject::ActionType enum, pet type rendering constants,
MAX_DUEL_CHANNELS, _DUEL_PLAYER_TYPE enum, DUEL_PLAYER_INFO/DUEL_CHANNEL_INFO struct
layouts, and event match system inheritance (CSBaseMatch).

Platform rendering, server-interaction, and UI behavior tests are manual-only.

**Prerequisites:**
- Running MU Online test server (live game required for AC-1..4 full validation)
- macOS build: `cmake --preset macos-arm64 && cmake --build --preset macos-arm64-debug`
- Linux build: MinGW cross-compile or native Linux build
- Windows build: `cmake --preset windows-x64 && cmake --build --preset windows-x64-debug`

> **Risk R17:** All full AC-1..4 scenarios require a running MU Online server for actual
> in-game validation. Catch2 tests cover server-independent component logic only.

---

## Automated Test Coverage (Catch2)

Run: `cmake -S MuMain -B build -DBUILD_TESTING=ON && cmake --build build && ctest --test-dir build`

| Test Case | AC | Verifies |
|-----------|-----|----------|
| MAX_QUESTS == 200, MAX_QUEST_CONDITION == 16, MAX_QUEST_REQUEST == 16 | AC-1 | Quest array dimension constants |
| Quest type enum: TYPE_QUEST=0..TYPE_QUEST_END=4, 5 values pairwise distinct | AC-1 | Quest entry type completeness |
| Quest view mode enum: QUEST_VIEW_NONE=0..QUEST_VIEW_END=3, 4 values pairwise distinct | AC-1 | Quest display state completeness |
| QUEST_CLASS_ACT struct: chLive/byQuestType (BYTE), wItemType (WORD) | AC-1 | Condition struct field layout |
| QUEST_CLASS_REQUEST struct: byLive/byType (BYTE), WORD fields, dwZen (DWORD) | AC-1 | Request struct field layout |
| QUEST_ATTRIBUTE struct: QuestAct[16], QuestRequest[16], strQuestName[32] | AC-1 | Quest attribute array sizes |
| CSQuest state packing: MASK=0x03, STATES_PER_ENTRY=4, BIT_WIDTH=2 (MU_GAME_AVAILABLE) | AC-1 | Bitfield packing self-consistency |
| REQUEST_REWARD_CLASSIFY: RRC_NONE=0, RRC_REQUEST=1, RRC_REWARD=2 (MU_GAME_AVAILABLE) | AC-1 | Request/reward classification |
| Pet state enum: PET_FLYING=0..PET_END=7, 8 values pairwise distinct | AC-2 | Pet locomotion/combat states |
| PET_TYPE enum: NONE=-1, DARK_SPIRIT=0, DARK_HORSE=1, END=2 | AC-2 | Pet type identifiers |
| PET_COMMAND enum: DEFAULT=0..END=4, 5 values pairwise distinct | AC-2 | Pet AI command modes |
| PET_INFO struct: DWORD type/exp fields, WORD level/life/damage/attack fields (MU_GAME_AVAILABLE) | AC-2 | Pet network data struct layout |
| PetObject::ActionType: eAction_Stand=0..eAction_End=6 (MU_GAME_AVAILABLE) | AC-2 | Pet animation state completeness |
| Pet type constants: PC4_ELF=1..SKELETON=7 pairwise distinct (MU_GAME_AVAILABLE) | AC-2 | Pet rendering constant uniqueness |
| MAX_DUEL_CHANNELS == 4 | AC-3 | Duel arena channel capacity |
| _DUEL_PLAYER_TYPE: DUEL_HERO=0, DUEL_ENEMY=1, MAX_DUEL_PLAYERS=2, pairwise distinct | AC-3 | Duel participant type enum |
| DUEL_PLAYER_INFO struct: m_sIndex (short), m_szID (wchar_t[]), m_iScore (int), m_fHPRate/m_fSDRate (float) | AC-3 | Duel player tracking struct |
| DUEL_CHANNEL_INFO struct: m_bEnable/m_bJoinable (BOOL), m_szID1/m_szID2 symmetric | AC-3 | Duel channel state struct |
| MAX_DUEL_CHANNELS == MAX_DUEL_PLAYERS * 2 | AC-4 | Channel capacity consistency |
| CNewBloodCastleSystem/CNewChaosCastleSystem derive from CSBaseMatch (MU_GAME_AVAILABLE) | AC-4 | Event match inheritance |

---

## Manual Test Scenarios

### Prerequisites for Manual Tests

All manual scenarios require:
1. Running MU Online test server (local or remote)
2. Valid game client build (macOS, Linux, or Windows)
3. Test character logged in and standing in a populated map
4. For pet tests: character with Dark Spirit or Dark Horse pet item
5. For PvP/duel tests: at least one other player online, in a PvP-enabled zone

---

### AC-1: Quest UI Opens and Displays Quest Information

**Objective:** Verify that the quest window opens correctly, displays quest list,
quest details, and progress tracking on macOS, Linux, and Windows.

#### Scenario 1.1: Open Quest Window

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open game client, log in, enter game world | Character appears in-game |
| 2 | Press Q key (or quest menu button) to open quest window | CNewUIMyQuestInfoWindow appears |
| 3 | Verify quest list is populated | Active quests shown (up to MAX_QUESTS=200 slots) |
| 4 | Verify quest window has correct layout | Quest name, NPC type, conditions, requirements visible |
| 5 | Repeat on macOS, Linux, Windows | Same behavior on all platforms |

**Pass Criteria:** Quest window opens, quest list displays correctly, no garbled text.

#### Scenario 1.2: View Quest Details

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click on a quest in the quest list | Quest detail view opens |
| 2 | Verify quest name displayed (up to 32 wchar_t) | Name matches QUEST_ATTRIBUTE.strQuestName |
| 3 | Verify conditions list (up to 16 conditions) | MAX_QUEST_CONDITION=16 entries shown |
| 4 | Verify requirements list (up to 16 requests) | MAX_QUEST_REQUEST=16 entries shown |
| 5 | Verify quest type classification | Quest view mode matches (QUEST_VIEW_NONE..QUEST_VIEW_END) |

**Pass Criteria:** Quest details render correctly with all condition and requirement fields.

#### Scenario 1.3: Quest Progress Tracking

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Accept a quest from an NPC | Quest added to quest list |
| 2 | Open quest progress window | CNewUIQuestProgress shows active quest |
| 3 | Complete partial quest objective | Progress updates in real-time |
| 4 | Verify quest state changes | 2-bit state (QUEST_STATE_MASK=0x03) transitions correctly |

**Pass Criteria:** Quest progress tracks and updates correctly across all platforms.

#### Scenario 1.4: NPC Quest Interaction

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Approach a quest NPC | NPC interaction available |
| 2 | Open NPC dialogue (CNewUINPCQuest) | Quest dialogue window appears |
| 3 | Accept a new quest | Quest added to quest list |
| 4 | Return to NPC after completing quest | NPC offers reward (SQuestReward) |
| 5 | Verify request/reward classification | REQUEST_REWARD_CLASSIFY distinguishes items correctly |

**Pass Criteria:** Full quest lifecycle (accept → progress → complete → reward) works.

---

### AC-2: Pet Companion Follows Player and Can Be Managed

**Objective:** Verify that Dark Spirit and Dark Horse pets can be summoned, follow the
player, perform actions, and respond to AI commands on all platforms.

#### Scenario 2.1: Summon Pet

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Equip pet item (Dark Spirit or Dark Horse) | Pet item in equipment slot |
| 2 | Activate pet summon | Pet appears near player character |
| 3 | Verify PET_INFO data populated | Type, level, exp, life, damage, attack stats shown |
| 4 | Verify PET_TYPE matches equipped pet | PET_TYPE_DARK_SPIRIT=0 or PET_TYPE_DARK_HORSE=1 |

**Pass Criteria:** Pet summons correctly with valid PET_INFO data.

#### Scenario 2.2: Pet Follow and Movement

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Move player character | Pet follows with PET_FLYING state (state 0) |
| 2 | Stop moving | Pet transitions to idle state |
| 3 | Verify pet animation states | ActionType transitions: eAction_Stand, eAction_Move visible |
| 4 | Move to different map | Pet follows to new map location |
| 5 | Repeat on macOS, Linux, Windows | Same pet behavior on all platforms |

**Pass Criteria:** Pet follows player movement with correct state transitions.

#### Scenario 2.3: Pet AI Command Modes

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set pet to Default mode (PET_CMD_DEFAULT=0) | Pet uses default AI behavior |
| 2 | Set pet to Random mode (PET_CMD_RANDOM=1) | Pet attacks random nearby enemies |
| 3 | Set pet to Owner mode (PET_CMD_OWNER=2) | Pet stays near and defends owner |
| 4 | Set pet to Target mode (PET_CMD_TARGET=3) | Pet attacks owner's current target |
| 5 | Verify command transitions | PET_COMMAND enum values 0-3 respond correctly |

**Pass Criteria:** All 4 pet AI command modes function correctly.

#### Scenario 2.4: Pet Combat and Stats

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Pet engages enemy in combat | Pet animation changes to attack states |
| 2 | Verify pet damage output | m_wDamageMin/m_wDamageMax range respected |
| 3 | Verify pet takes damage | m_wLife decreases when hit |
| 4 | Verify pet attack speed | m_wAttackSpeed governs attack frequency |
| 5 | Check pet rendering type constant | PC4_ELF(1), PC4_SATAN(3), etc. render correct model |

**Pass Criteria:** Pet combat stats and rendering match PET_INFO/PetObject data.

---

### AC-3: PvP Targeting and Combat Works Between Players

**Objective:** Verify that players can target each other, engage in PvP combat, and
damage/HP tracking displays correctly on all platforms.

#### Scenario 3.1: PvP Target Player

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter a PvP-enabled zone | PvP mode active |
| 2 | Click on another player to target | Target indicator appears on other player |
| 3 | Verify target info displayed | Player name, level, guild tag visible |
| 4 | Attack targeted player | Combat animation plays, damage numbers appear |

**Pass Criteria:** Player targeting and PvP combat initiation works.

#### Scenario 3.2: PvP Combat Feedback

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Attack another player | Damage numbers display correctly |
| 2 | Receive damage from another player | HP bar decreases, damage numbers shown |
| 3 | Verify kill tracking | Kill/death recorded in game state |
| 4 | Repeat on macOS, Linux, Windows | Same PvP behavior on all platforms |

**Pass Criteria:** PvP combat feedback (damage, HP, kills) displays correctly.

---

### AC-4: Duel Invitation and Acceptance Work

**Objective:** Verify duel invitation, acceptance, arena combat, scoring, and spectator
mode work correctly on all platforms.

#### Scenario 4.1: Duel Invitation Send/Receive

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Right-click another player | Context menu with "Duel" option appears |
| 2 | Select "Duel" to send invitation | Duel request sent to target player |
| 3 | Target player receives invitation | Duel invitation popup on target's screen |
| 4 | Target accepts duel | Both players teleported to duel arena (CDuelMgr) |

**Pass Criteria:** Duel invitation and acceptance flow works correctly.

#### Scenario 4.2: Duel Arena Combat

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Both players in duel arena | IsDuelArena() returns true, CGMDuelArena active |
| 2 | Verify DUEL_PLAYER_INFO for both players | DUEL_HERO=0 and DUEL_ENEMY=1 assigned correctly |
| 3 | Players engage in combat | Damage tracked, m_iScore increments on kill |
| 4 | Verify HP/SD rate display | m_fHPRate and m_fSDRate update in duel HUD |
| 5 | Verify duel channel state | DUEL_CHANNEL_INFO.m_bEnable=true, m_bJoinable appropriate |

**Pass Criteria:** Duel arena combat tracking and scoring works correctly.

#### Scenario 4.3: Duel Channel Capacity

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Start 4 simultaneous duels | MAX_DUEL_CHANNELS=4 channels all active |
| 2 | Attempt 5th duel | Rejected — all channels occupied |
| 3 | One duel ends | Channel freed, new duel can start |
| 4 | Verify channel info | m_szID1/m_szID2 show correct player names per channel |

**Pass Criteria:** MAX_DUEL_CHANNELS=4 enforced, channels recycle correctly.

#### Scenario 4.4: Duel Spectator Mode

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open duel spectator UI | CNewUIDuelWindow shows active channels |
| 2 | Select a channel to watch | Camera moves to duel arena |
| 3 | Verify spectator sees both players | Duel HUD shows both players' HP/SD/score |
| 4 | Duel ends | Spectator notified of result |

**Pass Criteria:** Spectator mode functions for all active duel channels.

#### Scenario 4.5: Event Match Systems

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter Blood Castle event | CNewBloodCastleSystem activates (inherits CSBaseMatch) |
| 2 | Verify match timer renders | RenderMatchTimes() displays countdown |
| 3 | Complete event, verify result screen | RenderMatchResult() shows outcome |
| 4 | Enter Chaos Castle event | CNewChaosCastleSystem activates (inherits CSBaseMatch) |
| 5 | Verify match timer and result | Same CSBaseMatch interface works for both events |

**Pass Criteria:** Blood Castle and Chaos Castle events use CSBaseMatch interface correctly.

---

## Platform Test Matrix

| Scenario | macOS (arm64) | Linux (x64) | Windows (x64) |
|----------|:---:|:---:|:---:|
| AC-1: Open quest window | [ ] | [ ] | [ ] |
| AC-1: Quest details | [ ] | [ ] | [ ] |
| AC-1: Quest progress | [ ] | [ ] | [ ] |
| AC-1: NPC quest interaction | [ ] | [ ] | [ ] |
| AC-2: Summon pet | [ ] | [ ] | [ ] |
| AC-2: Pet follow/movement | [ ] | [ ] | [ ] |
| AC-2: Pet AI commands | [ ] | [ ] | [ ] |
| AC-2: Pet combat/stats | [ ] | [ ] | [ ] |
| AC-3: PvP target player | [ ] | [ ] | [ ] |
| AC-3: PvP combat feedback | [ ] | [ ] | [ ] |
| AC-4: Duel invitation | [ ] | [ ] | [ ] |
| AC-4: Duel arena combat | [ ] | [ ] | [ ] |
| AC-4: Duel channel capacity | [ ] | [ ] | [ ] |
| AC-4: Duel spectator mode | [ ] | [ ] | [ ] |
| AC-4: Event match systems | [ ] | [ ] | [ ] |

---

## Validation Sign-Off

| Validator | Platform | Date | Status |
|-----------|----------|------|--------|
| (pending) | macOS | | [ ] |
| (pending) | Linux | | [ ] |
| (pending) | Windows | | [ ] |

---

*Test scenarios generated by PCC dev-story workflow for Story 6.3.2*
