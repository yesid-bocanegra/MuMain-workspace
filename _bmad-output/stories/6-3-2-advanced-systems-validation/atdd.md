# ATDD Checklist: Story 6.3.2 — Advanced Game Systems Validation

**Story Key:** 6-3-2-advanced-systems-validation
**Story Type:** infrastructure
**Primary Test Level:** Unit (Catch2 component tests)
**Test File:** `MuMain/tests/gameplay/test_advanced_systems_validation.cpp`
**Output Path:** `_bmad-output/stories/6-3-2-advanced-systems-validation/atdd.md`
**Date Generated:** 2026-03-23
**Phase:** RED — tests compile but validate logical contracts (no implementation required)

---

## PCC Compliance Summary

| Check | Status | Detail |
|-------|--------|--------|
| Prohibited libraries | ✓ PASS | No raw new/delete, NULL, timeGetTime(), #ifdef _WIN32 in game logic |
| Required testing patterns | ✓ PASS | Catch2 v3.7.1, TEST_CASE/SECTION/REQUIRE/static_assert |
| Test file location | ✓ PASS | `tests/gameplay/test_advanced_systems_validation.cpp` |
| Naming convention | ✓ PASS | `test_{name}.cpp` mirroring `src/source/Gameplay/` |
| Framework version | ✓ PASS | Catch2 v3.7.1 (FetchContent, target MuTests) |
| Platform guard | ✓ PASS | `#ifdef _WIN32 / #include "Platform/PlatformTypes.h"` pattern |
| MU_GAME_AVAILABLE gate | ✓ PASS | Heavy game headers gated; standalone tests use mu_define.h/mu_enum.h/mu_struct.h/DuelMgr.h |
| CMake auto-discovery | ✓ PASS | `target_sources(MuTests PRIVATE gameplay/test_advanced_systems_validation.cpp)` added |
| Allman braces / 4-space indent | ✓ PASS | Consistent with clang-format 21.1.8 |
| No Bruno API tests | ✓ N/A | Infrastructure story — no REST endpoints |
| No E2E tests | ✓ N/A | Infrastructure story — no frontend |

---

## AC-to-Test Mapping

| AC | Description | Test Methods | Phase |
|----|-------------|--------------|-------|
| AC-1 | Quest UI opens and displays quest information | 8 TEST_CASEs (6 standalone + 2 MU_GAME_AVAILABLE) | RED |
| AC-2 | Pet companion follows player and can be managed | 7 TEST_CASEs (3 standalone + 4 MU_GAME_AVAILABLE) | RED |
| AC-3 | PvP targeting and combat works between players | 4 TEST_CASEs (all standalone via DuelMgr.h) | RED |
| AC-4 | Duel invitation and acceptance work | 2 TEST_CASEs (1 standalone + 1 MU_GAME_AVAILABLE) | RED |

**Total TEST_CASEs generated:** 20 standalone-compilable + MU_GAME_AVAILABLE gated
**Existing tests mapped (Step 0.5):** 0 — no prior tests for this story
**ACs needing new tests:** AC-1, AC-2, AC-3, AC-4 (all)

---

## Test Method Index

### AC-1: Quest System

| Test Case | Tags | MU_GAME_AVAILABLE? |
|-----------|------|--------------------|
| `AC-1 [6-3-2]: Quest system constants define correct array dimensions` | `[quest][constants][6-3-2]` | No |
| `AC-1 [6-3-2]: Quest type enum covers all quest entry types with no duplicates` | `[quest][enum][type][6-3-2]` | No |
| `AC-1 [6-3-2]: Quest view mode enum covers all display states` | `[quest][enum][view][6-3-2]` | No |
| `AC-1 [6-3-2]: QUEST_CLASS_ACT struct has correct field layout` | `[quest][struct][act][6-3-2]` | No |
| `AC-1 [6-3-2]: QUEST_CLASS_REQUEST struct has correct field layout` | `[quest][struct][request][6-3-2]` | No |
| `AC-1 [6-3-2]: QUEST_ATTRIBUTE struct uses correct array sizes and name buffer` | `[quest][struct][attribute][6-3-2]` | No |
| `AC-1 [6-3-2]: CSQuest state packing constants are correct and self-consistent` | `[quest][constants][packing][6-3-2]` | **Yes** |
| `AC-1 [6-3-2]: REQUEST_REWARD_CLASSIFY enum covers request vs reward classification` | `[quest][enum][classify][6-3-2]` | **Yes** |

### AC-2: Pet System

