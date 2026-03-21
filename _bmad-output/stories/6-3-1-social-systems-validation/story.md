# Story 6.3.1: Social Systems Validation

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

---

## Story Metadata

| Attribute | Value |
|-----------|-------|
| Epic | 6 - Cross-Platform Gameplay Validation |
| Feature | 6.3 - Social & Systems |
| Story ID | 6.3.1 |
| Story Points | 3 |
| Priority | P0 - Must Have |
| Story Type | infrastructure |
| Value Stream | VS-1 (Core Experience) |
| Flow Code | VS1-GAME-VALIDATE-SOCIAL |
| FRs Covered | FR29, FR30, FR36 |
| Prerequisites | 6-1-1-auth-character-validation (done) |

**Story Types:** `backend_api` | `backend_service` | `frontend_feature` | `infrastructure` | `fullstack`

### Affected Components

| Component | Tags | Change Summary |
|-----------|------|----------------|
| mumain | backend | Add Catch2 test suite for chat, party, and guild data structure validation on cross-platform builds |
| project-docs | documentation | Story artifacts, test scenarios, validation documentation |

---

## Story

**[VS-1] [Flow:VS1-GAME-VALIDATE-SOCIAL]**

**As a** player on macOS/Linux,
**I want** guilds, parties, and chat to work correctly,
**so that** multiplayer social features function on all platforms.

---

## Functional Acceptance Criteria

<!-- Functional ACs require live server + platform builds for full end-to-end validation.
     This infrastructure story provides: (a) Catch2 component-level tests for server-independent
     chat/party/guild logic, and (b) manual test scenario documentation for when server/platform builds are available.
     ACs are marked with component-level automated coverage status below.
     Full validation deferred to manual execution per Risk R17 (server dependency). -->

- [x] **AC-1:** Chat messages send and receive (normal, party, guild, whisper channels) — *Component tests: `MESSAGE_TYPE` enum completeness and uniqueness, `INPUT_MESSAGE_TYPE` enum values, `MAX_CHAT_SIZE` constant (90), chat buffer sizes (`MAX_CHAT_BUFFER_SIZE`=60, `MAX_NUMBER_OF_LINES`=200), `PCHATING`/`PCHATING_KEY` packet struct layout. Full end-to-end: deferred to manual validation (Risk R17)*
- [x] **AC-2:** Party creation, invitation, and member display work — *Component tests: `MAX_PARTYS` constant (5), `PARTY_t` struct layout (Name, Number, Map, x, y, currHP, maxHP, stepHP, index), party window dimension constants, `CPartyManager` singleton accessibility pattern. Full end-to-end: deferred to manual validation (Risk R17)*
- [x] **AC-3:** Guild information panel displays correctly — *Component tests: `GuildConstants::GUILD_NAME_LENGTH` (8), `GuildConstants::GUILD_MARK_SIZE` (64), `GuildConstants::MAX_CAPACITY` (80), `GuildTab` enum (INFO/MEMBERS/UNION), `GuildInfoButton` enum (6 values), `RelationshipType` enum values, `GUILD_LIST_t` struct layout, `MARK_t` struct layout. Full end-to-end: deferred to manual validation (Risk R17)*
- [x] **AC-4:** Player names and guild tags render above characters — *Component tests: guild color constants (`GuildConstants::Colors::YELLOW`, `WHITE`, `GRAY`), `MAX_MARKS` constant (2000), `MARK_t` guild/union name buffer sufficiency. CHARACTER guild-related fields (GuildStatus, GuildType, GuildRelationShip, GuildMarkIndex) validated via manual test scenarios. Full end-to-end: deferred to manual validation (Risk R17)*
- [x] **AC-5:** Chat encoding: Korean and Latin characters display correctly (char16_t validation) — *Component tests: `char16_t` parameter types in `SendPublicChatMessage`/`SendWhisperMessage` packet bindings, `MAX_CHAT_SIZE` alignment with packet field sizes, `MAX_USERNAME_SIZE` constant used in guild/party name buffers. Full end-to-end: deferred to manual validation (Risk R17)*

---

## Standard Acceptance Criteria

