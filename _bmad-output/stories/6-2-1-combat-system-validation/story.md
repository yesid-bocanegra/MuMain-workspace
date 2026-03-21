# Story 6.2.1: Combat System Validation

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 6 - Cross-Platform Gameplay Validation |
| Feature | 6.2 - Combat & Economy |
| Story ID | 6.2.1 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | infrastructure |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-GAME-VALIDATE-COMBAT |
| FRs Covered | FR26, FR27, FR28 |
| Prerequisites | 6-1-2-world-navigation-validation (done) |

**Story Types:** `backend_api` | `backend_service` | `frontend_feature` | `infrastructure` | `fullstack`

### Affected Components

<!-- Which components does this story modify? List ALL affected components from .pcc-config.yaml -->
<!-- The first backend/frontend listed becomes the primary target for quality gates -->

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Add Catch2 test suite for combat system validation (skills, attacks, effects, health/mana) |
| project-docs | documentation | Story artifacts, test scenarios, validation documentation |

---

## Story

**[VS-1] [Flow:VS1-GAME-VALIDATE-COMBAT]**

**As a** player on macOS/Linux,
**I want** combat (melee, ranged, skills) to work correctly with monsters and players,
**so that** the core gameplay loop functions on all platforms.

---

## Functional Acceptance Criteria

<!-- Functional ACs require live server + platform builds for full end-to-end validation.
     This infrastructure story provides: (a) Catch2 component-level tests for server-independent
     combat logic, and (b) manual test scenario documentation for when server/platform builds are available.
     ACs are marked with component-level automated coverage status below.
     Full validation deferred to manual execution per Risk R17 (server dependency). -->

- [ ] **AC-1:** Melee attacks hit monsters, damage numbers display — *Component tests: attack animation states, `SetPlayerAttack()` state transitions, `AttackStage()` sequencing. Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-2:** Skill activation (hotkey or click) works, effects render — *Component tests: `CSkillManager::GetSkillInformation()` data validation, skill delay checking, skill type enumeration. Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-3:** Monster death animations and loot drops work — *Component tests: death/loot object type validation, item drop data structures. Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-4:** Player death and respawn work — *Component tests: death state transitions, respawn state management. Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-5:** Health/mana bars update correctly — *Component tests: character attribute data structures, HP/MP value ranges. Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-6:** Audio: combat sound effects play (depends on EPIC-5) — *Component tests: combat sound enum validation (`SOUND_BRANDISH_SWORD01..03`, `SOUND_MONSTER` range 210-450). Full end-to-end: deferred to manual validation (Risk R17)*

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance (naming, logging, error taxonomy per project-context.md)
- [ ] **AC-STD-2:** Testing Requirements — Catch2 test suite validates combat logic where testable without live server
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

- [ ] Task 1: Create test scenario documentation for combat system validation (AC: VAL-6)
  - [ ] Subtask 1.1: Document manual test plan for melee attacks (target monster, verify damage numbers)
  - [ ] Subtask 1.2: Document manual test plan for skill activation (hotkey bar, click-to-cast, effect rendering)
  - [ ] Subtask 1.3: Document manual test plan for monster death and loot drops
  - [ ] Subtask 1.4: Document manual test plan for player death and respawn
  - [ ] Subtask 1.5: Document manual test plan for health/mana bar updates during combat
  - [ ] Subtask 1.6: Document manual test plan for combat audio (sword swings, monster hits, skill sounds)
- [ ] Task 2: Create Catch2 test suite for combat system validation logic (AC: 1-6, STD-2)
  - [ ] Subtask 2.1: Test skill data structures — `CSkillManager` skill information lookup, skill type enums, delay validation
  - [ ] Subtask 2.2: Test combat sound enums — validate `SOUND_BRANDISH_SWORD*` and `SOUND_MONSTER` range coverage
  - [ ] Subtask 2.3: Test combat-related data structures — `Script_Skill`, attack type enums, `MonsterSkillType`
  - [ ] Subtask 2.4: Test buff system data structures — `w_BuffStateSystem` state management, buff type enums
  - [ ] Subtask 2.5: Test item combat attributes — `GetAttackDamage()` min/max calculation structures, `CSItemOption` bonus types
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
| Unit | Catch2 v3.7.1 | Logic coverage for combat systems | Skill data validation, combat enums, attack structures, buff states, sound enums |
| Manual | Screenshots + checklist | All 6 ACs on 3 platforms | Melee, skills, death/loot, respawn, health/mana, audio |
| Regression | Manual comparison | No regression on Windows | Same combat flows verified on Windows baseline |

