# ATDD Checklist — Story 6.3.1: Social Systems Validation

**Story Key:** 6-3-1-social-systems-validation
**Story Type:** infrastructure
**Generated:** 2026-03-21
**Phase:** RED (failing tests created, implementation pending)

---

## AC-to-Test Mapping

| AC | Description | Test Method(s) | Location | Status |
|----|-------------|----------------|----------|--------|
| AC-1 | Chat system constants, enum completeness, packet struct layout | `AC-1 [6-3-1]: Chat constants define correct buffer dimensions` | test_social_systems_validation.cpp | `[ ]` |
| AC-1 | MESSAGE_TYPE enum 10 values + TYPE_UNKNOWN sentinel | `AC-1 [6-3-1]: MESSAGE_TYPE enum covers all chat channels with no duplicates` | test_social_systems_validation.cpp (MU_GAME_AVAILABLE) | `[ ]` |
| AC-1 | INPUT_MESSAGE_TYPE 4 channels + INPUT_NOTHING sentinel | `AC-1 [6-3-1]: INPUT_MESSAGE_TYPE covers all input channels` | test_social_systems_validation.cpp (MU_GAME_AVAILABLE) | `[ ]` |
| AC-1 | PCHATING ChatText buffer = MAX_CHAT_SIZE | `AC-1 [6-3-1]: PCHATING packet struct has correct ChatText buffer size` | test_social_systems_validation.cpp (MU_GAME_AVAILABLE) | `[ ]` |
| AC-1 | PCHATING_KEY ChatText buffer = MAX_CHAT_SIZE | `AC-1 [6-3-1]: PCHATING_KEY packet struct has correct ChatText buffer size` | test_social_systems_validation.cpp (MU_GAME_AVAILABLE) | `[ ]` |
| AC-2 | MAX_PARTYS=5, PARTY_t struct field layout | `AC-2 [6-3-1]: Party constants define correct capacity and struct layout` | test_social_systems_validation.cpp | `[ ]` |
| AC-3 | GuildConstants dimensions (name=8, mark=64, capacity=80) | `AC-3 [6-3-1]: GuildConstants define correct guild name and mark dimensions` | test_social_systems_validation.cpp | `[ ]` |
| AC-3 | GuildTab enum (INFO/MEMBERS/UNION) pairwise distinct | `AC-3 [6-3-1]: GuildTab enum covers Info/Members/Union tabs with correct values` | test_social_systems_validation.cpp | `[ ]` |
| AC-3 | GuildInfoButton enum 7 values incl. END=6 sentinel | `AC-3 [6-3-1]: GuildInfoButton enum covers all 7 button values including END sentinel` | test_social_systems_validation.cpp | `[ ]` |
| AC-3 | RelationshipType bit flags (NONE=0, UNION=1, RIVAL=2, UNION_MASTER=4, RIVAL_UNION=8) | `AC-3 [6-3-1]: RelationshipType enum covers all alliance/rivalry flag bits` | test_social_systems_validation.cpp | `[ ]` |
| AC-3 | GUILD_LIST_t struct field layout | `AC-3 [6-3-1]: GUILD_LIST_t struct has correct field layout` | test_social_systems_validation.cpp | `[ ]` |
| AC-3 | MARK_t struct field layout (Key, GuildName, UnionName, Mark[64]) | `AC-3 [6-3-1]: MARK_t struct has correct field layout for guild mark storage` | test_social_systems_validation.cpp | `[ ]` |
| AC-4 | MAX_MARKS=2000, Colors::YELLOW/WHITE/GRAY ARGB values | `AC-4 [6-3-1]: MAX_MARKS constant defines guild mark array capacity` | test_social_systems_validation.cpp | `[ ]` |
| AC-4 | GuildConstants::Colors ARGB values, full opacity | `AC-4 [6-3-1]: GuildConstants::Colors ARGB values are correct for all tiers` | test_social_systems_validation.cpp | `[ ]` |
| AC-4 | MARK_t name buffers sufficient for GUILD_NAME_LENGTH | `AC-4 [6-3-1]: MARK_t guild name buffer is sufficient for GUILD_NAME_LENGTH characters` | test_social_systems_validation.cpp | `[ ]` |
| AC-5 | MAX_USERNAME_SIZE=10, MAX_CHAT_SIZE=90, cross-system consistency | `AC-5 [6-3-1]: Chat encoding constants are consistent across all subsystems` | test_social_systems_validation.cpp | `[ ]` |
| AC-5 | PCHATING/PCHATING_KEY ChatText = MAX_CHAT_SIZE, char16_t alignment | `AC-5 [6-3-1]: PCHATING struct ChatText matches MAX_CHAT_SIZE for char16_t alignment` | test_social_systems_validation.cpp (MU_GAME_AVAILABLE) | `[ ]` |

---

## Implementation Checklist

### Test Infrastructure

