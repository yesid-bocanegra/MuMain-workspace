# Test Scenarios: Story 6.3.1 — Social Systems Validation

**Story ID:** 6.3.1
**Epic:** 6 — Cross-Platform Gameplay Validation
**Flow Code:** VS1-GAME-VALIDATE-SOCIAL
**Date:** 2026-03-21
**Test Type:** Manual + Catch2 Unit

---

## Overview

This document defines the complete test plan for validating that chat messaging,
party management, guild systems, player name/guild tag rendering, and chat encoding
work correctly on macOS, Linux, and Windows.

Automated Catch2 tests cover pure data structure and constant validation:
MAX_CHAT_SIZE, MESSAGE_TYPE enum completeness, PARTY_t struct layout, GuildConstants
(name length, mark size, capacity), GuildTab/GuildInfoButton/RelationshipType enums,
GUILD_LIST_t/MARK_t struct field presence, guild color ARGB values, and cross-system
encoding consistency (MAX_USERNAME_SIZE, char16_t alignment).

Platform rendering, server-interaction, and UI behavior tests are manual-only.

**Prerequisites:**
- Running MU Online test server (live game required for AC-1..5 full validation)
- macOS build: `cmake --preset macos-arm64 && cmake --build --preset macos-arm64-debug`
- Linux build: MinGW cross-compile or native Linux build
- Windows build: `cmake --preset windows-x64 && cmake --build --preset windows-x64-debug`

> **Risk R17:** All full AC-1..5 scenarios require a running MU Online server for actual
> in-game validation. Catch2 tests cover server-independent component logic only.

---

## Automated Test Coverage (Catch2)

Run: `cmake -S MuMain -B build -DBUILD_TESTING=ON && cmake --build build && ctest --test-dir build`

