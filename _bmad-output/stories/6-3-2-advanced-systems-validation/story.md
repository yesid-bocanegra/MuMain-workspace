# Story 6.3.2: Advanced Game Systems Validation

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 6 - Cross-Platform Gameplay Validation |
| Feature | 6.3 - Social & Systems |
| Story ID | 6.3.2 |
| Story Points | 3 |
| Priority | P1 - Should Have |
| Story Type | infrastructure |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-GAME-VALIDATE-SYSTEMS |
| FRs Covered | FR31, FR32, FR34 |
| Prerequisites | 6-2-1-combat-system-validation (done) |

**Story Types:** `backend_api` | `backend_service` | `frontend_feature` | `infrastructure` | `fullstack`

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Add Catch2 test suite for quest, pet, and PvP/duel system validation |
| project-docs | documentation | Story artifacts, test scenarios, validation documentation |

---

## Story

**[VS-1] [Flow:VS1-GAME-VALIDATE-SYSTEMS]**

**As a** player on macOS/Linux,
**I want** quests, pets, and PvP to work correctly,
**so that** all secondary gameplay systems function on all platforms.

---

## Functional Acceptance Criteria

<!-- Functional ACs require live server + platform builds for full end-to-end validation.
     This infrastructure story provides: (a) Catch2 component-level tests for server-independent
     quest/pet/PvP logic, and (b) manual test scenario documentation for when server/platform builds are available.
     ACs are marked with component-level automated coverage status below.
     Full validation deferred to manual execution per Risk R17 (server dependency). -->

- [ ] **AC-1:** Quest UI opens and displays quest information — *Component tests: `MAX_QUESTS` (200), `MAX_QUEST_CONDITION` (16), `MAX_QUEST_REQUEST` (16), `QUEST_STATE_MASK` (0x03), `QUEST_STATES_PER_ENTRY` (4), `QUEST_STATE_BIT_WIDTH` (2), `QUEST_CLASS_ACT` struct layout, `QUEST_CLASS_REQUEST` struct layout, `QUEST_ATTRIBUTE` struct (name buffer, condition/request array sizes), quest view mode enum (`QUEST_VIEW_NONE`..`QUEST_VIEW_END`), quest type enum (`TYPE_QUEST`..`TYPE_QUEST_END`), `SQuestRequest`/`SQuestReward` struct layout, `REQUEST_REWARD_CLASSIFY` enum. Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-2:** Pet companion follows player and can be managed — *Component tests: `PET_TYPE` enum (`PET_TYPE_NONE`=-1, `PET_TYPE_DARK_SPIRIT`=0, `PET_TYPE_DARK_HORSE`=1, `PET_TYPE_END`=2), `PET_COMMAND` enum (`PET_CMD_DEFAULT`..`PET_CMD_END`), `PET_INFO` struct layout (type, exp, level, life, damage, attackSpeed, attackSuccess), pet state enum (`PET_FLYING`..`PET_END`), `PetObject::ActionType` enum (`eAction_Stand`..`eAction_End`), pet type constants (`PC4_ELF`=1..`SKELETON`=7). Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-3:** PvP targeting and combat works between players — *Component tests: `MAX_DUEL_CHANNELS` (4), `_DUEL_PLAYER_TYPE` enum (`DUEL_HERO`=0, `DUEL_ENEMY`=1, `MAX_DUEL_PLAYERS`=2), `DUEL_PLAYER_INFO` struct layout (index, ID, score, hpRate, sdRate), `DUEL_CHANNEL_INFO` struct layout (enable, joinable, id1, id2). Full end-to-end: deferred to manual validation (Risk R17)*
- [ ] **AC-4:** Duel invitation and acceptance work — *Component tests: `CDuelMgr` duel state management constants, `DUEL_PLAYER_INFO` score/hp/sd fields, duel channel enable/joinable flags, `IsDuelArena()` function existence. Event match systems: `CSBaseMatch` inheritance pattern for `CNewBloodCastleSystem` and `CNewChaosCastleSystem`. Full end-to-end: deferred to manual validation (Risk R17)*

---