- [x] **AC-STD-1:** Code Standards Compliance (naming, logging, error taxonomy per project-context.md)
- [x] **AC-STD-2:** Testing Requirements — Catch2 test suite validates chat/party/guild logic where testable without live server
- [x] **AC-STD-13:** Quality Gate passes (`./ctl check` — clang-format + cppcheck 0 errors)
- [x] **AC-STD-15:** Git Safety (no incomplete rebase, no force push)
- [x] **AC-STD-16:** Correct test infrastructure used (Catch2 v3.7.1, `tests/` directory)

### NFR Acceptance Criteria (Type-Specific)

**For ALL stories:**
- [x] **AC-STD-13:** Quality Gate passes (`./ctl check`)

---

## Validation Artifacts

*Server-dependent validation artifacts (AC-VAL-1 through AC-VAL-4) removed — require running MU Online server per Risk R17. Manual test scenarios documented at `_bmad-output/test-scenarios/epic-6/social-systems-validation.md` for execution when server + platform builds become available.*

---

## Tasks / Subtasks

- [x] Task 1: Create manual test scenario documentation (AC: 1-5)
  - [x] Subtask 1.1: Document chat channel test scenarios (normal, party, guild, whisper)
  - [x] Subtask 1.2: Document party lifecycle test scenarios (create, invite, display members)
  - [x] Subtask 1.3: Document guild panel test scenarios (info tab, members tab, union tab)
  - [x] Subtask 1.4: Document player name/guild tag rendering test scenarios
  - [x] Subtask 1.5: Document Korean/Latin chat encoding test scenarios
- [x] Task 2: Create Catch2 component test suite (AC: 1-5)
  - [x] Subtask 2.1: Chat system constants and enum validation tests
  - [x] Subtask 2.2: Party system constants and struct validation tests
  - [x] Subtask 2.3: Guild system constants, enums, and struct validation tests
  - [x] Subtask 2.4: Character guild field and rendering constant tests
  - [x] Subtask 2.5: Chat encoding and packet struct validation tests
- [x] Task 3: Run quality gate (`./ctl check`) and verify 0 errors (AC: STD-13)

---

## Test Design

| Test Type | Tool | Coverage Target | Key Scenarios |
|-----------|------|-----------------|---------------|
| Unit | Catch2 v3.7.1 | Logic coverage for chat/party/guild systems | MESSAGE_TYPE enum, PARTY_t struct, GuildConstants, guild marks, chat encoding |
| Manual | Screenshots + checklist | All 5 ACs on 3 platforms | Chat channels, party lifecycle, guild panel, name rendering, Korean text |
| Regression | Manual comparison | No regression on Windows | Same social flows verified on Windows baseline |

---

## Dev Notes

### Architecture Context

- **Chat system:** `CNewUIChatLogWindow` (`UI/Windows/NewUIChatLogWindow.h/.cpp`) displays chat history with filtering by `MESSAGE_TYPE`. `CNewUIChatInputBox` (`UI/Windows/NewUIChatInputBox.h/.cpp`) handles message composition with `INPUT_MESSAGE_TYPE` channel selection. Chat packets use `PCHATING`/`PCHATING_KEY` structs from `Network/WSclient.h`. Network layer sends via `SendPublicChatMessage()`/`SendWhisperMessage()` with `char16_t` parameters in `PacketBindings_ClientToServer.h` (NEVER EDIT — generated).
- **Party system:** `CNewUIPartyInfoWindow` (`UI/Windows/Social/NewUIPartyInfoWindow.h/.cpp`) shows full party info with HP bars. `CNewUIPartyListWindow` (`UI/Windows/Social/NewUIPartyListWindow.h/.cpp`) is the compact HUD display. `CPartyManager` (`Gameplay/Social/PartyManager.h`) is the singleton managing party state with `PARTY_t` struct tracking name, map location, HP. `MAX_PARTYS=5` is the party size limit.
- **Guild system:** `CNewUIGuildInfoWindow` (`UI/Windows/Social/NewUIGuildInfoWindow.h/.cpp`) displays guild info with tabs (Info/Members/Union). `CNewUIGuildMakeWindow` (`UI/Windows/Social/NewUIGuildMakeWindow.h/.cpp`) handles guild creation with mark editor. `CGuildCache` (`Gameplay/Social/GuildCache.h`) caches guild marks indexed by guild key. `GuildConstants` (`Gameplay/Social/GuildConstants.h`) centralizes all guild constants including `GUILD_NAME_LENGTH=8`, `GUILD_MARK_SIZE=64`, `MAX_CAPACITY=80`.
- **Player name/guild tag rendering:** `CNewUINameWindow` (`UI/Windows/HUD/NewUINameWindow.h/.cpp`) renders names above characters. `CHARACTER` struct has guild fields: `GuildStatus`, `GuildType`, `GuildRelationShip`, `GuildMarkIndex`. Guild colors defined in `GuildConstants::Colors` namespace. `RenderGuild()` and `RenderCharacter()` in `ZzzCharacter.h/.cpp` handle visual rendering.
- **Guild data structures:** `GUILD_LIST_t` (Name + Number + Server + GuildStatus), `MARK_t` (Key + UnionName + GuildName + Mark[64]). Global `GuildMark[MAX_MARKS]` array where `MAX_MARKS=2000`.