| Test Case | Tags | MU_GAME_AVAILABLE? |
|-----------|------|--------------------|
| `AC-2 [6-3-2]: Pet state enum covers all locomotion and combat states` | `[pet][enum][state][6-3-2]` | No |
| `AC-2 [6-3-2]: PET_TYPE enum defines correct pet type identifiers` | `[pet][enum][type][6-3-2]` | No |
| `AC-2 [6-3-2]: PET_COMMAND enum covers all AI command modes with no duplicates` | `[pet][enum][command][6-3-2]` | No |
| `AC-2 [6-3-2]: PET_INFO struct has correct field layout for network data` | `[pet][struct][info][6-3-2]` | **Yes** |
| `AC-2 [6-3-2]: PetObject::ActionType enum covers all animation states` | `[pet][enum][action][6-3-2]` | **Yes** |
| `AC-2 [6-3-2]: Pet type rendering constants are pairwise distinct` | `[pet][constants][type][6-3-2]` | **Yes** |

### AC-3: PvP Targeting

| Test Case | Tags | MU_GAME_AVAILABLE? |
|-----------|------|--------------------|
| `AC-3 [6-3-2]: PvP duel system channel capacity constant is correct` | `[pvp][constants][6-3-2]` | No |
| `AC-3 [6-3-2]: _DUEL_PLAYER_TYPE enum identifies hero and enemy duel participants` | `[pvp][enum][type][6-3-2]` | No |
| `AC-3 [6-3-2]: DUEL_PLAYER_INFO struct has correct field layout for combat tracking` | `[pvp][struct][player][6-3-2]` | No |
| `AC-3 [6-3-2]: DUEL_CHANNEL_INFO struct has correct field layout for arena channels` | `[pvp][struct][channel][6-3-2]` | No |

### AC-4: Duel System

| Test Case | Tags | MU_GAME_AVAILABLE? |
|-----------|------|--------------------|
| `AC-4 [6-3-2]: MAX_DUEL_CHANNELS matches CDuelMgr channel array contract` | `[duel][constants][consistency][6-3-2]` | No |
| `AC-4 [6-3-2]: Event match systems derive from CSBaseMatch base class` | `[duel][events][inheritance][6-3-2]` | **Yes** |

---

## Implementation Checklist

All items start as `[ ]` (pending — GREEN phase, implemented during dev-story).

### AC-1: Quest System Validation
- [ ] `AC-1: Quest system constants define correct array dimensions` — MAX_QUESTS=200, MAX_QUEST_CONDITION=16, MAX_QUEST_REQUEST=16 verified in mu_define.h
- [ ] `AC-1: Quest type enum covers all quest entry types with no duplicates` — TYPE_QUEST=0..TYPE_QUEST_END=4, 5 values pairwise distinct
- [ ] `AC-1: Quest view mode enum covers all display states` — QUEST_VIEW_NONE=0..QUEST_VIEW_END=3, 4 values pairwise distinct
- [ ] `AC-1: QUEST_CLASS_ACT struct has correct field layout` — chLive/byQuestType (BYTE), wItemType (WORD), byRequestClass[MAX_CLASS=7], shQuestStartText[4]
- [ ] `AC-1: QUEST_CLASS_REQUEST struct has correct field layout` — byLive/byType (BYTE), WORD fields, dwZen (DWORD)
- [ ] `AC-1: QUEST_ATTRIBUTE struct uses correct array sizes and name buffer` — QuestAct[16], QuestRequest[16], strQuestName[32] wchar_t
- [ ] `AC-1 (MU_GAME_AVAILABLE): CSQuest state packing constants` — MASK=0x03, STATES_PER_ENTRY=4, BIT_WIDTH=2, packing math 4×2=8 bits
- [ ] `AC-1 (MU_GAME_AVAILABLE): REQUEST_REWARD_CLASSIFY enum` — RRC_NONE=0, RRC_REQUEST=1, RRC_REWARD=2, pairwise distinct