## Standard Acceptance Criteria

- [ ] **AC-STD-1:** Code Standards Compliance (naming, logging, error taxonomy per project-context.md)
- [ ] **AC-STD-2:** Testing Requirements — Catch2 test suite validates quest/pet/PvP logic where testable without live server
- [ ] **AC-STD-12:** SLI/SLO Targets — Component test suite execution time < 200ms per test case, 0 timeouts in CI runs
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format + cppcheck 0 errors)
- [ ] **AC-STD-14:** Observability — Test output includes struct size validation, enum value coverage counts, and static_assert messages during build
- [ ] **AC-STD-15:** API Contract — N/A (C++ game client test suite; see Contract Catalog Entries)
- [ ] **AC-STD-16:** Correct test infrastructure used (Catch2 v3.7.1, `tests/` directory, CMake auto-discovery)

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [ ] **AC-STD-13:** Quality Gate passes (`./ctl check`)

---

## Validation Artifacts

*Server-dependent validation artifacts removed — require running MU Online server per Risk R17. Manual test scenarios documented at `_bmad-output/test-scenarios/epic-6/advanced-systems-validation.md` for execution when server + platform builds become available.*

---

## Tasks / Subtasks

- [x] Task 1: Create manual test scenario documentation (AC: 1-4)
  - [x] Subtask 1.1: Document quest UI test scenarios (open quest window, view quest list, check quest details, track progress display)
  - [x] Subtask 1.2: Document pet companion test scenarios (summon pet, pet follows player, pet attacks, pet management UI)
  - [x] Subtask 1.3: Document PvP targeting test scenarios (target player, attack player, PvP combat feedback)
  - [x] Subtask 1.4: Document duel system test scenarios (send/receive invitation, accept/decline, duel combat, scoring, spectator mode)
- [x] Task 2: Create Catch2 component test suite (AC: 1-4)
  - [x] Subtask 2.1: Quest system constants and struct validation — `MAX_QUESTS`, `MAX_QUEST_CONDITION`, `MAX_QUEST_REQUEST`, `QUEST_STATE_*` constants, `QUEST_CLASS_ACT`/`QUEST_CLASS_REQUEST`/`QUEST_ATTRIBUTE` struct layouts, quest type/view enums
  - [x] Subtask 2.2: Pet system enums and struct validation — `PET_TYPE` enum, `PET_COMMAND` enum, pet state enum, `PetObject::ActionType` enum, `PET_INFO` struct layout, pet type constants (`PC4_ELF`..`SKELETON`)
  - [x] Subtask 2.3: PvP/Duel system constants and struct validation — `MAX_DUEL_CHANNELS`, `_DUEL_PLAYER_TYPE` enum, `DUEL_PLAYER_INFO`/`DUEL_CHANNEL_INFO` struct layouts
  - [x] Subtask 2.4: Event match system validation — Blood Castle and Chaos Castle type enums, event type constants
- [x] Task 3: Run quality gate (`./ctl check`) and verify 0 errors (AC: STD-13)

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
| Unit | Catch2 v3.7.1 | Logic coverage for quest/pet/PvP systems | Quest constants/structs, pet enums/structs, duel constants/structs, event match types |
| Manual | Screenshots + checklist | All 4 ACs on 3 platforms | Quest UI, pet companion, PvP combat, duel system |
| Regression | Manual comparison | No regression on Windows | Same quest/pet/PvP flows verified on Windows baseline |

---

## Dev Notes

### Architecture Context