---

## Dev Notes

### Architecture Context

- **Combat core:** `ZzzCharacter.h/.cpp` is the central hub for character combat actions — `SetPlayerAttack()`, `SetPlayerMagic()`, `SetPlayerDie()`, `SetPlayerShock()`, `AttackStage()`, `CharacterAnimation()`. Also handles `CreateMonster()` and `CreateHero()`.
- **Skill system:** `CSkillManager` (`Gameplay/Skills/SkillManager.h/.cpp`) manages skill information, damage calculation, delay checking, and mastery types. Key methods: `GetSkillInformation()`, `GetSkillInformation_Damage()`, `CheckSkillDelay()`.
- **Skill effects:** `CSkillEffectMgr` (`Gameplay/Skills/SkillEffectMgr.h/.cpp`) manages visual effect objects for skills — `CreateEffect()`, `DeleteEffect()`, `SearchEffect()`, `MoveEffects()`.
- **Buff system:** `w_BuffStateSystem` (`Gameplay/Buffs/`) manages buffs/debuffs with value control, time tracking, and script-loaded configurations.
- **Combat effects rendering:** `ZzzEffect.h/.cpp` provides `CreateEffect()`, `CreateBlood()`, `CreateSpark()`, `CreateBlur()`, `CreateHealing()`. Large files: `ZzzEffectJoint.cpp` (296KB), `ZzzEffectParticle.cpp` (415KB), `ZzzEffectMagicSkill.cpp`.
- **Monster AI:** `ZzzAI.h/.cpp` controls monster combat behavior including `MonsterSkill[]` array for special attacks.
- **Items & loot:** `ZzzObject.h/.cpp` handles `CreateItemDrop()`, `CreateMoneyDrop()`. `ZzzInventory.h` provides `GetAttackDamage()` for min/max damage from equipment. `CSItemOption.h/.cpp` manages item combat bonuses.
- **Summon/pets:** `CSummonSystem` (`Gameplay/Skills/SummonSystem.h/.cpp`) handles summon skills, pet combat, and DoT effects.
- **PvP systems:** `DuelMgr` (1v1 duels), `CSChaosCastle`, `NewBloodCastleSystem`, `w_CursedTemple` — event-based combat modes.
- **Network combat packets:** `PacketFunctions_ClientToServer.h` provides `SendHitRequest(targetId, attackAnimation, lookingDirection)`, `SendTargetedSkill(skillId, targetId)`, `SendRageAttackRequest()`, `SendRageAttackRangeRequest()`.
- **Combat audio:** `DSPlaySound.h` defines enums — `SOUND_BRANDISH_SWORD01/02/03` for melee, `SOUND_MONSTER` range (210-450) for monster sounds. EPIC-5 migrated to miniaudio backend.
- **Health/mana UI:** `NewUIMainFrameWindow.h/.cpp` (81KB) handles the main HUD with health/mana display logic. `w_CharacterInfo.h/.cpp` manages character attribute state.
- **Monk system:** `MonkSystem.h/.cpp` implements class-specific combat with `SendAttackPacket()`.
- **Map-specific combat:** `GMHellas.h` implements map-specific monster skills (`CreateMonsterSkill_ReduceDef()`, `CreateMonsterSkill_Poison()`, `CreateMonsterSkill_Summon()`).

### Key Source Files

| File | Purpose |
|------|---------|
| `src/source/Gameplay/Characters/ZzzCharacter.h/.cpp` | Character combat: attack, magic, death, animation states |
| `src/source/Gameplay/Skills/SkillManager.h/.cpp` | Skill data, damage calc, delay, mastery |
| `src/source/Gameplay/Skills/SkillEffectMgr.h/.cpp` | Skill visual effect management |
| `src/source/Gameplay/Skills/SummonSystem.h/.cpp` | Summon/pet skills, DoT effects |
| `src/source/Gameplay/Buffs/w_BuffStateSystem.h/.cpp` | Buff/debuff state management |
| `src/source/Gameplay/Characters/ZzzAI.h/.cpp` | Monster AI combat behavior |
| `src/source/Gameplay/Characters/MonkSystem.h/.cpp` | Monk class-specific combat |
| `src/source/Gameplay/Items/ZzzInventory.h` | `GetAttackDamage()` damage calculation |
| `src/source/Gameplay/Items/CSItemOption.h/.cpp` | Item combat bonuses |
| `src/source/Gameplay/Characters/ZzzObject.h/.cpp` | Item/money drops, world objects |
| `src/source/RenderFX/ZzzEffect.h/.cpp` | Combat effect rendering (blood, spark, healing) |
| `src/source/RenderFX/ZzzEffectMagicSkill.cpp` | Magic skill effect rendering |
| `src/source/Audio/DSPlaySound.h` | Combat sound enum definitions |
| `src/source/UI/Windows/HUD/NewUIMainFrameWindow.h/.cpp` | HUD with health/mana bars |
| `src/source/Gameplay/Characters/w_CharacterInfo.h/.cpp` | Character attributes (HP, MP, stats) |
| `src/source/Data/Skills/SkillStructs.h` | Skill data structures |
| `src/source/Core/mu_struct.h` | `Script_Skill`, combat data structs |
| `src/source/Core/mu_enum.h` | `MonsterSkillType`, attack type enums |
| `src/source/Dotnet/PacketFunctions_ClientToServer.h` | Combat network packets (NEVER EDIT — generated) |
| `src/source/Gameplay/Events/DuelMgr.h/.cpp` | PvP duel system |