### Key Source Files

| File | Purpose |
|------|---------|
| `src/source/UI/Windows/NewUIChatLogWindow.h/.cpp` | Chat message display, MESSAGE_TYPE filtering |
| `src/source/UI/Windows/NewUIChatInputBox.h/.cpp` | Chat input, INPUT_MESSAGE_TYPE channel selection |
| `src/source/UI/Windows/Social/NewUIPartyInfoWindow.h/.cpp` | Party info panel with HP bars |
| `src/source/UI/Windows/Social/NewUIPartyListWindow.h/.cpp` | Compact party HUD display |
| `src/source/UI/Windows/Social/NewUIGuildInfoWindow.h/.cpp` | Guild info panel (Info/Members/Union tabs) |
| `src/source/UI/Windows/Social/NewUIGuildMakeWindow.h/.cpp` | Guild creation with mark editor |
| `src/source/Gameplay/Social/PartyManager.h` | Party singleton manager, PARTY_t struct |
| `src/source/Gameplay/Social/GuildCache.h` | Guild mark cache, MARK_t struct |
| `src/source/Gameplay/Social/GuildConstants.h` | Centralized guild constants and enums |
| `src/source/Gameplay/Characters/ZzzCharacter.h/.cpp` | Character rendering, guild mark rendering |
| `src/source/UI/Windows/HUD/NewUINameWindow.h/.cpp` | Player name/guild tag rendering above characters |
| `src/source/Network/WSclient.h` | MAX_CHAT_SIZE, PCHATING packet structs, MAX_PARTYS |
| `src/source/Dotnet/PacketBindings_ClientToServer.h` | Chat packet functions with char16_t params (NEVER EDIT — generated) |
| `src/source/Core/mu_struct.h` | CHARACTER struct with guild fields |
| `src/source/Core/mu_define.h` | MAX_MARKS, MAX_USERNAME_SIZE |

### Risk Items

- **R17 (from sprint-status):** All EPIC-6 stories require a running MU Online server for manual validation. Ensure test server is available before starting manual test tasks.
- **R17 Mitigation Strategy:** Same two-tier strategy as 6-2-1/6-2-2: (1) Automated Catch2 component tests validate data structures, enum integrity, constant correctness without server dependency; (2) Manual test scenarios document full end-to-end validation for when server + platform builds are available.
- **Chat encoding complexity:** The chat system uses `char16_t` for network transmission (via .NET AOT bridge) but `wchar_t` internally. Cross-platform `wchar_t` size differences (2 bytes Windows, 4 bytes Linux/macOS) are handled by the `char16_t` encoding layer validated in EPIC-3 (story 3-2-1). Component tests should verify that constants are consistent across the encoding boundary.
- **Guild mark rendering:** Guild marks are 8x8 pixel bitmaps stored as 64-byte arrays. The rendering path goes through `CGuildCache` → `RenderGuild()` → OpenGL (now SDL_GPU after EPIC-4). Component tests validate data structure sizes, not rendering correctness.
- **Generated packet files:** `PacketBindings_ClientToServer.h` and `PacketFunctions_*.h/.cpp` are XSLT-generated — NEVER edit these files.

### PCC Project Constraints