- **Quest system:** `CSQuest` (`Gameplay/Social/CSQuest.h/.cpp`) is a singleton (`g_csQuest`) managing quest state via a bitfield array. Each quest stores a 2-bit state (`QUEST_STATE_MASK=0x03`, `QUEST_STATES_PER_ENTRY=4` per byte). `CQuestMng` (`Gameplay/Social/QuestMng.h/.cpp`) handles NPC dialogue, quest progress tracking, and reward distribution. Quest data loaded from script files via `OpenQuestScript()`. UI: `CNewUIMyQuestInfoWindow` displays quest list, `CNewUIQuestProgress` shows active quest progress, `CNewUINPCQuest` handles NPC quest interaction.
- **Quest data structures:** `QUEST_ATTRIBUTE` holds quest name (wchar_t[32]), NPC type, and arrays of `QUEST_CLASS_ACT[MAX_QUEST_CONDITION=16]` (conditions) and `QUEST_CLASS_REQUEST[MAX_QUEST_REQUEST=16]` (requirements). `SQuestRequest`/`SQuestReward` (from `QuestMng.h`) track individual request/reward items with type, index, value, current progress, and item pointer. `REQUEST_REWARD_CLASSIFY` enum distinguishes request vs reward entries.
- **Pet system:** Two pet architectures coexist: (1) `CSPetDarkSpirit` (`Gameplay/Pets/CSPetSystem.h`) for Dark Spirit/Dark Horse pets with `PET_INFO` struct tracking type, level, exp, life, damage, attack stats; (2) `PetProcess` + `PetObject` (`Gameplay/Pets/w_PetProcess.h`, `w_BasePet.h`) for visual pet rendering with state machine (`eAction_Stand`..`eAction_Dead`). `giPetManager` namespace provides top-level lifecycle functions: `CreatePetDarkSpirit()`, `MovePet()`, `RenderPet()`, `DeletePet()`, `SendPetCommand()`. Pet types defined as constants: `PC4_ELF=1`, `PC4_TEST=2`, `PC4_SATAN=3`, `XMAS_RUDOLPH=4`, `UNICORN=6`, `SKELETON=7`.
- **Pet data:** `CHARACTER` struct holds `PET_INFO m_PetInfo[PET_TYPE_END]` (array of 2: Dark Spirit + Dark Horse). `PET_INFO` contains: `m_dwPetType`, `m_dwExp1`/`m_dwExp2`, `m_wLevel`, `m_wLife`, `m_wDamageMin`/`m_wDamageMax`, `m_wAttackSpeed`, `m_wAttackSuccess`. `PET_TYPE` enum: `PET_TYPE_NONE=-1`, `PET_TYPE_DARK_SPIRIT=0`, `PET_TYPE_DARK_HORSE=1`, `PET_TYPE_END=2`. `PET_COMMAND` enum: `PET_CMD_DEFAULT=0`, `PET_CMD_RANDOM=1`, `PET_CMD_OWNER=2`, `PET_CMD_TARGET=3`, `PET_CMD_END=4`. Pet AI state enum: `PET_FLYING=0`..`PET_END=7`.
- **PvP/Duel system:** `CDuelMgr` (`Gameplay/Events/DuelMgr.h/.cpp`) manages 1v1 duels with `MAX_DUEL_CHANNELS=4` concurrent duel arenas. `DUEL_PLAYER_INFO` tracks player index, name, score, HP rate, SD rate. `DUEL_CHANNEL_INFO` tracks channel enable/joinable state and two player names. `g_DuelMgr` is the global instance. `CGMDuelArena` (`World/Maps/GMDuelArena.h`) is the duel arena map class. `IsDuelArena()` checks current map.
- **Event match systems:** `CNewBloodCastleSystem` and `CNewChaosCastleSystem` both inherit from `CSBaseMatch` (`Gameplay/Events/CSEventMatch.h`). They live in `namespace SEASON3B` and implement `RenderMatchTimes()`, `SetMatchGameCommand()`, `SetMatchResult()`, `RenderMatchResult()`. Legacy `CSChaosCastle.h` provides object-level functions for Chaos Castle terrain/units.
- **Summon system:** `CSummonSystem` (`Gameplay/Skills/SummonSystem.h/.cpp`) handles skill-based summons separate from the pet system. Manages DoT effects and summon skill activation.
- **MU Helper:** `MuHelper` (`Gameplay/NPCs/MuHelper.h/.cpp`) is the auto-play system that can automatically activate pets and use skills.

### Key Source Files

