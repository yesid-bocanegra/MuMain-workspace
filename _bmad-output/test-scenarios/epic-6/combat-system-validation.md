# Test Scenarios: Story 6.2.1 — Combat System Validation

**Story ID:** 6.2.1
**Epic:** 6 — Cross-Platform Gameplay Validation
**Flow Code:** VS1-GAME-VALIDATE-COMBAT
**Date:** 2026-03-21
**Test Type:** Manual + Catch2 Unit

---

## Overview

This document defines the complete test plan for validating the combat system (melee attacks,
skill activation, monster death/loot, player death/respawn, health/mana bars, and combat audio)
works correctly on macOS, Linux, and Windows (regression).

Automated Catch2 tests cover pure logic (skill enums, sound enum ranges, struct constants,
DemendConditionInfo requirement checking). Platform rendering and server-interaction tests
are manual-only.

**Prerequisites:**
- Running MU Online test server (live game required for AC-1..6 full validation)
- macOS build: `cmake --preset macos-arm64 && cmake --build --preset macos-arm64-debug`
- Linux build: MinGW cross-compile or native Linux build
- Windows build: `cmake --preset windows-x64 && cmake --build --preset windows-x64-debug`

> **Risk R17:** All full AC-1..6 scenarios require a running MU Online server for actual
> in-game validation. Catch2 tests cover server-independent component logic only.

---

## Automated Tests (Catch2 — Headless, No Server Required)

### Unit Test File
`MuMain/tests/gameplay/test_combat_system_validation.cpp`

### Test Coverage

| Test Case | AC | Expected Phase |
|-----------|-----|----------------|
| `AC-1 [6-2-1]: ActionSkillType defines correct IDs for melee attack skills` | AC-1 | RED→GREEN |
| `AC-1 [6-2-1]: ActionSkillType melee skill IDs are all distinct` | AC-1 | RED→GREEN |
| `AC-2 [6-2-1]: Skill attribute struct constants define correct array dimensions` | AC-2 | RED→GREEN |
| `AC-2 [6-2-1]: SKILL_ATTRIBUTE_FILE Name buffer has correct byte size for BMD parsing` | AC-2 | RED→GREEN |
| `AC-2 [6-2-1]: SKILL_ATTRIBUTE runtime Name buffer has wide-character size` | AC-2 | RED→GREEN |
| `AC-2 [6-2-1]: DemendConditionInfo default-constructs with all stat requirements at zero` | AC-2 | RED→GREEN |
| `AC-2 [6-2-1]: DemendConditionInfo operator<= validates all stat thresholds` | AC-2 | RED→GREEN |
| `AC-2 [6-2-1]: ActionSkillType magic and support skill values` | AC-2 | RED→GREEN |
| `AC-3 [6-2-1]: MonsterSkillType defines correct base values for monster behavior` | AC-3 | RED→GREEN |
| `AC-3 [6-2-1]: MonsterSkillType basic skill values are all distinct` | AC-3 | RED→GREEN |
| `AC-4 [6-2-1]: AT_SKILL_UNDEFINED is 0 — initial and post-death state sentinel` | AC-4 | RED→GREEN |
| `AC-4 [6-2-1]: AT_SKILL_MASTER_END defines master skill index upper bound at 608` | AC-4 | RED→GREEN |
| `AC-4 [6-2-1]: AT_SKILL_MASTER_END is within MAX_SKILLS skill array capacity` | AC-4 | RED→GREEN |
| `AC-5 [6-2-1]: MAX_SKILLS defines per-character skill array capacity as 650` | AC-5 | RED→GREEN |
| `AC-5 [6-2-1]: SKILL_ATTRIBUTE Mana and Damage fields are independently addressable` | AC-5 | RED→GREEN |
| `AC-5 [6-2-1]: SKILL_ATTRIBUTE RequireClass array has MAX_CLASS entries` | AC-5 | RED→GREEN |
| `AC-6 [6-2-1]: SOUND_BRANDISH_SWORD enum values for melee attack swing sounds` | AC-6 | RED→GREEN |
| `AC-6 [6-2-1]: SOUND_ATTACK_MELEE_HIT sounds form a range of 5 consecutive IDs` | AC-6 | RED→GREEN |
| `AC-6 [6-2-1]: SOUND_MONSTER macro range covers IDs 210 to 450` | AC-6 | RED→GREEN |
| `AC-6 [6-2-1]: SOUND_MONSTER_BULL1 is the first monster enum entry matching SOUND_MONSTER` | AC-6 | RED→GREEN |
| `AC-6 [6-2-1]: Combat sound ranges are mutually non-overlapping` | AC-6 | RED→GREEN |
| `Task-2.4 [6-2-1]: eBuffState sentinel and combat-relevant buff values` | Task-2.4 | RED→GREEN |
| `Task-2.4 [6-2-1]: eBuffState debuff sentinel values for combat effects` | Task-2.4 | RED→GREEN |
| `Task-2.4 [6-2-1]: eBuffClass categorises buffs and debuffs` | Task-2.4 | RED→GREEN |
| `Task-2.5 [6-2-1]: Item set system constants define correct capacities` | Task-2.5 | RED→GREEN |
| `Task-2.5 [6-2-1]: ITEM_SET_TYPE struct has correct array dimensions` | Task-2.5 | RED→GREEN |
| `Task-2.5 [6-2-1]: ITEM_SET_OPTION struct has correct nested array dimensions` | Task-2.5 | RED→GREEN |
| `Task-2.5 [6-2-1]: SET_OPTION struct fields are independently addressable` | Task-2.5 | RED→GREEN |
| `AC-1 [6-2-1]: CSkillManager::GetSkillInformation runtime lookup` (SKIP — needs MUGame) | AC-1 | SKIP |
| `AC-2 [6-2-1]: CSkillManager::CheckSkillDelay activation gating` (SKIP — needs MUGame) | AC-2 | SKIP |
| `AC-3 [6-2-1]: Script_Skill array capacity` (SKIP — needs MUGame) | AC-3 | SKIP |
| `AC-1 [6-2-1]: SetPlayerAttack and AttackStage state transitions` (SKIP — needs MUGame) | AC-1 | SKIP |
| `Task-2.4 [6-2-1]: w_BuffStateSystem RegisterBuff/UnRegisterBuff runtime` (SKIP — needs MUGame) | Task-2.4 | SKIP |
| `Task-2.5 [6-2-1]: GetAttackDamage min/max calculation` (SKIP — needs MUGame) | Task-2.5 | SKIP |