| Test Case | AC | Verifies |
|-----------|-----|----------|
| MAX_CHAT_SIZE == 90 | AC-1 | Chat buffer dimension constant |
| MAX_CHAT_BUFFER_SIZE == 60 (MU_GAME_AVAILABLE) | AC-1 | Chat log circular buffer capacity |
| MAX_NUMBER_OF_LINES == 200 (MU_GAME_AVAILABLE) | AC-1 | Maximum rendered chat lines |
| MESSAGE_TYPE enum: 10 named values, TYPE_ALL_MESSAGE=0, TYPE_UNKNOWN=0xFFFFFFFF | AC-1 | Enum completeness and sentinel |
| MESSAGE_TYPE pairwise distinctness (45 pairs) | AC-1 | No value aliasing in chat channels |
| Channel type ordering: chat(1) < whisper(2) < system(3) < party(5) < guild(6) | AC-1 | Enum value ordering |
| INPUT_MESSAGE_TYPE_COUNT == 4 (MU_GAME_AVAILABLE) | AC-1 | Input channel count |
| INPUT_NOTHING == -1 (MU_GAME_AVAILABLE) | AC-1 | Input sentinel value |
| sizeof(PCHATING::ChatText) == MAX_CHAT_SIZE (MU_GAME_AVAILABLE) | AC-1 | Packet buffer size |
| sizeof(PCHATING_KEY::ChatText) == MAX_CHAT_SIZE (MU_GAME_AVAILABLE) | AC-1 | Encrypted packet buffer size |
| MAX_PARTYS == 5 | AC-2 | Party member capacity |
| PARTY_t::Name buffer = (MAX_USERNAME_SIZE+1) × sizeof(wchar_t) | AC-2 | Name buffer sizing |
| PARTY_t byte fields: Number, Map, x, y, stepHP (1 byte each) | AC-2 | Struct field sizes |
| PARTY_t int fields: currHP, maxHP, index (4 bytes each) | AC-2 | Struct field sizes |
| PARTY_t non-empty (static_assert) | AC-2 | Struct existence |
| GuildConstants::GUILD_NAME_LENGTH == 8 | AC-3 | Guild name character limit |
| GuildConstants::GUILD_NAME_BUFFER_SIZE == 9 | AC-3 | Null-terminated buffer size |
| GuildConstants::GUILD_MARK_SIZE == 64 | AC-3 | Mark bitmap storage size |
| GuildConstants::GUILD_MARK_PIXELS == 8 | AC-3 | Mark pixel grid dimension |
| GuildConstants::Capacity::MAX_CAPACITY == 80 | AC-3 | Maximum guild member count |
| GuildTab enum: INFO=0, MEMBERS=1, UNION=2 (pairwise distinct) | AC-3 | Tab index correctness |
| GuildInfoButton enum: GUILD_OUT=0, END=6, 6 non-END values pairwise distinct | AC-3 | Button index correctness |
| RelationshipType: NONE=0x00, UNION=0x01, RIVAL=0x02, UNION_MASTER=0x04, RIVAL_UNION=0x08 | AC-3 | Bit flag values |
| RelationshipType non-NONE flags: AND==0 for all 6 pairs (no aliasing) | AC-3 | Power-of-two bit flag proof |
| GUILD_LIST_t non-empty, Name = (MAX_USERNAME_SIZE+1) × sizeof(wchar_t) | AC-3 | Struct layout |
| GUILD_LIST_t byte fields: Number, Server, GuildStatus (1 byte each) | AC-3 | Struct field sizes |
| MARK_t non-empty, GuildName/UnionName = GUILD_NAME_BUFFER_SIZE × sizeof(wchar_t) | AC-3 | Struct layout |
| MARK_t::Mark == 64 bytes, Key == 4 bytes | AC-3 | Mark data sizes |
| MAX_MARKS == 2000 | AC-4 | Guild mark array capacity |
| MAX_MARKS > MAX_CAPACITY (architectural constraint) | AC-4 | Cache exceeds single guild |
| GuildConstants::Colors::YELLOW == 0xFFC8FF64u | AC-4 | Allied guild ARGB color |
| GuildConstants::Colors::WHITE == 0xFFFFFFFFu | AC-4 | Neutral guild ARGB color |
| GuildConstants::Colors::GRAY == 0xFF999999u | AC-4 | Rival guild ARGB color |
| Guild colors pairwise distinct | AC-4 | No color aliasing |
| All guild colors alpha == 0xFF (full opacity) | AC-4 | Rendering correctness |
| MARK_t::GuildName ≥ GUILD_NAME_LENGTH+1 chars | AC-4 | Buffer sufficiency |
| MARK_t::UnionName ≥ GUILD_NAME_LENGTH+1 chars | AC-4 | Buffer sufficiency |
| MAX_USERNAME_SIZE == 10 | AC-5 | Username field size |
| MAX_CHAT_SIZE == 90 (encoding consistency) | AC-5 | Cross-system constant check |
| PARTY_t::Name matches MAX_USERNAME_SIZE+1 chars | AC-5 | Party name consistency |
| GUILD_LIST_t::Name matches MAX_USERNAME_SIZE+1 chars | AC-5 | Guild list name consistency |
| GUILD_NAME_LENGTH(8) ≤ MAX_USERNAME_SIZE(10) | AC-5 | Architectural constraint |
| MAX_CHAT_SIZE % 2 == 0 (MU_GAME_AVAILABLE) | AC-5 | char16_t 2-byte alignment |
| sizeof(PCHATING::ChatText) == MAX_CHAT_SIZE (MU_GAME_AVAILABLE) | AC-5 | char16_t alignment |
| sizeof(PCHATING_KEY::ChatText) == MAX_CHAT_SIZE (MU_GAME_AVAILABLE) | AC-5 | char16_t alignment |

---

## Manual Test Scenarios

### Prerequisites for Manual Tests

All manual scenarios require:
1. Running MU Online test server (local or remote)
2. Valid game client build (macOS, Linux, or Windows)
3. Test character logged in and standing in a populated map
4. At least one other player online (for whisper/party/guild testing)

---

### AC-1: Chat Messages Send and Receive (Normal, Party, Guild, Whisper Channels)

**Objective:** Verify all chat channels work correctly and messages display properly
on macOS, Linux, and Windows.

#### Scenario 1.1: Normal Chat Message Send/Receive

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open game client, log in, enter game world | Character appears in-game |
| 2 | Press Enter to open chat input box | Chat input box appears at bottom of screen |
| 3 | Type "Hello World" and press Enter | Message appears in chat log with player name prefix |
| 4 | Verify message in chat log window | Message visible, correctly formatted, no garbled text |
| 5 | Repeat on macOS, Linux, Windows | Same behavior on all platforms |

**Pass Criteria:** Message sent and received, displayed in chat log, no truncation or encoding errors.

#### Scenario 1.2: Party Chat Channel

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create or join a party (see AC-2 scenarios) | Party established with at least 2 members |
| 2 | Switch chat channel to Party (~) | Chat input prefix changes to party indicator |
| 3 | Type "Party test message" and press Enter | Message appears in party chat channel |
| 4 | On second player's client, verify message received | Message appears in party channel on other client |

**Pass Criteria:** Party messages only visible to party members, correct channel coloring.