| File | Purpose |
|------|---------|
| `src/source/Gameplay/Social/CSQuest.h/.cpp` | Quest state singleton, bitfield state management |
| `src/source/Gameplay/Social/QuestMng.h/.cpp` | Quest progress, NPC dialogue, rewards |
| `src/source/UI/Windows/Quest/NewUIMyQuestInfoWindow.h/.cpp` | Quest list UI window |
| `src/source/UI/Windows/Quest/NewUIQuestProgress.h/.cpp` | Active quest progress display |
| `src/source/Gameplay/Pets/CSPetSystem.h/.cpp` | Pet system base + Dark Spirit implementation |
| `src/source/Gameplay/Pets/GIPetManager.h/.cpp` | Pet lifecycle management namespace |
| `src/source/Gameplay/Pets/w_PetProcess.h/.cpp` | Pet rendering/state process manager |
| `src/source/Gameplay/Pets/w_BasePet.h/.cpp` | PetObject state machine, ActionType enum |
| `src/source/Gameplay/Characters/w_CharacterInfo.h` | PET_INFO struct, CHARACTER pet data |
| `src/source/Gameplay/Events/DuelMgr.h/.cpp` | Duel system manager, channels, spectating |
| `src/source/World/Maps/GMDuelArena.h/.cpp` | Duel arena map class |
| `src/source/UI/Events/NewUIDuelWindow.h/.cpp` | Duel HUD display |
| `src/source/Gameplay/Events/NewBloodCastleSystem.h/.cpp` | Blood Castle event match |
| `src/source/Gameplay/Events/NewChaosCastleSystem.h/.cpp` | Chaos Castle event match |
| `src/source/Gameplay/Events/CSEventMatch.h` | CSBaseMatch base class for event matches |
| `src/source/Gameplay/Skills/SummonSystem.h/.cpp` | Skill-based summon system |
| `src/source/Core/mu_struct.h` | QUEST_CLASS_ACT, QUEST_CLASS_REQUEST, QUEST_ATTRIBUTE structs |
| `src/source/Core/mu_enum.h` | PET_TYPE, PET_COMMAND, pet state, quest type enums |
| `src/source/Core/mu_define.h` | MAX_QUESTS, MAX_QUEST_CONDITION, MAX_QUEST_REQUEST |

### Risk Items

- **R17 (from sprint-status):** All EPIC-6 stories require a running MU Online server for manual validation. Ensure test server is available before starting manual test tasks.
- **R17 Mitigation Strategy:** Same two-tier strategy as 6-2-1/6-2-2/6-3-1: (1) Automated Catch2 component tests validate data structures, enum integrity, constant correctness without server dependency; (2) Manual test scenarios document full end-to-end validation for when server + platform builds are available. Component tests pass now; full end-to-end AC-1..4 validation is deferred to manual execution when R17 is resolved.
- **Two pet architectures:** The codebase has two coexisting pet systems — `CSPetSystem` (data/network) and `PetProcess`/`PetObject` (rendering/animation). Component tests should validate both data model (`PET_INFO` struct, `PET_TYPE` enum) and rendering state machine (`ActionType` enum, pet state enum) independently.
- **Quest state bitfield packing:** Quest states are packed 4-per-byte using 2-bit encoding. Tests should verify the packing constants (`QUEST_STATE_MASK=0x03`, `QUEST_STATES_PER_ENTRY=4`, `QUEST_STATE_BIT_WIDTH=2`) are self-consistent.
- **Generated packet files:** `PacketBindings_ClientToServer.h` and `PacketFunctions_*.h/.cpp` are XSLT-generated — NEVER edit these files.

### PCC Project Constraints

- **Prohibited:** No raw `new`/`delete`, no `NULL`, no `timeGetTime()`, no `#ifdef _WIN32` in game logic, no `wchar_t` in new serialization
- **Required:** `std::unique_ptr`, `nullptr`, `std::chrono::steady_clock`, `std::filesystem::path`, `#pragma once`, Allman braces, 4-space indent
- **Quality gate:** `./ctl check` (clang-format 21.1.8 + cppcheck) — must pass 0 errors
- **Test organization:** `tests/{module}/test_{name}.cpp` mirroring `src/source/{Module}/`
- **References:** `_bmad-output/project-context.md`, `docs/development-standards.md`