- **Prohibited:** No raw `new`/`delete`, no `NULL`, no `timeGetTime()`, no `#ifdef _WIN32` in game logic, no `wchar_t` in new serialization
- **Required:** `std::unique_ptr`, `nullptr`, `std::chrono::steady_clock`, `std::filesystem::path`, `#pragma once`, Allman braces, 4-space indent
- **Quality gate:** `./ctl check` (clang-format 21.1.8 + cppcheck) — must pass 0 errors
- **Test organization:** `tests/{module}/test_{name}.cpp` mirroring `src/source/{Module}/`
- **References:** `_bmad-output/project-context.md`, `docs/development-standards.md`

### Project Structure Notes

- Tests go in `MuMain/tests/` — e.g., `tests/gameplay/test_social_systems_validation.cpp`
- Test binary: `MuTests` target, linked against `MUCore` (and potentially `MUGame` for gameplay logic)
- `MUCore` uses `file(GLOB)` — new `.cpp` files auto-discovered
- For UI-level tests involving social windows, may need `#ifdef MU_GAME_AVAILABLE` compile-time guard (consistent with 6-1-2, 6-2-1, 6-2-2 patterns)
- Previous stories (6-1-1, 6-1-2, 6-2-1, 6-2-2) established pattern: Catch2 `TEST_CASE` / `SECTION` structure, component-level testing of data structures and enums without server dependency

### Dependency Context

This story depends on **6-1-1-auth-character-validation** (done) — player must be logged in to use social features. It is a **parallel track** (Track D) that does NOT block other stories.

Previous stories established:
- 6-1-1: Catch2 test patterns for scene state validation, quality gate workflow
- 6-1-2: `#ifdef MU_GAME_AVAILABLE` compile-time guard pattern, boundary condition testing
- 6-2-1: Combat data structure validation (34 TEST_CASEs), `CSItemOption` constants testing, non-aliasing proof pattern, pairwise uniqueness checks
- 6-2-2: Inventory/trading data structure validation (24 TEST_CASEs), `STORAGE_TYPE` pairwise distinctness (153 assertions), comprehensive enum coverage patterns

### Previous Story Intelligence

From 6-2-2 code review learnings:
- Use `#ifdef MU_GAME_AVAILABLE` compile-time guard when test code references MUGame-only types
- Avoid vacuous tautology tests — validate actual constants against architectural constraints, not hardcoded literals against themselves
- Ensure pairwise uniqueness checks cover ALL enum values (not just a subset)
- Keep ATDD checklist synchronized with actual test implementation
- Use `static_assert` for struct layout validation where possible
- Clearly distinguish component tests (automated, no server) from end-to-end tests (manual, server required)

---

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (claude-opus-4-6)

### Debug Log References

- Quality gate (`./ctl check`): PASS — 711 files checked, 0 errors (clang-format + cppcheck)
- Test file from ATDD RED phase: 17 TEST_CASEs (12 standalone + 5 MU_GAME_AVAILABLE), 564 lines
- Test file formatting verified: clang-format clean, cppcheck clean

### Completion Notes List

- Test file `test_social_systems_validation.cpp` was created during ATDD phase (create-story workflow) and verified during dev-story
- Manual test scenario documentation created at `_bmad-output/test-scenarios/epic-6/social-systems-validation.md` covering all 5 ACs across 3 platforms (macOS, Linux, Windows)
- Two-tier validation strategy (consistent with 6-2-1/6-2-2): automated Catch2 component tests (no server) + manual test scenarios (server required per Risk R17)
- 17 TEST_CASEs covering: chat constants/enums (AC-1, 5 tests), party struct layout (AC-2, 1 test), guild constants/enums/structs (AC-3, 6 tests), guild marks/colors (AC-4, 3 tests), encoding consistency (AC-5, 2 tests)
- All guild relationship type flags verified as power-of-two bit flags with zero overlap (6 pairs)
- AC-VAL-1..4 (validation artifacts) deferred to manual execution when server + platform builds available

### File List

| Action | File |
|--------|------|
| EXISTING | `MuMain/tests/gameplay/test_social_systems_validation.cpp` |
| NEW | `_bmad-output/test-scenarios/epic-6/social-systems-validation.md` |

### Change Log

| Date | Change |
|------|--------|
| 2026-03-21 | Story implementation complete: manual test scenarios created, Catch2 test suite verified (17 TEST_CASEs), quality gate passed |