---

## Manual Test Scenarios

### Scenario 1: Melee Attacks — Hit Monsters with Damage Numbers (AC-1)

**Platforms:** macOS, Linux, Windows (regression)
**Risk R17 note:** Requires running MU Online test server.

**Steps:**
1. Log in and enter Lorencia with a Dark Knight character.
2. Target a Bull (lowest-level monster) near the starting area.
3. Left-click to initiate a melee attack.

**Expected Results:**
- Character plays attack animation (sword swing).
- Combat sound plays (SOUND_BRANDISH_SWORD01/02/03/04 range).
- Damage number appears above monster's head.
- Monster health bar decreases.

**Evidence Required:** Screenshot or video showing damage numbers and health bar reduction.

---

### Scenario 2: Skill Activation — Hotkey and Click-to-Cast (AC-2)

**Platforms:** macOS, Linux, Windows (regression)
**Risk R17 note:** Requires running MU Online test server.

**Steps:**
1. Assign a skill (e.g., Cyclone for Dark Knight, Fireball for Dark Wizard) to a hotkey slot.
2. Target a monster.
3. Press the assigned hotkey.
4. Also test click-to-cast from the skill bar.

**Expected Results:**
- Skill activation animation plays.
- Skill visual effect renders correctly (particle effect, impact).
- Mana cost is deducted from the mana bar.
- Damage is applied to the target.

**Evidence Required:** Screenshot showing skill effect rendered and mana bar reduced.

---

### Scenario 3: Monster Death and Loot Drops (AC-3)

**Platforms:** macOS, Linux, Windows (regression)
**Risk R17 note:** Requires running MU Online test server.

**Steps:**
1. Kill a monster (Bull, Hound, or Goblin near Lorencia).
2. Observe the death animation.
3. Check the ground for loot after the death animation completes.