### Project Structure Notes

- Tests go in `MuMain/tests/` — e.g., `tests/gameplay/test_advanced_systems_validation.cpp`
- Test binary: `MuTests` target, linked against `MUCore` (and potentially `MUGame` for gameplay logic)
- `MUCore` uses `file(GLOB)` — new `.cpp` files auto-discovered
- For gameplay-level tests involving pet/quest/duel systems, may need `#ifdef MU_GAME_AVAILABLE` compile-time guard (consistent with 6-1-2, 6-2-1, 6-2-2, 6-3-1 patterns)
- Previous stories (6-1-1 through 6-3-1) established pattern: Catch2 `TEST_CASE` / `SECTION` structure, component-level testing of data structures and enums without server dependency

### Dependency Context

This story sits on the **critical path** for EPIC-6:
- **Depends on:** 6-2-1-combat-system-validation (done) — combat must work for PvP/duel validation
- **Unblocks:** Nothing — this is the end of the critical path chain (6.1.1 → 6.1.2 → 6.2.1 → 6.3.2)

Previous stories established:
- 6-1-1: Catch2 test patterns for scene state validation, quality gate workflow
- 6-1-2: `#ifdef MU_GAME_AVAILABLE` compile-time guard pattern, boundary condition testing
- 6-2-1: Combat data structure validation (34 TEST_CASEs), non-aliasing proof pattern, pairwise uniqueness checks
- 6-2-2: Inventory/trading data structure validation (24 TEST_CASEs), `STORAGE_TYPE` pairwise distinctness, comprehensive enum coverage
- 6-3-1: Social systems validation (17 TEST_CASEs), `static_assert` for struct layout validation, guild enum bit-flag validation

### Previous Story Intelligence

From 6-3-1 code review learnings:
- Use `static_assert` for struct layout validation where possible (verified at compile time, more reliable than runtime checks)
- Ensure pairwise uniqueness checks cover ALL enum values (not just a subset)
- Keep ATDD checklist synchronized with actual test implementation
- Clearly distinguish component tests (automated, no server) from end-to-end tests (manual, server required)
- Avoid misleading comments that describe incorrect behavior — match comments to actual test logic
- Eliminate redundant runtime assertions after `static_assert` (prefer compile-time checks)

---

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

N/A — no debug issues encountered.

### Completion Notes List

- All 3 tasks completed: manual test scenarios, Catch2 component test suite (20 TEST_CASEs), quality gate verification
- ATDD checklist 29/29 items checked — 100% coverage
- Infrastructure story: no server-dependent gates (AC compliance, design compliance, frontend completeness all N/A)
- Quality gate passed: 711/711 files, 0 errors (clang-format 21.1.8 + cppcheck)
- Test file created in RED phase (ATDD step), verified compilable in GREEN phase (dev-story step)
- Manual test scenarios document deferred E2E validation for Risk R17 (server dependency)
- Critical path Track B complete: 6-1-1 → 6-1-2 → 6-2-1 → 6-3-2 chain finished

### File List

| File | Action | Notes |
|------|--------|-------|
| `MuMain/tests/gameplay/test_advanced_systems_validation.cpp` | Created (ATDD) | 20 TEST_CASEs: quest, pet, PvP/duel validation |
| `MuMain/tests/CMakeLists.txt` | Modified (ATDD) | Added target_sources entry at line 238 |
| `_bmad-output/test-scenarios/epic-6/advanced-systems-validation.md` | Created | Manual test scenarios for AC-1..4, platform matrix |
| `_bmad-output/stories/6-3-2-advanced-systems-validation/atdd.md` | Modified | All 29 checklist items marked [x] |
| `_bmad-output/stories/6-3-2-advanced-systems-validation/story.md` | Modified | Tasks marked complete, status → review |
| `_bmad-output/stories/6-3-2-advanced-systems-validation/progress.md` | Created | Session tracking, 3/3 tasks complete |
| `_bmad-output/implementation-artifacts/sprint-status.yaml` | Modified | Story status: ready-for-dev → in-progress → review |