### Risk Items

- **R17 (from sprint-status):** All EPIC-6 stories require a running MU Online server for manual validation. Ensure test server is available before starting manual test tasks.
- **R17 Mitigation Strategy:** This infrastructure story addresses R17 by splitting validation into two tiers: (1) Automated Catch2 component tests run without server dependency — validating skill data structures, combat enums, sound enum ranges, buff system states, and item attribute calculations; (2) Manual test scenarios (documented in `_bmad-output/test-scenarios/epic-6/combat-system-validation.md`) define the full end-to-end validation steps for when server + platform builds become available. Component tests pass now; full end-to-end AC-1..6 validation is deferred to manual execution when R17 is resolved.
- **Combat system complexity:** The combat system spans many subsystems (skills, buffs, effects, AI, pets, PvP events). Component tests should focus on data structure validation and enum coverage rather than attempting to test tightly-coupled runtime behavior.
- **Generated packet files:** `PacketFunctions_ClientToServer.h/.cpp` and `PacketBindings_*.h` are XSLT-generated — NEVER edit these files. Test combat packet function signatures exist but do not test packet serialization.

### PCC Project Constraints

- **Prohibited:** No raw `new`/`delete`, no `NULL`, no `timeGetTime()`, no `#ifdef _WIN32` in game logic, no `wchar_t` in new serialization
- **Required:** `std::unique_ptr`, `nullptr`, `std::chrono::steady_clock`, `std::filesystem::path`, `#pragma once`, Allman braces, 4-space indent
- **Quality gate:** `./ctl check` (clang-format 21.1.8 + cppcheck) — must pass 0 errors
- **Test organization:** `tests/{module}/test_{name}.cpp` mirroring `src/source/{Module}/`
- **References:** `_bmad-output/project-context.md`, `docs/development-standards.md`

### Project Structure Notes

- Tests go in `MuMain/tests/` — e.g., `tests/gameplay/test_combat_system_validation.cpp`
- Test binary: `MuTests` target, linked against `MUCore` (and potentially `MUGame` for gameplay logic)
- `MUCore` uses `file(GLOB)` — new `.cpp` files auto-discovered
- For gameplay-level tests, may need to link against `MUGame` or extract testable logic into headers
- Previous stories (6-1-1, 6-1-2) established pattern: Catch2 `TEST_CASE` / `SECTION` structure, component-level testing of data structures and enums without server dependency

### Dependency Context

This story sits on the **critical path** for EPIC-6:
- **Depends on:** 6-1-2-world-navigation-validation (done) — player can navigate to combat areas
- **Unblocks:** 6-3-2-advanced-systems-validation — advanced systems require combat working

Previous stories established:
- 6-1-1: Catch2 test patterns for scene state validation, `SceneCommon.h` encapsulation, quality gate workflow
- 6-1-2: Catch2 test patterns for world/map data validation (ENUM_WORLD, pathfinding, gate data), `#ifdef MU_GAME_AVAILABLE` compile-time guard for tests requiring MUGame linkage, boundary condition testing patterns

### Previous Story Intelligence

From 6-1-2 code review learnings:
- Use `#ifdef MU_GAME_AVAILABLE` compile-time guard when test code references MUGame-only types
- Avoid parameter documentation mismatches in test comments
- Add boundary condition tests (not just happy-path)
- Clearly distinguish component tests (automated, no server) from end-to-end tests (manual, server required)
- Keep ATDD checklist synchronized with actual test implementation

---

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes

### File List