**Expected Results:**
- Monster plays death animation.
- Monster disappears after animation completes.
- Loot item (or Zen) drops at the monster's position.
- Loot item is pickable by the player.

**Evidence Required:** Screenshot showing loot drop on ground after monster death.

---

### Scenario 4: Player Death and Respawn (AC-4)

**Platforms:** macOS, Linux, Windows (regression)
**Risk R17 note:** Requires running MU Online test server. Use a low-level character
near a strong monster or arrange PK death in a test environment.

**Steps:**
1. Allow the character to die (zero HP).
2. Observe the death animation.
3. Wait for the respawn prompt.
4. Confirm respawn at the default respawn point.

**Expected Results:**
- Character plays death animation (fall to ground).
- Death sound plays.
- "You have died" message or respawn UI appears.
- Character respawns at Lorencia starting point with full HP/MP.
- All combat state is cleared (no active skill effect, no attack state).

**Evidence Required:** Screenshot of respawn UI and character at respawn point with full HP bar.

---

### Scenario 5: Health and Mana Bars Update During Combat (AC-5)

**Platforms:** macOS, Linux, Windows (regression)
**Risk R17 note:** Requires running MU Online test server.

**Steps:**
1. Enter combat with a monster.
2. Take damage from a monster attack.
3. Cast a skill to consume mana.
4. Use a health/mana potion.

**Expected Results:**
- HP bar decreases when taking damage (proportional to damage received).
- MP bar decreases when casting skills (by the skill's mana cost).
- HP/MP bars increase when potions are consumed.
- Numerical HP/MP values in the character info window match bar display.

**Evidence Required:** Screenshot series showing HP and MP bars changing across combat states.

---

### Scenario 6: Combat Audio — Sword Swings, Monster Hits, and Skill Sounds (AC-6)

**Platforms:** macOS, Linux, Windows (regression)
**Risk R17 note:** Requires running MU Online test server with audio enabled.
**Note:** EPIC-5 migrated the audio backend to miniaudio (DSPlaySound.h enums are used
by the new backend via the DSPlaySound shim).

**Steps:**
1. Ensure audio is enabled in game settings (volume > 0).
2. Perform melee attacks on a monster and listen for sword swing sounds.
3. Receive a hit from a monster and listen for the impact sound.
4. Cast a skill and listen for the skill activation sound.
5. Kill a monster and listen for its death sound.

**Expected Results:**
- Sword swing sound plays on each melee attack (SOUND_BRANDISH_SWORD range: 60-63).
- Hit impact sound plays when a melee attack connects (SOUND_ATTACK_MELEE_HIT range: 70-74).
- Monster ambient sounds play periodically (SOUND_MONSTER range: 210-450).
- Monster death sound plays on kill (within SOUND_MONSTER range).
- No audio stuttering, skipping, or crashes on any platform.

**Evidence Required:** Note confirming audio plays correctly on each platform (video preferred).

---

## Platform Validation Matrix

| AC | Automated (Catch2) | macOS Manual | Linux Manual | Windows Manual |
|----|-------------------|--------------|--------------|----------------|
| AC-1 | Enum coverage | Required (R17) | Required (R17) | Required (regression) |
| AC-2 | Struct + operator | Required (R17) | Required (R17) | Required (regression) |
| AC-3 | Enum coverage | Required (R17) | Required (R17) | Required (regression) |
| AC-4 | Enum sentinel | Required (R17) | Required (R17) | Required (regression) |
| AC-5 | Struct fields | Required (R17) | Required (R17) | Required (regression) |
| AC-6 | Sound enum range | Required (R17) | Required (R17) | Required (regression) |

---

## Notes

- **R17 Mitigation:** Automated Catch2 tests validate all server-independent component logic
  (enum values, struct layouts, data structure contracts). Manual scenarios validate the full
  end-to-end combat flow once the test server is available.
- **Generated files:** `PacketFunctions_ClientToServer.h` (combat network packets) is
  XSLT-generated — NEVER edit. Test combat packet function signatures are out of scope.
- **Combat complexity:** The combat system spans many subsystems. Component tests focus on
  data structure contracts; full behavior validation requires the live game loop.