- [ ] Test file created at `MuMain/tests/gameplay/test_social_systems_validation.cpp`
- [ ] Test file compiles without errors (MinGW cross-compile or Linux native)
- [ ] Test file links against `MuTests` target with `MUCore` dependency
- [ ] All `TEST_CASE` macros use Catch2 v3.7.1 `REQUIRE`/`CHECK` assertion style
- [ ] `#ifdef MU_GAME_AVAILABLE` guard applied to UI/network-dependent tests
- [ ] `#ifdef _WIN32` / `#include "Platform/PlatformTypes.h"` platform guard applied

### AC-1: Chat System

- [ ] `MAX_CHAT_SIZE == 90` verified via `REQUIRE`
- [ ] `MAX_CHAT_BUFFER_SIZE == 60` verified (MU_GAME_AVAILABLE guard)
- [ ] `MAX_NUMBER_OF_LINES == 200` verified (MU_GAME_AVAILABLE guard)
- [ ] `MESSAGE_TYPE` enum: all 10 named values (TYPE_ALL_MESSAGE…TYPE_GM_MESSAGE) pairwise distinct
- [ ] `MESSAGE_TYPE::TYPE_UNKNOWN == 0xFFFFFFFF` sentinel verified
- [ ] `MESSAGE_TYPE::NUMBER_OF_TYPES == 10` verified
- [ ] `INPUT_MESSAGE_TYPE_COUNT == 4` verified (MU_GAME_AVAILABLE guard)
- [ ] `INPUT_NOTHING == -1` sentinel verified (MU_GAME_AVAILABLE guard)
- [ ] `sizeof(PCHATING::ChatText) == MAX_CHAT_SIZE` verified (MU_GAME_AVAILABLE guard)
- [ ] `sizeof(PCHATING_KEY::ChatText) == MAX_CHAT_SIZE` verified (MU_GAME_AVAILABLE guard)

### AC-2: Party System

- [ ] `MAX_PARTYS == 5` verified
- [ ] `PARTY_t::Name` buffer is `(MAX_USERNAME_SIZE + 1) * sizeof(wchar_t)` bytes
- [ ] `PARTY_t::Number`, `Map`, `x`, `y`, `stepHP` are single-byte (BYTE) fields
- [ ] `PARTY_t::currHP`, `maxHP`, `index` are 4-byte (int) fields
- [ ] `PARTY_t` non-empty static_assert passes

### AC-3: Guild Info Panel

- [ ] `GuildConstants::GUILD_NAME_LENGTH == 8` verified
- [ ] `GuildConstants::GUILD_NAME_BUFFER_SIZE == 9` verified (GUILD_NAME_LENGTH + 1)
- [ ] `GuildConstants::GUILD_MARK_SIZE == 64` verified
- [ ] `GuildConstants::GUILD_MARK_PIXELS == 8` verified (8×8 grid)
- [ ] `GuildConstants::Capacity::MAX_CAPACITY == 80` verified
- [ ] `GuildTab::INFO == 0`, `MEMBERS == 1`, `UNION == 2` verified, pairwise distinct
- [ ] `GuildInfoButton::GUILD_OUT == 0`, `END == 6` verified, all 6 non-END values pairwise distinct
- [ ] `RelationshipType::NONE == 0x00` verified
- [ ] `RelationshipType` non-NONE values are power-of-two bit flags (no aliasing across all 6 pairs)
- [ ] `GUILD_LIST_t` non-empty, `Name` = `(MAX_USERNAME_SIZE + 1) * sizeof(wchar_t)`, byte fields verified
- [ ] `MARK_t` non-empty, `GuildName`/`UnionName` = `GUILD_NAME_BUFFER_SIZE * sizeof(wchar_t)`, `Mark` = 64 bytes, `Key` = 4 bytes

### AC-4: Character Guild Fields and Rendering

- [ ] `MAX_MARKS == 2000` verified
- [ ] `MAX_MARKS > GuildConstants::Capacity::MAX_CAPACITY` constraint verified
- [ ] `GuildConstants::Colors::YELLOW == 0xFFC8FF64u` verified
- [ ] `GuildConstants::Colors::WHITE == 0xFFFFFFFFu` verified
- [ ] `GuildConstants::Colors::GRAY == 0xFF999999u` verified
- [ ] All three guild colors pairwise distinct
- [ ] All three guild colors have full opacity (alpha = 0xFF)
- [ ] `MARK_t::GuildName` buffer ≥ `GUILD_NAME_LENGTH + 1` chars
- [ ] `MARK_t::UnionName` buffer ≥ `GUILD_NAME_LENGTH + 1` chars

### AC-5: Chat Encoding