#### Scenario 1.3: Guild Chat Channel

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure test character is in a guild | Guild membership confirmed in guild panel |
| 2 | Switch chat channel to Guild (@) | Chat input prefix changes to guild indicator |
| 3 | Type "Guild test message" and press Enter | Message appears in guild chat channel |
| 4 | On second guild member's client, verify message | Message appears in guild channel on other client |

**Pass Criteria:** Guild messages only visible to guild members, correct channel coloring.

#### Scenario 1.4: Whisper (Private) Message

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Type "/whisper PlayerName Test whisper" | Whisper sent to target player |
| 2 | On target player's client, verify whisper received | Whisper appears with sender name, distinct color |
| 3 | Target player replies via whisper | Reply appears on original sender's client |

**Pass Criteria:** Whisper messages private between two players, distinct visual style.

---

### AC-2: Party Creation, Invitation, and Member Display

**Objective:** Verify party lifecycle works correctly, including creation, invitation,
member HP display, and party dissolution on all platforms.

#### Scenario 2.1: Party Creation

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Right-click another player's character | Context menu appears with "Party" option |
| 2 | Select "Party" → "Invite" | Party invitation sent to target player |
| 3 | On target player: accept invitation | Party formed, both players see party window |
| 4 | Verify party window shows both members | Names, HP bars, map location visible |

**Pass Criteria:** Party created successfully, both members see each other in party window.

#### Scenario 2.2: Party Member Display (HP Bars and Location)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | In an active party, view party info window | Party member list visible |
| 2 | Verify each member shows: Name, HP bar, map | All fields populated correctly |
| 3 | One member takes damage | HP bar updates in real-time on other members' displays |
| 4 | One member changes map | Map field updates on other members' party window |

**Pass Criteria:** HP bars update in real-time, map location tracked, max 5 members enforced.

#### Scenario 2.3: Party Dissolution

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Party leader selects "Disband party" | All members removed from party |
| 2 | Verify party window closes for all members | Party UI elements removed |
| 3 | Verify each member can create/join new party | No stale party state |

**Pass Criteria:** Clean party dissolution with no ghost members or UI artifacts.

---

### AC-3: Guild Information Panel Displays Correctly

**Objective:** Verify guild info panel renders correctly with Info, Members, and Union
tabs functioning on all platforms.

#### Scenario 3.1: Guild Info Tab

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open guild panel (G key or menu) | Guild information window appears |
| 2 | Verify Info tab is default (GuildTab::INFO=0) | Guild name, master name, member count visible |
| 3 | Verify guild mark renders correctly | 8×8 pixel guild mark visible, not corrupted |
| 4 | Verify guild capacity shows X/80 format | Member count / MAX_CAPACITY displayed |

**Pass Criteria:** Info tab displays all guild metadata correctly.

#### Scenario 3.2: Guild Members Tab

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click Members tab (GuildTab::MEMBERS=1) | Member list appears |
| 2 | Verify member names displayed (up to 8 chars) | Names within GUILD_NAME_LENGTH limit |
| 3 | Verify online/offline status indicators | Status correctly reflects member presence |
| 4 | Verify guild action buttons (6 buttons) | GUILD_OUT through UNION_OUT buttons functional |

**Pass Criteria:** Member list populated, status indicators correct, action buttons responsive.

#### Scenario 3.3: Guild Union Tab

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Click Union tab (GuildTab::UNION=2) | Union/alliance information appears |
| 2 | Verify union guild list (if union exists) | Allied guild names and marks displayed |
| 3 | Verify rival guild display (if rivals exist) | Rival guilds shown with GRAY color indicator |
| 4 | Verify RelationshipType indicators | UNION (allied), RIVAL (enemy), UNION_MASTER, RIVAL_UNION |

**Pass Criteria:** Union tab shows alliance/rivalry information correctly.

---

### AC-4: Player Names and Guild Tags Render Above Characters

**Objective:** Verify that player names and guild tags render correctly above character
models on all platforms with correct guild relationship coloring.

#### Scenario 4.1: Player Name Rendering

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter a populated map with other players | Characters visible in game world |
| 2 | Verify player names appear above characters | Name text rendered at correct position |
| 3 | Verify name length (up to MAX_USERNAME_SIZE=10) | Names not truncated or overflowing |
| 4 | Repeat on macOS, Linux, Windows | Consistent rendering across platforms |

**Pass Criteria:** Player names visible, correctly positioned, readable on all platforms.

#### Scenario 4.2: Guild Tag Rendering

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | View a player who is in a guild | Guild tag appears alongside player name |
| 2 | Verify guild mark (8×8 bitmap) renders | Mark visible, GUILD_MARK_SIZE=64 bytes |
| 3 | Verify guild marks stored in GuildMark[] array | Up to MAX_MARKS=2000 marks cached |