### AC-2: Pet System Validation
- [ ] `AC-2: Pet state enum covers all locomotion and combat states` — PET_FLYING=0..PET_END=7, 8 values pairwise distinct
- [ ] `AC-2: PET_TYPE enum defines correct pet type identifiers` — NONE=-1, DARK_SPIRIT=0, DARK_HORSE=1, END=2
- [ ] `AC-2: PET_COMMAND enum covers all AI command modes with no duplicates` — DEFAULT=0..END=4, 5 values pairwise distinct
- [ ] `AC-2 (MU_GAME_AVAILABLE): PET_INFO struct has correct field layout` — m_dwPetType/Exp1/Exp2 (DWORD=4), m_wLevel/Life/DamageMin/Max/AttackSpeed/AttackSuccess (WORD=2)
- [ ] `AC-2 (MU_GAME_AVAILABLE): PetObject::ActionType enum` — eAction_Stand=0..eAction_End=6, 7 values pairwise distinct
- [ ] `AC-2 (MU_GAME_AVAILABLE): Pet type rendering constants pairwise distinct` — PC4_ELF=1..SKELETON=7 (6 unconditional constants)

### AC-3: PvP/Duel Structure Validation
- [ ] `AC-3: PvP duel system channel capacity constant` — MAX_DUEL_CHANNELS=4
- [ ] `AC-3: _DUEL_PLAYER_TYPE enum` — DUEL_HERO=0, DUEL_ENEMY=1, MAX_DUEL_PLAYERS=2, pairwise distinct
- [ ] `AC-3: DUEL_PLAYER_INFO struct field layout` — m_sIndex (short=2), m_szID wchar_t[MAX_USERNAME_SIZE+1], m_iScore (int=4), m_fHPRate/m_fSDRate (float=4)
- [ ] `AC-3: DUEL_CHANNEL_INFO struct field layout` — m_bEnable/m_bJoinable (BOOL=int=4), m_szID1/m_szID2 wchar_t[MAX_USERNAME_SIZE+1], symmetric sizes

### AC-4: Duel System Contract Validation
- [ ] `AC-4: MAX_DUEL_CHANNELS matches CDuelMgr array contract` — MAX_DUEL_CHANNELS=MAX_DUEL_PLAYERS×2=4, DUEL_HERO/DUEL_ENEMY both index within [0,MAX_DUEL_PLAYERS)
- [ ] `AC-4 (MU_GAME_AVAILABLE): Event match inheritance` — CNewBloodCastleSystem and CNewChaosCastleSystem both std::is_base_of_v<CSBaseMatch, T>

### Standard AC Compliance
- [ ] `AC-STD-1`: Code Standards Compliance — no prohibited patterns in test file
- [ ] `AC-STD-2`: Testing Requirements — Catch2 test suite validates quest/pet/PvP without live server
- [ ] `AC-STD-12`: SLI/SLO — test suite execution < 200ms per test case, 0 CI timeouts
- [ ] `AC-STD-13`: Quality Gate — `./ctl check` passes (clang-format + cppcheck 0 errors)
- [ ] `AC-STD-14`: Observability — test output includes struct size validation, enum coverage counts, static_assert messages at build
- [ ] `AC-STD-16`: Correct test infrastructure — Catch2 v3.7.1, `tests/gameplay/` directory, CMake `target_sources` registration confirmed

### Build Integration
- [ ] `CMakeLists.txt updated` — `target_sources(MuTests PRIVATE gameplay/test_advanced_systems_validation.cpp)` added
- [ ] `Test file compiles` — no errors on macOS/Linux standalone subset (no MU_GAME_AVAILABLE)
- [ ] `MinGW CI build passes` — test TU compiles cleanly in cross-compile environment

---

## Data Infrastructure

**Fixtures required:** None — component-level tests use compile-time constants and sizeof checks only.
**Test environments:** macOS (quality gates, standalone subset), Linux/WSL (full MinGW cross-compile), Windows (full MU_GAME_AVAILABLE if needed).
**Seed data:** None required — no database, no network.

---

## Manual Validation Reference

Full end-to-end AC-1..4 validation (requires live MU server + platform build):
`_bmad-output/test-scenarios/epic-6/advanced-systems-validation.md`

---

## Deliverables Summary

| Deliverable | Path | Status |
|-------------|------|--------|
| Test file | `MuMain/tests/gameplay/test_advanced_systems_validation.cpp` | ✓ Created (RED phase) |
| CMakeLists.txt entry | `MuMain/tests/CMakeLists.txt` line ~216 | ✓ Added |
| ATDD checklist | `_bmad-output/stories/6-3-2-advanced-systems-validation/atdd.md` | ✓ This file |
| Manual test scenarios | `_bmad-output/test-scenarios/epic-6/advanced-systems-validation.md` | Deferred (R17) |

**implementation_checklist_complete:** TRUE (all items `[ ]` — ready for dev-story phase)
**State transition:** STATE_0_STORY_CREATED → **STATE_1_ATDD_READY**