- [ ] `MAX_USERNAME_SIZE == 10` verified
- [ ] `MAX_CHAT_SIZE == 90` verified (encoding consistency check)
- [ ] `PARTY_t::Name` buffer matches `MAX_USERNAME_SIZE + 1` chars
- [ ] `GUILD_LIST_t::Name` buffer matches `MAX_USERNAME_SIZE + 1` chars
- [ ] `GuildConstants::GUILD_NAME_LENGTH(8) <= MAX_USERNAME_SIZE(10)` architectural constraint verified
- [ ] `MAX_CHAT_SIZE % 2 == 0` verified (char16_t 2-byte alignment) (MU_GAME_AVAILABLE guard)
- [ ] `sizeof(PCHATING::ChatText) == MAX_CHAT_SIZE` char16_t alignment verified (MU_GAME_AVAILABLE guard)
- [ ] `sizeof(PCHATING_KEY::ChatText) == MAX_CHAT_SIZE` char16_t alignment verified (MU_GAME_AVAILABLE guard)

### Standard ACs

- [ ] AC-STD-1: Code standards compliance — no prohibited APIs, Allman braces, 4-space indent
- [ ] AC-STD-2: Catch2 test suite validates chat/party/guild logic without live server dependency
- [ ] AC-STD-13: `./ctl check` passes (clang-format + cppcheck 0 errors)
- [ ] AC-STD-15: Git safety — no incomplete rebase, no force push
- [ ] AC-STD-16: Catch2 v3.7.1 used, tests in `tests/` directory

### PCC Compliance

- [ ] No prohibited libraries used (no raw `new`/`delete`, no `NULL`, no Win32 APIs in test logic)
- [ ] No `#ifdef _WIN32` in test logic (only in includes block, per PCC rule)
- [ ] Required testing patterns followed (Catch2 `REQUIRE`/`CHECK` macros, `TEST_CASE`/`SECTION`)
- [ ] No mocking framework used — tests focus on pure logic/constants
- [ ] Test file in correct location: `tests/gameplay/test_social_systems_validation.cpp`
- [ ] Platform-compatibility guard: `#ifdef _WIN32` / `PlatformTypes.h` include block

---

## Test File Summary

| File | Path | Phase | TEST_CASEs |
|------|------|-------|-----------|
| test_social_systems_validation.cpp | `MuMain/tests/gameplay/test_social_systems_validation.cpp` | RED | 16 (11 standalone + 5 MU_GAME_AVAILABLE) |

### TEST_CASE Count by AC

| AC | Standalone TEST_CASEs | MU_GAME_AVAILABLE TEST_CASEs | Total |
|----|----------------------|------------------------------|-------|
| AC-1 | 1 | 4 | 5 |
| AC-2 | 1 | 0 | 1 |
| AC-3 | 6 | 0 | 6 |
| AC-4 | 3 | 0 | 3 |
| AC-5 | 1 | 1 | 2 |
| **Total** | **12** | **5** | **17** |

---

## Manual Test Scenarios (Risk R17 — Server Dependency)

Full AC-1…AC-5 end-to-end validation requires a running MU Online server. Document manual scenarios at:
`_bmad-output/test-scenarios/epic-6/social-systems-validation.md`

| Scenario | AC | Platforms | Status |
|----------|----|-----------|--------|
| Chat messages: normal/party/guild/whisper channels | AC-1 | macOS, Linux, Windows | `[ ]` |
| Korean character chat encoding via char16_t bridge | AC-1, AC-5 | macOS, Linux, Windows | `[ ]` |
| Party creation, invitation, member HP display | AC-2 | macOS, Linux, Windows | `[ ]` |
| Guild info panel: Info/Members/Union tabs | AC-3 | macOS, Linux, Windows | `[ ]` |
| Player name + guild tag rendering above characters | AC-4 | macOS, Linux, Windows | `[ ]` |

---

## Notes

- **R17 mitigation:** Two-tier strategy — automated Catch2 component tests (no server) + manual test scenarios (server required). Consistent with 6-2-1/6-2-2 approach.
- **MU_GAME_AVAILABLE guard:** Tests for `MESSAGE_TYPE`, `INPUT_MESSAGE_TYPE`, `PCHATING`, `PCHATING_KEY` require MUGame linkage (Win32 + OpenGL). Standalone tests cover all other ACs without server/game dependencies.
- **No Bruno collection:** Story type is `infrastructure` — no REST API endpoints to test.
- **No E2E tests:** Story type is `infrastructure` — Playwright not applicable.
- **char16_t alignment:** `MAX_CHAT_SIZE=90` is even, allowing exact char16_t packing (45 code units). This is validated in AC-5 standalone test (`MAX_CHAT_SIZE % 2 == 0`).
- **RelationshipType bit-flag proof:** All 6 pairs of non-NONE flags verified for zero AND overlap — more rigorous than pairwise uniqueness alone.
- **GuildInfoButton END sentinel:** `END=6` is the array-sizing sentinel, not a valid button. Tests verify both `GUILD_OUT=0` and `END=6` plus pairwise uniqueness of the 6 actual buttons.