**Pass Criteria:** Guild tags and marks render correctly, cache operates within limits.

#### Scenario 4.3: Guild Relationship Color Coding

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | View an allied guild member (UNION) | Name/tag rendered in YELLOW (0xFFC8FF64) |
| 2 | View a neutral guild member | Name/tag rendered in WHITE (0xFFFFFFFF) |
| 3 | View a rival guild member (RIVAL) | Name/tag rendered in GRAY (0xFF999999) |
| 4 | Verify full opacity on all colors | Alpha channel = 0xFF, no transparency |

**Pass Criteria:** Guild relationship colors match GuildConstants::Colors ARGB values.

---

### AC-5: Chat Encoding — Korean and Latin Characters Display Correctly

**Objective:** Verify that chat messages containing Korean (Hangul), Latin, and mixed
character sets display correctly on all platforms using the char16_t encoding bridge.

#### Scenario 5.1: Latin Character Chat

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Type a Latin message: "Hello World 123!@#" | Message displays correctly in chat |
| 2 | Verify MAX_CHAT_SIZE=90 byte limit | Messages up to 90 bytes accepted |
| 3 | Verify message appears on other clients | No encoding corruption in transit |

**Pass Criteria:** Latin text sends, receives, and displays without corruption.

#### Scenario 5.2: Korean Character Chat

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Switch to Korean IME input | Korean input method active |
| 2 | Type Hangul characters: "안녕하세요" | Korean text appears in chat input |
| 3 | Press Enter to send | Message appears in chat log with correct Hangul |
| 4 | Verify on receiving client | Hangul characters render correctly |
| 5 | Test on macOS (4-byte wchar_t) | char16_t bridge handles encoding correctly |
| 6 | Test on Linux (4-byte wchar_t) | char16_t bridge handles encoding correctly |
| 7 | Test on Windows (2-byte wchar_t) | Native wchar_t path works correctly |

**Pass Criteria:** Korean text preserved through char16_t encoding bridge on all platforms.

#### Scenario 5.3: Mixed Character Chat

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Type mixed message: "Hello 안녕 Test 테스트" | Mixed Latin/Korean displays correctly |
| 2 | Send and verify on all platforms | No partial character corruption |
| 3 | Verify MAX_CHAT_SIZE respects byte count | char16_t code units fit within 90-byte buffer |

**Pass Criteria:** Mixed-script messages transmit correctly via char16_t alignment.

#### Scenario 5.4: Username Cross-System Consistency

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create character with 10-char name (MAX_USERNAME_SIZE) | Name accepted, stored correctly |
| 2 | Verify name in party member display | PARTY_t::Name buffer sufficient |
| 3 | Verify name in guild member list | GUILD_LIST_t::Name buffer sufficient |
| 4 | Verify guild name (up to 8 chars) fits in chat | GUILD_NAME_LENGTH ≤ MAX_USERNAME_SIZE |

**Pass Criteria:** Username buffers consistent across all social subsystems.

---

## Platform Test Matrix

| Scenario | macOS (arm64) | Linux (x64) | Windows (x64) |
|----------|:---:|:---:|:---:|
| AC-1: Normal chat | [ ] | [ ] | [ ] |
| AC-1: Party chat | [ ] | [ ] | [ ] |
| AC-1: Guild chat | [ ] | [ ] | [ ] |
| AC-1: Whisper | [ ] | [ ] | [ ] |
| AC-2: Party create | [ ] | [ ] | [ ] |
| AC-2: Member display | [ ] | [ ] | [ ] |
| AC-2: Party dissolve | [ ] | [ ] | [ ] |
| AC-3: Info tab | [ ] | [ ] | [ ] |
| AC-3: Members tab | [ ] | [ ] | [ ] |
| AC-3: Union tab | [ ] | [ ] | [ ] |
| AC-4: Player names | [ ] | [ ] | [ ] |
| AC-4: Guild tags | [ ] | [ ] | [ ] |
| AC-4: Relationship colors | [ ] | [ ] | [ ] |
| AC-5: Latin chat | [ ] | [ ] | [ ] |
| AC-5: Korean chat | [ ] | [ ] | [ ] |
| AC-5: Mixed chat | [ ] | [ ] | [ ] |
| AC-5: Username consistency | [ ] | [ ] | [ ] |

---

## Validation Sign-Off

| Validator | Platform | Date | Status |
|-----------|----------|------|--------|
| (pending) | macOS | | [ ] |
| (pending) | Linux | | [ ] |
| (pending) | Windows | | [ ] |

---

*Test scenarios generated by PCC dev-story workflow for Story 6.3.1*
